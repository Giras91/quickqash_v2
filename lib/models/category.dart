import 'package:isar/isar.dart';

part 'category.g.dart';

@collection
class Category {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;

  String? iconName;
  int? colorValue;
  int sortOrder = 0;
}
