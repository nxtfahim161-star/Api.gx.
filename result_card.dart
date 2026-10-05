class ResultCard extends StatelessWidget {
  final AIResult? result;
  const ResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final r = result;
    if (r == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111015),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: const Column(
          children: [
            Icon(Icons.candlestick_chart, size: 34, color: AppColors.lilac),
            SizedBox(height: 10),
            Text('AI Analysis Result',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text('এখনো কোনো বিশ্লেষণ হয়নি',
                style: TextStyle(fontSize: 12, color: Color(0xFF85808A))),
          ],
        ),
      );
    }

    final bull = r.up >= r.down;
    final c = bull ? AppColors.green : AppColors.red;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bull ? const Color(0xFF10251F) : const Color(0xFF29151A),
            const Color(0xFF100D13),
          ],
        ),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(bull ? Icons.trending_up : Icons.trending_down,
                  color: c, size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('AI Analysis Result',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              const Text('60 / 40',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lilac)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                  child: _probBox(
                      'UP', r.up, AppColors.green, Icons.arrow_upward)),
              const SizedBox(width: 12),
              Expanded(
                  child: _probBox(
                      'DOWN', r.down, AppColors.red, Icons.arrow_downward)),
            ],
          ),
          const SizedBox(height: 16),
          _row(Icons.candlestick_chart, 'Technical Pattern', r.pattern),
          const SizedBox(height: 10),
          _row(Icons.public, 'Market Sentiment', r.sentiment),
          const SizedBox(height: 10),
          _row(Icons.notes_outlined, 'Reason', r.reason),
        ],
      ),
    );
  }

  Widget _probBox(String label, double v, Color c, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.22)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: c, size: 16),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      color: c, fontSize: 12, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Text('${v.toStringAsFixed(1)}%',
              style: TextStyle(
                  color: c, fontSize: 28, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: const Color(0xFFB86CFF)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF85808A),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13, height: 1.45, color: Color(0xFFD9D4DC))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
