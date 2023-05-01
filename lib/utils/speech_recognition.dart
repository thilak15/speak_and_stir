import 'package:speech_to_text/speech_to_text.dart' as stt;


class SpeechRecognition {
  final stt.SpeechToText _speech = stt.SpeechToText();
  Function? onListeningStopped;

  bool get isAvailable => _speech.isAvailable;
  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    bool result = await _speech.initialize(
      onError: (error) => print('Speech recognition error: $error'),
      onStatus: (status) => print('Speech recognition status: $status'),
    );

    if (!result) {
      throw Exception('Speech recognition initialization failed');
    }

    return result;
  }

  Future<void> listen({
  required Function(String) onResult,
  Function()? onCancelled,
}) async {
  if (!_speech.isListening) {
    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          if (onListeningStopped != null) {
            onListeningStopped!();
          }
        }
      },
      listenFor: Duration(seconds: 10),
      pauseFor: Duration(seconds: 5),
      partialResults: true,
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
      onDevice: true,
    );
  } else {
    onCancelled?.call();
    await _speech.stop();
  }
}


  Future<void> stop() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> cancel() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
  }
}
