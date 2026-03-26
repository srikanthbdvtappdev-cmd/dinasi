import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../providers/grocery_provider.dart';
import '../providers/language_provider.dart';
import '../providers/app_strings.dart';
import 'package:provider/provider.dart';

class VoiceMicButton extends StatefulWidget {
  const VoiceMicButton({super.key});

  @override
  State<VoiceMicButton> createState() => _VoiceMicButtonState();
}

enum _MicState { ready, listening, unavailable }

class _VoiceMicButtonState extends State<VoiceMicButton>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  _MicState _state = _MicState.ready;
  bool _available = false;
  String _spokenText = '';
  Timer? _silenceTimer;

  // 5s timeout if no speech starts; 3s timeout after speech pauses
  static const _initialSilence = Duration(seconds: 5);
  static const _postSpeechPause = Duration(seconds: 3);

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
      onError: (_) {
        _silenceTimer?.cancel();
        if (_state == _MicState.listening) {
          setState(() {
            _state = _MicState.ready;
            _pulseController.stop();
            _pulseController.reset();
          });
        }
      },
    );
    if (!_available) setState(() => _state = _MicState.unavailable);
  }

  void _resetSilenceTimer({bool hasSpeech = false}) {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(hasSpeech ? _postSpeechPause : _initialSilence, () {
      if (_state == _MicState.listening) _stopListening();
    });
  }

  Future<void> _startListening() async {
    if (!_available) {
      setState(() => _state = _MicState.unavailable);
      return;
    }
    setState(() {
      _state = _MicState.listening;
      _spokenText = '';
    });
    _pulseController.repeat(reverse: true);

    final localeId = context.read<LanguageProvider>().isKannada
        ? 'kn_IN'
        : 'en_US';

    // Start 5-second initial silence timer
    _resetSilenceTimer(hasSpeech: false);

    await _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords.trim();
        setState(() => _spokenText = words);

        if (words.isNotEmpty) {
          // Speech detected — reset to 3-second post-speech timer
          _resetSilenceTimer(hasSpeech: true);
        }

        if (result.finalResult && words.isNotEmpty) {
          _silenceTimer?.cancel();
          _stopListening();
        }
      },
      localeId: localeId,
      listenFor: const Duration(seconds: 60),
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      ),
    );
  }

  void _stopListening() {
    if (_state != _MicState.listening) return;
    _silenceTimer?.cancel();
    _state = _MicState.ready;
    _speech.stop();
    _pulseController.stop();
    _pulseController.reset();

    final text = _spokenText.trim();
    if (text.isNotEmpty) {
      final lang = context.read<LanguageProvider>().language;
      context.read<GroceryListProvider>().addItemsFromVoice(
        text,
        language: lang,
      );
      setState(() {
        _spokenText = '';
      });
    } else {
      setState(() {
        _spokenText = '';
      });
    }
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _pulseController.dispose();
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context.watch<LanguageProvider>());
    final isListening = _state == _MicState.listening;

    final String displayText;
    if (_state == _MicState.unavailable) {
      displayText = strings.micUnavailable;
    } else if (isListening) {
      displayText = _spokenText.isNotEmpty ? _spokenText : strings.micListening;
    } else {
      displayText = strings.micTapToSpeak;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status / recognized text
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isListening
                ? const Color(0xFF2D6A4F).withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            displayText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isListening
                  ? const Color(0xFF2D6A4F)
                  : Colors.grey.shade500,
              fontStyle: isListening ? FontStyle.normal : FontStyle.italic,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Mic button with pulse effect
        GestureDetector(
          onTap: isListening ? _stopListening : _startListening,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (isListening)
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
                      color: isListening
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
    );
  }
}
