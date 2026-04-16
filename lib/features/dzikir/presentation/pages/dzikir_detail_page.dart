import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/dzikir_item.dart';
import '../providers/bookmark_provider.dart';
import '../widgets/dzikir_counter_widget.dart';

class DzikirDetailPage extends ConsumerWidget {
  const DzikirDetailPage({super.key, required this.item});

  final DzikirItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref.watch(bookmarkProvider.select((s) => s.contains(item.id)));
    final arabicFontSize = ref.watch(arabicFontSizeProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.title),
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isBookmarked ? AppColors.primary : null,
            ),
            onPressed: () => ref.read(bookmarkProvider.notifier).toggle(item.id),
            tooltip: isBookmarked ? 'Hapus bookmark' : 'Tambah bookmark',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Arabic ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Text(
                item.arabic,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.amiri(
                  fontSize: arabicFontSize + 4,
                  height: 2.2,
                  color: cs.onSurface,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Latin ────────────────────────────────────────────────
            _SectionLabel('Latin'),
            const SizedBox(height: 6),
            Text(
              item.latin,
              style: TextStyle(
                fontSize: 15,
                height: 1.7,
                fontStyle: FontStyle.italic,
                color: cs.onSurface.withValues(alpha: 0.75),
              ),
            ),

            const SizedBox(height: 16),

            // ── Translation ──────────────────────────────────────────
            _SectionLabel('Artinya'),
            const SizedBox(height: 6),
            Text(
              '"${item.translation}"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
            ),

            const SizedBox(height: 16),

            // ── Reference ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      item.reference,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (item.notes != null) ...[
              const SizedBox(height: 12),
              Text(
                item.notes!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),

            // ── Counter ──────────────────────────────────────────────
            Center(child: DzikirCounterWidget(item: item)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
      ),
    );
  }
}
