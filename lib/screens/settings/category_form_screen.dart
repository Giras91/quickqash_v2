import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/category.dart';
import '../../repositories/repositories.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  final int? categoryId;

  const CategoryFormScreen({super.key, this.categoryId});

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedIcon;
  int? _selectedColor;
  bool _isLoading = false;

  final List<MapEntry<String, IconData>> _availableIcons = [
    const MapEntry('local_cafe', Icons.local_cafe),
    const MapEntry('restaurant', Icons.restaurant),
    const MapEntry('fastfood', Icons.fastfood),
    const MapEntry('local_bar', Icons.local_bar),
    const MapEntry('local_pizza', Icons.local_pizza),
    const MapEntry('cake', Icons.cake),
    const MapEntry('icecream', Icons.icecream),
    const MapEntry('lunch_dining', Icons.lunch_dining),
    const MapEntry('dinner_dining', Icons.dinner_dining),
    const MapEntry('breakfast_dining', Icons.breakfast_dining),
    const MapEntry('liquor', Icons.liquor),
    const MapEntry('coffee', Icons.coffee),
    const MapEntry('tapas', Icons.tapas),
    const MapEntry('ramen_dining', Icons.ramen_dining),
    const MapEntry('set_meal', Icons.set_meal),
    const MapEntry('soup_kitchen', Icons.soup_kitchen),
  ];

  final List<Color> _availableColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _loadCategory();
  }

  Future<void> _loadCategory() async {
    if (widget.categoryId == null) return;

    try {
      final repo = ref.read(categoryRepositoryProvider);
      final category = await repo.getById(widget.categoryId!);
      
      if (category != null && mounted) {
        _nameController.text = category.name;
        _selectedIcon = category.iconName;
        _selectedColor = category.colorValue;
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading category: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(categoryRepositoryProvider);
      
      // Get max sort order for new categories
      int sortOrder = 0;
      if (widget.categoryId == null) {
        final categories = await repo.getAll();
        sortOrder = categories.isEmpty ? 0 : categories.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
      } else {
        final existing = await repo.getById(widget.categoryId!);
        sortOrder = existing?.sortOrder ?? 0;
      }

      final category = Category()
        ..name = _nameController.text.trim()
        ..iconName = _selectedIcon
        ..colorValue = _selectedColor
        ..sortOrder = sortOrder;

      if (widget.categoryId != null) {
        category.id = widget.categoryId!;
      }

      await repo.save(category);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.categoryId != null
                  ? 'Category updated successfully'
                  : 'Category added successfully',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving category: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryId != null ? 'Edit Category' : 'Add Category'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g., Beverages, Appetizers',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a category name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            Text(
              'Icon',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableIcons.map((entry) {
                final isSelected = _selectedIcon == entry.key;
                return InkWell(
                  onTap: () => setState(() => _selectedIcon = entry.key),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Icon(
                      entry.value,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Color',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableColors.map((color) {
                final isSelected = _selectedColor == color.toARGB32();
                return InkWell(
                  onTap: () => setState(() => _selectedColor = color.toARGB32()),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(
                              color: Colors.white,
                              width: 3,
                            )
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            
            FilledButton(
              onPressed: _isLoading ? null : _saveCategory,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.categoryId != null ? 'Update Category' : 'Add Category'),
            ),
          ],
        ),
      ),
    );
  }
}
