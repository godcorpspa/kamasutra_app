import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

/// A song found in the catalogue.
class SongResult {
  final String title;
  final String artist;
  final String? year;

  const SongResult({required this.title, required this.artist, this.year});
}

class SongSearchException implements Exception {
  final int? statusCode;

  const SongSearchException([this.statusCode]);

  @override
  String toString() => 'SongSearchException($statusCode)';
}

/// Song search built only on open, free services run by the non-profit
/// MetaBrainz Foundation, so the app pays nothing and uses no licensed
/// content:
///
/// * MusicBrainz, the open music encyclopedia, finds the songs. Titles,
///   artists and dates are its "core data", released under CC0 (public
///   domain), commercial use included. It asks clients to name themselves
///   in the User-Agent and to send at most one request per second.
/// * ListenBrainz, its open listening-statistics sister project, says how
///   many times each recording has been played, so famous songs come
///   first (plain counts are factual data, also public domain).
///
/// No audio and no album covers are used: covers are copyrighted artwork.
class SongSearch {
  SongSearch({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  static const _userAgent =
      'KamasutraCoupleGames/1.0 (https://github.com/godcorpspa/kamasutra_app)';

  Future<List<SongResult>> search(String text) async {
    final terms = text.replaceAll(_luceneSpecial, ' ').trim();
    if (terms.isEmpty) return const [];

    // First the commercially released recordings (they carry an ISRC code)
    // whose title or artist matches: this finds the well-known versions and
    // also answers searches by artist name ("Vasco Rossi").
    final recordings = await _recordings({
      'query': '(recording:($terms) OR artist:($terms)) AND isrc:[0 TO z]',
      'limit': '100',
    });
    // Few hits (lesser-known or older songs): add a plain text search.
    if (recordings.length < 25) {
      final seen = {for (final r in recordings) r['id']};
      final more = await _recordings({
        'query': terms,
        'dismax': 'true',
        'limit': '60',
      });
      recordings.addAll(more.where((r) => seen.add(r['id'])));
    }

    final ids = [
      for (final r in recordings)
        if (r['id'] case final String id) id,
    ];
    return rank({'recordings': recordings}, listens: await _listenCounts(ids));
  }

  static final _luceneSpecial = RegExp(r'[+\-!(){}\[\]^"~*?:\\/&|]');

  Future<List<Map<String, dynamic>>> _recordings(
      Map<String, String> params) async {
    final uri = Uri.https('musicbrainz.org', '/ws/2/recording', {
      ...params,
      'fmt': 'json',
    });
    // 503 means "slow down": the service shares its rate limit per network,
    // so wait a little and try again before giving up.
    http.Response? response;
    for (var attempt = 0; attempt < 3; attempt++) {
      final wait = _lastRequest
          .add(Duration(milliseconds: 1100 * (attempt + 1)))
          .difference(DateTime.now());
      if (!wait.isNegative) await Future<void>.delayed(wait);
      _lastRequest = DateTime.now();
      response = await _client.get(uri, headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 12));
      if (response.statusCode != 503) break;
    }
    if (response!.statusCode != 200) {
      throw SongSearchException(response.statusCode);
    }
    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return (json['recordings'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .toList();
  }

  /// Play counts per recording from ListenBrainz. Popularity only refines
  /// the order, so any failure just returns an empty map.
  Future<Map<String, int>> _listenCounts(List<String> recordingIds) async {
    final counts = <String, int>{};
    try {
      for (var i = 0; i < recordingIds.length; i += 100) {
        final batch = recordingIds.sublist(i, min(i + 100, recordingIds.length));
        final response = await _client
            .post(
              Uri.https('api.listenbrainz.org', '/1/popularity/recording'),
              headers: {
                'User-Agent': _userAgent,
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'recording_mbids': batch}),
            )
            .timeout(const Duration(seconds: 8));
        if (response.statusCode != 200) break;
        for (final e in jsonDecode(response.body) as List) {
          if ((e as Map)['recording_mbid'] case final String id) {
            counts[id] = (e['total_listen_count'] as num?)?.toInt() ?? 0;
          }
        }
      }
    } catch (_) {
      // Keep whatever arrived; the order falls back to release counts.
    }
    return counts;
  }

  void close() => _client.close();

  /// Turns a MusicBrainz recording search into a short list of songs.
  ///
  /// The catalogue lists every release of a song separately and ranks them
  /// by text match only, so a famous song can trail behind obscure ones
  /// with the same title. Recordings are grouped by title and artist, loose
  /// matches are dropped and the rest are ordered by how often they have
  /// been played ([listens], from ListenBrainz) and released — then by
  /// match. Karaoke, instrumental and cover versions are pushed down.
  static List<SongResult> rank(
    Map<String, dynamic> json, {
    Map<String, int> listens = const {},
    int limit = 15,
  }) {
    final groups = <String, _Group>{};
    for (final r in (json['recordings'] as List? ?? const [])) {
      final rec = r as Map<String, dynamic>;
      final title = (rec['title'] as String? ?? '').trim();
      final artist = [
        for (final c in (rec['artist-credit'] as List? ?? const []))
          '${(c as Map)['name'] ?? ''}${c['joinphrase'] ?? ''}',
      ].join().trim();
      if (title.isEmpty || artist.isEmpty) continue;

      final key = '${_normalize(title)}|${_normalize(artist)}';
      final group = groups.putIfAbsent(
        key,
        () => _Group(title: title, artist: artist),
      );
      group.score = max(group.score, (rec['score'] as num?)?.toInt() ?? 0);
      group.releases += (rec['releases'] as List? ?? const []).length;
      group.listens += listens[rec['id']] ?? 0;
      final date = rec['first-release-date'] as String?;
      if (date != null && date.length >= 4) {
        final year = date.substring(0, 4);
        if (group.year == null || year.compareTo(group.year!) < 0) {
          group.year = year;
        }
      }
    }

    // Drop loose matches (single words of a longer query, say).
    final best = groups.values.fold<int>(0, (m, g) => max(m, g.score));
    final ranked = groups.values.where((g) => g.score * 2 >= best).toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));
    return [
      for (final g in ranked.take(limit))
        SongResult(title: g.title, artist: g.artist, year: g.year),
    ];
  }

  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim();
}

class _Group {
  final String title;
  final String artist;
  int score = 0;
  int releases = 0;
  int listens = 0;
  String? year;

  _Group({required this.title, required this.artist});

  static final _lesser = RegExp(r'karaoke|instrumental|cover|tribute|made famous',
      caseSensitive: false);

  double get weight {
    final fame = log(2 + listens) + 0.5 * log(2 + releases);
    var w = score / 100 * fame;
    if (_lesser.hasMatch(title) || _lesser.hasMatch(artist)) w *= 0.3;
    return w;
  }
}
