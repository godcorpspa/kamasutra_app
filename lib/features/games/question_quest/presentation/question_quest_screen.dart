import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../shared/utils/display_text.dart';
import '../../shared/game_kit.dart';

/// Question Quest: the partners take turns drawing a question at the chosen
/// depth and answering it. Answers grow a shared connection score (deeper
/// questions count more, a "you surprised me" answer triples it); there is
/// no winner. Favourite questions are collected for the end.
class QuestionQuestScreen extends StatefulWidget {
  const QuestionQuestScreen({super.key});

  @override
  State<QuestionQuestScreen> createState() => _QuestionQuestScreenState();
}

enum _Phase { setup, playing, finished }

class _Question {
  final String category;
  final String text;

  const _Question(this.category, this.text);
}

const _questionCategories = [
  'dreams',
  'memories',
  'desires',
  'fears',
  'future',
  'intimacy',
];

const _depths = {
  'light': (Icons.wb_sunny_outlined, 1),
  'medium': (Icons.waves_outlined, 2),
  'deep': (Icons.nights_stay_outlined, 3),
};

const _questionsPerTopic = 6;
const _timerSeconds = 60;

class _QuestionQuestScreenState extends State<QuestionQuestScreen> {
  final _session = GameSession();
  final _random = Random();
  late final GameCountdown _countdown = GameCountdown(
    onTick: () {
      if (mounted) setState(() {});
    },
    onDone: () => _answer(0),
  );

  _Phase _phase = _Phase.setup;
  String _category = 'all';
  String _depth = 'medium';
  bool _timerOn = false;

  List<_Question> _questions = [];
  int _index = 0;
  int _firstPlayer = 1;
  bool _revealed = false;
  int _points = 0;
  int _answered = 0;
  int _surprises = 0;
  int _skipped = 0;
  final Set<int> _favourites = {};

  int get _player => _index.isEven ? _firstPlayer : 3 - _firstPlayer;
  int get _multiplier => _depths[_depth]!.$2;

  @override
  void dispose() {
    _countdown.cancel();
    _session.finish();
    super.dispose();
  }

  List<String> get _rules => [
        'games.question_quest.rule_1'.tr(),
        'games.question_quest.rule_2'.tr(),
        'games.question_quest.rule_3'.tr(),
        'games.question_quest.rule_4'.tr(),
        'games.question_quest.rule_5'.tr(),
      ];

  List<_Question> _loadQuestions() {
    final topics =
        _category == 'all' ? _questionCategories : [_category];
    final all = [
      for (final c in topics)
        for (var i = 1; i <= _questionsPerTopic; i++)
          _Question(c, 'games.question_quest.q_${_depth}_${c}_$i'.tr()),
    ]..shuffle(_random);
    return all.take(12).toList();
  }

  void _start() {
    _session.start();
    setState(() {
      _questions = _loadQuestions();
      _index = 0;
      _firstPlayer = _random.nextInt(2) + 1;
      _revealed = false;
      _points = 0;
      _answered = 0;
      _surprises = 0;
      _skipped = 0;
      _favourites.clear();
      _phase = _Phase.playing;
    });
  }

  void _reveal() {
    HapticFeedback.mediumImpact();
    setState(() => _revealed = true);
    if (_timerOn) _countdown.start(_timerSeconds);
  }

  /// 0 = skipped, 1 = answered, 2 = answered and surprised the partner.
  void _answer(int level) {
    _countdown.cancel();
    HapticFeedback.mediumImpact();
    setState(() {
      switch (level) {
        case 0:
          _skipped++;
        case 1:
          _answered++;
          _points += _multiplier;
        default:
          _answered++;
          _surprises++;
          _points += 3 * _multiplier;
      }
      if (_index < _questions.length - 1) {
        _index++;
        _revealed = false;
      } else {
        _session.finish();
        _phase = _Phase.finished;
      }
    });
  }

  void _toggleFavourite() {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_favourites.remove(_index)) _favourites.add(_index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'games.question_quest.title'.tr(),
      guardExit: _phase == _Phase.playing,
      onHelp: () => showGameRules(
        context,
        title: 'game_ui.how_to_play'.tr(),
        rules: _rules,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey('$_phase$_index$_revealed'),
          child: switch (_phase) {
            _Phase.setup => _buildSetup(),
            _Phase.playing => _buildQuestion(),
            _Phase.finished => _buildFinale(),
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
          icon: Icons.forum_outlined,
          title: 'games.question_quest.title'.tr(),
          subtitle: 'games.question_quest.subtitle'.tr(),
        ),
        const SizedBox(height: 32),
        const GamePlayersCard(),
        const SizedBox(height: 28),
        GameSectionLabel('games.question_quest.depth_label'.tr()),
        for (final d in _depths.entries) ...[
          GameOptionTile(
            title: 'games.question_quest.depth_${d.key}'.tr(),
            subtitle: 'games.question_quest.depth_${d.key}_desc'.tr(),
            icon: d.value.$1,
            badge: '×${d.value.$2}',
            selected: _depth == d.key,
            onTap: () => setState(() => _depth = d.key),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 18),
        GameSectionLabel('games.question_quest.category_label'.tr()),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in ['all', ..._questionCategories])
              _Pill(
                label: 'games.question_quest.cat_$c'.tr(),
                selected: _category == c,
                onTap: () => setState(() => _category = c),
              ),
          ],
        ),
        const SizedBox(height: 28),
        GameSectionLabel('games.question_quest.timer_optional'.tr()),
        GameSegmented<bool>(
          values: const [false, true],
          selected: _timerOn,
          label: (on) => on
              ? 'games.question_quest.timer_on'.tr()
              : 'games.question_quest.timer_off'.tr(),
          onChanged: (on) => setState(() => _timerOn = on),
        ),
        const SizedBox(height: 28),
        GameRulesCard(title: 'game_ui.how_to_play'.tr(), rules: _rules),
        const SizedBox(height: 28),
        GamePrimaryButton(
          label: 'games.question_quest.start_journey'.tr(),
          icon: Icons.play_arrow_rounded,
          onPressed: _start,
        ),
      ],
    );
  }

  // ── Question ───────────────────────────────────────────────────────────

  Widget _buildQuestion() {
    final text = Theme.of(context).textTheme;
    final q = _questions[_index];
    final favourite = _favourites.contains(_index);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          GameTurnBanner(
            player: _player,
            caption: 'games.question_quest.answering'.tr(),
            trailing: 'game_ui.question_of'.tr(namedArgs: {
              'current': '${_index + 1}',
              'total': '${_questions.length}',
            }),
          ),
          const SizedBox(height: 12),
          GameProgressBar(value: _index / _questions.length),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.favorite_border_rounded,
                  size: 14, color: AppColors.champagne),
              const SizedBox(width: 6),
              Text(
                '${plainLabel('games.question_quest.connection'.tr())}  $_points',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontFeatures: AppTypography.lining,
                  color: AppColors.mist,
                ),
              ),
              const Spacer(),
              if (_revealed && _timerOn)
                Text(
                  formatSeconds(_countdown.remaining),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFeatures: AppTypography.lining,
                    color: _countdown.remaining <= 10
                        ? AppColors.rose
                        : AppColors.ivory,
                  ),
                ),
            ],
          ),
          Expanded(
            child: Center(
              child: _revealed
                  ? GameSurface(
                      highlighted: true,
                      padding: const EdgeInsets.fromLTRB(24, 18, 12, 30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 36),
                              Expanded(
                                child: Text(
                                  '${'games.question_quest.cat_${q.category}'.tr()} · '
                                          '${'games.question_quest.depth_$_depth'.tr()}'
                                      .toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: AppTypography.eyebrow.copyWith(
                                    fontSize: 10,
                                    color: GameTone.accentSoft,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _toggleFavourite,
                                tooltip: plainLabel(
                                    'games.question_quest.feature_bookmark'
                                        .tr()),
                                icon: Icon(
                                  favourite
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: favourite
                                      ? AppColors.champagne
                                      : AppColors.smoke,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(
                              q.text,
                              textAlign: TextAlign.center,
                              style: text.headlineSmall?.copyWith(height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _CardBack(onTap: _reveal),
            ),
          ),
          if (_revealed) ...[
            GamePrimaryButton(
              label: 'games.question_quest.answered'.tr(),
              icon: Icons.check_rounded,
              onPressed: () => _answer(1),
            ),
            const SizedBox(height: 10),
            GameSecondaryButton(
              label: 'games.question_quest.surprise_reaction'.tr(),
              icon: Icons.auto_awesome_outlined,
              onPressed: () => _answer(2),
            ),
          ] else
            GamePrimaryButton(
              label: 'games.question_quest.tap_to_reveal'.tr(),
              icon: Icons.visibility_outlined,
              onPressed: _reveal,
            ),
          GameQuietButton(
            label: 'games.question_quest.skip'.tr(),
            icon: Icons.skip_next_rounded,
            onPressed: () => _answer(0),
          ),
        ],
      ),
    );
  }

  // ── Finale ─────────────────────────────────────────────────────────────

  Widget _buildFinale() {
    final max = 3 * _multiplier * _questions.length;
    final ratio = max == 0 ? 0.0 : (_points / max).clamp(0.0, 1.0);
    final message = ratio > 0.7
        ? 'games.question_quest.connection_message_high'
        : ratio > 0.4
            ? 'games.question_quest.connection_message_mid'
            : 'games.question_quest.connection_message_low';
    final favourites = [
      for (final i in _favourites.toList()..sort()) _questions[i].text,
    ];
    return GameFinale(
      icon: Icons.favorite_border_rounded,
      title: 'games.question_quest.journey_complete'.tr(),
      subtitle: message.tr(),
      onPlayAgain: () => setState(() => _phase = _Phase.setup),
      onExit: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GameSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plainLabel(
                            'games.question_quest.connection_level'.tr()),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.mist),
                      ),
                    ),
                    Text(
                      '${(ratio * 100).round()}%',
                      style: const TextStyle(
                        fontFamily: AppTypography.displayFont,
                        fontFeatures: AppTypography.lining,
                        fontSize: 22,
                        color: AppColors.ivory,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GameProgressBar(value: ratio),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _Stat('$_answered',
                        'games.question_quest.revealed_count'.tr()),
                    _Stat('$_surprises',
                        'games.question_quest.surprise_count'.tr()),
                    _Stat('$_skipped',
                        'games.question_quest.skipped_count'.tr()),
                  ],
                ),
              ],
            ),
          ),
          if (favourites.isNotEmpty) ...[
            const SizedBox(height: 22),
            GameSectionLabel(
                'games.question_quest.bookmarked_questions'.tr()),
            for (final f in favourites)
              Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.star_rounded,
                          size: 16, color: AppColors.champagne),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        f,
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.4,
                          color: AppColors.ivory,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 8),
          Text(
            plainLabel('games.question_quest.closing'.tr()),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTypography.displayFont,
              fontStyle: FontStyle.italic,
              fontSize: 15,
              color: AppColors.mist,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  final VoidCallback onTap;

  const _CardBack({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 0.78,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: GameTone.selectedBorder),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                GameTone.accent.withOpacity(0.16),
                AppColors.inkRaised.withOpacity(0.9),
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.hairline),
                    ),
                  ),
                ),
              ),
              const GameEmblem(icon: Icons.question_mark_rounded, size: 84),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.round),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? GameTone.selectedFill : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.round),
            border: Border.all(
              color: selected ? GameTone.selectedBorder : AppColors.outline,
            ),
          ),
          child: Text(
            plainLabel(label),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.ivory : AppColors.mist,
            ),
          ),
        ),
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
              fontSize: 22,
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
