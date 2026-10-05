package com.example.gasi_candle_ai

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
}package com.example.gasi_candle_ai

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.ClipData
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.PixelFormat
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
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import android.widget.Toast
import androidx.core.content.FileProvider
import java.io.File
import java.io.FileOutputStream
import kotlin.math.abs

class OverlayService : Service() {

    private lateinit var wm: WindowManager
    private val handler = Handler(Looper.getMainLooper())

    private var button: TextView? = null
    private var projection: MediaProjection? = null
    private var reader: ImageReader? = null
    private var display: VirtualDisplay? = null

    private var w = 0
    private var h = 0
    private var armed = false
    private var waiting = false
    private var token = 0

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
            val file = File(dir, "chart_" + System.currentTimeMillis() + ".png")
            FileOutputStream(file).use { out ->
                bmp.compress(Bitmap.CompressFormat.PNG, 100, out)
            }
            bmp.recycle()
            shareFile = file
        } catch (e: Exception) {
            toast("Screenshot error: " + (e.message ?: ""))
        } finally {
            waiting = false
            button?.visibility = View.VISIBLE
        }

        shareFile?.let { share(it) }
    }

    private fun share(file: File) {
        try {
            val uri = FileProvider.getUriForFile(
                this, packageName + ".fileprovider", file
            )
            val send = Intent(Intent.ACTION_SEND)
            send.type = "image/png"
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
