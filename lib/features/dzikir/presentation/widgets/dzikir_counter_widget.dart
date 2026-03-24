import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/dzikir_item.dart';
import '../providers/counter_provider.dart';

class DzikirCounterWidget extends ConsumerWidget {
  const DzikirCounterWidget({super.key, required this.item});

  final DzikirItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(dzikirCounterProvider(item.id));
    final isDone = count >= item.targetCount;
    final progress = (count / item.targetCount).clamp(0.0, 1.0);
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Progress indicator
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(
              isDone ? AppColors.primary : AppColors.primary,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Counter display
        Text(
          '$count',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDone ? AppColors.primary : cs.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
        ),
        Text(
          'dari ${item.targetCount}x',
          style: TextStyle(
            fontSize: 14,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),

        const SizedBox(height: 24),

        // Tap button
        if (!isDone) ...[
          GestureDetector(
            onTap: () => ref.read(dzikirCounterProvider(item.id).notifier).increment(),
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 36),
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Selesai',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Reset
        TextButton(
          onPressed: count > 0
              ? () => ref.read(dzikirCounterProvider(item.id).notifier).reset()
              : null,
          child: const Text('Reset'),
        ),
      ],
    );
  }
}
