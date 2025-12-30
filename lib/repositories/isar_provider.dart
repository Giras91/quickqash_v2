import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/item.dart';
import '../models/category.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/payment.dart';
import '../models/printer.dart';
import '../models/inventory_log.dart';
import '../services/seed_service.dart';

/// Provider for production Isar instance
final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [
      ItemSchema,
      CategorySchema,
      OrderSchema,
      OrderItemSchema,
      PaymentSchema,
      PrinterSchema,
      InventoryLogSchema,
    ],
    directory: dir.path,
    name: 'quickqash',
  );

  // Seed initial data on first launch
  await SeedService.seedInitialData(isar);

  return isar;
});

/// Provider for training Isar instance
final trainingIsarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [
      ItemSchema,
      CategorySchema,
      OrderSchema,
      OrderItemSchema,
      PaymentSchema,
      PrinterSchema,
      InventoryLogSchema,
    ],
    directory: dir.path,
    name: 'quickqash_training',
  );

  // Seed initial data on first launch
  await SeedService.seedInitialData(isar);

  return isar;
});
