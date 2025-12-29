import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/item.dart';
import '../../repositories/repositories.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;

  const ProductFormScreen({super.key, this.productId});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _barcodeController;

  String? _selectedCategoryId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _barcodeController = TextEditingController();

    // Load existing product if editing
    if (widget.productId != null) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    final itemRepo = ref.read(itemRepositoryProvider);
    final id = int.tryParse(widget.productId ?? '');
    if (id == null) return;

    final product = await itemRepo.getById(id);
    if (product != null && mounted) {
      setState(() {
        _nameController.text = product.name;
        _priceController.text = product.price.toString();
        _barcodeController.text = product.barcode ?? '';
        _selectedCategoryId = product.category;
        _isActive = product.isActive;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    final name = _nameController.text.trim();
    final priceStr = _priceController.text.trim();
    final barcode = _barcodeController.text.trim();

    // Validation
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product name is required')),
      );
      return;
    }

    final price = double.tryParse(priceStr);
    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid price')),
      );
      return;
    }

    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a category')),
      );
      return;
    }

    try {
      final itemRepo = ref.read(itemRepositoryProvider);

      Item product;
      if (widget.productId != null) {
        // Edit existing product
        final id = int.tryParse(widget.productId ?? '');
        if (id == null) throw Exception('Invalid product ID');

        final existing = await itemRepo.getById(id);
        if (existing == null) throw Exception('Product not found');

        product = existing
          ..name = name
          ..price = price
          ..barcode = barcode.isEmpty ? null : barcode
          ..category = _selectedCategoryId!
          ..isActive = _isActive;
      } else {
        // Create new product
        product = Item()
          ..name = name
          ..price = price
          ..barcode = barcode.isEmpty ? null : barcode
          ..category = _selectedCategoryId
          ..isActive = _isActive
          ..createdAt = DateTime.now();
      }

      await itemRepo.save(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.productId != null ? 'Product updated' : 'Product created')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(ref.watch(categoryRepositoryProvider).watchAll() as dynamic);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId != null ? 'Edit Product' : 'Add Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Product Name',
                hintText: 'Enter product name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Price
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Price',
                hintText: '0.00',
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Barcode
            TextField(
              controller: _barcodeController,
              decoration: InputDecoration(
                labelText: 'Barcode (Optional)',
                hintText: 'Enter or scan barcode',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category dropdown
            categoriesAsync.when(
              data: (categories) {
                return DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  hint: const Text('Select Category'),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat.name,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Text('Error loading categories: $error'),
            ),
            const SizedBox(height: 16),

            // Active toggle
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Show this product in POS'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton(
              onPressed: _saveProduct,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Save Product'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
