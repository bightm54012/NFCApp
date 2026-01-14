import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

void main() => runApp(const MaterialApp(home: NfcEmulatorApp()));

class NfcEmulatorApp extends StatefulWidget {
  const NfcEmulatorApp({super.key});
  @override
  _NfcEmulatorAppState createState() => _NfcEmulatorAppState();
}

class _NfcEmulatorAppState extends State<NfcEmulatorApp> {
  static const platform = MethodChannel('com.example.nfc/action');
  String _status = "等待操作...";
  String _lastReadUid = "";    // 原始 UID (例如 7D1B898E)
  String _displayUid = "";     // 顯示用的格式化 ID (例如 7D:1B:89:8E)
  String _emulatingDisplay = ""; // 正在模擬中顯示的文字 (含前綴)
  String _currentMode = "none";  // 記錄目前的模式

  String _formatToCardId(String hex) {
    if (hex.isEmpty) return "";
    hex = hex.replaceAll(":", "").toUpperCase();
    String formatted = "";
    for (int i = 0; i < hex.length; i += 2) {
      formatted += hex.substring(i, (i + 2).clamp(0, hex.length));
      if (i < hex.length - 2) formatted += ":";
    }
    return formatted;
  }

  Future<void> _readNfc() async {
    try {
      setState(() => _status = "請靠近實體卡片...");
      var tag = await FlutterNfcKit.poll();
      setState(() {
        _lastReadUid = tag.id;
        _displayUid = _formatToCardId(tag.id);
        _status = "讀取成功！";
      });
      await FlutterNfcKit.finish();
    } catch (e) {
      setState(() => _status = "讀取出錯: $e");
    }
  }

  // 核心修改：傳送 mode 給原生層，並更新顯示文字
  Future<void> _updateEmulation(String mode) async {
    var availability = await FlutterNfcKit.nfcAvailability;
    if (availability != NFCAvailability.available) {
      setState(() => _status = "NFC 未就緒");
      return;
    }

    if (_lastReadUid.isEmpty) {
      setState(() => _status = "錯誤：請先讀取一個卡片 ID");
      return;
    }

    try {
      // 呼叫原生層，傳送模式與原始 UID
      await platform.invokeMethod('startEmulation', {
        "uid": _lastReadUid,
        "mode": mode
      });

      setState(() {
        _currentMode = mode;
        _status = "模擬就緒";
        // 更新顯示邏輯
        if (mode == "http") {
          _emulatingDisplay = "https://${_lastReadUid.toUpperCase()}";
        } else if (mode == "tel") {
          _emulatingDisplay = "Tel: ${_lastReadUid.toUpperCase()}";
        } else {
          _emulatingDisplay = _formatToCardId(_lastReadUid);
        }
      });
    } on PlatformException catch (e) {
      setState(() => _status = "模擬失敗: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NFC 門禁模擬器")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _readNfc, child: const Text("1. 讀取門禁卡")),
            const SizedBox(height: 15),

            // 按鈕名改為「手機模擬」
            ElevatedButton(
                onPressed: () => _updateEmulation("none"),
                child: const Text("2. 手機模擬")
            ),

            if (_emulatingDisplay.isNotEmpty)
              Column(
                children: [
                  const SizedBox(height: 20),
                  const Text("切換模擬格式：", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(onPressed: () => _updateEmulation("http"), child: const Text("HTTP")),
                      TextButton(onPressed: () => _updateEmulation("tel"), child: const Text("TEL")),
                      TextButton(onPressed: () => _updateEmulation("none"), child: const Text("無前綴")),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Icon(Icons.vibration, color: Colors.green),
                  Text(
                    "HCE 服務運作中",
                    style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                  ),
                  Text(
                    "目前模擬內容:\n$_emulatingDisplay",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}