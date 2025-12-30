# QuickQash Stability Guidelines - Quick Reference

## 🚨 CRITICAL RULES - Violating these causes crashes

### Rule 1: NEVER access Isar directly
❌ **DON'T DO THIS:**
```dart
final isar = await ref.read(isarProvider.future);
final item = await isar.items.get(id);
```

✅ **DO THIS INSTEAD:**
```dart
final repo = ref.read(itemRepositoryProvider);
final item = await repo.getById(id);
```

**Why?** Repositories handle null Isar, training mode, and errors. Direct access bypasses all safety.

---

### Rule 2: NEVER watch raw Streams with ref.watch()
❌ **DON'T DO THIS:**
```dart
final data = ref.watch(ref.watch(categoryRepositoryProvider).watchAll() as dynamic);
```

✅ **DO THIS INSTEAD:**
```dart
// At file level:
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAll();
});

// In build():
final data = ref.watch(categoriesProvider);
```

**Why?** `ref.watch()` expects `ProviderListenable`, not raw `Stream`. Type casting hides errors.

---

### Rule 3: ALWAYS wrap repository streams in StreamProvider
❌ **INCORRECT PATTERN:**
```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var items = ref.watch(ref.watch(itemRepositoryProvider).watchAll());  // CRASH!
  }
}
```

✅ **CORRECT PATTERN:**
```dart
final itemsProvider = StreamProvider<List<Item>>((ref) {
  final repo = ref.watch(itemRepositoryProvider);
  return repo.watchAll();
});

class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var items = ref.watch(itemsProvider);
  }
}
```

---

### Rule 4: ALWAYS include all Isar schemas in initialization
In `lib/repositories/isar_provider.dart`:
```dart
final isarProvider = FutureProvider<Isar>((ref) async {
  final isar = await Isar.open(
    [
      ItemSchema,
      CategorySchema,
      OrderSchema,
      OrderItemSchema,
      PaymentSchema,
      PrinterSchema,
      InventoryLogSchema,  // ← DON'T FORGET THIS
    ],
    directory: dir.path,
    name: 'quickqash',
  );
  return isar;
});
```

**After adding a new model**, run:
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 📋 IMPLEMENTATION CHECKLIST

When adding a new settings form screen:

- [ ] Create `FooFormScreen` with `ConsumerStatefulWidget`
- [ ] Initialize controllers in `initState()`
- [ ] Dispose controllers in `dispose()`
- [ ] Use `ref.read(fooRepositoryProvider)` for data access
- [ ] Wrap all database operations in try-catch
- [ ] Use `if (mounted)` before showing dialogs
- [ ] Test: Add new item, edit item, delete item

When adding a new list screen:

- [ ] Create `FooListScreen` with `ConsumerStatefulWidget`
- [ ] Create `StreamProvider<List<Foo>>` for data
- [ ] Use `ref.watch(fooProvider)` for reactive data
- [ ] Handle `.when(data:..., loading:..., error:...)`
- [ ] Use `FutureBuilder` or `.when()` for async operations
- [ ] Never use `.toList()` on Streams without `.toList()`

---

## 🛡️ ERROR PREVENTION PATTERNS

### Pattern 1: Safe Database Reads
```dart
Future<Item?> _loadItem(int id) async {
  try {
    final repo = ref.read(itemRepositoryProvider);
    final item = await repo.getById(id);
    if (item != null && mounted) {
      setState(() => _nameController.text = item.name);
    }
  } catch (e) {
    debugPrint('Error loading item: $e');
    // Show error snackbar if needed
  }
}
```

### Pattern 2: Safe Database Writes
```dart
Future<void> _saveItem() async {
  if (!_formKey.currentState!.validate()) return;
  
  setState(() => _isLoading = true);
  
  try {
    final repo = ref.read(itemRepositoryProvider);
    final item = Item()..name = _nameController.text;
    await repo.save(item);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved')),
      );
      context.pop();
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

### Pattern 3: Reactive List Display
```dart
// Define provider at file level
final itemsProvider = StreamProvider<List<Item>>((ref) {
  final repo = ref.watch(itemRepositoryProvider);
  return repo.watchAll();
});

// Use in StatelessWidget (or ConsumerWidget)
class ItemListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsProvider);
    
    return itemsAsync.when(
      data: (items) => ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(title: Text(item.name));
        },
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

---

## 🔍 DEBUGGING CRASHES

### If app crashes when entering Settings:
1. Check if all repositories use `if (_isar == null) return ...`
2. Check if all StreamProviders are defined at file level
3. Run `dart run build_runner build`
4. Check `build/generated_files` for schema errors

### If app crashes when editing/adding items:
1. Check if form uses `ref.read(repositoryProvider)` 
2. Check if `isarProvider` includes all schemas
3. Check if all database writes are in try-catch blocks
4. Check if `mounted` checks are used before setState

### If app crashes on List screens:
1. Check if `.when()` handles loading and error states
2. Check if StreamProvider is defined at file level, not inline
3. Check if `ref.watch()` is called only in build() method
4. Check if data passed to ListView is not null

---

## 📊 QUICK REPO REFERENCE

### ItemRepository
```dart
Future<Item?> getById(Id id)
Future<List<Item>> getAll()
Future<List<Item>> getActiveItems()
Future<void> save(Item item)
Future<void> delete(Id id)
Stream<List<Item>> watchAll()
Stream<List<Item>> watchFiltered({String? categoryId, String? query})
```

### CategoryRepository
```dart
Future<Category?> getById(Id id)
Future<List<Category>> getAll()
Future<void> save(Category category)
Future<void> delete(Id id)
Stream<List<Category>> watchAll()
```

### PrinterRepository
```dart
Future<Printer?> getById(Id id)
Future<List<Printer>> getAll()
Future<void> save(Printer printer)
Future<void> delete(Id id)
Stream<List<Printer>> watchAll()
```

### OrderRepository
```dart
Future<Order?> getById(Id id)
Future<List<Order>> getAll()
Future<void> save(Order order)
Stream<List<Order>> watchAll()
Stream<List<Order>> watchByDateRange(DateTime start, DateTime end)
```

### InventoryRepository
```dart
Future<void> logMovement(int itemId, String itemName, int quantityChange, String reason, String notes)
Future<List<Item>> getLowStockItems()
Stream<List<Item>> watchLowStockItems()
Future<List<InventoryLog>> getLogsByDateRange(DateTime start, DateTime end)
```

---

## 🚀 LAUNCH READINESS CHECKLIST

Before running the app:
- [ ] All 5 settings forms use repositories, not direct Isar
- [ ] All StreamProviders are defined at file level
- [ ] All imports for repositories are correct
- [ ] `build_runner` has been run
- [ ] No `import 'package:isar/isar.dart'` in UI screens
- [ ] All try-catch blocks have error handling
- [ ] All async operations show loading states

---

## 📚 REFERENCE DOCUMENTS

- [STABILITY_FIXES.md](STABILITY_FIXES.md) - Detailed fix explanations
- [Riverpod Best Practices](https://riverpod.dev/) - Official docs
- [Isar Database Guide](https://isar.dev/) - Schema documentation

