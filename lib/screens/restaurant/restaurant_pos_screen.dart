import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/shared/cart_panel.dart';
import '../../widgets/shared/category_tabs.dart';
import '../../widgets/shared/product_card.dart';
import '../../widgets/shared/training_banner.dart';
import '../../widgets/shared/modifier_bottom_sheet.dart';
import '../../providers/cart_provider.dart';
import '../../models/item.dart';
import '../../models/category.dart';
import '../../repositories/repositories.dart';

class RestaurantPosScreen extends ConsumerStatefulWidget {
  const RestaurantPosScreen({super.key});

  @override
  ConsumerState<RestaurantPosScreen> createState() => _RestaurantPosScreenState();
}

class _RestaurantPosScreenState extends ConsumerState<RestaurantPosScreen> {
  late TextEditingController _searchController;
  int? _selectedTableIndex;
  int _selectedCategory = 0;
  int _selectedSeat = 1;
  bool _showTableSelector = true;

  final _mockTables = List.generate(
    12,
    (i) => _MockTable(
      number: i + 1,
      status: i % 4 == 0
          ? TableStatus.empty
          : i % 4 == 1
              ? TableStatus.seated
              : i % 4 == 2
                  ? TableStatus.ordering
                  : TableStatus.served,
    ),
  );

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addItemToTable(Item item) {
    if (_selectedTableIndex == null) return;

    ref.read(cartProvider.notifier).addItem(
      itemId: item.id.toString(),
      name: item.name,
      price: item.price,
      modifiers: ['Seat $_selectedSeat'],
      kitchenRoute: item.kitchenRoute,
    );
  }

  void _showModifierSheet(Item item) {
    if (_selectedTableIndex == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModifierBottomSheet(
        itemName: item.name,
        basePrice: item.price,
        modifierGroups: _getModifiersForItem(item),
        onConfirm: (modifiers, notes) {
          ref.read(cartProvider.notifier).addItem(
            itemId: item.id.toString(),
            name: item.name,
            price: item.price,
            modifiers: ['Seat $_selectedSeat', ...modifiers],
            kitchenRoute: item.kitchenRoute,
            notes: notes,
          );
        },
      ),
    );
  }

  List<ModifierGroup> _getModifiersForItem(Item item) {
    // Return different modifiers based on category name
    final cat = (item.category ?? '').toLowerCase();
    if (cat.contains('appet')) { // Appetizers
        return [
          ModifierGroup(
            name: 'Preparation',
            type: ModifierType.single,
            options: [
              ModifierOption(name: 'Regular'),
              ModifierOption(name: 'Extra Crispy'),
              ModifierOption(name: 'Well Done'),
            ],
          ),
        ];
    } else if (cat.contains('entree') || cat.contains('main')) { // Entrees
        return [
          ModifierGroup(
            name: 'Temperature',
            type: ModifierType.single,
            required: true,
            options: [
              ModifierOption(name: 'Rare'),
              ModifierOption(name: 'Medium Rare'),
              ModifierOption(name: 'Medium'),
              ModifierOption(name: 'Medium Well'),
              ModifierOption(name: 'Well Done'),
            ],
          ),
          ModifierGroup(
            name: 'Sides',
            subtitle: 'Choose up to 2',
            type: ModifierType.multi,
            options: [
              ModifierOption(name: 'Fries'),
              ModifierOption(name: 'Mashed Potatoes'),
              ModifierOption(name: 'Vegetables'),
              ModifierOption(name: 'Salad'),
              ModifierOption(name: 'Rice'),
            ],
          ),
        ];
    } else if (cat.contains('side')) { // Sides
        return [
          ModifierGroup(
            name: 'Size',
            type: ModifierType.single,
            options: [
              ModifierOption(name: 'Regular'),
              ModifierOption(name: 'Large', extraCost: 2.00),
            ],
          ),
        ];
    } else if (cat.contains('dessert')) { // Desserts
        return [
          ModifierGroup(
            name: 'Toppings',
            subtitle: 'Select any',
            type: ModifierType.multi,
            options: [
              ModifierOption(name: 'Whipped Cream', extraCost: 1.00),
              ModifierOption(name: 'Ice Cream', extraCost: 2.00),
              ModifierOption(name: 'Chocolate Sauce', extraCost: 0.50),
              ModifierOption(name: 'Caramel Sauce', extraCost: 0.50),
            ],
          ),
        ];
    } else if (cat.contains('drink') || cat.contains('beverage')) { // Drinks
        return [
          ModifierGroup(
            name: 'Size',
            type: ModifierType.single,
            options: [
              ModifierOption(name: 'Small'),
              ModifierOption(name: 'Medium', extraCost: 0.50),
              ModifierOption(name: 'Large', extraCost: 1.00),
            ],
          ),
          ModifierGroup(
            name: 'Ice',
            type: ModifierType.single,
            options: [
              ModifierOption(name: 'Regular Ice'),
              ModifierOption(name: 'Light Ice'),
              ModifierOption(name: 'No Ice'),
              ModifierOption(name: 'Extra Ice'),
            ],
          ),
        ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    // Load categories and items via repositories
    final categoriesAsync = ref.watch(restaurantCategoriesProvider);
    final itemsAsync = ref.watch(restaurantItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('QuickQash Restaurant'),
            const SizedBox(width: 12),
            const TrainingBadge(),
            if (_selectedTableIndex != null) ...[
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Table ${_mockTables[_selectedTableIndex!].number}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showTableSelector ? Icons.chevron_left : Icons.chevron_right),
            onPressed: () {
              setState(() {
                _showTableSelector = !_showTableSelector;
              });
            },
            tooltip: _showTableSelector ? 'Hide tables' : 'Show tables',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 8),
        ],
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          const TrainingBanner(),
          Expanded(
            child: Row(
              children: [
                // Left: Table selector (20%, collapsible)
                if (_showTableSelector)
                  Container(
                    width: 220,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        right: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Theme.of(context).dividerColor),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Tables',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _mockTables.length,
                            itemBuilder: (context, index) {
                              final table = _mockTables[index];
                              final isSelected = _selectedTableIndex == index;
                              return _TableCard(
                                table: table,
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    _selectedTableIndex = index;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                // Center: Menu builder (50%)
                Expanded(
                  flex: 50,
                  child: Column(
                    children: [
                      if (_selectedTableIndex != null) ...[
                        categoriesAsync.when(
                          data: (categories) {
                            final names = categories.map((c) => c.name).toList();
                            return CategoryTabs(
                              categories: names,
                              selectedIndex: _selectedCategory,
                              onCategoryChanged: (index) {
                                setState(() {
                                  _selectedCategory = index;
                                });
                              },
                            );
                          },
                          loading: () => const SizedBox(
                            height: 50,
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          error: (e, s) => const SizedBox(
                            height: 50,
                            child: Center(child: Text('Error loading categories')),
                          ),
                        ),
                        // Search bar
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            border: Border(
                              bottom: BorderSide(color: Theme.of(context).dividerColor),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search or scan barcode...',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (barcode) async {
                                    if (_selectedTableIndex == null) return;
                                    final messenger = ScaffoldMessenger.of(context);
                                    final repo = ref.read(itemRepositoryProvider);
                                    final found = await repo.getByBarcode(barcode.trim());
                                    if (found != null) {
                                      _addItemToTable(found);
                                      messenger.showSnackBar(SnackBar(content: Text('Added ${found.name} to Table ${_mockTables[_selectedTableIndex!].number}')));
                                      _searchController.clear();
                                      setState(() {});
                                    } else {
                                      messenger.showSnackBar(const SnackBar(content: Text('Item not found for barcode')));
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Seat selector
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            border: Border(
                              bottom: BorderSide(color: Theme.of(context).dividerColor),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text('Seat: '),
                              const SizedBox(width: 8),
                              ...List.generate(4, (i) {
                                final seat = i + 1;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text('$seat'),
                                    selected: _selectedSeat == seat,
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedSeat = seat;
                                      });
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                      Expanded(
                        child: _selectedTableIndex == null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.table_restaurant,
                                      size: 64,
                                      color: Theme.of(context).disabledColor,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Select a table to start',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: Theme.of(context).disabledColor,
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            : itemsAsync.when(
                                data: (items) {
                                  var filtered = items.where((i) => i.isActive).toList();
                                  final names = categoriesAsync.asData?.value.map((c) => c.name).toList() ?? const <String>[];
                                  if (names.isNotEmpty && _selectedCategory >= 0 && _selectedCategory < names.length) {
                                    final selectedName = names[_selectedCategory];
                                    filtered = filtered.where((i) => (i.category ?? '') == selectedName).toList();
                                  }
                                  final q = _searchController.text.trim().toLowerCase();
                                  if (q.isNotEmpty) {
                                    filtered = filtered.where((i) => i.name.toLowerCase().contains(q) || (i.barcode?.toLowerCase().contains(q) ?? false)).toList();
                                  }

                                  return GridView.builder(
                                    padding: const EdgeInsets.all(16),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      childAspectRatio: 0.9,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) {
                                      final item = filtered[index];
                                      final prefix = item.kitchenRoute != null ? '${item.kitchenRoute} ' : '';
                                      return ProductCard(
                                        name: '$prefix${item.name}',
                                        price: item.price,
                                        onTap: () => _addItemToTable(item),
                                        onLongPress: () => _showModifierSheet(item),
                                      );
                                    },
                                  );
                                },
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (e, s) => Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.error_outline, size: 64),
                                      const SizedBox(height: 16),
                                      Text('Error: $e'),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                // Right: Order summary (30%)
                Expanded(
                  flex: 30,
                  child: CartPanel(
                    tableName: _selectedTableIndex != null
                        ? _mockTables[_selectedTableIndex!].name
                        : null,
                    checkoutLabel: 'Send to Kitchen',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  final _MockTable table;
  final bool isSelected;
  final VoidCallback onTap;

  const _TableCard({
    required this.table,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color getStatusColor() {
      switch (table.status) {
        case TableStatus.empty:
          return Colors.grey.shade300;
        case TableStatus.seated:
          return Colors.blue.shade200;
        case TableStatus.ordering:
          return Colors.orange.shade200;
        case TableStatus.served:
          return Colors.green.shade200;
      }
    }

    return Card(
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : getStatusColor(),
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.table_restaurant,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Colors.black87,
              ),
              const SizedBox(height: 4),
              Text(
                'Table ${table.number}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum TableStatus { empty, seated, ordering, served }

class _MockTable {
  final int number;
  final TableStatus status;
  String get name => 'Table $number';

  _MockTable({required this.number, required this.status});
}


// Stream providers for Restaurant POS
final restaurantCategoriesProvider = StreamProvider<List<Category>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchAll();
});

final restaurantItemsProvider = StreamProvider<List<Item>>((ref) {
  final repo = ref.watch(itemRepositoryProvider);
  return repo.watchAll();
});
