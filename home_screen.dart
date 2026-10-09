import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

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
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _ch = MethodChannel('gasi/native');

  final _paste = TextEditingController();
  bool _granted = false;
  bool _starting = false;
  AIResult? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _paste.dispose();
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

  Future<void> _openSettings() async {
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

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
          children: [
            const HeaderBar(),
            const SizedBox(height: 20),
            PermissionCard(granted: _granted, onOpenSettings: _openSettings),
            gap,
            const SetupCard(),
            gap,
            const TimeframeCard(),
            gap,
            CaptureCard(
              granted: _granted,
              starting: _starting,
              onStart: _start,
              onStop: _stop,
            ),
            if (_result != null) ...[
              gap,
              ResultPanel(result: _result!),
            ],
            gap,
            PasteCard(
              controller: _paste,
              onPaste: _pasteClipboard,
              onShow: _showResult,
            ),
            gap,
            const HowCard(),
            gap,
            const DisclaimerCard(),
          ],
        ),
      ),
    );
  }
}

/// Gemini API key সেভ করা + ব্যাটারি সেটিংস খোলার কার্ড।
class SetupCard extends StatefulWidget {
  const SetupCard({super.key});

  @override
  State<SetupCard> createState() => _SetupCardState();
}

class _SetupCardState extends State<SetupCard> with WidgetsBindingObserver {
  static const _ch = MethodChannel('gasi/native');

  final _c = TextEditingController();
  bool _hasKey = false;
  bool _battery = false;
  bool _hide = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final k = await _ch.invokeMethod<bool>('hasApiKey');
      final b = await _ch.invokeMethod<bool>('isBatteryUnrestricted');
      if (mounted) {
        setState(() {
          _hasKey = k == true;
          _battery = b == true;
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final k = _c.text.trim();
    if (k.isEmpty) return;
    try {
      await _ch.invokeMethod('saveApiKey', {'key': k});
      _c.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API key সেভ হয়েছে')),
        );
      }
    } catch (_) {}
  }

  Future<void> _openBattery() async {
    try {
      await _ch.invokeMethod('openBatterySettings');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final keyColor = _hasKey ? AppColors.green : AppColors.amber;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111015),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_hasKey ? Icons.check_circle : Icons.key,
                  size: 20, color: keyColor),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _hasKey ? 'Gemini API key সেভ আছে' : 'Gemini API key দিন',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'aistudio.google.com/apikey থেকে key নিন। key শুধু এই ফোনে থাকবে। নতুন key বসালে পুরোনোটা বদলে যাবে।',
            style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF8F8993)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _c,
            obscureText: _hide,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'AIza...',
              filled: true,
              fillColor: Colors.white.withOpacity(0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(_hide ? Icons.visibility : Icons.visibility_off,
                    size: 20),
                onPressed: () => setState(() => _hide = !_hide),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.purple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Key সেভ করুন'),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.07), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(_battery ? Icons.battery_charging_full : Icons.battery_alert,
                  size: 20, color: _battery ? AppColors.green : AppColors.amber),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _battery
                      ? 'ব্যাকগ্রাউন্ডে চলতে পারবে'
                      : 'ব্যাটারি সীমা বন্ধ করুন',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (!_battery) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: _openBattery,
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

/// কত মিনিটের পূর্বাভাস চাই (1 / 5 / 15) সেটা বাছাই করার কার্ড।
class TimeframeCard extends StatefulWidget {
  const TimeframeCard({super.key});

  @override
  State<TimeframeCard> createState() => _TimeframeCardState();
}

class _TimeframeCardState extends State<TimeframeCard> {
  static const _ch = MethodChannel('gasi/native');
  static const _options = [1, 5, 15];
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
  }

  Future<void> _pick(int m) async {
    setState(() => _sel = m);
    try {
      await _ch.invokeMethod('saveMinutes', {'minutes': m});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111015),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timer_outlined, size: 20, color: AppColors.lilac),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'কত মিনিটের পূর্বাভাস?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'UP/DOWN পার্সেন্টেজ এই সময়ের জন্য আসবে।',
            style: TextStyle(fontSize: 12, color: Color(0xFF8F8993)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final m in _options)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: m == _options.last ? 0 : 8),
                    child: GestureDetector(
                      onTap: () => _pick(m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _sel == m
                              ? AppColors.purple
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _sel == m
                                ? AppColors.lilac
                                : Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Text(
                          '$m মিনিট',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _sel == m ? Colors.white : const Color(0xFFB9B3BF),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
