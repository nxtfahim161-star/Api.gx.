void main() => runApp(const GasiApp());

class GasiApp extends StatelessWidget {
  const GasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'gasi candle analysis AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF08080D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.purple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
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

  final TextEditingController _ctrl = TextEditingController();
  bool _granted = false;
  bool _starting = false;
  AIResult? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    try {
      final r = await _ch.invokeMethod<bool>('hasOverlayPermission');
      if (mounted) setState(() => _granted = r ?? false);
    } catch (_) {}
  }

  Future<void> _start() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      await _ch.invokeMethod('startOverlay');
    } on PlatformException catch (e) {
      _msg(e.message ?? 'শুরু করা যায়নি');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _stop() async {
    try {
      await _ch.invokeMethod('stopOverlay');
      _msg('Floating G বন্ধ করা হয়েছে');
    } catch (_) {
      _msg('বন্ধ করা যায়নি');
    }
  }

  Future<void> _openSettings() async {
    try {
      await _ch.invokeMethod('openOverlaySettings');
    } catch (_) {
      _msg('Settings খোলা যায়নি');
    }
  }

  Future<void> _paste() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    if (d?.text != null && mounted) {
      setState(() => _ctrl.text = d!.text!);
    }
  }

  void _showResult() {
    final r = AIResult.parse(_ctrl.text);
    if (r == null) {
      _msg('JSON সঠিক নয় (UP+DOWN=100 এবং সব field লাগবে)');
      return;
    }
    setState(() => _result = r);
    FocusScope.of(context).unfocus();
  }

  void _msg(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(t), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _check,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            children: [
              const HeaderBar(),
              const SizedBox(height: 22),
              CaptureCard(
                granted: _granted,
                starting: _starting,
                onStart: _start,
                onStop: _stop,
              ),
              const SizedBox(height: 16),
              PermissionCard(granted: _granted, onOpenSettings: _openSettings),
              const SizedBox(height: 16),
              PasteCard(
                controller: _ctrl,
                onPaste: _paste,
                onShow: _showResult,
              ),
              const SizedBox(height: 16),
              ResultCard(result: _result),
              const SizedBox(height: 16),
              const HowCard(),
              const SizedBox(height: 16),
              const DisclaimerCard(),
            ],
          ),
        ),
      ),
    );
  }
}
