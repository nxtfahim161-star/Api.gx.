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

enum GateStep { loading, agreement, key, home }

class Gate extends StatefulWidget {
  const Gate({super.key});

  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  static const _ch = MethodChannel('gasi/native');
  GateStep _step = GateStep.loading;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    bool agreed = false;
    bool setup = false;
    try {
      final r = await Future.wait<dynamic>([
        _ch.invokeMethod<Map<dynamic, dynamic>>('getFlags'),
        _ch.invokeMethod<Map<dynamic, dynamic>>('getUi'),
        Future<void>.delayed(const Duration(milliseconds: 2600)),
      ]);
      final f = r[0] as Map<dynamic, dynamic>?;
      agreed = f?['agreed'] == true;
      setup = f?['setup_done'] == true;
      final u = r[1] as Map<dynamic, dynamic>?;
      final b = u?['bg'];
      if (b is String) bgNotifier.value = b;
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 1500));
    }
    if (!mounted) return;
    setState(() {
      if (!agreed) {
        _step = GateStep.agreement;
      } else if (!setup) {
        _step = GateStep.key;
      } else {
        _step = GateStep.home;
      }
    });
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
        page = const SplashScreen(key: ValueKey('splash'));
        break;
      case GateStep.agreement:
        page = AgreementScreen(
          key: const ValueKey('agreement'),
          onAgree: () async {
            await _flag('agreed');
            if (mounted) setState(() => _step = GateStep.key);
          },
        );
        break;
      case GateStep.key:
        page = KeyScreen(
          key: const ValueKey('key'),
          onDone: () async {
            await _flag('setup_done');
            if (mounted) setState(() => _step = GateStep.home);
          },
        );
        break;
      case GateStep.home:
        page = const HomeScreen(key: ValueKey('home'));
        break;
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: page,
    );
  }
}

/// শুরুর লোডিং: ব্যাকগ্রাউন্ডে GX লোগো, মাঝে স্থির গোল রিং, ভেতরে নরম পালস।
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _logo(double size) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GasiBackground(
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.07,
                child: Center(
                  child: Image.asset(
                    'assets/logo.png',
                    width: 460,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) => const SizedBox(),
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
                            ClipOval(child: _logo(112)),
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
                    style: TextStyle(fontSize: 13, color: Color(0xFF8F8993)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AgreementScreen extends StatefulWidget {
  final VoidCallback onAgree;
  const AgreementScreen({super.key, required this.onAgree});

  @override
  State<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen> {
  bool _ok = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GasiBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('User Agreement',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text('Please read this before you continue',
                    style: TextStyle(fontSize: 13, color: Color(0xFF8F8993))),
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
                const SizedBox(height: 12),
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
                const SizedBox(height: 8),
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
}

/// প্রথমবার ইনস্টলের পর একবারই আসে। পরে বদলাতে হলে সেটিংস থেকে।
class KeyScreen extends StatefulWidget {
  final VoidCallback onDone;
  const KeyScreen({super.key, required this.onDone});

  @override
  State<KeyScreen> createState() => _KeyScreenState();
}

class _KeyScreenState extends State<KeyScreen> {
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
                    const Text('আপনার Gemini API key দিন',
                        style: TextStyle(
                            fontSize: 21, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    const Text(
                      'aistudio.google.com/apikey থেকে বিনামূল্যে key নিন। key শুধু এই ফোনে থাকবে। এটা শুধু এই প্রথমবারই জিজ্ঞেস করা হবে, পরে বদলাতে হলে সেটিংস থেকে বদলাবেন।',
                      style: TextStyle(
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
                        child: const Text('সেভ করে শুরু করুন',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: TextButton(
                        onPressed: _busy ? null : widget.onDone,
                        child: const Text('এখন না, পরে সেটিংস থেকে দেব',
                            style: TextStyle(
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
/// প্রথম পেজ: শুধু চার্ট অ্যানালাইসিস চালু/বন্ধ আর কত সময়ের পূর্বাভাস।
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _ch = MethodChannel('gasi/native');

  bool _granted = false;
  bool _starting = false;

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
      if (mounted) setState(() => _granted = g == true);
    } catch (_) {}
  }

  Future<void> _openOverlaySettings() async {
    try {
      await _ch.invokeMethod('openOverlaySettings');
    } catch (_) {}
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      await _ch.invokeMethod('startOverlay');
      _snack('Floating G চালু হয়েছে। chart-এ গিয়ে G চাপুন।');
    } on PlatformException catch (e) {
      _snack(e.message ?? 'শুরু করা যায়নি');
    } catch (_) {
      _snack('শুরু করা যায়নি');
    }
    if (mounted) setState(() => _starting = false);
  }

  Future<void> _stop() async {
    try {
      await _ch.invokeMethod('stopOverlay');
      _snack('Floating G বন্ধ হয়েছে');
    } catch (_) {}
  }

  void _openSettingsPage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GasiBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'সেটিংস',
                  onPressed: _openSettingsPage,
                  icon: const Icon(Icons.settings_outlined, size: 26),
                ),
              ),
              const HeaderBar(),
              const SizedBox(height: 18),
              if (!_granted) ...[
                PermissionCard(
                  granted: _granted,
                  onOpenSettings: _openOverlaySettings,
                ),
                gap,
              ],
              const TimeframePicker(),
              gap,
              CaptureCard(
                granted: _granted,
                starting: _starting,
                onStart: _start,
                onStop: _stop,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// কত সময়ের পূর্বাভাস চাই: ১ মিনিট থেকে ৫ ঘণ্টা।
class TimeframePicker extends StatefulWidget {
  const TimeframePicker({super.key});

  @override
  State<TimeframePicker> createState() => _TimeframePickerState();
}

class _TimeframePickerState extends State<TimeframePicker> {
  static const _ch = MethodChannel('gasi/native');
  static const Map<int, String> _opts = {
    1: '১ মিনিট',
    5: '৫ মিনিট',
    15: '১৫ মিনিট',
    30: '৩০ মিনিট',
    60: '১ ঘণ্টা',
    120: '২ ঘণ্টা',
    300: '৫ ঘণ্টা',
  };
  int _sel = 5;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final m = await _ch.invokeMethod<int>('getMinutes');
      if (mounted && m != null) setState(() => _sel = m);
    } catch (_) {}
  }Future<void> _pick(int m) async {
    setState(() => _sel = m);
    try {
      await _ch.invokeMethod('saveMinutes', {'minutes': m});
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
          const Row(
            children: [
              Icon(Icons.timer_outlined, size: 20, color: AppColors.lilac),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'কত সময়ের পূর্বাভাস?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'AI এই সময়ের জন্য UP/DOWN শতাংশ বলবে।',
            style: TextStyle(fontSize: 12, color: Color(0xFF8F8993)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in _opts.entries)
                GestureDetector(
                  onTap: () => _pick(e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 11),
                    decoration: BoxDecoration(
                      color: _sel == e.key
                          ? AppColors.purple
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _sel == e.key
                            ? AppColors.lilac
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _sel == e.key
                            ? Colors.white
                            : const Color(0xFFB9B3BF),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            '১৫ মিনিট বা তার বেশি সময়ের পূর্বাভাসে AI-র বিশ্লেষণ তুলনামূলক বেশি অর্থবহ, কারণ ১-৫ মিনিটে দাম বেশি এলোমেলো থাকে। বড় সময় বাছলে ১৫ মিনিট বা ১ ঘণ্টার চার্টের স্ক্রিনশট নিন।',
            style: TextStyle(
                fontSize: 12, height: 1.5, color: Color(0xFF8F8993)),
          ),
        ],
      ),
    );
  }
}

class SettingsHeading extends StatelessWidget {
  final String text;
  const SettingsHeading(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: AppColors.lilac,
        ),
      ),
    );
  }
}

/// সেটিংস পেজ: প্রথম পেজে যা নেই সব এখানে।
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _paste = TextEditingController();
  AIResult? _result;

  @override
  void dispose() {
    _paste.dispose();
    super.dispose();
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _pasteClipboard() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    final t = d?.text;
    if (t != null && mounted) setState(() => _paste.text = t);
  }

  void _showResult() {
    final r = AIResult.parse(_paste.text);
    if (r == null) {
      _snack('JSON ঠিক নেই। AI-র পুরো উত্তর paste করুন।');
      return;
    }
    setState(() => _result = r);
  }

  void _showAgreement() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('User Agreement'),
        content: const SingleChildScrollView(
          child: Text(
            kAgreementText,
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
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
                  const Text('সেটিংস',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900)),
                ],
              ),
              const SettingsHeading('API KEY'),
              const KeysCard(),
              const SettingsHeading('বিশ্লেষণের ধরন'),
              const AnalysisOptionsCard(),
              const SettingsHeading('সাজসজ্জা'),
              AppearanceCard(onBg: (id) => bgNotifier.value = id),
              const SettingsHeading('ব্যাকগ্রাউন্ডে চলা'),
              const BatteryCard(),
              const SettingsHeading('সফলতার হিসাব'),
              const StatsCard(),
              const SettingsHeading('হাতে ফলাফল দেখা'),
              PasteCard(
                controller: _paste,
                onPaste: _pasteClipboard,
                onShow: _showResult,
              ),
              if (_result != null) ...[
                gap,
                ResultPanel(result: _result!),
              ],
              const SettingsHeading('তথ্য'),
              const HowCard(),
              gap,
              const DisclaimerCard(),
              gap,
              Container(
                decoration: cardDeco(),
                child: ListTile(
                  onTap: _showAgreement,
                  leading: const Icon(Icons.description_outlined,
                      color: AppColors.lilac),
                  title: const Text('User Agreement',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            ],
          ),
        ),
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

class _KeysCardState extends State<KeysCard> {
  static const _ch = MethodChannel('gasi/native');
  final _g = TextEditingController();
  final _td = TextEditingController();
  bool _hasG = false;
  bool _hasTd = false;
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
      final a = await _ch.invokeMethod<bool>('hasApiKey');
      final b = await _ch.invokeMethod<bool>('hasTdKey');
      if (mounted) {
        setState(() {
          _hasG = a == true;
          _hasTd = b == true;
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
      _snack('Gemini key সেভ হয়েছে');
    } catch (_) {}
  }

  Future<void> _saveTd() async {
    final k = _td.text.trim();
    if (k.isEmpty) return;
    try {
      await _ch.invokeMethod('saveTdKey', {'key': k});
      _td.clear();
      await _load();
      _snack('Twelve Data key সেভ হয়েছে');
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
              Icon(_hasG ? Icons.check_circle : Icons.key,
                  size: 20,
                  color: _hasG ? AppColors.green : AppColors.amber),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _hasG ? 'Gemini API key সেভ আছে' : 'Gemini API key নেই',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'নতুন key বসালে পুরোনোটা বদলে যাবে। aistudio.google.com/apikey থেকে key নিন।',
            style: TextStyle(
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
              child: const Text('Gemini key সেভ করুন'),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.07), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(_hasTd ? Icons.check_circle : Icons.show_chart,
                  size: 18,
                  color: _hasTd ? AppColors.green : AppColors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _hasTd
                      ? 'Twelve Data key সেভ আছে'
                      : 'Twelve Data key (ঐচ্ছিক)',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'ফরেক্স ও স্টকের আসল ডাটার জন্য। twelvedata.com থেকে বিনামূল্যে key নিন। ক্রিপ্টোতে লাগে না।',
            style: TextStyle(
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
              child: const Text('Twelve Data key সেভ করুন'),
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

class _AnalysisOptionsCardState extends State<AnalysisOptionsCard> {
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
            'ওয়েব সার্চ',
            _web
                ? 'চালু: বাজারের খবর দেখে বিশ্লেষণ, প্রথমবার একটু ধীরে'
                : 'বন্ধ: দ্রুত উত্তর, শুধু চার্ট ও বইয়ের জ্ঞান',
            _web,
            (v) {
              setState(() => _web = v);
              _set('saveWeb', 'web', v);
            },
          ),
          const Divider(height: 18),
          _row(
            'আসল ক্যান্ডেল ডাটা',
            _data
                ? 'চালু: ক্রিপ্টো/ফরেক্স/স্টকে সংখ্যা দিয়ে নিখুঁত হিসাব'
                : 'বন্ধ: সবসময় স্ক্রিনশট দেখে বিশ্লেষণ',
            _data,
            (v) {
              setState(() => _data = v);
              _set('saveData', 'data', v);
            },
          ),
          const Divider(height: 18),
          _row(
            'OTC মোড (সবচেয়ে দ্রুত)',
            _otc
                ? 'চালু: ওয়েব ও আসল ডাটা বাদ, একবারেই স্ক্রিনশট থেকে উত্তর'
                : 'বন্ধ: অ্যাপ নিজে OTC চিনে ওয়েব সার্চ বাদ দেয়',
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
}
/// ব্যাটারি সীমা বন্ধ করার কার্ড।
class BatteryCard extends StatefulWidget {
  const BatteryCard({super.key});

  @override
  State<BatteryCard> createState() => _BatteryCardState();
}

class _BatteryCardState extends State<BatteryCard> with WidgetsBindingObserver {
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
                  _ok ? 'ব্যাকগ্রাউন্ডে চলতে পারবে' : 'ব্যাটারি সীমা বন্ধ করুন',
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
                child: const Text('ব্যাটারি সেটিংস খুলুন'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// AI-র সফলতার হার: কার্ডে ✅/❌ চেপে যোগ করা হিসাব থেকে।
class StatsCard extends StatefulWidget {
  const StatsCard({super.key});

  @override
  State<StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<StatsCard> with WidgetsBindingObserver {
  static const _ch = MethodChannel('gasi/native');
  static const List<String> _labels = [
    '১ মিনিট',
    '৫ মিনিট',
    '১৫ মিনিট',
    '৩০ মিনিট',
    '১ ঘণ্টা',
    '২ ঘণ্টা',
    '৫ ঘণ্টা',
  ];
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
          const Row(
            children: [
              Icon(Icons.query_stats, size: 20, color: AppColors.lilac),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'AI-র সফলতার হার (আপনার হিসাব)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
                ? 'এখনও কোনো হিসাব নেই'
                : '${_s[1]} টা মিলেছে, মোট $total টা',
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
          const Text(
            'রেজাল্ট কার্ডে ✅/❌ চেপে হিসাব যোগ করুন। ২০-৩০টার কম ট্রেডে এই হার ভরসাযোগ্য নয়।',
            style:
                TextStyle(fontSize: 11, height: 1.4, color: Color(0xFF8F8993)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _reset,
              child: const Text('হিসাব মুছুন',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8F8993))),
            ),
          ),
        ],
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
}

class _AppearanceCardState extends State<AppearanceCard> {
  static const _ch = MethodChannel('gasi/native');
  static const _colors = [
    '#8B5CF6', '#38D996', '#FF6685', '#FFB45C',
    '#3B82F6', '#EC4899', '#14B8A6', '#F8FAFC',
  ];
  static const _icons = ['G', '⚡', '📈', '◎', '✦', 'AI'];

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
      decoration: BoxDecoration(
        color: const Color(0xFF111015).withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.palette_outlined, size: 20, color: AppColors.lilac),
              SizedBox(width: 9),
              Expanded(
                child: Text('সাজসজ্জা',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
                        fontSize: _icon.length > 1 && _icon == 'AI' ? 16 : 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ),
            ),
          ),
          _title('বাটনের রং'),
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
          _title('বাটনের আইকন'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final i in _icons)
                _chip(i, _icon == i, () {
                  setState(() => _icon = i);
                  _save({'btn_icon': i});
                }),
            ],
          ),
          _title('বাটনের সাইজ: $_size'),
          Slider(
            value: _size.toDouble(),
            min: 44,
            max: 80,
            divisions: 18,
            activeColor: AppColors.purple,
            onChanged: (v) => setState(() => _size = v.round()),
            onChangeEnd: (v) => _save({'btn_size': v.round()}),
          ),
          _title('বাটনের স্বচ্ছতা: $_alpha%'),
          Slider(
            value: _alpha.toDouble(),
            min: 40,
            max: 100,
            divisions: 12,
            activeColor: AppColors.purple,
            onChanged: (v) => setState(() => _alpha = v.round()),
            onChangeEnd: (v) => _save({'btn_alpha': v.round()}),
          ),
          _title('রেজাল্ট কার্ড কোথায় আসবে'),
          Row(
            children: [
              _chip('উপরে', _pos == 'top', () {
                setState(() => _pos = 'top');
                _save({'card_pos': 'top'});
              }),
              const SizedBox(width: 8),
              _chip('নিচে', _pos == 'bottom', () {
                setState(() => _pos = 'bottom');
                _save({'card_pos': 'bottom'});
              }),
            ],
          ),
          _title('কার্ডের স্বচ্ছতা: $_cardAlpha%'),
          Slider(
            value: _cardAlpha.toDouble(),
            min: 70,
            max: 100,
            divisions: 6,
            activeColor: AppColors.purple,
            onChanged: (v) => setState(() => _cardAlpha = v.round()),
            onChangeEnd: (v) => _save({'card_alpha': v.round()}),
          ),
          _title('অ্যাপের ব্যাকগ্রাউন্ড'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in kBackgroundNames.entries)
                _chip(e.value, _bg == e.key, () {
                  setState(() => _bg = e.key);
                  _save({'bg': e.key});
                  widget.onBg(e.key);
                }),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _reset,
              child: const Text('ডিফল্টে ফেরান',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8F8993))),
            ),
          ),
        ],
      ),
    );
  }
}
