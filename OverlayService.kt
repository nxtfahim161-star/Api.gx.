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
You are a disciplined short-term chart analyst. Accuracy and honesty matter more than sounding confident. A wrong confident answer is worse than an honest uncertain one.

STEP 1 - READ THE CHART (use only what is visible)
- Identify the asset and the chart timeframe if they are shown.
- Look at the most recent 10 to 20 candles: overall trend (up, down or sideways), the size of the last 3 to 5 candles, and their wicks.
- Mark the nearest visible support and resistance, and where the current price sits relative to them.
- Note any visible indicator (moving averages, RSI, MACD, Bollinger Bands, volume) and what it says.
- If the image is not a price chart, or the candles are too small or unclear to read, do not guess: use 50 and 50, pattern "No clear classical pattern", sentiment "Neutral", and say the chart is unclear in the reason.

STEP 2 - JUDGE THE NEXT MOVE
Weigh these signals, strongest first:
1. Direction and strength of the last 3 to 5 candles (momentum).
2. Trend context: is the latest move with the trend or a pullback against it?
3. Price at or near support or resistance: rejection wicks, a breakout with a strong close, or a failed breakout.
4. A classical candlestick pattern only if it appears at a meaningful location. Never force a pattern.
5. Visible indicators, as confirmation only.

STEP 3 - CHECK THE LIVE MARKET (search is mandatory)
Before answering you MUST use the Google Search tool to check the current state of the market for the asset shown in the chart. Search for things like: the asset's news today, today's price trend, central bank or economic data releases, and any major event scheduled within the next hour. Then combine what you found with your technical reading and with your knowledge of classical candlestick and technical analysis literature.
Technical evidence carries about 70 percent of the decision. Live market context carries about 30 percent.
If the search returns nothing useful, or no major event is near, use "Neutral" for market_sentiment and do not invent context. Never invent news.

STEP 4 - CALIBRATE (very important)
- Short-term price moves are noisy. Stay modest: normally keep each side between 30 and 70.
- Go above 70 only when at least three independent signals agree (momentum, trend, level, pattern or indicator). Never exceed 80.
- If signals conflict, or the chart is choppy or sideways, stay between 45 and 55.
- Do not simply follow the colour of the last candle. Check for exhaustion, long opposing wicks and nearby levels before following momentum.

OUTPUT FORMAT
Return ONLY this JSON object and nothing else:

{
"up_probability_percent": 0,
"down_probability_percent": 0,
"technical_pattern": "Name of pattern",
"market_sentiment": "Bullish / Bearish / Neutral",
"summary_reason": "1-2 short lines naming the actual evidence you saw (chart evidence, plus the most relevant live market factor if you found one)."
}

STRICT RULES
- No Markdown, no text before or after the JSON, no extra fields.
- up_probability_percent and down_probability_percent are numbers and add up to exactly 100.
- technical_pattern: only a pattern supported by visible evidence, otherwise "No clear classical pattern".
- market_sentiment is exactly one of "Bullish", "Bearish", "Neutral". If live context is unavailable, use "Neutral".
- summary_reason must refer to what is really visible on this chart (for example the last candles, a level, a wick), not generic statements.
- Never fabricate prices, news or indicators that are not visible or verifiable.
"""
}

// ============================================================
// Result UI (gauge + card)
// ============================================================
private val C_GREEN = Color.rgb(56, 217, 150)
private val C_RED = Color.rgb(255, 102, 133)
private val C_AMBER = Color.rgb(255, 180, 92)
private val C_LILAC = Color.rgb(192, 132, 252)

private fun fmtPct(v: Float): String =
    if (v % 1f == 0f) v.toInt().toString() else String.format("%.1f", v)

/** ছবির মতো গেজ: বামে সবুজ, ডানে লাল, ধূসর কাঁটা, কালো UP/down লেবেল, গোলাপি % পিল। */
class GaugeView(
    context: Context,
    private val up: Float,
    private val down: Float
) : View(context) {

    private val d = resources.displayMetrics.density
    private val pink = Color.rgb(252, 190, 212)

    private val arc = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.BUTT
    }
    private val needle = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.ROUND
        color = Color.rgb(205, 205, 205)
    }
    private val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
    private val txt = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textAlign = Paint.Align.CENTER
        typeface = Typeface.DEFAULT_BOLD
        strokeJoin = Paint.Join.ROUND
    }

    private fun radiusFor(width: Int) = width * 0.38f
    private fun strokeFor() = 26 * d

    override fun onMeasure(w: Int, h: Int) {
        val width = MeasureSpec.getSize(w)
        val r = radiusFor(width)
        val cy = r + strokeFor() / 2 + 40 * d
        val height = cy + 0.5f * r + strokeFor() / 2 + 52 * d
        setMeasuredDimension(width, height.toInt())
    }

    private fun pill(
        canvas: Canvas, text: String, left: Float, top: Float,
        bg: Int, size: Float, outlined: Boolean
    ) {
        txt.textSize = size
        val tw = txt.measureText(text)
        val padH = 12 * d
        val ph = size + 14 * d
        val rect = RectF(left, top, left + tw + padH * 2, top + ph)
        fill.color = bg
        canvas.drawRoundRect(rect, 12 * d, 12 * d, fill)
        val bx = rect.centerX()
        val by = rect.centerY() + size * 0.35f
        if (outlined) {
            txt.style = Paint.Style.STROKE
            txt.strokeWidth = 4 * d
            txt.color = Color.BLACK
            canvas.drawText(text, bx, by, txt)
        }
        txt.style = Paint.Style.FILL
        txt.color = Color.WHITE
        canvas.drawText(text, bx, by, txt)
    }

    private fun pillWidth(text: String, size: Float): Float {
        txt.textSize = size
        return txt.measureText(text) + 24 * d
    }

    override fun onDraw(canvas: Canvas) {
        val stroke = strokeFor()
        val r = radiusFor(width)
        val cx = width / 2f
        val cy = r + stroke / 2 + 40 * d
        val rect = RectF(cx - r, cy - r, cx + r, cy + r)

        val start = 150f
        val total = 240f
        val upSweep = total * up / 100f
        val downSweep = total - upSweep
        val gap = 2.5f

        arc.strokeWidth = stroke
        arc.color = Color.argb(30, 255, 255, 255)
        canvas.drawArc(rect, start, total, false, arc)

        if (upSweep > gap) {
            arc.color = C_GREEN
            val end = if (downSweep > gap) gap / 2 else 0f
            canvas.drawArc(rect, start, upSweep - end, false, arc)
        }
        if (downSweep > gap) {
            arc.color = C_RED
            val s = if (upSweep > gap) gap / 2 else 0f
            canvas.drawArc(rect, start + upSweep + s, downSweep - s, false, arc)
        }

        // কাঁটা
        val angle = Math.toRadians((start + upSweep).toDouble())
        val len = r * 0.62f
        needle.strokeWidth = 11 * d
        canvas.drawLine(
            cx, cy,
            cx + (len * cos(angle)).toFloat(),
            cy + (len * sin(angle)).toFloat(),
            needle
        )
        fill.color = Color.rgb(205, 205, 205)
        canvas.drawCircle(cx, cy, 8 * d, fill)

        // মাঝের বড় সংখ্যা
        val isUp = up > down
        val big = if (up == down) "50%" else fmtPct(if (isUp) up else down) + "%"
        val caption = if (up == down) "সমান" else if (isUp) "UP" else "DOWN"
        txt.style = Paint.Style.FILL
        txt.textSize = 30 * d
        txt.color = Color.WHITE
        canvas.drawText(big, cx, cy + r * 0.42f + 12 * d, txt)
        txt.textSize = 13 * d
        txt.color = if (up == down) C_AMBER else if (isUp) C_GREEN else C_RED
        canvas.drawText(caption, cx, cy + r * 0.42f + 32 * d, txt)

        // কালো লেবেল: UP (বামে), down (ডানে)
        val ls = 20 * d
        pill(canvas, "UP", 4 * d, 4 * d, Color.BLACK, ls, false)
        val dw = pillWidth("down", ls)
        pill(canvas, "down", width - dw - 4 * d, 4 * d, Color.BLACK, ls, false)

        // গোলাপি পিল: Up:30% / down:70%
        val ps = 17 * d
        val upT = "Up:" + fmtPct(up) + "%"
        val dnT = "down:" + fmtPct(down) + "%"
        val py = height - (ps + 14 * d) - 4 * d
        pill(canvas, upT, 4 * d, py, pink, ps, true)
        val dnW = pillWidth(dnT, ps)
        pill(canvas, dnT, width - dnW - 4 * d, py, pink, ps, true)
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
        web: Boolean,
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

        val webColor = if (web) C_GREEN else C_AMBER
        val webChip = text(
            c,
            if (web) "🌐 ওয়েব ও বইয়ের জ্ঞান মিলিয়ে" else "📖 শুধু চার্ট ও বইয়ের জ্ঞান",
            11f, webColor, bold = true
        )
        webChip.setPadding(dp(c, 10), dp(c, 4), dp(c, 10), dp(c, 4))
        webChip.background = pill(c, webColor, 28)
        root.addView(webChip, LinearLayout.LayoutParams(-2, -2).apply { topMargin = dp(c, 2) })

        root.addView(
            GaugeView(c, up.toFloat(), down.toFloat()),
            LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(c, 6) }
        )

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

    // 404 এলে পরের মডেল চেষ্টা করবে
    private val models = listOf("gemini-flash-latest", "gemini-3.5-flash", "gemini-3-flash-preview")

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
    private fun callGemini(key: String, b64: String, withSearch: Boolean, m: String): Pair<Int, String> {
        val minutes = getSharedPreferences("gasi", MODE_PRIVATE).getInt("minutes", 5)
        val prompt = AnalysisPrompt.TEXT.trimIndent() +
            "\n\nFORECAST HORIZON: The UP and DOWN probabilities must describe the price " +
            "direction over the NEXT " + minutes + " MINUTE" + (if (minutes == 1) "" else "S") +
            " from the latest candle in the screenshot. The chart's own timeframe may differ; " +
            "still answer only for this horizon."
        val parts = JSONArray()
            .put(JSONObject().put("text", prompt))
            .put(
                JSONObject().put(
                    "inline_data", JSONObject()
                        .put("mime_type", "image/jpeg")
                        .put("data", b64)
                )
            )
        val body = JSONObject()
            .put("contents", JSONArray().put(JSONObject().put("parts", parts)))
        if (withSearch) {
            body.put(
                "tools", JSONArray().put(JSONObject().put("google_search", JSONObject()))
            )
        }
        val c = URL(
            "https://generativelanguage.googleapis.com/v1beta/models/$m:generateContent"
        ).openConnection() as HttpURLConnection
        c.requestMethod = "POST"
        c.connectTimeout = 20000
        c.readTimeout = 90000
        c.doOutput = true
        c.setRequestProperty("Content-Type", "application/json")
        c.setRequestProperty("x-goog-api-key", key)
        c.outputStream.use { it.write(body.toString().toByteArray()) }
        val code = c.responseCode
        val ok = code in 200..299
        val text = (if (ok) c.inputStream else c.errorStream)
            ?.bufferedReader()?.readText() ?: ""
        return Pair(code, text)
    }

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

                // প্রথমে Google Search সহ, না হলে search ছাড়া আবার চেষ্টা
                var r = Pair(0, "")
                var searched = true
                for (m in models) {
                    searched = true
                    r = callGemini(key, b64, true, m)
                    if (r.first !in 200..299) {
                        searched = false
                        r = callGemini(key, b64, false, m)
                    }
                    if (r.first != 404) break
                }

                if (r.first !in 200..299) {
                    var m = ""
                    try {
                        m = JSONObject(r.second).getJSONObject("error").getString("message")
                    } catch (_: Exception) {
                    }
                    handler.post { clearResult() }
                    toast("API " + r.first + ": " + m.take(160), true)
                    return@thread
                }

                val cands = JSONObject(r.second).optJSONArray("candidates")
                if (cands == null || cands.length() == 0) {
                    handler.post { clearResult() }
                    toast("AI উত্তর দেয়নি (ছবি ব্লক হতে পারে)", true)
                    return@thread
                }
                val gm = cands.getJSONObject(0).optJSONObject("groundingMetadata")
                val queries = gm?.optJSONArray("webSearchQueries")
                val web = searched && queries != null && queries.length() > 0
                val parts = cands.getJSONObject(0)
                    .getJSONObject("content").getJSONArray("parts")
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

                handler.post { showResult(up, down, pattern, sent, why, web) }
            } catch (e: Exception) {
                handler.post { clearResult() }
                toast("AI error: " + (e.message ?: ""), true)
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
        up: Double, down: Double, pattern: String, sent: String, why: String, web: Boolean
    ) {
        clearResult()
        val card = ResultCard.build(this, up, down, pattern, sent, why, web) { clearResult() }
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

    private fun toast(msg: String, long: Boolean = false) {
        handler.post {
            Toast.makeText(
                applicationContext, msg,
                if (long) Toast.LENGTH_LONG else Toast.LENGTH_SHORT
            ).show()
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
