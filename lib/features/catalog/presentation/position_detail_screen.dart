import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/services/preferences_service.dart';

import '../../../app/theme.dart';
import '../../../data/models/position.dart';
import '../../../data/providers/providers.dart';
import '../widgets/category_style.dart';
import '../widgets/position_illustration.dart';

class PositionDetailScreen extends ConsumerStatefulWidget {
  final String positionId;

  const PositionDetailScreen({
    super.key,
    required this.positionId,
  });

  @override
  ConsumerState<PositionDetailScreen> createState() => _PositionDetailScreenState();
}

class _PositionDetailScreenState extends ConsumerState<PositionDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Record view
    Future.microtask(() {
      ref.read(positionRepositoryProvider).recordView(widget.positionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    // Watching the loader (not just the repository) makes the screen work
    // when opened directly — e.g. Android restoring the app on this route —
    // instead of reporting "not found" until the catalog was visited.
    final positionsAsync = ref.watch(positionsProvider(locale));
    final repo = ref.watch(positionRepositoryProvider);
    final position = repo.getById(widget.positionId);

    if (position == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: positionsAsync.isLoading
              ? const CircularProgressIndicator()
              : Text('errors.no_positions'.tr()),
        ),
      );
    }

    final category = position.categories.first;
    final alias = position.getAlias(locale);
    final tried = PreferencesService.instance.isTriedPosition(widget.positionId);
    final topInset = MediaQuery.of(context).padding.top;
    final plateSize = MediaQuery.of(context).size.width - AppSpacing.md * 2;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Art print header
          SliverAppBar(
            // The background spans the status bar too, so only the toolbar
            // and a small gap sit above the plate.
            expandedHeight: kToolbarHeight + AppSpacing.sm + plateSize,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.ink,
            leading: _GlassButton(
              icon: Icons.arrow_back,
              onPressed: () => context.pop(),
            ),
            actions: [
              _GlassButton(
                icon: position.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: position.isFavorite ? AppColors.rose : AppColors.ivory,
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await repo.toggleFavorite(position.id);
                  if (mounted) {
                    ref.invalidate(positionsProvider(locale));
                    setState(() {});
                  }
                },
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  topInset + kToolbarHeight + AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox.square(
                    dimension: plateSize,
                    child: PositionIllustration(
                      position: position,
                      borderRadius: BorderRadius.circular(28),
                      monogramSize: 132,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'categories.${category.name}'.tr().toUpperCase(),
                    style: AppTypography.eyebrow.copyWith(color: category.tint),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    position.getName(locale),
                    style: Theme.of(context).textTheme.displaySmall,
                  ).animate().fadeIn().slideY(begin: 0.15),
                  if (alias != null && alias.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      alias,
                      style: const TextStyle(
                        fontFamily: AppTypography.displayFont,
                        fontStyle: FontStyle.italic,
                        fontSize: 18,
                        color: AppColors.mist,
                      ),
                    ).animate().fadeIn(delay: 80.ms),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  // Key facts
                  _FactsRow(position: position)
                      .animate()
                      .fadeIn(delay: 160.ms),

                  // Categories & focus
                  const SizedBox(height: AppSpacing.xl),
                  _Section(
                    title: 'catalog.category'.tr(),
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final cat in position.categories)
                          _Tag(
                            label: 'categories.${cat.name}'.tr(),
                            icon: cat.icon,
                            tint: cat.tint,
                          ),
                      ],
                    ),
                  ),
                  if (position.focus.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _Section(
                      title: 'catalog.focus'.tr(),
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final f in position.focus)
                            _Tag(label: 'focus.${f.name}'.tr()),
                        ],
                      ),
                    ),
                  ],

                  // Setup instructions
                  if (position.getSetup(locale)?.isNotEmpty ?? false) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _Section(
                      title: 'position.setup'.tr(),
                      child: _SetupSteps(text: position.getSetup(locale)!),
                    ),
                  ],

                  // Prerequisites
                  if (position.prerequisites.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _Section(
                      title: 'position.prerequisites'.tr(),
                      child: Column(
                        children: [
                          for (final prereq in position.prerequisites)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(Icons.check, size: 18,
                                        color: AppColors.champagne),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(child: Text(prereq)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  // Cautions
                  if (position.getCautions(locale)?.isNotEmpty ?? false) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _Callout(
                      icon: Icons.error_outline,
                      tint: AppColors.jewelEmber,
                      title: 'position.cautions'.tr(),
                      body: position.getCautions(locale)!,
                    ),
                  ],

                  // Easy variant
                  if (position.getEasyVariant(locale)?.isNotEmpty ?? false) ...[
                    const SizedBox(height: AppSpacing.md),
                    _Callout(
                      icon: Icons.spa_outlined,
                      tint: AppColors.jewelSage,
                      title: 'position.easy_version'.tr(),
                      body: position.getEasyVariant(locale)!,
                    ),
                  ],

                  // Check-in prompt, set as a pull quote
                  if (position.getCheckin(locale)?.isNotEmpty ?? false) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _Section(
                      title: 'position.check_in'.tr(),
                      child: Container(
                        padding: const EdgeInsets.only(left: AppSpacing.md),
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(
                                color: AppColors.champagne, width: 1.5),
                          ),
                        ),
                        child: Text(
                          position.getCheckin(locale)!,
                          style: const TextStyle(
                            fontFamily: AppTypography.displayFont,
                            fontStyle: FontStyle.italic,
                            fontSize: 19,
                            height: 1.45,
                            color: AppColors.ivory,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Tags
                  if (position.tags.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _Section(
                      title: 'position.tags'.tr(),
                      child: Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final tag in position.tags)
                            Text(
                              '#$tag',
                              style: const TextStyle(
                                color: AppColors.mist,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  // Similar positions
                  const SizedBox(height: AppSpacing.xxl),
                  _buildSimilarPositions(context, locale, position),
                ],
              ),
            ),
          ),
        ],
      ),

      // Try this button
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.ink,
          border: Border(top: BorderSide(color: AppColors.hairline)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
            child: tried
                ? OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text('shuffle.tried'.tr()),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      disabledForegroundColor: AppColors.champagne,
                      side: const BorderSide(color: AppColors.outline),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      PreferencesService.instance
                          .addTriedPosition(widget.positionId);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: Text('position.try_this'.tr()),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimilarPositions(
    BuildContext context,
    String locale,
    Position position,
  ) {
    final repo = ref.watch(positionRepositoryProvider);
    final similar = repo.getSimilar(position.id, limit: 6);

    if (similar.isEmpty) return const SizedBox.shrink();

    return _Section(
      title: 'position.similar_positions'.tr(),
      child: SizedBox(
        height: 196,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: similar.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final p = similar[index];
            return GestureDetector(
              onTap: () => context.push('/catalog/${p.id}'),
              child: SizedBox(
                width: 132,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox.square(
                      dimension: 132,
                      child: PositionIllustration(
                        position: p,
                        monogramSize: 46,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      p.getName(locale),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTypography.displayFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Difficulty · energy · duration, separated by hairlines.
class _FactsRow extends StatelessWidget {
  final Position position;

  const _FactsRow({required this.position});

  @override
  Widget build(BuildContext context) {
    Widget fact(String label, Widget value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.eyebrow.copyWith(fontSize: 10)),
              const SizedBox(height: 8),
              value,
            ],
          ),
        );
    const valueStyle = TextStyle(
      fontFamily: AppTypography.displayFont,
      fontFeatures: AppTypography.lining,
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: AppColors.ivory,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.hairline),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            fact(
              'position.difficulty'.tr(),
              Row(children: [
                Text('${position.difficulty}/5', style: valueStyle),
                const SizedBox(width: 10),
                DifficultyMeter(difficulty: position.difficulty, barWidth: 6),
              ]),
            ),
            const VerticalDivider(width: 24, color: AppColors.hairline),
            fact('position.energy'.tr(),
                Text('energy.${position.energy.name}'.tr(), style: valueStyle)),
            const VerticalDivider(width: 24, color: AppColors.hairline),
            fact(
                'position.duration'.tr(),
                Text('duration.${position.duration.name}'.tr(),
                    style: valueStyle)),
          ],
        ),
      ),
    );
  }
}

/// The setup as a numbered list that can be read at a glance: the first
/// [_visibleSteps] steps (getting into position) are shown, the refinements
/// that follow sit behind a "show all" toggle. Unnumbered setups (one-line
/// descriptions) render as a plain paragraph.
class _SetupSteps extends StatefulWidget {
  final String text;

  const _SetupSteps({required this.text});

  @override
  State<_SetupSteps> createState() => _SetupStepsState();
}

class _SetupStepsState extends State<_SetupSteps> {
  static const _visibleSteps = 3;
  static final _stepStart = RegExp(r'^\s*\d+[.)]\s*', multiLine: true);

  bool _expanded = false;

  List<String> get _steps => widget.text
      .split(_stepStart)
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.ivory.withOpacity(0.86),
          height: 1.55,
        );
    final steps = _steps;
    if (!_stepStart.hasMatch(widget.text) || steps.length < 2) {
      return Text(widget.text.trim(), style: bodyStyle);
    }

    final collapsible = steps.length > _visibleSteps;
    final shown =
        _expanded || !collapsible ? steps : steps.take(_visibleSteps).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: AppDurations.normal,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < shown.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontFamily: AppTypography.displayFont,
                            fontFeatures: AppTypography.lining,
                            fontSize: 20,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                            color: AppColors.champagne,
                          ),
                        ),
                      ),
                      Expanded(child: Text(shown[i], style: bodyStyle)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (collapsible)
          TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            icon: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              size: 20,
            ),
            label: Text(
              _expanded
                  ? 'position.show_fewer_steps'.tr()
                  : 'position.show_all_steps'
                      .tr(namedArgs: {'count': '${steps.length}'}),
            ),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: AppTypography.eyebrow),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// Hairline pill used for categories and focus areas.
class _Tag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color tint;

  const _Tag({required this.label, this.icon, this.tint = AppColors.mist});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.round),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: tint),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.ivory),
          ),
        ],
      ),
    );
  }
}

/// Quiet bordered note with a tinted icon (cautions, easy variant).
class _Callout extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String body;

  const _Callout({
    required this.icon,
    required this.tint,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.inkRaised,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: tint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: tint,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Translucent round button floating over the artwork.
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _GlassButton({
    required this.icon,
    required this.onPressed,
    this.color = AppColors.ivory,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: AppColors.ink.withOpacity(0.6),
        shape: const CircleBorder(side: BorderSide(color: AppColors.hairline)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}
