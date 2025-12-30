import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/item.dart';
import '../../models/category.dart';
import '../../repositories/repositories.dart';
import '../../widgets/shared/category_tabs.dart';

// Provider that watches products collection and returns list
final productsProvider = StreamProvider<List<Item>>((ref) {
  final repo = ref.watch(itemRepositoryProvider);
  return repo.watchAll();
});

// Provider that watches categories
final productListCategoriesProvider = StreamProvider<List<Category>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchAll();
});

// Selected category filter
final selectedProductCategoryProvider = StateProvider<String?>((ref) => null);

// Search query
final productSearchProvider = StateProvider<String>((ref) => '');

// Filtered products based on category and search
final filteredProductsProvider = StreamProvider<List<Item>>((ref) {
  final repo = ref.watch(itemRepositoryProvider);
  final selectedCategory = ref.watch(selectedProductCategoryProvider);
  final searchQuery = ref.watch(productSearchProvider);

  return repo.watchFiltered(categoryId: selectedCategory, query: searchQuery);
});

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  late TextEditingController _searchController;

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

  Future<void> _deleteProduct(BuildContext context, WidgetRef ref, Item product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repo = ref.read(itemRepositoryProvider);
      final messenger = ScaffoldMessenger.of(context);
      await repo.delete(product.id);

      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('${product.name} deleted')),
        );
      }
    }
  }

  Future<void> _toggleProduct(WidgetRef ref, Item product) async {
    final repo = ref.read(itemRepositoryProvider);
    product.isActive = !product.isActive;
    await repo.save(product);
  }

  @override
  Widget build(BuildContext context) {
    final filteredProductsAsync = ref.watch(filteredProductsProvider);
    final categoriesAsync = ref.watch(productListCategoriesProvider);
    final selectedCategory = ref.watch(selectedProductCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/settings/products/add'),
            tooltip: 'Add Product',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search products...',
              onChanged: (value) {
                ref.read(productSearchProvider.notifier).state = value;
              },
              leading: const Icon(Icons.search),
              trailing: _searchController.text.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(productSearchProvider.notifier).state = '';
                        },
                      )
                    ]
                  : null,
            ),
          ),

          // Category tabs
          categoriesAsync.when(
            data: (categories) {
              final categoryNames = categories.map((c) => c.name).toList();
              final selectedIndex = selectedCategory != null
                  ? categoryNames.indexOf(selectedCategory)
                  : -1;
              return CategoryTabs(
                categories: categoryNames,
                selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
                onCategoryChanged: (index) {
                  if (index >= 0 && index < categoryNames.length) {
                    ref.read(selectedProductCategoryProvider.notifier).state = categoryNames[index];
                  }
                },
              );
            },
            loading: () => const SizedBox(
              height: 50,
              child: Center(child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
            error: (error, stack) => const SizedBox(
              height: 50,
              child: Center(child: Text('Error loading categories')),
            ),
          ),

          // Products list
          Expanded(
            child: filteredProductsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first product to get started',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Text(
                          '\$${product.price.toStringAsFixed(2)}${product.barcode != null && product.barcode!.isNotEmpty ? ' • ${product.barcode}' : ''}',
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Text('Edit'),
                              onTap: () => context.push('/settings/products/edit/${product.id}'),
                            ),
                            CheckedPopupMenuItem(
                              checked: product.isActive,
                              value: true,
                              onTap: () => _toggleProduct(ref, product),
                              child: const Text('Active'),
                            ),
                            PopupMenuItem(
                              child: const Text('Delete'),
                              onTap: () => _deleteProduct(context, ref, product),
                            ),
                          ],
                        ),
                        onTap: () => context.push('/settings/products/edit/${product.id}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: SizedBox.square(
                  dimension: 40,
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64),
                    const SizedBox(height: 16),
                    Text('Error loading products: $error'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
