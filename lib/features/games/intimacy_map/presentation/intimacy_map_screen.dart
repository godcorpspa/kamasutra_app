import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../shared/utils/display_text.dart';
import '../../shared/game_kit.dart';

/// Intimacy Map: each partner marks, on a body chart, how they like to be
/// touched in each zone; then the two maps are compared. In private mode
/// the phone is passed and the maps stay secret until the comparison; in
/// together mode both see each other's marks live.
class IntimacyMapScreen extends StatefulWidget {
  const IntimacyMapScreen({super.key});

  @override
  State<IntimacyMapScreen> createState() => _IntimacyMapScreenState();
}

// ─────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────

/// A zone on the chart. [x]/[y] are in figure units (the figure is drawn
/// in a 100 × 200 box, see [_FigurePainter]), so dots always sit on the
/// part they name. [left] says which margin its label goes to.
class _Zone {
  final String id;
  final String labelKey;
  final double x;
  final double y;
  final bool left;

  const _Zone(this.id, this.labelKey, this.x, this.y, {required this.left});

  String get name => 'games.intimacy_map.body_$labelKey'.tr();

  /// "Cosce (dietro)" → "Cosce": on the back view the side is implicit.
  String get shortName => name.replaceAll(RegExp(r'\s*\(.*\)\s*$'), '');
}

const _frontZones = [
  _Zone('forehead', 'forehead', 50, 8.5, left: true),
  _Zone('eyes', 'eyes', 54.4, 14.5, left: false),
  _Zone('ears', 'ears', 40.8, 16.5, left: true),
  _Zone('cheeks', 'cheeks', 44, 21, left: true),
  _Zone('lips', 'lips', 50, 24.2, left: false),
  _Zone('neck_front', 'neck', 50, 33, left: true),
  _Zone('shoulders', 'shoulders', 32.5, 45.5, left: true),
  _Zone('chest', 'chest', 50, 49, left: false),
  _Zone('nipples', 'nipples', 42.5, 55, left: true),
  _Zone('arms', 'arms', 23, 72, left: true),
  _Zone('stomach', 'stomach', 50, 76, left: false),
  _Zone('lower_belly', 'lower_belly', 50, 91, left: false),
  _Zone('hips', 'hips', 66, 97, left: false),
  _Zone('intimate', 'intimate', 50, 103.5, left: true),
  _Zone('hands', 'hands', 17.6, 120, left: true),
  _Zone('thighs_front', 'thighs', 59.5, 123, left: false),
  _Zone('inner_thighs', 'inner_thighs', 46.4, 127, left: true),
  _Zone('knees', 'knees', 40.4, 146, left: true),
  _Zone('calves_front', 'calves', 59.8, 165, left: false),
  _Zone('feet', 'feet', 41, 192.5, left: true),
];

const _backZones = [
  _Zone('head_back', 'nape', 50, 18, left: false),
  _Zone('neck_back', 'neck_back', 50, 33, left: true),
  _Zone('upper_back', 'upper_back', 50, 55, left: false),
  _Zone('lower_back', 'lower_back', 50, 84, left: true),
  _Zone('buttocks', 'buttocks', 57.5, 103, left: false),
  _Zone('thighs_back', 'thighs_back', 40.5, 126, left: true),
  _Zone('back_knees', 'back_knees', 40.4, 146, left: true),
  _Zone('calves_back', 'calves_back', 59.8, 163, left: false),
];

final _allZones = [..._frontZones, ..._backZones];

class _Sensation {
  final String id;
  final Color color;
  final IconData icon;

  const _Sensation(this.id, this.color, this.icon);

  String get label => 'games.intimacy_map.touch_$id'.tr();
}

const _sensations = [
  _Sensation('love', GameTone.accent, Icons.favorite_rounded),
  _Sensation('like', AppColors.jewelLilac, Icons.thumb_up_alt_outlined),
  _Sensation('sensitive', AppColors.jewelAmber, Icons.auto_awesome_outlined),
  _Sensation('ticklish', AppColors.jewelTeal,
      Icons.sentiment_very_satisfied_outlined),
  _Sensation('neutral', AppColors.mist, Icons.remove_rounded),
  _Sensation('avoid', AppColors.jewelGarnet, Icons.block_rounded),
];

_Sensation? _sensation(String? id) {
  if (id == null) return null;
  for (final s in _sensations) {
    if (s.id == id) return s;
  }
  return null;
}

enum _Phase { setup, mapping, handoff, reveal }

// ─────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────

class _IntimacyMapScreenState extends State<IntimacyMapScreen> {
  final _session = GameSession();

  _Phase _phase = _Phase.setup;
  bool _private = true;
  int _player = 1;
  bool _front = true;
  final _maps = [<String, String>{}, <String, String>{}];

  Map<String, String> get _mine => _maps[_player - 1];
  Map<String, String> get _theirs => _maps[2 - _player];
  int get _other => 3 - _player;

  @override
  void dispose() {
    _session.finish();
    super.dispose();
  }

  List<String> get _rules => [
        'games.intimacy_map.step1'.tr(),
        'games.intimacy_map.step2'.tr(),
        'games.intimacy_map.step3'.tr(),
        'games.intimacy_map.step4'.tr(),
      ];

  void _start() {
    _session.start();
    setState(() {
      _maps[0].clear();
      _maps[1].clear();
      _player = 1;
      _front = true;
      _phase = _Phase.mapping;
    });
  }

  void _mark(_Zone zone, String? sensation) {
    HapticFeedback.selectionClick();
    setState(() {
      if (sensation == null) {
        _mine.remove(zone.id);
      } else {
        _mine[zone.id] = sensation;
      }
    });
  }

  void _switchPlayer() {
    HapticFeedback.mediumImpact();
    if (_private) {
      setState(() => _phase = _Phase.handoff);
    } else {
      setState(() => _player = _other);
    }
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('games.intimacy_map.reset_maps'.tr()),
        content: Text('games.intimacy_map.reset_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('games.intimacy_map.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.rose),
            child: Text('games.intimacy_map.reset'.tr()),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        _maps[0].clear();
        _maps[1].clear();
      });
    }
  }

  void _compare() {
    HapticFeedback.heavyImpact();
    _session.finish();
    setState(() => _phase = _Phase.reveal);
  }

  Future<void> _pickSensation(_Zone zone) async {
    final current = _mine[zone.id];
    final picked = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.inkHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _SensationSheet(zone: zone, current: current),
    );
    if (!mounted || picked == null) return;
    _mark(zone, picked.isEmpty ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    final mapping = _phase == _Phase.mapping;
    return GameScaffold(
      title: 'games.intimacy_map.title'.tr(),
      guardExit: mapping || _phase == _Phase.handoff,
      onHelp: () => showGameRules(
        context,
        title: 'games.intimacy_map.how_it_works'.tr(),
        rules: _rules,
      ),
      actions: [
        if (mapping && (_maps[0].isNotEmpty || _maps[1].isNotEmpty))
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded, color: AppColors.mist),
            tooltip: plainLabel('games.intimacy_map.reset_maps'.tr()),
            onPressed: _reset,
          ),
      ],
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey('$_phase$_player'),
          child: switch (_phase) {
            _Phase.setup => _buildSetup(),
            _Phase.mapping => _buildMapping(),
            _Phase.handoff => GameHandoff(
                player: _other,
                icon: Icons.lock_outline_rounded,
                title: 'games.intimacy_map.pass_to'
                    .tr(namedArgs: {'name': GamePlayers.name(_other)}),
                message: 'games.intimacy_map.pass_phone_hint'.tr(),
                action: 'game_ui.continue_btn'.tr(),
                onContinue: () => setState(() {
                  _player = _other;
                  _front = true;
                  _phase = _Phase.mapping;
                }),
              ),
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
          icon: Icons.map_outlined,
          title: 'games.intimacy_map.title'.tr(),
          subtitle: 'games.intimacy_map.subtitle'.tr(),
        ),
        const SizedBox(height: 32),
        const GamePlayersCard(),
        const SizedBox(height: 28),
        GameSectionLabel('games.intimacy_map.mode_label'.tr()),
        GameOptionTile(
          title: 'games.intimacy_map.mode_private'.tr(),
          subtitle: 'games.intimacy_map.mode_private_desc'.tr(),
          icon: Icons.lock_outline_rounded,
          selected: _private,
          onTap: () => setState(() => _private = true),
        ),
        const SizedBox(height: 10),
        GameOptionTile(
          title: 'games.intimacy_map.mode_together'.tr(),
          subtitle: 'games.intimacy_map.mode_together_desc'.tr(),
          icon: Icons.people_outline_rounded,
          selected: !_private,
          onTap: () => setState(() => _private = false),
        ),
        const SizedBox(height: 28),
        GameSectionLabel('games.intimacy_map.sensation_types'.tr()),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final s in _sensations) _SensationChip(s)],
        ),
        const SizedBox(height: 28),
        GameRulesCard(
            title: 'games.intimacy_map.how_it_works'.tr(), rules: _rules),
        const SizedBox(height: 28),
        GamePrimaryButton(
          label: 'games.intimacy_map.start_exploration'.tr(),
          icon: Icons.play_arrow_rounded,
          onPressed: _start,
        ),
      ],
    );
  }

  // ── Mapping ────────────────────────────────────────────────────────────

  Widget _buildMapping() {
    final zones = _front ? _frontZones : _backZones;
    final canCompare = _maps[0].isNotEmpty && _maps[1].isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          GameTurnBanner(
            player: _player,
            caption: 'games.intimacy_map.map_of'.tr(),
            trailing: 'games.intimacy_map.zones_marked'.tr(namedArgs: {
              'count': '${_mine.length}',
              'total': '${_allZones.length}',
            }),
          ),
          const SizedBox(height: 10),
          GameSegmented<bool>(
            values: const [true, false],
            selected: _front,
            label: (f) => f
                ? 'games.intimacy_map.view_front'.tr()
                : 'games.intimacy_map.view_back'.tr(),
            onChanged: (f) => setState(() => _front = f),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _BodyAtlas(
              front: _front,
              zones: zones,
              marks: _mine,
              partnerMarks: _private ? null : _theirs,
              onTap: _pickSensation,
            ),
          ),
          Text(
            'games.intimacy_map.tap_hint'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.smoke),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _switchPlayer,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: Text(
                    GamePlayers.name(_other),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GamePrimaryButton(
                  label: 'games.intimacy_map.compare_maps'.tr(),
                  icon: Icons.compare_arrows_rounded,
                  onPressed: canCompare ? _compare : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Reveal ─────────────────────────────────────────────────────────────

  Widget _buildReveal() {
    final text = Theme.of(context).textTheme;
    final matches = <_Zone>[];
    final differences = <_Zone>[];
    final onlyOne = <_Zone>[];
    for (final z in _allZones) {
      final a = _maps[0][z.id];
      final b = _maps[1][z.id];
      if (a != null && b != null) {
        (a == b ? matches : differences).add(z);
      } else if (a != null || b != null) {
        onlyOne.add(z);
      }
    }
    final shared = matches.length + differences.length;
    final ratio = shared == 0 ? 0.0 : matches.length / shared;
    final message = ratio > 0.7
        ? 'games.intimacy_map.compatibility_msg_high'
        : ratio > 0.4
            ? 'games.intimacy_map.compatibility_msg_mid'
            : 'games.intimacy_map.compatibility_msg_low';
    final favourites = matches
        .where((z) => const {'love', 'sensitive'}.contains(_maps[0][z.id]))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const Center(child: GameEmblem(icon: Icons.map_outlined)),
        const SizedBox(height: 18),
        Text(
          plainLabel('games.intimacy_map.compare_title'.tr()),
          textAlign: TextAlign.center,
          style: text.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          plainLabel(message.tr()),
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: AppColors.mist),
        ),
        const SizedBox(height: 22),
        GameSurface(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'games.intimacy_map.compatibility_score'.tr(),
                      style:
                          const TextStyle(fontSize: 13, color: AppColors.mist),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  _Stat('${matches.length}',
                      'games.intimacy_map.match_count'.tr()),
                  _Stat('${differences.length}',
                      'games.intimacy_map.discovery_count'.tr()),
                  _Stat('${_maps[0].length}', GamePlayers.name(1)),
                  _Stat('${_maps[1].length}', GamePlayers.name(2)),
                ],
              ),
            ],
          ),
        ),
        if (favourites.isNotEmpty) ...[
          const SizedBox(height: 24),
          GameSectionLabel('games.intimacy_map.favorite_zones'.tr()),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final z in favourites)
                _ZonePill(z.name, _sensation(_maps[0][z.id])!),
            ],
          ),
        ],
        const SizedBox(height: 24),
        GameSectionLabel('games.intimacy_map.compatible_zones'.tr()),
        if (matches.isEmpty)
          _Empty('games.intimacy_map.no_matching_zones'.tr())
        else
          for (final z in matches)
            _CompareRow(zone: z, a: _maps[0][z.id], b: _maps[1][z.id]),
        const SizedBox(height: 18),
        GameSectionLabel('games.intimacy_map.zones_to_explore'.tr()),
        if (differences.isEmpty)
          _Empty('games.intimacy_map.all_compatible'.tr())
        else
          for (final z in differences)
            _CompareRow(zone: z, a: _maps[0][z.id], b: _maps[1][z.id]),
        if (onlyOne.isNotEmpty) ...[
          const SizedBox(height: 18),
          GameSectionLabel('games.intimacy_map.only_one'.tr()),
          for (final z in onlyOne)
            _CompareRow(zone: z, a: _maps[0][z.id], b: _maps[1][z.id]),
        ],
        const SizedBox(height: 14),
        Text(
          plainLabel('games.intimacy_map.closing_hint'.tr()),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppTypography.displayFont,
            fontStyle: FontStyle.italic,
            fontSize: 15,
            color: AppColors.mist,
          ),
        ),
        const SizedBox(height: 26),
        GamePrimaryButton(
          label: 'games.intimacy_map.continue_marking'.tr(),
          icon: Icons.edit_outlined,
          onPressed: () => setState(() => _phase = _Phase.mapping),
        ),
        const SizedBox(height: 10),
        GameSecondaryButton(
          label: 'game_ui.new_game'.tr(),
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

// ─────────────────────────────────────────────────────────────────────────
// Body atlas
// ─────────────────────────────────────────────────────────────────────────

/// The figure with a dot on every zone and its name in the margin, joined
/// by a hairline — like an anatomical plate. Dot and name are both tappable.
class _BodyAtlas extends StatelessWidget {
  final bool front;
  final List<_Zone> zones;
  final Map<String, String> marks;
  final Map<String, String>? partnerMarks;
  final ValueChanged<_Zone> onTap;

  const _BodyAtlas({
    required this.front,
    required this.zones,
    required this.marks,
    required this.partnerMarks,
    required this.onTap,
  });

  static const _labelWidth = 86.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        // Labels sit outside the body's span (x 11…89 in figure units).
        final s = min((h - 8) / 200, (w / 2 - _labelWidth - 6) / 39)
            .clamp(0.8, 4.0);
        final left = (w - 100 * s) / 2;
        final top = (h - 200 * s) / 2;
        final leftEdge = left + 11 * s;
        final rightEdge = left + 89 * s;
        Offset at(_Zone z) => Offset(left + z.x * s, top + z.y * s);
        final labelY = _labelYs(zones, (z) => at(z).dy, h - 10);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _FigurePainter(
                  front: front,
                  scale: s,
                  origin: Offset(left, top),
                  leaders: [
                    for (final z in zones)
                      (
                        at(z),
                        Offset(z.left ? leftEdge : rightEdge, labelY[z.id]!),
                      ),
                  ],
                ),
              ),
            ),
            for (final z in zones) ...[
              _label(z, labelY[z.id]!, leftEdge, rightEdge),
              Positioned(
                left: at(z).dx - 18,
                top: at(z).dy - 18,
                width: 36,
                height: 36,
                child: Semantics(
                  button: true,
                  label: z.name,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(z),
                    child: Center(
                      child: _Dot(
                        mine: _sensation(marks[z.id]),
                        partner: _sensation(partnerMarks?[z.id]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Where each zone's label sits vertically: level with its dot, nudged
  /// down (or up, near the bottom) so labels in the same margin never
  /// overlap — the head and the hips have several zones close together.
  static Map<String, double> _labelYs(
    List<_Zone> zones,
    double Function(_Zone) dotY,
    double maxY,
  ) {
    const gap = 19.0;
    final out = <String, double>{};
    for (final side in [true, false]) {
      final column = zones.where((z) => z.left == side).toList()
        ..sort((a, b) => dotY(a).compareTo(dotY(b)));
      final ys = [for (final z in column) dotY(z)];
      for (var i = 1; i < ys.length; i++) {
        ys[i] = max(ys[i], ys[i - 1] + gap);
      }
      if (ys.isNotEmpty && ys.last > maxY) {
        ys[ys.length - 1] = maxY;
        for (var i = ys.length - 2; i >= 0; i--) {
          ys[i] = min(ys[i], ys[i + 1] - gap);
        }
      }
      for (var i = 0; i < column.length; i++) {
        out[column[i].id] = ys[i];
      }
    }
    return out;
  }

  Widget _label(_Zone z, double y, double leftEdge, double rightEdge) {
    final marked = _sensation(marks[z.id]);
    final text = Text(
      front ? z.name : z.shortName,
      maxLines: 1,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: marked != null ? FontWeight.w600 : FontWeight.w500,
        color: marked?.color ?? AppColors.mist,
      ),
    );
    return Positioned(
      left: z.left ? leftEdge - 4 - _labelWidth : rightEdge + 4,
      top: y - 10,
      width: _labelWidth,
      height: 20,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(z),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: z.left ? Alignment.centerRight : Alignment.centerLeft,
          child: text,
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final _Sensation? mine;
  final _Sensation? partner;

  const _Dot({required this.mine, required this.partner});

  @override
  Widget build(BuildContext context) {
    final m = mine;
    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (partner != null)
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: partner!.color, width: 1.6),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: m == null ? 11 : 14,
            height: m == null ? 11 : 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: m?.color ?? AppColors.ink,
              border: Border.all(
                color: m == null
                    ? AppColors.champagne.withOpacity(0.85)
                    : AppColors.ivory.withOpacity(0.9),
                width: m == null ? 1.3 : 1.2,
              ),
              boxShadow: m == null
                  ? null
                  : [BoxShadow(color: m.color.withOpacity(0.45), blurRadius: 8)],
            ),
          ),
        ],
      ),
    );
  }
}

/// A slender, neutral figure in a single hairline contour (100 × 200
/// units), with collarbones on the front and the spine on the back, plus
/// the leader lines from each zone to its label.
class _FigurePainter extends CustomPainter {
  final bool front;
  final double scale;
  final Offset origin;
  /// Hairlines from each dot to its label.
  final List<(Offset, Offset)> leaders;

  _FigurePainter({
    required this.front,
    required this.scale,
    required this.origin,
    required this.leaders,
  });

  /// Left half of the outline, from the neck down to the crotch, as cubic
  /// segments (control 1, control 2, end). The right half is its mirror.
  static const _leftContour = <List<double>>[
    [45, 28, 45, 31, 45, 33], // neck
    [44, 36, 36, 38, 30, 41], // trapezius → shoulder
    [25.5, 43, 23.5, 49, 23, 56], // deltoid
    [22.4, 65, 20.8, 74, 19.8, 82], // upper arm → elbow
    [18.9, 92, 17.4, 103, 16.6, 111], // forearm → wrist
    [15, 115, 13.8, 121, 15.2, 125.5], // hand, outer edge
    [16.4, 128.6, 19.4, 128.2, 20.2, 125], // fingertips
    [20.9, 121, 20.9, 116, 20.6, 112], // hand, inner edge
    [21.4, 104, 23.2, 94, 24.3, 83], // inner forearm
    [25.3, 73, 27.2, 63, 30.2, 56.5], // inner upper arm → armpit
    [31.4, 64, 35.6, 72, 37, 80], // ribs → waist
    [38, 87, 31.3, 91, 31, 99], // waist → hip
    [30.8, 112, 33.6, 128, 35.2, 146], // outer thigh → knee
    [34.6, 153, 33.4, 161, 34.8, 170], // calf
    [35.8, 177, 37.6, 182, 38.4, 186], // ankle
    [37, 189, 35.2, 193, 37.2, 195.6], // heel
    [39.6, 197.6, 44, 197.2, 45, 194.4], // sole → toes
    [45.6, 191, 44.6, 188.4, 44.3, 186], // instep
    [45.2, 176, 46.6, 165, 45.8, 156], // inner calf
    [45.2, 151.5, 45.1, 148.6, 45.4, 146], // inner knee
    [46.2, 132, 48.6, 118, 50, 109], // inner thigh → crotch
  ];

  Offset _p(double x, double y) =>
      origin + Offset(x * scale, y * scale);

  Path _body() {
    const start = Offset(45, 25);
    final path = Path()..moveTo(_p(start.dx, start.dy).dx, _p(start.dx, start.dy).dy);
    for (final s in _leftContour) {
      final c1 = _p(s[0], s[1]);
      final c2 = _p(s[2], s[3]);
      final e = _p(s[4], s[5]);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, e.dx, e.dy);
    }
    // Mirror, walking back up: each segment reversed and flipped.
    final points = <Offset>[start];
    for (final s in _leftContour) {
      points.add(Offset(s[4], s[5]));
    }
    for (var i = _leftContour.length - 1; i >= 0; i--) {
      final s = _leftContour[i];
      final from = points[i];
      final c1 = _p(100 - s[2], s[3]);
      final c2 = _p(100 - s[0], s[1]);
      final e = _p(100 - from.dx, from.dy);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, e.dx, e.dy);
    }
    return path..close();
  }

  Path _head() => Path()
    ..addOval(Rect.fromCenter(
      center: _p(50, 16),
      width: 19.2 * scale,
      height: 24 * scale,
    ));

  @override
  void paint(Canvas canvas, Size size) {
    final figure = Path.combine(PathOperation.union, _head(), _body());
    final bounds = figure.getBounds();

    canvas.drawPath(
      figure,
      Paint()
        ..color = GameTone.accent.withOpacity(0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawPath(
      figure,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.ivory.withOpacity(0.09),
            GameTone.accent.withOpacity(0.05),
            AppColors.ivory.withOpacity(0.03),
          ],
        ).createShader(bounds),
    );

    final detail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..color = AppColors.champagne.withOpacity(0.22);
    if (front) {
      // Collarbones.
      for (final side in [-1.0, 1.0]) {
        final a = _p(50 + side * 3.5, 40.5);
        final c = _p(50 + side * 9, 38.6);
        final b = _p(50 + side * 15.5, 40.2);
        canvas.drawPath(
          Path()
            ..moveTo(a.dx, a.dy)
            ..quadraticBezierTo(c.dx, c.dy, b.dx, b.dy),
          detail,
        );
      }
    } else {
      // Spine and the curve of the lower back.
      final top = _p(50, 37);
      final bottom = _p(50, 96);
      canvas.drawLine(top, bottom, detail);
      for (final side in [-1.0, 1.0]) {
        final a = _p(50, 104);
        final c = _p(50 + side * 5, 109);
        final b = _p(50 + side * 12, 106.5);
        canvas.drawPath(
          Path()
            ..moveTo(a.dx, a.dy)
            ..quadraticBezierTo(c.dx, c.dy, b.dx, b.dy),
          detail,
        );
      }
    }

    canvas.drawPath(
      figure,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.champagne.withOpacity(0.7),
    );

    final leader = Paint()
      ..strokeWidth = 0.8
      ..color = AppColors.ivory.withOpacity(0.18);
    for (final (dot, end) in leaders) {
      final dir = end.dx < dot.dx ? -1 : 1;
      canvas.drawLine(dot + Offset(dir * 8.0, 0), end, leader);
    }
  }

  @override
  bool shouldRepaint(covariant _FigurePainter old) =>
      old.front != front ||
      old.scale != scale ||
      old.origin != origin ||
      old.leaders.length != leaders.length ||
      old.leaders.first != leaders.first;
}

// ─────────────────────────────────────────────────────────────────────────
// Small pieces
// ─────────────────────────────────────────────────────────────────────────

class _SensationSheet extends StatelessWidget {
  final _Zone zone;
  final String? current;

  const _SensationSheet({required this.zone, required this.current});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(zone.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'games.intimacy_map.how_touched_here'.tr(),
              style: const TextStyle(fontSize: 14, color: AppColors.mist),
            ),
            const SizedBox(height: 18),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 3.2,
              children: [
                for (final s in _sensations)
                  _SensationButton(
                    sensation: s,
                    selected: current == s.id,
                    onTap: () => Navigator.of(context).pop(s.id),
                  ),
              ],
            ),
            if (current != null) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(''),
                  style: TextButton.styleFrom(foregroundColor: AppColors.smoke),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: Text('games.intimacy_map.clear_mark'.tr()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SensationButton extends StatelessWidget {
  final _Sensation sensation;
  final bool selected;
  final VoidCallback onTap;

  const _SensationButton({
    required this.sensation,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = sensation.color;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? c.withOpacity(0.16) : AppColors.inkRaised,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? c : AppColors.hairline,
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(sensation.icon, size: 18, color: c),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sensation.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ivory,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SensationChip extends StatelessWidget {
  final _Sensation sensation;

  const _SensationChip(this.sensation);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.round),
        border: Border.all(color: AppColors.hairline),
        color: AppColors.inkRaised.withOpacity(0.78),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(sensation.icon, size: 14, color: sensation.color),
          const SizedBox(width: 6),
          Text(
            sensation.label,
            style: const TextStyle(fontSize: 13, color: AppColors.ivory),
          ),
        ],
      ),
    );
  }
}

class _ZonePill extends StatelessWidget {
  final String name;
  final _Sensation sensation;

  const _ZonePill(this.name, this.sensation);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.round),
        color: sensation.color.withOpacity(0.14),
        border: Border.all(color: sensation.color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(sensation.icon, size: 14, color: sensation.color),
          const SizedBox(width: 6),
          Text(name,
              style: const TextStyle(fontSize: 13, color: AppColors.ivory)),
        ],
      ),
    );
  }
}

/// Zone name, then each partner's sensation (or a dash).
class _CompareRow extends StatelessWidget {
  final _Zone zone;
  final String? a;
  final String? b;

  const _CompareRow({required this.zone, required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              zone.name,
              style: const TextStyle(fontSize: 14.5, color: AppColors.ivory),
            ),
          ),
          _Mark(player: 1, sensation: _sensation(a)),
          const SizedBox(width: 12),
          _Mark(player: 2, sensation: _sensation(b)),
        ],
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  final int player;
  final _Sensation? sensation;

  const _Mark({required this.player, required this.sensation});

  @override
  Widget build(BuildContext context) {
    final s = sensation;
    return SizedBox(
      width: 92,
      child: Row(
        children: [
          PlayerDot(player: player, size: 6),
          const SizedBox(width: 6),
          if (s == null)
            const Text('—', style: TextStyle(color: AppColors.smoke))
          else ...[
            Icon(s.icon, size: 13, color: s.color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                s.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: s.color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;

  const _Empty(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(
        plainLabel(text),
        style: const TextStyle(fontSize: 13.5, color: AppColors.smoke),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.mist),
          ),
        ],
      ),
    );
  }
}
