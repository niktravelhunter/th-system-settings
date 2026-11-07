import Flutter
import UIKit
import UserNotifications

/// Reduce Transparency and its change notice, the notification permission, and the app's
/// notification settings page.
public class ThSystemSettingsPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var sink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = ThSystemSettingsPlugin()
    let methods = FlutterMethodChannel(name: "th_system_settings", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: methods)
    let events = FlutterEventChannel(name: "th_system_settings/reduce_transparency", binaryMessenger: registrar.messenger())
    events.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "reduceTransparency":
      result(UIAccessibility.isReduceTransparencyEnabled)
    case "notificationStatus":
      reportStatus(result)
    case "requestNotificationPermission":
      // Alert and sound only.
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
        self.reportStatus(result)
      }
    case "openNotificationSettings":
      var link = UIApplication.openSettingsURLString
      if #available(iOS 16.0, *) {
        link = UIApplication.openNotificationSettingsURLString
      }
      guard let url = URL(string: link) else {
        result(false)
        return
      }
      UIApplication.shared.open(url, options: [:]) { opened in result(opened) }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func reportStatus(_ result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      let status: String
      switch settings.authorizationStatus {
      case .notDetermined: status = "notDetermined"
      case .denied: status = "denied"
      case .authorized: status = "authorized"
      case .provisional: status = "provisional"
      case .ephemeral: status = "ephemeral"
      @unknown default: status = "unsupported"
      }
      DispatchQueue.main.async { result(status) }
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    NotificationCenter.default.addObserver(
      self, selector: #selector(reduceTransparencyChanged),
      name: UIAccessibility.reduceTransparencyStatusDidChangeNotification, object: nil)
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    NotificationCenter.default.removeObserver(
      self, name: UIAccessibility.reduceTransparencyStatusDidChangeNotification, object: nil)
    sink = nil
    return nil
  }

  @objc private func reduceTransparencyChanged() {
    sink?(UIAccessibility.isReduceTransparencyEnabled)
  }
}
