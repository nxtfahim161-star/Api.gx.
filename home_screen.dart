import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

const Map<String, List<Color>> kBackgrounds = {
  'aurora': [Color(0xFF1E1136), Color(0xFF0B0A0E), Color(0xFF0A1C22)],
  'amoled': [Color(0xFF000000), Color(0xFF000000), Color(0xFF000000)],
  'midnight': [Color(0xFF0B1630), Color(0xFF0B0A0E), Color(0xFF111B3A)],
  'emerald': [Color(0xFF062016), Color(0xFF0B0A0E), Color(0xFF0B2A1E)],
  'wine': [Color(0xFF2A0C1A), Color(0xFF0B0A0E), Color(0xFF1E0F26)],
};

const Map<String, String> kBackgroundNames = {
  'aurora': 'অরোরা',
  'amoled': 'কালো',
  'midnight': 'মধ্যরাত',
  'emerald': 'পান্না',
  'wine': 'ওয়াইন',
};

BoxDecoration gasiBackground(String id) {
  final c = kBackgrounds[id] ?? kBackgrounds['aurora']!;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: c,
      stops: const [0.0, 0.5, 1.0],
    ),
  );
}

// ============================================================
// ভাষা (বাংলা / English)
// ============================================================
final ValueNotifier<String> langNotifier = ValueNotifier<String>('bn');

String tr(String bn, String en) => langNotifier.value == 'en' ? en : bn;

mixin LangAware<T extends StatefulWidget> on State<T> {
  void _onLangChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    langNotifier.addListener(_onLangChanged);
  }

  @override
  void dispose() {
    langNotifier.removeListener(_onLangChanged);
    super.dispose();
  }
}

String bgName(String id) {
  switch (id) {
    case 'amoled':
      return tr('কালো', 'Black');
    case 'midnight':
      return tr('মধ্যরাত', 'Midnight');
    case 'emerald':
      return tr('পান্না', 'Emerald');
    case 'wine':
      return tr('ওয়াইন', 'Wine');
    default:
      return tr('অরোরা', 'Aurora');
  }
}

final ValueNotifier<String> bgNotifier = ValueNotifier<String>('aurora');

BoxDecoration cardDeco() {
  return BoxDecoration(
    color: const Color(0xFF111015).withOpacity(0.92),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: Colors.white.withOpacity(0.07)),
  );
}

class GasiBackground extends StatelessWidget {
  final Widget child;
  const GasiBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: bgNotifier,
      builder: (context, id, _) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: gasiBackground(id),
          child: child,
        );
      },
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GasiApp());
}

class GasiApp extends StatelessWidget {
  const GasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'gasi candle analysis AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0A0E),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.purple,
          secondary: AppColors.lilac,
        ),
      ),
      home: const Gate(),
    );
  }
}

const String kAgreementText = '''This app gives you general information and an AI-generated estimate that is based on chart images, public market data and web information. It is meant only to give you an idea. It is for educational and informational purposes and it is not financial, investment or trading advice.

The percentages shown are estimates. They are not predictions and they are not guarantees. They can be wrong. Trading is risky, especially on OTC instruments whose prices are set by the broker, and you can lose all of the money you trade.

The app, its developer and any related party accept no responsibility or liability for any profit, loss or damage that comes from using this app. You use your own knowledge and judgment, you decide whether to trade, and you trade entirely at your own risk.

You are responsible for making sure that trading is legal in your country and that you are old enough to trade.

Screenshots you capture are sent to Google Gemini for analysis, and candle data may be requested from public market data services. Your API keys are stored only on your device.''';

const String kPrivacyText = '''Privacy Policy
Last updated: 12 October 2026

1. Summary
This app has no user accounts, no ads, no analytics and no server run by the developer. The developer does not collect, receive or sell your data.

2. Data stored only on your device
Your API keys, your settings, and your results history with your own right or wrong marks. You can delete them at any time by clearing the app data or uninstalling the app.

3. Data sent to third parties when you use the app
(a) When you tap the floating button, a screenshot of your whole screen and an analysis prompt are sent to Google Gemini, using your own API key. The screenshot is kept briefly in the app cache and is replaced at the next capture.
(b) The name and timeframe of the asset are sent to public market data services (Binance public data, or Twelve Data with your own key), and Gemini may use Google Search to look up market news. These services receive your IP address and handle data under their own terms.
Depending on your Google plan, Google may use submitted content to improve its services. Please check Google's terms for your account.

4. Sensitive information
A screenshot can contain anything that is visible on your screen, such as account balances or personal details. Hide such information before you capture.

5. Permissions
Display over other apps (for the floating button), screen capture (asked each time you start, and used only when you tap the button), notifications, internet access, and an optional battery optimization exemption.

6. Children
The app is not meant for anyone under 18, or below the legal age for trading in their country.

7. Your choices
You can remove your keys, revoke permissions or uninstall the app at any time.

8. Changes
This policy may be updated inside the app.''';

void showTextDialog(BuildContext context, String title, String text) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Text(text, style: const TextStyle(fontSize: 13, height: 1.5)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(tr('বন্ধ করুন', 'Close')),
        ),
      ],
    ),
  );
}

/// বাংলা / English বাছাইয়ের ছোট সুইচ।
class LanguageSwitch extends StatefulWidget {
  const LanguageSwitch({super.key});

  @override
  State<LanguageSwitch> createState() => _LanguageSwitchState();
}class _LanguageSwitchState extends State<LanguageSwitch>
    with LangAware<LanguageSwitch> {
  static const _ch = MethodChannel('gasi/native');

  Future<void> _set(String v) async {
    langNotifier.value = v;
    try {
      await _ch.invokeMethod('saveLang', {'lang': v});
    } catch (_) {}
  }

  Widget _chip(String label, String code) {
    final sel = langNotifier.value == code;
    return GestureDetector(
      onTap: () => _set(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? AppColors.purple : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: sel ? AppColors.lilac : Colors.white.withOpacity(0.08)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: sel ? Colors.white : const Color(0xFFB9B3BF))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip('বাংলা', 'bn'),
        const SizedBox(width: 8),
        _chip('English', 'en'),
      ],
    );
  }
}

/// GX লোগো (assets/logo.png না থাকলে "GX" লেখা)।
Widget gxLogo(double size) {
  return Image.asset(
    'assets/logo.png',
    width: size,
    height: size,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stack) => SizedBox(
      width: size,
      height: size,
      child: const Center(
        child: Text('GX',
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
      ),
    ),
  );
}

enum GateStep { loading, offline, agreement, key, manual, home }

class Gate extends StatefulWidget {
  const Gate({super.key});

  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  static const _ch = MethodChannel('gasi/native');
  GateStep _step = GateStep.loading;
  bool _agreed = false;
  bool _setup = false;
  bool _manual = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<bool> _online() async {
    try {
      final o = await _ch.invokeMethod<bool>('hasInternet');
      return o != false;
    } catch (_) {
      return true;
    }
  }

  // লোডিং ঠিক ৭ সেকেন্ড চলে; ইন্টারনেট পরীক্ষা সেই সময়ের মধ্যেই হয়।
  Future<void> _boot({bool quick = false}) async {
    bool online = true;
    try {
      final r = await Future.wait<dynamic>([
        _ch.invokeMethod<Map<dynamic, dynamic>>('getFlags'),
        _ch.invokeMethod<Map<dynamic, dynamic>>('getUi'),
        _online(),
        Future<void>.delayed(Duration(milliseconds: quick ? 900 : 7000)),
      ]);
      final f = r[0] as Map<dynamic, dynamic>?;
      _agreed = f?['agreed'] == true;
      _setup = f?['setup_done'] == true;
      _manual = f?['manual_seen'] == true;
      final l = f?['lang'];
      if (l is String) langNotifier.value = l;
      final u = r[1] as Map<dynamic, dynamic>?;
      final bg = u?['bg'];
      if (bg is String) bgNotifier.value = bg;
      online = r[2] == true;
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 1500));
    }
    if (!mounted) return;
    setState(() => _step = online ? _next() : GateStep.offline);
  }

  GateStep _next() {
    if (!_agreed) return GateStep.agreement;
    if (!_setup) return GateStep.key;
    if (!_manual) return GateStep.manual;
    return GateStep.home;
  }

  void _retry() {
    setState(() => _step = GateStep.loading);
    _boot(quick: true);
  }

  Future<void> _flag(String name) async {
    try {
      await _ch.invokeMethod('saveFlag', {'name': name, 'value': true});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    Widget page = const SizedBox.shrink();
    switch (_step) {
      case GateStep.loading:
        page = const WelcomeScreen(key: ValueKey('splash'));
        break;
      case GateStep.offline:
        page = OfflineScreen(key: const ValueKey('offline'), onRetry: _retry);
        break;
      case GateStep.agreement:
        page = AgreementScreen(
          key: const ValueKey('agreement'),
          onAgree: () async {
            await _flag('agreed');
            _agreed = true;
            if (mounted) setState(() => _step = _next());
          },
        );
        break;
      case GateStep.key:
        page = KeyScreen(
          key: const ValueKey('key'),
          onDone: () async {
            await _flag('setup_done');
            _setup = true;
            if (mounted) setState(() => _step = _next());
          },
        );
        break;
      case GateStep.manual:
        page = ManualScreen(
          key: const ValueKey('manual'),
          onDone: () async {
            await _flag('manual_seen');
            _manual = true;
            if (mounted) setState(() => _step = _next());
          },
        );
        break;
      case GateStep.home:
        page = const HomeShell(key: ValueKey('home'));
        break;
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: page,
    );
  }
}/// ইন্টারনেট না থাকলে অ্যাপে ঢোকার সময় এটা দেখায়।
class OfflineScreen extends StatelessWidget {
  final VoidCallback onRetry;
  const OfflineScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GasiBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.red.withOpacity(0.12),
                      border: Border.all(
                          color: AppColors.red.withOpacity(0.5), width: 2),
                    ),
                    child: const Icon(Icons.wifi_off_rounded,
                        size: 52, color: AppColors.red),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    tr('ইন্টারনেট সংযোগ নেই', 'No internet connection'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tr('অনুগ্রহ করে ইন্টারনেট চালু করে আবার চেষ্টা করুন।',
                        'Please check your internet and try again.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14, height: 1.5, color: Color(0xFF9AA4D8)),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: 220,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: Text(tr('আবার চেষ্টা করুন', 'Try again'),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// শুরুর লোডিং: পেছনে নিয়ন টাইলের ঢেউ, সামনে GX লোগো, স্থির গোল রিং, ভেতরে নরম পালস।
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _c;
  late final AnimationController _w;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _w = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    _w.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GasiBackground(
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _w,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: TileWavePainter(_w.value * 120.0),
                    );
                  },
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.85,
                    colors: [
                      const Color(0xFF0B0A0E).withOpacity(0.55),
                      const Color(0xFF0B0A0E).withOpacity(0.86),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) {
                      final t = Curves.easeInOut.transform(_c.value);
                      return SizedBox(
                        width: 230,
                        height: 230,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 150 + 44 * t,
                              height: 150 + 44 * t,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.purple
                                    .withOpacity(0.10 + 0.22 * t),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.purple
                                        .withOpacity(0.25 + 0.35 * t),
                                    blurRadius: 30 + 30 * t,
                                    spreadRadius: 2 + 6 * t,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 206,
                              height: 206,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.lilac.withOpacity(0.85),
                                  width: 4,
                                ),
                              ),
                            ),
                            ClipOval(child: gxLogo(112)),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'gasi candle analysis AI',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Loading…',
                    style: TextStyle(fontSize: 13, color: Color(0xFFB9B3E0)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}/// স্প্ল্যাশের পেছনের ওঠানামা করা নিয়ন টাইলের ঢেউ।
class TileWavePainter extends CustomPainter {
  final double t;
  TileWavePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.5;
    const tw = 86.0;
    const th = 50.0;
    const stepX = tw / 2 + 5;
    const stepY = th / 2 + 3;

    final fill = Paint()..style = PaintingStyle.fill;
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round;
    final glow = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final spark = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    Path diamond(double x, double y, double w, double h) {
      return Path()
        ..moveTo(x, y - h / 2)
        ..lineTo(x + w / 2, y)
        ..lineTo(x, y + h / 2)
        ..lineTo(x - w / 2, y)
        ..close();
    }

    for (int s = -20; s <= 20; s++) {
      for (int d = -14; d <= 14; d++) {
        if ((s + d) % 2 != 0) continue;
        final x = cx + d * stepX;
        final y = cy + s * stepY;
        if (x < -tw || x > size.width + tw) continue;
        if (y < -th - 40 || y > size.height + th + 40) continue;

        final r = _gDist(s.toDouble(), d.toDouble()) / 1.414;
        final raise = 0.5 + 0.5 * _gSin(t * 1.9 - r * 0.62);
        final z = raise * 18;
        final mix = 0.5 + 0.5 * _gSin(r * 0.3 - t * 0.8);
        final neon = Color.lerp(
          const Color(0xFF8B5CF6),
          const Color(0xFFFF3DCB),
          mix,
        )!;

        // নিচের ফাঁকে নিয়ন আলো (টাইল নামলে বেশি)
        glow.color = neon.withOpacity(0.55 * (1 - raise) + 0.05);
        canvas.drawPath(diamond(x, y + 6, tw + 8, th + 6), glow);

        final depth = 10.0 + z;
        final top = y - z;

        final left = Path()
          ..moveTo(x - tw / 2, top)
          ..lineTo(x, top + th / 2)
          ..lineTo(x, top + th / 2 + depth)
          ..lineTo(x - tw / 2, top + depth)
          ..close();
        final right = Path()
          ..moveTo(x + tw / 2, top)
          ..lineTo(x, top + th / 2)
          ..lineTo(x, top + th / 2 + depth)
          ..lineTo(x + tw / 2, top + depth)
          ..close();
        fill.color = const Color(0xFF120E1C);
        canvas.drawPath(left, fill);
        fill.color = const Color(0xFF191426);
        canvas.drawPath(right, fill);

        final topPath = diamond(x, top, tw, th);
        fill.color = const Color(0xFF241D35);
        canvas.drawPath(topPath, fill);
        edge.color = neon.withOpacity(0.18 + 0.7 * raise);
        canvas.drawPath(topPath, edge);

        // মাঝে মাঝে ঝলক
        if (((s * 31 + d * 17) % 19).abs() == 0) {
          final ph = _gSin(t * 3.0 + s * 0.7 + d * 0.4);
          if (ph > 0.9) {
            spark.color = Colors.white.withOpacity((ph - 0.9) * 9);
            canvas.drawCircle(Offset(x + tw / 4, top + th / 4), 3.5, spark);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant TileWavePainter old) => old.t != t;
}

class AgreementScreen extends StatefulWidget {
  final VoidCallback onAgree;
  const AgreementScreen({super.key, required this.onAgree});

  @override
  State<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen>
    with LangAware<AgreementScreen> {
  bool _ok = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GasiBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Align(
                  alignment: Alignment.centerRight,
                  child: LanguageSwitch(),
                ),
                const SizedBox(height: 14),
                const Text('User Agreement',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  tr('চালিয়ে যাওয়ার আগে এটি পড়ুন (চুক্তি ইংরেজিতে)',
                      'Please read this before you continue'),
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF8F8993)),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: cardDeco(),
                    child: const SingleChildScrollView(
                      child: Text(
                        kAgreementText,
                        style: TextStyle(
                            fontSize: 13.5,
                            height: 1.55,
                            color: Color(0xFFD8D3DD)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => setState(() => _ok = !_ok),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _ok,
                        activeColor: AppColors.purple,
                        onChanged: (v) => setState(() => _ok = v == true),
                      ),
                      const Expanded(
                        child: Text(
                          'I have read and agree to the User Agreement.',
                          style: TextStyle(fontSize: 13.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () =>
                        showTextDialog(context, 'Privacy Policy', kPrivacyText),
                    child: const Text('Privacy Policy',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _ok ? widget.onAgree : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Agree & Continue',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}/// প্রথমবার ইনস্টলের পর একবারই আসে। পরে বদলাতে হলে অ্যাকাউন্ট পেজ থেকে।
class KeyScreen extends StatefulWidget {
  final VoidCallback onDone;
  const KeyScreen({super.key, required this.onDone});

  @override
  State<KeyScreen> createState() => _KeyScreenState();
}

class _KeyScreenState extends State<KeyScreen>
    with LangAware<KeyScreen> {
  static const _ch = MethodChannel('gasi/native');
  final _c = TextEditingController();
  bool _hide = true;
  bool _busy = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final k = _c.text.trim();
    if (k.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await _ch.invokeMethod('saveApiKey', {'key': k});
    } catch (_) {}
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GasiBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: cardDeco(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.key, size: 30, color: AppColors.lilac),
                    const SizedBox(height: 12),
                    Text(
                        tr('আপনার Gemini API key দিন',
                            'Enter your Gemini API key'),
                        style: const TextStyle(
                            fontSize: 21, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(
                      tr(
                          'aistudio.google.com/apikey থেকে বিনামূল্যে key নিন। key শুধু এই ফোনে থাকবে। এটা শুধু এই প্রথমবারই জিজ্ঞেস করা হবে, পরে বদলাতে হলে অ্যাকাউন্ট পেজ থেকে বদলাবেন।',
                          'Get a free key from aistudio.google.com/apikey. The key stays only on this phone. You are asked only this once; to change it later, open the Account page.'),
                      style: const TextStyle(
                          fontSize: 13, height: 1.5, color: Color(0xFF8F8993)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _c,
                      obscureText: _hide,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'AIza...',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                              _hide ? Icons.visibility : Icons.visibility_off,
                              size: 20),
                          onPressed: () => setState(() => _hide = !_hide),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _busy ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(tr('সেভ করে শুরু করুন', 'Save and start'),
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: TextButton(
                        onPressed: _busy ? null : widget.onDone,
                        child: Text(
                            tr('এখন না, পরে অ্যাকাউন্ট থেকে দেব',
                                'Not now, I will add it later in Account'),
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF8F8993))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
const double kPi = 3.141592653589793;

double _gSin(double a) => Offset.fromDirection(a, 1.0).dy;
double _gCos(double a) => Offset.fromDirection(a, 1.0).dx;
double _gDist(double x, double y) => Offset(x, y).distance;

// মহাদেশের মোটামুটি আকার (lon, lat জোড়ায়)। শুধু বিন্দুর পৃথিবী আঁকার জন্য।
const List<List<double>> kLandPolys = [
  // উত্তর আমেরিকা
  [-168, 66, -160, 70, -140, 70, -125, 70, -95, 72, -80, 70, -62, 60, -55, 50, -67, 45, -70, 42, -76, 35, -81, 30, -80, 25, -84, 30, -90, 29, -97, 26, -97, 20, -92, 18, -87, 21, -83, 10, -78, 8, -80, 8, -86, 12, -92, 15, -105, 20, -110, 24, -115, 30, -118, 34, -124, 40, -124, 48, -130, 54, -140, 60, -150, 60, -165, 60],
  // দক্ষিণ আমেরিকা
  [-78, 8, -72, 12, -62, 10, -52, 5, -50, 0, -35, -5, -38, -14, -40, -22, -48, -26, -58, -35, -65, -42, -68, -52, -72, -54, -75, -48, -73, -38, -71, -28, -70, -18, -76, -12, -81, -5, -80, 0],
  // ইউরেশিয়া
  [-10, 36, -9, 43, -1, 46, -5, 48, 2, 51, 8, 54, 8, 58, 5, 62, 14, 68, 25, 71, 40, 68, 60, 70, 80, 73, 100, 77, 120, 73, 140, 72, 160, 70, 180, 68, 180, 65, 170, 60, 160, 55, 155, 58, 142, 52, 140, 45, 130, 42, 127, 36, 122, 40, 120, 30, 122, 25, 110, 20, 108, 12, 105, 9, 100, 13, 100, 5, 103, 1, 98, 8, 98, 16, 92, 22, 88, 22, 80, 15, 77, 8, 73, 17, 70, 22, 66, 25, 58, 25, 56, 27, 50, 30, 48, 29, 44, 24, 40, 20, 35, 28, 35, 32, 36, 36, 30, 36, 27, 37, 26, 40, 23, 40, 22, 37, 19, 41, 16, 38, 12, 38, 9, 44, 3, 43, -2, 37, -6, 36],
  // আফ্রিকা
  [-17, 21, -16, 28, -10, 35, 0, 36, 10, 37, 20, 32, 32, 31, 35, 28, 33, 22, 37, 18, 43, 12, 51, 12, 48, 5, 40, -3, 40, -15, 35, -24, 32, -29, 27, -34, 20, -35, 18, -30, 14, -22, 12, -12, 13, -5, 9, 3, 5, 5, -5, 5, -10, 6, -16, 12],
  // অস্ট্রেলিয়া
  [114, -22, 122, -18, 130, -12, 137, -12, 142, -11, 146, -19, 153, -26, 151, -34, 146, -39, 138, -35, 130, -32, 115, -34],
  // গ্রিনল্যান্ড
  [-55, 60, -45, 60, -20, 70, -18, 80, -40, 83, -65, 80, -72, 76],
  // ব্রিটেন
  [-6, 50, 1, 51, 2, 53, -2, 57, -5, 58, -6, 55, -3, 54],
  // জাপান
  [130, 31, 135, 34, 140, 36, 142, 40, 141, 45, 138, 40, 132, 35],
  // বোর্নিও
  [109, 2, 117, 7, 119, 1, 116, -4, 110, -3],
  // সুমাত্রা
  [95, 5, 98, 4, 106, -3, 105, -6, 100, -2],
  // মাদাগাস্কার
  [44, -25, 50, -15, 49, -12, 44, -17],
];

bool _isLand(double lon, double lat) {
  for (final poly in kLandPolys) {
    bool inside = false;
    final n = poly.length ~/ 2;
    int j = n - 1;
    for (int i = 0; i < n; i++) {
      final xi = poly[i * 2];
      final yi = poly[i * 2 + 1];
      final xj = poly[j * 2];
      final yj = poly[j * 2 + 1];
      if (((yi > lat) != (yj > lat)) &&
          (lon < (xj - xi) * (lat - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }
    if (inside) return true;
  }
  return false;
}

/// গোলকের বিন্দুগুলো একবারই হিসাব হয়: [x0, y0, z0] ক্রমে।
class GlobeData {
  static List<double>? _land;
  static List<double>? _ocean;

  static List<double> get land {
    _land ??= _build(3.0, true);
    return _land!;
  }

  static List<double> get ocean {
    _ocean ??= _build(8.0, false);
    return _ocean!;
  }

  static List<double> _build(double step, bool wantLand) {
    final out = <double>[];
    for (double lat = -80; lat <= 84; lat += step) {
      final la = lat * kPi / 180;
      final cl = _gCos(la);
      final lonStep = step / (cl < 0.2 ? 0.2 : cl);
      for (double lon = -180; lon < 180; lon += lonStep) {
        if (_isLand(lon, lat) != wantLand) continue;
        final lo = lon * kPi / 180;
        out.add(cl * _gSin(lo));
        out.add(_gSin(la));
        out.add(cl * _gCos(lo));
      }
    }
    return out;
  }
}class GlobeModel extends ChangeNotifier {
  double angle = 0;
  double time = 0;
  double speed = 0.18;

  void update(double a, double t, double s) {
    angle = a;
    time = t;
    speed = s;
    notifyListeners();
  }
}

class GlobePainter extends CustomPainter {
  final GlobeModel m;
  GlobePainter(this.m) : super(repaint: m);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.9;
    final double boost = ((m.speed - 0.18) / 2.0).clamp(0.0, 1.0).toDouble();
    final pulse = 0.8 + 0.2 * _gSin(m.time * 2.0);
    final bright = (0.78 + 0.22 * boost) * pulse;

    // বাইরের আভা
    canvas.drawCircle(
      center,
      radius * 1.14,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0x00000000),
            const Color(0x00000000),
            Color.fromARGB((60 + 70 * boost).round(), 70, 90, 255),
            const Color(0x00000000),
          ],
          stops: const [0.0, 0.78, 0.92, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.14)),
    );

    // গোলকের ভেতরটা
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.35),
          radius: 1.0,
          colors: [
            const Color(0xFF1B2A8A).withOpacity(0.55),
            const Color(0xFF070B2E).withOpacity(0.9),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    final ca = _gCos(m.angle);
    final sa = _gSin(m.angle);
    const tilt = 0.38;
    final ct = _gCos(tilt);
    final st = _gSin(tilt);

    final low = <Offset>[];
    final mid = <Offset>[];
    final high = <Offset>[];

    void project(List<double> pts, List<Offset> lo, List<Offset> mi,
        List<Offset> hi) {
      for (int i = 0; i + 2 < pts.length; i += 3) {
        final x0 = pts[i];
        final y0 = pts[i + 1];
        final z0 = pts[i + 2];
        final x = x0 * ca + z0 * sa;
        final zr = -x0 * sa + z0 * ca;
        final y = y0 * ct - zr * st;
        final z = y0 * st + zr * ct;
        if (z <= 0.02) continue;
        final o = Offset(center.dx + x * radius, center.dy - y * radius);
        if (z < 0.35) {
          lo.add(o);
        } else if (z < 0.7) {
          mi.add(o);
        } else {
          hi.add(o);
        }
      }
    }

    // সমুদ্রের ক্ষীণ বিন্দু
    final oLow = <Offset>[];
    final oMid = <Offset>[];
    final oHigh = <Offset>[];
    project(GlobeData.ocean, oLow, oMid, oHigh);
    final op = Paint()
      ..color = const Color(0xFF5B7BFF).withOpacity(0.16 * bright);
    for (final o in oMid) {
      canvas.drawCircle(o, 0.7, op);
    }
    for (final o in oHigh) {
      canvas.drawCircle(o, 0.7, op);
    }

    // স্থলের বিন্দু
    project(GlobeData.land, low, mid, high);
    final lp = Paint();
    lp.color = const Color(0xFF6F8CFF).withOpacity(0.35 * bright);
    for (final o in low) {
      canvas.drawCircle(o, 0.8, lp);
    }
    lp.color = const Color(0xFF8CA4FF).withOpacity(0.7 * bright);
    for (final o in mid) {
      canvas.drawCircle(o, 1.15, lp);
    }
    lp.color = const Color(0xFFBFD0FF).withOpacity(0.95 * bright);
    for (final o in high) {
      canvas.drawCircle(o, 1.5, lp);
    }

    // কিছু উজ্জ্বল নোড ও সংযোগ রেখা
    final land = GlobeData.land;
    final count = land.length ~/ 3;
    final nodes = <Offset>[];
    final nodeZ = <double>[];
    if (count > 40) {
      for (int k = 0; k < 14; k++) {
        final idx = (count ~/ 14) * k + 3;
        final x0 = land[idx * 3];
        final y0 = land[idx * 3 + 1];
        final z0 = land[idx * 3 + 2];
        final x = x0 * ca + z0 * sa;
        final zr = -x0 * sa + z0 * ca;
        final y = y0 * ct - zr * st;
        final z = y0 * st + zr * ct;
        nodes.add(Offset(center.dx + x * radius, center.dy - y * radius));
        nodeZ.add(z);
      }
    }
    final line = Paint()
      ..strokeWidth = 0.8
      ..color = const Color(0xFF8CA4FF).withOpacity(0.28 * bright);
    for (int a = 0; a < nodes.length; a++) {
      for (final b in [a + 1, a + 4]) {
        if (b >= nodes.length) continue;
        if (nodeZ[a] > 0.1 && nodeZ[b] > 0.1) {
          canvas.drawLine(nodes[a], nodes[b], line);
        }
      }
    }
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.9 * bright)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (int a = 0; a < nodes.length; a++) {
      if (nodeZ[a] > 0.1) {
        canvas.drawCircle(nodes[a], 2.6 + 1.2 * pulse, glowPaint);
      }
    }

    // কিনারার রিং
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..shader = const SweepGradient(
          colors: [
            Color(0xFF6C7BFF),
            Color(0xFFB65CFF),
            Color(0xFF3B82FF),
            Color(0xFF6C7BFF),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant GlobePainter old) => false;
}/// দুই পাশের মোমবাতি: ধীরে ওঠানামা করে ও ঝলমল করে, Start চাপলে দ্রুত নড়ে।
class CandleSidesPainter extends CustomPainter {
  final GlobeModel m;
  CandleSidesPainter(this.m) : super(repaint: m);

  @override
  void paint(Canvas canvas, Size size) {
    final double boost = ((m.speed - 0.18) / 2.0).clamp(0.0, 1.0).toDouble();
    final t = m.time * 1.1 + m.angle * 2.0;
    final mid = size.height * 0.5;
    for (int side = 0; side < 2; side++) {
      for (int i = 0; i < 5; i++) {
        final x = side == 0 ? 16.0 + i * 15.0 : size.width - 16.0 - i * 15.0;
        final ph = i * 0.9 + side * 1.9;
        final wave = _gSin(t + ph);
        final wave2 = _gSin(t * 0.63 + ph * 1.7);
        final bodyH = 30.0 + 26.0 * (0.5 + 0.5 * wave2);
        final cy = mid + (46.0 + 14.0 * boost) * wave + (i - 2) * 8.0;
        final top = cy - bodyH / 2;
        final bullish = _gSin(t * 0.5 + ph * 2.3) > 0;
        final base = bullish ? const Color(0xFF38D996) : const Color(0xFFB65CFF);
        final color =
            Color.lerp(const Color(0xFF6C58D6), base, 0.45)!;
        final shimmer = 0.5 + 0.5 * _gSin(t * 2.2 + ph * 3.0);
        final alpha = 0.50 + 0.30 * shimmer + 0.15 * boost;

        // আভা
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 6, top - 2, 12, bodyH + 4),
            const Radius.circular(5),
          ),
          Paint()
            ..color = color.withOpacity(0.28 * alpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
        // সলতে (wick)
        canvas.drawLine(
          Offset(x, top - 16 - 6 * wave2),
          Offset(x, top + bodyH + 16 + 6 * wave),
          Paint()
            ..color = color.withOpacity(alpha)
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round,
        );
        // দেহ
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 5, top, 10, bodyH),
            const Radius.circular(3),
          ),
          Paint()..color = color.withOpacity(alpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CandleSidesPainter old) => false;
}

/// গোলকের নিচের আলোর রিং।
class PlatformPainter extends CustomPainter {
  final GlobeModel m;
  PlatformPainter(this.m) : super(repaint: m);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final pulse = 0.7 + 0.3 * _gSin(m.time * 2.2);
    for (int i = 0; i < 3; i++) {
      final w = size.width * (1.0 - i * 0.28);
      final h = size.height * (1.0 - i * 0.28);
      final rect = Rect.fromCenter(center: c, width: w, height: h);
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = const Color(0xFF3B5BFF).withOpacity(0.35 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0xFF8C7BFF).withOpacity(0.85 * pulse),
      );
    }
  }

  @override
  bool shouldRepaint(covariant PlatformPainter old) => false;
}

/// স্টার্ট বাটনের ভেতরের ছোট তিনটা মোমবাতি।
class MiniCandlesPainter extends CustomPainter {
  final Color color;
  MiniCandlesPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final w = Paint()
      ..color = color
      ..strokeWidth = 2;
    final hs = [0.45, 0.7, 0.95];
    final tops = [0.4, 0.2, 0.0];
    for (int i = 0; i < 3; i++) {
      final x = size.width * (0.18 + i * 0.32);
      final top = size.height * tops[i];
      final h = size.height * hs[i] * 0.7;
      canvas.drawLine(Offset(x, top), Offset(x, top + h + 6), w);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 5, top + 4, 10, h),
          const Radius.circular(3),
        ),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MiniCandlesPainter old) => old.color != color;
}

/// পৃথিবী + পাশের মোমবাতি + নিচের রিং + মাঝের স্টার্ট বাটন।
class GlobeHero extends StatefulWidget {
  final bool running;
  final bool busy;
  final VoidCallback onTap;
  const GlobeHero({
    super.key,
    required this.running,
    required this.busy,
    required this.onTap,
  });

  @override
  State<GlobeHero> createState() => _GlobeHeroState();
}

class _GlobeHeroState extends State<GlobeHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final GlobeModel _m = GlobeModel();
  double _last = 0;
  double _angle = 0;
  double _speed = 0.18;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(hours: 1));
    _ctrl.addListener(_tick);
    _ctrl.forward();
  }

  void _tick() {
    final t = _ctrl.value * 3600.0;
    double dt = t - _last;
    _last = t;
    if (dt < 0) dt = 0;
    if (dt > 0.1) dt = 0.1;
    final target = widget.running ? 2.2 : 0.18;
    double k = dt * 2.5;
    if (k > 1) k = 1;
    _speed += (target - _speed) * k;
    _angle += dt * _speed;
    _m.update(_angle, t, _speed);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth > 420 ? 420.0 : box.maxWidth;
        final globe = w * 0.84;
        final height = w * 1.08;
        final btn = w * 0.36;
        return SizedBox(
          width: w,
          height: height,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(painter: CandleSidesPainter(_m)),
                ),
              ),
              Positioned(
                top: globe * 0.86,
                child: SizedBox(
                  width: w * 0.8,
                  height: w * 0.22,
                  child: RepaintBoundary(
                    child: CustomPaint(painter: PlatformPainter(_m)),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                child: SizedBox(
                  width: globe,
                  height: globe,
                  child: RepaintBoundary(
                    child: CustomPaint(painter: GlobePainter(_m)),
                  ),
                ),
              ),
              Positioned(
                top: 4 + (globe - btn) / 2,
                child: StartButton(
                  size: btn,
                  running: widget.running,
                  busy: widget.busy,
                  onTap: widget.onTap,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}class StartButton extends StatelessWidget {
  final double size;
  final bool running;
  final bool busy;
  final VoidCallback onTap;
  const StartButton({
    super.key,
    required this.size,
    required this.running,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ring = running
        ? const [Color(0xFFFF6685), Color(0xFFB65CFF), Color(0xFFFF6685)]
        : const [Color(0xFFB65CFF), Color(0xFF6C7BFF), Color(0xFFB65CFF)];
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(colors: ring),
          boxShadow: [
            BoxShadow(
              color: ring[0].withOpacity(0.55),
              blurRadius: 26,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0xFF1B1550), Color(0xFF0B0A24)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                SizedBox(
                  width: size * 0.2,
                  height: size * 0.2,
                  child: const CircularProgressIndicator(strokeWidth: 3),
                )
              else
                SizedBox(
                  width: size * 0.3,
                  height: size * 0.26,
                  child: CustomPaint(
                    painter: MiniCandlesPainter(
                      running ? const Color(0xFFFF9DB0) : Colors.white,
                    ),
                  ),
                ),
              SizedBox(height: size * 0.06),
              Text(
                running ? 'Tap to Stop' : 'Tap to Start',
                style: TextStyle(
                  fontSize: size * 0.105,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                running ? 'Analysis on' : 'Analysis',
                style: TextStyle(
                  fontSize: size * 0.085,
                  color: const Color(0xFFB9B3E0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ============================================================
// অ্যানিমেটেড আইকন: ১) বানর ও বল  ২) শিকারি ও পাখি
// ============================================================
double _ease(double x) {
  final t = x < 0 ? 0.0 : (x > 1 ? 1.0 : x);
  return t * t * (3 - 2 * t);
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// বানর বল ছোড়ে, বল সামনে গিয়ে ফিরে এসে বানরকে লাগে, বানর পড়ে যায়, আবার উঠে বল ছোড়ে।
class MonkeyIcon extends StatefulWidget {
  final double size;
  const MonkeyIcon({super.key, this.size = 56});

  @override
  State<MonkeyIcon> createState() => _MonkeyIconState();
}

class _MonkeyIconState extends State<MonkeyIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4400),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return CustomPaint(painter: _MonkeyPainter(_c.value));
        },
      ),
    );
  }
}class _MonkeyPainter extends CustomPainter {
  final double u;
  _MonkeyPainter(this.u);

  static const Color _fur = Color(0xFF8B5A2B);
  static const Color _face = Color(0xFFEAC99B);
  static const Color _ball = Color(0xFFFF8A3D);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    // মাটি
    canvas.drawLine(
      const Offset(6, 88),
      const Offset(94, 88),
      Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    // সময়রেখা
    double rot = 0; // ঋণাত্মক = পেছনে পড়া
    double arm = 1.2; // 0 = সামনে, ঋণাত্মক = ওপরে
    bool ballInHand = true;
    Offset ballPos = const Offset(0, 0);
    bool showBall = true;
    bool dizzy = false;

    if (u < 0.12) {
      arm = _lerp(1.2, -2.4, _ease(u / 0.12));
    } else if (u < 0.20) {
      arm = _lerp(-2.4, -0.2, _ease((u - 0.12) / 0.08));
    } else if (u < 0.50) {
      ballInHand = false;
      final k = (u - 0.20) / 0.30;
      arm = _lerp(-0.2, 1.2, _ease(k * 2));
      final x = _lerp(52, 94, k);
      final y = 54 - 16 * _gSin(k * kPi);
      ballPos = Offset(x, y);
    } else if (u < 0.72) {
      ballInHand = false;
      arm = 1.2;
      final k = (u - 0.50) / 0.22;
      final x = _lerp(94, 40, k);
      final y = 56 - 10 * _gSin(k * kPi) + 4 * k;
      ballPos = Offset(x, y);
    } else if (u < 0.84) {
      ballInHand = false;
      arm = 1.2;
      final k = _ease((u - 0.72) / 0.12);
      rot = -1.45 * k;
      dizzy = true;
      ballPos = Offset(_lerp(40, 54, k), _lerp(60, 84, k));
    } else if (u < 0.92) {
      ballInHand = false;
      arm = 1.2;
      rot = -1.45;
      dizzy = true;
      ballPos = const Offset(56, 84);
    } else if (u < 0.97) {
      ballInHand = false;
      arm = 1.2;
      rot = -1.45 * (1 - _ease((u - 0.92) / 0.05));
      ballPos = const Offset(56, 84);
    } else {
      ballInHand = false;
      showBall = false;
      arm = 1.2;
    }

    // বানর (পায়ের গোড়ালিতে ঘুরে পড়ে)
    canvas.save();
    canvas.translate(32, 88);
    canvas.rotate(rot);
    canvas.translate(-32, -88);

    final fur = Paint()..color = _fur;
    final dark = Paint()..color = const Color(0xFF5E3A18);
    final face = Paint()..color = _face;

    // লেজ
    final tail = Path()
      ..moveTo(24, 72)
      ..quadraticBezierTo(8, 70, 12, 52)
      ..quadraticBezierTo(14, 46, 19, 49);
    canvas.drawPath(
      tail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = _fur,
    );

    // পা
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(24, 78, 8, 10), const Radius.circular(4)),
      dark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(34, 78, 8, 10), const Radius.circular(4)),
      dark,
    );
    // শরীর
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(22, 54, 22, 28), const Radius.circular(10)),
      fur,
    );
    canvas.drawOval(Rect.fromLTWH(27, 60, 12, 16), face);

    // পেছনের হাত
    canvas.drawLine(
      const Offset(25, 60),
      const Offset(19, 74),
      Paint()
        ..color = _fur
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    // মাথা ও কান
    canvas.drawCircle(const Offset(23, 40), 5, fur);
    canvas.drawCircle(const Offset(23, 40), 2.6, face);
    canvas.drawCircle(const Offset(45, 40), 5, fur);
    canvas.drawCircle(const Offset(45, 40), 2.6, face);
    canvas.drawCircle(const Offset(34, 41), 13, fur);
    canvas.drawOval(Rect.fromLTWH(28, 41, 17, 13), face);
    // চোখ (সামনে তাকিয়ে)
    canvas.drawCircle(const Offset(35, 41), 2.6, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(42, 41), 2.6, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(36.2, 41.2), 1.3, Paint()..color = Colors.black);
    canvas.drawCircle(const Offset(43.2, 41.2), 1.3, Paint()..color = Colors.black);
    // মুখ
    canvas.drawArc(
      Rect.fromLTWH(34, 46, 8, 6),
      0.2,
      2.7,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF5E3A18),
    );

    // সামনের (ছোড়ার) হাত
    const shoulder = Offset(40, 60);
    final hand = Offset(
      shoulder.dx + 17 * _gCos(arm),
      shoulder.dy + 17 * _gSin(arm),
    );
    canvas.drawLine(
      shoulder,
      hand,
      Paint()
        ..color = _fur
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(hand, 3.4, face);

    if (ballInHand) {
      ballPos = Offset(hand.dx + 2, hand.dy - 3);
    }
    canvas.restore();

    // বল
    if (showBall) {
      canvas.drawCircle(ballPos, 5.2, Paint()..color = _ball);
      canvas.drawCircle(
          Offset(ballPos.dx - 1.6, ballPos.dy - 1.6), 1.6,
          Paint()..color = Colors.white.withOpacity(0.7));
    }

    // মাথা ঘোরা তারা
    if (dizzy) {
      final a = u * 40;
      for (int i = 0; i < 3; i++) {
        final ang = a + i * 2.09;
        final p = Offset(
          (rot < -0.5 ? 18.0 : 34.0) + 10 * _gCos(ang),
          (rot < -0.5 ? 66.0 : 24.0) + 4 * _gSin(ang),
        );
        canvas.drawCircle(p, 2.2, Paint()..color = const Color(0xFFFFE066));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MonkeyPainter old) => old.u != u;
}

/// আকাশে পাখি ওড়ে, শিকারি অনবরত গুলি করে, কিন্তু একটাও লাগে না।
class HunterBirdIcon extends StatefulWidget {
  final double size;
  const HunterBirdIcon({super.key, this.size = 56});

  @override
  State<HunterBirdIcon> createState() => _HunterBirdIconState();
}class _HunterBirdIconState extends State<HunterBirdIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 60))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return CustomPaint(painter: _HunterPainter(_c.value * 60.0));
        },
      ),
    );
  }
}

class _HunterPainter extends CustomPainter {
  final double t;
  _HunterPainter(this.t);

  static const Offset _shoulder = Offset(24, 72);

  Offset _bird(double tt) {
    final k = (tt * 0.22) % 1.0;
    final x = -8 + 116 * k;
    final y = 26 + 9 * _gSin(tt * 2.4) + 6 * _gSin(tt * 0.9);
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    canvas.clipRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, 100, 100), const Radius.circular(18)));

    // আকাশ
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 100, 100),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B2A6B), Color(0xFF4B6BFF), Color(0xFF9BB5FF)],
        ).createShader(Rect.fromLTWH(0, 0, 100, 100)),
    );
    // মেঘ
    final cloud = Paint()..color = Colors.white.withOpacity(0.35);
    final cx = 100 - ((t * 5) % 130);
    canvas.drawOval(Rect.fromLTWH(cx, 14, 22, 8), cloud);
    canvas.drawOval(Rect.fromLTWH(cx + 8, 10, 16, 9), cloud);
    // মাটি
    canvas.drawRect(
        Rect.fromLTWH(0, 88, 100, 12), Paint()..color = const Color(0xFF1F4D2B));

    // শিকারি
    final skin = Paint()..color = const Color(0xFFEAC99B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(14, 70, 14, 20), const Radius.circular(5)),
      Paint()..color = const Color(0xFF7A3B2E),
    );
    canvas.drawCircle(const Offset(21, 63), 6, skin);
    canvas.drawRect(Rect.fromLTWH(14, 56, 14, 4),
        Paint()..color = const Color(0xFF2E2A24));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(17, 51, 8, 7), const Radius.circular(2)),
      Paint()..color = const Color(0xFF2E2A24),
    );

    // নিশানা: কিছু আগের জায়গার দিকে (তাই লাগে না)
    final aimAt = _bird(t - 0.5);
    final aim = Offset(aimAt.dx - _shoulder.dx, aimAt.dy - _shoulder.dy).direction;
    final muzzle = Offset(
      _shoulder.dx + 24 * _gCos(aim),
      _shoulder.dy + 24 * _gSin(aim),
    );
    canvas.drawLine(
      _shoulder,
      muzzle,
      Paint()
        ..color = const Color(0xFF3A3A3A)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // গুলি
    const gap = 0.45;
    final base = (t / gap).floor();
    for (int j = 0; j < 3; j++) {
      final idx = base - j;
      final tFire = idx * gap;
      final age = t - tFire;
      if (age < 0 || age > 0.75) continue;
      final target = _bird(tFire - 0.5);
      final dir = Offset(target.dx - _shoulder.dx, target.dy - _shoulder.dy)
              .direction +
          (idx % 2 == 0 ? 0.17 : -0.2);
      final mz = Offset(
        _shoulder.dx + 24 * _gCos(dir),
        _shoulder.dy + 24 * _gSin(dir),
      );
      final d = age * 150;
      final p = Offset(mz.dx + d * _gCos(dir), mz.dy + d * _gSin(dir));
      final tail = Offset(p.dx - 8 * _gCos(dir), p.dy - 8 * _gSin(dir));
      canvas.drawLine(
        tail,
        p,
        Paint()
          ..color = const Color(0xFFFFE066).withOpacity(1 - age / 0.75)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
      if (age < 0.07) {
        canvas.drawCircle(
          mz,
          5 * (1 - age / 0.07),
          Paint()..color = const Color(0xFFFFB347).withOpacity(0.9),
        );
      }
    }

    // পাখি
    final b = _bird(t);
    final flap = _gSin(t * 16);
    final bodyPaint = Paint()..color = const Color(0xFFFF6685);
    final wing = Paint()
      ..color = const Color(0xFFFFB3C2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(b.dx - 1, b.dy), Offset(b.dx - 9, b.dy - 8 * flap - 2), wing);
    canvas.drawLine(
        Offset(b.dx + 1, b.dy), Offset(b.dx + 9, b.dy - 8 * flap - 2), wing);
    canvas.drawOval(
        Rect.fromCenter(center: b, width: 15, height: 9), bodyPaint);
    canvas.drawCircle(Offset(b.dx + 7, b.dy - 1), 3.4, bodyPaint);
    canvas.drawPath(
      Path()
        ..moveTo(b.dx + 10, b.dy - 2)
        ..lineTo(b.dx + 14, b.dy - 0.5)
        ..lineTo(b.dx + 10, b.dy + 0.8)
        ..close(),
      Paint()..color = const Color(0xFFFFD166),
    );
    canvas.drawCircle(Offset(b.dx + 7.8, b.dy - 1.8), 0.9, Paint()..color = Colors.black);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HunterPainter old) => old.t != t;
}
// ============================================================
// মূল কাঠামো: নিচে নেভিগেশন বার সহ চার পেজ
// ============================================================
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}class _HomeShellState extends State<HomeShell>
    with WidgetsBindingObserver, LangAware<HomeShell> {
  static const _ch = MethodChannel('gasi/native');

  int _tab = 0;
  int _tick = 0;
  bool _granted = false;
  bool _starting = false;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _refresh() async {
    try {
      final g = await _ch.invokeMethod<bool>('hasOverlayPermission');
      final r = await _ch.invokeMethod<bool>('isRunning');
      if (mounted) {
        setState(() {
          _granted = g == true;
          _running = r == true;
        });
      }
    } catch (_) {}
  }

  Future<void> _openOverlaySettings() async {
    try {
      await _ch.invokeMethod('openOverlaySettings');
    } catch (_) {}
  }

  Future<void> _toggle() async {
    if (_starting) return;
    if (_running) {
      try {
        await _ch.invokeMethod('stopOverlay');
      } catch (_) {}
      if (mounted) setState(() => _running = false);
      _snack(tr('Floating G বন্ধ হয়েছে', 'Floating G stopped'));
      return;
    }
    if (!_granted) {
      _snack(tr('আগে "Display over other apps" পারমিশন দিন',
          'Please allow "Display over other apps" first'));
      return;
    }
    setState(() => _starting = true);
    try {
      await _ch.invokeMethod('startOverlay');
      if (mounted) setState(() => _running = true);
      _snack(tr('Floating G চালু হয়েছে। চার্টে গিয়ে G চাপুন।',
          'Floating G is on. Go to your chart and tap G.'));
    } on PlatformException catch (e) {
      _snack(e.message ?? tr('শুরু করা যায়নি', 'Could not start'));
    } catch (_) {
      _snack(tr('শুরু করা যায়নি', 'Could not start'));
    }
    if (mounted) setState(() => _starting = false);
  }

  void _go(int i) {
    setState(() {
      _tab = i;
      _tick++;
    });
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GasiBackground(
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _tab,
            children: [
              HomePage(
                granted: _granted,
                running: _running,
                busy: _starting,
                onToggle: _toggle,
                onPermission: _openOverlaySettings,
                onSettings: _openSettings,
                onProfile: () => _go(3),
              ),
              HistoryPage(tick: _tick),
              AnalysisPage(tick: _tick),
              const AccountPage(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: GasiNavBar(
        index: _tab,
        running: _running,
        busy: _starting,
        onTab: _go,
        onCenter: _toggle,
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBox({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.purple.withOpacity(0.35)),
        ),
        child: Icon(icon, size: 24, color: const Color(0xFFD4CCFF)),
      ),
    );
  }
}/// প্রথম পেজ: নাম, পৃথিবী, স্টার্ট বাটন আর সময় বাছাই।
class HomePage extends StatelessWidget {
  final bool granted;
  final bool running;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onPermission;
  final VoidCallback onSettings;
  final VoidCallback onProfile;

  const HomePage({
    super.key,
    required this.granted,
    required this.running,
    required this.busy,
    required this.onToggle,
    required this.onPermission,
    required this.onSettings,
    required this.onProfile,
  });

  Widget _logo() {
    return Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF3B82FF), Color(0xFF8B5CF6)],
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => const Center(
            child: Text('GX',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      children: [
        Row(
          children: [
            _logo(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Gasi ',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white),
                        ),
                        TextSpan(
                          text: 'Candle',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.lilac),
                        ),
                      ],
                    ),
                  ),
                  const Text('Analysis AI',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            _IconBox(icon: Icons.settings_outlined, onTap: onSettings),
            const SizedBox(width: 8),
            _IconBox(icon: Icons.person_outline, onTap: onProfile),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Smarter Analysis  •  Better Decision',
          style: TextStyle(fontSize: 12, color: Color(0xFF9AA4D8)),
        ),
        const SizedBox(height: 14),
        Center(
          child: GlobeHero(running: running, busy: busy, onTap: onToggle),
        ),
        if (!granted) ...[
          const SizedBox(height: 6),
          PermissionNotice(onTap: onPermission),
          const SizedBox(height: 14),
        ],
        const TimeframePicker(),
      ],
    );
  }
}

class PermissionNotice extends StatelessWidget {
  final VoidCallback onTap;
  const PermissionNotice({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amber.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.amber.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.layers_outlined, color: AppColors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('Floating G চালাতে "Display over other apps" পারমিশন দরকার।',
                  'The floating G needs the "Display over other apps" permission.'),
              style: const TextStyle(fontSize: 12.5, height: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onTap,
            child: Text(tr('দিন', 'Allow')),
          ),
        ],
      ),
    );
  }
}

/// কত সময়ের পূর্বাভাস চাই: ১ মিনিট থেকে ৫ ঘণ্টা।
class TimeframePicker extends StatefulWidget {
  const TimeframePicker({super.key});

  @override
  State<TimeframePicker> createState() => _TimeframePickerState();
}class _TimeframePickerState extends State<TimeframePicker>
    with LangAware<TimeframePicker> {
  static const _ch = MethodChannel('gasi/native');
  static const List<int> _row1 = [1, 5, 15, 30];
  static const List<int> _row2 = [60, 120, 300];
  int _sel = 5;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _short(int m) => m >= 60 ? '${m ~/ 60}h' : '${m}m';

  Future<void> _load() async {
    try {
      final m = await _ch.invokeMethod<int>('getMinutes');
      if (mounted && m != null) setState(() => _sel = m);
    } catch (_) {}
  }

  Future<void> _pick(int m) async {
    setState(() => _sel = m);
    try {
      await _ch.invokeMethod('saveMinutes', {'minutes': m});
    } catch (_) {}
  }

  Widget _chip(int m) {
    final sel = _sel == m;
    return Expanded(
      child: GestureDetector(
        onTap: () => _pick(m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: sel
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF9B6BFF), Color(0xFF6A3DF5)],
                  )
                : null,
            color: sel ? null : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: sel ? AppColors.lilac : Colors.white.withOpacity(0.08),
              width: sel ? 1.6 : 1,
            ),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: AppColors.purple.withOpacity(0.5),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(Icons.schedule,
                  size: 19,
                  color: sel ? Colors.white : const Color(0xFF9AA4D8)),
              const SizedBox(height: 4),
              Text(
                _short(m),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: sel ? Colors.white : const Color(0xFFB9B3BF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _spaced(List<int> items) {
    final out = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      if (i > 0) out.add(const SizedBox(width: 8));
      out.add(_chip(items[i]));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.purple.withOpacity(0.25),
                  border: Border.all(color: AppColors.lilac.withOpacity(0.5)),
                ),
                child: const Icon(Icons.schedule, color: Color(0xFFD4CCFF)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Timeframe',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    Text(
                      tr('কত সময়ের পূর্বাভাস চান বাছুন',
                          'Select the forecast time'),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9AA4D8)),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_short(_sel)} ${tr('পূর্বাভাস', 'forecast')}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.lilac),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(children: _spaced(_row1)),
          const SizedBox(height: 8),
          Row(
            children: [
              ..._spaced(_row2),
              const SizedBox(width: 8),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            tr(
                '১৫ মিনিট বা তার বেশি সময়ের পূর্বাভাসে AI-র বিশ্লেষণ তুলনামূলক বেশি অর্থবহ, কারণ ১-৫ মিনিটে দাম বেশি এলোমেলো থাকে। বড় সময় বাছলে ১৫ মিনিট বা ১ ঘণ্টার চার্টের স্ক্রিনশট নিন।',
                'Forecasts of 15 minutes or more are comparatively more meaningful, because price is more random over 1-5 minutes. For a longer forecast, capture a 15 minute or 1 hour chart.'),
            style: const TextStyle(
                fontSize: 12, height: 1.5, color: Color(0xFF8F8993)),
          ),
        ],
      ),
    );
  }
}/// নিচের নেভিগেশন বার, মাঝে ক্যামেরা (স্টার্ট/স্টপ) বাটন।
class GasiNavBar extends StatelessWidget {
  final int index;
  final bool running;
  final bool busy;
  final ValueChanged<int> onTab;
  final VoidCallback onCenter;

  const GasiNavBar({
    super.key,
    required this.index,
    required this.running,
    required this.busy,
    required this.onTab,
    required this.onCenter,
  });

  Widget _item(IconData icon, String label, int i) {
    final sel = index == i;
    final color = sel ? AppColors.lilac : const Color(0xFF8F8FB8);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTab(i),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 26, color: color),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                  color: color)),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: sel ? 30 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.purple,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glow = running ? const Color(0xFFFF6685) : AppColors.purple;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 98,
        child: Stack(
          children: [
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              height: 72,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0E0C1A).withOpacity(0.96),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.purple.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Expanded(child: _item(Icons.home_rounded, tr('হোম', 'Home'), 0)),
                    Expanded(
                        child: _item(Icons.history, tr('ইতিহাস', 'History'), 1)),
                    const SizedBox(width: 84),
                    Expanded(
                        child: _item(Icons.bar_chart_rounded,
                            tr('বিশ্লেষণ', 'Analysis'), 2)),
                    Expanded(
                        child: _item(Icons.person_outline,
                            tr('অ্যাকাউন্ট', 'Account'), 3)),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: busy ? null : onCenter,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: running
                            ? const [Color(0xFFFF6685), Color(0xFFB65CFF)]
                            : const [Color(0xFFB65CFF), Color(0xFF5B3BFF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: glow.withOpacity(0.6),
                          blurRadius: 22,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      running ? Icons.stop_rounded : Icons.photo_camera_outlined,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _two(int n) => n < 10 ? '0$n' : '$n';

String _tfShort(int m) => m >= 60 ? '${m ~/ 60}h' : '${m}m';

/// ইতিহাসের একটা ফলাফল: ✅/❌ বসানো বা বদলানো যায়।
class HistoryTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final void Function(bool hit) onMark;
  const HistoryTile({super.key, required this.item, required this.onMark});

  String _when(num ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms.toInt());
    return '${_two(d.day)}/${_two(d.month)}  ${_two(d.hour)}:${_two(d.minute)}';
  }

  Widget _outcomeBtn(String label, bool sel, Color c, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? c.withOpacity(0.25) : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? c : Colors.white.withOpacity(0.08)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: sel ? c : const Color(0xFFB9B3BF))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = item;
    final up = (e['up'] as num?)?.toDouble() ?? 0;
    final down = (e['down'] as num?)?.toDouble() ?? 0;
    final isUp = up >= down;
    final c = isUp ? AppColors.green : AppColors.red;
    final asset = (e['asset'] as String?) ?? '';
    final mode = (e['mode'] as String?) ?? 'chart';
    final hit = (e['hit'] as num?)?.toInt() ?? -1;
    final modeText = mode == 'live'
        ? tr('আসল ডাটা', 'Real data')
        : (mode == 'web'
            ? tr('ওয়েবসহ', 'With web')
            : tr('শুধু চার্ট', 'Chart only'));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  asset.isEmpty ? tr('অজানা মার্কেট', 'Unknown market') : asset,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              Text(_when((e['id'] as num?) ?? 0),
                  style: const TextStyle(
                      fontSize: 11.5, color: Color(0xFF8F8993))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                isUp ? 'UP ${up.round()}%' : 'DOWN ${down.round()}%',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900, color: c),
              ),
              const SizedBox(width: 12),
              Text(
                  '${_tfShort(((e['minutes'] as num?) ?? 5).toInt())}  •  $modeText',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF9AA4D8))),
            ],
          ),
          if (((e['pattern'] as String?) ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text((e['pattern'] as String),
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFFB9B3BF))),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _outcomeBtn(tr('✅ মিলেছে', '✅ Matched'), hit == 1,
                  AppColors.green, () => onMark(true)),
              const SizedBox(width: 10),
              _outcomeBtn(tr('❌ মেলেনি', '❌ Missed'), hit == 0,
                  AppColors.red, () => onMark(false)),
            ],
          ),
        ],
      ),
    );
  }
}Future<List<Map<String, dynamic>>> _readHistory() async {
  const ch = MethodChannel('gasi/native');
  final out = <Map<String, dynamic>>[];
  try {
    final s = await ch.invokeMethod<String>('getHistory');
    if (s == null) return out;
    final list = jsonDecode(s) as List<dynamic>;
    for (final e in list) {
      out.add(Map<String, dynamic>.from(e as Map));
    }
  } catch (_) {}
  return out;
}

/// ইতিহাস: আগের সব ফলাফল, সাথে ✅/❌ বসানো যায়।
class HistoryPage extends StatefulWidget {
  final int tick;
  const HistoryPage({super.key, required this.tick});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with LangAware<HistoryPage> {
  static const _ch = MethodChannel('gasi/native');
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant HistoryPage old) {
    super.didUpdateWidget(old);
    if (old.tick != widget.tick) _load();
  }

  Future<void> _load() async {
    final l = await _readHistory();
    if (mounted) setState(() => _items = l);
  }

  Future<void> _mark(int index, bool hit) async {
    final e = _items[index];
    final id = (e['id'] as num).toInt();
    setState(() => e['hit'] = hit ? 1 : 0);
    try {
      await _ch.invokeMethod('markHistory', {'id': id, 'hit': hit});
    } catch (_) {}
  }

  Future<void> _clear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('ইতিহাস মুছবেন?', 'Clear history?')),
        content: Text(tr('সব ফলাফল মুছে যাবে। সফলতার হিসাব আলাদা থাকবে।',
            'All saved results will be removed. Your success record stays.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('না', 'No')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr('মুছুন', 'Clear')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _ch.invokeMethod('clearHistory');
    } catch (_) {}
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(tr('ইতিহাস', 'History'),
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w900)),
            ),
            if (_items.isNotEmpty)
              TextButton(
                onPressed: _clear,
                child: Text(tr('মুছুন', 'Clear'),
                    style: const TextStyle(color: Color(0xFF8F8993))),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          tr('ট্রেডের ফল জানার পর ✅ বা ❌ চেপে রাখুন, পরে বদলানোও যায়। এতেই সফলতার হার হিসাব হয়।',
              'After you know the trade result, tap ✅ or ❌. You can change it later. This is how your success rate is calculated.'),
          style: const TextStyle(
              fontSize: 12, height: 1.45, color: Color(0xFF8F8993)),
        ),
        const SizedBox(height: 16),
        if (_items.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: cardDeco(),
            child: Center(
              child: Text(
                tr('এখনও কোনো ফলাফল নেই। হোম পেজে Start চেপে চার্টে G চাপুন।',
                    'No results yet. Tap Start on the Home page, then tap G on your chart.'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, height: 1.5, color: Color(0xFF8F8993)),
              ),
            ),
          )
        else
          for (int i = 0; i < _items.length; i++)
            HistoryTile(item: _items[i], onMark: (hit) => _mark(i, hit)),
      ],
    );
  }
}

/// সফলতার হার পেজ: কতবার সফল, কতবার ব্যর্থ, আর পরে ফল বদলানো।
class SuccessRatePage extends StatefulWidget {
  const SuccessRatePage({super.key});

  @override
  State<SuccessRatePage> createState() => _SuccessRatePageState();
}class _SuccessRatePageState extends State<SuccessRatePage>
    with LangAware<SuccessRatePage> {
  static const _ch = MethodChannel('gasi/native');
  List<Map<String, dynamic>> _items = [];
  int _total = 0;
  int _hits = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l = await _readHistory();
    int t = 0;
    int h = 0;
    try {
      final r = await _ch.invokeMethod<List<dynamic>>('getStats');
      if (r != null && r.length >= 2) {
        t = (r[0] as num).toInt();
        h = (r[1] as num).toInt();
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _items = l;
        _total = t;
        _hits = h;
      });
    }
  }

  Future<void> _mark(int index, bool hit) async {
    final id = (_items[index]['id'] as num).toInt();
    try {
      await _ch.invokeMethod('markHistory', {'id': id, 'hit': hit});
    } catch (_) {}
    _load();
  }

  Widget _count(String label, int n, Color c) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: c.withOpacity(0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Text('$n',
                style: TextStyle(
                    fontSize: 30, fontWeight: FontWeight.w900, color: c)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Color(0xFFB9B3BF))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fails = _total - _hits;
    int unmarked = 0;
    for (final e in _items) {
      if (((e['hit'] as num?)?.toInt() ?? -1) == -1) unmarked++;
    }
    final rate = _total == 0 ? '—' : '${(_hits * 100 / _total).round()}%';
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GasiBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 4),
                  Text(tr('সফলতার হার', 'Success rate'),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: cardDeco(),
                child: Column(
                  children: [
                    Text(rate,
                        style: const TextStyle(
                            fontSize: 48, fontWeight: FontWeight.w900)),
                    Text(
                      tr('মোট $_total টা ট্রেডের হিসাবে',
                          'Based on $_total marked trades'),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8F8993)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _count(tr('✅ সফল', '✅ Success'), _hits, AppColors.green),
                        const SizedBox(width: 10),
                        _count(tr('❌ ব্যর্থ', '❌ Failed'), fails < 0 ? 0 : fails,
                            AppColors.red),
                        const SizedBox(width: 10),
                        _count(tr('⏳ বাকি', '⏳ Unmarked'), unmarked,
                            AppColors.amber),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                tr('ট্রেড শেষ হলে নিচের তালিকায় সফল বা ব্যর্থ বসান। ভুল হলে পরে আবার বদলাতে পারবেন।',
                    'When a trade ends, mark it as success or failed below. You can change it later if you made a mistake.'),
                style: const TextStyle(
                    fontSize: 12, height: 1.45, color: Color(0xFF8F8993)),
              ),
              const SizedBox(height: 16),
              if (_items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: cardDeco(),
                  child: Center(
                    child: Text(
                      tr('এখনও কোনো ফলাফল নেই।', 'No results yet.'),
                      style: const TextStyle(color: Color(0xFF8F8993)),
                    ),
                  ),
                )
              else
                for (int i = 0; i < _items.length; i++)
                  HistoryTile(
                      item: _items[i], onMark: (hit) => _mark(i, hit)),
            ],
          ),
        ),
      ),
    );
  }
}

/// বিশ্লেষণ পেজ: সফলতার হার।
class AnalysisPage extends StatefulWidget {
  final int tick;
  const AnalysisPage({super.key, required this.tick});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage>
    with LangAware<AnalysisPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      children: [
        Text(tr('বিশ্লেষণ', 'Analysis'),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(
          tr('AI-র দেওয়া দিক কতবার মিলেছে, আপনার নিজের দেওয়া ✅/❌ থেকে।',
              'How often the AI direction matched, based on your own ✅/❌ marks.'),
          style: const TextStyle(
              fontSize: 12, height: 1.45, color: Color(0xFF8F8993)),
        ),
        const SizedBox(height: 16),
        StatsCard(key: ValueKey(widget.tick)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: cardDeco(),
          child: Text(
            tr(
                'মনে রাখুন: পেআউট ৯৩% হলে লাভের জন্য প্রায় ৫২%-এর বেশি মিলতে হবে (ব্রেক-ইভেন)। ৫০টার বেশি ট্রেডের হিসাব না জমলে এই হারের ওপর ভরসা করবেন না।',
                'Remember: with a 93% payout you need about 52% or more matches to profit (break-even). Do not trust the rate until you have 50 or more marked trades.'),
            style: const TextStyle(
                fontSize: 12.5, height: 1.5, color: Color(0xFFB9B3BF)),
          ),
        ),
      ],
    );
  }
}

/// অ্যাকাউন্ট পেজ: চুক্তি, প্রাইভেসি পলিসি, ব্যবহার নির্দেশিকা।
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}class _AccountPageState extends State<AccountPage>
    with LangAware<AccountPage> {
  Widget _tile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: cardDeco(),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.lilac),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      children: [
        Text(tr('অ্যাকাউন্ট', 'Account'),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(
          tr('API key বদলাতে সেটিংস (ওপরের গিয়ার আইকন) খুলুন।',
              'To change your API keys, open Settings (the gear icon on the Home page).'),
          style: const TextStyle(
              fontSize: 12.5, height: 1.45, color: Color(0xFF8F8993)),
        ),
        const SizedBox(height: 16),
        _tile(Icons.menu_book_outlined, tr('ব্যবহার নির্দেশিকা', 'User Manual'),
            () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ManualPage()),
                )),
        _tile(Icons.description_outlined, 'User Agreement',
            () => showTextDialog(context, 'User Agreement', kAgreementText)),
        _tile(Icons.privacy_tip_outlined, 'Privacy Policy',
            () => showTextDialog(context, 'Privacy Policy', kPrivacyText)),
        const SizedBox(height: 8),
        Center(
          child: Text(
            tr('এটি একটি তথ্যমূলক সহায়ক অ্যাপ, ট্রেডিং পরামর্শ নয়।',
                'This is an informational helper app, not trading advice.'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF8F8993)),
          ),
        ),
      ],
    );
  }
}

/// সেটিংসের একটা ভাঁজ-করা সেকশন: ক্লিক করলে ভেতরের অংশ খোলে।
class SettingsSection extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  const SettingsSection({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: cardDeco(),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(widget.icon, color: AppColors.lilac),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: const TextStyle(
                                fontSize: 15.5, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(widget.subtitle,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF8F8993))),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _open
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: widget.child,
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// সেটিংসের যে সারিতে ক্লিক করলে নতুন পেজ খোলে।
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: cardDeco(),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: AppColors.lilac),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 15.5, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF8F8993))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// সেটিংস: আলাদা আলাদা সেকশনে সাজানো।
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}class _SettingsScreenState extends State<SettingsScreen>
    with LangAware<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GasiBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 4),
                  Text(tr('সেটিংস', 'Settings'),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 10),
              SettingsSection(
                icon: Icons.key,
                title: 'API key',
                subtitle: tr('Gemini ও Twelve Data key বদলান',
                    'Change Gemini and Twelve Data keys'),
                child: const KeysCard(),
              ),
              SettingsSection(
                icon: Icons.insights,
                title: tr('বিশ্লেষণের ধরন', 'Analysis mode'),
                subtitle: tr('ওয়েব সার্চ, আসল ক্যান্ডেল ডাটা, OTC মোড',
                    'Web search, real candle data, OTC mode'),
                child: const AnalysisOptionsCard(),
              ),
              SettingsSection(
                icon: Icons.palette_outlined,
                title: tr('কালার ও আইকন', 'Color and icon'),
                subtitle: tr('ভাসমান বাটন, কার্ড ও ব্যাকগ্রাউন্ড',
                    'Floating button, card and background'),
                child: AppearanceCard(onBg: (id) => bgNotifier.value = id),
              ),
              SettingsSection(
                icon: Icons.translate,
                title: tr('ভাষা', 'Language'),
                subtitle: tr('বাংলা / English', 'Bangla / English'),
                child: const LanguageCard(),
              ),
              SettingsSection(
                icon: Icons.battery_charging_full,
                title: tr('ব্যাকগ্রাউন্ডে চলা', 'Run in background'),
                subtitle: tr('ব্যাটারি সীমা বন্ধ করুন', 'Turn off battery limit'),
                child: const BatteryCard(),
              ),
              SettingsTile(
                icon: Icons.query_stats,
                title: tr('সফলতার হার', 'Success rate'),
                subtitle: tr('কতবার সফল, কতবার ব্যর্থ, ফল বদলান',
                    'How many succeeded or failed, edit results'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const SuccessRatePage()),
                ),
              ),
              SettingsTile(
                icon: Icons.menu_book_outlined,
                title: tr('ব্যবহার নির্দেশিকা', 'User Manual'),
                subtitle: tr('অ্যাপ কীভাবে কাজ করে', 'How the app works'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ManualPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ============================================================
// সেটিংস ও অ্যাকাউন্টের কার্ডগুলো
// ============================================================
class LanguageCard extends StatelessWidget {
  const LanguageCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDeco(),
      child: Row(
        children: [
          const Icon(Icons.translate, color: AppColors.lilac),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tr('অ্যাপের ভাষা', 'App language'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
          const LanguageSwitch(),
        ],
      ),
    );
  }
}

/// Gemini ও Twelve Data key বদলানোর কার্ড (সেটিংসে)।
class KeysCard extends StatefulWidget {
  const KeysCard({super.key});

  @override
  State<KeysCard> createState() => _KeysCardState();
}

class _KeysCardState extends State<KeysCard> with LangAware<KeysCard> {
  static const _ch = MethodChannel('gasi/native');
  final _g = TextEditingController();
  final _td = TextEditingController();
  bool _gCustom = false;
  bool _gAny = false;
  bool _tCustom = false;
  bool _tAny = false;
  bool _hide = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _g.dispose();
    _td.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final i = await _ch.invokeMethod<Map<dynamic, dynamic>>('getKeyInfo');
      if (i != null && mounted) {
        setState(() {
          _gCustom = i['gemini_custom'] == true;
          _gAny = i['gemini_any'] == true;
          _tCustom = i['td_custom'] == true;
          _tAny = i['td_any'] == true;
        });
      }
    } catch (_) {}
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _saveG() async {
    final k = _g.text.trim();
    if (k.isEmpty) return;
    try {
      await _ch.invokeMethod('saveApiKey', {'key': k});
      _g.clear();
      await _load();
      _snack(tr('Gemini key সেভ হয়েছে', 'Gemini key saved'));
    } catch (_) {}
  }

  Future<void> _saveTd() async {
    final k = _td.text.trim();
    if (k.isEmpty) return;
    try {
      await _ch.invokeMethod('saveTdKey', {'key': k});
      _td.clear();
      await _load();
      _snack(tr('Twelve Data key সেভ হয়েছে', 'Twelve Data key saved'));
    } catch (_) {}
  }

  Future<void> _resetG() async {
    try {
      await _ch.invokeMethod('resetApiKey');
      await _load();
      _snack(tr('বিল্ট-ইন key-তে ফেরা হয়েছে', 'Back to the built-in key'));
    } catch (_) {}
  }

  Future<void> _resetTd() async {
    try {
      await _ch.invokeMethod('resetTdKey');
      await _load();
      _snack(tr('বিল্ট-ইন key-তে ফেরা হয়েছে', 'Back to the built-in key'));
    } catch (_) {}
  }

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }String _status(bool custom, bool any) {
    if (custom) return tr('আপনার নিজের key চলছে', 'Your own key is in use');
    if (any) return tr('বিল্ট-ইন key চলছে', 'The built-in key is in use');
    return tr('কোনো key নেই', 'No key set');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_gAny ? Icons.check_circle : Icons.key,
                  size: 20, color: _gAny ? AppColors.green : AppColors.amber),
              const SizedBox(width: 9),
              Expanded(
                child: Text('Google Gemini API key',
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(_status(_gCustom, _gAny),
              style: const TextStyle(fontSize: 12, color: Color(0xFF9AA4D8))),
          const SizedBox(height: 4),
          Text(
            tr('নতুন key বসালে সেটাই চলবে। aistudio.google.com/apikey থেকে key নিন।',
                'A new key you enter will be used. Get a key from aistudio.google.com/apikey.'),
            style: const TextStyle(
                fontSize: 12, height: 1.4, color: Color(0xFF8F8993)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _g,
            obscureText: _hide,
            style: const TextStyle(fontSize: 13),
            decoration: _dec('AIza...').copyWith(
              suffixIcon: IconButton(
                icon: Icon(_hide ? Icons.visibility : Icons.visibility_off,
                    size: 20),
                onPressed: () => setState(() => _hide = !_hide),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: _saveG,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.purple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(tr('Gemini key সেভ করুন', 'Save Gemini key')),
            ),
          ),
          if (_gCustom)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _resetG,
                child: Text(tr('বিল্ট-ইন key-তে ফিরুন', 'Use the built-in key'),
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9AA4D8))),
              ),
            ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.07), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(_tAny ? Icons.check_circle : Icons.show_chart,
                  size: 18, color: _tAny ? AppColors.green : AppColors.amber),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Twelve Data API key',
                    style:
                        TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(_status(_tCustom, _tAny),
              style: const TextStyle(fontSize: 12, color: Color(0xFF9AA4D8))),
          const SizedBox(height: 4),
          Text(
            tr(
                'ফরেক্স ও স্টকের আসল ডাটার জন্য। twelvedata.com থেকে key নিন। ক্রিপ্টোতে লাগে না।',
                'For real forex and stock data. Get a key from twelvedata.com. Not needed for crypto.'),
            style: const TextStyle(
                fontSize: 12, height: 1.4, color: Color(0xFF8F8993)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _td,
            obscureText: true,
            style: const TextStyle(fontSize: 13),
            decoration: _dec('Twelve Data key'),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: _saveTd,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.lilac,
                side: BorderSide(color: AppColors.purple.withOpacity(0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(tr('Twelve Data key সেভ করুন', 'Save Twelve Data key')),
            ),
          ),
          if (_tCustom)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _resetTd,
                child: Text(tr('বিল্ট-ইন key-তে ফিরুন', 'Use the built-in key'),
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9AA4D8))),
              ),
            ),
        ],
      ),
    );
  }
}

/// ওয়েব সার্চ, আসল ক্যান্ডেল ডাটা ও OTC মোডের সুইচ।
class AnalysisOptionsCard extends StatefulWidget {
  const AnalysisOptionsCard({super.key});

  @override
  State<AnalysisOptionsCard> createState() => _AnalysisOptionsCardState();
}

class _AnalysisOptionsCardState extends State<AnalysisOptionsCard>
    with LangAware<AnalysisOptionsCard> {
  static const _ch = MethodChannel('gasi/native');
  bool _web = true;
  bool _data = true;
  bool _otc = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final w = await _ch.invokeMethod<bool>('getWeb');
      final d = await _ch.invokeMethod<bool>('getData');
      final o = await _ch.invokeMethod<bool>('getOtc');
      if (mounted) {
        setState(() {
          if (w != null) _web = w;
          if (d != null) _data = d;
          if (o != null) _otc = o;
        });
      }
    } catch (_) {}
  }

  Future<void> _set(String method, String key, bool v) async {
    try {
      await _ch.invokeMethod(method, {key: v});
    } catch (_) {}
  }

  Widget _row(String title, String sub, bool value, ValueChanged<bool> on) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(sub,
                  style: const TextStyle(
                      fontSize: 12, height: 1.35, color: Color(0xFF8F8993))),
            ],
          ),
        ),
        Switch(value: value, onChanged: on, activeColor: AppColors.purple),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
      decoration: cardDeco(),
      child: Column(
        children: [
          _row(
            tr('ওয়েব সার্চ', 'Web search'),
            _web
                ? tr('চালু: বাজারের খবর দেখে বিশ্লেষণ, প্রথমবার একটু ধীরে',
                    'On: uses market news, a bit slower the first time')
                : tr('বন্ধ: দ্রুত উত্তর, শুধু চার্ট ও বইয়ের জ্ঞান',
                    'Off: faster, chart and book knowledge only'),
            _web,
            (v) {
              setState(() => _web = v);
              _set('saveWeb', 'web', v);
            },
          ),
          const Divider(height: 18),
          _row(
            tr('আসল ক্যান্ডেল ডাটা', 'Real candle data'),
            _data
                ? tr('চালু: ক্রিপ্টো/ফরেক্স/স্টকে সংখ্যা দিয়ে নিখুঁত হিসাব',
                    'On: exact numbers for crypto, forex and stocks')
                : tr('বন্ধ: সবসময় স্ক্রিনশট দেখে বিশ্লেষণ',
                    'Off: always analyze from the screenshot'),
            _data,
            (v) {
              setState(() => _data = v);
              _set('saveData', 'data', v);
            },
          ),
          const Divider(height: 18),
          _row(
            tr('OTC মোড (সবচেয়ে দ্রুত)', 'OTC mode (fastest)'),
            _otc
                ? tr('চালু: ওয়েব ও আসল ডাটা বাদ, একবারেই স্ক্রিনশট থেকে উত্তর',
                    'On: skips web and real data, one call from the screenshot')
                : tr('বন্ধ: অ্যাপ নিজে OTC চিনে ওয়েব সার্চ বাদ দেয়',
                    'Off: the app detects OTC and skips web search itself'),
            _otc,
            (v) {
              setState(() => _otc = v);
              _set('saveOtc', 'otc', v);
            },
          ),
        ],
      ),
    );
  }
}/// ব্যাটারি সীমা বন্ধ করার কার্ড।
class BatteryCard extends StatefulWidget {
  const BatteryCard({super.key});

  @override
  State<BatteryCard> createState() => _BatteryCardState();
}

class _BatteryCardState extends State<BatteryCard>
    with WidgetsBindingObserver, LangAware<BatteryCard> {
  static const _ch = MethodChannel('gasi/native');
  bool _ok = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final b = await _ch.invokeMethod<bool>('isBatteryUnrestricted');
      if (mounted) setState(() => _ok = b == true);
    } catch (_) {}
  }

  Future<void> _open() async {
    try {
      await _ch.invokeMethod('openBatterySettings');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_ok ? Icons.battery_charging_full : Icons.battery_alert,
                  size: 20, color: _ok ? AppColors.green : AppColors.amber),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _ok
                      ? tr('ব্যাকগ্রাউন্ডে চলতে পারবে', 'Can run in the background')
                      : tr('ব্যাটারি সীমা বন্ধ করুন', 'Turn off battery limit'),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          if (!_ok) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: _open,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.lilac,
                  side: BorderSide(color: AppColors.purple.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(tr('ব্যাটারি সেটিংস খুলুন', 'Open battery settings')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// AI-র সফলতার হার: ✅/❌ হিসাব থেকে।
class StatsCard extends StatefulWidget {
  const StatsCard({super.key});

  @override
  State<StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<StatsCard>
    with WidgetsBindingObserver, LangAware<StatsCard> {
  static const _ch = MethodChannel('gasi/native');
  static const List<String> _labels = ['1m', '5m', '15m', '30m', '1h', '2h', '5h'];
  List<int> _s = List<int>.filled(16, 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final r = await _ch.invokeMethod<List<dynamic>>('getStats');
      if (r != null && r.length >= 16 && mounted) {
        setState(() => _s = r.map((e) => (e as num).toInt()).toList());
      }
    } catch (_) {}
  }

  Future<void> _reset() async {
    try {
      await _ch.invokeMethod('resetStats');
    } catch (_) {}
    _load();
  }

  String _rate(int h, int t) => t == 0 ? '—' : '${(h * 100 / t).round()}%';

  Widget _mini(String label, int h, int t, double w) {
    return Container(
      width: w,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF8F8993))),
          const SizedBox(height: 4),
          Text(_rate(h, t),
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          Text('$h/$t',
              style: const TextStyle(fontSize: 11, color: Color(0xFF8F8993))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _s[0];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.query_stats, size: 20, color: AppColors.lilac),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  tr('AI-র সফলতার হার (আপনার হিসাব)',
                      'AI success rate (your record)'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _rate(_s[1], _s[0]),
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
          ),
          Text(
            total == 0
                ? tr('এখনও কোনো হিসাব নেই', 'No record yet')
                : tr('${_s[1]} টা মিলেছে, মোট $total টা',
                    '${_s[1]} matched out of $total'),
            style: const TextStyle(fontSize: 12, color: Color(0xFF8F8993)),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, box) {
              final w = (box.maxWidth - 16) / 3;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < _labels.length; i++)
                    _mini(_labels[i], _s[3 + i * 2], _s[2 + i * 2], w),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            tr('ইতিহাস পেজে ✅/❌ চেপে হিসাব যোগ করুন। ২০-৩০টার কম ট্রেডে এই হার ভরসাযোগ্য নয়।',
                'Add records with ✅/❌ on the History page. With fewer than 20-30 trades this rate is not reliable.'),
            style: const TextStyle(
                fontSize: 11, height: 1.4, color: Color(0xFF8F8993)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _reset,
              child: Text(tr('হিসাব মুছুন', 'Reset record'),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8F8993))),
            ),
          ),
        ],
      ),
    );
  }
}/// ব্যবহার নির্দেশিকার লেখা (প্রথমবার ও সেটিংসে একই)।
class ManualContent extends StatelessWidget {
  const ManualContent({super.key});

  Widget _step(int n, String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: cardDeco(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF9B6BFF), Color(0xFF6A3DF5)],
              ),
            ),
            child: Text('$n',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFFC8C3CD))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _step(
          1,
          tr('পারমিশন দিন', 'Give permission'),
          tr('"Display over other apps" চালু করুন, তাহলে ট্রেডিং অ্যাপের ওপর ভাসমান G বাটন দেখা যাবে।',
              'Turn on "Display over other apps" so the floating G button can appear on top of your trading app.'),
        ),
        _step(
          2,
          tr('সময় বাছুন', 'Pick the forecast time'),
          tr('হোম পেজে ১ মিনিট থেকে ৫ ঘণ্টার মধ্যে কত সময়ের পূর্বাভাস চান বাছুন। ১৫ মিনিট বা তার বেশি সময়ে AI-র বিশ্লেষণ তুলনামূলক বেশি অর্থবহ।',
              'On the Home page choose a forecast from 1 minute to 5 hours. A forecast of 15 minutes or more is comparatively more meaningful.'),
        ),
        _step(
          3,
          tr('Tap to Start চাপুন', 'Tap to Start'),
          tr('পৃথিবীর মাঝের বাটন (বা নিচের ক্যামেরা বাটন) চাপুন। স্ক্রিন ক্যাপচারের অনুমতি চাইলে "Start now" দিন। তখন পৃথিবী দ্রুত ঘুরবে।',
              'Tap the button in the middle of the globe (or the camera button below). If Android asks for screen capture, allow it. The globe will spin fast.'),
        ),
        _step(
          4,
          tr('চার্টে G চাপুন', 'Tap G on your chart'),
          tr('আপনার ট্রেডিং অ্যাপের চার্টে যান, চার্টের নাম আর পেআউট দেখা যাক। ভাসমান G চাপুন, কয়েক সেকেন্ডে ফলাফল কার্ড ভেসে উঠবে।',
              'Open the chart in your trading app so the asset name and payout are visible. Tap the floating G and a result card appears within seconds.'),
        ),
        _step(
          5,
          tr('কার্ড কীভাবে পড়বেন', 'How to read the card'),
          tr('গেজে UP/DOWN শতাংশ দেখা যায়। ব্রেক-ইভেন লাইন বলে পেআউটে লাভ করতে অন্তত কত শতাংশ মিলতে হবে। 🌐 মানে ওয়েব দেখা হয়েছে, 📊 মানে আসল ক্যান্ডেল ডাটা, 📖 মানে শুধু চার্ট। হলুদ বা লাল সতর্কতা এলে সাবধান হন।',
              'The gauge shows UP/DOWN percentages. The break-even line tells you how often the AI must be right to profit at your payout. 🌐 means web info was used, 📊 real candle data, 📖 chart only. Be careful when a yellow or red warning appears.'),
        ),
        _step(
          6,
          tr('ফল মিলিয়ে নিন', 'Mark the result'),
          tr('ট্রেড শেষ হলে ইতিহাসে (বা কার্ডের নিচে) ✅ বা ❌ চাপুন। ভুল হলে পরে বদলানো যায়। সেটিংস → সফলতার হারে মোট সফল ও ব্যর্থ দেখা যায়।',
              'When a trade ends, tap ✅ or ❌ in History (or under the card). You can change it later. Settings → Success rate shows your total successes and failures.'),
        ),
        _step(
          7,
          tr('সেটিংসের টিপস', 'Settings tips'),
          tr('বিশ্লেষণের ধরনে ওয়েব সার্চ, আসল ক্যান্ডেল ডাটা আর OTC মোড বদলানো যায়। OTC জোড়ায় OTC মোড চালু রাখলে উত্তর সবচেয়ে দ্রুত আসে। কালার ও আইকনে ভাসমান বাটন সাজান, আর API key সেখানেই বদলান।',
              'In Analysis mode you can switch web search, real candle data and OTC mode. For OTC pairs keep OTC mode on for the fastest answer. Color and icon styles the floating button, and API keys can be changed in Settings.'),
        ),
        _step(
          8,
          tr('সতর্কতা', 'Be careful'),
          tr('এটি অনুমান, নিশ্চিত ভবিষ্যদ্বাণী বা ট্রেডিং পরামর্শ নয়। ঝুঁকি আপনার নিজের, আর ক্ষতির দায় অ্যাপ বা এর নির্মাতার নয়।',
              'This is an estimate, not a guaranteed prediction or trading advice. The risk is yours, and the app and its developer take no responsibility for losses.'),
        ),
      ],
    );
  }
}

/// সেটিংস বা অ্যাকাউন্ট থেকে খোলা ব্যবহার নির্দেশিকার পেজ।
class ManualPage extends StatefulWidget {
  const ManualPage({super.key});

  @override
  State<ManualPage> createState() => _ManualPageState();
}

class _ManualPageState extends State<ManualPage> with LangAware<ManualPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GasiBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 4),
                  Text(tr('ব্যবহার নির্দেশিকা', 'User Manual'),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 12),
              const ManualContent(),
            ],
          ),
        ),
      ),
    );
  }
}

/// ইনস্টলের পর প্রথমবার একবার দেখানো ব্যবহার নির্দেশিকা।
class ManualScreen extends StatefulWidget {
  final VoidCallback onDone;
  const ManualScreen({super.key, required this.onDone});

  @override
  State<ManualScreen> createState() => _ManualScreenState();
}

class _ManualScreenState extends State<ManualScreen>
    with LangAware<ManualScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GasiBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(tr('কীভাবে কাজ করে', 'How it works'),
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w900)),
                    ),
                    const LanguageSwitch(),
                  ],
                ),
              ),
              const Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(18, 8, 18, 8),
                  child: ManualContent(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: widget.onDone,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(tr('বুঝেছি, শুরু করি', 'Got it, let us start'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
/// সাজসজ্জা: ফ্লোটিং বাটনের রং/আইকন/সাইজ, রেজাল্ট কার্ডের জায়গা, অ্যাপের ব্যাকগ্রাউন্ড।
class AppearanceCard extends StatefulWidget {
  final void Function(String id) onBg;
  const AppearanceCard({super.key, required this.onBg});

  @override
  State<AppearanceCard> createState() => _AppearanceCardState();
}class _AppearanceCardState extends State<AppearanceCard>
    with LangAware<AppearanceCard> {
  static const _ch = MethodChannel('gasi/native');
  static const _colors = [
    '#8B5CF6', '#38D996', '#FF6685', '#FFB45C',
    '#3B82F6', '#EC4899', '#14B8A6', '#F8FAFC',
  ];
  static const _icons = ['G', '📈', '✦', 'AI'];

  String _color = '#8B5CF6';
  String _icon = 'G';
  int _size = 58;
  int _alpha = 100;
  String _pos = 'top';
  int _cardAlpha = 96;
  String _bg = 'aurora';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Color _c(String hex) =>
      Color(int.parse('FF${hex.substring(1)}', radix: 16));

  Future<void> _load() async {
    try {
      final u = await _ch.invokeMethod<Map<dynamic, dynamic>>('getUi');
      if (u == null || !mounted) return;
      setState(() {
        _color = (u['btn_color'] as String?) ?? _color;
        _icon = (u['btn_icon'] as String?) ?? _icon;
        _size = (u['btn_size'] as num?)?.toInt() ?? _size;
        _alpha = (u['btn_alpha'] as num?)?.toInt() ?? _alpha;
        _pos = (u['card_pos'] as String?) ?? _pos;
        _cardAlpha = (u['card_alpha'] as num?)?.toInt() ?? _cardAlpha;
        _bg = (u['bg'] as String?) ?? _bg;
      });
    } catch (_) {}
  }

  Future<void> _save(Map<String, Object> m) async {
    try {
      await _ch.invokeMethod('setUi', {'ui': m});
    } catch (_) {}
  }

  Future<void> _reset() async {
    try {
      await _ch.invokeMethod('resetUi');
    } catch (_) {}
    await _load();
    widget.onBg(_bg);
  }

  Widget _chip(String label, bool sel, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? AppColors.purple : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: sel ? AppColors.lilac : Colors.white.withOpacity(0.08)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: sel ? Colors.white : const Color(0xFFB9B3BF))),
      ),
    );
  }

  Widget _animChip(String value, Widget child) {
    final sel = _icon == value;
    return GestureDetector(
      onTap: () {
        setState(() => _icon = value);
        _save({'btn_icon': value});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: sel
              ? AppColors.purple.withOpacity(0.35)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sel ? AppColors.lilac : Colors.white.withOpacity(0.08),
            width: sel ? 2 : 1,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(t,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB9B3BF))),
      );

  @override
  Widget build(BuildContext context) {
    final base = _c(_color);
    final previewSize = _size.toDouble();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette_outlined, size: 20, color: AppColors.lilac),
              const SizedBox(width: 9),
              Expanded(
                child: Text(tr('ফ্লোটিং বাটন ও থিম', 'Floating button and theme'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Opacity(
              opacity: _alpha / 100,
              child: Container(
                width: previewSize,
                height: previewSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(base, Colors.white, 0.18)!,
                      Color.lerp(base, Colors.black, 0.32)!,
                    ],
                  ),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.45), width: 2),
                ),
                child: Text(_icon,
                    style: TextStyle(
                        fontSize: _icon == 'AI' ? 16 : 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ),
            ),
          ),
          _title(tr('বাটনের রং', 'Button color')),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final h in _colors)
                GestureDetector(
                  onTap: () {
                    setState(() => _color = h);
                    _save({'btn_color': h});
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _c(h),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == h
                            ? Colors.white
                            : Colors.white.withOpacity(0.15),
                        width: _color == h ? 3 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          _title(tr('বাটনের আইকন', 'Button icon')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final i in _icons)
                _chip(i, _icon == i, () {
                  setState(() => _icon = i);
                  _save({'btn_icon': i});
                }),
              _animChip('🐵', const MonkeyIcon(size: 52)),
              _animChip('🦅', const HunterBirdIcon(size: 52)),
            ],
          ),
          _title('${tr('বাটনের সাইজ', 'Button size')}: $_size'),
          Slider(
            value: _size.toDouble(),
            min: 44,
            max: 80,
            divisions: 18,
            activeColor: AppColors.purple,
            onChanged: (v) => setState(() => _size = v.round()),
            onChangeEnd: (v) => _save({'btn_size': v.round()}),
          ),
          _title('${tr('বাটনের স্বচ্ছতা', 'Button opacity')}: $_alpha%'),
          Slider(
            value: _alpha.toDouble(),
            min: 40,
            max: 100,
            divisions: 12,
            activeColor: AppColors.purple,
            onChanged: (v) => setState(() => _alpha = v.round()),
            onChangeEnd: (v) => _save({'btn_alpha': v.round()}),
          ),
          _title(tr('রেজাল্ট কার্ড কোথায় আসবে', 'Where the result card appears')),
          Row(
            children: [
              _chip(tr('উপরে', 'Top'), _pos == 'top', () {
                setState(() => _pos = 'top');
                _save({'card_pos': 'top'});
              }),
              const SizedBox(width: 8),
              _chip(tr('নিচে', 'Bottom'), _pos == 'bottom', () {
                setState(() => _pos = 'bottom');
                _save({'card_pos': 'bottom'});
              }),
            ],
          ),
          _title('${tr('কার্ডের স্বচ্ছতা', 'Card opacity')}: $_cardAlpha%'),
          Slider(
            value: _cardAlpha.toDouble(),
            min: 70,
            max: 100,
            divisions: 6,
            activeColor: AppColors.purple,
            onChanged: (v) => setState(() => _cardAlpha = v.round()),
            onChangeEnd: (v) => _save({'card_alpha': v.round()}),
          ),
          _title(tr('অ্যাপের ব্যাকগ্রাউন্ড', 'App background')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in kBackgrounds.keys)
                _chip(bgName(id), _bg == id, () {
                  setState(() => _bg = id);
                  _save({'bg': id});
                  widget.onBg(id);
                }),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _reset,
              child: Text(tr('ডিফল্টে ফেরান', 'Reset to default'),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8F8993))),
            ),
          ),
        ],
      ),
    );
  }
}
// ============================================================
// পার্ট ১: "WELCOME, TO AI ANALYSIS" টাইপরাইটার ওয়েলকাম স্ক্রিন
//
// কীভাবে বসাবেন:
//  ধাপ ১) এই ফাইলের সবটুকু home_screen.dart-এর একদম শেষে বসান।
//  ধাপ ২) home_screen.dart-এ এই লাইনটা খুঁজুন (Gate ক্লাসের ভেতরে):
//           page = const SplashScreen(key: ValueKey('splash'));
//         এবং বদলে লিখুন:
//           page = const WelcomeScreen(key: ValueKey('splash'));
//  নতুন কোনো প্যাকেজ বা workflow বদল লাগবে না।
//
// সময়রেখা:
//   0.0–0.8s  প্রায় কালো স্ক্রিন থেকে ধীরে 3D টাইল দেখা যায়
//   0.8s থেকে প্রতি 100ms-এ একটা করে অক্ষর (স্পেসেও 100ms, কিন্তু স্পেসে সাউন্ড নেই)
//   টাইপ শেষে 500ms অপেক্ষা, তারপর কার্সর মিলিয়ে যায় এবং 800ms নিয়ন গ্লো পালস
//   তারপর লেখা স্থির থাকে (Gate নিজের সময়ে পরের স্ক্রিনে নিয়ে যায়)
// ============================================================

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  static const String _text = 'WELCOME, TO AI ANALYSIS';
  static const Color _pink = Color(0xFFFF3DCB);
  static const Color _violet = Color(0xFF8B5CF6);

  late final AnimationController _wave; // পেছনের টাইলের ধীর ঢেউ
  late final AnimationController _reveal; // শুরুর 0.8s ফেড-ইন
  late final AnimationController _type; // 100ms x অক্ষর সংখ্যা
  late final AnimationController _blink; // কার্সর ব্লিঙ্ক (500ms জ্বলে, 500ms নেভে)
  late final AnimationController _cursorFade; // টাইপ শেষে কার্সর মিলিয়ে যাওয়া
  late final AnimationController _glow; // 800ms গ্লো পালস

  int _shown = 0;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _type = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100 * _text.length),
    );
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _cursorFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _type.addListener(_onType);
    _run();
  }

  /// একটার পর একটা ধাপ চালায়।
  Future<void> _run() async {
    await _reveal.forward();
    if (!mounted) return;
    await _type.forward();
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _cursorFade.forward();
    await _glow.forward();
  }

  /// প্রতি 100ms-এ নতুন অক্ষর দেখায়; স্পেস ছাড়া প্রতি অক্ষরে একটা ছোট ট্যাপ সাউন্ড।
  void _onType() {
    int n = (_type.value * _text.length).floor() + 1;
    if (n > _text.length) n = _text.length;
    if (n <= _shown) return;
    _shown = n;
    if (_text[n - 1] != ' ') {
      // ডিভাইসের টাচ-সাউন্ড সেটিং মেনে চলে। নীরব থাকলে কিছুই বাজে না।
      const MethodChannel('gasi/keysound')
    .invokeMethod<void>('tap')
    .catchError((Object _) {
  SystemSound.play(SystemSoundType.click);
});
    }
  }

  @override
  void dispose() {
    _type.removeListener(_onType);
    _wave.dispose();
    _reveal.dispose();
    _type.dispose();
    _blink.dispose();
    _cursorFade.dispose();
    _glow.dispose();
    super.dispose();
  }

  Widget _buildText() {
    return AnimatedBuilder(
      animation: Listenable.merge([_type, _blink, _cursorFade, _glow]),
      builder: (context, _) {
        final pulse = _gSin(kPi * _glow.value); // 0 -> 1 -> 0
        final blinkOn = _blink.value < 0.5;
        final cursorAlpha = blinkOn ? (1.0 - _cursorFade.value) : 0.0;

        const base = TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.2,
          height: 1.35,
        );
        final shown = base.copyWith(
          color: Colors.white,
          shadows: [
            Shadow(
              color: _pink.withOpacity(0.35 + 0.55 * pulse),
              blurRadius: 14 + 22 * pulse,
            ),
            Shadow(
              color: _violet.withOpacity(0.45 + 0.4 * pulse),
              blurRadius: 26 + 24 * pulse,
            ),
          ],
        );
        // যে অক্ষর এখনো আসেনি সেগুলো স্বচ্ছ, তাই লেখা বাড়লে লেআউট নড়ে না।
        final hidden = base.copyWith(color: Colors.transparent);
        final cursor = base.copyWith(
          color: _pink.withOpacity(cursorAlpha),
          fontWeight: FontWeight.w300,
        );

        return RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(text: _text.substring(0, _shown), style: shown),
              TextSpan(text: '|', style: cursor),
              TextSpan(text: _text.substring(_shown), style: hidden),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GasiBackground(
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _wave,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: TileWavePainter(_wave.value * 120.0),
                    );
                  },
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.85,
                    colors: [
                      const Color(0xFF0B0A0E).withOpacity(0.55),
                      const Color(0xFF0B0A0E).withOpacity(0.86),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _violet.withOpacity(0.45),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(child: gxLogo(96)),
                    ),
                    const SizedBox(height: 30),
                    _buildText(),
                  ],
                ),
              ),
            ),
            // শুরুতে প্রায় কালো স্ক্রিন, 0.8s-এ ধীরে ধীরে সরে যায়।
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _reveal,
                  builder: (context, _) {
                    final a = 1.0 - Curves.easeOut.transform(_reveal.value);
                    return ColoredBox(color: Colors.black.withOpacity(a));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
