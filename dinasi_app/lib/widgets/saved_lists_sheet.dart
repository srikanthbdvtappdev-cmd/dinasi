import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/saved_lists_provider.dart';
import '../providers/grocery_provider.dart';
import '../models/saved_list.dart';

class SavedListsSheet extends StatelessWidget {
  const SavedListsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SavedListsProvider>(
      builder: (context, savedProvider, _) {
        final lists = savedProvider.lists;
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bookmark_outlined,
                      color: Color(0xFF2D6A4F),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'ಉಳಿಸಿದ ಪಟ್ಟಿಗಳು',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${lists.length} ಪಟ್ಟಿ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
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
                          'ಯಾವುದೇ ಪಟ್ಟಿ ಉಳಿಸಿಲ್ಲ',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ಪಟ್ಟಿ ತಯಾರಿಸಿ ಮತ್ತು ಉಳಿಸಿ ಬಟನ್ ಒತ್ತಿ',
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
                        onRestore: () => _confirmRestore(context, lists[index]),
                        onDelete: () => _confirmDelete(
                          context,
                          savedProvider,
                          lists[index],
                        ),
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

  void _confirmRestore(BuildContext context, SavedList savedList) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ಪಟ್ಟಿ ತರೋಣವೇ?'),
        content: Text('"${savedList.name}" ಪಟ್ಟಿ ತಂದರೆ ಈಗಿನ ಪಟ್ಟಿ ಅಳಿಯುತ್ತದೆ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ರದ್ದು', style: TextStyle(color: Colors.grey)),
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
            child: const Text('ತರಿಸಿ'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    SavedListsProvider provider,
    SavedList savedList,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ಅಳಿಸಬೇಕೇ?'),
        content: Text('"${savedList.name}" ಪಟ್ಟಿ ಶಾಶ್ವತವಾಗಿ ಅಳಿಯುತ್ತದೆ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ರದ್ದು', style: TextStyle(color: Colors.grey)),
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
            child: const Text('ಅಳಿಸಿ'),
          ),
        ],
      ),
    );
  }
}

class _SavedListTile extends StatelessWidget {
  final SavedList savedList;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _SavedListTile({
    required this.savedList,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final date = _formatDate(savedList.savedAt);
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
        '$date · ${savedList.items.length} ವಸ್ತುಗಳು',
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
            tooltip: 'ತರಿಸಿ',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 22,
            ),
            tooltip: 'ಅಳಿಸಿ',
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'ಇಂದು';
    if (diff.inDays == 1) return 'ನಿನ್ನೆ';
    if (diff.inDays < 7) return '${diff.inDays} ದಿನಗಳ ಹಿಂದೆ';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
