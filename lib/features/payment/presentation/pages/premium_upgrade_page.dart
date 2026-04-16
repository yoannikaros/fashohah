import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/pages/home_screen.dart'
    show kTeal, ArabesquePainter;

// Kebalikan profile: concave — tepi rendah, tengah naik
class _ArchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 52);
    path.quadraticBezierTo(size.width / 2, 0, size.width, 52);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_ArchClipper _) => false;
}

class PremiumUpgradePage extends ConsumerWidget {
  const PremiumUpgradePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final bottomPad = mq.padding.bottom;
    final user = ref.watch(authProvider);

    const kHeaderHeight = 260.0;

    return Scaffold(
      backgroundColor: kTeal,
      body: Stack(
        children: [
          // ── Konten scroll bersamaan ──
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: teal + arabesque + icon + judul
                SizedBox(
                  height: kHeaderHeight + topPad,
                  child: CustomPaint(
                    painter: ArabesquePainter(),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, topPad + 52, 20, 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon mahkota
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: Colors.amber,
                              size: 38,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Fashohah Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Akses penuh semua konten islami\ntanpa batas',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // White wave card
                ClipPath(
                  clipper: _ArchClipper(),
                  child: Container(
                    color: cs.surface,
                    padding: EdgeInsets.fromLTRB(20, 68, 20, 40 + bottomPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Harga
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: kTeal.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: kTeal.withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Seumur Hidup',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: kTeal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Rp 49.999',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: kTeal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Bayar sekali, akses selamanya',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Label keuntungan
                        Text(
                          'YANG KAMU DAPATKAN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ..._benefits.map((b) => _BenefitRow(
                              icon: b.$1,
                              title: b.$2,
                              subtitle: b.$3,
                            )),

                        const SizedBox(height: 28),

                        // Tombol bayar
                        if (user == null)
                          const _LoginFirstBanner()
                        else
                          _PayButton(userId: user.userId),

                        const SizedBox(height: 16),

                        Text(
                          'Pembayaran aman melalui Google Pay. Data kamu terlindungi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Tombol back tetap di atas ──
          Positioned(
            top: topPad + 4,
            left: 4,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data benefit ────────────────────────────────────────────────────────────

const _benefits = [
  (
    Icons.all_inclusive_rounded,
    'Akses Tak Terbatas',
    'Buka semua konten premium tanpa batas tampilan',
  ),
  (
    Icons.wifi_off_rounded,
    'Mode Offline',
    'Simpan materi favorit untuk dibaca tanpa internet',
  ),
  (
    Icons.hd_rounded,
    'Konten Eksklusif',
    'Akses konten khusus yang terus diperbarui',
  ),
  (
    Icons.support_agent_rounded,
    'Prioritas Dukungan',
    'Dapatkan bantuan lebih cepat dari tim kami',
  ),
];

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kTeal, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.55),
                    height: 1.4,
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

class _PayButton extends ConsumerStatefulWidget {
  const _PayButton({required this.userId});
  final int userId;

  @override
  ConsumerState<_PayButton> createState() => _PayButtonState();
}

class _PayButtonState extends ConsumerState<_PayButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _isLoading ? null : _pay,
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
          : const Icon(Icons.payment_rounded, size: 20),
      label: const Text(
        'Bayar dengan Google Pay',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: kTeal,
        disabledBackgroundColor: kTeal.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        minimumSize: const Size.fromHeight(54),
      ),
    );
  }

  Future<void> _pay() async {
    setState(() => _isLoading = true);
    // TODO: Implementasi Google Pay
    // 1. POST /api/payment.php?action=create_order
    // 2. Tampilkan Google Pay sheet
    // 3. POST /api/payment.php?action=verify dengan token
    // 4. Refresh premium status
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fitur pembayaran akan segera tersedia'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

class _LoginFirstBanner extends StatelessWidget {
  const _LoginFirstBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Masuk atau daftar akun dulu untuk membeli premium',
              style: TextStyle(fontSize: 13, color: Colors.deepOrange),
            ),
          ),
        ],
      ),
    );
  }
}
