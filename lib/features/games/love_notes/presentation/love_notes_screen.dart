import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../shared/utils/display_text.dart';
import '../../shared/game_kit.dart';

/// Love Notes: each round both partners secretly write a note on the same
/// prompt, passing the phone in between; at the end the notes are opened
/// and read together.
class LoveNotesScreen extends StatefulWidget {
  const LoveNotesScreen({super.key});

  @override
  State<LoveNotesScreen> createState() => _LoveNotesScreenState();
}

enum _Phase { setup, handoff, writing, reveal, results }

class _Note {
  final int round;
  final int player;
  final String prompt;
  final String text;

  const _Note(this.round, this.player, this.prompt, this.text);
}

const _categories = ['romantic', 'compliment', 'spicy'];

class _LoveNotesScreenState extends State<LoveNotesScreen> {
  final _session = GameSession();
  final _controller = TextEditingController();
  final List<_Note> _notes = [];

  _Phase _phase = _Phase.setup;
  String _category = 'romantic';
  int _totalRounds = 3;
  int _round = 1;
  int _writer = 1;
  String _prompt = '';
  bool _showEmptyError = false;
  ShuffleBag<String>? _prompts;

  @override
  void dispose() {
    _controller.dispose();
    _session.finish();
    super.dispose();
  }

  List<String> get _rules => [
        'games.love_notes.rule_1'.tr(),
        'games.love_notes.rule_2'.tr(),
        'games.love_notes.rule_3'.tr(),
        'games.love_notes.rule_4'.tr(),
      ];

  void _start() {
    _session.start();
    final prompts = localizedList('games.love_notes.prompts.$_category');
    setState(() {
      _prompts = ShuffleBag(prompts);
      _notes.clear();
      _round = 1;
      _writer = 1;
      _prompt = _prompts!.next();
      _phase = _Phase.handoff;
    });
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      HapticFeedback.lightImpact();
      setState(() => _showEmptyError = true);
      return;
    }
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    _notes.add(_Note(_round, _writer, _prompt, text));
    _controller.clear();
    setState(() {
      _showEmptyError = false;
      if (_writer == 1) {
        _writer = 2;
        _phase = _Phase.handoff;
      } else if (_round < _totalRounds) {
        _round++;
        _writer = 1;
        _prompt = _prompts!.next();
        _phase = _Phase.handoff;
      } else {
        _session.finish();
        _phase = _Phase.reveal;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inGame = _phase == _Phase.handoff || _phase == _Phase.writing;
    return GameScaffold(
      title: 'games.love_notes.title'.tr(),
      guardExit: inGame,
      onHelp: () => showGameRules(
        context,
        title: 'games.love_notes.rules_title'.tr(),
        rules: _rules,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey('$_phase$_round$_writer'),
          child: switch (_phase) {
            _Phase.setup => _buildSetup(),
            _Phase.handoff => GameHandoff(
                player: _writer,
                icon: Icons.edit_outlined,
                title: 'games.love_notes.handoff_title'
                    .tr(namedArgs: {'name': GamePlayers.name(_writer)}),
                message: 'games.love_notes.handoff_body'
                    .tr(namedArgs: {'other': GamePlayers.name(3 - _writer)}),
                action: 'game_ui.start_writing'.tr(),
                onContinue: () => setState(() => _phase = _Phase.writing),
              ),
            _Phase.writing => _buildWriting(),
            _Phase.reveal => GameHandoff(
                icon: Icons.mark_email_unread_outlined,
                title: 'games.love_notes.reveal_title'.tr(),
                message: 'games.love_notes.reveal_body'.tr(),
                action: 'games.love_notes.reveal_action'.tr(),
                onContinue: () => setState(() => _phase = _Phase.results),
              ),
            _Phase.results => _buildResults(),
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
          icon: Icons.mail_outline_rounded,
          title: 'games.love_notes.title'.tr(),
          subtitle: 'game_ui.write_secret_messages'.tr(),
        ),
        const SizedBox(height: 32),
        const GamePlayersCard(),
        const SizedBox(height: 28),
        GameSectionLabel('game_ui.category'.tr()),
        for (final c in _categories) ...[
          GameOptionTile(
            title: 'game_ui.${c}_cat'.tr(),
            subtitle: 'game_ui.${c}_desc'.tr(),
            icon: switch (c) {
              'romantic' => Icons.favorite_border_rounded,
              'compliment' => Icons.auto_awesome_outlined,
              _ => Icons.local_fire_department_outlined,
            },
            selected: _category == c,
            onTap: () => setState(() => _category = c),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 18),
        GameSectionLabel('game_ui.number_of_rounds'.tr()),
        GameSegmented<int>(
          values: const [3, 5, 7],
          selected: _totalRounds,
          numeric: true,
          label: (v) => '$v',
          onChanged: (v) => setState(() => _totalRounds = v),
        ),
        const SizedBox(height: 28),
        GameRulesCard(
            title: 'games.love_notes.rules_title'.tr(), rules: _rules),
        const SizedBox(height: 28),
        GamePrimaryButton(
          label: 'game_ui.start_writing'.tr(),
          icon: Icons.edit_outlined,
          onPressed: _start,
        ),
      ],
    );
  }

  // ── Writing ────────────────────────────────────────────────────────────

  Widget _buildWriting() {
    final text = Theme.of(context).textTheme;
    final last = _writer == 2 && _round >= _totalRounds;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        GameTurnBanner(
          player: _writer,
          trailing: 'game_ui.round_of'
              .tr(namedArgs: {'current': '$_round', 'total': '$_totalRounds'}),
        ),
        const SizedBox(height: 22),
        Text(
          plainLabel('games.love_notes.prompt'.tr()).toUpperCase(),
          textAlign: TextAlign.center,
          style: AppTypography.eyebrow.copyWith(
            color: GameTone.accentSoft,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _prompt,
          textAlign: TextAlign.center,
          style: text.headlineSmall?.copyWith(height: 1.3),
        ),
        const SizedBox(height: 22),
        TextField(
          controller: _controller,
          minLines: 6,
          maxLines: 10,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) {
            if (_showEmptyError) setState(() => _showEmptyError = false);
          },
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            color: AppColors.ivory,
          ),
          decoration: InputDecoration(
            hintText: plainLabel('games.love_notes.write'.tr()),
            fillColor: AppColors.inkRaised.withOpacity(0.85),
            errorText: _showEmptyError ? plainLabel('game_ui.write_first'.tr()) : null,
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
        const SizedBox(height: 18),
        GamePrimaryButton(
          label: last
              ? 'game_ui.send_note'.tr()
              : 'games.love_notes.send_to'
                  .tr(namedArgs: {'name': GamePlayers.name(3 - _writer)}),
          icon: Icons.send_rounded,
          onPressed: _submit,
        ),
      ],
    );
  }

  // ── Results ────────────────────────────────────────────────────────────

  Widget _buildResults() {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          plainLabel('game_ui.your_love_notes'.tr()),
          textAlign: TextAlign.center,
          style: text.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          plainLabel('game_ui.read_together'.tr()),
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: AppColors.mist),
        ),
        const SizedBox(height: 24),
        for (var r = 1; r <= _totalRounds; r++) ...[
          _RoundNotes(notes: _notes.where((n) => n.round == r).toList()),
          const SizedBox(height: 14),
        ],
        const SizedBox(height: 18),
        GamePrimaryButton(
          label: 'game_ui.play_again'.tr(),
          icon: Icons.replay_rounded,
          onPressed: () => setState(() => _phase = _Phase.setup),
        ),
        const SizedBox(height: 6),
        Center(
          child: GameQuietButton(
            label: 'game_ui.end'.tr(),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

class _RoundNotes extends StatelessWidget {
  final List<_Note> notes;

  const _RoundNotes({required this.notes});

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();
    return GameSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notes.first.prompt,
            style: const TextStyle(
              fontFamily: AppTypography.displayFont,
              fontSize: 17,
              fontStyle: FontStyle.italic,
              height: 1.35,
              color: AppColors.mist,
            ),
          ),
          for (final n in notes) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                PlayerDot(player: n.player, size: 7),
                const SizedBox(width: 8),
                Text(
                  GamePlayers.name(n.player),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: GamePlayers.color(n.player),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              n.text,
              style: const TextStyle(
                fontSize: 15.5,
                height: 1.5,
                color: AppColors.ivory,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
