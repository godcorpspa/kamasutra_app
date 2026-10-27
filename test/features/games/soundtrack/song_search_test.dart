import 'package:flutter_test/flutter_test.dart';
import 'package:kamasutra_app/features/games/soundtrack/data/song_search.dart';

Map<String, dynamic> _rec(
  String id,
  String title,
  String artist, {
  int score = 100,
  int releases = 1,
  String? date,
}) =>
    {
      'id': id,
      'title': title,
      'score': score,
      'artist-credit': [
        {'name': artist},
      ],
      if (date != null) 'first-release-date': date,
      'releases': [for (var i = 0; i < releases; i++) <String, dynamic>{}],
    };

void main() {
  test('groups the releases of one song and keeps its earliest year', () {
    final results = SongSearch.rank({
      'recordings': [
        _rec('a', 'Perfect', 'Ed Sheeran', releases: 30, date: '2019'),
        _rec('b', 'Perfect', 'Ed Sheeran', releases: 40, date: '2017-03-03'),
        _rec('c', 'Perfect', 'Ed Sheeran', releases: 20, date: '2023-05-10'),
      ],
    });
    expect(results, hasLength(1));
    expect(results.single.year, '2017');
  });

  test('puts the most played song first, even with a weaker text match', () {
    final results = SongSearch.rank(
      {
        'recordings': [
          _rec('obscure', 'Thinking Out Loud', 'Ron Sexsmith'),
          _rec('cover', 'Thinking Out Loud', 'Kidz Bop', releases: 3),
          _rec('hit', 'Thinking Out Loud', 'Ed Sheeran', score: 90),
        ],
      },
      listens: {'obscure': 120, 'cover': 900, 'hit': 67202},
    );
    expect(results.first.artist, 'Ed Sheeran');
  });

  test('without play counts, falls back to the number of releases', () {
    final results = SongSearch.rank({
      'recordings': [
        _rec('x', 'Perfect - Ed Sheeran', 'Tadeusz Machalski'),
        _rec('y', 'Perfect', 'Ed Sheeran', score: 57, releases: 90),
      ],
    });
    expect(results.first.artist, 'Ed Sheeran');
  });

  test('pushes karaoke and covers down and drops loose matches', () {
    final results = SongSearch.rank(
      {
        'recordings': [
          _rec('k', 'Albachiara (Karaoke Version)', 'Karaoke Hits'),
          _rec('v', 'Albachiara', 'Vasco Rossi'),
          _rec('n', 'Nell', 'Someone', score: 33, releases: 9),
        ],
      },
      listens: {'k': 500, 'v': 500, 'n': 99999},
    );
    expect(results.first.artist, 'Vasco Rossi');
    expect(results.map((r) => r.title), isNot(contains('Nell')));
  });

  test('joins multi-artist credits', () {
    final results = SongSearch.rank({
      'recordings': [
        {
          'id': 'm',
          'title': 'Meravigliosa creatura',
          'score': 100,
          'artist-credit': [
            {'name': 'Gianna Nannini', 'joinphrase': ' & '},
            {'name': 'Laura Pausini'},
          ],
        },
      ],
    });
    expect(results.single.artist, 'Gianna Nannini & Laura Pausini');
  });

  test('copes with an empty or odd response', () {
    expect(SongSearch.rank({}), isEmpty);
    expect(SongSearch.rank({'recordings': []}), isEmpty);
  });
}
