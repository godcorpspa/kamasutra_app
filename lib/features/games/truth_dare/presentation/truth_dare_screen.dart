import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../data/models/game.dart';
import '../../../../shared/utils/display_text.dart';
import '../../shared/game_kit.dart';
import '../data/truth_dare_actions.dart';

/// Truth or Dare: the players take turns choosing a truth or a dare at the
/// chosen intensity. Cards never repeat until the pile has been played.
class TruthDareScreen extends StatefulWidget {
  const TruthDareScreen({super.key});

  @override
  State<TruthDareScreen> createState() => _TruthDareScreenState();
}

class _TruthDareScreenState extends State<TruthDareScreen> {
  final _deck = TruthDareDeck();
  final _session = GameSession();

  GameIntensity _intensity = GameIntensity.soft;
  bool _playing = false;
  int _turn = 0; // completed turns; player 1 starts
  bool? _isTruth;
  String? _card;

  int get _player => _turn.isEven ? 1 : 2;
  int get _round => _turn ~/ 2 + 1;

  @override
  void dispose() {
    _session.finish();
    super.dispose();
  }

  String _intensityKey(GameIntensity i) => switch (i) {
        GameIntensity.soft => 'soft',
        GameIntensity.spicy => 'spicy',
        GameIntensity.extraSpicy => 'extra_spicy',
      };

  String _intensityLabel(GameIntensity i) => switch (i) {
        GameIntensity.soft => 'truth_dare_ui.intensity_soft'.tr(),
        GameIntensity.spicy => 'truth_dare_ui.intensity_spicy'.tr(),
        GameIntensity.extraSpicy => 'truth_dare_ui.intensity_extra'.tr(),
      };

  String _intensityDesc(GameIntensity i) => switch (i) {
        GameIntensity.soft => 'truth_dare_ui.desc_soft'.tr(),
        GameIntensity.spicy => 'truth_dare_ui.desc_spicy'.tr(),
        GameIntensity.extraSpicy => 'truth_dare_ui.desc_extra'.tr(),
      };

  Color _intensityColor(GameIntensity i) => switch (i) {
        GameIntensity.soft => AppColors.soft,
        GameIntensity.spicy => AppColors.spicy,
        GameIntensity.extraSpicy => AppColors.extraSpicy,
      };

  List<String> get _rules => [
        'truth_dare_ui.rule_1'.tr(),
        'truth_dare_ui.rule_2'.tr(),
        'truth_dare_ui.rule_3'.tr(),
      ];

  void _start() {
    setState(() {
      _playing = true;
      _turn = 0;
      _card = null;
      _isTruth = null;
    });
  }

  void _draw(bool truth) {
    HapticFeedback.mediumImpact();
    _session.start();
    setState(() {
      _isTruth = truth;
      _card = _deck.draw(truth: truth, intensity: _intensityKey(_intensity));
    });
  }

  void _next() {
    HapticFeedback.lightImpact();
    setState(() {
      _turn++;
      _card = null;
      _isTruth = null;
    });
  }

  void _end() {
    _session.finish();
    setState(() {
      _playing = false;
      _card = null;
      _isTruth = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'truth_dare_ui.title'.tr(),
      onHelp: () => showGameRules(
        context,
        title: 'truth_dare_ui.how_to_play'.tr(),
        rules: _rules,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _playing ? _buildGame() : _buildSetup(),
      ),
    );
  }

  // ── Setup ──────────────────────────────────────────────────────────────

  Widget _buildSetup() {
    return ListView(
      key: const ValueKey('setup'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        GameHero(
          icon: Icons.theater_comedy_outlined,
          title: 'truth_dare_ui.title'.tr(),
          subtitle: 'truth_dare_ui.subtitle_setup'.tr(),
        ),
        const SizedBox(height: 32),
        const GamePlayersCard(),
        const SizedBox(height: 28),
        GameSectionLabel('truth_dare_ui.choose_intensity'.tr()),
        for (final i in GameIntensity.values) ...[
          GameOptionTile(
            title: _intensityLabel(i),
            subtitle: _intensityDesc(i),
            dot: _intensityColor(i),
            selected: _intensity == i,
            onTap: () => setState(() => _intensity = i),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 18),
        GameRulesCard(title: 'truth_dare_ui.how_to_play'.tr(), rules: _rules),
        const SizedBox(height: 28),
        GamePrimaryButton(
          label: 'game_ui.start_playing'.tr(),
          icon: Icons.play_arrow_rounded,
          onPressed: _start,
        ),
      ],
    );
  }

  // ── Game ───────────────────────────────────────────────────────────────

  Widget _buildGame() {
    return Padding(
      key: const ValueKey('game'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          GameTurnBanner(
            player: _player,
            trailing: '${'truth_dare_ui.round_n'.tr(namedArgs: {'n': '$_round'})}'
                ' · ${plainLabel(_intensityLabel(_intensity))}',
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween(begin: 0.96, end: 1.0).animate(animation),
                  child: child,
                ),
              ),
              child: _card == null ? _buildChoice() : _buildCard(),
            ),
          ),
          GameQuietButton(
            label: 'truth_dare_ui.end_game'.tr(),
            onPressed: _end,
          ),
        ],
      ),
    );
  }

  Widget _buildChoice() {
    final text = Theme.of(context).textTheme;
    return Column(
      key: ValueKey('choice$_turn'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          plainLabel('truth_dare_ui.what_choose'.tr()),
          textAlign: TextAlign.center,
          style: text.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          plainLabel('truth_dare_ui.tap_card'.tr()),
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: AppColors.mist),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _ChoiceCard(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'games.truth_dare.truth'.tr(),
                caption: 'truth_dare_ui.truth_sub'.tr(),
                onTap: () => _draw(true),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _ChoiceCard(
                icon: Icons.local_fire_department_outlined,
                label: 'games.truth_dare.dare'.tr(),
                caption: 'truth_dare_ui.dare_sub'.tr(),
                onTap: () => _draw(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCard() {
    final truth = _isTruth ?? true;
    return Column(
      key: ValueKey(_card),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GameSurface(
          highlighted: true,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(
            children: [
              Icon(
                truth
                    ? Icons.chat_bubble_outline_rounded
                    : Icons.local_fire_department_outlined,
                size: 22,
                color: GameTone.accentSoft,
              ),
              const SizedBox(height: 10),
              Text(
                plainLabel(truth
                        ? 'games.truth_dare.truth'.tr()
                        : 'games.truth_dare.dare'.tr())
                    .toUpperCase(),
                style: AppTypography.eyebrow.copyWith(
                  color: GameTone.accentSoft,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                _card!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTypography.displayFont,
                  fontFeatures: AppTypography.lining,
                  fontSize: 23,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                  color: AppColors.ivory,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        GamePrimaryButton(
          label: 'truth_dare_ui.done_next'.tr(),
          icon: Icons.check_rounded,
          onPressed: _next,
        ),
        const SizedBox(height: 12),
        GameSecondaryButton(
          label: 'truth_dare_ui.change'.tr(),
          icon: Icons.refresh_rounded,
          onPressed: () => _draw(truth),
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: GameTone.selectedBorder),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                GameTone.accent.withOpacity(0.14),
                AppColors.inkRaised.withOpacity(0.85),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: GameTone.selectedBorder),
                  ),
                  child: Icon(icon, color: GameTone.accentSoft, size: 24),
                ),
                const SizedBox(height: 18),
                Text(
                  plainLabel(label),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  plainLabel(caption),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.mist),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
