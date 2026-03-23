import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/saved_lists_provider.dart';
import '../providers/grocery_provider.dart';
import '../providers/language_provider.dart';
import '../providers/app_strings.dart';
import '../models/saved_list.dart';

class SavedListsSheet extends StatelessWidget {
  const SavedListsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SavedListsProvider, LanguageProvider>(
      builder: (context, savedProvider, langProvider, _) {
        final lists = savedProvider.lists;
        final s = AppStrings.of(langProvider);
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bookmark_outlined,
                      color: Color(0xFF2D6A4F),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.savedListsTitle(lists.length).split(' (')[0],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      s.savedListsCount(lists.length),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    // Import button
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.upload_file_outlined,
                        color: Color(0xFF2D6A4F),
                        size: 22,
                      ),
                      tooltip: s.savedListsImportJson,
                      onPressed: () => _importList(context, savedProvider, s),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // List or empty state
              if (lists.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          size: 56,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          s.savedListsEmpty,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.savedListsEmptyHint,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: lists.length,
                    separatorBuilder: (ctx2, _) =>
                        const Divider(height: 1, indent: 20, endIndent: 20),
                    itemBuilder: (context, index) {
                      return _SavedListTile(
                        savedList: lists[index],
                        onRestore: () =>
                            _confirmRestore(context, lists[index], s),
                        onExport: () => _exportList(lists[index]),
                        onDelete: () => _confirmDelete(
                          context,
                          savedProvider,
                          lists[index],
                          s,
                        ),
                        strings: s,
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

  void _confirmRestore(
    BuildContext context,
    SavedList savedList,
    AppStrings s,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.savedListsRestoreTitle),
        content: Text(s.savedListsRestoreBody(savedList.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              s.btnCancel,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close sheet
              context.read<GroceryListProvider>().loadFromSaved(
                savedList.items,
                savedList.name,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2D6A4F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(s.savedListsRestoreBtn),
          ),
        ],
      ),
    );
  }

  // ── JSON export ────────────────────────────────────────────────────────

  Future<void> _exportList(SavedList savedList) async {
    final json = const JsonEncoder.withIndent('  ').convert(savedList.toJson());
    final dir = await getTemporaryDirectory();
    final safeName = savedList.name.replaceAll(RegExp(r'[^\w\s\-]'), '_');
    final file = File('${dir.path}/$safeName.dinasi.json');
    await file.writeAsString(json, flush: true);
    await Share.shareXFiles([
      XFile(
        file.path,
        mimeType: 'application/json',
        name: '$safeName.dinasi.json',
      ),
    ], subject: savedList.name);
  }

  // ── JSON import ────────────────────────────────────────────────────────

  Future<void> _importList(
    BuildContext context,
    SavedListsProvider provider,
    AppStrings s,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    final content = await File(path).readAsString();
    if (!context.mounted) return;
    final name = await provider.importFromJsonString(content);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          name != null
              ? s.savedListsImportSuccess(name)
              : s.savedListsImportFailed,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    SavedListsProvider provider,
    SavedList savedList,
    AppStrings s,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.savedListsDeleteTitle),
        content: Text(s.savedListsDeleteBody(savedList.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              s.btnCancel,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          FilledButton(
            onPressed: () {
              provider.deleteList(savedList.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(s.btnDelete),
          ),
        ],
      ),
    );
  }
}

class _SavedListTile extends StatelessWidget {
  final SavedList savedList;
  final VoidCallback onRestore;
  final VoidCallback onExport;
  final VoidCallback onDelete;
  final AppStrings strings;

  const _SavedListTile({
    required this.savedList,
    required this.onRestore,
    required this.onExport,
    required this.onDelete,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final date = _formatDate(savedList.savedAt, strings);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFD8EDD9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.bookmark, color: Color(0xFF2D6A4F), size: 20),
      ),
      title: Text(
        savedList.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        '$date · ${strings.itemCount(savedList.items.length)}',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onRestore,
            icon: const Icon(
              Icons.restore_outlined,
              color: Color(0xFF2D6A4F),
              size: 22,
            ),
            tooltip: strings.savedListsRestoreBtn,
          ),
          IconButton(
            onPressed: onExport,
            icon: const Icon(
              Icons.ios_share_outlined,
              color: Color(0xFF2D6A4F),
              size: 22,
            ),
            tooltip: strings.savedListsExportJson,
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 22,
            ),
            tooltip: strings.btnDelete,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt, AppStrings s) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return s.dateToday;
    if (diff.inDays == 1) return s.dateYesterday;
    if (diff.inDays < 7) return s.daysAgo(diff.inDays);
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
