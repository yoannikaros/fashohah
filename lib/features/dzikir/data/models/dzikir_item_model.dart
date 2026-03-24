import '../../domain/entities/dzikir_item.dart';

class DzikirItemModel extends DzikirItem {
  const DzikirItemModel({
    required super.id,
    required super.categoryId,
    required super.title,
    required super.arabic,
    required super.latin,
    required super.translation,
    required super.reference,
    required super.targetCount,
    super.notes,
  });

  factory DzikirItemModel.fromJson(Map<String, dynamic> json) {
    return DzikirItemModel(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      title: json['title'] as String,
      arabic: json['arabic'] as String,
      latin: json['latin'] as String,
      translation: json['translation'] as String,
      reference: json['reference'] as String,
      targetCount: json['targetCount'] as int,
      notes: json['notes'] as String?,
    );
  }
}
