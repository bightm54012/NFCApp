package com.ni.nfcApp

import android.content.Context
import android.nfc.cardemulation.HostApduService
import android.os.Bundle

class MyHceService : HostApduService() {
    override fun processCommandApdu(commandApdu: ByteArray?, extras: Bundle?): ByteArray {
        val prefs = getSharedPreferences("NFC_PREFS", Context.MODE_PRIVATE)
        val savedUid = prefs.getString("current_uid", "00000000") ?: "00000000"

        return hexToBytes(savedUid) + byteArrayOf(0x90.toByte(), 0x00.toByte())
    }

    override fun onDeactivated(reason: Int) {}

    private fun hexToBytes(hex: String): ByteArray {
        val s = hex.replace(":", "")
        val data = ByteArray(s.length / 2)
        for (i in 0 until s.length step 2) {
            data[i / 2] = ((Character.digit(s[i], 16) shl 4) + Character.digit(s[i + 1], 16)).toByte()
        }
        return data
    }
}