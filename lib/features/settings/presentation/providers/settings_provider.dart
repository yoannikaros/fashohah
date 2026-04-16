import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../prayer/presentation/providers/prayer_provider.dart';

String _notifKey(String prayer) => 'notif_${prayer.toLowerCase()}';

// ── Theme Mode ───────────────────────────────────────────────────────────────

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final saved = prefs.getString(_key);
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.light,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      _key,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      },
    );
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

// ── Prayer Notifications ─────────────────────────────────────────────────────

class PrayerNotifNotifier extends FamilyNotifier<bool, String> {
  @override
  bool build(String prayer) {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool(_notifKey(prayer)) ?? (prayer != 'Imsak');
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_notifKey(arg), state);
    // Trigger reschedule notifikasi
    ref.invalidate(todayPrayerProvider);
  }
}

final prayerNotifProvider =
    NotifierProvider.family<PrayerNotifNotifier, bool, String>(
  PrayerNotifNotifier.new,
);

// ── Master Notification Toggle ───────────────────────────────────────────────

class MasterNotifNotifier extends Notifier<bool> {
  static const _key = 'notif_master';

  @override
  bool build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_key, state);

    if (!state) {
      // Langsung batalkan semua tanpa menunggu reschedule
      await NotificationService.instance.cancelAllPrayerNotifications();
    } else {
      // Pastikan izin OS diberikan dulu
      final enabled = await NotificationService.instance.areNotificationsEnabled();
      if (!enabled) {
        await NotificationService.instance.requestPermission();
      }
      // Trigger reschedule
      ref.invalidate(todayPrayerProvider);
    }
  }
}

final masterNotifProvider =
    NotifierProvider<MasterNotifNotifier, bool>(MasterNotifNotifier.new);

// ── Arabic Font Size ─────────────────────────────────────────────────────────

class ArabicFontSizeNotifier extends Notifier<double> {
  static const _key = 'arabic_font_size';
  static const defaultSize = 22.0;

  @override
  double build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getDouble(_key) ?? defaultSize;
  }

  Future<void> set(double size) async {
    state = size;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble(_key, size);
  }
}

final arabicFontSizeProvider =
    NotifierProvider<ArabicFontSizeNotifier, double>(ArabicFontSizeNotifier.new);

// ── Re-export prayer names list ──────────────────────────────────────────────

const prayerNotifKeys = notifPrayerNames;
