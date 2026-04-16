import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/home_page.dart';
import '../../../../core/notifications/notification_service.dart';

const _kTeal = Color(0xFF00B5A5);
const _kTealPattern = Color(0xFF009D8F);
const _kOnboardingKey = 'onboarding_done';

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  bool _locationGranted = false;
  bool _notifGranted = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkCurrent();
  }

  Future<void> _checkCurrent() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      setState(() {
        _locationGranted = true;
        _notifGranted = true;
      });
      return;
    }
    final loc = await Permission.location.status;
    final notif = await NotificationService.instance.areNotificationsEnabled();
    if (mounted) {
      setState(() {
        _locationGranted = loc.isGranted;
        _notifGranted = notif;
      });
    }
  }

  Future<void> _requestAll() async {
    setState(() => _loading = true);

    if (Platform.isAndroid || Platform.isIOS) {
      // 1. Lokasi
      final locStatus = await Permission.location.request();
      // 2. Notifikasi
      await NotificationService.instance.requestPermission();
      // 3. Exact alarm (Android 12+)
      if (Platform.isAndroid) {
        await NotificationService.instance.requestExactAlarmPermission();
      }

      if (mounted) {
        final notif =
            await NotificationService.instance.areNotificationsEnabled();
        setState(() {
          _locationGranted = locStatus.isGranted;
          _notifGranted = notif;
          _loading = false;
        });
      }
    } else {
      setState(() {
        _locationGranted = true;
        _notifGranted = true;
        _loading = false;
      });
    }

    await _finishOnboarding();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final size = MediaQuery.of(context).size;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: _kTeal,
      body: Stack(
        children: [
          // ── Layer 1: full teal + arabesque ──
          Positioned.fill(
            child: Container(
              color: _kTeal,
              child: CustomPaint(painter: _ArabesquePainter()),
            ),
          ),

          // ── Layer 2: container putih rounded top (60% bawah) ──
          Positioned(
            top: size.height * 0.36,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul
                    Text(
                      'Selamat Datang!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fashohah membutuhkan beberapa izin agar semua fitur dapat berjalan dengan baik.',
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurface.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Permission items
                    _PermissionItem(
                      icon: Icons.location_on_rounded,
                      iconColor: const Color(0xFF2E8A6E),
                      iconBg: const Color(0xFFE2F5F0),
                      title: 'Akses Lokasi',
                      description:
                          'Digunakan untuk menentukan waktu sholat yang tepat dan arah kiblat sesuai posisi Anda saat ini.',
                      granted: _locationGranted,
                    ),
                    const SizedBox(height: 16),
                    _PermissionItem(
                      icon: Icons.notifications_rounded,
                      iconColor: const Color(0xFF1565C0),
                      iconBg: const Color(0xFFE3F2FD),
                      title: 'Notifikasi',
                      description:
                          'Digunakan untuk mengirimkan pengingat adzan tepat waktu agar Anda tidak melewatkan waktu sholat.',
                      granted: _notifGranted,
                    ),
                    if (Platform.isAndroid) ...[
                      const SizedBox(height: 16),
                      _PermissionItem(
                        icon: Icons.alarm_rounded,
                        iconColor: const Color(0xFFB8860B),
                        iconBg: const Color(0xFFFFF3DC),
                        title: 'Alarm Tepat Waktu',
                        description:
                            'Diperlukan di Android 12+ agar notifikasi adzan muncul tepat pada waktunya, tidak terlambat.',
                        granted: _locationGranted && _notifGranted,
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Tombol utama
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _loading ? null : _requestAll,
                        style: FilledButton.styleFrom(
                          backgroundColor: _kTeal,
                          disabledBackgroundColor:
                              _kTeal.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                _locationGranted && _notifGranted
                                    ? 'Mulai Sekarang'
                                    : 'Izinkan & Mulai',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Lewati
                    Center(
                      child: TextButton(
                        onPressed: _loading ? null : _finishOnboarding,
                        child: Text(
                          'Lewati untuk sekarang',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Layer 3: logo + nama app di area teal ──
          Positioned(
            top: topPad + 24,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Icon masjid
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.mosque_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Fashohah',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Islamic Super App',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PERMISSION ITEM
// ─────────────────────────────────────────────────────────────
class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;
  final bool granted;

  const _PermissionItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
    required this.granted,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: granted
              ? _kTeal.withValues(alpha: 0.4)
              : cs.outline.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: granted
                  ? _kTeal.withValues(alpha: 0.12)
                  : iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              granted ? Icons.check_circle_rounded : icon,
              color: granted ? _kTeal : iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          // Teks
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (granted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Diizinkan',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _kTeal,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.55),
                    height: 1.5,
                  ),
                ),
              ],
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
      final sx = cx + pr * .42 * math.cos(lft), sy = cy + pr * .42 * math.sin(lft);
      final ex = cx + pr * .42 * math.cos(rgt), ey = cy + pr * .42 * math.sin(rgt);
      final c1x = cx + pr * .78 * math.cos(mid - .28), c1y = cy + pr * .78 * math.sin(mid - .28);
      final c2x = cx + pr * .78 * math.cos(mid + .28), c2y = cy + pr * .78 * math.sin(mid + .28);
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

  void _vines(Canvas c, Paint s, double cx, double cy, double pr, double cw, double ch) {
    for (final d in [Offset(0, -1), Offset(1, 0), Offset(0, 1), Offset(-1, 0)]) {
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
                ex, ey),
          s);
    }
  }

  void _teardrops(Canvas c, Paint s, double cx, double cy, double dist, double h, double w) {
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
