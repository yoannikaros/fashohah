import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_screen.dart' show kTeal, ArabesquePainter;
import '../../data/models/api_category_model.dart';
import '../providers/category_provider.dart';
import 'category_detail_page.dart';

// ─────────────────────────────────────────────────────────────
//  PAGE
// ─────────────────────────────────────────────────────────────
class CategoryPage extends ConsumerWidget {
  const CategoryPage({super.key});

  static const _headerHeight = 200.0;
  static const _overlap      = 90.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPad         = MediaQuery.of(context).padding.top;
    final categoriesAsync = ref.watch(apiCategoryProvider);
    final cs             = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: kTeal,
      body: Stack(
        children: [
          // ── Layer 1: teal + arabesque ──
          Positioned(
            top: 0, left: 0, right: 0,
            height: _headerHeight + topPad,
            child: Container(
              color: kTeal,
              child: CustomPaint(painter: ArabesquePainter()),
            ),
          ),

          // ── Layer 2: konten scrollable ──
          Positioned.fill(
            top: _headerHeight + topPad - _overlap,
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.only(
                  topLeft:  Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: categoriesAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: cs.primary, strokeWidth: 2,
                  ),
                ),
                error: (e, _) => _ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(apiCategoryProvider),
                ),
                data: (categories) => _TableOfContents(categories: categories),
              ),
            ),
          ),

          // ── Layer 3: header ──
          Positioned(
            top: topPad, left: 0, right: 0,
            height: _headerHeight,
            child: const _Header(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 30, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
              const Text(
                'Semua Kategori',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              'Pilih kategori yang ingin kamu pelajari',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TABLE OF CONTENTS
// ─────────────────────────────────────────────────────────────
class _TableOfContents extends StatelessWidget {
  const _TableOfContents({required this.categories});
  final List<ApiCategory> categories;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Label "DAFTAR ISI" ──
          Row(
            children: [
              Container(width: 3, height: 18,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(2),
                  )),
              const SizedBox(width: 8),
              Text(
                'DAFTAR ISI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Divider(color: cs.outline.withValues(alpha: 0.5), height: 1),
              ),
              const SizedBox(width: 8),
              Text(
                '${categories.length} Bab',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Satu container daftar isi ──
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  for (var i = 0; i < categories.length; i++) ...[
                    _TocItem(
                      category: categories[i],
                      isLast: i == categories.length - 1,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TOC ITEM — satu baris daftar isi
// ─────────────────────────────────────────────────────────────
class _TocItem extends StatelessWidget {
  const _TocItem({
    required this.category,
    required this.isLast,
  });

  final ApiCategory category;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryDetailPage(
                  categoryId: category.id,
                  categoryName: category.namaKategori,
                  isPremium: category.isPremium,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // ── Nama kategori ──
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            category.namaKategori,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface,
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (category.isPremium) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.workspace_premium_rounded,
                                    size: 10, color: Colors.amber),
                                SizedBox(width: 3),
                                Text(
                                  'Premium',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.amber,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ── Garis titik-titik ──
                  SizedBox(
                    width: 48,
                    child: CustomPaint(painter: _DottedLinePainter(cs.outline)),
                  ),

                  const SizedBox(width: 8),

                  // ── Ikon premium atau chevron ──
                  if (category.isPremium)
                    Icon(Icons.lock_outline_rounded,
                        size: 18,
                        color: Colors.amber.withValues(alpha: 0.7))
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: cs.onSurface.withValues(alpha: 0.3),
                    ),
                ],
              ),
            ),
          ),
        ),

        // ── Divider antar baris ──
        if (!isLast)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: cs.outline.withValues(alpha: 0.4),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DOTTED LINE PAINTER
// ─────────────────────────────────────────────────────────────
class _DottedLinePainter extends CustomPainter {
  const _DottedLinePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const dotSize   = 1.5;
    const gapSize   = 4.0;
    final y         = size.height / 2;
    var x           = 0.0;

    while (x < size.width) {
      canvas.drawCircle(Offset(x, y), dotSize / 2, paint);
      x += dotSize + gapSize;
    }
  }

  @override
  bool shouldRepaint(_DottedLinePainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────
//  ERROR VIEW
// ─────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text('Gagal memuat kategori',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
