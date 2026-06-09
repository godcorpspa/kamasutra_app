import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/firebase_status_provider.dart';

/// Small banner shown when Firebase is unavailable, so users understand that
/// login and cloud sync are off and their data stays only on this device.
///
/// Renders nothing when Firebase is available, so it is safe to drop at the
/// top of any screen (e.g. login, settings):
///
/// ```dart
/// const OfflineModeBadge(),
/// ```
class OfflineModeBadge extends ConsumerWidget {
  const OfflineModeBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(firebaseAvailableProvider);
    if (available) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, color: Color(0xFFFFC107), size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              // Falls back to the key text if the translation is missing.
              'common.offline_mode'.tr(),
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFE08A),
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
