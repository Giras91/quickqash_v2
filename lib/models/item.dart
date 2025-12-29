import 'package:isar/isar.dart';

part 'item.g.dart';

@collection
class Item {
  Id id = Isar.autoIncrement;

  late String name;
  late double price;
  String? category;
  String? kitchenRoute;
  String? barcode;
  bool isActive = true;

  // Inventory tracking
  double quantity = 0.0; // Current stock quantity
  String unit = 'pcs'; // unit of measure (pcs, kg, L, etc.)
  double? lowStockThreshold; // Alert threshold
  double? reorderQuantity; // Quantity to reorder when low

  @Index()
  late DateTime createdAt;
}

