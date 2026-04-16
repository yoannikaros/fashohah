import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/prayer_provider.dart';
import '../widgets/month_prayer_list.dart';
import '../widgets/next_prayer_banner.dart';
import '../widgets/today_prayer_card.dart';

const _kTeal = Color(0xFF00B5A5);
const _kTealPattern = Color(0xFF009D8F);
const _kHeaderHeight = 160.0;
const _kOverlap = 70.0;

class PrayerPage extends ConsumerStatefulWidget {
  const PrayerPage({super.key});

  @override
  ConsumerState<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends ConsumerState<PrayerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(prayerAutoLocationProvider);

    final todayAsync = ref.watch(todayPrayerProvider);
    final locationAsync = ref.watch(locationProvider);
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
              child: CustomPaint(painter: _PrayerArabesquePainter()),
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
              child: Column(
                children: [
                  // TabBar di dalam container putih
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Hari Ini'),
                      Tab(text: '1 Bulan'),
                    ],
                    labelColor: _kTeal,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: _kTeal,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                  ),
                  // Konten tab
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Hari Ini
                        todayAsync.when(
                          loading: () => const _LoadingView(),
                          error: (e, _) => _ErrorView(
                            message: e.toString(),
                            onRetry: () => ref.invalidate(todayPrayerProvider),
                          ),
                          data: (today) {
                            if (today == null) return const _EmptyView();
                            return _TodayTab(today: today);
                          },
                        ),
                        // Tab 2: 1 Bulan
                        const _MonthTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Layer 3: header teks + refresh ──
          Positioned(
            top: topPad,
            left: 0,
            right: 0,
            height: _kHeaderHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 8, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jadwal Sholat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        locationAsync.when(
                          data: (loc) => Text(
                            loc.isDefault
                                ? 'Jakarta (Default)'
                                : 'Lokasi saat ini',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 22),
                    onPressed: () {
                      ref.invalidate(todayPrayerProvider);
                      ref.invalidate(selectedMonthPrayerProvider);
                    },
                    tooltip: 'Refresh',
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

// ─── Today Tab ──────────────────────────────────────────────────────────────

class _TodayTab extends StatelessWidget {
  const _TodayTab({required this.today});

  final dynamic today;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tanggal header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(today.date),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 26,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  today.hijriDateStr,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Next prayer banner
          NextPrayerBanner(today: today),

          // Prayer list
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text(
              'Jadwal Sholat',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
            ),
          ),

          TodayPrayerCard(today: today),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ─── Month Tab ───────────────────────────────────────────────────────────────

class _MonthTab extends ConsumerWidget {
  const _MonthTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final monthAsync = ref.watch(selectedMonthPrayerProvider);

    return Column(
      children: [
        // ── Month navigator ─────────────────────────────────────
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  ref.read(selectedMonthProvider.notifier).state =
                      DateTime(selectedMonth.year, selectedMonth.month - 1);
                },
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(
                _monthYearStr(selectedMonth),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                onPressed: () {
                  ref.read(selectedMonthProvider.notifier).state =
                      DateTime(selectedMonth.year, selectedMonth.month + 1);
                },
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),

        // ── List ────────────────────────────────────────────────
        Expanded(
          child: monthAsync.when(
            loading: () => const _LoadingView(),
            error: (e, _) => _ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(selectedMonthPrayerProvider),
            ),
            data: (days) => MonthPrayerList(days: days),
          ),
        ),
      ],
    );
  }

  String _monthYearStr(DateTime dt) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── States ──────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 2,
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => const Center(
        child: Text('Tidak ada data jadwal sholat'),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isOffline =
        message.contains('koneksi') || message.contains('offline');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isOffline
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                isOffline
                    ? Icons.wifi_off_rounded
                    : Icons.error_outline_rounded,
                size: 32,
                color: isOffline
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isOffline ? 'Tidak Ada Koneksi' : 'Terjadi Kesalahan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              isOffline
                  ? 'Data belum tersimpan. Harap connect ke internet untuk pertama kali.'
                  : message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(
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

// ─────────────────────────────────────────────────────────────
//  ARABESQUE PAINTER
// ─────────────────────────────────────────────────────────────
class _PrayerArabesquePainter extends CustomPainter {
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
