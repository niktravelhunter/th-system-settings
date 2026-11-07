import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:th_system_settings/th_system_settings.dart';

const methods = MethodChannel('th_system_settings');
const events = EventChannel('th_system_settings/reduce_transparency');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <String>[];

  /// The native side answers [answers] by method name; a value that is an Exception is thrown.
  void answer(Map<String, Object?> answers) {
    messenger.setMockMethodCallHandler(methods, (call) async {
      calls.add(call.method);
      final a = answers[call.method];
      if (a is Exception) throw a;
      return a;
    });
  }

  setUp(() {
    calls.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(methods, null);
    messenger.setMockStreamHandler(events, null);
  });

  group('iOS', () {
    test('reduceTransparency: the native answer', () async {
      answer({'reduceTransparency': true});
      expect(await ThSystemSettings.reduceTransparency(), isTrue);
      answer({'reduceTransparency': false});
      expect(await ThSystemSettings.reduceTransparency(), isFalse);
      answer({'reduceTransparency': null});
      expect(await ThSystemSettings.reduceTransparency(), isFalse, reason: 'no answer → false');
    });

    test('notificationStatus: every status string passes through', () async {
      for (final s in ['notDetermined', 'denied', 'authorized', 'provisional', 'ephemeral']) {
        answer({'notificationStatus': s});
        expect(await ThSystemSettings.notificationStatus(), s);
      }
      answer({'notificationStatus': 'somethingNew'});
      expect(await ThSystemSettings.notificationStatus(), 'unsupported', reason: 'an unknown string');
      answer({'notificationStatus': null});
      expect(await ThSystemSettings.notificationStatus(), 'unsupported', reason: 'no answer');
    });

    test('requestNotificationPermission: its own method, every status string', () async {
      for (final s in ['notDetermined', 'denied', 'authorized', 'provisional', 'ephemeral']) {
        answer({'requestNotificationPermission': s});
        expect(await ThSystemSettings.requestNotificationPermission(), s);
      }
      expect(calls.toSet(), {'requestNotificationPermission'});
    });

    test('openNotificationSettings: the native answer', () async {
      answer({'openNotificationSettings': true});
      expect(await ThSystemSettings.openNotificationSettings(), isTrue);
      answer({'openNotificationSettings': false});
      expect(await ThSystemSettings.openNotificationSettings(), isFalse);
    });

    test('a platform error or a missing plugin gives the safe value', () async {
      answer({
        'reduceTransparency': PlatformException(code: 'x'),
        'notificationStatus': PlatformException(code: 'x'),
        'requestNotificationPermission': PlatformException(code: 'x'),
        'openNotificationSettings': PlatformException(code: 'x'),
      });
      expect(await ThSystemSettings.reduceTransparency(), isFalse);
      expect(await ThSystemSettings.notificationStatus(), 'unsupported');
      expect(await ThSystemSettings.requestNotificationPermission(), 'unsupported');
      expect(await ThSystemSettings.openNotificationSettings(), isFalse);
      messenger.setMockMethodCallHandler(methods, null); // no native side at all: MissingPluginException
      expect(await ThSystemSettings.reduceTransparency(), isFalse);
      expect(await ThSystemSettings.notificationStatus(), 'unsupported');
      expect(await ThSystemSettings.openNotificationSettings(), isFalse);
    });

    test('reduceTransparencyChanges: each change notice, in order', () async {
      messenger.setMockStreamHandler(
        events,
        MockStreamHandler.inline(onListen: (args, sink) {
          sink.success(true);
          sink.success(false);
          sink.success(true);
          sink.endOfStream();
        }),
      );
      expect(await ThSystemSettings.reduceTransparencyChanges.toList(), [true, false, true]);
    });
  });

  group('not iOS', () {
    for (final p in [TargetPlatform.android, TargetPlatform.macOS, TargetPlatform.linux, TargetPlatform.windows]) {
      test('${p.name}: the safe values, no channel touched', () async {
        debugDefaultTargetPlatformOverride = p;
        answer({
          'reduceTransparency': true,
          'notificationStatus': 'authorized',
          'requestNotificationPermission': 'authorized',
          'openNotificationSettings': true,
        });
        var listened = false;
        messenger.setMockStreamHandler(
          events,
          MockStreamHandler.inline(onListen: (args, sink) => listened = true),
        );
        expect(await ThSystemSettings.reduceTransparency(), isFalse);
        expect(await ThSystemSettings.notificationStatus(), 'unsupported');
        expect(await ThSystemSettings.requestNotificationPermission(), 'unsupported');
        expect(await ThSystemSettings.openNotificationSettings(), isFalse);
        expect(await ThSystemSettings.reduceTransparencyChanges.toList(), isEmpty);
        expect(calls, isEmpty, reason: 'no method channel call');
        expect(listened, isFalse, reason: 'no event channel listen');
      });
    }
  });
}
