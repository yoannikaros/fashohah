import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/dzikir_item.dart';
import '../providers/bookmark_provider.dart';
import '../providers/counter_provider.dart';

class DzikirCard extends ConsumerWidget {
  const DzikirCard({
    super.key,
    required this.item,
    required this.onTap,
    this.showBookmark = true,
  });

  final DzikirItem item;
  final VoidCallback onTap;
  final bool showBookmark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(dzikirCounterProvider(item.id));
    final isBookmarked = ref.watch(bookmarkProvider.select((s) => s.contains(item.id)));
    final arabicFontSize = ref.watch(arabicFontSizeProvider);
    final isDone = count >= item.targetCount;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDone
              ? AppColors.primary.withValues(alpha: 0.08)
              : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone
                ? AppColors.primary.withValues(alpha: 0.3)
                : cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (showBookmark)
                  GestureDetector(
                    onTap: () => ref.read(bookmarkProvider.notifier).toggle(item.id),
                    child: Icon(
                      isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      size: 20,
                      color: isBookmarked ? AppColors.primary : cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Arabic text
            Text(
              item.arabic,
              textAlign: TextAlign.right,
              style: GoogleFonts.amiri(
                fontSize: arabicFontSize,
                height: 2.0,
                color: cs.onSurface,
              ),
              textDirection: TextDirection.rtl,
            ),

            const SizedBox(height: 8),

            // Counter chip + progress
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.primary
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count/${item.targetCount}x',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDone ? Colors.white : cs.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isDone)
                  Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
