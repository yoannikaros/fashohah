import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import 'privacy_policy_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final masterNotif = ref.watch(masterNotifProvider);
    final arabicSize = ref.watch(arabicFontSizeProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            floating: true,
            snap: true,
            title: Text('Pengaturan'),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              // ── Tampilan ────────────────────────────────────────────
              _SectionHeader('Tampilan'),
              _SettingsGroup(children: [
                _TileThemeMode(current: themeMode),
              ]),

              // ── Ukuran Font Arab ────────────────────────────────────
              _SectionHeader('Al-Qur\'an & Dzikir'),
              _SettingsGroup(children: [
                _TileArabicFontSize(size: arabicSize),
              ]),

              // ── Notifikasi ──────────────────────────────────────────
              _SectionHeader('Notifikasi Adzan'),
              _SettingsGroup(children: [
                // Master toggle
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
                  // Banner izin notifikasi OS jika belum diberikan (Android 13+)
                  if (Platform.isAndroid) _NotifPermissionBanner(),
                  // Banner exact alarm jika belum diizinkan (Android 12+)
                  if (Platform.isAndroid) _ExactAlarmBanner(),
                  ...prayerNotifKeys.map((prayer) {
                    final enabled = ref.watch(prayerNotifProvider(prayer));
                    return _SwitchTile(
                      icon: _prayerIcon(prayer),
                      iconColor: cs.onSurface.withValues(alpha: 0.5),
                      title: prayer,
                      value: enabled,
                      onChanged: (_) =>
                          ref.read(prayerNotifProvider(prayer).notifier).toggle(),
                    );
                  }),
                ],
              ]),

              // ── Tentang ─────────────────────────────────────────────
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

              const SizedBox(height: 32),

              // App name footer
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
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Islamic Super App',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.2),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ]),
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
                  onTap: () =>
                      ref.read(themeModeProvider.notifier).set(mode),
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
                        color: selected
                            ? AppColors.primary
                            : Colors.transparent,
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
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
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
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.45)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Preview
          Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontFamily: 'serif', fontSize: size, height: 2),
          ),
          Slider(
            value: size,
            min: 16,
            max: 36,
            divisions: 10,
            activeColor: AppColors.primary, // ignore: deprecated_member_use
            onChanged: (v) =>
                ref.read(arabicFontSizeProvider.notifier).set(v),
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
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
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
                        size: 20,
                        color: cs.onSurface.withValues(alpha: 0.3))
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
              const Icon(Icons.notifications_off_rounded, color: Colors.red, size: 18),
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
          final result = await NotificationService.instance.canScheduleExactAlarms();
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
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }
}
