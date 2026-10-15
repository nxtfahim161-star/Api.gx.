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

                // ---------- ইন্টারনেট আছে কিনা ----------
                "hasInternet" -> {
                    Thread {
                        var ok = false
                        val urls = listOf(
                            "https://www.google.com/generate_204",
                            "https://generativelanguage.googleapis.com/"
                        )
                        for (u in urls) {
                            try {
                                val c = java.net.URL(u).openConnection() as java.net.HttpURLConnection
                                c.connectTimeout = 4000
                                c.readTimeout = 4000
                                c.requestMethod = "GET"
                                val code = c.responseCode
                                c.disconnect()
                                if (code in 200..499) {
                                    ok = true
                                    break
                                }
                            } catch (e: Exception) {
                            }
                        }
                        runOnUiThread { result.success(ok) }
                    }.start()
                }

                // ---------- প্রথমবারের ধাপ (চুক্তি, key) ----------
                "getFlags" -> {
                    val p = prefs()
                    val hasKey = Keys.gemini(this).isNotEmpty()
                    result.success(
                        mapOf(
                            "agreed" to p.getBoolean("agreed", false),
                            "manual_seen" to p.getBoolean("manual_seen", false),
                            "setup_done" to (p.getBoolean("setup_done", false) || hasKey),
                            "lang" to (p.getString("lang", "bn") ?: "bn")
                        )
                    )
                }

                "saveFlag" -> {
                    val name = call.argument<String>("name") ?: ""
                    val value = call.argument<Boolean>("value") ?: true
                    if (name == "agreed" || name == "setup_done" || name == "manual_seen") {
                        prefs().edit().putBoolean(name, value).apply()
                    }
                    result.success(null)
                }

                "saveLang" -> {
                    val l = call.argument<String>("lang") ?: "bn"
                    prefs().edit().putString("lang", if (l == "en") "en" else "bn").apply()
                    result.success(null)
                }

                // ---------- API key ----------
                "hasApiKey" -> result.success(Keys.gemini(this).isNotEmpty())

                // key-র অবস্থা: নিজের দেওয়া (custom) নাকি বিল্ট-ইন ডিফল্ট
                "getKeyInfo" -> {
                    val p = prefs()
                    result.success(
                        mapOf(
                            "gemini_custom" to (p.getString("key", "") ?: "").isNotEmpty(),
                            "gemini_any" to Keys.gemini(this).isNotEmpty(),
                            "td_custom" to (p.getString("td_key", "") ?: "").isNotEmpty(),
                            "td_any" to Keys.twelve(this).isNotEmpty()
                        )
                    )
                }

                "resetApiKey" -> {
                    prefs().edit().remove("key").apply()
                    result.success(null)
                }

                "resetTdKey" -> {
                    prefs().edit().remove("td_key").apply()
                    result.success(null)
                }

                "saveApiKey" -> {
                    val k = call.argument<String>("key") ?: ""
                    prefs().edit().putString("key", k.trim()).apply()
                    result.success(null)
                }

                "hasTdKey" -> result.success(Keys.twelve(this).isNotEmpty())
                
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
                    Store.resetOutcomes(this)
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

                // ---------- ইতিহাস ----------
                "getHistory" -> result.success(Store.readHistory(this).toString())

                "markHistory" -> {
                    val id = (call.argument<Any>("id") as? Number)?.toLong() ?: 0L
                    val hit = call.argument<Boolean>("hit") ?: false
                    Store.setOutcome(this, id, hit)
                    result.success(null)
                }

                "clearHistory" -> {
                    Store.clearHistory(this)
                    result.success(null)
                }

                "isRunning" -> result.success(OverlayService.instance != null)

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
