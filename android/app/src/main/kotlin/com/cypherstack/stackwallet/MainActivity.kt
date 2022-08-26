package com.cypherstack.stackwallet

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterFragmentActivity
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.File
import java.io.InputStream
import 	java.nio.charset.Charset
import android.os.Build
import android.view.ViewTreeObserver
import android.view.WindowManager
class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "STACK_WALLET_RESTORE"

    var openPath: String? = null
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getOpenFile" -> {
                    result.success(openPath)
                }
                "resetOpenPath" -> {
                    resetOpenPath()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun resetOpenPath() {
        openPath = null
    }

    fun readFileDirectlyAsText(fileName: String): String
            = File(fileName).readText(Charsets.UTF_8)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleOpenFile(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleOpenFile(intent)
    }

    fun InputStream.readTextAndClose(charset: Charset = Charsets.UTF_8): String {
        return this.bufferedReader(charset).use { it.readText() }
    }

    private fun handleOpenFile(intent: Intent?) {
        val uri = intent?.data
        if (uri != null) {
            var inputStream = this.contentResolver.openInputStream(uri!!)
            val inputAsString = inputStream!!.readTextAndClose()
            openPath = inputAsString
        }
    }
}