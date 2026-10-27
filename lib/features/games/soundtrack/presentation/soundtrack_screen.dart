import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../shared/utils/display_text.dart';
import '../../shared/game_kit.dart';
import '../data/song_search.dart';

/// Soundtrack: the partners take turns picking a song for a theme ("our
/// first meeting", "road trip"…); the other reacts to it. At the end the
/// playlist is shown with the favourite songs and can be copied.
class SoundtrackScreen extends StatefulWidget {
  const SoundtrackScreen({super.key});

  @override
  State<SoundtrackScreen> createState() => _SoundtrackScreenState();
}

enum _Phase { setup, choosing, reacting, playlist }

class _Theme {
  final String key;
  final IconData icon;

  const _Theme(this.key, this.icon);

  String get title => 'soundtrack_prompts.$key.title'.tr();
  String get desc => 'soundtrack_prompts.$key.desc'.tr();
}

const _themes = [
  _Theme('first_impression', Icons.auto_awesome_outlined),
  _Theme('special_moment', Icons.favorite_border_rounded),
  _Theme('road_trip', Icons.directions_car_outlined),
  _Theme('romantic_evening', Icons.wine_bar_outlined),
  _Theme('energy', Icons.bolt_outlined),
  _Theme('comfort', Icons.spa_outlined),
  _Theme('passion', Icons.local_fire_department_outlined),
  _Theme('nostalgia', Icons.hourglass_empty_rounded),
  _Theme('future_together', Icons.wb_twilight_outlined),
  _Theme('our_song', Icons.people_outline_rounded),
];

class _Reaction {
  final String id;
  final IconData icon;
  final Color color;
  final int hearts;

  const _Reaction(this.id, this.icon, this.color, this.hearts);

  String get label => 'games.soundtrack.reaction_$id'.tr();
}

const _reactions = [
  _Reaction('love', Icons.favorite_rounded, GameTone.accent, 3),
  _Reaction('fire', Icons.local_fire_department_outlined, AppColors.jewelEmber, 2),
  _Reaction('nice', Icons.thumb_up_alt_outlined, AppColors.jewelLilac, 1),
  _Reaction('meh', Icons.more_horiz_rounded, AppColors.mist, 0),
];

_Reaction? _reaction(String? id) {
  for (final r in _reactions) {
    if (r.id == id) return r;
  }
  return null;
}

class _Song {
  final String title;
  final String artist;
  final _Theme theme;
  final int addedBy;
  String? reaction;

  _Song(this.title, this.artist, this.theme, this.addedBy);

  int get hearts => _reaction(reaction)?.hearts ?? 0;
}

class _SoundtrackScreenState extends State<SoundtrackScreen> {
  final _session = GameSession();
  final _random = Random();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _searchController = TextEditingController();
  final _songSearch = SongSearch();
  final List<_Song> _playlist = [];

  // Catalogue search for the current turn.
  Timer? _debounce;
  int _searchSeq = 0;
  bool _searching = false;
  bool _searchFailed = false;
  List<SongResult>? _results;
  SongResult? _picked;
  bool _manual = false;

  _Phase _phase = _Phase.setup;
  int _themeCount = 8;
  List<_Theme> _round = [];
  int _index = 0;
  int _firstPlayer = 1;
  bool _missingTitle = false;

  int get _player => _index.isEven ? _firstPlayer : 3 - _firstPlayer;

  @override
  void dispose() {
    _debounce?.cancel();
    _songSearch.close();
    _searchController.dispose();
    _titleController.dispose();
    _artistController.dispose();
    _session.finish();
    super.dispose();
  }

  List<String> get _rules => [
        'games.soundtrack.rule_1'.tr(),
        'games.soundtrack.rule_2'.tr(),
        'games.soundtrack.rule_3'.tr(),
        'games.soundtrack.rule_4'.tr(),
        'games.soundtrack.rule_5'.tr(),
      ];

  void _start() {
    _session.start();
    setState(() {
      _round = (List.of(_themes)..shuffle(_random)).take(_themeCount).toList();
      _index = 0;
      _firstPlayer = _random.nextInt(2) + 1;
      _playlist.clear();
      _phase = _Phase.choosing;
    });
  }

  /// Searches the catalogue a moment after the player stops typing.
  void _onSearchChanged(String text) {
    _debounce?.cancel();
    if (text.trim().length < 3) {
      _searchSeq++;
      setState(() {
        _results = null;
        _searching = false;
        _searchFailed = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 700), () => _search(text));
  }

  Future<void> _search(String text) async {
    _debounce?.cancel();
    if (text.trim().length < 2) return;
    final seq = ++_searchSeq;
    setState(() {
      _searching = true;
      _searchFailed = false;
    });
    try {
      final results = await _songSearch.search(text);
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _results = results.take(10).toList();
        _searching = false;
      });
    } catch (_) {
      // Offline, timed out or the service is busy: offer manual entry.
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _results = null;
        _searching = false;
        _searchFailed = true;
      });
    }
  }

  void _resetTurn() {
    _debounce?.cancel();
    _searchSeq++;
    _searchController.clear();
    _titleController.clear();
    _artistController.clear();
    _results = null;
    _picked = null;
    _searching = false;
    _searchFailed = false;
    _manual = false;
    _missingTitle = false;
  }

  void _addSong() {
    final _Song song;
    if (_manual) {
      final title = _titleController.text.trim();
      if (title.isEmpty) {
        HapticFeedback.lightImpact();
        setState(() => _missingTitle = true);
        return;
      }
      final artist = _artistController.text.trim();
      song = _Song(
        title,
        artist.isEmpty ? 'game_ui.unknown_artist'.tr() : artist,
        _round[_index],
        _player,
      );
    } else {
      final picked = _picked;
      if (picked == null) return;
      song = _Song(picked.title, picked.artist, _round[_index], _player);
    }
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    _playlist.add(song);
    setState(() {
      _resetTurn();
      _phase = _Phase.reacting;
    });
  }

  void _react(String? id) {
    HapticFeedback.mediumImpact();
    _playlist.last.reaction = id;
    _next();
  }

  void _skipTheme() {
    _resetTurn();
    _next();
  }

  void _next() {
    if (_index < _round.length - 1) {
      setState(() {
        _index++;
        _phase = _Phase.choosing;
      });
    } else {
      _session.finish();
      setState(() => _phase = _Phase.playlist);
    }
  }

  Future<void> _copyPlaylist() async {
    final lines = [
      for (var i = 0; i < _playlist.length; i++)
        '${i + 1}. ${_playlist[i].title} — ${_playlist[i].artist}',
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('games.soundtrack.copied'.tr())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inGame = _phase == _Phase.choosing || _phase == _Phase.reacting;
    return GameScaffold(
      title: 'games.soundtrack.app_bar_title'.tr(),
      guardExit: inGame,
      onHelp: () => showGameRules(
        context,
        title: 'game_ui.how_to_play'.tr(),
        rules: _rules,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey('$_phase$_index'),
          child: switch (_phase) {
            _Phase.setup => _buildSetup(),
            _Phase.choosing => _buildChoosing(),
            _Phase.reacting => _buildReacting(),
            _Phase.playlist => _buildPlaylist(),
          },
        ),
      ),
    );
  }

  // ── Setup ──────────────────────────────────────────────────────────────

  Widget _buildSetup() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        GameHero(
          icon: Icons.music_note_outlined,
          title: 'games.soundtrack.app_bar_title'.tr(),
          subtitle: 'game_ui.create_love_playlist'.tr(),
        ),
        const SizedBox(height: 32),
        const GamePlayersCard(),
        const SizedBox(height: 28),
        GameSectionLabel('games.soundtrack.prompts_count'.tr()),
        GameSegmented<int>(
          values: const [5, 8, 10],
          selected: _themeCount,
          numeric: true,
          label: (v) => '$v',
          onChanged: (v) => setState(() => _themeCount = v),
        ),
        const SizedBox(height: 28),
        GameSectionLabel('game_ui.playlist_themes'.tr()),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in _themes)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.round),
                  border: Border.all(color: AppColors.hairline),
                  color: AppColors.inkRaised.withOpacity(0.78),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.icon, size: 14, color: GameTone.accentSoft),
                    const SizedBox(width: 6),
                    Text(
                      t.title,
                      style:
                          const TextStyle(fontSize: 13, color: AppColors.ivory),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 28),
        GameRulesCard(title: 'game_ui.how_to_play'.tr(), rules: _rules),
        const SizedBox(height: 28),
        GamePrimaryButton(
          label: 'game_ui.create_playlist'.tr(),
          icon: Icons.play_arrow_rounded,
          onPressed: _start,
        ),
      ],
    );
  }

  // ── Turn ───────────────────────────────────────────────────────────────

  String get _progress => 'game_ui.song_of'.tr(namedArgs: {
        'current': '${_index + 1}',
        'total': '${_round.length}',
      });

  Widget _themeCard(_Theme theme) {
    final text = Theme.of(context).textTheme;
    return GameSurface(
      highlighted: true,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      child: Column(
        children: [
          Icon(theme.icon, color: GameTone.accentSoft, size: 24),
          const SizedBox(height: 10),
          Text(theme.title,
              textAlign: TextAlign.center, style: text.headlineSmall),
          const SizedBox(height: 6),
          Text(
            theme.desc,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: AppColors.mist),
          ),
        ],
      ),
    );
  }

  Widget _buildChoosing() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        GameTurnBanner(
          player: _player,
          caption: 'game_kit.chooses'.tr(),
          trailing: _progress,
        ),
        const SizedBox(height: 12),
        GameProgressBar(value: _index / _round.length),
        const SizedBox(height: 18),
        _themeCard(_round[_index]),
        const SizedBox(height: 20),
        if (_manual) ..._manualEntry() else ..._catalogueSearch(),
        const SizedBox(height: 22),
        GamePrimaryButton(
          label: 'game_ui.add_btn'.tr(),
          icon: Icons.add_rounded,
          onPressed: _manual || _picked != null ? _addSong : null,
        ),
        Center(
          child: GameQuietButton(
            label: 'game_ui.skip_action'.tr(),
            icon: Icons.skip_next_rounded,
            onPressed: _skipTheme,
          ),
        ),
      ],
    );
  }

  List<Widget> _catalogueSearch() {
    final picked = _picked;
    if (picked != null) {
      return [
        GameSurface(
          highlighted: true,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const _SongBadge(size: 56),
              const SizedBox(width: 14),
              Expanded(child: _SongText(song: picked)),
              IconButton(
                tooltip: 'games.soundtrack.change_song'.tr(),
                icon: const Icon(Icons.close_rounded, color: AppColors.mist),
                onPressed: () => setState(() => _picked = null),
              ),
            ],
          ),
        ),
      ];
    }
    final results = _results;
    return [
      TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: _onSearchChanged,
        onSubmitted: _search,
        style: const TextStyle(color: AppColors.ivory),
        decoration: InputDecoration(
          hintText: 'games.soundtrack.search_hint'.tr(),
          prefixIcon: const Icon(Icons.search_rounded),
          fillColor: AppColors.inkRaised.withOpacity(0.85),
          suffixIcon: _searching
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 1.6),
                  ),
                )
              : null,
        ),
      ),
      const SizedBox(height: 8),
      if (_searchFailed)
        _SearchNote('games.soundtrack.offline'.tr())
      else if (results != null && results.isEmpty)
        _SearchNote('games.soundtrack.no_results'.tr())
      else if (results != null)
        for (final r in results)
          _ResultRow(
            song: r,
            onTap: () {
              HapticFeedback.selectionClick();
              FocusScope.of(context).unfocus();
              setState(() => _picked = r);
            },
          ),
      Row(
        children: [
          Expanded(
            child: Text(
              'games.soundtrack.search_source'.tr(),
              style: const TextStyle(fontSize: 11.5, color: AppColors.smoke),
            ),
          ),
          TextButton.icon(
            onPressed: () => setState(() {
              _manual = true;
              final typed = _searchController.text.trim();
              if (_titleController.text.isEmpty) _titleController.text = typed;
            }),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: Text('games.soundtrack.type_manually'.tr()),
          ),
        ],
      ),
    ];
  }

  List<Widget> _manualEntry() {
    return [
      TextField(
        controller: _titleController,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.next,
        onChanged: (_) {
          if (_missingTitle) setState(() => _missingTitle = false);
        },
        style: const TextStyle(color: AppColors.ivory),
        decoration: InputDecoration(
          labelText: 'game_ui.song_title_label'.tr(),
          prefixIcon: const Icon(Icons.music_note_outlined),
          fillColor: AppColors.inkRaised.withOpacity(0.85),
          errorText: _missingTitle ? 'game_ui.enter_song_title'.tr() : null,
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _artistController,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _addSong(),
        style: const TextStyle(color: AppColors.ivory),
        decoration: InputDecoration(
          labelText: 'game_ui.artist_label'.tr(),
          prefixIcon: const Icon(Icons.person_outline_rounded),
          fillColor: AppColors.inkRaised.withOpacity(0.85),
        ),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () => setState(() => _manual = false),
          icon: const Icon(Icons.search_rounded, size: 16),
          label: Text('games.soundtrack.search_catalog'.tr()),
        ),
      ),
    ];
  }

  Widget _buildReacting() {
    final text = Theme.of(context).textTheme;
    final song = _playlist.last;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        GameTurnBanner(
          player: 3 - _player,
          caption: 'games.soundtrack.reacting'.tr(),
          trailing: _progress,
        ),
        const SizedBox(height: 22),
        GameSurface(
          highlighted: true,
          child: Row(
            children: [
              const _SongBadge(size: 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.theme.title.toUpperCase(),
                      style: AppTypography.eyebrow.copyWith(
                        fontSize: 10,
                        color: GameTone.accentSoft,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(song.title, style: text.titleLarge),
                    Text(
                      song.artist,
                      style: const TextStyle(fontSize: 14, color: AppColors.mist),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text(
          'games.soundtrack.react_prompt'.tr(),
          textAlign: TextAlign.center,
          style: text.headlineSmall,
        ),
        const SizedBox(height: 18),
        for (final r in _reactions) ...[
          GameOptionTile(
            title: r.label,
            icon: r.icon,
            badge: r.hearts > 0 ? '+${r.hearts}' : null,
            selected: false,
            onTap: () => _react(r.id),
          ),
          const SizedBox(height: 10),
        ],
        Center(
          child: GameQuietButton(
            label: 'games.soundtrack.skip_reaction'.tr(),
            icon: Icons.skip_next_rounded,
            onPressed: () => _react(null),
          ),
        ),
      ],
    );
  }

  // ── Playlist ───────────────────────────────────────────────────────────

  Widget _buildPlaylist() {
    final text = Theme.of(context).textTheme;
    final hearts = _playlist.fold<int>(0, (sum, s) => sum + s.hearts);
    final top = (List.of(_playlist)..sort((a, b) => b.hearts.compareTo(a.hearts)))
        .where((s) => s.hearts > 0)
        .take(3)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const Center(child: GameEmblem(icon: Icons.queue_music_rounded)),
        const SizedBox(height: 18),
        Text(
          plainLabel('game_ui.your_playlist'.tr()),
          textAlign: TextAlign.center,
          style: text.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          '${GamePlayers.name(1)} & ${GamePlayers.name(2)}',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: AppColors.mist),
        ),
        const SizedBox(height: 22),
        GameSurface(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            children: [
              _Stat('${_playlist.length}',
                  'games.soundtrack.songs_added'.tr()),
              _Stat('$hearts', 'games.soundtrack.total_hearts'.tr()),
            ],
          ),
        ),
        if (top.isNotEmpty) ...[
          const SizedBox(height: 24),
          GameSectionLabel('games.soundtrack.top_picks'.tr()),
          for (var i = 0; i < top.length; i++)
            _SongRow(song: top[i], number: i + 1, highlight: true),
        ],
        const SizedBox(height: 24),
        GameSectionLabel(
          'game_ui.songs_count'.tr(namedArgs: {'count': '${_playlist.length}'}),
        ),
        if (_playlist.isEmpty)
          Text(
            'game_ui.no_songs_added'.tr(),
            style: const TextStyle(fontSize: 13.5, color: AppColors.smoke),
          )
        else
          for (var i = 0; i < _playlist.length; i++)
            _SongRow(song: _playlist[i], number: i + 1),
        const SizedBox(height: 14),
        Text(
          plainLabel('games.soundtrack.closing'.tr()),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppTypography.displayFont,
            fontStyle: FontStyle.italic,
            fontSize: 15,
            color: AppColors.mist,
          ),
        ),
        const SizedBox(height: 26),
        if (_playlist.isNotEmpty) ...[
          GameSecondaryButton(
            label: 'games.soundtrack.copy_playlist'.tr(),
            icon: Icons.copy_rounded,
            onPressed: _copyPlaylist,
          ),
          const SizedBox(height: 10),
        ],
        GamePrimaryButton(
          label: 'game_ui.new_playlist'.tr(),
          icon: Icons.replay_rounded,
          onPressed: () => setState(() => _phase = _Phase.setup),
        ),
        const SizedBox(height: 6),
        Center(
          child: GameQuietButton(
            label: 'game_ui.exit'.tr(),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

class _SongRow extends StatelessWidget {
  final _Song song;
  final int number;
  final bool highlight;

  const _SongRow({
    required this.song,
    required this.number,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final reaction = _reaction(song.reaction);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$number',
              style: TextStyle(
                fontFamily: AppTypography.displayFont,
                fontFeatures: AppTypography.lining,
                fontSize: 17,
                color: highlight ? AppColors.champagne : AppColors.smoke,
              ),
            ),
          ),
          const _SongBadge(size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ivory,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    PlayerDot(player: song.addedBy, size: 6),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${song.artist} · ${song.theme.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.mist),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (reaction != null) ...[
            const SizedBox(width: 8),
            Icon(reaction.icon, size: 18, color: reaction.color),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTypography.displayFont,
              fontFeatures: AppTypography.lining,
              fontSize: 24,
              color: AppColors.ivory,
            ),
          ),
          Text(
            plainLabel(label),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.mist),
          ),
        ],
      ),
    );
  }
}

/// A quiet music-note tile beside each song (no album covers: they are
/// copyrighted artwork).
class _SongBadge extends StatelessWidget {
  final double size;

  const _SongBadge({this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GameTone.selectedBorder),
        color: GameTone.selectedFill,
      ),
      child: Icon(Icons.music_note_rounded,
          size: size * 0.42, color: GameTone.accentSoft),
    );
  }
}

class _SongText extends StatelessWidget {
  final SongResult song;

  const _SongText({required this.song});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          song.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.ivory,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          [song.artist, if (song.year != null) song.year].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.5, color: AppColors.mist),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final SongResult song;
  final VoidCallback onTap;

  const _ResultRow({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            const _SongBadge(),
            const SizedBox(width: 14),
            Expanded(child: _SongText(song: song)),
            const Icon(Icons.add_circle_outline_rounded,
                size: 20, color: AppColors.smoke),
          ],
        ),
      ),
    );
  }
}

class _SearchNote extends StatelessWidget {
  final String text;

  const _SearchNote(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.mist),
      ),
    );
  }
}
