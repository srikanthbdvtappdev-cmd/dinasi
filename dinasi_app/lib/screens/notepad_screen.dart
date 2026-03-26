import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../providers/language_provider.dart';
import '../providers/notepad_provider.dart';
import '../providers/app_strings.dart';
import '../models/note.dart';

/// Shared controller so the parent header can trigger notepad actions.
class NotepadController {
  VoidCallback? save;
  VoidCallback? delete;
  VoidCallback? showSavedNotes;
  VoidCallback? clearDrawing;
  VoidCallback? undoStroke;
  // Called on mode changes; carries the new isDrawMode value.
  void Function(bool isDrawMode)? onModeChanged;
}

class NotepadTabContent extends StatefulWidget {
  final NotepadController? controller;
  const NotepadTabContent({super.key, this.controller});

  @override
  State<NotepadTabContent> createState() => _NotepadTabContentState();
}

enum _MicState { ready, listening, unavailable }

class _NotepadTabContentState extends State<NotepadTabContent>
    with SingleTickerProviderStateMixin {
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final SpeechToText _speech = SpeechToText();

  _MicState _micState = _MicState.ready;
  bool _speechAvailable = false;
  String _interimText = '';
  String _textBeforeListening = '';
  String _listenLocaleId = 'en_US';
  Timer? _silenceTimer;
  Timer? _restartTimer;
  bool _pendingRestart = false;

  // ── Draw mode ─────────────────────────────────────────────────────────────
  bool _isDrawMode = false;
  Color _penColor = Colors.black;
  double _penWidth = 3.0;
  bool _isEraser = false;
  final List<_Stroke> _strokes = [];
  _Stroke? _currentStroke;

  static const _palette = [
    Colors.black,
    Color(0xFF2D6A4F), // green
    Colors.blue,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.brown,
  ];

  void _updatePen({Color? color, double? width, bool? eraser}) {
    setState(() {
      if (color != null) _penColor = color;
      if (width != null) _penWidth = width;
      if (eraser != null) _isEraser = eraser;
    });
  }

  void _undoStroke() {
    setState(() {
      if (_strokes.isNotEmpty) _strokes.removeLast();
    });
    _saveDraftStrokes();
  }

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    // Register callbacks so the parent header can trigger save/delete/draw.
    widget.controller?.save = _showSaveDialog;
    widget.controller?.delete = _isDrawMode
        ? _showClearDrawingDialog
        : _showClearDialog;
    widget.controller?.showSavedNotes = _showSavedNotes;
    widget.controller?.clearDrawing = _showClearDrawingDialog;
    widget.controller?.undoStroke = _undoStroke;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.25,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _textCtrl.addListener(_onDraftTextChanged);
    // Restore persisted draft after first frame so context is available.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDraft());
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (e) {
        _onSpeechDone();
      },
      onStatus: (status) {
        if (!mounted || _micState != _MicState.listening) return;
        if ((status == 'done' || status == 'notListening') && _pendingRestart) {
          _pendingRestart = false;
          _restartTimer?.cancel();
          _doListen();
        }
      },
    );
    if (!_speechAvailable && mounted) {
      setState(() => _micState = _MicState.unavailable);
    }
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 30), () {
      if (_micState == _MicState.listening) _onSpeechDone();
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final spoken = result.recognizedWords;
    if (!mounted) return;

    if (spoken.isNotEmpty) {
      _resetSilenceTimer();
      final sep =
          _textBeforeListening.isEmpty ||
              _textBeforeListening.endsWith('\n') ||
              _textBeforeListening.endsWith(' ')
          ? ''
          : ' ';
      final newText = _textBeforeListening + sep + spoken;
      setState(() {
        _interimText = spoken;
        _textCtrl.text = newText;
        _textCtrl.selection = TextSelection.collapsed(offset: newText.length);
      });
      if (result.finalResult && _micState == _MicState.listening) {
        _textBeforeListening = newText;
        setState(() => _interimText = '');
        _scheduleRestart();
      }
    } else if (result.finalResult && _micState == _MicState.listening) {
      _scheduleRestart();
    }
  }

  void _scheduleRestart() {
    _pendingRestart = true;
    // Fallback: if onStatus:'done' never fires (some devices), restart after 600ms
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 600), () {
      if (_pendingRestart && _micState == _MicState.listening) {
        _pendingRestart = false;
        _doListen();
      }
    });
  }

  void _doListen() {
    if (!mounted || _micState != _MicState.listening) return;
    _speech.listen(
      onResult: _onSpeechResult,
      localeId: _listenLocaleId,
      listenFor: const Duration(minutes: 5),
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      ),
    );
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) return;
    final langProvider = context.read<LanguageProvider>();
    _listenLocaleId = langProvider.isKannada ? 'kn_IN' : 'en_US';

    // Capture existing text; we'll append spoken words after it
    _textBeforeListening = _textCtrl.text;
    _interimText = '';
    _pendingRestart = false;
    _restartTimer?.cancel();
    setState(() => _micState = _MicState.listening);
    _pulseCtrl.repeat(reverse: true);
    _resetSilenceTimer();

    await _speech.listen(
      onResult: _onSpeechResult,
      localeId: _listenLocaleId,
      listenFor: const Duration(minutes: 5),
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      ),
    );
  }

  void _onSpeechDone() {
    if (!mounted || _micState != _MicState.listening) return;
    _silenceTimer?.cancel();
    _restartTimer?.cancel();
    _pendingRestart = false;
    _micState = _MicState.ready;
    _speech.stop();
    _pulseCtrl.stop();
    _pulseCtrl.reset();
    setState(() {
      _interimText = '';
    });
  }

  void _stopListening() => _onSpeechDone();

  void _insertNewLine() {
    final newText = _textCtrl.text + '\n';
    _textCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    _textBeforeListening = newText;
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  void _showSaveDialog() {
    final content = _textCtrl.text.trim();
    final s = AppStrings.of(context.read<LanguageProvider>());
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.notepadEmptySnack),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    final firstLine = content.split('\n').first.trim();
    final autoTitle = firstLine.length > 40
        ? firstLine.substring(0, 40)
        : firstLine;
    final titleCtrl = TextEditingController(text: autoTitle);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.notepadSaveTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: titleCtrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: s.notepadTitleLabel,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: const Color(0xFFF5F5F0),
          ),
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
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2D6A4F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final title = titleCtrl.text.trim().isEmpty
                  ? autoTitle
                  : titleCtrl.text.trim();
              context.read<NotepadProvider>().saveNote(title, content);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(s.notepadSaved(title)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(s.btnSave),
          ),
        ],
      ),
    );
  }

  // ── Clear ─────────────────────────────────────────────────────────────────

  void _showClearDialog() {
    if (_textCtrl.text.isEmpty) return;
    final s = AppStrings.of(context.read<LanguageProvider>());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.notepadClearTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(s.notepadClearBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.btnCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              _textCtrl.clear();
              Navigator.pop(ctx);
            },
            child: Text(s.btnDelete),
          ),
        ],
      ),
    );
  }

  // ── Saved notes sheet ─────────────────────────────────────────────────────

  void _showSavedNotes() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<NotepadProvider>(),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (ctx, scrollCtrl) => _SavedNotesSheet(
            scrollController: scrollCtrl,
            langProvider: context.read<LanguageProvider>(),
            onLoad: (note) {
              _textCtrl.text = note.content;
              _textCtrl.selection = TextSelection.collapsed(
                offset: note.content.length,
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Clear drawing ─────────────────────────────────────────────────────────

  void _showClearDrawingDialog() {
    if (_strokes.isEmpty) return;
    final s = AppStrings.of(context.read<LanguageProvider>());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.notepadClearDrawingTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(s.notepadClearDrawingBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.btnCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              setState(() {
                _strokes.clear();
                _currentStroke = null;
              });
              _saveDraftStrokes();
              Navigator.pop(ctx);
            },
            child: Text(s.btnDelete),
          ),
        ],
      ),
    );
  }

  // ── Draft persistence ─────────────────────────────────────────────────────

  void _onDraftTextChanged() {
    if (!mounted) return;
    context.read<NotepadProvider>().saveDraftText(_textCtrl.text);
  }

  void _saveDraftStrokes() {
    if (!mounted) return;
    final data = _strokes
        .map(
          (s) => {
            'color': s.color.toARGB32(),
            'width': s.width,
            'isEraser': s.isEraser,
            'points': s.points.map((p) => [p.dx, p.dy]).toList(),
          },
        )
        .toList();
    context.read<NotepadProvider>().saveDraftStrokes(
      data.cast<Map<String, dynamic>>(),
    );
  }

  void _loadDraft() {
    if (!mounted) return;
    final provider = context.read<NotepadProvider>();
    // Restore text
    if (provider.draftText.isNotEmpty) {
      _textCtrl.removeListener(_onDraftTextChanged);
      _textCtrl.text = provider.draftText;
      _textCtrl.selection = TextSelection.collapsed(
        offset: provider.draftText.length,
      );
      _textCtrl.addListener(_onDraftTextChanged);
    }
    // Restore strokes
    if (provider.draftStrokes.isNotEmpty) {
      for (final strokeData in provider.draftStrokes) {
        final stroke = _Stroke(
          color: Color(strokeData['color'] as int),
          width: (strokeData['width'] as num).toDouble(),
          isEraser: strokeData['isEraser'] as bool,
        );
        final pointsList = strokeData['points'] as List;
        for (final p in pointsList) {
          stroke.points.add(
            Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()),
          );
        }
        _strokes.add(stroke);
      }
      if (mounted) setState(() {});
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _restartTimer?.cancel();
    _textCtrl.removeListener(_onDraftTextChanged);
    _textCtrl.dispose();
    _focusNode.dispose();
    _pulseCtrl.dispose();
    _speech.cancel();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  void _switchMode(bool drawMode) {
    // Stop mic if switching away from text mode
    if (drawMode && _micState == _MicState.listening) _stopListening();
    // Dismiss keyboard when switching to draw mode
    if (drawMode) _focusNode.unfocus();
    setState(() => _isDrawMode = drawMode);
    // Keep header delete button wired to the right action
    widget.controller?.delete = drawMode
        ? _showClearDrawingDialog
        : _showClearDialog;
    widget.controller?.onModeChanged?.call(drawMode);
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final s = AppStrings.of(langProvider);
    final isListening = _micState == _MicState.listening;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Column(
      children: [
        // ── Mode toggle bar ───────────────────────────────────────────
        Container(
          color: const Color(0xFFF5F5EE),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Row(
            children: [
              _ModeToggle(
                isDrawMode: _isDrawMode,
                textLabel: s.notepadTextMode,
                drawLabel: s.notepadDrawMode,
                onChanged: _switchMode,
              ),
              const Spacer(),
              // Draw-mode toolbar
              if (_isDrawMode) ...[
                // Undo
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.undo, size: 22),
                  onPressed: _undoStroke,
                  tooltip: s.notepadUndoStroke,
                ),
                const SizedBox(width: 4),
                // Eraser toggle
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    _isEraser ? Icons.edit : Icons.auto_fix_normal,
                    size: 22,
                    color: _isEraser ? Colors.grey : const Color(0xFF2D6A4F),
                  ),
                  tooltip: _isEraser ? 'Pen' : 'Eraser',
                  onPressed: () => _updatePen(eraser: !_isEraser),
                ),
                const SizedBox(width: 4),
                // Stroke width slider
                SizedBox(
                  width: 64,
                  child: Slider(
                    value: _penWidth,
                    min: 1.0,
                    max: 12.0,
                    divisions: 11,
                    activeColor: const Color(0xFF2D6A4F),
                    onChanged: _isEraser ? null : (v) => _updatePen(width: v),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Color palette (draw mode only)
        if (_isDrawMode)
          Container(
            color: const Color(0xFFF5F5EE),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              children: _palette.map((color) {
                final isSelected = !_isEraser && _penColor == color;
                return GestureDetector(
                  onTap: () => _updatePen(color: color, eraser: false),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Colors.black87
                            : Colors.grey.shade300,
                        width: isSelected ? 2.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        // ── Writing area or drawing canvas ────────────────────────────
        Expanded(
          child: _isDrawMode
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Colors.white,
                      child: GestureDetector(
                        onPanStart: (details) {
                          final stroke = _Stroke(
                            color: _penColor,
                            width: _isEraser ? 20.0 : _penWidth,
                            isEraser: _isEraser,
                          );
                          stroke.points.add(details.localPosition);
                          setState(() => _currentStroke = stroke);
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            _currentStroke?.points.add(details.localPosition);
                          });
                        },
                        onPanEnd: (_) {
                          setState(() {
                            if (_currentStroke != null) {
                              _strokes.add(_currentStroke!);
                              _currentStroke = null;
                            }
                          });
                          _saveDraftStrokes();
                        },
                        child: CustomPaint(
                          painter: _DrawingPainter(_strokes, _currentStroke),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: _focusNode.hasFocus
                                ? const Color(0xFF2D6A4F)
                                : Colors.grey.shade300,
                            width: _focusNode.hasFocus ? 1.5 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(14),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight:
                                    constraints.maxHeight -
                                    28, // subtract 2×14 padding
                              ),
                              child: TextField(
                                controller: _textCtrl,
                                focusNode: _focusNode,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                onTapOutside: (_) => _focusNode.unfocus(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.6,
                                ),
                                decoration: InputDecoration(
                                  hintText: s.notepadHint,
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 15,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),

        // ── Voice footer — hidden in draw mode or while keyboard is open ──
        if (!_isDrawMode && keyboardInset == 0)
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5EE),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isListening
                        ? const Color(0xFF2D6A4F).withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isListening && _interimText.isNotEmpty
                        ? _interimText
                        : (isListening
                              ? s.micListening
                              : (_micState == _MicState.unavailable
                                    ? s.micUnavailable
                                    : s.micTapToSpeak)),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: isListening
                          ? const Color(0xFF2D6A4F)
                          : Colors.grey.shade500,
                      fontStyle: isListening
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: isListening ? _stopListening : _startListening,
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isListening)
                            Container(
                              width: 72 * _pulseAnim.value,
                              height: 72 * _pulseAnim.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(
                                  0xFF2D6A4F,
                                ).withValues(alpha: 0.15),
                              ),
                            ),
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _micState == _MicState.unavailable
                                  ? Colors.grey.shade400
                                  : (isListening
                                        ? const Color(0xFF1B4332)
                                        : const Color(0xFF2D6A4F)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF2D6A4F,
                                  ).withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              isListening ? Icons.stop : Icons.mic,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (isListening) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _insertNewLine,
                    icon: const Icon(Icons.keyboard_return, size: 18),
                    label: const Text('New Line'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2D6A4F),
                    ),
                  ),
                ],
              ],
            ),
          ),

        // Push content above keyboard when open
        SizedBox(height: keyboardInset),
      ],
    );
  }
}

// ── Drawing data ──────────────────────────────────────────────────────────

class _Stroke {
  _Stroke({required this.color, required this.width, required this.isEraser})
    : points = [];
  final List<Offset> points;
  final Color color;
  final double width;
  final bool isEraser;
}

class _DrawingPainter extends CustomPainter {
  final List<_Stroke> strokes;
  final _Stroke? currentStroke;

  _DrawingPainter(this.strokes, this.currentStroke);

  @override
  void paint(Canvas canvas, Size size) {
    final all = [...strokes, if (currentStroke != null) currentStroke!];
    for (final stroke in all) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.isEraser ? Colors.white : stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_DrawingPainter old) => true;
}

// ── Mode toggle widget ─────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  final bool isDrawMode;
  final String textLabel;
  final String drawLabel;
  final void Function(bool isDrawMode) onChanged;

  const _ModeToggle({
    required this.isDrawMode,
    required this.textLabel,
    required this.drawLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tab(
            label: textLabel,
            icon: Icons.text_fields,
            selected: !isDrawMode,
            onTap: () => onChanged(false),
          ),
          _Tab(
            label: drawLabel,
            icon: Icons.brush_outlined,
            selected: isDrawMode,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? const Color(0xFF2D6A4F) : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected
                    ? const Color(0xFF2D6A4F)
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Saved notes bottom sheet ───────────────────────────────────────────────

class _SavedNotesSheet extends StatelessWidget {
  final ScrollController scrollController;
  final LanguageProvider langProvider;
  final void Function(Note note) onLoad;

  const _SavedNotesSheet({
    required this.scrollController,
    required this.langProvider,
    required this.onLoad,
  });

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NotepadProvider>().notes;
    final s = AppStrings.of(langProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5EE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Sheet title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.notes, color: Color(0xFF2D6A4F), size: 20),
                const SizedBox(width: 8),
                Text(
                  s.notepadSavedTitle(notes.length),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D6A4F),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Notes list or empty state
          if (notes.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_note,
                      size: 56,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.notepadNoNotes,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: notes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (ctx, i) {
                  final note = notes[i];
                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      title: Text(
                        note.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            note.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(note.createdAt, s),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.download_outlined, size: 20),
                            color: const Color(0xFF2D6A4F),
                            tooltip: s.notepadLoadTooltip,
                            onPressed: () {
                              Navigator.pop(ctx);
                              onLoad(note);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            color: Colors.redAccent,
                            tooltip: s.notepadDeleteTooltip,
                            onPressed: () =>
                                ctx.read<NotepadProvider>().deleteNote(note.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt, AppStrings s) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${s.dateToday} $h:$m';
    }
    if (diff.inDays == 1) return s.dateYesterday;
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
