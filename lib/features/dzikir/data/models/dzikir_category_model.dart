import '../../domain/entities/dzikir_category.dart';

class DzikirCategoryModel extends DzikirCategory {
  const DzikirCategoryModel({
    required super.id,
    required super.name,
    required super.description,
    required super.icon,
    required super.itemCount,
  });

  factory DzikirCategoryModel.fromJson(Map<String, dynamic> json, int itemCount) {
    return DzikirCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['subtitle'] ?? json['description'] ?? '') as String,
      icon: json['icon'] as String,
      itemCount: itemCount,
    );
  }
}
