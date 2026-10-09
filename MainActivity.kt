package com.example.gasi_candle_ai

import android.app.AlertDialog
import android.content.Intent
import android.content.pm.PackageManager
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.widget.EditText
import android.widget.FrameLayout
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var pending: MethodChannel.Result? = null
    private var keyDialog: AlertDialog? = null
    private var askedOnce = false

    private fun hasKey(): Boolean =
        !(getSharedPreferences("gasi", MODE_PRIVATE).getString("key", "") ?: "").isEmpty()

    // API key না থাকলে অ্যাপ খুললেই key বসানোর বক্স আসবে
    private fun showKeyDialog() {
        if (keyDialog?.isShowing == true) return
        val dm = resources.displayMetrics.density
        val input = EditText(this)
        input.hint = "AIza..."
        input.setSingleLine()
        val pad = (20 * dm).toInt()
        val box = FrameLayout(this)
        box.setPadding(pad, pad / 2, pad, 0)
        box.addView(input)
        keyDialog = AlertDialog.Builder(this)
            .setTitle("Gemini API key দিন")
            .setMessage("aistudio.google.com/apikey থেকে key কপি করে এখানে বসান। key শুধু এই ফোনে থাকবে।")
            .setView(box)
            .setPositiveButton("সেভ") { _, _ ->
                val k = input.text.toString().trim()
                if (k.isNotEmpty()) {
                    getSharedPreferences("gasi", MODE_PRIVATE)
                        .edit().putString("key", k).apply()
                }
            }
            .setNegativeButton("পরে", null)
            .create()
        keyDialog?.show()
    }

    override fun onResume() {
        super.onResume()
        if (!askedOnce && !hasKey()) {
            askedOnce = true
            showKeyDialog()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Android 13+ এ notification permission চাওয়া
        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(
                arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 7002
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "gasi/native"
        ).setMethodCallHandler { call, result ->
            when (call.method) {

                "hasOverlayPermission" ->
                    result.success(Settings.canDrawOverlays(this))

                "openOverlaySettings" -> {
                    startActivity(
                        Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:" + packageName)
                        )
                    )
                    result.success(null)
                }

                "hasApiKey" -> {
                    val k = getSharedPreferences("gasi", MODE_PRIVATE)
                        .getString("key", "") ?: ""
                    result.success(k.isNotEmpty())
                }

                "getMinutes" -> {
                    val m = getSharedPreferences("gasi", MODE_PRIVATE).getInt("minutes", 5)
                    result.success(m)
                }

                "saveMinutes" -> {
                    val m = call.argument<Int>("minutes") ?: 5
                    getSharedPreferences("gasi", MODE_PRIVATE)
                        .edit().putInt("minutes", m).apply()
                    result.success(null)
                }

                "askApiKey" -> {
                    showKeyDialog()
                    result.success(null)
                }

                "saveApiKey" -> {
                    val k = call.argument<String>("key") ?: ""
                    getSharedPreferences("gasi", MODE_PRIVATE)
                        .edit().putString("key", k.trim()).apply()
                    result.success(null)
                }

                "isBatteryUnrestricted" -> {
                    val pm = getSystemService(POWER_SERVICE) as PowerManager
                    result.success(pm.isIgnoringBatteryOptimizations(packageName))
                }

                "openBatterySettings" -> {
                    try {
                        startActivity(
                            Intent(
                                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                Uri.parse("package:" + packageName)
                            )
                        )
                    } catch (e: Exception) {
                        startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                    }
                    result.success(null)
                }

                "startOverlay" -> {
                    if (!Settings.canDrawOverlays(this)) {
                        result.error("NO_PERMISSION", "Overlay permission নেই", null)
                    } else if (pending != null) {
                        result.error("BUSY", "অপেক্ষা করুন", null)
                    } else {
                        pending = result
                        val mpm = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                        startActivityForResult(mpm.createScreenCaptureIntent(), 7001)
                    }
                }

                "stopOverlay" -> {
                    stopService(Intent(this, OverlayService::class.java))
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 7001) return

        val r = pending
        pending = null

        if (resultCode == android.app.Activity.RESULT_OK && data != null) {
            val i = Intent(this, OverlayService::class.java)
            i.putExtra("code", resultCode)
            i.putExtra("data", data)
            ContextCompat.startForegroundService(this, i)
            r?.success(null)
        } else {
            r?.error("DENIED", "Screen capture permission দেওয়া হয়নি", null)
        }
    }
}
