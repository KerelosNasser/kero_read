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
                    val originalName = getDisplayName(data)
                    var fileName = originalName
                    var file = File(cacheDir, fileName)
                    var counter = 1
                    val baseName = originalName.substringBeforeLast(".pdf")
                    while (file.exists()) {
                        fileName = "${baseName}_$counter.pdf"
                        file = File(cacheDir, fileName)
                        counter++
                    }
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

    private fun getDisplayName(uri: android.net.Uri): String {
        var name: String? = null
        if (uri.scheme == "content") {
            try {
                contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val index = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                        if (index != -1) {
                            name = cursor.getString(index)
                        }
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        if (name == null) {
            name = uri.path
            val cut = name?.lastIndexOf('/') ?: -1
            if (cut != -1) {
                name = name?.substring(cut + 1)
            }
        }
        if (name != null) {
            try {
                name = java.net.URLDecoder.decode(name, "UTF-8")
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        // Sanitize name: remove invalid chars
        name = name?.replace("[\\\\/:*?\"<>|]".toRegex(), "_")
        if (name.isNullOrBlank()) {
            name = "imported_${System.currentTimeMillis()}"
        }
        if (!name.lowercase().endsWith(".pdf")) {
            name = "$name.pdf"
        }
        return name
    }
}

