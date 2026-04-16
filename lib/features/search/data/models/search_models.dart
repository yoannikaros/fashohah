class SearchCategory {
  const SearchCategory({
    required this.id,
    required this.namaKategori,
    required this.isPremium,
    this.icon,
  });

  final int id;
  final String namaKategori;
  final bool isPremium;
  final String? icon;

  factory SearchCategory.fromJson(Map<String, dynamic> j) => SearchCategory(
        id: j['id'] as int,
        namaKategori: j['nama_kategori'] as String,
        isPremium: j['is_premium'] as bool,
        icon: j['icon'] as String?,
      );
}

class SearchJudul {
  const SearchJudul({
    required this.id,
    required this.judul,
    required this.kategoriId,
    required this.namaKategori,
    required this.isPremium,
  });

  final int id;
  final String judul;
  final int kategoriId;
  final String namaKategori;
  final bool isPremium;

  factory SearchJudul.fromJson(Map<String, dynamic> j) => SearchJudul(
        id: j['id'] as int,
        judul: j['judul'] as String,
        kategoriId: j['kategori_id'] as int,
        namaKategori: j['nama_kategori'] as String,
        isPremium: j['is_premium'] as bool,
      );
}

class SearchResults {
  const SearchResults({
    required this.categories,
    required this.judul,
  });

  final List<SearchCategory> categories;
  final List<SearchJudul> judul;

  bool get isEmpty => categories.isEmpty && judul.isEmpty;

  factory SearchResults.fromJson(Map<String, dynamic> data) => SearchResults(
        categories: (data['categories'] as List)
            .map((e) => SearchCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
        judul: (data['judul'] as List)
            .map((e) => SearchJudul.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static const empty = SearchResults(categories: [], judul: []);
}
