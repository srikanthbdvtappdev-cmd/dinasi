import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/grocery_item.dart';
import '../providers/grocery_provider.dart';
import 'package:provider/provider.dart';
import 'edit_item_dialog.dart';

class GroceryListTile extends StatefulWidget {
  final GroceryItem item;
  final int index;

  const GroceryListTile({super.key, required this.item, required this.index});

  @override
  State<GroceryListTile> createState() => _GroceryListTileState();
}

class _GroceryListTileState extends State<GroceryListTile> {
  bool _editingQty = false;
  late TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  String _formatQty(double q) =>
      q % 1 == 0 ? q.toInt().toString() : q.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E4), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Index number
            SizedBox(
              width: 24,
              child: Text(
                '${widget.index + 1}',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Item name + edit icon
            Expanded(
              child: GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: context.read<GroceryListProvider>(),
                    child: EditItemDialog(item: item),
                  ),
                ),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2C2C2C),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit, size: 13, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),

            // Quantity editing
            _editingQty
                ? SizedBox(
                    width: 56,
                    child: TextField(
                      controller: _qtyController,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF2D6A4F),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF2D6A4F),
                            width: 2,
                          ),
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      onSubmitted: (val) {
                        final qty = double.tryParse(val) ?? item.quantity;
                        context.read<GroceryListProvider>().updateItem(
                          item.id,
                          quantity: qty,
                        );
                        setState(() => _editingQty = false);
                      },
                      onTapOutside: (_) {
                        setState(() => _editingQty = false);
                      },
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      _qtyController.text = _formatQty(item.quantity);
                      setState(() => _editingQty = true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7F4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFB7DCC8),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _formatQty(item.quantity),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D6A4F),
                        ),
                      ),
                    ),
                  ),

            const SizedBox(width: 8),

            // Unit dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7F4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFB7DCC8), width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Unit>(
                  value: item.unit,
                  isDense: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 14,
                    color: Color(0xFF2D6A4F),
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2D6A4F),
                    fontWeight: FontWeight.w600,
                  ),
                  items: Unit.values.map((u) {
                    return DropdownMenuItem(value: u, child: Text(u.label));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      context.read<GroceryListProvider>().updateItem(
                        item.id,
                        unit: v,
                      );
                    }
                  },
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Delete button
            GestureDetector(
              onTap: () {
                context.read<GroceryListProvider>().removeItem(item.id);
              },
              child: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
