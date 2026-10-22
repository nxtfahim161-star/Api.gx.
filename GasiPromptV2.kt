package com.example.gasi_candle_ai

/**
 * উন্নত Gemini প্রম্পট (v2)।
 * আউটপুট JSON ফরম্যাট আগের মতোই রাখা হয়েছে (AIResult.parse-এর সাথে মেলে)।
 *
 * ব্যবহার:
 *   val prompt = GasiPromptV2.build(
 *       timeframe = "5m",            // নির্বাচিত টাইমফ্রেম
 *       candleData = realCandleText, // Twelve Data থেকে পাওয়া ক্যান্ডেল (না থাকলে null)
 *       otc = otcMode,               // OTC মোড চালু থাকলে true
 *       webSearch = webMode,         // ওয়েব সার্চ চালু থাকলে true
 *       bangla = isBangla            // true হলে summary_reason বাংলায় আসবে
 *   )
 */
object GasiPromptV2 {

    private val CORE = """
ROLE: Expert price-action analyst.
TASK: From the attached chart screenshot, estimate whether price will be HIGHER or LOWER at the end of the next {TIMEFRAME} from now.

RULES
- Use only what is visible or provided. Never invent candles, levels, indicators, volume, prices or news.
- If the image is not a readable trading chart, return the FALLBACK JSON.

STEP 1 - CHART READ (internal, do not output)
- Identify the asset, the chart timeframe and the price scale.
- Trend direction and strength (higher highs/lows, drawn moving averages).
- Last 3-5 candles: body vs range, wicks, close position, momentum. The last candle may still be forming: give it less weight.
- Nearest support/resistance and where price sits relative to them; breakout, rejection, retest.
- Name a pattern only if it appears in the right place: reversal patterns need a prior trend and a key level; continuation patterns need an existing trend.
- Volume and indicators (RSI, MACD, MA) only if visible; they confirm or weaken the signal.
- Small overlapping candles in a range = no edge, lean 50/50.
""".trimIndent()

    private const val CONTEXT_LIVE = """
STEP 2 - LIVE CONTEXT
Using web search, check the identified asset for: major news, scheduled high-impact events within the next few hours, broader trend and sentiment. If you cannot verify something, treat this part as Neutral (50/50). Never guess.
Final = 60% technical + 40% live context.
"""

    private const val CONTEXT_OFF = """
STEP 2 - LIVE CONTEXT
Web search is OFF. Do not use outside news. Set market_sentiment to Neutral.
Final = 100% technical.
"""

    private const val CONTEXT_OTC = """
STEP 2 - LIVE CONTEXT
This is an OTC (broker-generated) market. Real-world news does not drive it. Ignore news. Set market_sentiment to Neutral.
Final = 100% technical.
"""

    private const val CANDLES_HEAD = """
REAL CANDLE DATA (primary evidence for numbers; the screenshot is secondary):
"""

    private const val CANDLES_RULE = """
If the data and the screenshot disagree, trust the data. Do not copy the data back into the answer.
"""

    private const val PROBABILITY = """
STEP 3 - PROBABILITY
- Conflicting signals: pull toward 50.
- Normal range for the favored side: 50-70.
- 71-85 only if trend, key level, last-candle momentum and confirmation all agree.
- Never above 85.
- Integers only; UP + DOWN = exactly 100.

OUTPUT: Return ONLY this JSON, no markdown, no extra text, no extra fields:
{
"up_probability_percent": 0,
"down_probability_percent": 0,
"technical_pattern": "Best-supported classical pattern, or No clear classical pattern",
"market_sentiment": "Bullish / Bearish / Neutral (from Step 2 only)",
"summary_reason": "{REASON_LANG}"
}

FALLBACK (unreadable image or not a chart):
{"up_probability_percent":50,"down_probability_percent":50,"technical_pattern":"No clear classical pattern","market_sentiment":"Neutral","summary_reason":"{FALLBACK_REASON}"}

Before answering, verify: valid JSON, sum = 100, market_sentiment is exactly one of Bullish, Bearish, Neutral.
"""

    fun build(
        timeframe: String,
        candleData: String? = null,
        otc: Boolean = false,
        webSearch: Boolean = true,
        bangla: Boolean = true,
    ): String {
        val sb = StringBuilder()
        sb.append(CORE.replace("{TIMEFRAME}", timeframe))
        if (!candleData.isNullOrBlank()) {
            sb.append("\n").append(CANDLES_HEAD.trim()).append("\n")
            sb.append(candleData.trim()).append("\n")
            sb.append(CANDLES_RULE.trim()).append("\n")
        }
        val context = when {
            otc -> CONTEXT_OTC
            webSearch -> CONTEXT_LIVE
            else -> CONTEXT_OFF
        }
        sb.append("\n").append(context.trim()).append("\n\n")
        val reason = if (bangla) {
            "Max 2 short lines in Bengali: key chart evidence + context."
        } else {
            "Max 2 short lines in English: key chart evidence + context."
        }
        val fallback = if (bangla) "Chart পরিষ্কার দেখা যাচ্ছে না।" else "The chart is not clearly visible."
        sb.append(
            PROBABILITY.trim()
                .replace("{REASON_LANG}", reason)
                .replace("{FALLBACK_REASON}", fallback)
        )
        return sb.toString()
    }
}
