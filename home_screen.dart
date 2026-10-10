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
}void main() {
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
  String _bg = 'aurora';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _loadBg();
  }Future<void> _loadBg() async {
    try {
      final u = await _ch.invokeMethod<Map<dynamic, dynamic>>('getUi');
      final b = u?['bg'];
      if (b is String && mounted) setState(() => _bg = b);
    } catch (_) {}
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
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: gasiBackground(_bg),
        child: SafeArea(
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
            const StatsCard(),
            gap,
            AppearanceCard(onBg: (id) => setState(() => _bg = id)),
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
      ),
    );
  }
}/// Gemini API key সেভ করা + ব্যাটারি সেটিংস খোলার কার্ড।
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
}/// কত মিনিটের পূর্বাভাস চাই (1 / 5 / 15) সেটা বাছাই করার কার্ড।
class TimeframeCard extends StatefulWidget {
  const TimeframeCard({super.key});

  @override
  State<TimeframeCard> createState() => _TimeframeCardState();
}

class _TimeframeCardState extends State<TimeframeCard> {
  static const _ch = MethodChannel('gasi/native');
  static const _options = [1, 5, 15];
  int _sel = 5;
  bool _web = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final m = await _ch.invokeMethod<int>('getMinutes');
      final w = await _ch.invokeMethod<bool>('getWeb');
      if (mounted) {
        setState(() {
          if (m != null) _sel = m;
          if (w != null) _web = w;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleWeb(bool v) async {
    setState(() => _web = v);
    try {
      await _ch.invokeMethod('saveWeb', {'web': v});
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
          const SizedBox(height: 14),
          Divider(color: Colors.white.withOpacity(0.07), height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ওয়েব সার্চ',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      _web
                          ? 'চালু: বেশি তথ্য, উত্তর একটু ধীরে (প্রথমবার)'
                          : 'বন্ধ: দ্রুত উত্তর, শুধু চার্ট ও বইয়ের জ্ঞান',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8F8993)),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _web,
                onChanged: _toggleWeb,
                activeColor: AppColors.purple,
              ),
            ],
          ),
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
  List<int> _s = List.filled(8, 0);

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
      if (r != null && r.length >= 8 && mounted) {
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

  Widget _mini(String label, int h, int t) {
    return Expanded(
      child: Container(
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
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800)),
            Text('$h/$t',
                style: const TextStyle(fontSize: 11, color: Color(0xFF8F8993))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _s[0];
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
            total == 0 ? 'এখনও কোনো হিসাব নেই' : '${_s[1]} টা মিলেছে, মোট $total টা',
            style: const TextStyle(fontSize: 12, color: Color(0xFF8F8993)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _mini('১ মিনিট', _s[3], _s[2]),
              const SizedBox(width: 8),
              _mini('৫ মিনিট', _s[5], _s[4]),
              const SizedBox(width: 8),
              _mini('১৫ মিনিট', _s[7], _s[6]),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'রেজাল্ট কার্ডে ✅/❌ চেপে হিসাব যোগ করুন। ২০-৩০টার কম ট্রেডে এই হার ভরসাযোগ্য নয়।',
            style: TextStyle(fontSize: 11, height: 1.4, color: Color(0xFF8F8993)),
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
