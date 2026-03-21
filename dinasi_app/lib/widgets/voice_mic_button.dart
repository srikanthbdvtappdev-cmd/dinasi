import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../providers/grocery_provider.dart';
import 'package:provider/provider.dart';

class VoiceMicButton extends StatefulWidget {
  const VoiceMicButton({super.key});

  @override
  State<VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends State<VoiceMicButton>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _available = false;
  String _spokenText = '';
  String _statusText = 'Tap mic to speak';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _available = await _speech.initialize(
      onError: (err) {
        setState(() {
          _isListening = false;
          _statusText = 'Error: ${err.errorMsg}';
          _pulseController.stop();
          _pulseController.reset();
        });
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (_isListening) _stopListening();
        }
      },
    );
    setState(() {});
  }

  Future<void> _startListening() async {
    if (!_available) {
      setState(() => _statusText = 'Speech recognition unavailable');
      return;
    }
    setState(() {
      _isListening = true;
      _spokenText = '';
      _statusText = 'ಕೇಳುತ್ತಿದ್ದೇನೆ...';
    });
    _pulseController.repeat(reverse: true);

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _spokenText = result.recognizedWords;
          _statusText = _spokenText.isNotEmpty
              ? _spokenText
              : 'ಕೇಳುತ್ತಿದ್ದೇನೆ...';
        });
      },
      localeId: 'kn_IN',
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      ),
    );
  }

  void _stopListening() {
    _speech.stop();
    _pulseController.stop();
    _pulseController.reset();

    final text = _spokenText.trim();
    if (text.isNotEmpty) {
      context.read<GroceryListProvider>().addItemsFromVoice(text);
    }

    setState(() {
      _isListening = false;
      _spokenText = '';
      _statusText = 'Tap mic to speak';
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status / recognized text
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: _isListening
                ? const Color(0xFF2D6A4F).withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _statusText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _isListening
                  ? const Color(0xFF2D6A4F)
                  : Colors.grey.shade500,
              fontStyle: _isListening ? FontStyle.normal : FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Mic button with pulse effect
        GestureDetector(
          onTap: _isListening ? _stopListening : _startListening,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (_isListening)
                    Container(
                      width: 72 * _pulseAnimation.value,
                      height: 72 * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2D6A4F).withValues(alpha: 0.15),
                      ),
                    ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? const Color(0xFF1B4332)
                          : const Color(0xFF2D6A4F),
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
                      _isListening ? Icons.stop : Icons.mic,
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
    );
  }
}
