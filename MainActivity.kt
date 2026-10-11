package com.example.gasi_candle_ai

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var pending: MethodChannel.Result? = null

    private val timeframes = listOf(1, 5, 15, 30, 60, 120, 300)

    private fun prefs(): SharedPreferences =
        getSharedPreferences("gasi", Context.MODE_PRIVATE)

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

                // ---------- পারমিশন ----------
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

                // ---------- প্রথমবারের ধাপ (চুক্তি, key) ----------
                "getFlags" -> {
                    val p = prefs()
                    val hasKey = (p.getString("key", "") ?: "").isNotEmpty()
                    result.success(
                        mapOf(
                            "agreed" to p.getBoolean("agreed", false),
                            "setup_done" to (p.getBoolean("setup_done", false) || hasKey)
                        )
                    )
                }

                "saveFlag" -> {
                    val name = call.argument<String>("name") ?: ""
                    val value = call.argument<Boolean>("value") ?: true
                    if (name == "agreed" || name == "setup_done") {
                        prefs().edit().putBoolean(name, value).apply()
                    }
                    result.success(null)
                }

                // ---------- API key ----------
                "hasApiKey" -> {
                    val k = prefs().getString("key", "") ?: ""
                    result.success(k.isNotEmpty())
                }

                "saveApiKey" -> {
                    val k = call.argument<String>("key") ?: ""
                    prefs().edit().putString("key", k.trim()).apply()
                    result.success(null)
                }

                "hasTdKey" -> {
                    val k = prefs().getString("td_key", "") ?: ""
                    result.success(k.isNotEmpty())
                }

                "saveTdKey" -> {
                    val k = call.argument<String>("key") ?: ""
                    prefs().edit().putString("td_key", k.trim()).apply()
                    result.success(null)
                }

                // ---------- পূর্বাভাসের সময় ও সুইচ ----------
                "getMinutes" -> result.success(prefs().getInt("minutes", 5))

                "saveMinutes" -> {
                    val m = call.argument<Int>("minutes") ?: 5
                    prefs().edit().putInt("minutes", m).apply()
                    result.success(null)
                }

                "getWeb" -> result.success(prefs().getBoolean("web", true))
                
                "saveWeb" -> {
                    val v = call.argument<Boolean>("web") ?: true
                    prefs().edit().putBoolean("web", v).apply()
                    result.success(null)
                }

                "getData" -> result.success(prefs().getBoolean("data", true))

                "saveData" -> {
                    val v = call.argument<Boolean>("data") ?: true
                    prefs().edit().putBoolean("data", v).apply()
                    result.success(null)
                }

                "getOtc" -> result.success(prefs().getBoolean("otc", false))

                "saveOtc" -> {
                    val v = call.argument<Boolean>("otc") ?: false
                    prefs().edit().putBoolean("otc", v).apply()
                    result.success(null)
                }

                // ---------- ✅/❌ হিসাব ----------
                "getStats" -> {
                    val sp = prefs()
                    val list = ArrayList<Int>()
                    list.add(sp.getInt("t_all", 0))
                    list.add(sp.getInt("h_all", 0))
                    for (tf in timeframes) {
                        list.add(sp.getInt("t_$tf", 0))
                        list.add(sp.getInt("h_$tf", 0))
                    }
                    result.success(list)
                }

                "resetStats" -> {
                    val ed = prefs().edit()
                    ed.remove("t_all")
                    ed.remove("h_all")
                    for (tf in timeframes) {
                        ed.remove("t_$tf")
                        ed.remove("h_$tf")
                    }
                    ed.apply()
                    result.success(null)
                }

                // ---------- সাজসজ্জা ----------
                "getUi" -> {
                    val sp = prefs()
                    result.success(
                        mapOf(
                            "btn_color" to (sp.getString("btn_color", "#8B5CF6") ?: "#8B5CF6"),
                            "btn_icon" to (sp.getString("btn_icon", "G") ?: "G"),
                            "btn_size" to sp.getInt("btn_size", 58),
                            "btn_alpha" to sp.getInt("btn_alpha", 100),
                            "card_pos" to (sp.getString("card_pos", "top") ?: "top"),
                            "card_alpha" to sp.getInt("card_alpha", 96),
                            "bg" to (sp.getString("bg", "aurora") ?: "aurora")
                        )
                    )
                }

                "setUi" -> {
                    val allowed = setOf(
                        "btn_color", "btn_icon", "btn_size", "btn_alpha",
                        "card_pos", "card_alpha", "bg"
                    )
                    val map = call.argument<Map<String, Any>>("ui")
                    if (map != null) {
                        val ed = prefs().edit()
                        for ((k, v) in map) {
                            if (k !in allowed) continue
                            when (v) {
                                is Int -> ed.putInt(k, v)
                                is String -> ed.putString(k, v)
                                else -> {}
                            }
                        }
                        ed.apply()
                        OverlayService.instance?.applyStyle()
                    }
                    result.success(null)
                }

                "resetUi" -> {
                    val ed = prefs().edit()
                    for (k in listOf(
                        "btn_color", "btn_icon", "btn_size", "btn_alpha",
                        "card_pos", "card_alpha", "bg"
                    )) {
                        ed.remove(k)
                    }
                    ed.apply()
                    OverlayService.instance?.applyStyle()
                    result.success(null)
                }

                // ---------- ফ্লোটিং বাটন চালু/বন্ধ ----------
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
