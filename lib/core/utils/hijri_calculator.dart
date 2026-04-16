/// Konversi tanggal Gregorian ke Hijriyah menggunakan algoritma Julian Day.
class HijriCalculator {
  static const _monthNames = [
    'Muharram',
    'Safar',
    "Rabi'ul Awwal",
    "Rabi'ul Akhir",
    'Jumadil Awwal',
    'Jumadil Akhir',
    'Rajab',
    "Sya'ban",
    'Ramadhan',
    'Syawal',
    "Dzulqa'dah",
    'Dzulhijjah',
  ];

  /// Kembalikan record (day, month, year, monthName) dalam format Hijriyah.
  static ({String day, String month, String year, String monthName})
      fromGregorian(DateTime date) {
    final jd = _toJulianDay(date.year, date.month, date.day);
    final (hy, hm, hd) = _julianToHijri(jd);
    return (
      day: hd.toString(),
      month: hm.toString(),
      year: hy.toString(),
      monthName: _monthNames[hm - 1],
    );
  }

  static int _toJulianDay(int y, int m, int d) {
    if (m <= 2) {
      y--;
      m += 12;
    }
    final a = y ~/ 100;
    final b = 2 - a + (a ~/ 4);
    return (365.25 * (y + 4716)).toInt() +
        (30.6001 * (m + 1)).toInt() +
        d +
        b -
        1524;
  }

  static (int year, int month, int day) _julianToHijri(int jd) {
    final l = jd - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    final ll = l - 10631 * n + 354;
    final j = ((10985 - ll) ~/ 5316) * ((50 * ll) ~/ 17719) +
        (ll ~/ 5670) * ((43 * ll) ~/ 15238);
    final lll = ll -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (ll ~/ 5670) * ((15238 * j) ~/ 43) +
        29;
    final month = (24 * lll) ~/ 709;
    final day = lll - (709 * month) ~/ 24;
    final year = 30 * n + j - 30;
    return (year, month, day);
  }
}
