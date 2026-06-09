import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kamasutra_app/shared/widgets/game_scaffold.dart';

void main() {
  group('GameScaffold', () {
    Widget wrap(Widget child) => MaterialApp(
          home: child,
        );

    testWidgets('renders the body, background and overlays', (tester) async {
      await tester.pumpWidget(wrap(
        GameScaffold(
          onBack: () {},
          background: const [
            ColoredBox(color: Color(0xFF111111), key: Key('bg')),
          ],
          overlays: const [
            ColoredBox(color: Color(0x88FFFFFF), key: Key('overlay')),
          ],
          body: const Center(child: Text('hello', key: Key('body'))),
        ),
      ));

      expect(find.byKey(const Key('bg')), findsOneWidget);
      expect(find.byKey(const Key('body')), findsOneWidget);
      expect(find.byKey(const Key('overlay')), findsOneWidget);
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('AppBar is fully transparent (M3 surfaceTint disabled)',
        (tester) async {
      await tester.pumpWidget(wrap(
        GameScaffold(
          onBack: () {},
          body: const SizedBox.shrink(),
        ),
      ));

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      // The two layout-fixing knobs from commit d4a7ed0.
      expect(appBar.backgroundColor, Colors.transparent);
      expect(appBar.surfaceTintColor, Colors.transparent);
      expect(appBar.scrolledUnderElevation, 0);
      expect(appBar.elevation, 0);
    });

    testWidgets('tapping the default back button calls onBack', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrap(
        GameScaffold(
          onBack: () => taps++,
          body: const SizedBox.shrink(),
        ),
      ));

      await tester.tap(find.byIcon(Icons.arrow_back_ios));
      expect(taps, 1);
    });

    testWidgets('a help action appears only when onHelp is provided',
        (tester) async {
      await tester.pumpWidget(wrap(
        GameScaffold(
          onBack: () {},
          body: const SizedBox.shrink(),
        ),
      ));
      expect(find.byIcon(Icons.help_outline), findsNothing);

      await tester.pumpWidget(wrap(
        GameScaffold(
          onBack: () {},
          onHelp: () {},
          body: const SizedBox.shrink(),
        ),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('body width is clamped to the screen', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(
        GameScaffold(
          onBack: () {},
          body: SizedBox(
            key: const Key('body'),
            width: double.infinity,
            height: 100,
          ),
        ),
      ));

      final bodyRect = tester.getRect(find.byKey(const Key('body')));
      expect(bodyRect.width, lessThanOrEqualTo(400));
    });
  });
}
