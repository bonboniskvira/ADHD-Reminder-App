import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();

  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speechToText.initialize();
    return _isInitialized;
  }

  bool get isListening => _speechToText.isListening;

  Future<void> startListening({
    required void Function(String words, bool isFinal) onResult,
    String? localeId,
  }) async {
    final ok = await initialize();
    if (!ok) {
      throw SpeechServiceException('Speech recognition is not available.');
    }

    await _speechToText.listen(
      onResult: (result) => onResult(result.recognizedWords, result.finalResult),
      localeId: localeId,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  Future<void> cancelListening() async {
    await _speechToText.cancel();
  }
}

class SpeechServiceException implements Exception {
  SpeechServiceException(this.message);

  final String message;

  @override
  String toString() => 'SpeechServiceException: $message';
}
