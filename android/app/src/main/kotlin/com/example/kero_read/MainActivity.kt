package com.example.kero_read

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "kero_read/intent"
    }

    private var sharedPdfPath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getInitialPdf") {
                result.success(sharedPdfPath)
                sharedPdfPath = null
            } else {
                result.notImplemented()
            }
        }

        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
        
        sharedPdfPath?.let { path ->
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL).invokeMethod("onPdfOpened", path)
                sharedPdfPath = null
            }
        }
    }

    private fun handleIntent(intent: Intent) {
        val action = intent.action
        val data = intent.data

        if (Intent.ACTION_VIEW == action && data != null) {
            try {
                contentResolver.openInputStream(data)?.use { inputStream ->
                    val fileName = "imported_${System.currentTimeMillis()}.pdf"
                    val file = File(cacheDir, fileName)
                    FileOutputStream(file).use { outputStream ->
                        inputStream.copyTo(outputStream)
                    }
                    sharedPdfPath = file.absolutePath
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
