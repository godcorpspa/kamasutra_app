import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/theme.dart';
import '../../../data/models/position.dart';

/// A position's illustration presented as an "art print": a parchment plate
/// with the artwork multiplied onto it, so the white background of the
/// line-art assets melts into the paper instead of showing as a white box.
///
/// Positions whose asset is still the generic template placeholder (or has
/// no file yet) get an editorial monogram instead. SVG, PNG, JPG and WebP
/// are supported and detection is content-based, so every real illustration
/// dropped into assets/images/positions/ shows up automatically with no
/// code change.
class PositionIllustration extends StatelessWidget {
  final Position position;
  final BorderRadius borderRadius;
  final double monogramSize;

  const PositionIllustration({
    super.key,
    required this.position,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadius.lg)),
    this.monogramSize = 56,
  });

  /// Marker text present only in the generated placeholder SVGs.
  static const _placeholderMarker = '>Illustrazione<';

  static const _extensions = ['svg', 'png', 'jpg', 'jpeg', 'webp'];

  static final Map<String, Future<_Artwork?>> _cache = {};

  /// Finds the artwork for [ref] in assets/images/positions/.
  ///
  /// [ref] may carry an extension ("cowgirl.svg") or not ("cowgirl"). The
  /// named file is tried first, then the same base name in every supported
  /// format — so a real `cowgirl.png` dropped next to a placeholder
  /// `cowgirl.svg` is picked up without editing the positions JSON.
  /// Returns null when only a placeholder (or nothing) exists.
  static Future<_Artwork?> _artwork(String ref) =>
      _cache.putIfAbsent(ref, () async {
        final dot = ref.lastIndexOf('.');
        final hasExtension = dot > 0 &&
            _extensions.contains(ref.substring(dot + 1).toLowerCase());
        final base = hasExtension ? ref.substring(0, dot) : ref;
        final candidates = {
          if (hasExtension) ref,
          for (final ext in _extensions) '$base.$ext',
        };
        for (final name in candidates) {
          final path = 'assets/images/positions/$name';
          try {
            if (name.toLowerCase().endsWith('.svg')) {
              final svg = await rootBundle.loadString(path);
              if (svg.contains(_placeholderMarker)) continue;
              return _Artwork(svg: svg);
            }
            final data = await rootBundle.load(path);
            return _Artwork(bytes: data.buffer.asUint8List());
          } catch (_) {
            // Not bundled in this format — try the next one.
          }
        }
        return null;
      });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: ColoredBox(
        color: AppColors.parchment,
        child: FutureBuilder<_Artwork?>(
          future: _artwork(position.illustrationRef),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox.expand();
            }
            final artwork = snapshot.data;
            if (artwork == null) {
              return _Monogram(
                letter: _initial(position.getName(context.locale.languageCode)),
                size: monogramSize,
              );
            }
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  AppColors.parchment,
                  BlendMode.multiply,
                ),
                child: artwork.svg != null
                    ? SvgPicture.string(artwork.svg!, fit: BoxFit.contain)
                    : LayoutBuilder(
                        builder: (context, constraints) => Image.memory(
                          artwork.bytes!,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          // Decode at display size, not full resolution:
                          // the catalog can show ~150 of these.
                          cacheWidth: constraints.maxWidth.isFinite
                              ? (constraints.maxWidth *
                                      MediaQuery.devicePixelRatioOf(context))
                                  .round()
                              : null,
                        ),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  static String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '·' : trimmed.characters.first.toUpperCase();
  }
}

class _Monogram extends StatelessWidget {
  final String letter;
  final double size;

  const _Monogram({required this.letter, required this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            letter,
            style: TextStyle(
              fontFamily: AppTypography.displayFont,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              fontSize: size,
              height: 1.0,
              color: AppColors.wine.withOpacity(0.78),
            ),
          ),
          SizedBox(height: size * 0.12),
          Container(
            width: size * 0.42,
            height: 1,
            color: AppColors.wine.withOpacity(0.28),
          ),
        ],
      ),
    );
  }
}

/// Loaded artwork: either SVG source or encoded raster bytes.
class _Artwork {
  final String? svg;
  final Uint8List? bytes;

  const _Artwork({this.svg, this.bytes});
}
