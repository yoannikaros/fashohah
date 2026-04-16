import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/register_page.dart';
import '../../../auth/presentation/pages/profile_page.dart';
import '../../../payment/presentation/pages/premium_upgrade_page.dart';
import 'privacy_policy_page.dart';

const _kTeal = Color(0xFF00B5A5);
const _kTealPattern = Color(0xFF009D8F);
const _kHeaderHeight = 160.0;
const _kOverlap = 70.0;

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final masterNotif = ref.watch(masterNotifProvider);
    final arabicSize = ref.watch(arabicFontSizeProvider);
    final authUser = ref.watch(authProvider);
    final cs = Theme.of(context).colorScheme;
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

          // ── Layer 2: konten putih rounded top ──
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
              child: ListView(
                padding: const EdgeInsets.only(top: 20, bottom: 32),
                children: [
                  // ── Akun ──────────────────────────────────────────
                  _SectionHeader('Akun'),
                  if (authUser != null) ...[
                    // User sudah login — tampilkan card profil
                    _AccountCard(user: authUser),
                    // Banner upgrade (hanya untuk user gratis)
                    if (!authUser.isPremium) _UpgradeBannerCard(),
                  ] else
                    // Belum login — tampilkan tombol Daftar & Masuk
                    _AuthButtonsCard(),

                  // ── Tampilan ──────────────────────────────────────
                  _SectionHeader('Tampilan'),
                  _SettingsGroup(children: [
                    _TileThemeMode(current: themeMode),
                  ]),

                  // ── Al-Qur'an & Dzikir ────────────────────────────
                  _SectionHeader('Al-Qur\'an & Dzikir'),
                  _SettingsGroup(children: [
                    _TileArabicFontSize(size: arabicSize),
                  ]),

                  // ── Notifikasi ────────────────────────────────────
                  _SectionHeader('Notifikasi Adzan'),
                  _SettingsGroup(children: [
                    _SwitchTile(
                      icon: Icons.notifications_rounded,
                      iconColor: AppColors.primary,
                      title: 'Aktifkan Notifikasi',
                      subtitle: 'Pengingat waktu adzan',
                      value: masterNotif,
                      onChanged: (_) =>
                          ref.read(masterNotifProvider.notifier).toggle(),
                    ),
                    if (masterNotif) ...[
                      const _Divider(),
                      if (Platform.isAndroid) _NotifPermissionBanner(),
                      if (Platform.isAndroid) _ExactAlarmBanner(),
                      ...prayerNotifKeys.map((prayer) {
                        final enabled = ref.watch(prayerNotifProvider(prayer));
                        return _SwitchTile(
                          icon: _prayerIcon(prayer),
                          iconColor: cs.onSurface.withValues(alpha: 0.5),
                          title: prayer,
                          value: enabled,
                          onChanged: (_) => ref
                              .read(prayerNotifProvider(prayer).notifier)
                              .toggle(),
                        );
                      }),
                    ],
                  ]),

                  // ── Tentang ───────────────────────────────────────
                  _SectionHeader('Tentang'),
                  _SettingsGroup(children: [
                    _NavTile(
                      icon: Icons.shield_outlined,
                      iconColor: Colors.blue,
                      title: 'Kebijakan Privasi',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyPage(),
                        ),
                      ),
                    ),
                    const _Divider(),
                    _NavTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: cs.onSurface.withValues(alpha: 0.5),
                      title: 'Versi Aplikasi',
                      trailing: Text(
                        '1.0.0',
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    const _Divider(),
                    _NavTile(
                      icon: Icons.favorite_rounded,
                      iconColor: Colors.red,
                      title: 'Dibuat dengan',
                      trailing: Text(
                        'Flutter & Dart',
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Fashohah',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.25),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Islamic Super App',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Layer 3: header teks ──
          Positioned(
            top: topPad,
            left: 0,
            right: 0,
            height: _kHeaderHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Pengaturan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Sesuaikan aplikasi sesuai preferensimu',
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

  IconData _prayerIcon(String prayer) => switch (prayer) {
        'Imsak' => Icons.bedtime_outlined,
        'Subuh' => Icons.wb_twilight_rounded,
        'Dzuhur' => Icons.wb_sunny_outlined,
        'Ashar' => Icons.wb_sunny_rounded,
        'Maghrib' => Icons.nights_stay_outlined,
        'Isya' => Icons.dark_mode_outlined,
        _ => Icons.access_time_rounded,
      };
}

// ── Account Card (user sudah login) ──────────────────────────────────────────

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.user});
  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nama,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Badge Premium / Gratis
                    _StatusBadge(isPremium: user.isPremium),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: cs.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Upgrade Banner Card ──────────────────────────────────────────────────────

class _UpgradeBannerCard extends StatelessWidget {
  const _UpgradeBannerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00B5A5), Color(0xFF007A6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Pola dekoratif di background
          Positioned(
            right: -18,
            top: -18,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: -22,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Konten
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                // Icon mahkota
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.amber,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Teks
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upgrade ke Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Akses semua konten tanpa batas',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Tombol
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PremiumUpgradePage()),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF007A6E),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Lihat',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
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

// ── Status Badge (Premium / Gratis) ─────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isPremium});
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.workspace_premium_rounded,
                size: 11, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'Premium',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF00B5A5).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00B5A5).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.person_outline_rounded,
              size: 11, color: Color(0xFF00B5A5)),
          SizedBox(width: 4),
          Text(
            'Gratis',
            style: TextStyle(
              color: Color(0xFF00B5A5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Auth Buttons Card (belum login) ──────────────────────────────────────────

class _AuthButtonsCard extends StatelessWidget {
  const _AuthButtonsCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Masuk atau Daftar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Simpan progres & akses konten premium',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Tombol Daftar
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size.fromHeight(42),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  child: const Text(
                    'Daftar Gratis',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Tombol Masuk
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size.fromHeight(42),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  child: const Text(
                    'Masuk',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Theme mode tile ───────────────────────────────────────────────────────────

class _TileThemeMode extends ConsumerWidget {
  const _TileThemeMode({required this.current});
  final ThemeMode current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final options = [
      (ThemeMode.system, 'Mengikuti sistem', Icons.brightness_auto_rounded),
      (ThemeMode.light, 'Terang', Icons.light_mode_rounded),
      (ThemeMode.dark, 'Gelap', Icons.dark_mode_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.brightness_6_rounded,
                    color: Colors.orange, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Tema Aplikasi',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: options.map((opt) {
              final (mode, label, icon) = opt;
              final selected = current == mode;
              return Expanded(
                child: GestureDetector(
                  onTap: () => ref.read(themeModeProvider.notifier).set(mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            selected ? AppColors.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(icon,
                            size: 20,
                            color: selected
                                ? AppColors.primary
                                : cs.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                            color: selected
                                ? AppColors.primary
                                : cs.onSurface.withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Arabic font size tile ─────────────────────────────────────────────────────

class _TileArabicFontSize extends ConsumerWidget {
  const _TileArabicFontSize({required this.size});
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.text_fields_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Ukuran Teks Arab',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
              Text(
                '${size.round()}px',
                style: TextStyle(
                    fontSize: 13, color: cs.onSurface.withValues(alpha: 0.45)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Preview
          Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(fontSize: size, height: 2),
          ),
          Slider(
            value: size,
            min: 16,
            max: 36,
            divisions: 10,
            activeColor: AppColors.primary, // ignore: deprecated_member_use
            onChanged: (v) => ref.read(arabicFontSizeProvider.notifier).set(v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kecil',
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.4))),
              Text('Besar',
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.4))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.45)),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
            ),
            trailing ??
                (onTap != null
                    ? Icon(Icons.chevron_right_rounded,
                        size: 20, color: cs.onSurface.withValues(alpha: 0.3))
                    : const SizedBox()),
          ],
        ),
      ),
    );
  }
}

// ── Notification Permission Banner ───────────────────────────────────────────

class _NotifPermissionBanner extends StatefulWidget {
  @override
  State<_NotifPermissionBanner> createState() => _NotifPermissionBannerState();
}

class _NotifPermissionBannerState extends State<_NotifPermissionBanner>
    with WidgetsBindingObserver {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Cek ulang saat user kembali dari app settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final result = await NotificationService.instance.areNotificationsEnabled();
    if (mounted) setState(() => _enabled = result);
  }

  Future<void> _requestPermission() async {
    final granted = await NotificationService.instance.requestPermission();
    if (mounted) setState(() => _enabled = granted);
  }

  @override
  Widget build(BuildContext context) {
    if (_enabled == null || _enabled == true) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: _requestPermission,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_off_rounded,
                  color: Colors.red, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Notifikasi diblokir oleh sistem. Ketuk untuk mengaktifkan izin.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                    height: 1.4,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: Colors.red.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Exact Alarm Banner ────────────────────────────────────────────────────────

class _ExactAlarmBanner extends StatefulWidget {
  @override
  State<_ExactAlarmBanner> createState() => _ExactAlarmBannerState();
}

class _ExactAlarmBannerState extends State<_ExactAlarmBanner> {
  bool? _canExact;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.canScheduleExactAlarms().then((v) {
      if (mounted) setState(() => _canExact = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_canExact == null || _canExact == true) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: () async {
          await NotificationService.instance.requestExactAlarmPermission();
          // Cek ulang setelah kembali dari Settings
          final result =
              await NotificationService.instance.canScheduleExactAlarms();
          if (mounted) setState(() => _canExact = result);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.alarm_rounded, color: Colors.orange, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Izinkan "Alarm & Pengingat" agar notifikasi tepat waktu. Ketuk untuk mengatur.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                    height: 1.4,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: Colors.orange.shade600),
            ],
          ),
        ),
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
      indent: 62,
      endIndent: 0,
      color:
          Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
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
