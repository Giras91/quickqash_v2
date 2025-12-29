import 'package:isar/isar.dart';

part 'order_item.g.dart';

@collection
class OrderItem {
  Id id = Isar.autoIncrement;

  late String orderId;
  late String itemId;
  late String itemName;
  late double price;
  late int quantity;

  String? kitchenRoute;
  List<String> modifiers = [];
  String? notes;
}
