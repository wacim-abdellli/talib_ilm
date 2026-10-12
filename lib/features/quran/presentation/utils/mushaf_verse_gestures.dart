import 'package:flutter/gestures.dart';

/// Tap ignored when the finger moved (e.g. during a horizontal page swipe).
class MushafVerseTapRecognizer extends TapGestureRecognizer {
  Offset? _downPosition;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _downPosition = event.position;
    super.addAllowedPointer(event);
  }

  @override
  void handleTapUp({required PointerDownEvent down, required PointerUpEvent up}) {
    final start = _downPosition;
    if (start != null && (up.position - start).distance > kTouchSlop) {
      return;
    }
    super.handleTapUp(down: down, up: up);
  }

  @override
  void rejectGesture(int pointer) {
    _downPosition = null;
    super.rejectGesture(pointer);
  }
}

class MushafVerseRecognizerPool {
  final Map<String, MushafVerseTapRecognizer> _taps = {};
  final Map<String, LongPressGestureRecognizer> _longPresses = {};

  MushafVerseTapRecognizer tap({
    required int surah,
    required int ayah,
    required void Function() onTap,
  }) {
    final key = '$surah-$ayah';
    return _taps.putIfAbsent(key, () {
      final recognizer = MushafVerseTapRecognizer();
      recognizer.onTap = onTap;
      return recognizer;
    });
  }

  LongPressGestureRecognizer longPress({
    required int surah,
    required int ayah,
    required void Function() onLongPress,
  }) {
    final key = '$surah-$ayah';
    return _longPresses.putIfAbsent(key, () {
      final recognizer = LongPressGestureRecognizer();
      recognizer.onLongPress = onLongPress;
      return recognizer;
    });
  }

  void dispose() {
    for (final r in _taps.values) {
      r.dispose();
    }
    for (final r in _longPresses.values) {
      r.dispose();
    }
    _taps.clear();
    _longPresses.clear();
  }
}
