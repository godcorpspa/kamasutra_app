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
/// Positions whose asset is still the generic template placeholder get an
/// editorial monogram instead. Detection is content-based, so every real
/// illustration dropped into assets/images/positions/ shows up automatically
/// with no code change.
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

  static final Map<String, Future<String?>> _cache = {};

  /// The SVG source for [ref], or null when it is a placeholder or missing.
  static Future<String?> _artwork(String ref) => _cache.putIfAbsent(ref, () async {
        try {
          final svg =
              await rootBundle.loadString('assets/images/positions/$ref');
          return svg.contains(_placeholderMarker) ? null : svg;
        } catch (_) {
          return null;
        }
      });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: ColoredBox(
        color: AppColors.parchment,
        child: FutureBuilder<String?>(
          future: _artwork(position.illustrationRef),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox.expand();
            }
            final svg = snapshot.data;
            if (svg == null) {
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
                child: SvgPicture.string(svg, fit: BoxFit.contain),
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
