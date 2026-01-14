package com.example.nfc_app

import android.content.Context
import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.util.Log

class MyHceService : HostApduService() {

    private val TAG = "NFC_DEBUG"
    private val RESP_OK = byteArrayOf(0x90.toByte(), 0x00.toByte())
    private val RESP_ERROR = byteArrayOf(0x6F.toByte(), 0x00.toByte())

    // 標準 Type 4 Tag CC File (Capability Container)
    private val CC_FILE = byteArrayOf(
        0x00, 0x0F, // CCLEN
        0x20,       // Mapping Version
        0x00, 0x3B, // MLe (Maximum data length)
        0x00, 0x34, // MLc (Maximum command length)
        0x04,       // T (NDEF File Control TLV)
        0x06,       // L
        0xE1.toByte(), 0x04.toByte(), // File ID
        0x00, 0xFF.toByte(),         // Max NDEF Size
        0x00,       // Read Access
        0x00        // Write Access
    )

    private var currentStep = 0

    override fun processCommandApdu(commandApdu: ByteArray?, extras: Bundle?): ByteArray {
        if (commandApdu == null) return RESP_ERROR

        val hex = commandApdu.joinToString("") { "%02X".format(it) }
        Log.d(TAG, "收到指令: $hex")

        // 1. SELECT NDEF Application
        if (hex.contains("D2760000850101")) {
            Log.e(TAG, ">>> Step 1: AID 匹配成功")
            currentStep = 1
            // 修正：有些設備在 Step 1 需要看到明確的成功回應
            return RESP_OK
        }

        // 2. 處理所有的 SELECT 指令 (00A4)
        if (hex.startsWith("00A4")) {
            if (hex.contains("E103")) {
                Log.e(TAG, ">>> Step 2: CC File 匹配成功")
                currentStep = 2
                return RESP_OK
            } else if (hex.contains("E104")) {
                Log.e(TAG, ">>> Step 3: NDEF File 匹配成功")
                currentStep = 3
                return RESP_OK
            }
            // 如果對方發了其他的 Select，我們也回 OK 穩住連線
            return RESP_OK
        }

        // 3. READ BINARY (00B0)
        // ... 前面 Step 1, 2, 3 保持不變 ...

        if (hex.startsWith("00B0")) {
            // 解析 Offset (P1 P2)
            val offset = ((commandApdu[2].toInt() and 0xFF) shl 8) or (commandApdu[3].toInt() and 0xFF)
            // 解析 Le (期望讀取的長度，最後一個 byte)
            val le = if (commandApdu.size >= 5) (commandApdu[4].toInt() and 0xFF) else 0

            if (currentStep == 2) {
                val responsePart = if (offset < CC_FILE.size) CC_FILE.copyOfRange(offset, CC_FILE.size) else byteArrayOf()
                // 根據 Le 截取長度
                val finalResp = if (le > 0 && le < responsePart.size) responsePart.copyOfRange(0, le) else responsePart
                return finalResp + RESP_OK
            }

            if (currentStep == 3) {
                val prefs = getSharedPreferences("NFC_SETTINGS", Context.MODE_PRIVATE)
                val mode = prefs.getString("mode", "none") ?: "none"
                val uid = prefs.getString("uid", "") ?: ""

                // 生成資料
                val ndefData = when (mode) {
                    "http" -> buildUriNdef(0x04.toByte(), uid)
                    "tel" -> buildUriNdef(0x05.toByte(), uid)
                    else -> buildTextNdef(uid)
                }

                if (offset >= ndefData.size) return RESP_OK

                // 核心修正：根據讀取端要求的 Le 長度來回傳
                val availableData = ndefData.copyOfRange(offset, ndefData.size)
                val actualLength = if (le > 0 && le < availableData.size) le else availableData.size

                val responsePart = availableData.copyOfRange(0, actualLength)

                Log.e(TAG, ">>> Step 4: 傳送 $mode 資料 (請求長度: $le, 實際回傳: ${responsePart.size}, Offset: $offset)")

                return responsePart + RESP_OK
            }
        }

        return RESP_OK
    }

    // 封裝 URI 格式 (用於 HTTP 和 TEL)
    private fun buildUriNdef(prefix: Byte, content: String): ByteArray {
        val payload = content.toByteArray(Charsets.UTF_8)

        // NDEF Record (標準格式)
        val record = byteArrayOf(
            0xD1.toByte(),              // MB=1, ME=1, SR=1, TNF=0x01 (Well-known)
            0x01.toByte(),              // Type Length
            (payload.size + 1).toByte(),// Payload Length (前綴1 byte + 內容)
            0x55.toByte(),              // Type: 'U' (URI)
            prefix                      // 前綴: 0x04 (https://) 或 0x05 (tel:)
        ) + payload

        // NFC Forum Type 4 Tag 要求：
        // NDEF File 的前兩個位元組必須是整個 NDEF 紀錄的長度 (Big-Endian)
        val fullFile = byteArrayOf(
            ((record.size shr 8) and 0xFF).toByte(),
            (record.size and 0xFF).toByte()
        ) + record

        return fullFile
    }

    // 封裝純文字格式 (用於 無前綴)
    private fun buildTextNdef(content: String): ByteArray {
        val lang = "en".toByteArray(Charsets.US_ASCII)
        val text = content.toByteArray(Charsets.UTF_8)
        // Status byte: 0x02 代表語言代碼長度為 2 ('en')
        val payload = byteArrayOf(0x02.toByte()) + lang + text

        // NDEF Header: 0xD1, 0x01, Payload Len, 0x54 (Text Type)
        val record = byteArrayOf(
            0xD1.toByte(),
            0x01.toByte(),
            payload.size.toByte(),
            0x54.toByte()
        ) + payload

        val len = record.size
        return byteArrayOf(((len shr 8) and 0xFF).toByte(), (len and 0xFF).toByte()) + record
    }

    override fun onDeactivated(reason: Int) {
        currentStep = 0
        Log.e(TAG, "HCE 斷開，原因代碼: $reason")
    }
}