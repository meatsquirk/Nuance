import 'package:paint_color_assistant/a11y/speech.dart';

/// A recording [Speech] for the acceptance suite.
///
/// Stands in for the platform text-to-speech sink (D-6): instead of speaking, it
/// appends each utterance in order, so AC-8 can assert exactly what the readout
/// spoke (name, value, temperature, hue words, chroma, hue angle).
class FakeSpeech implements Speech {
  /// Every utterance passed to [speak], in call order.
  final List<String> utterances = [];

  @override
  Future<void> speak(String utterance) async {
    utterances.add(utterance);
  }
}
