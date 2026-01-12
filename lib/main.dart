import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'dart:io';

void main() => runApp(MaterialApp(home: NfcMasterApp()));

class NfcMasterApp extends StatefulWidget {
  @override
  _NfcMasterAppState createState() => _NfcMasterAppState();
}

class _NfcMasterAppState extends State<NfcMasterApp> {
  String _status = "等待操作";
  String _lastReadUid = "";
  static const platform = MethodChannel('com.example.nfc/action');

  Future<void> _readNfc() async {
    try {
      NFCTag tag = await FlutterNfcKit.poll();
      setState(() {
        _lastReadUid = tag.id;
        _status = "讀取成功：$_lastReadUid";
      });
      await FlutterNfcKit.finish();
    } catch (e) {
      setState(() => _status = "讀取失敗: $e");
    }
  }

  Future<void> _startEmulation() async {
    if (_lastReadUid.isEmpty) {
      setState(() => _status = "請先讀取一張卡片");
      return;
    }
    try {
      final String result = await platform.invokeMethod('startEmulation', {
        "uid": _lastReadUid
      });
      setState(() => _status = result);
    } on PlatformException catch (e) {
      setState(() => _status = "模擬啟動失敗: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("NFC 門禁全功能")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              color: Colors.grey[200],
              child: Text(_status, textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 50),
            ElevatedButton(onPressed: _readNfc, child: Text("1. 讀取門禁卡")),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startEmulation,
              child: Text("2. 手機變成門禁卡"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }
}