import 'dart:convert';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../data/services/preferences_service.dart';
import '../../../../shared/utils/display_text.dart';
import '../../shared/game_kit.dart';

/// Fantasy Builder: the partners take turns picking the elements of a
/// fantasy (place, mood, main action, surprise), each can veto one pick of
/// the other, and a secret theme is drawn at the end. Fantasies can be
/// saved with when the couple wants to make them real.
class FantasyBuilderScreen extends StatefulWidget {
  const FantasyBuilderScreen({super.key});

  @override
  State<FantasyBuilderScreen> createState() => _FantasyBuilderScreenState();
}

class _Option {
  final String value;
  final IconData icon;

  const _Option(this.value, this.icon);
}

const _settings = [
  _Option('beach_sunset', Icons.beach_access_outlined),
  _Option('mountain_cabin', Icons.cabin_outlined),
  _Option('candlelit_room', Icons.bedroom_parent_outlined),
  _Option('rooftop_city', Icons.location_city_outlined),
  _Option('forest_clearing', Icons.forest_outlined),
  _Option('luxury_hotel', Icons.hotel_outlined),
  _Option('private_pool', Icons.pool_outlined),
  _Option('vintage_train', Icons.train_outlined),
];

const _moods = [
  _Option('romantic', Icons.favorite_border_rounded),
  _Option('playful', Icons.sentiment_satisfied_alt_outlined),
  _Option('passionate', Icons.local_fire_department_outlined),
  _Option('mysterious', Icons.theater_comedy_outlined),
  _Option('adventurous', Icons.bolt_outlined),
  _Option('tender', Icons.spa_outlined),
];

const _softActions = [
  _Option('massage', Icons.spa_outlined),
  _Option('dance', Icons.music_note_outlined),
  _Option('bath', Icons.bathtub_outlined),
  _Option('stargazing', Icons.star_outline_rounded),
  _Option('cooking', Icons.restaurant_outlined),
  _Option('reading', Icons.menu_book_outlined),
];

const _spicyActions = [
  _Option('blindfold', Icons.visibility_off_outlined),
  _Option('roleplay', Icons.theater_comedy_outlined),
  _Option('ice_game', Icons.ac_unit_rounded),
  _Option('feather', Icons.gesture_rounded),
  _Option('oil_massage', Icons.water_drop_outlined),
  _Option('strip_game', Icons.casino_outlined),
];

const _surprises = [
  _Option('music', Icons.queue_music_rounded),
  _Option('champagne', Icons.wine_bar_outlined),
  _Option('chocolate', Icons.cake_outlined),
  _Option('flowers', Icons.local_florist_outlined),
  _Option('lingerie', Icons.checkroom_outlined),
  _Option('letter', Icons.mail_outline_rounded),
  _Option('perfume', Icons.auto_awesome_outlined),
  _Option('game', Icons.extension_outlined),
];

const _themes = [
  _Option('theme_whispers', Icons.record_voice_over_outlined),
  _Option('theme_mirror', Icons.flip_outlined),
  _Option('theme_mystery', Icons.theater_comedy_outlined),
  _Option('theme_moon', Icons.nightlight_outlined),
  _Option('theme_velvet', Icons.texture_rounded),
  _Option('theme_audacity', Icons.bolt_outlined),
  _Option('theme_kiss', Icons.favorite_border_rounded),
  _Option('theme_eternity', Icons.all_inclusive_rounded),
];

const _whenOptions = [
  _Option('tonight', Icons.nightlight_outlined),
  _Option('this_weekend', Icons.event_outlined),
  _Option('special_occasion', Icons.celebration_outlined),
  _Option('just_fantasy', Icons.cloud_outlined),
];

/// The four picked steps, in order: (translation group, options).
const _pickSteps = ['settings', 'moods', 'actions', 'surprises'];

String _label(String group, String value) =>
    'games.fantasy_builder.$group.$value'.tr();

/// A finished fantasy, as saved on the device.
class _Fantasy {
  final String setting;
  final String mood;
  final String action;
  final String actionGroup;
  final String surprise;
  final List<String> details;
  final String theme;
  final String? when;
  final DateTime createdAt;

  const _Fantasy({
    required this.setting,
    required this.mood,
    required this.action,
    required this.actionGroup,
    required this.surprise,
    required this.details,
    required this.theme,
    required this.when,
    required this.createdAt,
  });

  Map<String, Object?> toJson() => {
        'setting': setting,
        'mood': mood,
        'action': action,
        'actionGroup': actionGroup,
        'surprise': surprise,
        'details': details,
        'theme': theme,
        'when': when,
        'createdAt': createdAt.toIso8601String(),
      };

  static _Fantasy? fromJson(Map<String, dynamic> j) {
    try {
      return _Fantasy(
        setting: j['setting'] as String,
        mood: j['mood'] as String,
        action: j['action'] as String,
        actionGroup: j['actionGroup'] as String,
        surprise: j['surprise'] as String,
        details: (j['details'] as List).cast<String>(),
        theme: j['theme'] as String,
        when: j['when'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }
}

class _FantasyStore {
  static const _key = 'fantasy_builder_saved';
  static const _max = 20;

  static List<_Fantasy> load() {
    final raw = PreferencesService.instance.getStringList(_key) ?? const [];
    return [
      for (final s in raw)
        if (_decode(s) case final f?) f,
    ];
  }

  static _Fantasy? _decode(String s) {
    try {
      return _Fantasy.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(List<_Fantasy> list) =>
      PreferencesService.instance.setStringList(
        _key,
        [for (final f in list.take(_max)) jsonEncode(f.toJson())],
      );
}

enum _Phase { setup, build, reveal }

class _FantasyBuilderScreenState extends State<FantasyBuilderScreen> {
  final _session = GameSession();
  final _random = Random();
  final _detailController = TextEditingController();
  late List<_Fantasy> _saved = _FantasyStore.load();

  _Phase _phase = _Phase.setup;
  String _intensity = 'spicy';
  int _step = 0; // 0..3 picks, 4 = details
  int _firstPlayer = 1;
  final List<String?> _picks = [null, null, null, null];
  final List<String> _details = [];
  final _vetoUsed = [false, false];
  bool _justVetoed = false;
  String _theme = _themes.first.value;
  String? _when;
  bool _savedThis = false;

  int get _chooser => _step.isEven ? _firstPlayer : 3 - _firstPlayer;
  int get _other => 3 - _chooser;

  String get _actionGroup =>
      _intensity == 'soft' ? 'actions_soft' : 'actions_spicy';

  List<_Option> _optionsFor(int step) => switch (step) {
        0 => _settings,
        1 => _moods,
        2 => _intensity == 'soft' ? _softActions : _spicyActions,
        _ => _surprises,
      };

  String _groupFor(int step) =>
      step == 2 ? _actionGroup : _pickSteps[step];

  List<String> get _stepTitles => [
        'games.fantasy_builder.steps.setting'.tr(),
        'games.fantasy_builder.steps.atmosphere'.tr(),
        'games.fantasy_builder.steps.main_action'.tr(),
        'games.fantasy_builder.steps.surprise'.tr(),
        'games.fantasy_builder.steps.final_details'.tr(),
      ];

  List<String> get _rules => [
        'games.fantasy_builder.rules.rule_1'.tr(),
        'games.fantasy_builder.rules.rule_2'.tr(),
        'games.fantasy_builder.rules.rule_3'.tr(),
        'games.fantasy_builder.rules.rule_4'.tr(),
      ];

  @override
  void dispose() {
    _detailController.dispose();
    _session.finish();
    super.dispose();
  }

  void _start() {
    _session.start();
    setState(() {
      _phase = _Phase.build;
      _step = 0;
      _firstPlayer = _random.nextInt(2) + 1;
      _picks.fillRange(0, 4, null);
      _details.clear();
      _vetoUsed.fillRange(0, 2, false);
      _justVetoed = false;
      _when = null;
      _savedThis = false;
    });
  }

  void _pick(String value) => setState(() {
        _picks[_step] = value;
        _justVetoed = false;
      });

  void _randomPick() {
    HapticFeedback.mediumImpact();
    final options = _optionsFor(_step).map((o) => o.value).toList()
      ..remove(_picks[_step]);
    _pick(options[_random.nextInt(options.length)]);
  }

  void _veto() {
    HapticFeedback.heavyImpact();
    setState(() {
      _vetoUsed[_other - 1] = true;
      _picks[_step] = null;
      _justVetoed = true;
    });
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_step < 4) {
      setState(() {
        _step++;
        _justVetoed = false;
      });
      return;
    }
    _addDetail();
    _session.finish();
    setState(() {
      _theme = _themes[_random.nextInt(_themes.length)].value;
      _phase = _Phase.reveal;
    });
  }

  void _back() {
    if (_step == 0) return;
    setState(() {
      _step--;
      _justVetoed = false;
    });
  }

  void _addDetail([String? preset]) {
    final text = (preset ?? _detailController.text).trim();
    if (text.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (!_details.contains(text)) _details.add(text);
      if (preset == null) _detailController.clear();
    });
  }

  Future<void> _saveFantasy() async {
    HapticFeedback.mediumImpact();
    final fantasy = _Fantasy(
      setting: _picks[0]!,
      mood: _picks[1]!,
      action: _picks[2]!,
      actionGroup: _actionGroup,
      surprise: _picks[3]!,
      details: List.of(_details),
      theme: _theme,
      when: _when,
      createdAt: DateTime.now(),
    );
    setState(() {
      _saved = [fantasy, ..._saved];
      _savedThis = true;
    });
    await _FantasyStore.save(_saved);
  }

  Future<void> _deleteSaved(_Fantasy f) async {
    setState(() => _saved = [..._saved]..remove(f));
    await _FantasyStore.save(_saved);
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'games.fantasy_builder.title'.tr(),
      guardExit: _phase == _Phase.build,
      onHelp: () => showGameRules(
        context,
        title: 'game_ui.how_it_works'.tr(),
        rules: _rules,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey('$_phase$_step'),
          child: switch (_phase) {
            _Phase.setup => _buildSetup(),
            _Phase.build => _step < 4 ? _buildPickStep() : _buildDetailsStep(),
            _Phase.reveal => _buildReveal(),
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
          icon: Icons.auto_awesome_outlined,
          title: 'games.fantasy_builder.title'.tr(),
          subtitle: 'game_ui.build_perfect_fantasy'.tr(),
        ),
        const SizedBox(height: 32),
        const GamePlayersCard(),
        const SizedBox(height: 28),
        GameSectionLabel('game_ui.intensity'.tr()),
        GameOptionTile(
          title: 'game_ui.soft_label'.tr(),
          subtitle: 'game_ui.sweet_romantic'.tr(),
          dot: AppColors.soft,
          selected: _intensity == 'soft',
          onTap: () => setState(() => _intensity = 'soft'),
        ),
        const SizedBox(height: 10),
        GameOptionTile(
          title: 'game_ui.spicy_label'.tr(),
          subtitle: 'game_ui.passionate'.tr(),
          dot: AppColors.spicy,
          selected: _intensity == 'spicy',
          onTap: () => setState(() => _intensity = 'spicy'),
        ),
        const SizedBox(height: 28),
        GameRulesCard(
          title: 'game_ui.how_it_works'.tr(),
          rules: [
            'game_ui.how_it_works_description'.tr(),
            'games.fantasy_builder.feature_random'.tr(),
            'games.fantasy_builder.feature_veto'.tr(),
            'games.fantasy_builder.feature_secret'.tr(),
          ],
        ),
        if (_saved.isNotEmpty) ...[
          const SizedBox(height: 28),
          GameSectionLabel('games.fantasy_builder.previous_fantasies'.tr()),
          for (final f in _saved.take(5)) ...[
            _SavedFantasyTile(fantasy: f, onDelete: () => _deleteSaved(f)),
            const SizedBox(height: 8),
          ],
        ],
        const SizedBox(height: 28),
        GamePrimaryButton(
          label: 'game_ui.start_creating'.tr(),
          icon: Icons.auto_awesome_outlined,
          onPressed: _start,
        ),
      ],
    );
  }

  // ── Building ───────────────────────────────────────────────────────────

  Widget _stepHeader() {
    return Column(
      children: [
        GameTurnBanner(
          player: _chooser,
          caption: 'games.fantasy_builder.chooses'.tr(),
          trailing: '${_step + 1}/5',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (var i = 0; i < 5; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: i <= _step ? GameTone.cta : null,
                    color: i <= _step ? null : AppColors.hairline,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        Text(
          _stepTitles[_step],
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }

  Widget _buildPickStep() {
    final options = _optionsFor(_step);
    final group = _groupFor(_step);
    final selected = _picks[_step];
    final canVeto = selected != null && !_vetoUsed[_other - 1];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          _stepHeader(),
          if (_justVetoed) ...[
            const SizedBox(height: 6),
            Text(
              'games.fantasy_builder.vetoed_by'
                  .tr(namedArgs: {'name': GamePlayers.name(_other)}),
              style: const TextStyle(fontSize: 12.5, color: AppColors.rose),
            ),
          ],
          const SizedBox(height: 14),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                for (final o in options)
                  _OptionCard(
                    icon: o.icon,
                    label: _label(group, o.value),
                    selected: selected == o.value,
                    onTap: () => _pick(o.value),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _randomPick,
                  icon: const Icon(Icons.shuffle_rounded, size: 18),
                  label: Text(
                    plainLabel('games.fantasy_builder.random_pick'.tr()),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canVeto ? _veto : null,
                  icon: const Icon(Icons.front_hand_outlined, size: 18),
                  label: Text(
                    _vetoUsed[_other - 1]
                        ? plainLabel('games.fantasy_builder.veto_used'.tr())
                        : 'games.fantasy_builder.veto_by'
                            .tr(namedArgs: {'name': GamePlayers.name(_other)}),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.rose,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _navRow(
            canProceed: selected != null,
            nextLabel: 'game_ui.confirm_and_pass'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _navRow({required bool canProceed, required String nextLabel}) {
    return Row(
      children: [
        if (_step > 0) ...[
          IconButton.outlined(
            onPressed: _back,
            tooltip: plainLabel('common.back'.tr()),
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            style: IconButton.styleFrom(
              side: const BorderSide(color: AppColors.outline),
              padding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: GamePrimaryButton(
            label: nextLabel,
            icon: Icons.arrow_forward_rounded,
            onPressed: canProceed ? _next : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    final chips = [
      for (var i = 1; i <= 6; i++) 'games.fantasy_builder.detail_chip_$i'.tr(),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          _stepHeader(),
          const SizedBox(height: 8),
          Text(
            plainLabel('game_ui.add_special_details'.tr()),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: AppColors.mist),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              children: [
                TextField(
                  controller: _detailController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 40,
                  onSubmitted: (_) => _addDetail(),
                  style: const TextStyle(color: AppColors.ivory),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: plainLabel('game_ui.detail_hint'.tr()),
                    fillColor: AppColors.inkRaised.withOpacity(0.85),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_rounded,
                          color: GameTone.accentSoft),
                      onPressed: _addDetail,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in chips)
                      FilterChip(
                        label: Text(c),
                        selected: _details.contains(c),
                        onSelected: (on) => on
                            ? _addDetail(c)
                            : setState(() => _details.remove(c)),
                        showCheckmark: false,
                        selectedColor: GameTone.selectedFill,
                        side: BorderSide(
                          color: _details.contains(c)
                              ? GameTone.selectedBorder
                              : AppColors.hairline,
                        ),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          color: _details.contains(c)
                              ? AppColors.ivory
                              : AppColors.mist,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                if (_details.isEmpty)
                  Text(
                    plainLabel('games.fantasy_builder.no_details_yet'.tr()),
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(fontSize: 12.5, color: AppColors.smoke),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final d in _details.where((d) => !chips.contains(d)))
                        InputChip(
                          label: Text(d),
                          onDeleted: () => setState(() => _details.remove(d)),
                          side: const BorderSide(color: AppColors.outline),
                          labelStyle: const TextStyle(
                              fontSize: 13, color: AppColors.ivory),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          _navRow(canProceed: true, nextLabel: 'game_ui.see_fantasy'.tr()),
        ],
      ),
    );
  }

  // ── Reveal ─────────────────────────────────────────────────────────────

  Widget _buildReveal() {
    final text = Theme.of(context).textTheme;
    final theme = _themes.firstWhere((t) => t.value == _theme);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const Center(child: GameEmblem(icon: Icons.auto_awesome_outlined)),
        const SizedBox(height: 18),
        Text(
          plainLabel('games.fantasy_builder.your_fantasy'.tr()),
          textAlign: TextAlign.center,
          style: text.headlineMedium,
        ),
        const SizedBox(height: 22),
        GameSurface(
          highlighted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FantasyLine(
                label: 'game_ui.setting'.tr(),
                value: _label('settings', _picks[0]!),
              ),
              _FantasyLine(
                label: 'game_ui.atmosphere'.tr(),
                value: _label('moods', _picks[1]!),
              ),
              _FantasyLine(
                label: 'game_ui.main_action'.tr(),
                value: _label(_actionGroup, _picks[2]!),
              ),
              _FantasyLine(
                label: 'game_ui.surprise'.tr(),
                value: _label('surprises', _picks[3]!),
              ),
              if (_details.isNotEmpty)
                _FantasyLine(
                  label: 'game_ui.special_details'.tr(),
                  value: _details.join(', '),
                ),
              const Divider(height: 28, color: AppColors.hairline),
              Row(
                children: [
                  Icon(theme.icon, size: 20, color: AppColors.champagne),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plainLabel('games.fantasy_builder.secret_theme'.tr())
                              .toUpperCase(),
                          style: AppTypography.eyebrow.copyWith(
                            fontSize: 10,
                            color: AppColors.champagne,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'games.fantasy_builder.themes.${theme.value}'.tr(),
                          style: const TextStyle(
                            fontFamily: AppTypography.displayFont,
                            fontSize: 20,
                            color: AppColors.ivory,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'games.fantasy_builder.narrative.closing'.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppTypography.displayFont,
            fontStyle: FontStyle.italic,
            fontSize: 15,
            color: AppColors.mist,
          ),
        ),
        const SizedBox(height: 28),
        GameSectionLabel('game_ui.when_realize'.tr()),
        for (final w in _whenOptions) ...[
          GameOptionTile(
            title: 'game_ui.${w.value}'.tr(),
            subtitle: 'game_ui.${w.value}_desc'.tr(),
            icon: w.icon,
            selected: _when == w.value,
            onTap: () => setState(() {
              _when = w.value;
              _savedThis = false;
            }),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 22),
        GamePrimaryButton(
          label: _savedThis
              ? 'games.fantasy_builder.fantasy_saved'.tr()
              : 'games.fantasy_builder.save_scenario'.tr(),
          icon: _savedThis ? Icons.check_rounded : Icons.bookmark_border_rounded,
          onPressed: _savedThis ? null : _saveFantasy,
        ),
        const SizedBox(height: 10),
        GameSecondaryButton(
          label: 'game_ui.new_fantasy'.tr(),
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

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected
                  ? GameTone.selectedFill
                  : AppColors.inkRaised.withOpacity(0.78),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? GameTone.selectedBorder : AppColors.hairline,
                width: selected ? 1.2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 22,
                    color: selected ? GameTone.accentSoft : AppColors.mist),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.ivory : AppColors.mist,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FantasyLine extends StatelessWidget {
  final String label;
  final String value;

  const _FantasyLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plainLabel(label).toUpperCase(),
            style: AppTypography.eyebrow.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              height: 1.35,
              color: AppColors.ivory,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedFantasyTile extends StatelessWidget {
  final _Fantasy fantasy;
  final VoidCallback onDelete;

  const _SavedFantasyTile({required this.fantasy, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final when = fantasy.when;
    return GameSurface(
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label('settings', fantasy.setting),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ivory,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_label('moods', fantasy.mood)} · '
                  '${_label(fantasy.actionGroup, fantasy.action)}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.mist),
                ),
                if (when != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    plainLabel('game_ui.$when'.tr()),
                    style: const TextStyle(
                        fontSize: 12, color: GameTone.accentSoft),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.smoke),
            tooltip: plainLabel('common.delete'.tr()),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
