package com.example.attendance_tracker

import android.app.Activity
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class NativeFilePickerPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var context: Context? = null
    private var result: Result? = null

    companion object {
        private const val PICK_FILE_REQUEST = 1001
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "native_file_picker")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "pickJsonFile" -> {
                this.result = result
                pickJsonFile()
            }
            "saveToDownloads" -> {
                val fileName = call.argument<String>("fileName")
                val content = call.argument<String>("content")
                if (fileName != null && content != null) {
                    saveToDownloads(fileName, content, result)
                } else {
                    result.error("INVALID_ARGS", "fileName and content are required", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun pickJsonFile() {
        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            type = "application/json"
            addCategory(Intent.CATEGORY_OPENABLE)
            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("application/json", "text/plain", "*/*"))
        }

        try {
            activity?.startActivityForResult(
                Intent.createChooser(intent, "Select Backup File"),
                PICK_FILE_REQUEST
            )
        } catch (e: Exception) {
            result?.error("PICK_ERROR", "Failed to open file picker: ${e.message}", null)
            result = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == PICK_FILE_REQUEST) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uri: Uri? = data.data
                if (uri != null) {
                    try {
                        val filePath = getPathFromUri(uri)
                        result?.success(filePath)
                    } catch (e: Exception) {
                        result?.error("READ_ERROR", "Failed to read file: ${e.message}", null)
                    }
                } else {
                    result?.error("NO_FILE", "No file selected", null)
                }
            } else {
                result?.success(null) // User cancelled
            }
            result = null
            return true
        }
        return false
    }

    private fun getPathFromUri(uri: Uri): String? {
        return try {
            activity?.contentResolver?.openInputStream(uri)?.use { inputStream ->
                // Create a temporary file to store the content
                val tempFile = kotlin.io.path.createTempFile("backup", ".json").toFile()
                tempFile.outputStream().use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
                tempFile.absolutePath
            }
        } catch (e: Exception) {
            null
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    private fun saveToDownloads(fileName: String, content: String, result: Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Android 10+ (API 29+) - Use MediaStore
                saveToDownloadsModern(fileName, content, result)
            } else {
                // Android 9 and below - Direct file access
                saveToDownloadsLegacy(fileName, content, result)
            }
        } catch (e: Exception) {
            result.error("SAVE_ERROR", "Failed to save file: ${e.message}", null)
        }
    }

    private fun saveToDownloadsModern(fileName: String, content: String, result: Result) {
        val resolver = context?.contentResolver
        if (resolver == null) {
            result.error("NO_RESOLVER", "Content resolver not available", null)
            return
        }

        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, "application/json")
            put(MediaStore.MediaColumns.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/Attendance Tracker")
        }

        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
        if (uri != null) {
            try {
                resolver.openOutputStream(uri)?.use { outputStream ->
                    outputStream.write(content.toByteArray())
                    outputStream.flush()
                }
                result.success("${Environment.DIRECTORY_DOWNLOADS}/Attendance Tracker/$fileName")
            } catch (e: IOException) {
                result.error("WRITE_ERROR", "Failed to write file: ${e.message}", null)
            }
        } else {
            result.error("URI_ERROR", "Failed to create file URI", null)
        }
    }

    private fun saveToDownloadsLegacy(fileName: String, content: String, result: Result) {
        val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        val appDir = File(downloadsDir, "Attendance Tracker")
        
        if (!appDir.exists()) {
            appDir.mkdirs()
        }

        val file = File(appDir, fileName)
        try {
            FileOutputStream(file).use { outputStream ->
                outputStream.write(content.toByteArray())
                outputStream.flush()
            }
            result.success(file.absolutePath)
        } catch (e: IOException) {
            result.error("WRITE_ERROR", "Failed to write file: ${e.message}", null)
        }
    }
}