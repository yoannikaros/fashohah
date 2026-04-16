import '../../../../core/utils/hijri_calculator.dart';
import '../../domain/entities/prayer_day.dart';

class PrayerDayModel extends PrayerDay {
  const PrayerDayModel({
    required super.date,
    required super.fajr,
    required super.sunrise,
    required super.dhuhr,
    required super.asr,
    required super.maghrib,
    required super.isha,
    required super.imsak,
    required super.hijriDay,
    required super.hijriMonth,
    required super.hijriYear,
    required super.hijriMonthName,
  });

  /// Parse dari JSON response Aladhan API.
  factory PrayerDayModel.fromAladhan(Map<String, dynamic> json) {
    final timings = json['timings'] as Map<String, dynamic>;
    final dateData = json['date'] as Map<String, dynamic>;
    final gregorian = dateData['gregorian'] as Map<String, dynamic>;
    final hijri = dateData['hijri'] as Map<String, dynamic>;

    // Format tanggal: "01-03-2024"
    final dateParts = (gregorian['date'] as String).split('-');
    final date = DateTime(
      int.parse(dateParts[2]),
      int.parse(dateParts[1]),
      int.parse(dateParts[0]),
    );

    return PrayerDayModel(
      date: date,
      fajr: _parseTime(timings['Fajr'] as String),
      sunrise: _parseTime(timings['Sunrise'] as String),
      dhuhr: _parseTime(timings['Dhuhr'] as String),
      asr: _parseTime(timings['Asr'] as String),
      maghrib: _parseTime(timings['Maghrib'] as String),
      isha: _parseTime(timings['Isha'] as String),
      imsak: _parseTime(timings['Imsak'] as String),
      hijriDay: hijri['day'] as String,
      hijriMonth: hijri['month']['number'].toString(),
      hijriYear: hijri['year'] as String,
      hijriMonthName: (hijri['month']['en'] as String),
    );
  }

  /// Parse dari response equran.id/apidev/shalat.
  factory PrayerDayModel.fromEquran(
    Map<String, dynamic> json,
    int year,
    int month,
  ) {
    final rawTanggal = json['tanggal'];
    final day = rawTanggal is int
        ? rawTanggal
        : int.parse(rawTanggal.toString());
    final date = DateTime(year, month, day);
    final hijri = HijriCalculator.fromGregorian(date);

    return PrayerDayModel(
      date: date,
      imsak: json['imsak'] as String,
      fajr: json['subuh'] as String,
      sunrise: json['terbit'] as String,
      dhuhr: json['dzuhur'] as String,
      asr: json['ashar'] as String,
      maghrib: json['maghrib'] as String,
      isha: json['isya'] as String,
      hijriDay: hijri.day,
      hijriMonth: hijri.month,
      hijriYear: hijri.year,
      hijriMonthName: hijri.monthName,
    );
  }

  /// Parse dari JSON cache Hive.
  factory PrayerDayModel.fromJson(Map<String, dynamic> json) {
    return PrayerDayModel(
      date: DateTime.parse(json['date'] as String),
      fajr: json['fajr'] as String,
      sunrise: json['sunrise'] as String,
      dhuhr: json['dhuhr'] as String,
      asr: json['asr'] as String,
      maghrib: json['maghrib'] as String,
      isha: json['isha'] as String,
      imsak: json['imsak'] as String,
      hijriDay: json['hijriDay'] as String,
      hijriMonth: json['hijriMonth'] as String,
      hijriYear: json['hijriYear'] as String,
      hijriMonthName: json['hijriMonthName'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'fajr': fajr,
        'sunrise': sunrise,
        'dhuhr': dhuhr,
        'asr': asr,
        'maghrib': maghrib,
        'isha': isha,
        'imsak': imsak,
        'hijriDay': hijriDay,
        'hijriMonth': hijriMonth,
        'hijriYear': hijriYear,
        'hijriMonthName': hijriMonthName,
      };

  /// Strip timezone suffix: "04:27 (WIB)" → "04:27"
  static String _parseTime(String raw) {
    return raw.split(' ').first.trim();
  }
}
