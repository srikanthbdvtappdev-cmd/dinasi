import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/grocery_item.dart';
import '../providers/grocery_provider.dart';
import 'package:provider/provider.dart';

class EditItemDialog extends StatefulWidget {
  final GroceryItem item;
  const EditItemDialog({super.key, required this.item});

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late Unit _selectedUnit;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController = TextEditingController(
      text: widget.item.quantity % 1 == 0
          ? widget.item.quantity.toInt().toString()
          : widget.item.quantity.toString(),
    );
    _selectedUnit = widget.item.unit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'ಪಟ್ಟಿ ಬದಲಾಯಿಸಿ',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'ವಸ್ತುವಿನ ಹೆಸರು',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: const Color(0xFFF5F5F0),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'ಪ್ರಮಾಣ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F0),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Unit>(
                    value: _selectedUnit,
                    items: Unit.values.map((u) {
                      return DropdownMenuItem(value: u, child: Text(u.label));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedUnit = v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ರದ್ದು', style: TextStyle(color: Colors.grey)),
        ),
        FilledButton(
          onPressed: () {
            final qty = double.tryParse(_quantityController.text) ?? 1;
            context.read<GroceryListProvider>().updateItem(
              widget.item.id,
              name: _nameController.text.trim(),
              quantity: qty,
              unit: _selectedUnit,
            );
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2D6A4F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('ಉಳಿಸಿ'),
        ),
      ],
    );
  }
}
