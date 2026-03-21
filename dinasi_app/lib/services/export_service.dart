import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/grocery_item.dart';

class ExportService {
  /// Renders an export widget off-screen via the Overlay and captures it as PNG.
  static Future<Uint8List> _captureToImage(
    BuildContext context,
    List<GroceryItem> items,
    String title,
  ) async {
    final key = GlobalKey();
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -5000,
        top: 0,
        width: 420,
        child: Material(
          color: Colors.transparent,
          child: RepaintBoundary(
            key: key,
            child: _ExportWidget(items: items, title: title),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    // Allow a full paint cycle
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } finally {
      entry.remove();
    }
  }

  /// Embeds the captured PNG into a PDF and opens the OS share/print dialog.
  static Future<void> exportAsPdf(
    BuildContext context,
    List<GroceryItem> items,
    String title,
  ) async {
    final pngBytes = await _captureToImage(context, items, title);
    final doc = pw.Document();
    final image = pw.MemoryImage(pngBytes);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Center(
          child: pw.Image(image, fit: pw.BoxFit.contain),
        ),
      ),
    );
    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: 'dinasi_$title.pdf');
  }

  /// Captures the list as PNG and shares it directly.
  static Future<void> exportAsImage(
    BuildContext context,
    List<GroceryItem> items,
    String title,
  ) async {
    final pngBytes = await _captureToImage(context, items, title);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/dinasi_list.png');
    await file.writeAsBytes(pngBytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      subject: 'ದಿನಸಿ - $title',
    );
  }
}

// -- Flutter widget rendered off-screen for export --

class _ExportWidget extends StatelessWidget {
  final List<GroceryItem> items;
  final String title;

  const _ExportWidget({required this.items, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D6A4F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ದಿನಸಿ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D6A4F),
                    ),
                  ),
                  Text(
                    '${items.length} ವಸ್ತುಗಳು',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFF2D6A4F), thickness: 1.5),
          const SizedBox(height: 4),
          _RowWidget(
            index: '#',
            name: 'ವಸ್ತು',
            qty: 'ಪ್ರಮಾಣ',
            isHeader: true,
          ),
          ...items.asMap().entries.map(
            (e) => _RowWidget(
              index: '${e.key + 1}',
              name: e.value.name,
              qty: _fmtQty(e.value.quantity, e.value.unit.label),
              isHeader: false,
              isEven: e.key.isEven,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'ದಿನಸಿ App',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtQty(double qty, String unit) {
    final q = qty == qty.roundToDouble()
        ? qty.toInt().toString()
        : qty.toString();
    return '$q $unit';
  }
}

class _RowWidget extends StatelessWidget {
  final String index;
  final String name;
  final String qty;
  final bool isHeader;
  final bool isEven;

  const _RowWidget({
    required this.index,
    required this.name,
    required this.qty,
    required this.isHeader,
    this.isEven = true,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isHeader
        ? const Color(0xFFD8EDD9)
        : (isEven ? Colors.white : const Color(0xFFF5F9F5));
    final style = TextStyle(
      fontSize: 13,
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      color: isHeader ? const Color(0xFF2D6A4F) : const Color(0xFF1A1A1A),
    );
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(index, textAlign: TextAlign.right, style: style),
          ),
          const SizedBox(width: 10),
          Expanded(flex: 3, child: Text(name, style: style)),
          Expanded(flex: 2, child: Text(qty, style: style)),
          SizedBox(
            width: 24,
            child: isHeader
                ? Text('✓', style: style, textAlign: TextAlign.center)
                : Center(
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade400,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}