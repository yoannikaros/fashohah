import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/dzikir_provider.dart';
import '../widgets/category_card.dart';
import 'dzikir_list_page.dart';

const _kTeal = Color(0xFF00B5A5);
const _kTealPattern = Color(0xFF009D8F);
const _kHeaderHeight = 160.0;
const _kOverlap = 60.0;

class DzikirCategoryPage extends ConsumerWidget {
  const DzikirCategoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(dzikirCategoryListProvider);
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _kTeal,
      body: Stack(
        children: [
          // ── Layer 1: teal + arabesque ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _kHeaderHeight + topPad,
            child: Container(
              color: _kTeal,
              child: CustomPaint(painter: _ArabesquePainter()),
            ),
          ),

          // ── Layer 2: container putih rounded top ──
          Positioned.fill(
            top: _kHeaderHeight + topPad - _kOverlap,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: categoriesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (categories) => GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, i) => CategoryCard(
                    category: categories[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DzikirListPage(
                          categoryId: categories[i].id,
                          categoryName: categories[i].name,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 3: header teks ──
          Positioned(
            top: topPad,
            left: 0,
            right: 0,
            height: _kHeaderHeight,
            child: const Padding(
              padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dzikir & Doa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pilih kategori dzikir yang ingin dibaca',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
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
//  ARABESQUE PAINTER
// ─────────────────────────────────────────────────────────────
class _ArabesquePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = _kTealPattern
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = _kTealPattern
      ..style = PaintingStyle.fill;
    const cw = 68.0, ch = 68.0;
    for (double y = -ch; y < size.height + ch; y += ch) {
      final row = ((y + ch) / ch).floor();
      final ox = (row % 2 == 0) ? 0.0 : cw / 2;
      for (double x = -cw + ox; x < size.width + cw; x += cw) {
        _tile(canvas, stroke, fill, Offset(x, y), cw, ch);
      }
    }
  }

  void _tile(Canvas c, Paint s, Paint f, Offset o, double cw, double ch) {
    final cx = o.dx + cw / 2, cy = o.dy + ch / 2, pr = cw * 0.28;
    _rosette(c, s, f, cx, cy, pr);
    _vines(c, s, cx, cy, pr, cw, ch);
    _teardrops(c, s, cx, cy, cw * .46, cw * .10, cw * .055);
    _hearts(c, s, cx, cy, cw * .50);
  }

  void _rosette(Canvas c, Paint s, Paint f, double cx, double cy, double pr) {
    for (int i = 0; i < 8; i++) {
      final mid = (i + .5) * 2 * math.pi / 8 - math.pi / 2;
      final lft = i * 2 * math.pi / 8 - math.pi / 2;
      final rgt = (i + 1) * 2 * math.pi / 8 - math.pi / 2;
      final tx = cx + pr * math.cos(mid), ty = cy + pr * math.sin(mid);
      final sx = cx + pr * .42 * math.cos(lft),
          sy = cy + pr * .42 * math.sin(lft);
      final ex = cx + pr * .42 * math.cos(rgt),
          ey = cy + pr * .42 * math.sin(rgt);
      final c1x = cx + pr * .78 * math.cos(mid - .28),
          c1y = cy + pr * .78 * math.sin(mid - .28);
      final c2x = cx + pr * .78 * math.cos(mid + .28),
          c2y = cy + pr * .78 * math.sin(mid + .28);
      c.drawPath(
          Path()
            ..moveTo(sx, sy)
            ..cubicTo(c1x, c1y, c1x, c1y, tx, ty)
            ..cubicTo(c2x, c2y, c2x, c2y, ex, ey),
          s);
      c.drawCircle(Offset(tx, ty), 1.4, f);
    }
    c.drawCircle(Offset(cx, cy), pr * .20, s);
    c.drawCircle(Offset(cx, cy), pr * .08, f);
  }

  void _vines(Canvas c, Paint s, double cx, double cy, double pr, double cw,
      double ch) {
    for (final d in [
      Offset(0, -1),
      Offset(1, 0),
      Offset(0, 1),
      Offset(-1, 0)
    ]) {
      final sx = cx + pr * .95 * d.dx, sy = cy + pr * .95 * d.dy;
      final ex = cx + cw / 2 * d.dx, ey = cy + ch / 2 * d.dy;
      final p = Offset(-d.dy, d.dx);
      c.drawPath(
          Path()
            ..moveTo(sx, sy)
            ..cubicTo(
                sx + (ex - sx) * .35 + p.dx * cw * .12,
                sy + (ey - sy) * .35 + p.dy * ch * .12,
                sx + (ex - sx) * .65 - p.dx * cw * .12,
                sy + (ey - sy) * .65 - p.dy * ch * .12,
                ex,
                ey),
          s);
    }
  }

  void _teardrops(Canvas c, Paint s, double cx, double cy, double dist,
      double h, double w) {
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2 + math.pi / 4;
      c.save();
      c.translate(cx + dist * math.cos(a), cy + dist * math.sin(a));
      c.rotate(a + math.pi / 2);
      c.drawPath(
          Path()
            ..moveTo(0, -h / 2)
            ..cubicTo(-w, -h * .1, -w, h * .35, 0, h / 2)
            ..cubicTo(w, h * .35, w, -h * .1, 0, -h / 2)
            ..close(),
          s);
      c.restore();
    }
  }

  void _hearts(Canvas c, Paint s, double cx, double cy, double dist) {
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2 + math.pi / 4;
      const v = 7.0;
      c.save();
      c.translate(cx + dist * math.cos(a), cy + dist * math.sin(a));
      c.rotate(a + math.pi / 4);
      c.drawPath(
          Path()
            ..moveTo(0, v * .5)
            ..cubicTo(-v * .1, v * .15, -v * .5, -v * .05, -v * .5, -v * .25)
            ..cubicTo(-v * .5, -v * .55, 0, -v * .50, 0, -v * .15)
            ..cubicTo(0, -v * .50, v * .5, -v * .55, v * .5, -v * .25)
            ..cubicTo(v * .5, -v * .05, v * .1, v * .15, 0, v * .5)
            ..close(),
          s);
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
