import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/prayer/domain/entities/prayer_day.dart';

/// Nama-nama sholat yang bisa dinotifikasi.
/// Dipakai bersama oleh NotificationService dan settings provider.
const notifPrayerNames = ['Imsak', 'Subuh', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'];

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (Platform.isWindows) return;

    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Buka Fashohah');

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      ),
    );
    _initialized = true;
  }

  // ── Permission ─────────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    if (!_initialized) return false;

    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.requestNotificationsPermission() ?? false;
    }

    if (Platform.isIOS || Platform.isMacOS) {
      final darwinPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await darwinPlugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return true;
  }

  /// Cek apakah exact alarm diizinkan (Android 12+ / API 31+).
  /// Di bawah API 31 atau platform lain → selalu true.
  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await androidPlugin?.canScheduleExactNotifications() ?? false;
  }

  /// Cek apakah notifikasi diizinkan di level OS (Android 13+ / API 33+).
  /// Pada Android < 13, notifikasi selalu diizinkan (tidak ada prompt).
  Future<bool> areNotificationsEnabled() async {
    if (!_initialized) return false;
    if (!Platform.isAndroid) return true;
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await androidPlugin?.areNotificationsEnabled() ?? false;
  }

  /// Buka halaman "Alarms & Reminders" di System Settings agar user bisa
  /// mengizinkan exact alarm (Android 12+ / API 31+).
  Future<void> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return;
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  // ── Scheduling ─────────────────────────────────────────────────────────────

  /// Jadwalkan notifikasi adzan untuk 7 hari ke depan.
  ///
  /// [days] — list PrayerDay (maks 7), sudah difilter mulai hari ini.
  /// [masterEnabled] — master toggle dari Pengaturan.
  /// [prayerEnabled] — per-prayer toggle, key = nama sholat ('Subuh', dll).
  Future<void> scheduleWeekPrayers({
    required List<PrayerDay> days,
    required bool masterEnabled,
    required Map<String, bool> prayerEnabled,
  }) async {
    if (!_initialized) return;

    await cancelAllPrayerNotifications();
    if (!masterEnabled) return;

    final canExact = await canScheduleExactAlarms();
    final mode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final now = DateTime.now();

    for (int dayIndex = 0; dayIndex < days.length && dayIndex < 7; dayIndex++) {
      final day = days[dayIndex];

      // Slot 0–5 per hari → ID = dayIndex * 6 + slotIndex (0..41)
      final slots = [
        (name: 'Imsak',   time: day.imsak,   slot: 0),
        (name: 'Subuh',   time: day.fajr,    slot: 1),
        (name: 'Dzuhur',  time: day.dhuhr,   slot: 2),
        (name: 'Ashar',   time: day.asr,     slot: 3),
        (name: 'Maghrib', time: day.maghrib, slot: 4),
        (name: 'Isya',    time: day.isha,    slot: 5),
      ];

      for (final s in slots) {
        if (!(prayerEnabled[s.name] ?? (s.name != 'Imsak'))) continue;

        final scheduledTime = _buildDateTime(s.time, day.date);
        if (scheduledTime.isBefore(now)) continue;

        try {
          await _scheduleNotification(
            id: dayIndex * 6 + s.slot,
            title: s.name == 'Imsak' ? 'Imsak' : 'Waktu ${s.name}',
            body: s.name == 'Imsak'
                ? 'Segera imsak — ${s.time}. Hentikan makan dan minum.'
                : 'Sudah masuk waktu sholat ${s.name} — ${s.time}',
            scheduledTime: scheduledTime,
            mode: mode,
          );
        } catch (_) {
          // Abaikan error dari data cache lama yang tidak kompatibel.
        }
      }
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    AndroidScheduleMode mode = AndroidScheduleMode.inexactAllowWhileIdle,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'prayer_times',
      'Waktu Sholat',
      channelDescription: 'Notifikasi jadwal sholat harian',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(android: androidDetails, iOS: darwinDetails, macOS: darwinDetails),
      androidScheduleMode: mode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Batalkan semua notifikasi sholat (7 hari × 6 slot = ID 0..41).
  Future<void> cancelAllPrayerNotifications() async {
    if (!_initialized) return;
    // Hapus cache SharedPreferences dulu agar tidak crash akibat data lama
    // yang tidak punya field "type" (flutter_local_notifications v18+).
    await _clearNotificationCache();
    for (var i = 0; i < 7 * 6; i++) {
      try {
        await _plugin.cancel(i);
      } catch (_) {
        // Abaikan error deserialisasi data notifikasi lama.
      }
    }
  }

  /// Hapus SharedPreferences cache notifikasi terjadwal (Android only).
  Future<void> _clearNotificationCache() async {
    if (!Platform.isAndroid) return;
    try {
      const channel = MethodChannel('com.masruri.fashohah/notifications');
      await channel.invokeMethod<void>('clearNotificationCache');
    } catch (_) {}
  }

  DateTime _buildDateTime(String timeStr, DateTime baseDate) {
    final parts = timeStr.split(':');
    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}
