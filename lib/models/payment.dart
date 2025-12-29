import 'package:isar/isar.dart';

part 'payment.g.dart';

@collection
class Payment {
  Id id = Isar.autoIncrement;

  late String orderId;
  late String method; // 'cash', 'card', 'other'
  late double amount;
  late DateTime timestamp;

  String? reference;
}
