import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/dzikir_category_model.dart';
import '../models/dzikir_item_model.dart';

class DzikirLocalDatasource {
  Map<String, dynamic>? _cache;

  Future<Map<String, dynamic>> _loadJson() async {
    _cache ??= jsonDecode(
      await rootBundle.loadString('assets/data/dzikir.json'),
    ) as Map<String, dynamic>;
    return _cache!;
  }

  Future<List<DzikirCategoryModel>> getCategories() async {
    final data = await _loadJson();
    final categories = (data['categories'] as List).cast<Map<String, dynamic>>();
    final items = (data['items'] as List).cast<Map<String, dynamic>>();

    return categories.map((cat) {
      final id = cat['id'] as String;
      final count = items.where((item) => item['categoryId'] == id).length;
      return DzikirCategoryModel.fromJson(cat, count);
    }).toList();
  }

  Future<List<DzikirItemModel>> getItemsByCategory(String categoryId) async {
    final data = await _loadJson();
    final items = (data['items'] as List).cast<Map<String, dynamic>>();
    return items
        .where((item) => item['categoryId'] == categoryId)
        .map(DzikirItemModel.fromJson)
        .toList();
  }

  Future<DzikirItemModel?> getItemById(String id) async {
    final data = await _loadJson();
    final items = (data['items'] as List).cast<Map<String, dynamic>>();
    final match = items.where((item) => item['id'] == id).toList();
    if (match.isEmpty) return null;
    return DzikirItemModel.fromJson(match.first);
  }
}
