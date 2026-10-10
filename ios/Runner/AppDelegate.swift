import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register our native security plugin for hardware flashlight, sound, battery, and camera
    let registrar = self.registrar(forPlugin: "NativeSecurityPlugin")
    if let registrar = registrar {
        NativeSecurityPlugin.register(with: registrar)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
