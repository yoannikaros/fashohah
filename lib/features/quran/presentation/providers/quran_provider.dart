import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/quran_remote_datasource.dart';
import '../../data/repositories/quran_repository_impl.dart';
import '../../domain/entities/ayat.dart';
import '../../domain/entities/surat.dart';
import '../../domain/repositories/quran_repository.dart';

// ─── Dependency Providers ──────────────────────────────────────────────────

final quranDatasourceProvider = Provider<QuranRemoteDatasource>((ref) {
  return QuranRemoteDatasource(ref.watch(equranDioProvider));
});

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepositoryImpl(ref.watch(quranDatasourceProvider));
});

// ─── Surat List ────────────────────────────────────────────────────────────

final suratListProvider = FutureProvider<List<Surat>>((ref) async {
  return ref.watch(quranRepositoryProvider).getSurats();
});

// ─── Surat Detail ──────────────────────────────────────────────────────────

final suratDetailProvider =
    FutureProvider.family<(Surat, List<Ayat>), int>((ref, nomor) async {
  return ref.watch(quranRepositoryProvider).getSuratDetail(nomor);
});

// ─── Selected Qari ────────────────────────────────────────────────────────

const Map<String, String> kQariNames = {
  '01': 'Abdullah Al-Juhany',
  '02': 'Abdul Muhsin Al-Qasim',
  '03': 'Abdurrahman as-Sudais',
  '04': 'Ibrahim Al-Dossari',
  '05': 'Misyari Rasyid Al-Afasi',
};

final selectedQariProvider = StateProvider<String>((ref) => '05');
