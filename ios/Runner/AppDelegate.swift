import UIKit
import Flutter
import ContactlessReader

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    private var activeUid: String = ""

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let nfcChannel = FlutterMethodChannel(name: "com.example.nfc/action", binaryMessenger: controller.binaryMessenger)
        
        nfcChannel.setMethodCallHandler({ [weak self] (call, result) in
            guard let self = self else { return }
            
            if call.method == "startEmulation" {
                guard let args = call.arguments as? [String: Any],
                      let uid = args["uid"] as? String else {
                    result(FlutterError(code: "INVALID_ARG", message: "Missing UID", details: nil))
                    return
                }
                
                self.activeUid = uid
                
                if #available(iOS 17.4, *) {
                    Task {
                        await self.startNfcSimulation(targetUid: uid, flutterResult: result)
                    }
                } else {
                    result(FlutterError(code: "VERSION_LOW", message: "iOS 17.4+ is required", details: nil))
                }
            }
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    @available(iOS 17.4, *)
    private func startNfcSimulation(targetUid: String, flutterResult: @escaping FlutterResult) async {
        do {
            let session = try await CardSession()
            flutterResult("iOS 模擬會話已開啟: \(targetUid)")
            
            for await event in session.eventStream {
                switch event {
                case .received(let apdu):
                    var response = self.hexToData(targetUid)
                    response.append(contentsOf: [0x90, 0x00])
                    try await session.respond(response: response)
                    print("已回傳 UID 數據")
                    
                case .readerDetected:
                    print("靠近讀卡機中...")
                case .sessionInvalidated(let error):
                    print("Session 失效: \(error)")
                @unknown default:
                    break
                }
            }
        } catch {
            flutterResult(FlutterError(code: "SIM_FAIL", message: error.localizedDescription, details: nil))
        }
    }

    private func hexToData(_ hex: String) -> Data {
        let cleanHex = hex.replacingOccurrences(of: ":", with: "").replacingOccurrences(of: " ", with: "")
        var data = Data()
        var i = 0
        while i < cleanHex.count {
            let start = cleanHex.index(cleanHex.startIndex, offsetBy: i)
            let end = cleanHex.index(cleanHex.startIndex, offsetBy: i + 2)
            if let byte = UInt8(cleanHex[start..<end], radix: 16) {
                data.append(byte)
            }
            i += 2
        }
        return data
    }
}
