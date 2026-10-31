import 'package:flutter/services.dart';

/// Keeps the visible countdown awake and plays its end signal once on Android.
class RoundSignal {
  static const channel = MethodChannel('secret_word_society/round_signal');

  Future<void> _invoke(String method, [Map<String, Object>? arguments]) async {
    try {
      await channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // Other platforms still have the visual signal.
    } on PlatformException {
      // Audio failure must never prevent voting or expose private information.
    }
  }

  Future<void> arm(String token, DateTime deadline) => _invoke('arm', {
    'token': token,
    'deadlineMillis': deadline.millisecondsSinceEpoch,
  });
  Future<void> finish(String token, {required bool audible}) =>
      _invoke('finish', {'token': token, 'audible': audible});
  Future<void> cancel() => _invoke('cancel');
}
