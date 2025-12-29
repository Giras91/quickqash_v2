import 'package:isar/isar.dart';
import '../models/category.dart';
import '../models/item.dart';

/// Service to seed initial data on first launch
class SeedService {
  static Future<void> seedInitialData(Isar isar) async {
    // Check if data already exists
    final existingCategories = await isar.categorys.count();
    if (existingCategories > 0) {
      return; // Already seeded
    }

    // Create default categories
    final categories = [
      Category()
        ..name = 'Beverages'
        ..iconName = 'local_cafe'
        ..colorValue = 0xFF6200EE
        ..sortOrder = 0,
      Category()
        ..name = 'Food'
        ..iconName = 'restaurant'
        ..colorValue = 0xFFB3261E
        ..sortOrder = 1,
      Category()
        ..name = 'Snacks'
        ..iconName = 'fastfood'
        ..colorValue = 0xFFFB8500
        ..sortOrder = 2,
      Category()
        ..name = 'Desserts'
        ..iconName = 'cake'
        ..colorValue = 0xFFC41E3A
        ..sortOrder = 3,
    ];

    // Create sample items
    final items = [
      Item()
        ..name = 'Coffee'
        ..price = 3.50
        ..category = 'Beverages'
        ..isActive = true
        ..createdAt = DateTime.now(),
      Item()
        ..name = 'Espresso'
        ..price = 2.50
        ..category = 'Beverages'
        ..isActive = true
        ..createdAt = DateTime.now(),
      Item()
        ..name = 'Latte'
        ..price = 4.00
        ..category = 'Beverages'
        ..isActive = true
        ..createdAt = DateTime.now(),
      Item()
        ..name = 'Burger'
        ..price = 9.99
        ..category = 'Food'
        ..isActive = true
        ..createdAt = DateTime.now(),
      Item()
        ..name = 'Pizza Slice'
        ..price = 5.99
        ..category = 'Food'
        ..isActive = true
        ..createdAt = DateTime.now(),
      Item()
        ..name = 'Sandwich'
        ..price = 7.50
        ..category = 'Food'
        ..isActive = true
        ..createdAt = DateTime.now(),
      Item()
        ..name = 'Chips'
        ..price = 2.00
        ..category = 'Snacks'
        ..isActive = true
        ..createdAt = DateTime.now(),
      Item()
        ..name = 'Popcorn'
        ..price = 3.00
        ..category = 'Snacks'
        ..isActive = true
        ..createdAt = DateTime.now(),
      Item()
        ..name = 'Brownie'
        ..price = 4.50
        ..category = 'Desserts'
        ..isActive = true
        ..createdAt = DateTime.now(),
      Item()
        ..name = 'Cheesecake'
        ..price = 6.00
        ..category = 'Desserts'
        ..isActive = true
        ..createdAt = DateTime.now(),
    ];

    // Write to database in transaction
    await isar.writeTxn(() async {
      await isar.categorys.putAll(categories);
      await isar.items.putAll(items);
    });
  }
}
