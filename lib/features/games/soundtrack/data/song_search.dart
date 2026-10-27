import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

/// A song found in the catalogue.
class SongResult {
  final String title;
  final String artist;
  final String? year;

  /// MusicBrainz release group, used for the cover thumbnail.
  final String? releaseGroupId;

  const SongResult({
    required this.title,
    required this.artist,
    this.year,
    this.releaseGroupId,
  });

  /// Front cover from the Cover Art Archive (also open); many songs have
  /// none, so callers must handle a failed image.
  String? get coverUrl => releaseGroupId == null
      ? null
      : 'https://coverartarchive.org/release-group/$releaseGroupId/front-250';
}

class SongSearchException implements Exception {
  final int? statusCode;

  const SongSearchException([this.statusCode]);

  @override
  String toString() => 'SongSearchException($statusCode)';
}

/// Song search on MusicBrainz, the open music encyclopedia: open data, an
/// open-source server and no API key. Its rules ask clients to identify
/// themselves in the User-Agent and to send at most one request per second.
class SongSearch {
  SongSearch({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  static const _userAgent =
      'KamasutraCoupleGames/1.0 (https://github.com/godcorpspa/kamasutra_app)';

  Future<List<SongResult>> search(String text) async {
    final query = text.trim();
    if (query.isEmpty) return const [];

    final uri = Uri.https('musicbrainz.org', '/ws/2/recording', {
      'query': query,
      // Plain-text search over titles and artists, no Lucene syntax needed.
      'dismax': 'true',
      'fmt': 'json',
      'limit': '60',
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
    final json = jsonDecode(utf8.decode(response.bodyBytes));
    return rank(json as Map<String, dynamic>);
  }

  void close() => _client.close();

  /// Turns a MusicBrainz recording search into a short list of songs.
  ///
  /// The catalogue lists every release of a song separately and ranks them
  /// by text match only, so a famous song can trail behind obscure ones
  /// with the same title. Recordings are grouped by title and artist, then
  /// ordered by match score weighted by how many releases the song has —
  /// a fair proxy for how well known it is. Karaoke, instrumental and cover
  /// versions are pushed down.
  static List<SongResult> rank(Map<String, dynamic> json, {int limit = 15}) {
    final groups = <String, _Group>{};
    for (final r in (json['recordings'] as List? ?? const [])) {
      final rec = r as Map<String, dynamic>;
      final title = (rec['title'] as String? ?? '').trim();
      final artist = [
        for (final c in (rec['artist-credit'] as List? ?? const []))
          '${(c as Map)['name'] ?? ''}${c['joinphrase'] ?? ''}',
      ].join().trim();
      if (title.isEmpty || artist.isEmpty) continue;

      final releases = (rec['releases'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
      final key = '${_normalize(title)}|${_normalize(artist)}';
      final group = groups.putIfAbsent(
        key,
        () => _Group(title: title, artist: artist),
      );
      group.score = max(group.score, (rec['score'] as num?)?.toInt() ?? 0);
      group.releases += releases.length;
      final date = rec['first-release-date'] as String?;
      if (date != null && date.length >= 4) {
        final year = date.substring(0, 4);
        if (group.year == null || year.compareTo(group.year!) < 0) {
          group.year = year;
        }
      }
      // Cover: prefer the song's own album or single over compilations.
      for (final rel in releases) {
        final rg = rel['release-group'] as Map<String, dynamic>?;
        final id = rg?['id'];
        if (id is! String) continue;
        final official = rel['status'] == 'Official';
        final ownRelease = const {'Album', 'Single', 'EP'}
                .contains(rg?['primary-type']) &&
            ((rg?['secondary-types'] as List?)?.isEmpty ?? true);
        final rank = official && ownRelease ? 0 : (official ? 1 : 2);
        if (rank < group.coverRank) {
          group.coverRank = rank;
          group.releaseGroupId = id;
        }
      }
    }

    // Drop loose matches (single words of a longer query, say).
    final best = groups.values.fold<int>(0, (m, g) => max(m, g.score));
    final ranked = groups.values.where((g) => g.score * 2 >= best).toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));
    return [
      for (final g in ranked.take(limit))
        SongResult(
          title: g.title,
          artist: g.artist,
          year: g.year,
          releaseGroupId: g.releaseGroupId,
        ),
    ];
  }

  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ').trim();
}

class _Group {
  final String title;
  final String artist;
  int score = 0;
  int releases = 0;
  String? year;
  String? releaseGroupId;
  int coverRank = 3;

  _Group({required this.title, required this.artist});

  static final _lesser =
      RegExp(r'karaoke|instrumental|cover|tribute|made famous', caseSensitive: false);

  double get weight {
    var w = score / 100 * log(2 + releases);
    if (_lesser.hasMatch(title) || _lesser.hasMatch(artist)) w *= 0.3;
    return w;
  }
}
