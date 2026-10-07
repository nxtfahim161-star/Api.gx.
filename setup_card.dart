import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Gemini API key সেভ করা + ব্যাটারি সেটিংস খোলার কার্ড।
/// পেজের Column-এ `const SetupCard()` বসালেই কাজ করবে।
class SetupCard extends StatefulWidget {
  const SetupCard({super.key});

  @override
  State<SetupCard> createState() => _SetupCardState();
}

class _SetupCardState extends State<SetupCard> {
  static const _ch = MethodChannel('gasi/native');
  static const _purple = Color(0xFF8B5CF6);
  static const _lilac = Color(0xFFC084FC);
  static const _green = Color(0xFF38D996);
  static const _amber = Color(0xFFFFB45C);

  final _c = TextEditingController();
  bool _hasKey = false;
  bool _battery = false;
  bool _hide = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
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
    await Future.delayed(const Duration(seconds: 1));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final keyColor = _hasKey ? _green : _amber;
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
            'aistudio.google.com/apikey থেকে key নিন। key শুধু এই ফোনে থাকবে।',
            style: TextStyle(fontSize: 12, color: Color(0xFF8F8993)),
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
                backgroundColor: _purple,
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
                  size: 20, color: _battery ? _green : _amber),
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
                  foregroundColor: _lilac,
                  side: BorderSide(color: _purple.withOpacity(0.4)),
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
