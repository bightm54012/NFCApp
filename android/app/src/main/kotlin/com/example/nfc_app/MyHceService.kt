package com.example.nfc_app

import android.nfc.cardemulation.HostApduService
import android.os.Bundle

class MyHceService : HostApduService() {
    override fun processCommandApdu(commandApdu: ByteArray?, extras: Bundle?): ByteArray {
        return byteArrayOf(0x90.toByte(), 0x00.toByte())
    }

    override fun onDeactivated(reason: Int) {

    }
}