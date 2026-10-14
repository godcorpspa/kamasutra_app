import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../app/theme.dart';
import '../../../data/models/position.dart';
import 'category_style.dart';
import 'position_illustration.dart';

/// A card displaying a position preview: the illustration as an art print,
/// then category, name, alias and difficulty in an editorial stack.
class PositionCard extends StatelessWidget {
  final Position position;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool showFavorite;

  const PositionCard({
    super.key,
    required this.position,
    this.onTap,
    this.onFavoriteTap,
    this.showFavorite = true,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final category = position.categories.first;
    final alias = position.getAlias(lang);

    return Material(
      color: AppColors.inkRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: const BorderSide(color: AppColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: PositionIllustration(
                        position: position,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    if (showFavorite)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: _FavoriteButton(
                          isFavorite: position.isFavorite,
                          onTap: onFavoriteTap,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(7, 12, 7, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'categories.${category.name}'.tr().toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.eyebrow.copyWith(
                        fontSize: 9.5,
                        letterSpacing: 1.4,
                        color: category.tint,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      position.getName(lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTypography.displayFont,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: AppColors.ivory,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alias != null && alias.isNotEmpty ? alias : ' ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: AppColors.mist,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DifficultyMeter(difficulty: position.difficulty),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback? onTap;

  const _FavoriteButton({required this.isFavorite, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Sits directly on the parchment plate, so it is drawn in wine ink
    // rather than on a disc of its own.
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            size: 19,
            color: isFavorite
                ? AppColors.wine
                : AppColors.wine.withOpacity(0.45),
          ),
        ),
      ),
    );
  }
}
