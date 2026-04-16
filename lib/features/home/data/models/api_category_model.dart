class ApiCategory {
  final int id;
  final String namaKategori;
  final bool isPremium;
  final String? icon;

  const ApiCategory({
    required this.id,
    required this.namaKategori,
    this.isPremium = false,
    this.icon,
  });

  factory ApiCategory.fromJson(Map<String, dynamic> json) => ApiCategory(
        id: json['id'] as int,
        namaKategori: json['nama_kategori'] as String,
        isPremium: json['is_premium'] == true || json['is_premium'] == 1,
        icon: json['icon'] as String?,
      );
}
