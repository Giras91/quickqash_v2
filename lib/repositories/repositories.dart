import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/item.dart';
import '../models/category.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/payment.dart';
import '../models/printer.dart';
import '../models/inventory_log.dart';
import 'isar_provider.dart';
import '../main.dart';

/// Item repository with training mode support
final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final training = ref.watch(trainingModeProvider);
  final isarAsync = training
      ? ref.watch(trainingIsarProvider)
      : ref.watch(isarProvider);

  return ItemRepository(isarAsync);
});

class ItemRepository {
  final AsyncValue<Isar> _isarAsync;

  ItemRepository(this._isarAsync);

  Isar? get _isar => _isarAsync.valueOrNull;

  Future<List<Item>> getAll() async {
    if (_isar == null) return [];
    return await _isar!.items.where().findAll();
  }

  Future<List<Item>> getActiveItems() async {
    if (_isar == null) return [];
    return await _isar!.items.filter().isActiveEqualTo(true).findAll();
  }

  Future<Item?> getById(Id id) async {
    if (_isar == null) return null;
    return await _isar!.items.get(id);
  }

  Future<void> save(Item item) async {
    if (_isar == null) return;
    await _isar!.writeTxn(() async {
      await _isar!.items.put(item);
    });
  }

  Future<void> delete(Id id) async {
    if (_isar == null) return;
    await _isar!.writeTxn(() async {
      await _isar!.items.delete(id);
    });
  }

  Future<List<Item>> getByCategory(String category) async {
    if (_isar == null) return [];
    return await _isar!.items
        .filter()
        .categoryEqualTo(category)
        .and()
        .isActiveEqualTo(true)
        .findAll();
  }

  Future<List<Item>> search(String query) async {
    if (_isar == null) return [];
    final lowercaseQuery = query.toLowerCase();
    return await _isar!.items
        .filter()
        .nameContains(lowercaseQuery, caseSensitive: false)
        .or()
        .barcodeContains(lowercaseQuery, caseSensitive: false)
        .and()
        .isActiveEqualTo(true)
        .findAll();
  }

  Future<Item?> getByBarcode(String barcode) async {
    if (_isar == null) return null;
    return await _isar!.items
        .filter()
        .barcodeEqualTo(barcode)
        .and()
        .isActiveEqualTo(true)
        .findFirst();
  }

  Stream<List<Item>> watchAll() async* {
    if (_isar == null) {
      yield [];
      return;
    }
    await for (final _ in _isar!.items.watchLazy(fireImmediately: true)) {
      final items = await _isar!.items.where().findAll();
      yield items;
    }
  }

  Stream<List<Item>> watchFiltered({String? categoryId, String? query}) async* {
    if (_isar == null) {
      yield [];
      return;
    }
    await for (final _ in _isar!.items.watchLazy(fireImmediately: true)) {
      var results = await _isar!.items.filter().isActiveEqualTo(true).findAll();

      // Filter by category if provided
      if (categoryId != null && categoryId.isNotEmpty) {
        results = results.where((item) => item.category == categoryId).toList();
      }

      // Filter by search query if provided
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        results = results
            .where((item) =>
                item.name.toLowerCase().contains(lowerQuery) ||
                (item.barcode?.toLowerCase().contains(lowerQuery) ?? false))
            .toList();
      }

      yield results;
    }
  }
}

/// Category repository with training mode support
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final training = ref.watch(trainingModeProvider);
  final isarAsync = training
      ? ref.watch(trainingIsarProvider)
      : ref.watch(isarProvider);

  return CategoryRepository(isarAsync);
});

class CategoryRepository {
  final AsyncValue<Isar> _isarAsync;

  CategoryRepository(this._isarAsync);

  Isar? get _isar => _isarAsync.valueOrNull;

  Future<List<Category>> getAll() async {
    if (_isar == null) return [];
    return await _isar!.categorys.where().sortBySortOrder().findAll();
  }

  Stream<List<Category>> watchAll() async* {
    if (_isar == null) {
      yield [];
      return;
    }
    await for (final _ in _isar!.categorys.watchLazy(fireImmediately: true)) {
      final categories = await _isar!.categorys.where().sortBySortOrder().findAll();
      yield categories;
    }
  }

  Future<Category?> getById(Id id) async {
    if (_isar == null) return null;
    return await _isar!.categorys.get(id);
  }

  Future<void> save(Category category) async {
    if (_isar == null) return;
    await _isar!.writeTxn(() async {
      await _isar!.categorys.put(category);
    });
  }

  Future<void> delete(Id id) async {
    if (_isar == null) return;
    await _isar!.writeTxn(() async {
      await _isar!.categorys.delete(id);
    });
  }

  Future<void> reorder(List<Category> categories) async {
    if (_isar == null) return;
    await _isar!.writeTxn(() async {
      await _isar!.categorys.putAll(categories);
    });
  }
}

/// Printer repository with training mode support
final printerRepositoryProvider = Provider<PrinterRepository>((ref) {
  final training = ref.watch(trainingModeProvider);
  final isarAsync = training
      ? ref.watch(trainingIsarProvider)
      : ref.watch(isarProvider);

  return PrinterRepository(isarAsync);
});

class PrinterRepository {
  final AsyncValue<Isar> _isarAsync;

  PrinterRepository(this._isarAsync);

  Isar? get _isar => _isarAsync.valueOrNull;

  Future<List<Printer>> getAll() async {
    if (_isar == null) return [];
    return await _isar!.printers.where().findAll();
  }

  Stream<List<Printer>> watchAll() async* {
    if (_isar == null) {
      yield [];
      return;
    }
    await for (final _ in _isar!.printers.watchLazy(fireImmediately: true)) {
      final printers = await _isar!.printers.where().findAll();
      yield printers;
    }
  }

  Future<Printer?> getById(Id id) async {
    if (_isar == null) return null;
    return await _isar!.printers.get(id);
  }

  Future<void> save(Printer printer) async {
    if (_isar == null) return;
    await _isar!.writeTxn(() async {
      await _isar!.printers.put(printer);
    });
  }

  Future<void> delete(Id id) async {
    if (_isar == null) return;
    await _isar!.writeTxn(() async {
      await _isar!.printers.delete(id);
    });
  }
}

/// Order repository with training mode support
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final training = ref.watch(trainingModeProvider);
  final isarAsync = training
      ? ref.watch(trainingIsarProvider)
      : ref.watch(isarProvider);

  return OrderRepository(isarAsync);
});

class OrderRepository {
  final AsyncValue<Isar> _isarAsync;

  OrderRepository(this._isarAsync);

  Isar? get _isar => _isarAsync.valueOrNull;

  Future<List<Order>> getAll() async {
    if (_isar == null) return [];
    return await _isar!.orders.where().sortByCreatedAtDesc().findAll();
  }

  Stream<List<Order>> watchAll() async* {
    if (_isar == null) {
      yield [];
      return;
    }
    await for (final _ in _isar!.orders.watchLazy(fireImmediately: true)) {
      final orders = await _isar!.orders.where().sortByCreatedAtDesc().findAll();
      yield orders;
    }
  }

  Future<Order?> getById(Id id) async {
    if (_isar == null) return null;
    return await _isar!.orders.get(id);
  }

  Future<void> save(Order order) async {
    if (_isar == null) return;
    await _isar!.writeTxn(() async {
      await _isar!.orders.put(order);
    });
  }

  Future<void> saveWithItems(Order order, List<OrderItem> items) async {
    if (_isar == null) return;
    await _isar!.writeTxn(() async {
      await _isar!.orders.put(order);
      await _isar!.orderItems.putAll(items);
    });
  }

  Future<List<OrderItem>> getOrderItems(String orderId) async {
    if (_isar == null) return [];
    return await _isar!.orderItems
        .filter()
        .orderIdEqualTo(orderId)
        .findAll();
  }

  Future<List<Payment>> getOrderPayments(String orderId) async {
    if (_isar == null) return [];
    return await _isar!.payments
        .filter()
        .orderIdEqualTo(orderId)
        .findAll();
  }
}

/// Inventory repository with training mode support
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final training = ref.watch(trainingModeProvider);
  final isarAsync = training
      ? ref.watch(trainingIsarProvider)
      : ref.watch(isarProvider);

  return InventoryRepository(isarAsync);
});

class InventoryRepository {
  final AsyncValue<Isar> _isarAsync;

  InventoryRepository(this._isarAsync);

  Isar? get _isar => _isarAsync.valueOrNull;

  /// Record an inventory movement
  Future<void> logMovement({
    required int itemId,
    required String itemName,
    required double quantityChange,
    required String reason,
    String? notes,
  }) async {
    if (_isar == null) return;
    await _isar!.writeTxn(() async {
      // Update item quantity
      final item = await _isar!.items.get(itemId);
      if (item != null) {
        item.quantity += quantityChange;
        await _isar!.items.put(item);
      }

      // Log the movement
      final log = InventoryLog()
        ..itemId = itemId
        ..itemName = itemName
        ..quantityChange = quantityChange
        ..reason = reason
        ..notes = notes
        ..timestamp = DateTime.now()
        ..createdAt = DateTime.now();
      await _isar!.inventoryLogs.put(log);
    });
  }

  /// Get all inventory logs for an item
  Future<List<InventoryLog>> getItemLogs(int itemId) async {
    if (_isar == null) return [];
    return await _isar!.inventoryLogs
        .filter()
        .itemIdEqualTo(itemId)
        .sortByTimestampDesc()
        .findAll();
  }

  /// Get low-stock items
  Future<List<Item>> getLowStockItems() async {
    if (_isar == null) return [];
    final allItems = await _isar!.items.where().findAll();
    return allItems
        .where((item) =>
            item.lowStockThreshold != null &&
            item.quantity <= item.lowStockThreshold!)
        .toList();
  }

  /// Watch low-stock items reactively
  Stream<List<Item>> watchLowStockItems() async* {
    if (_isar == null) {
      yield [];
      return;
    }
    await for (final _ in _isar!.items.watchLazy(fireImmediately: true)) {
      final lowStock = await getLowStockItems();
      yield lowStock;
    }
  }

  /// Get inventory logs within a date range
  Future<List<InventoryLog>> getLogsByDateRange(DateTime start, DateTime end) async {
    if (_isar == null) return [];
    return await _isar!.inventoryLogs
        .filter()
        .timestampBetween(start, end)
        .sortByTimestampDesc()
        .findAll();
  }

  /// Get movement summary by reason
  Future<Map<String, double>> getMovementSummaryByReason(DateTime start, DateTime end) async {
    final logs = await getLogsByDateRange(start, end);
    final summary = <String, double>{};
    for (final log in logs) {
      summary.update(
        log.reason,
        (existing) => existing + log.quantityChange,
        ifAbsent: () => log.quantityChange,
      );
    }
    return summary;
  }
}

