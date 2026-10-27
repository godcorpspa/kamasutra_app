import 'package:flutter_test/flutter_test.dart';
import 'package:kamasutra_app/features/games/soundtrack/data/song_search.dart';

Map<String, dynamic> _rec(String title, String artist,
        {int score = 100, int releases = 1, String? date, String? rg}) =>
    {
      'title': title,
      'score': score,
      'artist-credit': [
        {'name': artist},
      ],
      if (date != null) 'first-release-date': date,
      'releases': [
        for (var i = 0; i < releases; i++)
          {
            'release-group': {'id': rg ?? 'rg-$title-$artist'},
          },
      ],
    };

void main() {
  test('groups the releases of one song and ranks famous songs first', () {
    final results = SongSearch.rank({
      'recordings': [
        _rec('Perfect - Ed Sheeran', 'Tadeusz Machalski'),
        _rec('Perfect Ed Sheeran Violin Cover', 'Taylor Davis', score: 86),
        _rec('Perfect', 'Ed Sheeran', score: 57, releases: 30, date: '2017-03-03'),
        _rec('Perfect', 'Ed Sheeran', score: 57, releases: 40, date: '2019'),
        _rec('Perfect', 'Ed Sheeran', score: 57, releases: 20, date: '2023-05-10'),
      ],
    });
    expect(results.first.title, 'Perfect');
    expect(results.first.artist, 'Ed Sheeran');
    expect(results.first.year, '2017');
    expect(results.where((r) => r.artist == 'Ed Sheeran'), hasLength(1));
  });

  test('pushes karaoke and covers down', () {
    final results = SongSearch.rank({
      'recordings': [
        _rec('Albachiara (Karaoke Version)', 'Karaoke Hits', releases: 5),
        _rec('Albachiara', 'Vasco Rossi', releases: 3),
      ],
    });
    expect(results.first.artist, 'Vasco Rossi');
  });

  test('joins multi-artist credits and builds the cover link', () {
    final results = SongSearch.rank({
      'recordings': [
        {
          'title': 'Meravigliosa creatura',
          'score': 100,
          'artist-credit': [
            {'name': 'Gianna Nannini', 'joinphrase': ' & '},
            {'name': 'Laura Pausini'},
          ],
          'releases': [
            {
              'release-group': {'id': 'abc'},
            },
          ],
        },
      ],
    });
    expect(results.single.artist, 'Gianna Nannini & Laura Pausini');
    expect(results.single.coverUrl,
        'https://coverartarchive.org/release-group/abc/front-250');
  });

  test('prefers the original album cover and drops loose matches', () {
    final results = SongSearch.rank({
      'recordings': [
        {
          'title': 'Sei nell’anima',
          'score': 100,
          'artist-credit': [
            {'name': 'Gianna Nannini'},
          ],
          'releases': [
            {
              'status': 'Official',
              'release-group': {
                'id': 'compilation',
                'primary-type': 'Album',
                'secondary-types': ['Compilation'],
              },
            },
            {
              'status': 'Official',
              'release-group': {'id': 'album', 'primary-type': 'Album'},
            },
          ],
        },
        _rec('Nell', 'Someone', score: 33, releases: 9),
      ],
    });
    expect(results, hasLength(1));
    expect(results.single.releaseGroupId, 'album');
  });

  test('copes with an empty or odd response', () {
    expect(SongSearch.rank({}), isEmpty);
    expect(SongSearch.rank({'recordings': []}), isEmpty);
  });
}
