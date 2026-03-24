import 'package:equatable/equatable.dart';

/// Jadwal sholat satu hari lengkap.
class PrayerDay extends Equatable {
  const PrayerDay({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.imsak,
    required this.hijriDay,
    required this.hijriMonth,
    required this.hijriYear,
    required this.hijriMonthName,
  });

  final DateTime date;

  // Waktu sholat — format "HH:mm"
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String imsak;

  // Tanggal Hijriyah
  final String hijriDay;
  final String hijriMonth;
  final String hijriYear;
  final String hijriMonthName;

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String get hijriDateStr => '$hijriDay $hijriMonthName $hijriYear H';

  /// Kembalikan semua waktu sholat sebagai list berurutan.
  List<({String name, String time, PrayerName prayer})> get prayerList => [
        (name: 'Imsak', time: imsak, prayer: PrayerName.imsak),
        (name: 'Subuh', time: fajr, prayer: PrayerName.fajr),
        (name: 'Terbit', time: sunrise, prayer: PrayerName.sunrise),
        (name: 'Dzuhur', time: dhuhr, prayer: PrayerName.dhuhr),
        (name: 'Ashar', time: asr, prayer: PrayerName.asr),
        (name: 'Maghrib', time: maghrib, prayer: PrayerName.maghrib),
        (name: 'Isya', time: isha, prayer: PrayerName.isha),
      ];

  /// Cari prayer berikutnya dari waktu sekarang.
  ({String name, String time, DateTime dateTime})? get nextPrayer {
    final now = DateTime.now();
    final prayersWithTime = [
      (name: 'Subuh', time: fajr),
      (name: 'Dzuhur', time: dhuhr),
      (name: 'Ashar', time: asr),
      (name: 'Maghrib', time: maghrib),
      (name: 'Isya', time: isha),
    ];

    for (final p in prayersWithTime) {
      final dt = _toDateTime(p.time);
      if (dt.isAfter(now)) {
        return (name: p.name, time: p.time, dateTime: dt);
      }
    }
    return null;
  }

  DateTime _toDateTime(String timeStr) {
    final parts = timeStr.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  @override
  List<Object?> get props => [date];
}

enum PrayerName { imsak, fajr, sunrise, dhuhr, asr, maghrib, isha }
