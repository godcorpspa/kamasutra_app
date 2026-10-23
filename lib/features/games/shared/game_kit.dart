import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import '../../../data/services/preferences_service.dart';
import '../../../shared/utils/display_text.dart';

/// Shared look and plumbing for the couple games.
///
/// Every game sits on the same quiet canvas as the rest of the app (ink,
/// hairlines, Playfair titles) with one accent: the fuchsia/orchid tone.
/// No particles, neon glows or cartoon drawings — a thin line icon inside
/// two hairline rings stands in for each game's illustration.
class GameTone {
  static const Color accent = AppColors.fuchsia;

  /// Softer orchid for text and icons on the dark canvas.
  static const Color accentSoft = Color(0xFFE8A6F2);

  static const LinearGradient cta = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFC94BDD), Color(0xFF8E3FA8)],
  );

  static Color get selectedFill => accent.withOpacity(0.10);
  static Color get selectedBorder => accent.withOpacity(0.55);
}

/// Ink canvas with a soft fuchsia light from the top and a faint champagne
/// one from the bottom corner.
class GameBackdrop extends StatelessWidget {
  final Widget child;

  const GameBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.ink),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -1.25),
                  radius: 1.0,
                  colors: [Color(0x33D946EF), Color(0x00D946EF)],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(1.1, 1.2),
                  radius: 0.9,
                  colors: [Color(0x14E9C9A6), Color(0x00E9C9A6)],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Scaffold for a game screen: transparent bar with back, title and an
/// optional help button over [GameBackdrop].
///
/// With [guardExit] the system back gesture and the back button ask before
/// abandoning a game in progress.
class GameScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onHelp;
  final bool guardExit;
  final List<Widget> actions;

  const GameScaffold({
    super.key,
    required this.title,
    required this.child,
    this.onHelp,
    this.guardExit = false,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !guardExit,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await confirmLeaveGame(context)) navigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.ink,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            ...actions,
            if (onHelp != null)
              IconButton(
                icon: const Icon(Icons.help_outline_rounded,
                    color: AppColors.mist),
                onPressed: onHelp,
              ),
            const SizedBox(width: 4),
          ],
        ),
        body: GameBackdrop(child: SafeArea(child: child)),
      ),
    );
  }
}

/// "Leave the game?" confirmation. Returns true when the player confirms.
Future<bool> confirmLeaveGame(BuildContext context) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('game_kit.leave_title'.tr()),
      content: Text('game_kit.leave_body'.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('game_kit.stay'.tr()),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: GameTone.accentSoft),
          child: Text('game_kit.leave'.tr()),
        ),
      ],
    ),
  );
  return leave ?? false;
}

/// Bottom sheet with a game's rules: a title and numbered lines.
Future<void> showGameRules(
  BuildContext context, {
  required String title,
  required List<String> rules,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: AppColors.inkHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(plainLabel(title),
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 18),
            _RuleList(rules: rules),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(plainLabel('game_ui.understood'.tr())),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The game's emblem: a thin line icon inside two hairline rings, the inner
/// one drawn in a fuchsia→champagne sweep.
class GameEmblem extends StatelessWidget {
  final IconData icon;
  final double size;

  const GameEmblem({super.key, required this.icon, this.size = 104});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EmblemPainter(),
        child: Center(
          child: Icon(icon, size: size * 0.32, color: GameTone.accentSoft),
        ),
      ),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final inner = r * 0.78;

    canvas.drawCircle(
      c,
      inner,
      Paint()
        ..shader = RadialGradient(colors: [
          GameTone.accent.withOpacity(0.20),
          GameTone.accent.withOpacity(0.0),
        ]).createShader(Rect.fromCircle(center: c, radius: inner)),
    );
    canvas.drawCircle(
      c,
      r - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.hairline,
    );
    canvas.drawCircle(
      c,
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = SweepGradient(
          transform: const GradientRotation(-pi / 2),
          colors: [
            GameTone.accent.withOpacity(0.85),
            AppColors.champagne.withOpacity(0.65),
            GameTone.accent.withOpacity(0.85),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: inner)),
    );
    // A single champagne bead on the outer ring.
    canvas.drawCircle(
      c + Offset(0, -(r - 0.5)),
      2.2,
      Paint()..color = AppColors.champagne,
    );
  }

  @override
  bool shouldRepaint(covariant _EmblemPainter oldDelegate) => false;
}

/// Emblem + title + subtitle at the top of a game's setup page.
class GameHero extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const GameHero({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        GameEmblem(icon: icon),
        const SizedBox(height: 20),
        Text(
          plainLabel(title),
          textAlign: TextAlign.center,
          style: text.headlineMedium,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            plainLabel(subtitle!),
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: AppColors.mist),
          ),
        ],
      ],
    );
  }
}

/// Small uppercase label above a group of options.
class GameSectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const GameSectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              plainLabel(text).toUpperCase(),
              style: AppTypography.eyebrow.copyWith(color: AppColors.mist),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Dark card with a hairline border.
class GameSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool highlighted;

  const GameSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: highlighted
            ? Color.alphaBlend(GameTone.selectedFill, AppColors.inkRaised)
            : AppColors.inkRaised.withOpacity(0.78),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: highlighted ? GameTone.selectedBorder : AppColors.hairline,
        ),
      ),
      child: child,
    );
  }
}

/// Selectable row: optional line icon, title, subtitle and a check ring.
class GameOptionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  /// Small coloured dot before the title (e.g. an intensity).
  final Color? dot;

  /// Short tag shown before the check ring (e.g. "x2").
  final String? badge;

  const GameOptionTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.dot,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? GameTone.selectedBorder
                            : AppColors.hairline,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: selected ? GameTone.accentSoft : AppColors.mist,
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (dot != null) ...[
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: dot,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              plainLabel(title),
                              style: text.titleMedium?.copyWith(
                                color: AppColors.ivory,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          plainLabel(subtitle!),
                          style:
                              text.bodySmall?.copyWith(color: AppColors.mist),
                        ),
                      ],
                    ],
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.round),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.champagne,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                _CheckRing(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckRing extends StatelessWidget {
  final bool selected;

  const _CheckRing({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? GameTone.accent : Colors.transparent,
        border: Border.all(
          color: selected ? GameTone.accent : AppColors.outline,
          width: 1.2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}

/// Row of equal-width choices (rounds, durations, difficulty…).
class GameSegmented<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T) label;
  final String Function(T)? caption;

  /// Numbers get the display serif with lining figures.
  final bool numeric;

  const GameSegmented({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
    required this.label,
    this.caption,
    this.numeric = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < values.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _segment(context, values[i])),
        ],
      ],
    );
  }

  Widget _segment(BuildContext context, T value) {
    final isSelected = value == selected;
    final sub = caption?.call(value);
    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(value);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? GameTone.selectedFill
                  : AppColors.inkRaised.withOpacity(0.78),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? GameTone.selectedBorder : AppColors.hairline,
                width: isSelected ? 1.2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  plainLabel(label(value)),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: numeric
                      ? TextStyle(
                          fontFamily: AppTypography.displayFont,
                          fontFeatures: AppTypography.lining,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color:
                              isSelected ? AppColors.ivory : AppColors.mist,
                        )
                      : TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected ? AppColors.ivory : AppColors.mist,
                        ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? GameTone.accentSoft
                          : AppColors.smoke,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "How to play" card with numbered lines.
class GameRulesCard extends StatelessWidget {
  final String title;
  final List<String> rules;

  const GameRulesCard({super.key, required this.title, required this.rules});

  @override
  Widget build(BuildContext context) {
    return GameSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plainLabel(title),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          _RuleList(rules: rules),
        ],
      ),
    );
  }
}

class _RuleList extends StatelessWidget {
  final List<String> rules;

  const _RuleList({required this.rules});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rules.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: GameTone.selectedBorder),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: GameTone.accentSoft,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    plainLabel(rules[i]),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.mist,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Full-width fuchsia call to action.
class GamePrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const GamePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.4,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          gradient: GameTone.cta,
          shadows: [
            if (enabled)
              BoxShadow(
                color: GameTone.accent.withOpacity(0.16),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled
                ? () {
                    HapticFeedback.mediumImpact();
                    onPressed!();
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: Colors.white),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      plainLabel(label),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width outlined secondary action.
class GameSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const GameSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final child = Text(plainLabel(label), textAlign: TextAlign.center);
    return SizedBox(
      width: double.infinity,
      child: icon == null
          ? OutlinedButton(onPressed: onPressed, child: child)
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: child,
            ),
    );
  }
}

/// Discreet text action ("End game").
class GameQuietButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  const GameQuietButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: AppColors.smoke),
      icon: Icon(icon ?? Icons.close_rounded, size: 16),
      label: Text(plainLabel(label)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Players
// ─────────────────────────────────────────────────────────────────────────

/// The couple's names, entered once and shared by every game.
class GamePlayers {
  static String _key(int player) => 'game_player${player}_name';

  /// The saved name, or null when the player never typed one.
  static String? stored(int player) {
    final value = PreferencesService.instance.getString(_key(player))?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  static String defaultName(int player) =>
      (player == 1 ? 'game_ui.player_1' : 'game_ui.player_2').tr();

  /// The name to show for [player] (1 or 2).
  static String name(int player) => stored(player) ?? defaultName(player);

  static Future<void> save(int player, String value) =>
      PreferencesService.instance.setString(_key(player), value.trim());

  /// Each player keeps a colour across the games: orchid and champagne.
  static Color color(int player) =>
      player == 1 ? GameTone.accentSoft : AppColors.champagne;
}

/// Two name fields, saved as the players type. Shown on every setup page.
class GamePlayersCard extends StatefulWidget {
  const GamePlayersCard({super.key});

  @override
  State<GamePlayersCard> createState() => _GamePlayersCardState();
}

class _GamePlayersCardState extends State<GamePlayersCard> {
  late final List<TextEditingController> _controllers = [
    TextEditingController(text: GamePlayers.stored(1) ?? ''),
    TextEditingController(text: GamePlayers.stored(2) ?? ''),
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GameSectionLabel('game_kit.players'.tr()),
        for (var p = 1; p <= 2; p++) ...[
          if (p == 2) const SizedBox(height: 10),
          TextField(
            controller: _controllers[p - 1],
            onChanged: (v) => GamePlayers.save(p, v),
            textCapitalization: TextCapitalization.words,
            textInputAction: p == 1 ? TextInputAction.next : TextInputAction.done,
            maxLength: 18,
            style: const TextStyle(color: AppColors.ivory, fontSize: 15),
            decoration: InputDecoration(
              counterText: '',
              hintText: GamePlayers.defaultName(p),
              fillColor: AppColors.inkRaised.withOpacity(0.78),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 18, right: 12),
                child: PlayerDot(player: p),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 10),
          child: Text(
            'game_kit.players_hint'.tr(),
            style: const TextStyle(fontSize: 12, color: AppColors.smoke),
          ),
        ),
      ],
    );
  }
}

/// A player's colour as a small ringed dot.
class PlayerDot extends StatelessWidget {
  final int player;
  final double size;

  const PlayerDot({super.key, required this.player, this.size = 10});

  @override
  Widget build(BuildContext context) {
    final color = GamePlayers.color(player);
    return Container(
      width: size + 6,
      height: size + 6,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

/// "Your turn, Giulia" banner with an optional counter on the right.
class GameTurnBanner extends StatelessWidget {
  final int player;
  final String? trailing;

  /// Overrides the "it's your turn" eyebrow.
  final String? caption;

  const GameTurnBanner({
    super.key,
    required this.player,
    this.trailing,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return GameSurface(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          PlayerDot(player: player, size: 12),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (caption ?? 'game_kit.turn_of'.tr()).toUpperCase(),
                  style: AppTypography.eyebrow.copyWith(fontSize: 10),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    GamePlayers.name(player),
                    key: ValueKey(player),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.displayFont,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: GamePlayers.color(player),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                fontSize: 13,
                fontFeatures: AppTypography.lining,
                color: AppColors.mist,
              ),
            ),
        ],
      ),
    );
  }
}

/// Thin progress bar (rounds, questions…).
class GameProgressBar extends StatelessWidget {
  final double value;

  const GameProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.hairline),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: const DecoratedBox(
                decoration: BoxDecoration(gradient: GameTone.cta),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Countdown ring: a hairline track with a fuchsia arc and the remaining
/// seconds in the middle.
class GameTimerRing extends StatelessWidget {
  final double progress;
  final String label;
  final String? caption;
  final double size;

  /// Turns the arc and label rosé when time is nearly up.
  final bool urgent;

  const GameTimerRing({
    super.key,
    required this.progress,
    required this.label,
    this.caption,
    this.size = 180,
    this.urgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TimerRingPainter(progress: progress, urgent: urgent),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.displayFont,
                  fontFeatures: AppTypography.lining,
                  fontSize: size * 0.24,
                  fontWeight: FontWeight.w500,
                  color: urgent ? AppColors.rose : AppColors.ivory,
                ),
              ),
              if (caption != null)
                Text(
                  caption!.toUpperCase(),
                  style: AppTypography.eyebrow.copyWith(fontSize: 10),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final bool urgent;

  _TimerRingPainter({required this.progress, required this.urgent});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 4;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppColors.hairline,
    );
    final sweep = 2 * pi * progress.clamp(0.0, 1.0);
    if (sweep <= 0) return;
    canvas.drawArc(
      rect,
      -pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          transform: const GradientRotation(-pi / 2),
          colors: urgent
              ? [AppColors.rose, AppColors.rose]
              : [GameTone.accent, AppColors.champagne, GameTone.accent],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter old) =>
      old.progress != progress || old.urgent != urgent;
}

// ─────────────────────────────────────────────────────────────────────────
// Plumbing
// ─────────────────────────────────────────────────────────────────────────

/// Draws items in random order without repeating one until all have come
/// out, and never the same item twice in a row across reshuffles.
class ShuffleBag<T> {
  final List<T> _items;
  final Random _random;
  final List<T> _bag = [];
  T? _last;

  ShuffleBag(Iterable<T> items, {Random? random})
      : _items = List.of(items),
        _random = random ?? Random();

  bool get isEmpty => _items.isEmpty;

  T next() {
    if (_bag.isEmpty) {
      _bag
        ..addAll(_items)
        ..shuffle(_random);
      if (_bag.length > 1 && _bag.last == _last) {
        final first = _bag.first;
        _bag[0] = _bag.last;
        _bag[_bag.length - 1] = first;
      }
    }
    return _last = _bag.removeLast();
  }
}

/// Reads a numbered list of translations: `prefix.0`, `prefix.1`… up to
/// the first missing index.
List<String> localizedList(String prefix, {int max = 100}) {
  final out = <String>[];
  for (var i = 0; i < max; i++) {
    final key = '$prefix.$i';
    final value = key.tr();
    if (value == key) break;
    out.add(value);
  }
  return out;
}

/// Counts a played game towards the progress badges (games played, days of
/// use, time together), at most once per session.
class GameSession {
  DateTime? _startedAt;
  bool _recorded = false;

  bool get isStarted => _startedAt != null;

  void start() => _startedAt ??= DateTime.now();

  void finish() {
    final startedAt = _startedAt;
    if (startedAt == null || _recorded) return;
    _recorded = true;
    final prefs = PreferencesService.instance;
    prefs.incrementGamesPlayed();
    prefs.recordUsageToday();
    prefs.addTimeTogetherMinutes(
        DateTime.now().difference(startedAt).inMinutes.clamp(1, 120));
  }
}
