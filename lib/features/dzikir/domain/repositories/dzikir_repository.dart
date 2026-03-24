import '../entities/dzikir_category.dart';
import '../entities/dzikir_item.dart';

abstract class DzikirRepository {
  Future<List<DzikirCategory>> getCategories();
  Future<List<DzikirItem>> getItemsByCategory(String categoryId);
  Future<DzikirItem?> getItemById(String id);
}
