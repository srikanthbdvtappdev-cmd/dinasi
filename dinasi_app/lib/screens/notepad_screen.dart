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

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    // Register callbacks so the parent header can trigger save/delete.
    widget.controller?.save = _showSaveDialog;
    widget.controller?.delete = _showClearDialog;
    widget.controller?.showSavedNotes = _showSavedNotes;
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
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (_) => _onSpeechDone(),
      onStatus: (_) {}, // restart handled in onResult to avoid race condition
    );
    if (!_speechAvailable && mounted) {
      setState(() => _micState = _MicState.unavailable);
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final spoken = result.recognizedWords;
    if (!mounted) return;

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

    // finalResult = true arrives BEFORE onStatus:'done', so it's safe to
    // commit text here and restart — no race condition.
    if (result.finalResult && _micState == _MicState.listening) {
      _textBeforeListening = newText;
      _interimText = '';
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted || _micState != _MicState.listening) return;
        _speech.listen(
          onResult: _onSpeechResult,
          localeId: _listenLocaleId,
          listenOptions: SpeechListenOptions(
            listenMode: ListenMode.dictation,
            cancelOnError: false,
            partialResults: true,
          ),
        );
      });
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) return;
    final langProvider = context.read<LanguageProvider>();
    _listenLocaleId = langProvider.isKannada ? 'kn_IN' : 'en_US';

    // Capture existing text; we'll append spoken words after it
    _textBeforeListening = _textCtrl.text;
    _interimText = '';
    setState(() => _micState = _MicState.listening);
    _pulseCtrl.repeat(reverse: true);

    await _speech.listen(
      onResult: _onSpeechResult,
      localeId: _listenLocaleId,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      ),
    );
  }

  void _onSpeechDone() {
    if (!mounted || _micState != _MicState.listening) return;
    _micState =
        _MicState.ready; // set synchronously to block any delayed restarts
    _speech.stop();
    _pulseCtrl.stop();
    _pulseCtrl.reset();
    setState(() {
      _interimText = '';
    });
  }

  void _stopListening() => _onSpeechDone();

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

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    _pulseCtrl.dispose();
    _speech.cancel();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final s = AppStrings.of(langProvider);
    final isListening = _micState == _MicState.listening;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Column(
      children: [
        // ── Writing area ──────────────────────────────────────────────
        Expanded(
          child: Padding(
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            constraints.maxHeight - 28, // subtract 2×14 padding
                      ),
                      child: TextField(
                        controller: _textCtrl,
                        focusNode: _focusNode,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        onTapOutside: (_) => _focusNode.unfocus(),
                        style: const TextStyle(fontSize: 16, height: 1.6),
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
                );
              },
            ),
          ),
        ),

        // ── Voice footer — hidden while keyboard is open ──────────────
        if (keyboardInset == 0)
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
              ],
            ),
          ),
      ],
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
