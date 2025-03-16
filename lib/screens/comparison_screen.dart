import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/analysis_stats.dart';
import '../models/otp_stats.dart';
import '../models/filter_options.dart';
import '../models/comparison_result.dart';
import '../services/sms_service.dart';

class ComparisonScreen extends StatefulWidget {
  final ComparisonResult comparison;

  const ComparisonScreen({
    Key? key,
    required this.comparison,
  }) : super(key: key);

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Comparison'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildComparisonHeader(),
            const SizedBox(height: 24),
            _buildMetricsComparison(),
            const SizedBox(height: 24),
            _buildDigitDistributionComparison(),
            const SizedBox(height: 24),
            _buildPatternAnalysisComparison(),
            const SizedBox(height: 24),
            _buildEntropyComparison(),
            const SizedBox(height: 24),
            _buildInsights(),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonHeader() {
    final firstDesc = widget.comparison.getFilterDescription(widget.comparison.firstFilter);
    final secondDesc = widget.comparison.getFilterDescription(widget.comparison.secondFilter);

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparing OTP Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    firstDesc,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'vs',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    secondDesc,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsComparison() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Metrics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Total OTPs
            _buildMetricRow(
              'Total OTPs',
              widget.comparison.firstStats.otpMessagesCount,
              widget.comparison.secondStats.otpMessagesCount,
              widget.comparison.otpCountDifference.toDouble(),
            ),
            const Divider(),

            // Randomness Score
            _buildMetricRow(
              'Randomness Score',
              widget.comparison.firstStats.otpStats.randomnessScore.toStringAsFixed(1),
              widget.comparison.secondStats.otpStats.randomnessScore.toStringAsFixed(1),
              widget.comparison.randomnessScoreDifference,
              isPercentage: false,
              decimals: 1,
            ),
            const Divider(),

            // Entropy
            _buildMetricRow(
              'Entropy',
              '${(widget.comparison.firstStats.otpStats.totalEntropy / widget.comparison.firstStats.otpStats.maxPossibleEntropy * 100).toStringAsFixed(1)}%',
              '${(widget.comparison.secondStats.otpStats.totalEntropy / widget.comparison.secondStats.otpStats.maxPossibleEntropy * 100).toStringAsFixed(1)}%',
              widget.comparison.entropyDifference / widget.comparison.firstStats.otpStats.maxPossibleEntropy * 100,
              isPercentage: true,
              decimals: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String title, dynamic firstValue, dynamic secondValue, double difference, {bool isPercentage = false, int decimals = 0}) {
    final diffStr = difference > 0
        ? '+${isPercentage ? difference.toStringAsFixed(decimals) + '%' : difference.toStringAsFixed(decimals)}'
        : difference.toStringAsFixed(decimals) + (isPercentage ? '%' : '');

    final diffColor = difference > 0 ? Colors.green : (difference < 0 ? Colors.red : Colors.grey);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(title),
        ),
        Expanded(
          flex: 2,
          child: Text(
            firstValue.toString(),
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            secondValue.toString(),
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            diffStr,
            style: TextStyle(
              color: diffColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildDigitDistributionComparison() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Digit Distribution',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: _buildDigitDistributionChart(),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildLegendItem('First Set', Colors.blue),
                const SizedBox(width: 24),
                _buildLegendItem('Second Set', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }

  Widget _buildDigitDistributionChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxDigitCount() * 1.2,
        titlesData: _getDigitTitles(),
        barGroups: _getDigitBarGroups(),
        barTouchData: BarTouchData(enabled: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 5,
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!),
            left: BorderSide(color: Colors.grey[300]!),
          ),
        ),
      ),
    );
  }

  FlTitlesData _getDigitTitles() {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (double value, TitleMeta meta) {
            return SideTitleWidget(
              meta: meta,
              space: 4,
              angle: 0,
              child: Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 12),
              ),
            );
          },
          reservedSize: 28,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
        ),
      ),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  List<BarChartGroupData> _getDigitBarGroups() {
    List<BarChartGroupData> groups = [];

    for (int i = 0; i < 10; i++) {
      // Get count for this digit in first dataset
      int firstCount = _getDigitCount(i.toString(), widget.comparison.firstStats.otpStats);
      int secondCount = _getDigitCount(i.toString(), widget.comparison.secondStats.otpStats);

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: firstCount.toDouble(),
              color: Colors.blue,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: secondCount.toDouble(),
              color: Colors.orange,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return groups;
  }

  int _getDigitCount(String digit, OtpStats stats) {
    if (digit == stats.mostCommonDigit) {
      return stats.mostCommonDigitCount;
    } else if (digit == stats.leastCommonDigit) {
      return stats.leastCommonDigitCount;
    } else {
      // Approximate for other digits
      return ((stats.mostCommonDigitCount + stats.leastCommonDigitCount) ~/ 3);
    }
  }

  double _getMaxDigitCount() {
    double maxFirst = widget.comparison.firstStats.otpStats.mostCommonDigitCount.toDouble();
    double maxSecond = widget.comparison.secondStats.otpStats.mostCommonDigitCount.toDouble();
    return maxFirst > maxSecond ? maxFirst : maxSecond;
  }

  Widget _buildPatternAnalysisComparison() {
    final first = widget.comparison.firstStats.otpStats;
    final second = widget.comparison.secondStats.otpStats;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pattern Analysis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Position bias comparison
            const Text(
              'Position Bias',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First dataset label
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('First Set'),
                ],
              ),
              const SizedBox(height: 8),

              // First dataset positions 1-6
              _buildPositionBiasRow(first.positionBias, Colors.blue),

              const SizedBox(height: 16),

              // Second dataset label
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Second Set'),
                ],
              ),
              const SizedBox(height: 8),

              // Second dataset positions 1-6
              _buildPositionBiasRow(second.positionBias, Colors.orange),
            ],
          ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Common prefixes comparison
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Common Prefixes',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      _buildPrefixList(first.commonPrefixes, Colors.blue),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Common Prefixes',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      _buildPrefixList(second.commonPrefixes, Colors.orange),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionBiasRow(Map<int, int> positionBias, Color color) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (position) {
          final String digit = positionBias.containsKey(position)
              ? positionBias[position].toString()
              : '?';

          return Container(
            width: 35,  // Reduced width
            height: 35,  // Reduced height
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              border: Border.all(color: color.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(4),
              color: color.withOpacity(0.1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  digit,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 15,  // Slightly smaller font
                  ),
                ),
                Text(
                  '${position + 1}',
                  style: TextStyle(
                    fontSize: 8,  // Smaller position number
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPositionBiasGrid(Map<int, int> positionBias, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (position) {
        final String digit = positionBias.containsKey(position)
            ? positionBias[position].toString()
            : '?';

        return Container(
          width: 28,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(4),
            color: color.withOpacity(0.1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                digit,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '${position + 1}',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPrefixList(Map<String, int> prefixes, Color color) {
    if (prefixes.isEmpty) {
      return const Text('No common prefixes');
    }

    final topPrefixes = prefixes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: topPrefixes.take(3).map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${entry.value}x'),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEntropyComparison() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entropy Comparison',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Overall entropy
            Row(
              children: [
                Expanded(
                  child: _buildEntropyItem(
                    'Overall',
                    widget.comparison.firstStats.otpStats.totalEntropy,
                    widget.comparison.firstStats.otpStats.maxPossibleEntropy,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildEntropyItem(
                    'Overall',
                    widget.comparison.secondStats.otpStats.totalEntropy,
                    widget.comparison.secondStats.otpStats.maxPossibleEntropy,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Position entropy comparison
            const Text(
              'Position Entropy',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: _buildPositionEntropyChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntropyItem(String label, double entropy, double maxEntropy, Color color) {
    final percentage = (entropy / maxEntropy * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: entropy / maxEntropy,
          backgroundColor: Colors.grey[200],
          color: color,
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildPositionEntropyChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.5,
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= 0 && value.toInt() < 6) {
                  return SideTitleWidget(
                    meta: meta,
                    space: 4,
                    angle: 0,
                    child: Text(
                      'Pos ${value.toInt() + 1}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!),
            left: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        minX: 0,
        maxX: 5,
        minY: 0,
        maxY: widget.comparison.firstStats.otpStats.maxPossibleEntropy,
        lineBarsData: [
          // First dataset
          LineChartBarData(
            spots: _getEntropySpots(widget.comparison.firstStats.otpStats.positionEntropy),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.1),
            ),
          ),
          // Second dataset
          LineChartBarData(
            spots: _getEntropySpots(widget.comparison.secondStats.otpStats.positionEntropy),
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.orange.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getEntropySpots(List<double> entropyValues) {
    List<FlSpot> spots = [];
    for (int i = 0; i < entropyValues.length; i++) {
      spots.add(FlSpot(i.toDouble(), entropyValues[i]));
    }
    return spots;
  }

  Widget _buildInsights() {
    // Generate insights based on the comparison
    List<String> insights = _generateInsights();

    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(insight)),
                    ],
                  ),
                )
            ),
          ],
        ),
      ),
    );
  }

  List<String> _generateInsights() {
    List<String> insights = [];

    // Entropy comparison
    if (widget.comparison.entropyDifference.abs() > 0.2) {
      final betterSet = widget.comparison.entropyDifference > 0 ? 'second' : 'first';
      insights.add(
          'The ${betterSet == 'second' ? 'orange' : 'blue'} set shows higher entropy (${(widget.comparison.entropyDifference.abs() / widget.comparison.firstStats.otpStats.maxPossibleEntropy * 100).toStringAsFixed(1)}% difference), indicating more randomness.'
      );
    }

    // Randomness score
    if (widget.comparison.randomnessScoreDifference.abs() > 1) {
      final betterSet = widget.comparison.randomnessScoreDifference > 0 ? 'second' : 'first';
      insights.add(
          'The ${betterSet == 'second' ? 'orange' : 'blue'} set has a better randomness score (${widget.comparison.randomnessScoreDifference.abs().toStringAsFixed(1)} points difference).'
      );
    }

    // Check for common prefixes
    final firstTopPrefix = _getTopPrefix(widget.comparison.firstStats.otpStats.commonPrefixes);
    final secondTopPrefix = _getTopPrefix(widget.comparison.secondStats.otpStats.commonPrefixes);

    if (firstTopPrefix != null && secondTopPrefix != null && firstTopPrefix.key != secondTopPrefix.key) {
      insights.add(
          'Different common prefixes detected: "${firstTopPrefix.key}" in blue set vs "${secondTopPrefix.key}" in orange set.'
      );
    }

    // Minimal insight if nothing significant found
    if (insights.isEmpty) {
      insights.add('There are no major differences in randomness or patterns between these two sets of OTPs.');
    }

    return insights;
  }

  MapEntry<String, int>? _getTopPrefix(Map<String, int> prefixes) {
    if (prefixes.isEmpty) return null;

    final sorted = prefixes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isNotEmpty) {
      return sorted.first;
    }

    return null;
  }
}