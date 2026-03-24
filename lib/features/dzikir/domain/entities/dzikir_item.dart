import 'package:equatable/equatable.dart';

class DzikirItem extends Equatable {
  const DzikirItem({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.arabic,
    required this.latin,
    required this.translation,
    required this.reference,
    required this.targetCount,
    this.notes,
  });

  final String id;
  final String categoryId;
  final String title;
  final String arabic;
  final String latin;
  final String translation;
  final String reference;
  final int targetCount;
  final String? notes;

  @override
  List<Object?> get props => [id, categoryId, title, arabic, latin, translation, reference, targetCount, notes];
}
