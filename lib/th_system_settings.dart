/// Three iOS system settings, read without any other package:
/// Reduce Transparency and its change notice, the notification permission (read and asked),
/// and the app's notification settings page.
///
/// iOS only for now. On every other platform each call returns its "nothing here" value
/// ('unsupported', false, an empty stream) without touching a channel.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ThSystemSettings {
  ThSystemSettings._();

  static const MethodChannel _methods = MethodChannel('th_system_settings');
  static const EventChannel _events = EventChannel('th_system_settings/reduce_transparency');

  /// The notification permission as iOS reports it.
  static const Set<String> statuses = {'notDetermined', 'denied', 'authorized', 'provisional', 'ephemeral'};

  static bool get _onIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Whether Reduce Transparency is on (Settings → Accessibility → Display & Text Size).
  static Future<bool> reduceTransparency() async {
    if (!_onIOS) return false;
    try {
      return await _methods.invokeMethod<bool>('reduceTransparency') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// The setting each time it changes while someone listens.
  static Stream<bool> get reduceTransparencyChanges {
    if (!_onIOS) return const Stream<bool>.empty();
    return _events.receiveBroadcastStream().map((value) => value == true);
  }

  /// 'notDetermined' | 'denied' | 'authorized' | 'provisional' | 'ephemeral', or 'unsupported'.
  static Future<String> notificationStatus() => _status('notificationStatus');

  /// Shows the phone's prompt (alert and sound) if the person was never asked, then returns the
  /// status as notificationStatus does. Once asked, iOS returns the stored answer without a prompt.
  static Future<String> requestNotificationPermission() => _status('requestNotificationPermission');

  /// Opens the app's notification settings (iOS 16+), else the app's page in Settings.
  /// True when the page opened.
  static Future<bool> openNotificationSettings() async {
    if (!_onIOS) return false;
    try {
      return await _methods.invokeMethod<bool>('openNotificationSettings') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<String> _status(String method) async {
    if (!_onIOS) return 'unsupported';
    try {
      final status = await _methods.invokeMethod<String>(method);
      return statuses.contains(status) ? status! : 'unsupported';
    } on PlatformException {
      return 'unsupported';
    } on MissingPluginException {
      return 'unsupported';
    }
  }
}
