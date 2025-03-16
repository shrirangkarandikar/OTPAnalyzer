import 'package:flutter/material.dart';
import '../models/otp_stats.dart';
import '../widgets/stats_card.dart';

class StatsScreen extends StatelessWidget {
  final OtpStats stats;

  const StatsScreen({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Analysis'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics based on ${stats.totalCount} OTP codes',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Basic stats
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Average Value',
                    value: stats.averageValue.toStringAsFixed(2),
                    icon: Icons.calculate,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatsCard(
                    title: 'Min Value',
                    value: stats.minValue.toString(),
                    icon: Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatsCard(
                    title: 'Max Value',
                    value: stats.maxValue.toString(),
                    icon: Icons.arrow_upward,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Digit frequency
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Most Common Digit',
                    value: '${stats.mostCommonDigit} (${stats.mostCommonDigitCount})',
                    icon: Icons.trending_up,
                    color: Colors.green[100],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatsCard(
                    title: 'Least Common Digit',
                    value: '${stats.leastCommonDigit} (${stats.leastCommonDigitCount})',
                    icon: Icons.trending_down,
                    color: Colors.red[100],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pattern analysis
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pattern Analysis',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    _buildPatternItem(
                      'Sequential digits (e.g., 123456)',
                      stats.hasSequentialOtp,
                    ),
                    _buildPatternItem(
                      'All same digits (e.g., 555555)',
                      stats.hasAllSameDigitsOtp,
                    ),
                    _buildPatternItem(
                      'Palindromes (same forwards & backwards)',
                      stats.palindromeCount > 0,
                      count: stats.palindromeCount,
                    ),
                    _buildPatternItem(
                      'Rising patterns (e.g., 135789)',
                      stats.risingPatternCount > 0,
                      count: stats.risingPatternCount,
                    ),
                    _buildPatternItem(
                      'Falling patterns (e.g., 987532)',
                      stats.fallingPatternCount > 0,
                      count: stats.fallingPatternCount,
                    ),
                    _buildPatternItem(
                      'Alternating patterns (e.g., 131313)',
                      stats.alternatingPatternCount > 0,
                      count: stats.alternatingPatternCount,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Security analysis
            Card(
              color: Colors.amber[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.security),
                        SizedBox(width: 8),
                        Text(
                          'Security Analysis',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getSecurityAnalysis(stats),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternItem(String label, bool exists, {int? count}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            exists ? Icons.check_circle : Icons.cancel,
            color: exists ? Colors.green : Colors.red[300],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label),
          ),
          if (count != null && count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  String _getSecurityAnalysis(OtpStats stats) {
    List<String> insights = [];

    // Security concerns
    if (stats.hasSequentialOtp) {
      insights.add('⚠️ Some OTPs use sequential digits, which are less secure.');
    }

    if (stats.hasAllSameDigitsOtp) {
      insights.add('⚠️ Some OTPs use all identical digits, which are very weak.');
    }

    if (stats.palindromeCount > 0) {
      insights.add('⚠️ ${stats.palindromeCount} OTPs are palindromes, making them slightly more predictable.');
    }

    if (stats.risingPatternCount > 0 || stats.fallingPatternCount > 0) {
      insights.add('⚠️ ${stats.risingPatternCount + stats.fallingPatternCount} OTPs have strictly rising or falling patterns.');
    }

    if (stats.alternatingPatternCount > 0) {
      insights.add('⚠️ ${stats.alternatingPatternCount} OTPs have alternating patterns, which are more predictable.');
    }

    // General insight on distribution
    if (stats.mostCommonDigitCount > (stats.totalCount * 6) / 8) {
      // If one digit appears in over 75% of positions it should be present
      insights.add('⚠️ The digit ${stats.mostCommonDigit} appears unusually frequently, suggesting non-uniform distribution.');
    }

    // Positive feedback if no patterns detected
    if (insights.isEmpty && stats.totalCount > 5) {
      insights.add('✅ No concerning patterns detected in your OTPs. They appear to be randomly generated.');
    } else if (insights.isEmpty) {
      insights.add('More OTP data needed for comprehensive security analysis.');
    }

    return insights.join('\n\n');
  }
}