import 'package:isar/isar.dart';

part 'inventory_log.g.dart';

@collection
class InventoryLog {
  Id id = Isar.autoIncrement;

  late int itemId; // Reference to Item
  late String itemName;
  late double quantityChange; // Positive for restocks, negative for sales
  late String reason; // 'sale', 'restock', 'adjustment', 'damage', 'loss'
  String? notes;

  late DateTime timestamp;
  String? userId; // Who made the change (optional)

  @Index()
  late DateTime createdAt;
}
