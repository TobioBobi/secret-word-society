import 'package:flutter/services.dart';

/// Android owns the audible deadline so suspended Flutter frames cannot delay it.
class RoundSignal {
  static const channel = MethodChannel('secret_word_society/round_signal');

  Future<bool> backgroundAllowed() async {
    try {
      return await channel.invokeMethod<bool>('backgroundAllowed') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> _invoke(String method, [Map<String, Object>? arguments]) async {
    try {
      await channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // Other platforms still have the visual signal.
    } on PlatformException {
      // Audio failure must never prevent voting or expose private information.
    }
  }

  Future<void> requestBackground() => _invoke('requestBackground');
  Future<void> arm(String token, DateTime deadline) => _invoke('arm', {
    'token': token,
    'deadlineMillis': deadline.millisecondsSinceEpoch,
  });
  Future<void> finish(String token) => _invoke('finish', {'token': token});
  Future<void> cancel() => _invoke('cancel');
}
