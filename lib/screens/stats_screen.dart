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
            const SizedBox(height: 24),

            // Common prefixes and suffixes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prefix & Suffix Analysis',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Common Prefixes',
                                  style: TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              ...stats.commonPrefixes.entries
                                  .toList()
                                  .where((e) => e.value > 1) // Only show prefixes that appear more than once
                                  .take(3) // Top 3
                                  .map((e) => _buildFrequencyItem(e.key, e.value, stats.totalCount))
                                  .toList(),
                              if (stats.commonPrefixes.entries.where((e) => e.value > 1).isEmpty)
                                const Text('No common prefixes found',
                                    style: TextStyle(fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Common Suffixes',
                                  style: TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              ...stats.commonSuffixes.entries
                                  .toList()
                                  .where((e) => e.value > 1) // Only show suffixes that appear more than once
                                  .take(3) // Top 3
                                  .map((e) => _buildFrequencyItem(e.key, e.value, stats.totalCount))
                                  .toList(),
                              if (stats.commonSuffixes.entries.where((e) => e.value > 1).isEmpty)
                                const Text('No common suffixes found',
                                    style: TextStyle(fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Digit pair analysis
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Digit Pair Analysis',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Consecutive digit pairs that appear frequently',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: stats.digitPairs.entries
                          .toList()
                          .where((e) => e.value > 2) // Only show pairs that appear more than twice
                          .take(5) // Top 5
                          .map((e) => _buildFrequencyItem(e.key, e.value, stats.totalCount * 5))
                          .toList(),
                    ),
                    if (stats.digitPairs.entries.where((e) => e.value > 2).isEmpty)
                      const Text('No significant digit pairs found',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Position bias
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Position Bias Analysis',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Most common digit at each position',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    _buildPositionBiasGrid(stats.positionBias),
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
                          'Randomness Analysis',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Randomness Score: ${stats.randomnessScore.toStringAsFixed(1)}/10',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Icon(
                          stats.randomnessScore > 7 ? Icons.check_circle :
                          (stats.randomnessScore > 4 ? Icons.warning : Icons.error),
                          color: stats.randomnessScore > 7 ? Colors.green :
                          (stats.randomnessScore > 4 ? Colors.orange : Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: stats.randomnessScore / 10,
                      backgroundColor: Colors.grey[300],
                      color: stats.randomnessScore > 7 ? Colors.green :
                      (stats.randomnessScore > 4 ? Colors.orange : Colors.red),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getRandomnessAnalysis(stats),
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

  Widget _buildFrequencyItem(String item, int count, int total) {
    final double percentage = count / total * 100;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            item,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              color: percentage > 30 ? Colors.red :
              (percentage > 20 ? Colors.orange : Colors.blue),
              minHeight: 8,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${count}x (${percentage.toStringAsFixed(1)}%)',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionBiasGrid(Map<int, int> positionBias) {
    // Create a fixed 2x3 grid
    return Column(
      children: [
        // First row - positions 1-3
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) {
            return _buildPositionCell(index, positionBias);
          }),
        ),
        const SizedBox(height: 12),
        // Second row - positions 4-6
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) {
            return _buildPositionCell(index + 3, positionBias);
          }),
        ),
      ],
    );
  }

  Widget _buildPositionCell(int position, Map<int, int> positionBias) {
    final String digit = positionBias.containsKey(position)
        ? positionBias[position].toString()
        : '?';

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Pos ${position + 1}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            digit,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getRandomnessAnalysis(OtpStats stats) {
    final List<String> insights = [];

    if (stats.randomnessScore > 8) {
      insights.add('✅ Your OTPs appear to be properly randomized with no significant patterns detected.');
    } else {
      if (stats.commonPrefixes.entries.where((e) => e.value > 1).isNotEmpty) {
        var mostCommonPrefix = stats.commonPrefixes.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        if (mostCommonPrefix.first.value > stats.totalCount * 0.3) {
          insights.add('⚠️ Strong prefix bias detected. The prefix "${mostCommonPrefix.first.key}" appears in ${mostCommonPrefix.first.value} of your OTPs.');
        }
      }

      if (stats.digitPairs.entries.where((e) => e.value > 2).isNotEmpty) {
        var mostCommonPair = stats.digitPairs.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        insights.add('⚠️ The digit sequence "${mostCommonPair.first.key}" appears ${mostCommonPair.first.value} times in your OTPs.');
      }

      if (stats.positionBias.isNotEmpty) {
        insights.add('⚠️ Position bias detected. Certain digits appear more frequently in specific positions.');
      }
    }

    if (insights.isEmpty) {
      if (stats.totalCount > 5) {
        insights.add('✅ No concerning patterns detected in your OTPs, but continue monitoring.');
      } else {
        insights.add('More OTP data needed for comprehensive randomness analysis.');
      }
    }

    return insights.join('\n\n');
  }
}