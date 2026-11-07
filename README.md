# th_system_settings

A small Flutter plugin that reads three iOS system settings without any other package:

- **Reduce Transparency** (Settings → Accessibility → Display & Text Size), and each change while the app runs;
- **the notification permission**: read, and asked once with the phone's own prompt (alert and sound);
- **the app's notification settings page**, opened from the app.

## Platforms

- **iOS 15 and later.** The notification settings page opens directly on iOS 16 and later; before that, the app's page in Settings opens.
- **Android and every other platform: not supported for now.** Each call returns its "nothing here" value (below) without touching a platform channel.

## API

```dart
import 'package:th_system_settings/th_system_settings.dart';

await ThSystemSettings.reduceTransparency();              // bool
ThSystemSettings.reduceTransparencyChanges;               // Stream<bool>
await ThSystemSettings.notificationStatus();              // String
await ThSystemSettings.requestNotificationPermission();   // String, after the prompt
await ThSystemSettings.openNotificationSettings();        // bool: the page opened
```

`notificationStatus` and `requestNotificationPermission` return one of `notDetermined`, `denied`, `authorized`, `provisional` or `ephemeral`, or `unsupported`. `unsupported` means: not iOS, no answer, or a status this version doesn't know.

| Call | Not iOS, or a platform error |
|---|---|
| `reduceTransparency()` | `false` |
| `reduceTransparencyChanges` | an empty stream |
| `notificationStatus()` | `'unsupported'` |
| `requestNotificationPermission()` | `'unsupported'` |
| `openNotificationSettings()` | `false` |

## Installing

Add it as a git dependency pinned to a commit:

```yaml
dependencies:
  th_system_settings:
    git:
      url: https://github.com/niktravelhunter/th-system-settings.git
      ref: <commit>
```

iOS builds it through CocoaPods (`ios/th_system_settings.podspec`).

## Tests

```
flutter test
```

The tests mock the method and event channels: every status string, the change stream, the error path, and the non-iOS path.

## License

MIT, see [LICENSE](LICENSE).
