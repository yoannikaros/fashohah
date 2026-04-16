import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../../data/models/auth_models.dart';
import '../../../home/presentation/pages/home_screen.dart'
    show kTeal, ArabesquePainter;
import '../../../payment/presentation/pages/premium_upgrade_page.dart';

// Convex bump — cembung ke atas dari tengah
class _ArchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(size.width / 2, 52, size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_ArchClipper _) => false;
}

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late AuthUser _cachedUser;

  @override
  void initState() {
    super.initState();
    _cachedUser = ref.read(authProvider)!;
  }

  @override
  Widget build(BuildContext context) {
    // Pop tanpa blank screen saat logout
    ref.listen<AuthUser?>(authProvider, (_, next) {
      if (next == null && mounted) Navigator.of(context).pop();
    });

    final user = ref.watch(authProvider) ?? _cachedUser;

    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final bottomPad = mq.padding.bottom;

    const kHeaderHeight = 290.0;

    return Scaffold(
      backgroundColor: kTeal,
      body: Stack(
        children: [
          // ── Konten scroll bersamaan ──
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: teal + arabesque + avatar + nama + email + badge
                SizedBox(
                  height: kHeaderHeight + topPad,
                  child: CustomPaint(
                    painter: ArabesquePainter(),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, topPad + 52, 20, 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Avatar(user: user, size: 72),
                          const SizedBox(height: 12),
                          Text(
                            user.nama,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _PremiumBadge(isPremium: user.isPremium),
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
                    padding: EdgeInsets.fromLTRB(16, 72, 16, 40 + bottomPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Info akun
                        _SectionTitle('Informasi Akun'),
                        const SizedBox(height: 8),
                        _InfoCard(children: [
                          _InfoRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Nama Lengkap',
                            value: user.nama,
                          ),
                          if (user.namaPanggilan != null) ...[
                            const _Divider(),
                            _InfoRow(
                              icon: Icons.badge_outlined,
                              label: 'Nama Panggilan',
                              value: user.namaPanggilan!,
                            ),
                          ],
                          const _Divider(),
                          _InfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: user.email,
                          ),
                        ]),

                        const SizedBox(height: 24),

                        // Status langganan
                        _SectionTitle('Status Langganan'),
                        const SizedBox(height: 8),
                        if (user.isPremium)
                          _PremiumActiveCard(premiumSince: user.premiumSince)
                        else
                          _UpgradeCard(),

                        const SizedBox(height: 32),

                        // Tombol logout
                        OutlinedButton.icon(
                          onPressed: () => _confirmLogout(context),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Keluar dari Akun'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Tombol back + refresh tetap di atas ──
          Positioned(
            top: topPad + 4,
            left: 4,
            right: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                ),
                IconButton(
                  onPressed: () async {
                    await ref
                        .read(authProvider.notifier)
                        .refreshPremiumStatus();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Status diperbarui'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded,
                      color: Colors.white70, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content:
            const Text('Kamu perlu masuk lagi untuk mengakses konten premium.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).logout();
              // Jangan pop manual — ref.listen di build() sudah menangani pop
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

// ─── Components ──────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.size});
  final AuthUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.2),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
      ),
      child: Center(
        child: Text(
          user.initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.35,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge({required this.isPremium});
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isPremium
            ? Colors.amber.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPremium ? Colors.amber : Colors.white.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPremium ? Icons.workspace_premium_rounded : Icons.person_rounded,
            size: 14,
            color: isPremium ? Colors.amber : Colors.white70,
          ),
          const SizedBox(width: 6),
          Text(
            isPremium ? 'Member Premium' : 'Akun Gratis',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPremium ? Colors.amber : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 46,
      endIndent: 0,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
    );
  }
}

class _PremiumActiveCard extends StatelessWidget {
  const _PremiumActiveCard({this.premiumSince});
  final String? premiumSince;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFF3E0)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.amber,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Member Premium Aktif',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF6D4C00),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  premiumSince != null
                      ? 'Sejak $premiumSince'
                      : 'Akses penuh semua konten premium',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB07500),
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

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kTeal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kTeal.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: kTeal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Akun Gratis',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: kTeal,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Upgrade untuk akses konten premium',
                      style: TextStyle(fontSize: 12, color: kTeal),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PremiumUpgradePage()),
            ),
            icon: const Icon(Icons.workspace_premium_rounded, size: 18),
            label: const Text('Upgrade Premium'),
            style: FilledButton.styleFrom(
              backgroundColor: kTeal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
      ),
    );
  }
}
