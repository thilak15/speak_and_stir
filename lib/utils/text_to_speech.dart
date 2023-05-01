import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeech {
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
  }
  Future<void> pauseFor(Duration duration) async {
  await _flutterTts.awaitSpeakCompletion(true);
  await Future.delayed(duration);
}
}

