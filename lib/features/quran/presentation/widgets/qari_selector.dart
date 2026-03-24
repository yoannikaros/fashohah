import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/quran_provider.dart';

class QariSelector extends ConsumerWidget {
  const QariSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedQari = ref.watch(selectedQariProvider);
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      initialValue: selectedQari,
      onSelected: (id) => ref.read(selectedQariProvider.notifier).state = id,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      offset: const Offset(0, 8),
      color: cs.surface,
      elevation: 4,
      itemBuilder: (context) => kQariNames.entries
          .map(
            (e) => PopupMenuItem(
              value: e.key,
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: e.key == selectedQari
                        ? Icon(Icons.check_rounded,
                            size: 16, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Text(e.value, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          )
          .toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Icon(
          Icons.mic_none_rounded,
          size: 22,
          color: cs.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
