import UIKit
import Flutter
import ContactlessReader

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    private var targetUid: String = ""

    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "com.example.nfc/action", binaryMessenger: controller.binaryMessenger)
        
        channel.setMethodCallHandler({ [weak self] (call, result) in
            if call.method == "startEmulation", let args = call.arguments as? [String: Any], let uid = args["uid"] as? String {
                self?.targetUid = uid
                if #available(iOS 17.4, *) {
                    Task { await self?.startIosSim(result: result) }
                } else {
                    result(FlutterError(code: "VER", message: "iOS 17.4+", details: nil))
                }
            }
        })
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    @available(iOS 17.4, *)
    func startIosSim(result: @escaping FlutterResult) async {
        do {
            let session = try await CardSession()
            result("iOS 模擬中...")
            for await event in session.eventStream {
                if case .received(let apdu) = event {
                    let response = Data(hexString: self.targetUid) + Data([0x90, 0x00])
                    try await session.respond(response: response)
                }
            }
        } catch {
            result(FlutterError(code: "FAIL", message: error.localizedDescription, details: nil))
        }
    }
}

extension Data {
    init(hexString: String) {
        let hex = hexString.replacingOccurrences(of: ":", with: "")
        self.init()
        var i = 0
        while i < hex.count {
            let start = hex.index(hex.startIndex, offsetBy: i)
            let end = hex.index(hex.startIndex, offsetBy: i + 2)
            if let byte = UInt8(hex[start..<end], radix: 16) { self.append(byte) }
            i += 2
        }
    }
}
