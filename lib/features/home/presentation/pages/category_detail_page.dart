import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/api_category_detail_model.dart';
import '../providers/category_detail_provider.dart';
import 'home_screen.dart' show kTeal, ArabesquePainter;
import 'judul_detail_page.dart';

// ─────────────────────────────────────────────────────────────
//  PAGE
// ─────────────────────────────────────────────────────────────
class CategoryDetailPage extends ConsumerWidget {
  const CategoryDetailPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.isPremium = false,
  });

  final int categoryId;
  final String categoryName;
  final bool isPremium;

  static const _headerHeight = 200.0;
  static const _overlap = 90.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPad = MediaQuery.of(context).padding.top;
    final detailAsync = ref.watch(categoryDetailProvider(categoryId));

    return Scaffold(
      backgroundColor: kTeal,
      body: Stack(
        children: [
          // ── Layer 1: teal + arabesque ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
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
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: detailAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: kTeal, strokeWidth: 2),
                ),
                error: (e, _) => _ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(categoryDetailProvider(categoryId)),
                ),
                data: (detail) => _JudulList(
                  judul: detail.judul,
                  categoryIsPremium: detail.isPremium,
                ),
              ),
            ),
          ),

          // ── Layer 3: header + back button ──
          Positioned(
            top: topPad,
            left: 0,
            right: 0,
            height: _headerHeight,
            child: _Header(title: categoryName),
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
  const _Header({required this.title});
  final String title;

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
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              'Pilih materi yang ingin dipelajari',
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
//  JUDUL LIST — gaya daftar isi
// ─────────────────────────────────────────────────────────────
class _JudulList extends StatelessWidget {
  const _JudulList({required this.judul, this.categoryIsPremium = false});
  final List<ApiJudulItem> judul;
  final bool categoryIsPremium;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (judul.isEmpty) {
      return Center(
        child: Text(
          'Belum ada materi',
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Label "DAFTAR ISI" ──
          Row(
            children: [
              Container(
                width: 3, height: 18,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'DAFTAR MATERI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Divider(
                  color: cs.outline.withValues(alpha: 0.5), height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${judul.length} Materi',
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
                  for (var i = 0; i < judul.length; i++)
                    _JudulTocItem(
                      item: judul[i],
                      isLast: i == judul.length - 1,
                      categoryIsPremium: categoryIsPremium,
                    ),
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
//  JUDUL TOC ITEM
// ─────────────────────────────────────────────────────────────
class _JudulTocItem extends StatelessWidget {
  const _JudulTocItem({
    required this.item,
    required this.isLast,
    this.categoryIsPremium = false,
  });

  final ApiJudulItem item;
  final bool isLast;
  final bool categoryIsPremium;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final itemIsPremium = item.isPremium || categoryIsPremium;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.isAvailable
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JudulDetailPage(
                          judulId: item.id,
                          judulName: item.judul,
                        ),
                      ),
                    )
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // ── Judul + sub-info ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.judul,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: item.isAvailable
                                      ? cs.onSurface
                                      : cs.onSurface.withValues(alpha: 0.4),
                                  height: 1.4,
                                ),
                              ),
                            ),
                            if (itemIsPremium) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.workspace_premium_rounded,
                                  size: 13, color: Colors.amber),
                            ],
                          ],
                        ),
                        if (item.subtitles.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${item.subtitles.length} materi',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                        if (!item.isAvailable) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Belum tersedia',
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurface.withValues(alpha: 0.35),
                              fontStyle: FontStyle.italic,
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
                    child: CustomPaint(
                      painter: _DottedLinePainter(cs.outline),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ── Ikon kanan ──
                  if (!item.isAvailable)
                    Icon(Icons.schedule_rounded,
                        size: 18,
                        color: cs.onSurface.withValues(alpha: 0.3))
                  else if (itemIsPremium)
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

    const dotSize = 1.5;
    const gapSize = 4.0;
    final y = size.height / 2;
    var x = 0.0;

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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Gagal memuat materi',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(
                backgroundColor: kTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
