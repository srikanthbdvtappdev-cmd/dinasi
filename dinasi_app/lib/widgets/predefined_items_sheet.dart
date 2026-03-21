import 'package:flutter/material.dart';
import '../models/grocery_item.dart';
import '../providers/grocery_provider.dart';
import '../providers/predefined_items_provider.dart';
import 'package:provider/provider.dart';

class PredefinedItemsSheet extends StatefulWidget {
  const PredefinedItemsSheet({super.key});

  @override
  State<PredefinedItemsSheet> createState() => _PredefinedItemsSheetState();
}

class _PredefinedItemsSheetState extends State<PredefinedItemsSheet> {
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCustomDialog(BuildContext context) {
    final kannadaCtrl = TextEditingController();
    final englishCtrl = TextEditingController();
    Unit selectedUnit = Unit.kg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'ಹೊಸ ವಸ್ತು ಸೇರಿಸಿ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: kannadaCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'ಕನ್ನಡ ಹೆಸರು *',
                  hintText: 'ಉದಾ: ಶ್ಯಾವಿಗೆ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F0),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: englishCtrl,
                decoration: InputDecoration(
                  labelText: 'English name (optional)',
                  hintText: 'e.g. Vermicelli',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F0),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Default unit: ',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Unit>(
                        value: selectedUnit,
                        isDense: true,
                        items: Unit.values
                            .map(
                              (u) => DropdownMenuItem(
                                value: u,
                                child: Text(u.label),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setDialogState(() => selectedUnit = v);
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
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ರದ್ದು', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              onPressed: () {
                final added = context
                    .read<PredefinedItemsProvider>()
                    .addCustomItem(
                      kannadaCtrl.text,
                      englishCtrl.text,
                      selectedUnit.label,
                    );
                Navigator.pop(ctx);
                if (!added) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('ಈ ಹೆಸರು ಈಗಾಗಲೇ ಇದೆ'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'ಪೂರ್ವನಿರ್ಧಾರಿತ ಪಟ್ಟಿಗೆ ಸೇರಿಸಲಾಗಿದೆ: ${kannadaCtrl.text.trim()}',
                      ),
                      backgroundColor: const Color(0xFF2D6A4F),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('ಸೇರಿಸಿ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PredefinedItemsProvider>(
      builder: (context, provider, _) {
        final filtered = provider.search(_query);

        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAF7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                child: Row(
                  children: [
                    const Text(
                      'ಪಟ್ಟಿಯಲ್ಲಿ ಸೇರಿಸಿ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const Spacer(),
                    // Add new predefined item button
                    TextButton.icon(
                      onPressed: () => _showAddCustomDialog(context),
                      icon: const Icon(
                        Icons.add_circle,
                        size: 18,
                        color: Color(0xFF2D6A4F),
                      ),
                      label: const Text(
                        'ಹೊಸದು',
                        style: TextStyle(
                          color: Color(0xFF2D6A4F),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'ಹುಡುಕಿ / Search...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF2D6A4F),
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF2D6A4F),
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              // Items list
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'ಯಾವುದೂ ಸಿಗಲಿಲ್ಲ',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () => _showAddCustomDialog(context),
                              icon: const Icon(
                                Icons.add,
                                color: Color(0xFF2D6A4F),
                              ),
                              label: const Text(
                                'ಹೊಸ ವಸ್ತು ಸೇರಿಸಿ',
                                style: TextStyle(color: Color(0xFF2D6A4F)),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (context, i) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final data = filtered[index];
                          final inCart = context
                              .watch<GroceryListProvider>()
                              .items
                              .any((i) => i.name == data['kannada']);
                          return _ItemRow(
                            data: data,
                            isCustom: provider.isCustom(data),
                            isInCart: inCart,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ItemRow extends StatelessWidget {
  final Map<String, String> data;
  final bool isCustom;
  final bool isInCart;

  const _ItemRow({
    required this.data,
    required this.isCustom,
    required this.isInCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isInCart
            ? const Color(0xFF2D6A4F).withValues(alpha: 0.07)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        title: Row(
          children: [
            Flexible(
              child: Text(
                data['kannada']!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isInCart
                      ? const Color(0xFF2D6A4F)
                      : const Color(0xFF1A1A1A),
                ),
              ),
            ),
            if (isInCart) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D6A4F),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 10, color: Colors.white),
                    SizedBox(width: 2),
                    Text(
                      'ಪಟ್ಟಿಯಲ್ಲಿದೆ',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isCustom) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8EDD9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'custom',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF2D6A4F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          data['english']!,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.tonal(
              onPressed: () {
                context.read<GroceryListProvider>().addPredefinedItem(
                  data['kannada']!,
                  data['unit'] ?? 'pcs',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ಪಟ್ಟಿಗೆ ಸೇರಿಸಲಾಗಿದೆ: ${data['kannada']}'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF2D6A4F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: isInCart
                    ? const Color(0xFF2D6A4F)
                    : const Color(0xFFD8EDD9),
                foregroundColor: isInCart
                    ? Colors.white
                    : const Color(0xFF2D6A4F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isInCart)
                    const Icon(Icons.add, size: 14)
                  else
                    const Text('+ ಸೇರಿಸಿ', style: TextStyle(fontSize: 13)),
                  if (isInCart)
                    const Text(' ಮತ್ತೊಂದು', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            if (isCustom) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.redAccent,
                ),
                tooltip: 'ತೆಗೆದುಹಾಕು',
                onPressed: () {
                  context.read<PredefinedItemsProvider>().removeCustomItem(
                    data,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
