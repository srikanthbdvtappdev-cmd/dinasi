import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/grocery_item.dart';
import '../providers/grocery_provider.dart';
import '../providers/language_provider.dart';
import '../providers/app_strings.dart';
import '../providers/predefined_items_provider.dart';
import 'package:provider/provider.dart';

class PredefinedItemsSheet extends StatefulWidget {
  const PredefinedItemsSheet({super.key});

  @override
  State<PredefinedItemsSheet> createState() => _PredefinedItemsSheetState();
}

class _PredefinedItemsSheetState extends State<PredefinedItemsSheet>
    with SingleTickerProviderStateMixin {
  String _query = '';
  final _searchController = TextEditingController();
  late TabController _tabController;
  bool _selectMode = false;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      if (!_selectMode) _selected.clear();
    });
  }

  void _toggleItem(String kannadaKey) {
    setState(() {
      if (_selected.contains(kannadaKey)) {
        _selected.remove(kannadaKey);
      } else {
        _selected.add(kannadaKey);
      }
    });
  }

  Future<void> _exportSelected(BuildContext context) async {
    final provider = context.read<PredefinedItemsProvider>();
    final items = provider.all
        .where((i) => _selected.contains(i['kannada']))
        .map(
          (i) => {
            'kannada': i['kannada'],
            'english': i['english'],
            'unit': i['unit'],
            if (i.containsKey('category')) 'category': i['category'],
          },
        )
        .toList();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(items);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/dinasi_items_export.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles([
      XFile(file.path, mimeType: 'application/json'),
    ], subject: 'ದಿನಸಿ – Items Export');
  }

  Future<void> _importJson(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    final String content;
    if (picked.bytes != null) {
      content = utf8.decode(picked.bytes!);
    } else if (picked.path != null) {
      content = await File(picked.path!).readAsString();
    } else {
      return;
    }
    dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid JSON file'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    if (decoded is! List) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid format: expected a JSON array'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    final items = <Map<String, String>>[];
    for (final e in decoded) {
      if (e is Map) {
        items.add(
          Map<String, String>.from(
            e.map((k, v) => MapEntry(k.toString(), v.toString())),
          ),
        );
      }
    }
    if (!context.mounted) return;
    final added = context.read<PredefinedItemsProvider>().importItems(items);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added == 0
              ? 'No new items added (all duplicates)'
              : 'Added $added item${added == 1 ? '' : 's'} from JSON',
        ),
        backgroundColor: added == 0 ? Colors.orange : const Color(0xFF2D6A4F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAddCustomDialog(BuildContext context, AppStrings s) {
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
          title: Text(
            s.predefinedAddDialogTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: kannadaCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: s.predefinedKannadaLabel,
                  hintText: s.predefinedKannadaHint,
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
                  labelText: s.predefinedEnglishLabel,
                  hintText: s.predefinedEnglishHint,
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
              child: Text(
                s.btnCancel,
                style: const TextStyle(color: Colors.grey),
              ),
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
                      content: Text(s.predefinedDuplicate),
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
                        s.predefinedAddedToList(kannadaCtrl.text.trim()),
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
              child: Text(s.btnAdd),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMedicineDialog(BuildContext context, AppStrings s) {
    final nameCtrl = TextEditingController();
    Unit selectedUnit = Unit.pcs;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add Medicine',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Medicine name *',
                  hintText: 'e.g. Metformin 500mg',
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
              child: Text(
                s.btnCancel,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final added = context
                    .read<PredefinedItemsProvider>()
                    .addCustomItem(
                      name,
                      name,
                      selectedUnit.label,
                      category: 'Medicines',
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      added
                          ? 'Added "$name" to medicines'
                          : s.predefinedDuplicate,
                    ),
                    backgroundColor: added
                        ? const Color(0xFF2D6A4F)
                        : Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PredefinedItemsProvider, LanguageProvider>(
      builder: (context, provider, langProvider, _) {
        final s = AppStrings.of(langProvider);

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
                    Flexible(
                      child: Text(
                        s.predefinedSheetTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    // Contextual add button — hidden while in select mode
                    if (!_selectMode)
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (_, __) {
                          final isMedTab = _tabController.index == 1;
                          return IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            tooltip: isMedTab
                                ? 'Add Medicine'
                                : s.predefinedAddNew,
                            onPressed: () => isMedTab
                                ? _showAddMedicineDialog(context, s)
                                : _showAddCustomDialog(context, s),
                            icon: const Icon(
                              Icons.add_circle,
                              size: 22,
                              color: Color(0xFF2D6A4F),
                            ),
                          );
                        },
                      ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.upload_file_outlined),
                      tooltip: 'Import JSON',
                      color: const Color(0xFF2D6A4F),
                      onPressed: () => _importJson(context),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        _selectMode
                            ? Icons.cancel_outlined
                            : Icons.checklist_outlined,
                      ),
                      tooltip: _selectMode
                          ? 'Cancel selection'
                          : 'Select items',
                      color: _selectMode
                          ? Colors.redAccent
                          : const Color(0xFF2D6A4F),
                      onPressed: _toggleSelectMode,
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: s.predefinedSearchHint,
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
              // Tab bar
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF2D6A4F),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF2D6A4F),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Groceries'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.medication_outlined, size: 15),
                        SizedBox(width: 4),
                        Text('Medicines'),
                      ],
                    ),
                  ),
                ],
              ),
              // Tab bodies
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ── Groceries tab ──────────────────────────────────
                    _buildItemList(
                      context: context,
                      provider: provider,
                      s: s,
                      items: provider.searchGroceries(_query),
                      isEnglish: langProvider.isEnglish,
                      alwaysEnglish: false,
                      onAddNew: () => _showAddCustomDialog(context, s),
                    ),
                    // ── Medicines tab ──────────────────────────────────
                    _buildItemList(
                      context: context,
                      provider: provider,
                      s: s,
                      items: provider.searchMedicines(_query),
                      isEnglish: true,
                      alwaysEnglish: true,
                      onAddNew: () => _showAddMedicineDialog(context, s),
                    ),
                  ],
                ),
              ),
              // ── Export bottom bar (visible in select mode) ─────────
              if (_selectMode)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        _selected.isEmpty
                            ? 'Tap items to select'
                            : '${_selected.length} selected',
                        style: TextStyle(
                          color: _selected.isEmpty
                              ? Colors.grey
                              : const Color(0xFF2D6A4F),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      if (_selected.isNotEmpty)
                        FilledButton.icon(
                          onPressed: () => _exportSelected(context),
                          icon: const Icon(Icons.ios_share_outlined, size: 16),
                          label: Text('Export (${_selected.length})'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2D6A4F),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
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

  Widget _buildItemList({
    required BuildContext context,
    required PredefinedItemsProvider provider,
    required AppStrings s,
    required List<Map<String, String>> items,
    required bool isEnglish,
    required bool alwaysEnglish,
    required VoidCallback onAddNew,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              s.predefinedNoResults,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onAddNew,
              icon: const Icon(Icons.add, color: Color(0xFF2D6A4F)),
              label: Text(
                s.predefinedAddNewItem,
                style: const TextStyle(color: Color(0xFF2D6A4F)),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final data = items[index];
        final kannadaKey = data['kannada']!;
        final inCart = context.watch<GroceryListProvider>().items.any(
          (i) => i.name == data['kannada'] || i.name == data['english'],
        );
        return _ItemRow(
          data: data,
          isCustom: provider.isCustom(data),
          isInCart: inCart,
          strings: s,
          isEnglish: alwaysEnglish || isEnglish,
          alwaysEnglish: alwaysEnglish,
          selectMode: _selectMode,
          isSelected: _selected.contains(kannadaKey),
          onSelectToggle: () => _toggleItem(kannadaKey),
        );
      },
    );
  }
}

class _ItemRow extends StatelessWidget {
  final Map<String, String> data;
  final bool isCustom;
  final bool isInCart;
  final AppStrings strings;
  final bool isEnglish;
  final bool alwaysEnglish;
  final bool selectMode;
  final bool isSelected;
  final VoidCallback? onSelectToggle;

  const _ItemRow({
    required this.data,
    required this.isCustom,
    required this.isInCart,
    required this.strings,
    required this.isEnglish,
    this.alwaysEnglish = false,
    this.selectMode = false,
    this.isSelected = false,
    this.onSelectToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: selectMode ? onSelectToggle : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2D6A4F).withValues(alpha: 0.12)
              : isInCart
              ? const Color(0xFF2D6A4F).withValues(alpha: 0.07)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 2,
          ),
          leading: selectMode
              ? Checkbox(
                  value: isSelected,
                  onChanged: (_) => onSelectToggle?.call(),
                  activeColor: const Color(0xFF2D6A4F),
                  visualDensity: VisualDensity.compact,
                )
              : null,
          title: Row(
            children: [
              Flexible(
                child: Text(
                  isEnglish ? data['english']! : data['kannada']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF2D6A4F)
                        : isInCart
                        ? const Color(0xFF2D6A4F)
                        : const Color(0xFF1A1A1A),
                  ),
                ),
              ),
              if (!selectMode && isInCart) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D6A4F),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, size: 10, color: Colors.white),
                      const SizedBox(width: 2),
                      Text(
                        strings.predefinedInCart,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (!selectMode && isCustom) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
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
          subtitle: alwaysEnglish
              ? null
              : Text(
                  isEnglish ? data['kannada']! : data['english']!,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
          trailing: selectMode
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.tonal(
                      onPressed: () {
                        final displayName = isEnglish
                            ? data['english']!
                            : data['kannada']!;
                        context.read<GroceryListProvider>().addPredefinedItem(
                          displayName,
                          data['unit'] ?? 'pcs',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              strings.predefinedAddedItem(
                                isEnglish ? data['english']! : data['kannada']!,
                              ),
                            ),
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
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isInCart)
                            const Icon(Icons.add, size: 14)
                          else
                            Text(
                              strings.predefinedBtnAddAnother,
                              style: const TextStyle(fontSize: 11),
                            ),
                          if (isInCart)
                            Text(
                              strings.predefinedBtnAddMore,
                              style: const TextStyle(fontSize: 11),
                            ),
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
                        tooltip: strings.predefinedDeleteTooltip,
                        onPressed: () {
                          context
                              .read<PredefinedItemsProvider>()
                              .removeCustomItem(data);
                        },
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
