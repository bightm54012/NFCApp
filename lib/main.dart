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
  String _lastReadUid = "";

  Future<void> _readNfc() async {
    try {
      setState(() => _status = "請靠近實體卡片...");
      var tag = await FlutterNfcKit.poll();
      setState(() {
        _lastReadUid = tag.id;
        _status = "讀取成功！ID: $_lastReadUid";
      });
      await FlutterNfcKit.finish();
    } catch (e) {
      setState(() => _status = "讀取出錯: $e");
    }
  }

  Future<void> _startEmulation() async {
    if (_lastReadUid.isEmpty) {
      setState(() => _status = "錯誤：請先讀取一個卡片 ID");
      return;
    }
    try {
      final String result = await platform.invokeMethod('startEmulation', {"uid": _lastReadUid});
      setState(() => _status = result);
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
            ElevatedButton(onPressed: _startEmulation, child: const Text("2. 手機變成門禁卡")),
          ],
        ),
      ),
    );
  }
}