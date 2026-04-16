/// Utility untuk fuzzy-match nama kota/provinsi GPS ke daftar equran.id.
class PrayerLocationMatcher {
  /// Strip prefix administratif Indonesia untuk perbandingan yang lebih baik.
  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('kabupaten ', '')
        .replaceAll('kota ', '')
        .replaceAll('dki ', '')
        .replaceAll('daerah istimewa ', '')
        .replaceAll('kepulauan ', '')
        .replaceAll('administrasi ', '')
        .replaceAll('kab. ', '')
        .trim();
  }

  /// Cari kandidat terbaik dari [candidates] yang cocok dengan [query].
  /// Strategi: exact → contains → word-score.
  /// Returns null jika tidak ada kecocokan sama sekali.
  static String? bestMatch(String query, List<String> candidates) {
    if (candidates.isEmpty || query.isEmpty) return null;

    final q = _normalize(query);

    // 1. Exact match
    for (final c in candidates) {
      if (_normalize(c) == q) return c;
    }

    // 2. Contains (kedua arah)
    for (final c in candidates) {
      final cn = _normalize(c);
      if (cn.contains(q) || q.contains(cn)) return c;
    }

    // 3. Word-overlap score
    final qWords = q.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
    if (qWords.isEmpty) return null;

    String? best;
    int bestScore = 0;
    for (final c in candidates) {
      final cWords = _normalize(c).split(RegExp(r'\s+'));
      int score = 0;
      for (final qw in qWords) {
        for (final cw in cWords) {
          if (cw.contains(qw) || qw.contains(cw)) {
            score++;
            break;
          }
        }
      }
      if (score > bestScore) {
        bestScore = score;
        best = c;
      }
    }

    return bestScore > 0 ? best : null;
  }
}
