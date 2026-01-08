import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:flutter/services.dart';
import 'dart:io';

void main() => runApp(MaterialApp(home: NfcApp()));

class NfcApp extends StatefulWidget {
  @override
  _NfcAppState createState() => _NfcAppState();
}

class _NfcAppState extends State<NfcApp> {
  String _status = "等待操作";
  String _savedUid = "";
  static const platform = MethodChannel('com.example.nfc/hce');

  Future<void> _readTag() async {
    try {
      setState(() => _status = "正在啟動 NFC...");
      var tag = await FlutterNfcKit.poll(
        timeout: Duration(seconds: 15),
        iosAlertMessage: "請靠近磁扣",
      );
      setState(() {
        _savedUid = tag.id;
        _status = "讀取成功！\nID: ${tag.id}";
      });
    } catch (e) {
      setState(() => _status = "讀取失敗: $e");
    } finally {
      await FlutterNfcKit.finish();
    }
  }

  // --- 功能 2：啟動模擬 (僅 Android 可用) ---
  Future<void> _startEmulation() async {
    if (_savedUid.isEmpty) {
      setState(() => _status = "請先讀取一個 ID");
      return;
    }
    try {
      // 呼叫 Android 原生 Kotlin 程式碼
      final String result = await platform.invokeMethod('startHce', {"uid": _savedUid});
      setState(() => _status = "Android 模擬中...\n手機現在是磁扣了\nID: $_savedUid");
    } on PlatformException catch (e) {
      setState(() => _status = "模擬失敗: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("NFC 門禁助手 (跨平台)")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
            SizedBox(height: 30),

            ElevatedButton(onPressed: _readTag, child: Text("讀取磁扣 ID")),

            if (Platform.isAndroid) ...[
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _startEmulation,
                child: Text("Android 專用：模擬此磁扣"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              ),
            ],

            if (Platform.isIOS) ...[
              SizedBox(height: 20),
              Text("(iOS 僅支援讀取功能)", style: TextStyle(color: Colors.grey)),
            ]
          ],
        ),
      ),
    );
  }
}