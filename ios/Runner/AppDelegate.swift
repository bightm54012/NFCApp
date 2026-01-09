import UIKit
import Flutter
import CoreNFC

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.example.nfc/action", binaryMessenger: controller.binaryMessenger)
    
    channel.setMethodCallHandler({ (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "startEmulation" {
        if #available(iOS 17.4, *) {
          self.runIosEmulation(result: result)
        } else {
          result(FlutterError(code: "VERSION", message: "iOS 17.4 required", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  @available(iOS 17.4, *)
  private func runIosEmulation(result: @escaping FlutterResult) {
    Task {
      do {
        _ = try await NFCPresentmentIntentAssertion.acquire()
        let session = try await CardSession()
        for try await event in session.eventStream {
          switch event {
          case .readerDetected:
            try await session.startEmulation()
          case .received(let apdu):
            try await apdu.respond(response: Data([0x90, 0x00]))
          default: break
          }
        }
        result("iOS 模擬會話已啟動")
      } catch {
        result(FlutterError(code: "ERR", message: error.localizedDescription, details: nil))
      }
    }
  }
}
