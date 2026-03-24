import 'package:equatable/equatable.dart';

class DzikirCategory extends Equatable {
  const DzikirCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.itemCount,
  });

  final String id;
  final String name;
  final String description;
  final String icon;
  final int itemCount;

  @override
  List<Object?> get props => [id, name, description, icon, itemCount];
}
