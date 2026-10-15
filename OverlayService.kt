package com.example.gasi_candle_ai

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
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
import android.view.HapticFeedbackConstants
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
import java.net.URLEncoder
import java.util.Locale
import kotlin.concurrent.thread
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

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

STEP 3 - USE THE LIVE MARKET BRIEF
A LIVE MARKET BRIEF gathered from Google Search may be provided at the end of this message. If it is provided, use it as the live market context: the asset's news today, price trend, upcoming events and sentiment. Combine it with your technical reading and with your knowledge of classical candlestick and technical analysis literature.
Technical evidence carries about 70 percent of the decision. Live market context carries about 30 percent.
If the brief says "unavailable" or contains nothing notable, use "Neutral" for market_sentiment. If no brief is provided at all, search the web yourself if you are able to; if you cannot, use "Neutral". Never invent news.

STEP 4 - CALIBRATE (very important)
- Short-term price moves are noisy. Stay modest: normally keep each side between 30 and 70.
- Go above 70 only when at least three independent signals agree (momentum, trend, level, pattern or indicator). Never exceed 80.
- If signals conflict, or the chart is choppy or sideways, stay between 45 and 55.
- Do not simply follow the colour of the last candle. Check for exhaustion, long opposing wicks and nearby levels before following momentum.

SPEED
Respond quickly. Do not write long reasoning or explanations. Keep summary_reason to one short sentence (under 25 words). Output the JSON immediately.

OUTPUT FORMAT
Return ONLY this JSON object and nothing else:

{
"up_probability_percent": 0,
"down_probability_percent": 0,
"technical_pattern": "Name of pattern",
"market_sentiment": "Bullish / Bearish / Neutral",
"summary_reason": "One short sentence (under 25 words) naming the actual evidence you saw.",
"high_impact_news_soon": false,
"payout_percent": null,
"chart_timeframe_minutes": null,
"asset_name": null
}

STRICT RULES
- No Markdown, no text before or after the JSON, no extra fields.
- up_probability_percent and down_probability_percent are numbers and add up to exactly 100.
- technical_pattern: only a pattern supported by visible evidence, otherwise "No clear classical pattern".
- market_sentiment is exactly one of "Bullish", "Bearish", "Neutral". If live context is unavailable, use "Neutral".
- summary_reason must refer to what is really visible on this chart (for example the last candles, a level, a wick), not generic statements.
- high_impact_news_soon is a boolean: true only if the LIVE MARKET BRIEF names a major scheduled or breaking event inside the forecast window (or within the next hour if the window is shorter than an hour), otherwise false.
- asset_name is the instrument name shown on the screen (the pair or ticker, including the OTC label if it is written), or null if it is not visible. Never guess it.
- chart_timeframe_minutes is the candle timeframe of the screenshot chart as a number of minutes (for example 1, 5, 15, 60), or null if it is not visible. Never guess it.
- payout_percent is the payout percentage shown on the screen for the traded asset (for example 93), or null if it is not visible. Never guess it.
- Never fabricate prices, news or indicators that are not visible or verifiable.
"""

    const val DETECT = """
Look at this trading chart screenshot and identify what is being traded. Return ONLY this JSON object:
{"asset": "<symbol as displayed>", "market": "<one market value>", "timeframe_minutes": <number>}
Rules:
- asset: the symbol exactly as displayed on the screen, written as BASE/QUOTE for crypto and forex pairs, or as the ticker for stocks.
- market: exactly one of "crypto", "forex", "stock", "otc", "unknown". Use "otc" if the name contains OTC or the instrument is shown as an OTC or synthetic pair. Use "unknown" if you cannot read it.
- timeframe_minutes: the candle timeframe of the chart as a number of minutes (1, 5, 15, 30 or 60) if visible, otherwise 0.
No other text.
"""

    const val RESEARCH_ASSET = """
Use Google Search to research the CURRENT market for the asset named at the end: the latest news today, today's price trend, scheduled economic data or central bank events within the next hour, and the overall market sentiment.
Reply in plain text only, maximum 80 words, in exactly this layout (be fast):
ASSET: ...
NEWS AND TREND: ...
UPCOMING EVENTS: ...
LIVE SENTIMENT: Bullish / Bearish / Neutral
Do not predict the price. Do not invent anything. If you find nothing notable, write "nothing notable" for that line.
"""

    const val RESEARCH = """
Look at this trading chart screenshot.
1) Identify the asset or currency pair and the chart timeframe.
2) Use Google Search to research the CURRENT market for that asset: the latest news today, today's price trend, scheduled economic data or central bank events within the next hour, and the overall market sentiment.
3) Reply in plain text only, maximum 80 words, in exactly this layout (be fast):
ASSET: ...
NEWS AND TREND: ...
UPCOMING EVENTS: ...
LIVE SENTIMENT: Bullish / Bearish / Neutral
Do not predict the price. Do not invent anything. If you find nothing notable, write "nothing notable" for that line.
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
        val caption = if (up == down) tr(context, "সমান", "TIE") else if (isUp) "UP" else "DOWN"
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

// পূর্বাভাসের সময়ের নাম (প্রম্পটের জন্য) ও বাংলা নাম
fun horizonLabel(m: Int): String {
    if (m >= 60 && m % 60 == 0) {
        val h = m / 60
        return h.toString() + (if (h == 1) " HOUR" else " HOURS")
    }
    return m.toString() + (if (m == 1) " MINUTE" else " MINUTES")
}

// ভাষা বাছাই (অ্যাপের সেটিংস থেকে): "bn" = বাংলা, "en" = English
fun tr(ctx: Context, bn: String, en: String): String {
    val l = ctx.getSharedPreferences("gasi", Context.MODE_PRIVATE).getString("lang", "bn")
    return if (l == "en") en else bn
}

fun tfLabel(ctx: Context, m: Int): String {
    if (m >= 60 && m % 60 == 0) {
        val h = m / 60
        return tr(ctx, h.toString() + " ঘণ্টা", h.toString() + (if (h == 1) " hour" else " hours"))
    }
    return tr(ctx, m.toString() + " মিনিট", m.toString() + (if (m == 1) " minute" else " minutes"))
}

// আসল ডাটার জন্য পূর্বাভাসের সময় অনুযায়ী ক্যান্ডেলের আকার
fun candleTfFor(m: Int): Int = when {
    m <= 5 -> 1
    m <= 15 -> 5
    m <= 60 -> 15
    else -> 60
}

// ============================================================
// আসল বাজারের ক্যান্ডেল ডাটা + ইন্ডিকেটর হিসাব
// ============================================================
class Candle(val o: Double, val h: Double, val l: Double, val c: Double)

object MarketData {

    private fun httpGet(url: String): String? {
        return try {
            val con = URL(url).openConnection() as HttpURLConnection
            con.connectTimeout = 8000
            con.readTimeout = 8000
            if (con.responseCode in 200..299) {
                con.inputStream.bufferedReader().readText()
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }
    
    // ক্রিপ্টো: Binance (key লাগে না) | ফরেক্স/স্টক: Twelve Data (key লাগে)
    fun fetch(market: String, asset: String, minutes: Int, tdKey: String): List<Candle>? {
        return try {
            val raw = asset.uppercase().replace(" ", "")
            val out = ArrayList<Candle>()
            if (market == "crypto") {
                var pair = raw.replace("/", "").replace("-", "")
                if (pair.endsWith("USD") && !pair.endsWith("BUSD")) pair += "T"
                val iv = when (minutes) {
                    1 -> "1m"
                    5 -> "5m"
                    15 -> "15m"
                    30 -> "30m"
                    60 -> "1h"
                    else -> "5m"
                }
                val q = "/api/v3/klines?symbol=" + pair + "&interval=" + iv + "&limit=120"
                val body = httpGet("https://data-api.binance.vision" + q)
                    ?: httpGet("https://api.binance.com" + q)
                    ?: return null
                val arr = JSONArray(body)
                for (i in 0 until arr.length()) {
                    val k = arr.getJSONArray(i)
                    out.add(
                        Candle(
                            k.getString(1).toDouble(), k.getString(2).toDouble(),
                            k.getString(3).toDouble(), k.getString(4).toDouble()
                        )
                    )
                }
            } else {
                var sym = raw
                if (market == "forex" && !sym.contains("/") && sym.length == 6) {
                    sym = sym.substring(0, 3) + "/" + sym.substring(3)
                }
                val iv = when (minutes) {
                    1 -> "1min"
                    5 -> "5min"
                    15 -> "15min"
                    30 -> "30min"
                    60 -> "1h"
                    else -> "5min"
                }
                val url = "https://api.twelvedata.com/time_series?symbol=" +
                    URLEncoder.encode(sym, "UTF-8") + "&interval=" + iv +
                    "&outputsize=120&apikey=" + tdKey
                val body = httpGet(url) ?: return null
                val vals = JSONObject(body).optJSONArray("values") ?: return null
                for (i in vals.length() - 1 downTo 0) {
                    val v = vals.getJSONObject(i)
                    out.add(
                        Candle(
                            v.getString("open").toDouble(), v.getString("high").toDouble(),
                            v.getString("low").toDouble(), v.getString("close").toDouble()
                        )
                    )
                }
            }
            if (out.size >= 40) out else null
        } catch (e: Exception) {
            null
        }
    }

    private fun ema(v: List<Double>, p: Int): List<Double> {
        val k = 2.0 / (p + 1)
        val out = ArrayList<Double>()
        var e = v[0]
        for (x in v) {
            e = x * k + e * (1 - k)
            out.add(e)
        }
        return out
    }

    private fun rsi(v: List<Double>, p: Int): Double {
        var g = 0.0
        var l = 0.0
        for (i in 1..p) {
            val d = v[i] - v[i - 1]
            if (d >= 0) g += d else l -= d
        }
        g /= p
        l /= p
        for (i in p + 1 until v.size) {
            val d = v[i] - v[i - 1]
            g = (g * (p - 1) + maxOf(d, 0.0)) / p
            l = (l * (p - 1) + maxOf(-d, 0.0)) / p
        }
        return if (l == 0.0) 100.0 else 100.0 - 100.0 / (1.0 + g / l)
    }

    private fun f(x: Double): String {
        val a = abs(x)
        return when {
            a >= 100 -> String.format(Locale.US, "%.2f", x)
            a >= 1 -> String.format(Locale.US, "%.4f", x)
            else -> String.format(Locale.US, "%.6f", x)
        }
    }

    private fun f1(x: Double): String = String.format(Locale.US, "%.1f", x)

    private fun shapes(k: Candle, p: Candle?): List<String> {
        val out = ArrayList<String>()
        val range = k.h - k.l
        if (range <= 0.0) return out
        val body = abs(k.c - k.o)
        val upper = k.h - maxOf(k.o, k.c)
        val lower = minOf(k.o, k.c) - k.l
        if (body <= range * 0.1) {
            out.add("doji")
        } else {
            if (lower >= body * 2 && upper <= body) out.add("hammer-shape (long lower wick)")
            if (upper >= body * 2 && lower <= body) out.add("shooting-star-shape (long upper wick)")
        }
        if (p != null) {
            if (p.c < p.o && k.c > k.o && k.o <= p.c && k.c >= p.o) out.add("bullish engulfing")
            if (p.c > p.o && k.c < k.o && k.o >= p.c && k.c <= p.o) out.add("bearish engulfing")
        }
        return out
    }

    fun summary(c: List<Candle>, asset: String, tf: Int): String {
        val n = c.size
        val closes = c.map { it.c }
        val last = c[n - 1]
        val e9 = ema(closes, 9)
        val e21 = ema(closes, 21)
        val ml = ema(closes, 12).zip(ema(closes, 26)) { a, b -> a - b }
        val sg = ema(ml, 9)
        val hist = ml[n - 1] - sg[n - 1]
        val histPrev = ml[n - 2] - sg[n - 2]
        val r = rsi(closes, 14)

        val w = closes.takeLast(20)
        val mean = w.average()
        val sd = sqrt(w.map { (it - mean) * (it - mean) }.average())
        val bu = mean + 2 * sd
        val bl = mean - 2 * sd
        val pctB = if (bu - bl > 0) (last.c - bl) / (bu - bl) else 0.5

        var atr = 0.0
        for (i in n - 14 until n) {
            atr += maxOf(
                c[i].h - c[i].l,
                abs(c[i].h - c[i - 1].c),
                abs(c[i].l - c[i - 1].c)
            )
        }
        atr /= 14

        val rec = c.subList(n - 31, n - 1)
        val res = rec.maxOf { it.h }
        val sup = rec.minOf { it.l }

        val range = last.h - last.l
        val bodyPct = if (range > 0) abs(last.c - last.o) / range * 100 else 0.0
        val upW = if (range > 0) (last.h - maxOf(last.o, last.c)) / range * 100 else 0.0
        val loW = if (range > 0) (minOf(last.o, last.c) - last.l) / range * 100 else 0.0

        val trend = when {
            e9[n - 1] > e21[n - 1] * 1.0002 -> "UPTREND (EMA9 above EMA21)"
            e9[n - 1] < e21[n - 1] * 0.9998 -> "DOWNTREND (EMA9 below EMA21)"
            else -> "SIDEWAYS (EMA9 about equal to EMA21)"
        }
        val sb = StringBuilder()
        sb.append("ASSET: ").append(asset).append(" | candle timeframe: ").append(tf)
            .append("m | candles: ").append(n).append(" (oldest first, last one is still forming)\n")
        sb.append("LAST 8 CANDLES (open, high, low, close):\n")
        for (i in n - 8 until n) {
            sb.append("  ").append(f(c[i].o)).append(", ").append(f(c[i].h)).append(", ")
                .append(f(c[i].l)).append(", ").append(f(c[i].c)).append("\n")
        }
        sb.append("LAST CANDLE: ").append(if (last.c >= last.o) "bullish" else "bearish")
            .append(", body ").append(f1(bodyPct)).append("% of range, upper wick ")
            .append(f1(upW)).append("%, lower wick ").append(f1(loW)).append("%\n")
        sb.append("TREND: ").append(trend).append("; EMA9=").append(f(e9[n - 1]))
            .append(", EMA21=").append(f(e21[n - 1])).append("; price is ")
            .append(if (last.c > e21[n - 1]) "above" else "below").append(" EMA21\n")
        sb.append("RSI(14): ").append(f1(r)).append("\n")
        sb.append("MACD(12,26,9): macd=").append(f(ml[n - 1])).append(", signal=")
            .append(f(sg[n - 1])).append(", histogram=").append(f(hist)).append(" (")
            .append(if (hist > histPrev) "rising" else "falling").append(")\n")
        sb.append("BOLLINGER(20,2): upper=").append(f(bu)).append(", mid=").append(f(mean))
            .append(", lower=").append(f(bl)).append("; %B=").append(f1(pctB * 100)).append("%\n")
        sb.append("ATR(14): ").append(f(atr)).append("\n")
        sb.append("RESISTANCE (30-candle high): ").append(f(res)).append(" (")
            .append(f1((res - last.c) / (if (atr > 0) atr else 1.0))).append(" ATR away)\n")
        sb.append("SUPPORT (30-candle low): ").append(f(sup)).append(" (")
            .append(f1((last.c - sup) / (if (atr > 0) atr else 1.0))).append(" ATR away)\n")
        val pNow = shapes(last, c[n - 2])
        val pPrev = shapes(c[n - 2], c[n - 3])
        sb.append("CANDLE SHAPES: last candle = ")
            .append(if (pNow.isEmpty()) "none" else pNow.joinToString(", "))
            .append("; previous candle = ")
            .append(if (pPrev.isEmpty()) "none" else pPrev.joinToString(", ")).append("\n")
        return sb.toString()
    }
}

// ============================================================
// API key: সেটিংসে বসানো key আগে, না থাকলে বিল্ডের সময় বসানো ডিফল্ট key
// ============================================================
object Keys {
    private var cached: Pair<String, String>? = null

    private fun defaults(ctx: Context): Pair<String, String> {
        val c = cached
        if (c != null) return c
        var g = ""
        var t = ""
        try {
            val lines = ctx.assets.open("keys.txt").bufferedReader().readLines()
            g = (lines.getOrNull(0) ?: "").trim()
            t = (lines.getOrNull(1) ?: "").trim()
        } catch (e: Exception) {
        }
        val r = Pair(g, t)
        cached = r
        return r
    }

    private fun prefs(ctx: Context): SharedPreferences =
        ctx.getSharedPreferences("gasi", Context.MODE_PRIVATE)

    fun gemini(ctx: Context): String {
        val k = prefs(ctx).getString("key", "") ?: ""
        return if (k.isNotEmpty()) k else defaults(ctx).first
    }

    fun twelve(ctx: Context): String {
        val k = prefs(ctx).getString("td_key", "") ?: ""
        return if (k.isNotEmpty()) k else defaults(ctx).second
    }
}

// ============================================================
// ফলাফলের ইতিহাস ও ✅/❌ হিসাব (ফোনে জমা থাকে)
// ============================================================
object Store {
    private fun p(ctx: Context): SharedPreferences =
        ctx.getSharedPreferences("gasi", Context.MODE_PRIVATE)

    fun readHistory(ctx: Context): JSONArray {
        return try {
            JSONArray(p(ctx).getString("history", "[]"))
        } catch (e: Exception) {
            JSONArray()
        }
    }

    @Synchronized
    fun addHistory(ctx: Context, entry: JSONObject) {
        val old = readHistory(ctx)
        val out = JSONArray()
        out.put(entry)
        for (i in 0 until minOf(old.length(), 99)) {
            out.put(old.get(i))
        }
        p(ctx).edit().putString("history", out.toString()).apply()
    }

    @Synchronized
    fun clearHistory(ctx: Context) {
        p(ctx).edit().putString("history", "[]").apply()
    }

    // ফল বসানো বা বদলানো: ইতিহাসের সাথে মোট হিসাবও ঠিক রাখে
    @Synchronized
    fun setOutcome(ctx: Context, id: Long, hit: Boolean) {
        val arr = readHistory(ctx)
        for (i in 0 until arr.length()) {
            val e = arr.getJSONObject(i)
            if (e.optLong("id") != id) continue
            val prev = e.optInt("hit", -1)
            val now = if (hit) 1 else 0
            if (prev == now) return
            val tf = e.optInt("minutes", 5)
            val sp = p(ctx)
            val ed = sp.edit()
            if (prev == -1) {
                ed.putInt("t_all", sp.getInt("t_all", 0) + 1)
                ed.putInt("t_$tf", sp.getInt("t_$tf", 0) + 1)
            }
            if (prev != 1 && now == 1) {
                ed.putInt("h_all", sp.getInt("h_all", 0) + 1)
                ed.putInt("h_$tf", sp.getInt("h_$tf", 0) + 1)
            }
            if (prev == 1 && now == 0) {
                ed.putInt("h_all", maxOf(0, sp.getInt("h_all", 0) - 1))
                ed.putInt("h_$tf", maxOf(0, sp.getInt("h_$tf", 0) - 1))
            }
            ed.apply()
            e.put("hit", now)
            p(ctx).edit().putString("history", arr.toString()).apply()
            return
        }
    }

    @Synchronized
    fun resetOutcomes(ctx: Context) {
        val arr = readHistory(ctx)
        for (i in 0 until arr.length()) {
            arr.getJSONObject(i).put("hit", -1)
        }
        p(ctx).edit().putString("history", arr.toString()).apply()
    }
}

// ============================================================
// থিম / সাজসজ্জার সেটিংস (অ্যাপের "সাজসজ্জা" কার্ড থেকে আসে)
// ============================================================
class UiStyle(
    val btnColor: Int,
    val btnIcon: String,
    val btnSize: Int,
    val btnAlpha: Int,
    val cardTop: Boolean,
    val cardAlpha: Int
)

fun readStyle(ctx: Context): UiStyle {
    val p = ctx.getSharedPreferences("gasi", Context.MODE_PRIVATE)
    val col = try {
        Color.parseColor(p.getString("btn_color", "#8B5CF6"))
    } catch (e: Exception) {
        Color.rgb(139, 92, 246)
    }
    return UiStyle(
        col,
        p.getString("btn_icon", "G") ?: "G",
        p.getInt("btn_size", 58),
        p.getInt("btn_alpha", 100),
        (p.getString("card_pos", "top") ?: "top") == "top",
        p.getInt("card_alpha", 96)
    )
}

private fun lighten(c: Int): Int {
    val hsv = FloatArray(3)
    Color.colorToHSV(c, hsv)
    hsv[1] = hsv[1] * 0.85f
    hsv[2] = minOf(1f, hsv[2] * 1.2f + 0.05f)
    return Color.HSVToColor(hsv)
}

private fun darken(c: Int): Int {
    val hsv = FloatArray(3)
    Color.colorToHSV(c, hsv)
    hsv[2] = hsv[2] * 0.7f
    return Color.HSVToColor(hsv)
}

private fun withAlpha(c: Int, a: Int): Int =
    Color.argb(a, Color.red(c), Color.green(c), Color.blue(c))

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

    private fun banner(c: Context, msg: String, color: Int): TextView {
        val b = text(c, msg, 12f, color, bold = true, center = true)
        b.setPadding(dp(c, 10), dp(c, 8), dp(c, 10), dp(c, 8))
        b.background = pill(c, color, 30)
        return b
    }

    fun loading(
        c: Context,
        msg: String = tr(c, "AI চার্ট বিশ্লেষণ করছে…", "AI is analyzing the chart…"),
        accent: Int = Color.rgb(139, 92, 246)
    ): View {
        val tv = text(c, msg, 14f, Color.WHITE, bold = true, center = true)
        tv.setPadding(dp(c, 22), dp(c, 14), dp(c, 22), dp(c, 14))
        tv.background = GradientDrawable().apply {
            cornerRadius = dp(c, 30).toFloat()
            setColor(Color.argb(240, 20, 16, 28))
            setStroke(dp(c, 1), withAlpha(accent, 130))
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
        live: Boolean,
        brief: String,
        highNews: Boolean,
        payout: Double,
        hint: String,
        accent: Int,
        cardAlpha: Int,
        onFeedback: (Boolean) -> Unit,
        onClose: () -> Unit
    ): View {
        val root = LinearLayout(c).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(c, 18), dp(c, 14), dp(c, 18), dp(c, 16))
            background = GradientDrawable().apply {
                cornerRadius = dp(c, 26).toFloat()
                setColor(Color.argb(cardAlpha * 255 / 100, 16, 13, 20))
                setStroke(dp(c, 1), withAlpha(accent, 110))
            }
        }

        val header = LinearLayout(c).apply { gravity = Gravity.CENTER_VERTICAL }
        header.addView(
            text(c, "gasi candle analysis", 14f, lighten(accent), bold = true),
            LinearLayout.LayoutParams(0, -2, 1f)
        )
        val close = text(c, "✕", 18f, Color.argb(200, 255, 255, 255), center = true)
        close.setPadding(dp(c, 12), dp(c, 4), dp(c, 4), dp(c, 4))
        close.setOnClickListener { onClose() }
        header.addView(close, LinearLayout.LayoutParams(-2, -2))
        root.addView(header)

        val webColor = if (web || live) C_GREEN else C_AMBER
        val webChip = text(
            c,
            when {
                live && web -> tr(c, "📊 আসল ক্যান্ডেল ডাটা + 🌐 ওয়েব", "📊 Real candle data + 🌐 Web")
                live -> tr(c, "📊 আসল ক্যান্ডেল ডাটা", "📊 Real candle data")
                web -> tr(c, "🌐 ওয়েব ও বইয়ের জ্ঞান মিলিয়ে", "🌐 Web + book knowledge")
                else -> tr(c, "📖 শুধু চার্ট ও বইয়ের জ্ঞান", "📖 Chart + book knowledge only")
            },
            11f, webColor, bold = true
        )
        webChip.setPadding(dp(c, 10), dp(c, 4), dp(c, 10), dp(c, 4))
        webChip.background = pill(c, webColor, 28)
        root.addView(webChip, LinearLayout.LayoutParams(-2, -2).apply { topMargin = dp(c, 2) })

        root.addView(
            GaugeView(c, up.toFloat(), down.toFloat()),
            LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(c, 6) }
        )

        if (highNews) {
            root.addView(
                banner(c, tr(c, "⚠ বড় খবর কাছাকাছি — ঝুঁকি বেশি", "⚠ Major news is near — higher risk"), C_RED),
                LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(c, 8) }
            )
        }
        val weakLine = if (payout > 0) maxOf(55.0, 100.0 / (1.0 + payout / 100.0) + 2.0) else 55.0
        if (maxOf(up, down) < weakLine) {
            root.addView(
                banner(c, tr(c, "⚠ সংকেত দুর্বল — এই রাউন্ডে ট্রেড এড়ানো ভালো", "⚠ Weak signal — better to skip this round"), C_AMBER),
                LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(c, 8) }
            )
        }

        if (hint.isNotEmpty()) {
            root.addView(
                text(c, "💡 " + hint, 11f, Color.rgb(255, 200, 120)),
                LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(c, 8) }
            )
        }

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

        if (payout > 0) {
            val be = 100.0 / (1.0 + payout / 100.0)
            root.addView(
                text(
                    c,
                    tr(
                        c,
                        "ব্রেক-ইভেন: " + pct(be) + "% (পেআউট " + pct(payout) +
                            "%) — AI-র সম্ভাবনা এর নিচে হলে লোকসান",
                        "Break-even: " + pct(be) + "% (payout " + pct(payout) +
                            "%) — below this AI probability you lose"
                    ),
                    11f, Color.rgb(170, 165, 178)
                ),
                LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(c, 6) }
            )
        }

        val why = text(c, reason, 13f, Color.rgb(200, 195, 205))
        why.setLineSpacing(0f, 1.25f)
        root.addView(why, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(c, 8) })

        if (brief.isNotEmpty()) {
            val b = text(c, tr(c, "🌐 লাইভ তথ্য: ", "🌐 Live info: ") + brief.take(320), 11f, Color.rgb(150, 178, 162))
            b.setLineSpacing(0f, 1.25f)
            root.addView(b, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(c, 8) })
        }

        val fbTitle = text(
            c, tr(c, "ট্রেডের পর: AI-র দিক কি মিলেছে?", "After the trade: did the AI direction match?"), 12f, Color.rgb(200, 195, 205), bold = true
        )
        root.addView(fbTitle, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(c, 12) })
        val fbRow = LinearLayout(c).apply { orientation = LinearLayout.HORIZONTAL }
        val okB = text(c, tr(c, "✅ মিলেছে", "✅ Matched"), 14f, C_GREEN, bold = true, center = true)
        okB.setPadding(0, dp(c, 9), 0, dp(c, 9))
        okB.background = pill(c, C_GREEN, 30)
        val noB = text(c, tr(c, "❌ মেলেনি", "❌ Missed"), 14f, C_RED, bold = true, center = true)
        noB.setPadding(0, dp(c, 9), 0, dp(c, 9))
        noB.background = pill(c, C_RED, 30)
        val done = {
            fbTitle.text = tr(c, "ধন্যবাদ, আপনার হিসাবে যোগ হয়েছে", "Thanks, added to your record")
            fbRow.visibility = View.GONE
        }
        okB.setOnClickListener { onFeedback(true); done() }
        noB.setOnClickListener { onFeedback(false); done() }
        fbRow.addView(okB, LinearLayout.LayoutParams(0, -2, 1f).apply { marginEnd = dp(c, 6) })
        fbRow.addView(noB, LinearLayout.LayoutParams(0, -2, 1f).apply { marginStart = dp(c, 6) })
        root.addView(fbRow, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(c, 6) })

        root.addView(
            text(c, tr(c, "এটি অনুমান, নিশ্চিত ভবিষ্যদ্বাণী নয়।", "This is an estimate, not a guaranteed prediction."), 11f, Color.rgb(140, 133, 146)),
            LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(c, 10) }
        )

        return root
    }
}

// ============================================================
// Service
// ============================================================
class OverlayService : Service() {

    companion object {
        @Volatile
        var instance: OverlayService? = null
    }

    private var buttonLp: WindowManager.LayoutParams? = null

    // অ্যাপ থেকে সেটিং বদলালে সাথে সাথে বাটনের রূপ বদলায়
    fun applyStyle() {
        handler.post {
            val b = button ?: return@post
            val st = readStyle(this)
            paintButton(b, st)
            buttonLp?.let {
                val px = (st.btnSize * resources.displayMetrics.density).toInt()
                it.width = px
                it.height = px
                try {
                    wm.updateViewLayout(b, it)
                } catch (_: Exception) {
                }
            }
        }
    }

    private fun paintButton(tv: TextView, st: UiStyle) {
        val d = resources.displayMetrics.density
        val bg = GradientDrawable(
            GradientDrawable.Orientation.TL_BR,
            intArrayOf(lighten(st.btnColor), darken(st.btnColor))
        )
        bg.shape = GradientDrawable.OVAL
        bg.setStroke((2 * d).toInt(), Color.argb(120, 255, 255, 255))
        tv.background = bg
        tv.text = st.btnIcon
        tv.typeface = Typeface.DEFAULT_BOLD
        tv.textSize = if (st.btnIcon.length > 1 && st.btnIcon.all { it.isLetter() }) 16f else 22f
        tv.setTextColor(Color.WHITE)
        tv.gravity = Gravity.CENTER
        tv.alpha = st.btnAlpha / 100f
    }

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
    // একই অ্যাসেটে বারবার ওয়েব সার্চ না করতে ১০ মিনিট পর্যন্ত সারসংক্ষেপ মনে রাখে
    private var cachedBrief = ""
    private var cachedAt = 0L
    private var cachedAsset = ""
    private var lastMinutes = 0
    @Volatile
    private var otcDetected = false
    private var refreshing = false
    private val models = listOf("gemini-flash-latest", "gemini-3.5-flash", "gemini-3-flash-preview")

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        wm = getSystemService(WINDOW_SERVICE) as WindowManager
        instance = this
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
            toast(tr(this, "Capture permission পাওয়া যায়নি", "Screen capture permission was not granted"))
            stopSelf()
            return START_NOT_STICKY
        }

        if (projection == null) {
            try {
                setupProjection(code, data)
            } catch (e: Exception) {
                toast(tr(this, "Capture শুরু হয়নি: ", "Capture could not start: ") + (e.message ?: ""))
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
            .setContentText(tr(this, "Floating G চালু আছে", "Floating G is on"))
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
                toast(tr(this, "Screenshot নেওয়া যায়নি, আবার চাপুন", "Could not take the screenshot, tap again"))
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
            // বড় ছবি ছোট করে (লম্বা দিক ১৮০০px) পাঠালে আপলোড দ্রুত হয়
            val longSide = maxOf(w, h)
            val scale = if (longSide > 1800) 1800f / longSide else 1f
            val outBmp = if (scale < 1f) {
                Bitmap.createScaledBitmap(bmp, (w * scale).toInt(), (h * scale).toInt(), true)
            } else {
                bmp
            }
            FileOutputStream(file).use { out ->
                outBmp.compress(Bitmap.CompressFormat.JPEG, 75, out)
            }
            if (outBmp !== bmp) outBmp.recycle()
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
    private fun callGemini(
        key: String, b64: String, withSearch: Boolean, m: String, prompt: String,
        lowThink: Boolean,
        json: Boolean
    ): Pair<Int, String> {
        val parts = JSONArray().put(JSONObject().put("text", prompt))
        if (b64.isNotEmpty()) {
            parts.put(
                JSONObject().put(
                    "inline_data", JSONObject()
                        .put("mime_type", "image/jpeg")
                        .put("data", b64)
                )
            )
        }
        val body = JSONObject()
            .put("contents", JSONArray().put(JSONObject().put("parts", parts)))
        if (withSearch) {
            body.put(
                "tools", JSONArray().put(JSONObject().put("google_search", JSONObject()))
            )
        }
        val gen = JSONObject()
        if (lowThink) {
            gen.put("thinkingConfig", JSONObject().put("thinkingLevel", "low"))
        }
        if (json) {
            // সরাসরি JSON উত্তর: দ্রুত ও পরিষ্কার (search টুলের সাথে চলে না)
            gen.put("responseMimeType", "application/json")
        }
        if (gen.length() > 0) body.put("generationConfig", gen)
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

    // মডেল fallback + সার্ভার ব্যস্ত হলে retry। (code, body) ফেরত দেয়
    private fun request(
        key: String, b64: String, prompt: String, withSearch: Boolean,
        json: Boolean = false
    ): Pair<Int, String> {
        val retryable = setOf(429, 500, 503, 504)
        var r = Pair(0, "")
        for (m in models) {
            for (attempt in 0..1) {
                r = try {
                    callGemini(key, b64, withSearch, m, prompt, true, json)
                } catch (e: Exception) {
                    Pair(-1, e.message ?: "network error")
                }
                // সেটিং না নিলে (400) সাধারণ অনুরোধে আবার
                if (r.first == 400) {
                    r = try {
                        callGemini(key, b64, withSearch, m, prompt, false, false)
                    } catch (e: Exception) {
                        Pair(-1, e.message ?: "network error")
                    }
                }
                if (r.first in 200..299) return r
                if (r.first in retryable && attempt == 0) {
                    Thread.sleep(2500)
                    continue
                }
                break
            }
            if (r.first != 404 && r.first !in retryable) return r
        }
        return r
    }

    private fun errorText(r: Pair<Int, String>): String {
        if (r.first == -1) {
            return tr(
                this,
                "ইন্টারনেট সংযোগ নেই, আবার চেষ্টা করুন",
                "No internet connection. Please try again."
            )
        }
        var m = ""
        try {
            m = JSONObject(r.second).getJSONObject("error").getString("message")
        } catch (_: Exception) {
            m = r.second
        }
        return "API " + r.first + ": " + m.take(160)
    }

    // সাধারণ লেখা + ওয়েব সার্চ হয়েছিল কিনা
    private fun readText(resp: String): Pair<String, Boolean> {
        val cands = JSONObject(resp).optJSONArray("candidates")
        if (cands == null || cands.length() == 0) return Pair("", false)
        val c0 = cands.getJSONObject(0)
        val q = c0.optJSONObject("groundingMetadata")?.optJSONArray("webSearchQueries")
        val parts = c0.optJSONObject("content")?.optJSONArray("parts")
        val sb = StringBuilder()
        if (parts != null) {
            for (i in 0 until parts.length()) {
                sb.append(parts.getJSONObject(i).optString("text"))
            }
        }
        return Pair(sb.toString().trim(), q != null && q.length() > 0)
    }
    
    // উত্তর থেকে JSON অংশ আর finishReason
    private fun readReply(resp: String): Pair<String, String> {
        val cands = JSONObject(resp).optJSONArray("candidates")
        if (cands == null || cands.length() == 0) return Pair("", "NO_CANDIDATE")
        val c0 = cands.getJSONObject(0)
        val finish = c0.optString("finishReason", "")
        val raw = readText(resp).first
        val s = raw.indexOf('{')
        val e = raw.lastIndexOf('}')
        val json = if (s >= 0 && e > s) raw.substring(s, e + 1) else ""
        return Pair(json, finish)
    }

    private fun strOf(j: JSONObject, k: String): String =
        if (!j.has(k) || j.isNull(k)) "" else j.optString(k, "").trim()

    private fun readPayout(j: JSONObject): Double {
        if (!j.has("payout_percent") || j.isNull("payout_percent")) return -1.0
        val v = j.optDouble("payout_percent", -1.0)
        return if (v in 1.0..200.0) v else -1.0
    }

    private fun researchPrompt(minutes: Int): String =
        AnalysisPrompt.RESEARCH.trimIndent() + "\n\nFORECAST WINDOW: the next " +
            horizonLabel(minutes) + ". Focus on events and sentiment relevant to this window."

    private fun horizonText(minutes: Int): String =
        "\n\nFORECAST HORIZON: The UP and DOWN probabilities must describe the price " +
            "direction over the NEXT " + horizonLabel(minutes) +
            " from the latest candle. Answer only for this horizon."

    // আসল ডাটা পথ। true = রেজাল্ট/এরর দেখানো হয়েছে; false = স্ক্রিনশট পথে যাও
    private fun tryDataPath(
        key: String, b64: String, prefs: SharedPreferences, useWeb: Boolean, minutes: Int
    ): Boolean {
        // ধাপ ১: স্ক্রিনশট থেকে অ্যাসেট চেনা
        val r0 = request(key, b64, AnalysisPrompt.DETECT.trimIndent(), false, true)
        if (r0.first !in 200..299) return false
        val det = readReply(r0.second).first
        if (det.isEmpty()) return false
        val d = try {
            JSONObject(det)
        } catch (e: Exception) {
            return false
        }
        val market = d.optString("market", "unknown").lowercase()
        val asset = d.optString("asset", "").trim()
        if (market == "otc") otcDetected = true
        if (asset.isEmpty() || market !in setOf("crypto", "forex", "stock")) return false
        val tf = candleTfFor(minutes)
        val tdKey = Keys.twelve(this)
        if (market != "crypto" && tdKey.isEmpty()) return false

        handler.post { showLoading(tr(this, "আসল বাজারের ডাটা আনছে…", "Fetching real market data…")) }

        // ওয়েব সার্চ আলাদা থ্রেডে, ক্যান্ডেল ডাটা আনার সাথে একসাথে চলে
        var brief = ""
        var web = false
        var worker: Thread? = null
        if (useWeb) {
            val fresh = System.currentTimeMillis() - cachedAt < 15 * 60 * 1000L
            if (cachedBrief.isNotEmpty() && fresh && cachedAsset == asset) {
                brief = cachedBrief
                web = true
            } else {
                worker = thread {
                    try {
                        val rr = request(
                            key, "",
                            AnalysisPrompt.RESEARCH_ASSET.trimIndent() +
                                "\n\nFORECAST WINDOW: the next " + horizonLabel(minutes) +
                                ". Focus on events and sentiment relevant to this window." +
                                "\n\nASSET TO RESEARCH: " + asset,
                            true
                        )
                        if (rr.first in 200..299) {
                            val tx = readText(rr.second)
                            if (tx.second && tx.first.isNotEmpty()) {
                                cachedBrief = tx.first
                                cachedAt = System.currentTimeMillis()
                                cachedAsset = asset
                            }
                        }
                    } catch (_: Exception) {
                    }
                }
            }
        }

        val candles = MarketData.fetch(market, asset, tf, tdKey) ?: return false

        worker?.join(70000L)
        if (worker != null && cachedAsset == asset && cachedBrief.isNotEmpty()) {
            brief = cachedBrief
            web = true
        }

        handler.post { showLoading(tr(this, "বিশ্লেষণ করছে…", "Analyzing…")) }
        val data = MarketData.summary(candles, asset, tf)
        val liveCtx = when {
            brief.isNotEmpty() ->
                "\n\nLIVE MARKET BRIEF (gathered from Google Search):\n" + brief
            useWeb ->
                "\n\nLIVE MARKET BRIEF: unavailable. Use Neutral for market_sentiment."
            else ->
                "\n\nLIVE MARKET BRIEF: not requested (fast mode). Use Neutral for market_sentiment."
        }
        val prompt = "NOTE: No screenshot is attached. The exact numeric candle data below was " +
            "fetched live from a market data API a moment ago; treat it as the chart and skip " +
            "any step that needs reading an image.\n\n" +
            AnalysisPrompt.TEXT.trimIndent() + horizonText(minutes) +
            "\n\nMARKET DATA (exact numbers):\n" + data + liveCtx

        var r = request(key, "", prompt, false, true)
        if (r.first !in 200..299) {
            handler.post { clearResult() }
            toast(errorText(r), true)
            return true
        }
        var rep = readReply(r.second)
        if (rep.first.isEmpty()) {
            r = request(key, "", prompt, false, true)
            if (r.first in 200..299) rep = readReply(r.second)
        }
        if (rep.first.isEmpty()) {
            handler.post { clearResult() }
            toast(tr(this, "AI খালি উত্তর দিয়েছে (" + rep.second + "), আবার চাপুন", "The AI returned an empty answer (" + rep.second + "), tap again"), true)
            return true
        }
        val j = JSONObject(rep.first)
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
        val highNews = j.optBoolean("high_impact_news_soon", false)
        val shownBrief = brief
        val finalUp = up
        val finalDown = down
        val finalWeb = web
        handler.post {
            showResult(finalUp, finalDown, pattern, sent, why, finalWeb, shownBrief, highNews, minutes, true, -1.0, "", asset)
        }
        return true
    }
    
    private fun analyze(file: File) {
        val prefs = getSharedPreferences("gasi", MODE_PRIVATE)
        val key = Keys.gemini(this)
        if (key.isEmpty()) {
            toast(tr(this, "API key সেট করা নেই, Share খুলছে", "No API key set, opening Share"))
            share(file)
            return
        }

        val otcMode = prefs.getBoolean("otc", false)
        var useWeb = prefs.getBoolean("web", true) && !otcMode
        showLoading(if (useWeb) tr(this, "বাজারের তথ্য দেখছে…", "Checking market info…") else tr(this, "AI চার্ট বিশ্লেষণ করছে…", "AI is analyzing the chart…"))

        thread {
            try {
                val b64 = Base64.encodeToString(file.readBytes(), Base64.NO_WRAP)
                val minutes = prefs.getInt("minutes", 5)
                if (minutes != lastMinutes) {
                    // পূর্বাভাসের সময় বদলালে আগের ওয়েব সারসংক্ষেপ আর ঠিক নয়
                    cachedBrief = ""
                    cachedAsset = ""
                    lastMinutes = minutes
                }

                // আসল ক্যান্ডেল ডাটা পথ (ক্রিপ্টো/ফরেক্স/স্টক); না হলে স্ক্রিনশট পথ
                otcDetected = false
                if (prefs.getBoolean("data", true) && !otcMode) {
                    if (tryDataPath(key, b64, prefs, useWeb, minutes)) return@thread
                    // OTC দাম ব্রোকারের নিজস্ব, আসল খবরের সাথে মেলে না: ওয়েব সার্চ বাদ
                    if (otcDetected) useWeb = false
                }
                val horizon = "\n\nFORECAST HORIZON: The UP and DOWN probabilities must describe " +
                    "the price direction over the NEXT " + horizonLabel(minutes) +
                    " from the latest candle in the screenshot. The chart's own timeframe may " +
                    "differ; still answer only for this horizon."
                val note = "\n\nNOTE: This brief may have been gathered a few minutes ago for a " +
                    "previous chart. In addition to the JSON fields above, add one boolean field " +
                    "\"brief_matches_chart\": true if the ASSET named in the brief is the same asset " +
                    "as the chart in this screenshot, otherwise false."

                var forceFresh = false

                for (round in 0..1) {
                    var brief = ""
                    var web = false
                    var fromCache = false

                    if (useWeb) {
                        val fresh = System.currentTimeMillis() - cachedAt < 15 * 60 * 1000L
                        if (!forceFresh && cachedBrief.isNotEmpty() && fresh) {
                            // দ্রুত পথ: আগের সারসংক্ষেপ ব্যবহার, ওয়েব সার্চ লাগে না
                            brief = cachedBrief
                            web = true
                            fromCache = true
                        } else {
                            handler.post { showLoading(tr(this, "ওয়েব থেকে বাজারের তথ্য নিচ্ছে…", "Getting market info from the web…")) }
                            val r1 = request(key, b64, researchPrompt(minutes), true)
                            if (r1.first in 200..299) {
                                val tx = readText(r1.second)
                                web = tx.second && tx.first.isNotEmpty()
                                if (web) {
                                    brief = tx.first
                                    cachedBrief = brief
                                    cachedAsset = ""
                                    cachedAt = System.currentTimeMillis()
                                }
                            }
                        }
                    }

                    handler.post { showLoading(tr(this, "বইয়ের জ্ঞান ও চার্ট মিলিয়ে বিশ্লেষণ করছে…", "Combining book knowledge and the chart…")) }

                    val live = when {
                        brief.isNotEmpty() ->
                            "\n\nLIVE MARKET BRIEF (gathered from Google Search):\n" + brief +
                                (if (fromCache) note else "")
                        useWeb ->
                            "\n\nLIVE MARKET BRIEF: unavailable. Use Neutral for market_sentiment."
                        else ->
                            "\n\nLIVE MARKET BRIEF: not requested (fast mode). " +
                                "Use Neutral for market_sentiment."
                    }
                    val finalPrompt = AnalysisPrompt.TEXT.trimIndent() + horizon + live

                    var r = request(key, b64, finalPrompt, false, true)
                    if (r.first !in 200..299) {
                        handler.post { clearResult() }
                        toast(errorText(r), true)
                        return@thread
                    }
                    var rep = readReply(r.second)
                    if (rep.first.isEmpty()) {
                        r = request(key, b64, finalPrompt, false, true)
                        if (r.first in 200..299) rep = readReply(r.second)
                    }
                    if (rep.first.isEmpty()) {
                        handler.post { clearResult() }
                        toast(tr(this, "AI খালি উত্তর দিয়েছে (" + rep.second + "), আবার চাপুন", "The AI returned an empty answer (" + rep.second + "), tap again"), true)
                        return@thread
                    }
                    val j = JSONObject(rep.first)

                    // আগের সারসংক্ষেপ অন্য অ্যাসেটের হলে নতুন করে ওয়েব সার্চ
                    if (fromCache && !j.optBoolean("brief_matches_chart", true)) {
                        cachedBrief = ""
                        forceFresh = true
                        continue
                    }

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
                    val shown = if (fromCache) tr(this, "(কিছুক্ষণ আগের) ", "(a few minutes ago) ") + brief else brief
                    val highNews = j.optBoolean("high_impact_news_soon", false)
                    val payout = readPayout(j)
                    val assetName = strOf(j, "asset_name")
                    val chartTf = if (j.has("chart_timeframe_minutes") &&
                        !j.isNull("chart_timeframe_minutes")
                    ) {
                        j.optInt("chart_timeframe_minutes", 0)
                    } else {
                        0
                    }
                    val hint = if (chartTf in 1..1440 && minutes / chartTf > 15) {
                        tr(
                            this,
                            "চার্ট " + tfLabel(this, chartTf) + "-এর, কিন্তু পূর্বাভাস " +
                                tfLabel(this, minutes) + "-এর। ভালো ফলের জন্য " +
                                tfLabel(this, candleTfFor(minutes)) +
                                " টাইমফ্রেমের চার্টের স্ক্রিনশট নিন।",
                            "The chart is " + tfLabel(this, chartTf) + " but the forecast is " +
                                tfLabel(this, minutes) + ". For a better result, capture a " +
                                tfLabel(this, candleTfFor(minutes)) + " timeframe chart."
                        )
                    } else {
                        ""
                    }

                    handler.post { showResult(up, down, pattern, sent, why, web, shown, highNews, minutes, false, payout, hint, assetName) }

                    // রেজাল্ট দেখানোর পর ব্যাকগ্রাউন্ডে ওয়েব তথ্য নতুন করে রাখা,
                    // যাতে পরের বার G চাপলে অপেক্ষা করতে না হয়
                    if (useWeb && web && !refreshing &&
                        System.currentTimeMillis() - cachedAt > 6 * 60 * 1000L
                    ) {
                        refreshing = true
                        try {
                            val rr = request(key, b64, researchPrompt(minutes), true)
                            if (rr.first in 200..299) {
                                val tx = readText(rr.second)
                                if (tx.second && tx.first.isNotEmpty()) {
                                    cachedBrief = tx.first
                                    cachedAsset = ""
                                    cachedAt = System.currentTimeMillis()
                                }
                            }
                        } catch (_: Exception) {
                        } finally {
                            refreshing = false
                        }
                    }
                    return@thread
                }
            } catch (e: Exception) {
                handler.post { clearResult() }
                val net = e is java.net.UnknownHostException ||
                    e is java.net.ConnectException ||
                    e is java.net.SocketTimeoutException
                if (net) {
                    toast(
                        tr(
                            this,
                            "ইন্টারনেট সংযোগ নেই, আবার চেষ্টা করুন",
                            "No internet connection. Please try again."
                        ),
                        true
                    )
                } else {
                    toast("AI error: " + (e.message ?: ""), true)
                }
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

            val chooser = Intent.createChooser(send, tr(this, "AI app বেছে নিন", "Choose an AI app"))
            chooser.addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
            startActivity(chooser)
        } catch (e: Exception) {
            toast(tr(this, "Share করা যায়নি: ", "Could not share: ") + (e.message ?: ""))
        }
    }

    // ---------- Result overlay ----------
    private fun showLoading(msg: String = tr(this, "AI চার্ট বিশ্লেষণ করছে…", "AI is analyzing the chart…")) {
        clearResult()
        val st = readStyle(this)
        val v = ResultCard.loading(this, msg, st.btnColor)
        val lp = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )
        lp.gravity = (if (st.cardTop) Gravity.TOP else Gravity.BOTTOM) or Gravity.CENTER_HORIZONTAL
        lp.y = if (st.cardTop) 120 else 160
        wm.addView(v, lp)
        resultView = v
    }

    private fun showResult(
        up: Double, down: Double, pattern: String, sent: String, why: String,
        web: Boolean, brief: String, highNews: Boolean, minutes: Int,
        live: Boolean = false,
        payout: Double = -1.0,
        hint: String = "",
        asset: String = ""
    ) {
        clearResult()
        val st = readStyle(this)
        val id = System.currentTimeMillis()
        try {
            val e = JSONObject()
            e.put("id", id)
            e.put("asset", asset)
            e.put("up", up)
            e.put("down", down)
            e.put("pattern", pattern)
            e.put("sent", sent)
            e.put("minutes", minutes)
            e.put("mode", if (live) "live" else if (web) "web" else "chart")
            e.put("payout", payout)
            e.put("hit", -1)
            Store.addHistory(this, e)
        } catch (_: Exception) {
        }
        val card = ResultCard.build(
            this, up, down, pattern, sent, why, web, live, brief, highNews, payout, hint,
            st.btnColor, st.cardAlpha,
            { hit ->
                Store.setOutcome(this, id, hit)
                toast(if (hit) tr(this, "✅ যোগ হয়েছে", "✅ Added") else tr(this, "❌ যোগ হয়েছে", "❌ Added"))
            },
            { clearResult() }
        )
        val lp = WindowManager.LayoutParams(
            (resources.displayMetrics.widthPixels * 0.92).toInt(),
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )
        lp.gravity = (if (st.cardTop) Gravity.TOP else Gravity.BOTTOM) or Gravity.CENTER_HORIZONTAL
        lp.y = if (st.cardTop) 100 else 140
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

        val st = readStyle(this)
        val size = (st.btnSize * resources.displayMetrics.density).toInt()

        val tv = TextView(this)
        paintButton(tv, st)

        val lp = WindowManager.LayoutParams(
            size, size,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )
        lp.gravity = Gravity.TOP or Gravity.START
        lp.x = 30
        lp.y = 300
        buttonLp = lp

        var startX = 0
        var startY = 0
        var touchX = 0f
        var touchY = 0f

        tv.setOnTouchListener { v, e ->
            when (e.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    v.animate().scaleX(0.88f).scaleY(0.88f).setDuration(90).start()
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
                    v.animate().scaleX(1f).scaleY(1f).setDuration(120).start()
                    if (abs(e.rawX - touchX) < 15 && abs(e.rawY - touchY) < 15) {
                        v.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                        capture()
                    }
                    true
                }
                MotionEvent.ACTION_CANCEL -> {
                    v.animate().scaleX(1f).scaleY(1f).setDuration(120).start()
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
        instance = null
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

