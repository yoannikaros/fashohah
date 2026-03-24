import '../../domain/entities/dzikir_category.dart';
import '../../domain/entities/dzikir_item.dart';
import '../../domain/repositories/dzikir_repository.dart';
import '../datasources/dzikir_local_datasource.dart';

class DzikirRepositoryImpl implements DzikirRepository {
  DzikirRepositoryImpl(this._datasource);

  final DzikirLocalDatasource _datasource;

  @override
  Future<List<DzikirCategory>> getCategories() => _datasource.getCategories();

  @override
  Future<List<DzikirItem>> getItemsByCategory(String categoryId) =>
      _datasource.getItemsByCategory(categoryId);

  @override
  Future<DzikirItem?> getItemById(String id) => _datasource.getItemById(id);
}
