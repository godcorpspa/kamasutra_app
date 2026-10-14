// Layout regression test for the full-screen game shells.
//
// Renders each game at real phone sizes, in Italian (the app's default
// locale), with the fonts the device actually renders and the app theme, and
// asserts that rendering raises no framework error (overflow, or an
// exception thrown inside a painter) and that no text lies outside the
// screen.
//
// Run with --dart-define=GAME_LAYOUT_SCREENSHOTS=1 to also write a PNG of
// every case to build/game_layout/ for visual inspection.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kamasutra_app/app/theme.dart';
import 'package:kamasutra_app/features/games/intimacy_map/presentation/intimacy_map_screen.dart';
import 'package:kamasutra_app/features/games/mirror_challenge/presentation/mirror_challenge_screen.dart';
import 'package:kamasutra_app/features/games/two_minutes/presentation/two_minutes_screen.dart';

const _screenshots =
    String.fromEnvironment('GAME_LAYOUT_SCREENSHOTS') == '1';

/// Common Android/iOS logical sizes, narrowest first.
const _phones = <String, Size>{
  '360x800': Size(360, 800),
  '393x852': Size(393, 852),
  '411x914': Size(411, 914),
};

final _games = <String, Widget Function()>{
  'two_minutes': () => const TwoMinutesScreen(),
  'intimacy_map': () => const IntimacyMapScreen(),
  // Control: a game the user confirmed renders correctly.
  'mirror_challenge': () => const MirrorChallengeScreen(),
};

/// Font files declared in pubspec.yaml, per family — read from the pubspec
/// itself so the test always loads exactly what the app bundles.
Map<String, List<String>> _appFonts() {
  final families = <String, List<String>>{};
  String? current;
  for (final line in File('pubspec.yaml').readAsLinesSync()) {
    final family = RegExp(r'^\s*- family:\s*(\S+)').firstMatch(line);
    if (family != null) {
      current = family.group(1)!;
      families[current] = [];
      continue;
    }
    final asset = RegExp(r'^\s*- asset:\s*(\S+)').firstMatch(line);
    if (asset != null && current != null) {
      families[current]!.add(asset.group(1)!);
    }
  }
  return families;
}

/// True when [bytes] start with a TrueType/OpenType signature.
bool _isFont(Uint8List bytes) {
  if (bytes.length < 4) return false;
  final tag = String.fromCharCodes(bytes.sublist(0, 4));
  return tag == 'OTTO' ||
      tag == 'true' ||
      tag == 'ttcf' ||
      (bytes[0] == 0 && bytes[1] == 1 && bytes[2] == 0 && bytes[3] == 0);
}

/// The SDK's bundled Material fonts (Roboto + icons), located from the
/// test runner's own executable so it works without FLUTTER_ROOT.
Directory? _materialFontsDir() {
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    final candidate = Directory('${dir.path}/artifacts/material_fonts');
    if (candidate.existsSync()) return candidate;
    dir = dir.parent;
  }
  return null;
}

Future<void> _loadFont(String family, List<Uint8List> fonts) async {
  final loader = FontLoader(family);
  for (final bytes in fonts) {
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    final it = jsonDecode(File('assets/lang/it.json').readAsStringSync())
        as Map<String, dynamic>;
    Localization.load(const Locale('it'), translations: Translations(it));

    // Reproduce what the device actually renders: the app font when the
    // asset is a real font file, otherwise the platform fallback (Roboto on
    // Android). Without this the test would measure the 'Ahem' test font,
    // whose square glyphs are far wider than any real font.
    final material = _materialFontsDir();
    final roboto = [
      for (final name in ['Regular', 'Medium', 'Bold', 'Italic'])
        if (material != null && File('${material.path}/Roboto-$name.ttf').existsSync())
          File('${material.path}/Roboto-$name.ttf').readAsBytesSync(),
    ];
    await _loadFont('Roboto', roboto);
    for (final entry in _appFonts().entries) {
      final valid = [
        for (final path in entry.value)
          if (_isFont(File(path).readAsBytesSync())) File(path).readAsBytesSync(),
      ];
      await _loadFont(entry.key, valid.isNotEmpty ? valid : roboto);
    }
    final icons = File('${material?.path}/MaterialIcons-Regular.otf');
    if (icons.existsSync()) {
      await _loadFont('MaterialIcons', [icons.readAsBytesSync()]);
    }
  });

  for (final game in _games.entries) {
    for (final phone in _phones.entries) {
      testWidgets('${game.key} setup view fits a ${phone.key} screen',
          (tester) async {
        final view = tester.view;
        view.devicePixelRatio = 1.0;
        view.physicalSize = phone.value;
        addTearDown(view.reset);

        // Collect every framework error instead of failing on the first:
        // RenderFlex overflows, and above all exceptions thrown inside a
        // CustomPainter. The latter are the nasty ones — the framework skips
        // the painter's canvas.restore(), so everything painted afterwards
        // inherits the painter's translation and renders shifted/cut off
        // while layout and hit-testing stay correct.
        final errors = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) {
          errors.add(details.exceptionAsString().split('\n').first);
        };

        final boundary = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme,
              home: game.value(),
            ),
          ),
        );
        // The screens run repeating animations, so pumpAndSettle would
        // never settle: advance a fixed amount of time instead.
        await tester.pump(const Duration(milliseconds: 800));

        if (_screenshots) {
          final ro = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final png = await tester.runAsync(() async {
            final image = await ro.toImage(pixelRatio: 1.0);
            final data =
                await image.toByteData(format: ui.ImageByteFormat.png);
            return data!.buffer.asUint8List();
          });
          final out = File('build/game_layout/${game.key}_${phone.key}.png');
          out.parent.createSync(recursive: true);
          out.writeAsBytesSync(png!);
        }

        // Every visible piece of text must sit fully inside the screen
        // and must not be clipped/ellipsized by its own box.
        final width = phone.value.width;
        final offenders = <String>[];
        void visit(RenderObject ro) {
          if (ro is RenderParagraph && ro.hasSize && ro.attached) {
            final text = ro.text.toPlainText().trim();
            if (text.isNotEmpty) {
              final topLeft = ro.localToGlobal(Offset.zero);
              final right = topLeft.dx + ro.size.width;
              if (topLeft.dx < -0.5 || right > width + 0.5) {
                offenders.add('"$text" spans x=${topLeft.dx.toStringAsFixed(1)}'
                    '..${right.toStringAsFixed(1)} (screen $width)');
              }
              if (ro.didExceedMaxLines) {
                offenders.add('"$text" is truncated');
              }
            }
          }
          ro.visitChildren(visit);
        }

        tester.binding.renderViews.forEach(visit);

        // Must be restored before any expect(), or a failing expectation
        // leaves the test binding in a state where the runner hangs.
        FlutterError.onError = previous;
        expect(errors, isEmpty,
            reason: 'framework errors while rendering:\n${errors.join('\n')}');
        expect(offenders, isEmpty,
            reason: 'text outside the screen:\n${offenders.join('\n')}');
      });
    }
  }
}
