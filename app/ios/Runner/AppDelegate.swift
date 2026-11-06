import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "velomine/secure_storage",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    let store = SecureTokenStore()

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "readRefreshToken":
        result(store.read())
      case "writeRefreshToken":
        guard let token = call.arguments as? String else {
          result(FlutterError(code: "bad_argument", message: "No token was sent.", details: nil))
          return
        }
        result(store.write(token))
      case "clear":
        store.clear()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
