import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/grocery_provider.dart';
import '../providers/predefined_items_provider.dart';
import '../providers/saved_lists_provider.dart';
import '../widgets/grocery_list_tile.dart';
import '../widgets/voice_mic_button.dart';
import '../widgets/predefined_items_sheet.dart';
import '../widgets/saved_lists_sheet.dart';
import '../models/grocery_item.dart';
import '../services/export_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5EE),
      body: SafeArea(
        child: Column(
          children: [
            // App Header
            _Header(),
            // Grocery List
            Expanded(child: _GroceryBody()),
            // Voice Input Footer
            _VoiceFooter(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GroceryListProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ದಿನಸಿ',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A),
                        height: 1.1,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Dinasi · ${provider.listTitle}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action buttons
              Row(
                children: [
                  // Predefined items button
                  OutlinedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => MultiProvider(
                          providers: [
                            ChangeNotifierProvider.value(value: provider),
                            ChangeNotifierProvider.value(
                              value: context.read<PredefinedItemsProvider>(),
                            ),
                          ],
                          child: DraggableScrollableSheet(
                            initialChildSize: 0.75,
                            minChildSize: 0.4,
                            maxChildSize: 0.95,
                            builder: (_, scrollController) =>
                                const PredefinedItemsSheet(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.format_list_bulleted,
                      size: 16,
                      color: Color(0xFF2D6A4F),
                    ),
                    label: const Text(
                      'ಪಟ್ಟಿ',
                      style: TextStyle(
                        color: Color(0xFF2D6A4F),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF2D6A4F),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Export button
                  IconButton(
                    onPressed: () => _showExportSheet(context, provider),
                    icon: const Icon(
                      Icons.share_outlined,
                      color: Color(0xFF2D6A4F),
                      size: 22,
                    ),
                    tooltip: 'ರಫ್ತು ಮಾಡಿ',
                  ),
                  // Save current list
                  IconButton(
                    onPressed: () => _showSaveListDialog(context, provider),
                    icon: const Icon(
                      Icons.bookmark_add_outlined,
                      color: Color(0xFF2D6A4F),
                      size: 22,
                    ),
                    tooltip: 'ಪಟ್ಟಿ ಉಳಿಸಿ',
                  ),
                  // Browse saved lists
                  IconButton(
                    onPressed: () => _showSavedListsSheet(context),
                    icon: const Icon(
                      Icons.bookmarks_outlined,
                      color: Color(0xFF2D6A4F),
                      size: 22,
                    ),
                    tooltip: 'ಉಳಿಸಿದ ಪಟ್ಟಿಗಳು',
                  ),
                  // Clear all button
                  IconButton(
                    onPressed: () {
                      if (provider.itemCount == 0) return;
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('ಎಲ್ಲ ಅಳಿಸಿ?'),
                          content: const Text(
                            'ಪಟ್ಟಿಯಲ್ಲಿರುವ ಎಲ್ಲ ವಸ್ತುಗಳನ್ನು ತೆಗೆಯಬೇಕೇ?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('ಬೇಡ'),
                            ),
                            FilledButton(
                              onPressed: () {
                                provider.clearAll();
                                Navigator.pop(context);
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                              ),
                              child: const Text('ಅಳಿಸಿ'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GroceryBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GroceryListProvider>(
      builder: (context, provider, _) {
        final items = provider.items;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item count badge
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8EDD9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shopping_basket,
                      size: 14,
                      color: Color(0xFF2D6A4F),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${items.length} ವಸ್ತುಗಳು',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2D6A4F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (items.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ಪಟ್ಟಿ ಖಾಲಿ ಇದೆ',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ಮೈಕ್ ಒತ್ತಿ ಕನ್ನಡದಲ್ಲಿ ಹೇಳಿ\nಅಥವಾ ಪಟ್ಟಿಯಿಂದ ಆರಿಸಿ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  onReorder: provider.reorderItems,
                  proxyDecorator: (child, index, animation) =>
                      Material(color: Colors.transparent, child: child),
                  itemBuilder: (context, index) {
                    return KeyedSubtree(
                      key: ValueKey(items[index].id),
                      child: GroceryListTile(item: items[index], index: index),
                    );
                  },
                ),
              ),

            // Manual add button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: TextButton.icon(
                onPressed: () => _showAddManualDialog(context, provider),
                icon: const Icon(
                  Icons.add_circle_outline,
                  size: 18,
                  color: Color(0xFF2D6A4F),
                ),
                label: const Text(
                  'ಹೊಸ ವಸ್ತು ಸೇರಿಸಿ',
                  style: TextStyle(
                    color: Color(0xFF2D6A4F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddManualDialog(
    BuildContext context,
    GroceryListProvider provider,
  ) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    Unit unit = Unit.kg;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'ಹೊಸ ವಸ್ತು',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'ಹೆಸರು',
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
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
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
                    const SizedBox(width: 10),
                    DropdownButton<Unit>(
                      value: unit,
                      items: Unit.values
                          .map(
                            (u) => DropdownMenuItem(
                              value: u,
                              child: Text(u.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => unit = v);
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'ರದ್ದು',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              FilledButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final qty = double.tryParse(qtyCtrl.text) ?? 1;
                  provider.addItem(
                    GroceryItem(name: name, quantity: qty, unit: unit),
                  );
                  Navigator.pop(ctx);
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
        );
      },
    );
  }
}

class _VoiceFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5EE),
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [VoiceMicButton()],
      ),
    );
  }
}

void _showSaveListDialog(BuildContext context, GroceryListProvider provider) {
  if (provider.itemCount == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ಪಟ್ಟಿ ಖಾಲಿ ಇದೆ — ಮೊದಲು ವಸ್ತುಗಳನ್ನು ಸೇರಿಸಿ'),
        duration: Duration(seconds: 2),
      ),
    );
    return;
  }
  final nameCtrl = TextEditingController(text: provider.listTitle);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'ಪಟ್ಟಿ ಉಳಿಸಿ',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: TextField(
        controller: nameCtrl,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'ಪಟ್ಟಿಯ ಹೆಸರು',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: const Color(0xFFF5F5F0),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('ರದ್ದು', style: TextStyle(color: Colors.grey)),
        ),
        FilledButton(
          onPressed: () {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            ctx.read<SavedListsProvider>().saveList(
              name,
              List.from(provider.items),
            );
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"$name" ಪಟ್ಟಿ ಉಳಿಸಲಾಗಿದೆ'),
                duration: const Duration(seconds: 2),
              ),
            );
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
    ),
  );
}

void _showSavedListsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: context.read<SavedListsProvider>()),
        ChangeNotifierProvider.value(
          value: context.read<GroceryListProvider>(),
        ),
      ],
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (ctx2, _) => const SavedListsSheet(),
      ),
    ),
  );
}

void _showExportSheet(BuildContext context, GroceryListProvider provider) {
  if (provider.itemCount == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ಪಟ್ಟಿ ಖಾಲಿ ಇದೆ — ಮೊದಲು ವಸ್ತುಗಳನ್ನು ಸೇರಿಸಿ'),
        duration: Duration(seconds: 2),
      ),
    );
    return;
  }
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'ರಫ್ತು ಮಾಡಿ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '${provider.itemCount} ವಸ್ತುಗಳ ಪಟ್ಟಿ',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          _ExportOptionTile(
            icon: Icons.picture_as_pdf_outlined,
            title: 'PDF ಆಗಿ',
            subtitle: 'ಪಟ್ಟಿಯನ್ನು PDF ರೂಪದಲ್ಲಿ ಶೇರ್ ಮಾಡಿ',
            color: Colors.redAccent,
            onTap: () {
              Navigator.pop(context);
              ExportService.exportAsPdf(
                context,
                List.from(provider.items),
                provider.listTitle,
              ).catchError((_) {});
            },
          ),
          const SizedBox(height: 12),
          _ExportOptionTile(
            icon: Icons.image_outlined,
            title: 'ಚಿತ್ರವಾಗಿ',
            subtitle: 'ಪಿಕ್ಚರ್ (PNG) ರೂಪದಲ್ಲಿ ಶೇರ್ ಮಾಡಿ',
            color: const Color(0xFF2D6A4F),
            onTap: () {
              Navigator.pop(context);
              ExportService.exportAsImage(
                context,
                List.from(provider.items),
                provider.listTitle,
              ).catchError((_) {});
            },
          ),
        ],
      ),
    ),
  );
}

class _ExportOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ExportOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
