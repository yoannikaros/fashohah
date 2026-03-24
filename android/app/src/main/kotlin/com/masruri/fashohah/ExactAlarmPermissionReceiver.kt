package com.masruri.fashohah

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Menangani perubahan status izin SCHEDULE_EXACT_ALARM (Android 12+ / API 31+).
 *
 * Google Play mewajibkan receiver ini terdaftar untuk aplikasi yang menggunakan
 * SCHEDULE_EXACT_ALARM (targetSdk 31+). Ketika user mencabut izin di
 * Settings > Aplikasi > Akses khusus > Alarm & pengingat:
 *   1. Android secara otomatis membatalkan semua exact alarm yang tertunda.
 *   2. Aplikasi ini akan mendeteksi perubahan saat dibuka kembali melalui
 *      NotificationService.canScheduleExactAlarms() dan otomatis beralih
 *      ke mode inexact (tetap berfungsi, hanya kurang presisi).
 *
 * Receiver ini cukup terdaftar di manifest — tidak perlu logika tambahan
 * karena fallback sudah ditangani di sisi Dart.
 */
class ExactAlarmPermissionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Tidak ada aksi yang diperlukan di sini.
        // Penanganan fallback ke inexact alarm sudah dilakukan di Dart
        // (NotificationService.scheduleWeekPrayers) saat app dibuka kembali.
    }
}
