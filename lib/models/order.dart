import 'package:isar/isar.dart';

part 'order.g.dart';

@collection
class Order {
  Id id = Isar.autoIncrement;

  late String orderId; // UUID
  late String mode; // 'retail', 'cafe', 'restaurant'
  late DateTime timestamp;

  double subtotal = 0.0;
  double tax = 0.0;
  double discount = 0.0;
  double total = 0.0;

  String? tableName;
  String? customerName;
  String status = 'pending'; // pending, completed, cancelled

  @Index()
  late DateTime createdAt;
}
