import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/dzikir_local_datasource.dart';
import '../../data/repositories/dzikir_repository_impl.dart';
import '../../domain/entities/dzikir_category.dart';
import '../../domain/entities/dzikir_item.dart';

// ── Datasource & Repository ──────────────────────────────────────────────────

final _dzikirDatasourceProvider = Provider((_) => DzikirLocalDatasource());

final _dzikirRepositoryProvider = Provider(
  (ref) => DzikirRepositoryImpl(ref.read(_dzikirDatasourceProvider)),
);

// ── Data Providers ───────────────────────────────────────────────────────────

final dzikirCategoryListProvider = FutureProvider<List<DzikirCategory>>((ref) {
  return ref.read(_dzikirRepositoryProvider).getCategories();
});

final dzikirItemListProvider =
    FutureProvider.family<List<DzikirItem>, String>((ref, categoryId) {
  return ref.read(_dzikirRepositoryProvider).getItemsByCategory(categoryId);
});

final dzikirItemProvider =
    FutureProvider.family<DzikirItem?, String>((ref, id) {
  return ref.read(_dzikirRepositoryProvider).getItemById(id);
});
