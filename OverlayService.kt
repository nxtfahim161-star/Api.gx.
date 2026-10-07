package com.example.gasi_candle_ai

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PixelFormat
import android.graphics.RectF
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Base64
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.core.content.FileProvider
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin

// ============================================================
// AI Prompt
// ============================================================
object AnalysisPrompt {
    const val TEXT = """
You are an advanced Hybrid Market Analyst AI.

You evaluate real-time chart screenshots by combining classical candlestick literature with current live market trends and sentiment data.

When a screenshot is received, execute the following steps:

1. TECHNICAL & BOOK KNOWLEDGE ANALYSIS

Identify candlestick patterns, wicks, body ratios, trend structure, and visible support/resistance levels strictly according to established classical candlestick and technical-analysis literature.

Analyze only information that is actually visible in the screenshot.

Where visible, consider: classical candlestick patterns, candle body size and body-to-range ratio, upper and lower wicks, bullish and bearish pressure, recent price action, trend direction, market structure, support and resistance, breakout or rejection, momentum, volume, and visible technical indicators.

Do not invent chart information that is not visible.

2. REAL-TIME MARKET CONTEXT & SENTIMENT

Identify the asset pair or financial instrument shown in the screenshot.

Use current or recent reliable information available to you to evaluate: current market sentiment, relevant financial news, relevant macroeconomic indicators, major market-moving events, current/recent market trends, and other important factors directly relevant to the identified asset.

Do not fabricate current news, sentiment, prices, macroeconomic information, or market events.

If current/recent market information is unavailable, do not guess it. Reflect the lack of live context in the final analysis.

3. WEIGHTED PROBABILITY CALCULATION

Combine the evidence using the following fixed weights:

Technical Analysis = 60%

Live Market Sentiment / News / Macro Context = 40%

The final UP and DOWN probabilities MUST be numeric values between 0 and 100 and add up to exactly 100.

The probabilities represent an analytical estimate, not certainty.

4. OUTPUT FORMAT

Return ONLY valid JSON.

Use EXACTLY this structure:

{
"up_probability_percent": 0,
"down_probability_percent": 0,
"technical_pattern": "Name of pattern",
"market_sentiment": "Bullish / Bearish / Neutral based on live context",
"summary_reason": "1-2 lines explaining how book rules and live market data led to this percentage."
}

STRICT OUTPUT RULES:

- Return ONLY the JSON object.
- Do not include Markdown.
- Do not include introductory text.
- Do not include explanations outside the JSON object.
- Do not include additional JSON fields.
- "up_probability_percent" and "down_probability_percent" MUST be numeric and MUST sum to exactly 100.
- "technical_pattern" must contain only a pattern supported by visible chart evidence.
- If no reliable classical pattern is visible, use "No clear classical pattern".
- "market_sentiment" MUST be exactly one of: "Bullish", "Bearish", "Neutral".
- If reliable live market context is unavailable, use "Neutral" rather than inventing a sentiment.
- "summary_reason" must be concise and limited to 1-2 lines.
- The final probabilities must reflect the combined 60% technical-analysis and 40% live-market-context methodology.
- Never fabricate information.
"""
}

// ============================================================
// Result UI (gauge + card)
// ============================================================
private val C_GREEN = Color.rgb(56, 217, 150)
private val C_RED = Color.rgb(255, 102, 133)
private val C_AMBER = Color.rgb(255, 180, 92)
private val C_LILAC = Color.rgb(192, 132, 252)

class GaugeView(context: Context, private val up: Float) : View(context) {

    private val d = resources.displayMetrics.density

    private val arc = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.BUTT
    }
    private val needle = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.ROUND
        color = Color.WHITE
    }
    private val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
    private val label = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textAlign = Paint.Align.CENTER
        typeface = Typeface.DEFAULT_BOLD
        textSize = 13 * d
    }

    override fun onMeasure(w: Int, h: Int) {
        val width = MeasureSpec.getSize(w)
        setMeasuredDimension(width, (width / 2f + 40 * d).toInt())
    }

    override fun onDraw(canvas: Canvas) {
        val stroke = 22 * d
        val pad = stroke / 2 + 14 * d
        val cx = width / 2f
        val radius = width / 2f - pad
        val cy = radius + pad
        val rect = RectF(cx - radius, cy - radius, cx + radius, cy + radius)

        arc.strokeWidth = stroke

        arc.color = Color.argb(30, 255, 255, 255)
        canvas.drawArc(rect, 180f, 180f, false, arc)

        val gap = 2.5f
        val upSweep = 180f * up / 100f
        val downSweep = 180f - upSweep

        if (upSweep > gap) {
            arc.color = C_GREEN
            val end = if (downSweep > gap) gap / 2 else 0f
            canvas.drawArc(rect, 180f, upSweep - end, false, arc)
        }
        if (downSweep > gap) {
            arc.color = C_RED
            val start = if (upSweep > gap) gap / 2 else 0f
            canvas.drawArc(rect, 180f + upSweep + start, downSweep - start, false, arc)
        }

        val angle = Math.toRadians((180f + upSweep).toDouble())
        val len = radius - stroke * 0.9f
        needle.strokeWidth = 4 * d
        canvas.drawLine(
            cx, cy,
            cx + (len * cos(angle)).toFloat(),
            cy + (len * sin(angle)).toFloat(),
            needle
        )
        fill.color = Color.WHITE
        canvas.drawCircle(cx, cy, 9 * d, fill)
        fill.color = Color.rgb(16, 13, 20)
        canvas.drawCircle(cx, cy, 4 * d, fill)

        val ly = cy + 26 * d
        label.color = C_GREEN
        canvas.drawText("UP", cx - radius, ly, label)
        label.color = C_RED
        canvas.drawText("DOWN", cx + radius, ly, label)
    }
}

object ResultCard {

    private fun dp(c: Context, v: Int) = (v * c.resources.displayMetrics.density).toInt()

    private fun pct(v: Double): String =
        if (v % 1.0 == 0.0) v.toInt().toString() else String.format("%.1f", v)

    private fun pill(c: Context, color: Int, alpha: Int): GradientDrawable =
        GradientDrawable().apply {
            cornerRadius = dp(c, 20).toFloat()
            setColor(Color.argb(alpha, Color.red(color), Color.green(color), Color.blue(color)))
            setStroke(
                dp(c, 1),
                Color.argb(110, Color.red(color), Color.green(color), Color.blue(color))
            )
        }

    private fun text(
        c: Context, s: String, size: Float, color: Int,
        bold: Boolean = false, center: Boolean = false
    ) = TextView(c).apply {
        text = s
        textSize = size
        setTextColor(color)
        if (bold) typeface = Typeface.DEFAULT_BOLD
        if (center) gravity = Gravity.CENTER
    }

    fun loading(c: Context): View {
        val tv = text(c, "AI চার্ট বিশ্লেষণ করছে…", 14f, Color.WHITE, bold = true, center = true)
        tv.setPadding(dp(c, 22), dp(c, 14), dp(c, 22), dp(c, 14))
        tv.background = GradientDrawable().apply {
            cornerRadius = dp(c, 30).toFloat()
            setColor(Color.argb(240, 20, 16, 28))
            setStroke(dp(c, 1), Color.argb(120, 139, 92, 246))
        }
        return tv
    }

    fun build(
        c: Context,
        up: Double,
        down: Double,
        pattern: String,
        sentiment: String,
        reason: String,
        onClose: () -> Unit
    ): View {
        val root = LinearLayout(c).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(c, 18), dp(c, 14), dp(c, 18), dp(c, 16))
            background = GradientDrawable().apply {
                cornerRadius = dp(c, 26).toFloat()
                setColor(Color.argb(246, 16, 13, 20))
                setStroke(dp(c, 1), Color.argb(90, 139, 92, 246))
            }
        }

        val header = LinearLayout(c).apply { gravity = Gravity.CENTER_VERTICAL }
        header.addView(
            text(c, "gasi candle analysis", 14f, C_LILAC, bold = true),
            LinearLayout.LayoutParams(0, -2, 1f)
        )
        val close = text(c, "✕", 18f, Color.argb(200, 255, 255, 255), center = true)
        close.setPadding(dp(c, 12), dp(c, 4), dp(c, 4), dp(c, 4))
        close.setOnClickListener { onClose() }
        header.addView(close, LinearLayout.LayoutParams(-2, -2))
        root.addView(header)

        root.addView(
            GaugeView(c, up.toFloat()),
            LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(c, 6) }
        )

        val isUp = up > down
        val isTie = up == down
        val verdictColor = when {
            isTie -> C_AMBER
            isUp -> C_GREEN
            else -> C_RED
        }
        val verdictText = when {
            isTie -> "সমান সম্ভাবনা"
            isUp -> "UP  ${pct(up)}%"
            else -> "DOWN  ${pct(down)}%"
        }
        root.addView(
            text(c, verdictText, 30f, verdictColor, bold = true, center = true),
            LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(c, 2) }
        )

        val row = LinearLayout(c).apply { orientation = LinearLayout.HORIZONTAL }
        val upPill = text(c, "Up: ${pct(up)}%", 15f, C_GREEN, bold = true, center = true)
        upPill.setPadding(0, dp(c, 8), 0, dp(c, 8))
        upPill.background = pill(c, C_GREEN, 36)
        val downPill = text(c, "Down: ${pct(down)}%", 15f, C_RED, bold = true, center = true)
        downPill.setPadding(0, dp(c, 8), 0, dp(c, 8))
        downPill.background = pill(c, C_RED, 36)
        row.addView(upPill, LinearLayout.LayoutParams(0, -2, 1f).apply { marginEnd = dp(c, 6) })
        row.addView(downPill, LinearLayout.LayoutParams(0, -2, 1f).apply { marginStart = dp(c, 6) })
        root.addView(row, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(c, 14) })

        val sentColor = when (sentiment) {
            "Bullish" -> C_GREEN
            "Bearish" -> C_RED
            else -> C_AMBER
        }
        val info = LinearLayout(c).apply { gravity = Gravity.CENTER_VERTICAL }
        info.addView(
            text(c, pattern, 14f, Color.WHITE, bold = true),
            LinearLayout.LayoutParams(0, -2, 1f)
        )
        val chip = text(c, sentiment, 12f, sentColor, bold = true, center = true)
        chip.setPadding(dp(c, 12), dp(c, 5), dp(c, 12), dp(c, 5))
        chip.background = pill(c, sentColor, 30)
        info.addView(chip, LinearLayout.LayoutParams(-2, -2))
        root.addView(info, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(c, 14) })

        val why = text(c, reason, 13f, Color.rgb(200, 195, 205))
        why.setLineSpacing(0f, 1.25f)
        root.addView(why, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(c, 8) })

        root.addView(
            text(c, "এটি অনুমান, নিশ্চিত ভবিষ্যদ্বাণী নয়।", 11f, Color.rgb(140, 133, 146)),
            LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(c, 10) }
        )

        return root
    }
}

// ============================================================
// Service
// ============================================================
class OverlayService : Service() {

    private lateinit var wm: WindowManager
    private val handler = Handler(Looper.getMainLooper())
    private var button: TextView? = null
    private var resultView: View? = null
    private var projection: MediaProjection? = null
    private var reader: ImageReader? = null
    private var display: VirtualDisplay? = null
    private var w = 0
    private var h = 0
    private var armed = false
    private var waiting = false
    private var token = 0

    private val model = "gemini-2.5-flash"

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        wm = getSystemService(WINDOW_SERVICE) as WindowManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startAsForeground()

        val code = intent?.getIntExtra("code", Int.MIN_VALUE) ?: Int.MIN_VALUE
        val data: Intent? = if (Build.VERSION.SDK_INT >= 33) {
            intent?.getParcelableExtra("data", Intent::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent?.getParcelableExtra("data")
        }

        if (data == null || code == Int.MIN_VALUE) {
            toast("Capture permission পাওয়া যায়নি")
            stopSelf()
            return START_NOT_STICKY
        }

        if (projection == null) {
            try {
                setupProjection(code, data)
            } catch (e: Exception) {
                toast("Capture শুরু হয়নি: " + (e.message ?: ""))
                stopSelf()
                return START_NOT_STICKY
            }
        }

        showButton()
        return START_NOT_STICKY
    }

    private fun startAsForeground() {
        val channelId = "gasi_overlay"
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        nm.createNotificationChannel(
            NotificationChannel(channelId, "Floating G", NotificationManager.IMPORTANCE_LOW)
        )
        val n = Notification.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setContentTitle("gasi candle analysis AI")
            .setContentText("Floating G চালু আছে")
            .setOngoing(true)
            .build()
        if (Build.VERSION.SDK_INT >= 29) {
            startForeground(1001, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
        } else {
            startForeground(1001, n)
        }
    }

    private fun setupProjection(code: Int, data: Intent) {
        val mpm = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val p = mpm.getMediaProjection(code, data)
        p.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() {
                handler.post { stopSelf() }
            }
        }, handler)
        projection = p

        val m = resources.displayMetrics
        if (Build.VERSION.SDK_INT >= 30) {
            val b = wm.maximumWindowMetrics.bounds
            w = b.width()
            h = b.height()
        } else {
            w = m.widthPixels
            h = m.heightPixels
        }

        val r = ImageReader.newInstance(w, h, PixelFormat.RGBA_8888, 2)
        r.setOnImageAvailableListener({ rd ->
            val img = rd.acquireLatestImage()
            if (img != null) {
                if (armed) {
                    armed = false
                    try {
                        handleImage(img)
                    } finally {
                        img.close()
                    }
                } else {
                    img.close()
                }
            }
        }, handler)
        reader = r

        display = p.createVirtualDisplay(
            "gasi", w, h, m.densityDpi,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            r.surface, null, handler
        )
    }

    private fun capture() {
        if (waiting) return
        waiting = true
        val my = ++token
        // আগের রেজাল্ট কার্ড স্ক্রিনশটে যেন না আসে
        clearResult()
        button?.visibility = View.INVISIBLE
        handler.postDelayed({
            if (my == token && waiting) armed = true
        }, 250)
        handler.postDelayed({
            if (my == token && waiting) {
                armed = false
                waiting = false
                button?.visibility = View.VISIBLE
                toast("Screenshot নেওয়া যায়নি, আবার চাপুন")
            }
        }, 2500)
    }

    private fun handleImage(image: Image) {
        var shareFile: File? = null
        try {
            val plane = image.planes[0]
            val pixelStride = plane.pixelStride
            val rowStride = plane.rowStride
            val rowPadding = rowStride - pixelStride * w

            val full = Bitmap.createBitmap(
                w + rowPadding / pixelStride, h, Bitmap.Config.ARGB_8888
            )
            full.copyPixelsFromBuffer(plane.buffer)
            val bmp = Bitmap.createBitmap(full, 0, 0, w, h)
            if (bmp !== full) full.recycle()

            val dir = File(cacheDir, "captures")
            dir.mkdirs()
            dir.listFiles()?.forEach { it.delete() }
            val file = File(dir, "chart_" + System.currentTimeMillis() + ".jpg")
            FileOutputStream(file).use { out ->
                bmp.compress(Bitmap.CompressFormat.JPEG, 80, out)
            }
            bmp.recycle()
            shareFile = file
        } catch (e: Exception) {
            toast("Screenshot error: " + (e.message ?: ""))
        } finally {
            waiting = false
            button?.visibility = View.VISIBLE
        }
        shareFile?.let { analyze(it) }
    }

    // ---------- AI call (Gemini) ----------
    private fun analyze(file: File) {
        val key = getSharedPreferences("gasi", MODE_PRIVATE)
            .getString("key", "") ?: ""
        if (key.isEmpty()) {
            toast("API key সেট করা নেই, Share খুলছে")
            share(file)
            return
        }

        showLoading()

        thread {
            try {
                val b64 = Base64.encodeToString(file.readBytes(), Base64.NO_WRAP)
                val body = JSONObject()
                    .put(
                        "contents", JSONArray().put(
                            JSONObject().put(
                                "parts", JSONArray()
                                    .put(JSONObject().put("text", AnalysisPrompt.TEXT.trimIndent()))
                                    .put(
                                        JSONObject().put(
                                            "inline_data", JSONObject()
                                                .put("mime_type", "image/jpeg")
                                                .put("data", b64)
                                        )
                                    )
                            )
                        )
                    )
                    .put(
                        "tools", JSONArray().put(
                            JSONObject().put("google_search", JSONObject())
                        )
                    )

                val c = URL(
                    "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent"
                ).openConnection() as HttpURLConnection
                c.requestMethod = "POST"
                c.connectTimeout = 20000
                c.readTimeout = 90000
                c.doOutput = true
                c.setRequestProperty("Content-Type", "application/json")
                c.setRequestProperty("x-goog-api-key", key)
                c.outputStream.use { it.write(body.toString().toByteArray()) }

                val ok = c.responseCode in 200..299
                val resp = (if (ok) c.inputStream else c.errorStream)
                    .bufferedReader().readText()
                if (!ok) {
                    handler.post { clearResult() }
                    toast("API error " + c.responseCode)
                    return@thread
                }

                val parts = JSONObject(resp).getJSONArray("candidates")
                    .getJSONObject(0).getJSONObject("content").getJSONArray("parts")
                val sb = StringBuilder()
                for (i in 0 until parts.length()) {
                    sb.append(parts.getJSONObject(i).optString("text"))
                }
                val raw = sb.toString()
                val j = JSONObject(raw.substring(raw.indexOf('{'), raw.lastIndexOf('}') + 1))

                var up = j.getDouble("up_probability_percent")
                var down = j.getDouble("down_probability_percent")
                val total = up + down
                if (total > 0 && abs(total - 100.0) > 0.1) {
                    up = up / total * 100.0
                    down = 100.0 - up
                }
                val pattern = j.optString("technical_pattern", "No clear classical pattern")
                val sent = j.optString("market_sentiment", "Neutral")
                val why = j.optString("summary_reason", "")

                handler.post { showResult(up, down, pattern, sent, why) }
            } catch (e: Exception) {
                handler.post { clearResult() }
                toast("AI error: " + (e.message ?: ""))
            }
        }
    }

    // ---------- Share fallback (key না থাকলে) ----------
    private fun share(file: File) {
        try {
            val uri = FileProvider.getUriForFile(
                this, packageName + ".fileprovider", file
            )
            val send = Intent(Intent.ACTION_SEND)
            send.type = "image/jpeg"
            send.putExtra(Intent.EXTRA_STREAM, uri)
            send.putExtra(Intent.EXTRA_TEXT, AnalysisPrompt.TEXT.trimIndent())
            send.clipData = ClipData.newRawUri("chart", uri)
            send.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

            val chooser = Intent.createChooser(send, "AI app বেছে নিন")
            chooser.addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
            startActivity(chooser)
        } catch (e: Exception) {
            toast("Share করা যায়নি: " + (e.message ?: ""))
        }
    }

    // ---------- Result overlay ----------
    private fun showLoading() {
        clearResult()
        val v = ResultCard.loading(this)
        val lp = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )
        lp.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
        lp.y = 120
        wm.addView(v, lp)
        resultView = v
    }

    private fun showResult(
        up: Double, down: Double, pattern: String, sent: String, why: String
    ) {
        clearResult()
        val card = ResultCard.build(this, up, down, pattern, sent, why) { clearResult() }
        val lp = WindowManager.LayoutParams(
            (resources.displayMetrics.widthPixels * 0.92).toInt(),
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )
        lp.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
        lp.y = 100
        wm.addView(card, lp)
        resultView = card
    }

    private fun clearResult() {
        resultView?.let {
            try {
                wm.removeView(it)
            } catch (_: Exception) {
            }
        }
        resultView = null
    }

    // ---------- Floating G button ----------
    private fun showButton() {
        if (button != null) return

        val size = (58 * resources.displayMetrics.density).toInt()
        val bg = GradientDrawable()
        bg.shape = GradientDrawable.OVAL
        bg.setColor(Color.rgb(139, 92, 246))

        val tv = TextView(this)
        tv.text = "G"
        tv.textSize = 22f
        tv.setTextColor(Color.WHITE)
        tv.gravity = Gravity.CENTER
        tv.background = bg

        val lp = WindowManager.LayoutParams(
            size, size,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )
        lp.gravity = Gravity.TOP or Gravity.START
        lp.x = 30
        lp.y = 300

        var startX = 0
        var startY = 0
        var touchX = 0f
        var touchY = 0f

        tv.setOnTouchListener { v, e ->
            when (e.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    startX = lp.x
                    startY = lp.y
                    touchX = e.rawX
                    touchY = e.rawY
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    lp.x = startX + (e.rawX - touchX).toInt()
                    lp.y = startY + (e.rawY - touchY).toInt()
                    wm.updateViewLayout(v, lp)
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (abs(e.rawX - touchX) < 15 && abs(e.rawY - touchY) < 15) {
                        capture()
                    }
                    true
                }
                else -> false
            }
        }

        wm.addView(tv, lp)
        button = tv
    }

    private fun toast(msg: String) {
        handler.post {
            Toast.makeText(applicationContext, msg, Toast.LENGTH_SHORT).show()
        }
    }

    override fun onDestroy() {
        clearResult()
        button?.let {
            try {
                wm.removeView(it)
            } catch (_: Exception) {
            }
        }
        button = null
        try { display?.release() } catch (_: Exception) {}
        try { reader?.close() } catch (_: Exception) {}
        try { projection?.stop() } catch (_: Exception) {}
        display = null
        reader = null
        projection = null
        super.onDestroy()
    }
}
