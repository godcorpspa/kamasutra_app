import 'package:flutter/material.dart';

/// Shared scaffold for full-screen game screens.
///
/// Every game uses the same shell: a transparent [AppBar] floating over a
/// full-bleed animated background (gradient + particles), with the interactive
/// content laid out inside a [SafeArea]. This widget centralises that pattern
/// and, crucially, the two layout guarantees every game needs:
///
///  1. The AppBar is *truly* transparent under Material 3 — `surfaceTintColor`
///     and `scrolledUnderElevation` are disabled, otherwise M3 paints an
///     opaque tint band over the background.
///  2. The body can never be laid out wider than the physical screen, so
///     content can't be cropped or pushed off the right edge (and button
///     hit-targets can't drift off-screen) if an ancestor hands down oversized
///     width constraints.
///
/// Layer order (bottom → top):
///   [background] … → SafeArea(content) → [overlays] …
class GameScaffold extends StatelessWidget {
  const GameScaffold({
    super.key,
    required this.onBack,
    required this.body,
    this.title,
    this.onHelp,
    this.leading,
    this.background = const [],
    this.overlays = const [],
  });

  /// Called by the default back button. The host decides what "back" means
  /// (e.g. confirm-exit while a game is running vs. pop the route).
  final VoidCallback onBack;

  /// Main interactive content. Receives a [SafeArea] and a width clamp.
  final Widget body;

  /// AppBar title (usually only shown on the setup screen).
  final Widget? title;

  /// If non-null, a help/? action is shown in the AppBar.
  final VoidCallback? onHelp;

  /// Optional custom leading widget; defaults to a back button.
  final Widget? leading;

  /// Full-bleed background layers (gradient, particles…), painted behind the
  /// content. Passed straight into the body [Stack] so their constraints are
  /// identical to a hand-rolled Scaffold + Stack.
  final List<Widget> background;

  /// Foreground layers painted above the content (confetti, celebrations…).
  final List<Widget> overlays;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: leading ??
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
              onPressed: onBack,
            ),
        title: title,
        actions: onHelp != null
            ? [
                IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.white70),
                  onPressed: onHelp,
                ),
              ]
            : null,
      ),
      body: Stack(
        children: [
          ...background,
          SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width,
              ),
              child: body,
            ),
          ),
          ...overlays,
        ],
      ),
    );
  }
}
