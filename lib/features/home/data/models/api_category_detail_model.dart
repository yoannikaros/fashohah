class ApiSubtitleItem {
  final int id;
  final int number;
  final String subtitle;
  final String? audio;
  final int nomorHalaman;
  final String penjelasan;

  const ApiSubtitleItem({
    required this.id,
    required this.number,
    required this.subtitle,
    this.audio,
    required this.nomorHalaman,
    required this.penjelasan,
  });

  factory ApiSubtitleItem.fromJson(Map<String, dynamic> json) =>
      ApiSubtitleItem(
        id: json['id'] as int,
        number: json['number'] as int,
        subtitle: json['subtitle'] as String,
        audio: json['audio'] as String?,
        nomorHalaman: (json['nomor_halaman'] as num).toInt(),
        penjelasan: (json['penjelasan'] as String?) ?? '',
      );

  /// Key unik untuk AudioManager (agar tidak konflik dengan ayat Qur'an)
  String get audioId => 'cat-$id';
}

class ApiJudulItem {
  final int id;
  final String judul;
  final bool isPremium;
  final bool isAvailable;
  final List<ApiSubtitleItem> subtitles;

  const ApiJudulItem({
    required this.id,
    required this.judul,
    this.isPremium = false,
    this.isAvailable = true,
    required this.subtitles,
  });

  factory ApiJudulItem.fromJson(Map<String, dynamic> json) => ApiJudulItem(
        id: json['id'] as int,
        judul: json['judul'] as String,
        isPremium: json['is_premium'] == true || json['is_premium'] == 1,
        isAvailable: json['is_available'] != false,
        subtitles: (json['subtitle'] as List<dynamic>)
            .map((e) => ApiSubtitleItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Response dari api.php?judul_id={id} — termasuk info premium/akses
class ApiJudulDetail {
  final int id;
  final String judul;
  final int kategoriId;
  final String namaKategori;
  final bool isPremium;
  final List<ApiSubtitleItem> subtitles;

  // ── Premium access info ──
  final bool isLocked;
  final int viewCount;
  final int viewsRemaining;
  final bool requiresLogin;
  final bool requiresPayment;

  const ApiJudulDetail({
    required this.id,
    required this.judul,
    required this.kategoriId,
    required this.namaKategori,
    this.isPremium = false,
    required this.subtitles,
    this.isLocked = false,
    this.viewCount = 0,
    this.viewsRemaining = -1,
    this.requiresLogin = false,
    this.requiresPayment = false,
  });

  factory ApiJudulDetail.fromJson(Map<String, dynamic> json) {
    final isPremium =
        json['is_premium'] == true || json['is_premium'] == 1;
    final isLocked =
        json['is_locked'] == true || json['is_locked'] == 1;
    final requiresLogin =
        json['requires_login'] == true || json['requires_login'] == 1;
    final requiresPayment =
        json['requires_payment'] == true || json['requires_payment'] == 1;

    return ApiJudulDetail(
      id: json['id'] as int,
      judul: json['judul'] as String,
      kategoriId: json['kategori_id'] as int,
      namaKategori: json['nama_kategori'] as String,
      isPremium: isPremium,
      subtitles: (json['subtitle'] as List<dynamic>)
          .map((e) => ApiSubtitleItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      isLocked: isLocked,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      viewsRemaining: (json['views_remaining'] as num?)?.toInt() ?? -1,
      requiresLogin: requiresLogin,
      requiresPayment: requiresPayment,
    );
  }
}

class ApiCategoryDetail {
  final int id;
  final String namaKategori;
  final bool isPremium;
  final List<ApiJudulItem> judul;

  const ApiCategoryDetail({
    required this.id,
    required this.namaKategori,
    this.isPremium = false,
    required this.judul,
  });

  factory ApiCategoryDetail.fromJson(Map<String, dynamic> json) =>
      ApiCategoryDetail(
        id: json['id'] as int,
        namaKategori: json['nama_kategori'] as String,
        isPremium: json['is_premium'] == true || json['is_premium'] == 1,
        judul: (json['judul'] as List<dynamic>)
            .map((e) => ApiJudulItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
