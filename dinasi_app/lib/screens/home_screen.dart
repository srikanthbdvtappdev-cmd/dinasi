import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/grocery_provider.dart';
import '../providers/language_provider.dart';
import '../providers/app_strings.dart';
import '../providers/predefined_items_provider.dart';
import '../providers/saved_lists_provider.dart';
import '../widgets/grocery_list_tile.dart';
import '../widgets/voice_mic_button.dart';
import '../widgets/predefined_items_sheet.dart';
import '../widgets/saved_lists_sheet.dart';
import '../models/grocery_item.dart';
import '../services/export_service.dart';
import 'notepad_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _notepadCtrl = NotepadController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5EE),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              tabController: _tab,
              currentTab: _tab.index,
              notepadCtrl: _notepadCtrl,
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  Column(
                    children: [
                      Expanded(child: _GroceryBody()),
                      _VoiceFooter(),
                    ],
                  ),
                  NotepadTabContent(controller: _notepadCtrl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final TabController tabController;
  final int currentTab;
  final NotepadController? notepadCtrl;

  const _Header({
    required this.tabController,
    required this.currentTab,
    this.notepadCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<GroceryListProvider, LanguageProvider>(
      builder: (context, provider, langProvider, _) {
        final s = AppStrings.of(langProvider);
        return Container(
          color: const Color(0xFF2D6A4F),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: title + action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 8, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title
                    Expanded(
                      child: Text(
                        s.appTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF8A80),
                          height: 1.1,
                        ),
                      ),
                    ),
                    // Language toggle — always visible
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        context
                            .read<GroceryListProvider>()
                            .clearForLanguageSwitch();
                        langProvider.toggle();
                      },
                      icon: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white54, width: 1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          langProvider.isKannada ? 'ಕನ' : 'EN',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      tooltip: s.tooltipLanguage,
                    ),
                    // Notepad actions — visible only on the notepad tab
                    if (currentTab == 1) ...[
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: () => notepadCtrl?.showSavedNotes?.call(),
                        icon: const Icon(
                          Icons.notes,
                          color: Colors.white,
                          size: 22,
                        ),
                        tooltip: s.notepadSavedNotesTooltip,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: () => notepadCtrl?.save?.call(),
                        icon: const Icon(
                          Icons.save_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                        tooltip: s.notepadSaveTooltip,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: () => notepadCtrl?.delete?.call(),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFFF8A80),
                          size: 22,
                        ),
                        tooltip: s.notepadClearTooltip,
                      ),
                    ],
                    // Grocery actions — visible only on the grocery tab
                    if (currentTab == 0) ...[
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => MultiProvider(
                              providers: [
                                ChangeNotifierProvider.value(value: provider),
                                ChangeNotifierProvider.value(
                                  value: context
                                      .read<PredefinedItemsProvider>(),
                                ),
                                ChangeNotifierProvider.value(
                                  value: langProvider,
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
                          size: 22,
                          color: Colors.white,
                        ),
                        tooltip: s.tooltipPredefinedList,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: () => _showExportSheet(context, provider, s),
                        icon: const Icon(
                          Icons.share_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                        tooltip: s.tooltipExport,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: () =>
                            _showSaveListDialog(context, provider, s),
                        icon: const Icon(
                          Icons.bookmark_add_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                        tooltip: s.tooltipSaveList,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: () => _showSavedListsSheet(context),
                        icon: const Icon(
                          Icons.bookmarks_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                        tooltip: s.tooltipSavedLists,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          if (provider.itemCount == 0) return;
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(s.clearAllTitle),
                              content: Text(s.clearAllBody),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(s.btnCancel),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    provider.clearAll();
                                    Navigator.pop(context);
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                  ),
                                  child: Text(s.btnDelete),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFFF8A80),
                          size: 22,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Tab bar
              TabBar(
                controller: tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                indicatorColor: const Color(0xFFFF8A80),
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 13),
                tabs: [
                  Tab(text: s.tabGroceries),
                  Tab(text: s.tabNotepad),
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
    return Consumer2<GroceryListProvider, LanguageProvider>(
      builder: (context, provider, langProvider, _) {
        final items = provider.items;
        final s = AppStrings.of(langProvider);

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
                      s.itemCount(items.length),
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

            // Smart suggestions row
            _SmartSuggestionsRow(s: s),

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
                        s.emptyStateTitle,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.emptyStateSubtitle,
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
                onPressed: () => _showAddManualDialog(context, provider, s),
                icon: const Icon(
                  Icons.add_circle_outline,
                  size: 18,
                  color: Color(0xFF2D6A4F),
                ),
                label: Text(
                  s.btnAddItem,
                  style: const TextStyle(
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
    AppStrings s,
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
            title: Text(
              s.addItemTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: s.fieldName,
                    hintText: s.addItemHint,
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
                          labelText: s.fieldQuantity,
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
                child: Text(
                  s.btnCancel,
                  style: const TextStyle(color: Colors.grey),
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
                child: Text(s.btnAdd),
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
    // Add bottom padding equal to the navigation bar inset (gesture nav / button nav)
    // so the mic button is never obscured behind the system navigation bar.
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
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

void _showSaveListDialog(
  BuildContext context,
  GroceryListProvider provider,
  AppStrings s,
) {
  if (provider.itemCount == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.snackListEmpty),
        duration: const Duration(seconds: 2),
      ),
    );
    return;
  }
  final nameCtrl = TextEditingController(text: provider.listTitle);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        s.saveListTitle,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: TextField(
        controller: nameCtrl,
        autofocus: true,
        decoration: InputDecoration(
          labelText: s.saveListLabel,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: const Color(0xFFF5F5F0),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(s.btnCancel, style: const TextStyle(color: Colors.grey)),
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
                content: Text(s.listSaved(name)),
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
          child: Text(s.btnSave),
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
        ChangeNotifierProvider.value(value: context.read<LanguageProvider>()),
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

void _showExportSheet(
  BuildContext context,
  GroceryListProvider provider,
  AppStrings s,
) {
  if (provider.itemCount == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.snackListEmpty), duration: Duration(seconds: 2)),
    );
    return;
  }
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            Text(
              s.exportTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              s.exportSubtitle(provider.itemCount),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            _ExportOptionTile(
              icon: Icons.picture_as_pdf_outlined,
              title: s.exportPdfTitle,
              subtitle: s.exportPdfSubtitle,
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
              title: s.exportImageTitle,
              subtitle: s.exportImageSubtitle,
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
      );
    },
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

/// Displays a horizontal row of quick-add chips for the user's most frequently
/// bought items that are not already in the current list.
class _SmartSuggestionsRow extends StatelessWidget {
  final AppStrings s;

  const _SmartSuggestionsRow({required this.s});

  @override
  Widget build(BuildContext context) {
    return Consumer<GroceryListProvider>(
      builder: (context, provider, _) {
        final suggestions = provider.getSmartSuggestions(6);
        if (suggestions.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 13,
                    color: Color(0xFF2D6A4F),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    s.smartSuggestions,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2D6A4F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: suggestions.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        avatar: const Icon(
                          Icons.add,
                          size: 14,
                          color: Color(0xFF2D6A4F),
                        ),
                        label: Text(
                          _chipLabel(item),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          final qty =
                              double.tryParse(item['quantity'] ?? '1') ?? 1.0;
                          final unit = UnitLabel.fromLabel(item['unit']!);
                          provider.addItem(
                            GroceryItem(
                              name: item['name']!,
                              quantity: qty,
                              unit: unit,
                            ),
                          );
                        },
                        backgroundColor: const Color(0xFFD8EDD9),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _chipLabel(Map<String, String> item) {
    return item['name']!;
  }
}
