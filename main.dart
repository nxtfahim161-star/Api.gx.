import 'package:flutter/material.dart';

class AppColors {
  static const purple = Color(0xFF8B5CF6);
  static const lilac = Color(0xFFC084FC);
  static const green = Color(0xFF38D996);
  static const red = Color(0xFFFF6685);
  static const amber = Color(0xFFFFB45C);
}import 'dart:convert';

class AIResult {
  final double up;
  final double down;
  final String pattern;
  final String sentiment;
  final String reason;

  const AIResult(this.up, this.down, this.pattern, this.sentiment, this.reason);

  static AIResult? parse(String text) {
    try {
      var t = text.trim();
      final a = t.indexOf('{');
      final b = t.lastIndexOf('}');
      if (a < 0 || b <= a) return null;
      t = t.substring(a, b + 1);
      final m = jsonDecode(t);
      if (m is! Map) return null;
      final up = (m['up_probability_percent'] as num).toDouble();
      final down = (m['down_probability_percent'] as num).toDouble();
      if (!up.isFinite || !down.isFinite) return null;
      if (up < 0 || up > 100 || down < 0 || down > 100) return null;
      if ((up + down - 100).abs() > 0.1) return null;
      final pattern = m['technical_pattern'].toString().trim();
      final sentiment = m['market_sentiment'].toString().trim();
      final reason = m['summary_reason'].toString().trim();
      if (pattern.isEmpty || reason.isEmpty) return null;
      if (!const ['Bullish', 'Bearish', 'Neutral'].contains(sentiment)) {
        return null;
      }
      return AIResult(up, down, pattern, sentiment, reason);
    } catch (_) {
      return null;
    }
  }
}import 'package:flutter/material.dart';
import 'app_colors.dart';

class HowCard extends StatelessWidget {
  const HowCard({super.key});

  static const steps = [
    ['Permission', 'Overlay permission দিন, যাতে অন্য app-এর উপর G button দেখা যায়।'],
    ['Screen Capture', 'Start চাপলে Android screen capture-এর অনুমতি চাইবে।'],
    ['Capture', 'Chart screen-এ G button চাপলে screenshot নেওয়া হবে।'],
    ['AI Analysis', 'Screenshot ও prompt Share দিয়ে আপনার পছন্দের AI app-এ পাঠান।'],
    ['Result', 'AI-র JSON উত্তর এখানে paste করলে UP/DOWN result দেখা যাবে।'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111015),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 21, color: Color(0xFFB86CFF)),
              SizedBox(width: 9),
              Text('কীভাবে কাজ করে',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.13),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.purple.withOpacity(0.28)),
                    ),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.lilac)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(steps[i][0],
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(steps[i][1],
                            style: const TextStyle(
                                fontSize: 12,
                                height: 1.45,
                                color: Color(0xFF8F8993))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class DisclaimerCard extends StatelessWidget {
  const DisclaimerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171218),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.amber.withOpacity(0.16)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.amber),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'AI probability একটি analytical estimate। এটি নিশ্চিত ভবিষ্যদ্বাণী নয়। Trading-এর সিদ্ধান্ত নেওয়ার আগে নিজে যাচাই করুন।',
              style: TextStyle(
                  fontSize: 11, height: 1.5, color: Color(0xFF9B939E)),
            ),
          ),
        ],
      ),
    );
  }
}import 'package:flutter/material.dart';
import 'app_colors.dart';

class HeaderBar extends StatelessWidget {
  const HeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: AppColors.purple.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 1),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                color: const Color(0xFF17121B),
                alignment: Alignment.center,
                child: const Text('G',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.lilac)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('gasi candle analysis AI',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text('Hybrid AI Chart Analysis',
                  style: TextStyle(fontSize: 13, color: Color(0xFFAAA4AE))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.purple.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.purple.withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 14, color: AppColors.lilac),
              SizedBox(width: 5),
              Text('AI',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lilac)),
            ],
          ),
        ),
      ],
    );
  }
}

class CaptureCard extends StatelessWidget {
  final bool granted;
  final bool starting;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const CaptureCard({
    super.key,
    required this.granted,
    required this.starting,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF21142A), Color(0xFF100D14)],
        ),
        border: Border.all(color: AppColors.purple.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.16),
                    shape: BoxShape.circle),
                child: const Icon(Icons.analytics_outlined,
                    color: AppColors.lilac, size: 25),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chart Analysis',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    SizedBox(height: 3),
                    Text('আপনার বর্তমান chart capture করুন',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFFAAA4AE))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Start চাপুন, তারপর chart screen-এ গিয়ে ভাসমান G button চাপুন।',
            style:
                TextStyle(fontSize: 14, height: 1.5, color: Color(0xFFD0CBD3)),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: (!granted || starting) ? null : onStart,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.purple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17)),
              ),
              child: starting
                  ? const SizedBox(
                      width: 23,
                      height: 23,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.screen_share_outlined, size: 21),
                        SizedBox(width: 9),
                        Text('Start Chart Capture',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onStop,
              icon: const Icon(Icons.stop_circle_outlined, size: 19),
              label: const Text('Stop Floating G'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE1D9E5),
                side: BorderSide(color: AppColors.lilac.withOpacity(0.35)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PermissionCard extends StatelessWidget {
  final bool granted;
  final VoidCallback onOpenSettings;

  const PermissionCard({
    super.key,
    required this.granted,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final c = granted ? AppColors.green : AppColors.amber;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF121116),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: c.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(granted ? Icons.check : Icons.lock_outline,
                    color: c, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      granted
                          ? 'Overlay Permission Active'
                          : 'Overlay Permission Required',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      granted
                          ? 'Floating G button ব্যবহার করা যাবে।'
                          : 'অন্য app-এর উপর G button দেখাতে permission দিন।',
                      style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: Color(0xFF97919A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!granted) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: OutlinedButton(
                onPressed: onOpenSettings,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.lilac,
                  side: BorderSide(color: AppColors.purple.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Open Permission Settings'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PasteCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onPaste;
  final VoidCallback onShow;

  const PasteCard({
    super.key,
    required this.controller,
    required this.onPaste,
    required this.onShow,
  });

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
              Icon(Icons.data_object, size: 20, color: Color(0xFFB86CFF)),
              SizedBox(width: 9),
              Text('AI-র JSON উত্তর',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'AI app-এর JSON উত্তর কপি করে এখানে paste করুন।',
            style: TextStyle(fontSize: 12, color: Color(0xFF8F8993)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 4,
            maxLines: 8,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: '{ "up_probability_percent": ... }',
              filled: true,
              fillColor: Colors.white.withOpacity(0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPaste,
                  icon: const Icon(Icons.content_paste, size: 18),
                  label: const Text('Paste'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onShow,
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.purple),
                  child: const Text('Result দেখান'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
