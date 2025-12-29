import 'package:flutter/material.dart';

class ModifierBottomSheet extends StatefulWidget {
  final String itemName;
  final double basePrice;
  final List<ModifierGroup> modifierGroups;
  final Function(List<String> selectedModifiers, String? notes) onConfirm;

  const ModifierBottomSheet({
    super.key,
    required this.itemName,
    required this.basePrice,
    required this.modifierGroups,
    required this.onConfirm,
  });

  @override
  State<ModifierBottomSheet> createState() => _ModifierBottomSheetState();
}

class _ModifierBottomSheetState extends State<ModifierBottomSheet> {
  final Map<String, String> _selectedSingleChoice = {}; // group -> selected value
  final Map<String, Set<String>> _selectedMultiChoice = {}; // group -> selected values
  final _notesController = TextEditingController();
  int _quantity = 1;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  List<String> get _allSelectedModifiers {
    final modifiers = <String>[];
    
    // Add single choice selections
    _selectedSingleChoice.forEach((group, value) {
      if (value.isNotEmpty) modifiers.add(value);
    });
    
    // Add multi choice selections
    _selectedMultiChoice.forEach((group, values) {
      modifiers.addAll(values);
    });
    
    return modifiers;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.itemName,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${widget.basePrice.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Modifier groups
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.modifierGroups.length + 1, // +1 for notes field
                  itemBuilder: (context, index) {
                    if (index == widget.modifierGroups.length) {
                      // Special instructions field
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Special Instructions',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                hintText: 'Add any special requests...',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      );
                    }

                    final group = widget.modifierGroups[index];
                    return _buildModifierGroup(group);
                  },
                ),
              ),

              // Bottom action bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    // Quantity control
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '$_quantity',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Add to order button
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          for (var i = 0; i < _quantity; i++) {
                            widget.onConfirm(
                              _allSelectedModifiers,
                              _notesController.text.isEmpty ? null : _notesController.text,
                            );
                          }
                          Navigator.of(context).pop();
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Add to Order',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModifierGroup(ModifierGroup group) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                group.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (group.required)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Required',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (group.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              group.subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          const SizedBox(height: 12),

          // Options
          if (group.type == ModifierType.single)
            ..._buildSingleChoiceOptions(group)
          else
            ..._buildMultiChoiceOptions(group),
        ],
      ),
    );
  }

  List<Widget> _buildSingleChoiceOptions(ModifierGroup group) {
    return group.options.map((option) {
      return RadioListTile<String>(
        title: Text(option.name),
        subtitle: option.extraCost > 0
            ? Text('+\$${option.extraCost.toStringAsFixed(2)}')
            : null,
        value: option.name,
        groupValue: _selectedSingleChoice[group.name],
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedSingleChoice[group.name] = value;
            });
          }
        },
        contentPadding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      );
    }).toList();
  }

  List<Widget> _buildMultiChoiceOptions(ModifierGroup group) {
    return group.options.map((option) {
      final selectedSet = _selectedMultiChoice[group.name] ?? {};
      final isSelected = selectedSet.contains(option.name);
      
      return CheckboxListTile(
        title: Text(option.name),
        subtitle: option.extraCost > 0
            ? Text('+\$${option.extraCost.toStringAsFixed(2)}')
            : null,
        value: isSelected,
        onChanged: (value) {
          setState(() {
            _selectedMultiChoice[group.name] ??= {};
            if (value == true) {
              _selectedMultiChoice[group.name]!.add(option.name);
            } else {
              _selectedMultiChoice[group.name]!.remove(option.name);
            }
          });
        },
        contentPadding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      );
    }).toList();
  }
}

enum ModifierType { single, multi }

class ModifierGroup {
  final String name;
  final String? subtitle;
  final ModifierType type;
  final bool required;
  final List<ModifierOption> options;

  ModifierGroup({
    required this.name,
    this.subtitle,
    required this.type,
    this.required = false,
    required this.options,
  });
}

class ModifierOption {
  final String name;
  final double extraCost;

  ModifierOption({
    required this.name,
    this.extraCost = 0.0,
  });
}
