# ⚡ QUICK FIX REFERENCE - COPY PASTE TEMPLATES

## PROBLEM 1: Settings Screen Crashes on Open

### Check List
- [ ] Is there a `.watch(ref.watch(...).watchAll())` pattern?
- [ ] Are there `as dynamic` type casts?
- [ ] Is app crashing with "type mismatch" error?

### Solution Template
```dart
// ❌ REMOVE THIS:
final categoriesAsync = ref.watch(
  ref.watch(categoryRepositoryProvider).watchAll() as dynamic
);

// ✅ ADD THIS:
// At file level, BEFORE the class definition:
final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchAll();
});

// In the build() method:
final categoriesAsync = ref.watch(categoriesStreamProvider);
```

**Files with this issue**: 
- ProductFormScreen
- ProductListScreen
- (Any screen watching repository streams)

---

## PROBLEM 2: Form Screen Crashes When Editing Items

### Check List
- [ ] Does form use `final isar = await ref.read(isarProvider.future)`?
- [ ] Are there direct `.isar.collections.get()` calls?
- [ ] No try-catch around database access?

### Solution Template
```dart
// ❌ REMOVE THIS:
Future<void> _loadItem() async {
  final isar = await ref.read(isarProvider.future);
  final item = await isar.items.get(id);
  // ... no error handling
}

// ✅ REPLACE WITH THIS:
Future<void> _loadItem() async {
  try {
    final repo = ref.read(itemRepositoryProvider);
    final item = await repo.getById(id);
    if (item != null && mounted) {
      setState(() => _nameController.text = item.name);
    }
  } catch (e) {
    debugPrint('Error loading item: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
```

**Files with this issue**:
- CategoryFormScreen  
- PrinterFormScreen
- ProductFormScreen
- (Any form screen loading/saving data)

---

## PROBLEM 3: Inventory Operations Crash

### Check List
- [ ] Does app crash with "unknown schema" error?
- [ ] Is `InventoryLog` model created but missing from Isar?
- [ ] Not registered in `isar_provider.dart`?

### Solution Template
```dart
// In lib/repositories/isar_provider.dart

// ✅ ADD THIS IMPORT:
import '../models/inventory_log.dart';

// ✅ UPDATE BOTH PROVIDERS:
final isarProvider = FutureProvider<Isar>((ref) async {
  final isar = await Isar.open(
    [
      ItemSchema,
      CategorySchema,
      OrderSchema,
      OrderItemSchema,
      PaymentSchema,
      PrinterSchema,
      InventoryLogSchema,  // ← ADD THIS LINE
    ],
    directory: dir.path,
    name: 'quickqash',
  );
  return isar;
});

final trainingIsarProvider = FutureProvider<Isar>((ref) async {
  final isar = await Isar.open(
    [
      ItemSchema,
      CategorySchema,
      OrderSchema,
      OrderItemSchema,
      PaymentSchema,
      PrinterSchema,
      InventoryLogSchema,  // ← ADD THIS LINE
    ],
    directory: dir.path,
    name: 'quickqash_training',
  );
  return isar;
});

// ✅ RUN BUILD RUNNER:
// dart run build_runner build --delete-conflicting-outputs
```

---

## PROBLEM 4: Generic Crash in Settings Forms

### Universal Fix Checklist
```dart
// Use this template for ANY form screen:

class MyFormScreen extends ConsumerStatefulWidget {
  const MyFormScreen({super.key});

  @override
  ConsumerState<MyFormScreen> createState() => _MyFormScreenState();
}

class _MyFormScreenState extends ConsumerState<MyFormScreen> {
  late TextEditingController _nameController;  // ← late keyword

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();  // ← initialize here
  }

  @override
  void dispose() {
    _nameController.dispose();  // ← dispose here
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final repo = ref.read(itemRepositoryProvider);  // ← use repository
      final item = Item()..name = _nameController.text;
      await repo.save(item);
      
      if (mounted) {  // ← check mounted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {  // ← check mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {  // ← check mounted
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use repository for data access
    // final repo = ref.read(itemRepositoryProvider);
    
    return Scaffold(
      // ... form UI
    );
  }
}
```

---

## QUICK DIAGNOSTIC CHECKLIST

When app crashes:

1. **Check the error message**
   ```
   "type '...' is not a subtype of" 
   → Problem: Raw stream watching → Use StreamProvider wrapper
   
   "LateInitializationError: Field ... has not been initialized"
   → Problem: Controller not initialized → Add initState() initialization
   
   "Unknown collection in Isar"
   → Problem: Missing schema → Add to isar_provider.dart and run build_runner
   
   "type 'Null' is not a type of 'Isar'"
   → Problem: Direct Isar access without null check → Use repository pattern
   ```

2. **Identify crash location**
   ```
   Crash when opening Settings
   → Check StreamProvider wrapping in form screens
   
   Crash when saving/editing items
   → Check for direct isarProvider.future access
   
   Crash when completing orders
   → Check if all models registered in Isar
   ```

3. **Apply template**
   ```
   Use the appropriate template from above
   Run dart run build_runner build
   Test the fix
   ```

---

## VERIFICATION AFTER FIX

After making any stability fix:

```bash
# 1. Check for errors
dart get_errors

# 2. Run build runner
dart run build_runner build --delete-conflicting-outputs

# 3. Run the app
flutter run -d windows

# 4. Test the crash scenario
# (e.g., if fixed ProductForm, click "Add Product" and save)

# 5. Verify no new crashes
# Check debug console for errors
```

---

## COMMON PATTERNS TO MEMORIZE

### Pattern 1: List Screen with Reactive Data
```dart
// Define provider at file level
final itemsProvider = StreamProvider<List<Item>>((ref) {
  return ref.watch(itemRepositoryProvider).watchAll();
});

// Use in build()
final items = ref.watch(itemsProvider);

// Handle in UI
items.when(
  data: (items) => ListView(...),
  loading: () => CircularProgressIndicator(),
  error: (e, st) => Text('Error: $e'),
)
```

### Pattern 2: Form Screen with Data Loading
```dart
Future<void> _loadItem() async {
  try {
    final repo = ref.read(itemRepositoryProvider);
    final item = await repo.getById(id);
    if (item != null && mounted) {
      setState(() => _nameController.text = item.name);
    }
  } catch (e) {
    debugPrint('Error: $e');
  }
}
```

### Pattern 3: Form Screen with Data Saving
```dart
Future<void> _saveItem() async {
  setState(() => _isLoading = true);
  try {
    final repo = ref.read(itemRepositoryProvider);
    await repo.save(item);
    if (mounted) context.pop();
  } catch (e) {
    if (mounted) showSnackBar('Error: $e');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

---

## EMERGENCY CRASH RECOVERY

If you're in a crash loop:

1. **Comment out problematic line** (temporary fix)
2. **Identify the pattern** (which template applies?)
3. **Apply the correct template**
4. **Run `dart run build_runner build`**
5. **Test again**

---

## WHEN TO USE EACH APPROACH

| Scenario | Approach | Template |
|----------|----------|----------|
| Displaying list of items | StreamProvider + ref.watch() | Pattern 1 |
| Loading existing item | ref.read(repository) + try-catch | Pattern 2 |
| Saving new/edited item | ref.read(repository) + try-catch | Pattern 3 |
| Reactive data in form | StreamProvider wrapper | Reactive Pattern |
| Direct database access | NEVER - use repository | Never ❌ |
| Direct Isar access | NEVER - use repository | Never ❌ |

---

## SUPPORT RESOURCES

- **STABILITY_FIXES.md** - Detailed explanations of all fixes
- **STABILITY_GUIDELINES.md** - Complete best practices guide
- **STABILITY_VISUAL_GUIDE.md** - Diagrams and architecture
- **This File** - Quick reference templates

---

**Remember**: When in doubt, **use the repository pattern**!

