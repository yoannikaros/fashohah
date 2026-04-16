import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../features/prayer/presentation/providers/prayer_provider.dart';

// ─── Constants ───────────────────────────────────────────────────────────────

const _kaabaLat = 21.4225;
const _kaabaLon = 39.8262;

const _bgDark    = Color(0xFF070E0A);
const _bgMid     = Color(0xFF0C1C11);
const _green     = Color(0xFF0D7C3E);
const _greenGlow = Color(0xFF1AA058);
const _gold      = Color(0xFFD4A017);
const _goldLight = Color(0xFFEFC84A);

// ─── Helpers ─────────────────────────────────────────────────────────────────

double _calculateQibla(double lat, double lon) {
  final lat1 = lat * math.pi / 180;
  final lat2 = _kaabaLat * math.pi / 180;
  final dLon = (_kaabaLon - lon) * math.pi / 180;
  final y = math.sin(dLon) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

double _calculateDistance(double lat, double lon) {
  const r = 6371.0;
  final dLat = (_kaabaLat - lat) * math.pi / 180;
  final dLon = (_kaabaLon - lon) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat * math.pi / 180) *
          math.cos(_kaabaLat * math.pi / 180) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

// ─── Page ────────────────────────────────────────────────────────────────────

class QiblaPage extends ConsumerStatefulWidget {
  const QiblaPage({super.key});

  @override
  ConsumerState<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends ConsumerState<QiblaPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(locationProvider);
    final kabkota      = ref.watch(prayerKabkotaProvider);
    final provinsi     = ref.watch(prayerProvinsiProvider);

    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          // ── Radial dark-green background ──────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.4),
                radius: 1.1,
                colors: [_bgMid, _bgDark],
              ),
            ),
          ),

          // ── Subtle concentric rings (Islamic motif) ───────────────
          Positioned.fill(
            child: CustomPaint(painter: _BgRingsPainter()),
          ),

          // ── Main content ──────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _AppBarRow(onBack: () => Navigator.pop(context)),

                Expanded(
                  child: locationAsync.when(
                    loading: () => const _LoadingView(),
                    error: (e, _) => _ErrorView(message: e.toString()),
                    data: (loc) {
                      if (loc.isDefault) {
                        return const _ErrorView(
                          message:
                              'GPS tidak tersedia.\nAktifkan lokasi untuk menggunakan kompas kiblat.',
                          icon: Icons.location_off_rounded,
                        );
                      }

                      final qiblaAngle =
                          _calculateQibla(loc.latitude, loc.longitude);
                      final distanceKm =
                          _calculateDistance(loc.latitude, loc.longitude);

                      return _CompassBody(
                        qiblaAngle: qiblaAngle,
                        distanceKm: distanceKm,
                        kabkota: kabkota,
                        provinsi: provinsi,
                        pulseCtrl: _pulseCtrl,
                      );
                    },
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

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _AppBarRow extends StatelessWidget {
  const _AppBarRow({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 16, 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: onBack,
          ),
          const Expanded(
            child: Text(
              'Kompas Kiblat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _gold.withValues(alpha: 0.35)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mosque_outlined, color: _gold, size: 14),
                SizedBox(width: 6),
                Text(
                  "Ka'bah",
                  style: TextStyle(
                      color: _gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Compass Body ─────────────────────────────────────────────────────────────

class _CompassBody extends StatelessWidget {
  const _CompassBody({
    required this.qiblaAngle,
    required this.distanceKm,
    required this.kabkota,
    required this.provinsi,
    required this.pulseCtrl,
  });

  final double qiblaAngle;
  final double distanceKm;
  final String kabkota;
  final String provinsi;
  final AnimationController pulseCtrl;

  bool get _hasCompass =>
      !Platform.isWindows && !Platform.isLinux && !Platform.isMacOS;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Location badge
        _LocationBadge(provinsi: provinsi, kabkota: kabkota),
        const SizedBox(height: 12),

        // Compass (flexible — fills available height)
        Expanded(
          child: _hasCompass
              ? StreamBuilder<CompassEvent>(
                  stream: FlutterCompass.events,
                  builder: (context, snap) {
                    final heading = snap.data?.heading ?? 0;
                    return _CompassDial(
                      qiblaRad: (qiblaAngle - heading) * math.pi / 180,
                      compassRad: -heading * math.pi / 180,
                      heading: heading,
                      pulseCtrl: pulseCtrl,
                      accuracy: snap.data?.accuracy,
                    );
                  },
                )
              : _CompassDial(
                  qiblaRad: qiblaAngle * math.pi / 180,
                  compassRad: 0,
                  heading: 0,
                  pulseCtrl: pulseCtrl,
                  accuracy: null,
                  staticMode: true,
                ),
        ),

        // Info cards
        _InfoSection(qiblaAngle: qiblaAngle, distanceKm: distanceKm),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ─── Compass Dial ─────────────────────────────────────────────────────────────

class _CompassDial extends StatelessWidget {
  const _CompassDial({
    required this.qiblaRad,
    required this.compassRad,
    required this.heading,
    required this.pulseCtrl,
    required this.accuracy,
    this.staticMode = false,
  });

  final double qiblaRad;
  final double compassRad;
  final double heading;
  final AnimationController pulseCtrl;
  final double? accuracy;
  final bool staticMode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size =
            math.min(constraints.maxWidth, constraints.maxHeight) * 0.86;

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow pulse
                    AnimatedBuilder(
                      animation: pulseCtrl,
                      builder: (_, __) => Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _green.withValues(
                                  alpha: 0.08 + 0.07 * pulseCtrl.value),
                              blurRadius: 40 + 12 * pulseCtrl.value,
                              spreadRadius: 4,
                            ),
                            BoxShadow(
                              color: _gold.withValues(
                                  alpha: 0.04 + 0.03 * pulseCtrl.value),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Outer bezel (static — shows degree numbers)
                    CustomPaint(
                      size: Size(size, size),
                      painter: _BezelPainter(),
                    ),

                    // Rotating compass face (N follows device orientation)
                    Transform.rotate(
                      angle: staticMode ? 0 : compassRad,
                      child: CustomPaint(
                        size: Size(size * 0.80, size * 0.80),
                        painter: _CompassFacePainter(),
                      ),
                    ),

                    // Ka'bah arrow (always points to Mecca)
                    Transform.rotate(
                      angle: qiblaRad,
                      child: CustomPaint(
                        size: Size(size * 0.80, size * 0.80),
                        painter: _QiblaArrowPainter(),
                      ),
                    ),

                    // Center jewel
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [_goldLight, _gold],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _gold.withValues(alpha: 0.7),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Heading label
              if (!staticMode)
                Text(
                  '${heading.abs().toStringAsFixed(0)}° • ${_headingLabel(heading)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                )
              else
                Text(
                  'Arah Utara (statis)',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),

              const SizedBox(height: 8),

              // Accuracy badge
              if (accuracy != null && !staticMode)
                _AccuracyBadge(accuracy: accuracy!),
            ],
          ),
        );
      },
    );
  }

  String _headingLabel(double h) {
    final d = h % 360;
    if (d < 22.5 || d >= 337.5) return 'U';
    if (d < 67.5) return 'TL';
    if (d < 112.5) return 'T';
    if (d < 157.5) return 'TG';
    if (d < 202.5) return 'S';
    if (d < 247.5) return 'BD';
    if (d < 292.5) return 'B';
    return 'BL';
  }
}

// ─── Info Section ─────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.qiblaAngle, required this.distanceKm});

  final double qiblaAngle;
  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    final distStr = distanceKm >= 1000
        ? '${(distanceKm / 1000).toStringAsFixed(1)} rb km'
        : '${distanceKm.toStringAsFixed(0)} km';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _GlassCard(
              icon: Icons.explore_rounded,
              label: 'Arah Kiblat',
              value: '${qiblaAngle.toStringAsFixed(1)}°',
              sub: 'dari Utara',
              accentColor: _gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _GlassCard(
              icon: Icons.straighten_rounded,
              label: 'Jarak ke Mekah',
              value: distStr,
              sub: "Ka'bah",
              accentColor: _greenGlow,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 10,
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

// ─── Location Badge ───────────────────────────────────────────────────────────

class _LocationBadge extends StatelessWidget {
  const _LocationBadge({required this.provinsi, required this.kabkota});

  final String provinsi;
  final String kabkota;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_rounded,
                color: _greenGlow, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kabkota,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  provinsi,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _green.withValues(alpha: 0.4)),
            ),
            child: const Text(
              'GPS',
              style: TextStyle(
                  color: _greenGlow,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Accuracy Badge ───────────────────────────────────────────────────────────

class _AccuracyBadge extends StatelessWidget {
  const _AccuracyBadge({required this.accuracy});
  final double accuracy;

  @override
  Widget build(BuildContext context) {
    final good = accuracy < 15;
    final color = good ? _greenGlow : Colors.orange;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          good ? 'Akurasi tinggi' : 'Kalibrasi kompas diperlukan',
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }
}

// ─── Painters ────────────────────────────────────────────────────────────────

/// Concentric rings di background halaman (motif islamik subtle).
class _BgRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0D7C3E).withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final cx = size.width / 2;
    final cy = size.height * 0.38;
    for (final r in [70.0, 140.0, 210.0, 280.0, 350.0, 420.0]) {
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

/// Bezel luar: ring gelap dengan border emas, tick marks & label derajat.
class _BezelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

    // Dark outer ring fill
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = const Color(0xFF101C13)
        ..style = PaintingStyle.fill,
    );

    // Gold outer border
    canvas.drawCircle(
      Offset(cx, cy),
      r - 1,
      Paint()
        ..color = _gold.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Inner border
    canvas.drawCircle(
      Offset(cx, cy),
      r - 18,
      Paint()
        ..color = _gold.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < 72; i++) {
      final deg   = i * 5;
      final angle = deg * math.pi / 180 - math.pi / 2;
      final isLabel  = deg % 30 == 0;
      final isMajor  = deg % 10 == 0;
      final tickLen  = isLabel ? 13.0 : (isMajor ? 9.0 : 4.5);
      final outerR   = r - 2.5;

      final outerX = cx + outerR * math.cos(angle);
      final outerY = cy + outerR * math.sin(angle);
      final innerX = cx + (outerR - tickLen) * math.cos(angle);
      final innerY = cy + (outerR - tickLen) * math.sin(angle);

      canvas.drawLine(
        Offset(outerX, outerY),
        Offset(innerX, innerY),
        Paint()
          ..color = isMajor
              ? _gold.withValues(alpha: 0.75)
              : Colors.white.withValues(alpha: 0.2)
          ..strokeWidth = isMajor ? 1.5 : 0.9
          ..strokeCap = StrokeCap.round,
      );

      if (isLabel) {
        textPainter
          ..text = TextSpan(
            text: '$deg°',
            style: TextStyle(
              fontSize: 8,
              color: Colors.white.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          )
          ..layout();
        final labelR = outerR - 24;
        final lx = cx + labelR * math.cos(angle);
        final ly = cy + labelR * math.sin(angle);
        textPainter.paint(
          canvas,
          Offset(lx - textPainter.width / 2, ly - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

/// Wajah kompas yang berputar mengikuti orientasi perangkat. Menampilkan U/T/S/B.
class _CompassFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

    // Face background with radial gradient
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFF162B1C), const Color(0xFF0A1510)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );

    // Subtle inner rings
    for (final fr in [0.55, 0.75]) {
      canvas.drawCircle(
        Offset(cx, cy),
        r * fr,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Cardinal direction labels (U/T/S/B)
    final cardinals = [
      ('U', 0.0,   Colors.redAccent),
      ('T', 90.0,  Colors.white54),
      ('S', 180.0, Colors.white54),
      ('B', 270.0, Colors.white54),
    ];

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final c in cardinals) {
      final angle  = c.$2 * math.pi / 180 - math.pi / 2;
      final labelR = r * 0.72;
      final tx     = cx + labelR * math.cos(angle);
      final ty     = cy + labelR * math.sin(angle);

      // Highlight circle for North
      if (c.$2 == 0.0) {
        canvas.drawCircle(
          Offset(tx, ty),
          12,
          Paint()
            ..color = Colors.redAccent.withValues(alpha: 0.15)
            ..style = PaintingStyle.fill,
        );
      }

      tp
        ..text = TextSpan(
          text: c.$1,
          style: TextStyle(
            fontSize: c.$2 == 0.0 ? 17 : 14,
            fontWeight: FontWeight.bold,
            color: c.$3,
          ),
        )
        ..layout();
      tp.paint(
        canvas,
        Offset(tx - tp.width / 2, ty - tp.height / 2),
      );
    }

    // Intercardinal dots (NE/SE/SW/NW positions)
    for (final deg in [45.0, 135.0, 225.0, 315.0]) {
      final angle  = deg * math.pi / 180 - math.pi / 2;
      final dotR   = r * 0.72;
      canvas.drawCircle(
        Offset(cx + dotR * math.cos(angle), cy + dotR * math.sin(angle)),
        2.5,
        Paint()..color = Colors.white.withValues(alpha: 0.2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

/// Panah kiblat emas yang selalu menunjuk ke Ka'bah.
class _QiblaArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width / 2;

    // Glow line
    canvas.drawLine(
      Offset(cx, cy - r + 26),
      Offset(cx, cy),
      Paint()
        ..color = _gold.withValues(alpha: 0.12)
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );

    // ── Upper arrow shaft ─────────────────────────────────────────
    canvas.drawLine(
      Offset(cx, cy - r + 50),
      Offset(cx, cy - 6),
      Paint()
        ..color = _gold
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    // Arrow head (upper)
    final arrowUp = Path()
      ..moveTo(cx,      cy - r + 24)  // tip
      ..lineTo(cx - 11, cy - r + 52)  // left
      ..lineTo(cx,      cy - r + 42)  // indent
      ..lineTo(cx + 11, cy - r + 52)  // right
      ..close();
    canvas.drawPath(
      arrowUp,
      Paint()
        ..color = _gold
        ..style = PaintingStyle.fill,
    );
    // Gold glow on arrowhead
    canvas.drawPath(
      arrowUp,
      Paint()
        ..color = _goldLight.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );

    // ── Lower arrow shaft ─────────────────────────────────────────
    canvas.drawLine(
      Offset(cx, cy + r - 50),
      Offset(cx, cy + 6),
      Paint()
        ..color = Colors.redAccent.withValues(alpha: 0.6)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    // Arrow head (lower)
    final arrowDown = Path()
      ..moveTo(cx,      cy + r - 24)  // tip
      ..lineTo(cx - 10, cy + r - 52)  // left
      ..lineTo(cx,      cy + r - 43)  // indent
      ..lineTo(cx + 10, cy + r - 52)  // right
      ..close();
    canvas.drawPath(
      arrowDown,
      Paint()
        ..color = Colors.redAccent.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill,
    );

    // ── Ka'bah symbol at gold arrow tip ──────────────────────────
    final kRect = Rect.fromCenter(
      center: Offset(cx, cy - r + 14),
      width: 13,
      height: 15,
    );
    // Ka'bah body (dark)
    canvas.drawRRect(
      RRect.fromRectAndRadius(kRect, const Radius.circular(2)),
      Paint()..color = const Color(0xFF101010),
    );
    // Gold kiswah band
    canvas.drawLine(
      Offset(cx - 6.5, cy - r + 18),
      Offset(cx + 6.5, cy - r + 18),
      Paint()
        ..color = _gold
        ..strokeWidth = 1.5,
    );
    // Gold border
    canvas.drawRRect(
      RRect.fromRectAndRadius(kRect, const Radius.circular(2)),
      Paint()
        ..color = _gold.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── Loading & Error Views ────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
              color: _gold, strokeWidth: 2),
          SizedBox(height: 16),
          Text(
            'Mendeteksi lokasi...',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView(
      {required this.message, this.icon = Icons.error_outline_rounded});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Icon(icon, color: Colors.white24, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white54, height: 1.6, fontSize: 14),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async => Geolocator.openLocationSettings(),
              icon: const Icon(Icons.settings_rounded, size: 18),
              label: const Text('Buka Pengaturan Lokasi'),
            ),
          ],
        ),
      ),
    );
  }
}
