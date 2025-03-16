import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/otp_stats.dart';
import '../services/sms_service.dart';
import '../widgets/stats_card.dart';
import 'stats_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SmsService _smsService = SmsService();
  OtpStats? _stats;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get all OTP messages (limit 100)
      final messages = await _smsService.getOtpMessages(limit: 100);

      // Analyze the OTPs
      final stats = _smsService.analyzeOtpCodes(messages);

      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_stats == null || _stats!.totalCount == 0) {
      return const Center(
        child: Text('No OTP data available. Try receiving some OTP messages first.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OTP Analysis Summary',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Based on the last ${_stats!.totalCount} OTP messages',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Overview cards
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Total OTPs',
                  value: _stats!.totalCount.toString(),
                  icon: Icons.numbers,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatsCard(
                  title: 'Randomness',
                  value: '${_stats!.randomnessScore.toStringAsFixed(1)}/10',
                  icon: Icons.shuffle,
                  color: _stats!.randomnessScore > 7 ? Colors.green[50] :
                  (_stats!.randomnessScore > 4 ? Colors.orange[50] : Colors.red[50]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Distribution chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Digit Distribution',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildDigitDistributionChart(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Common patterns
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pattern Detection',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPatternSummary(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Security overview
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
                        'Security Overview',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSecurityIndicator(),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StatsScreen(stats: _stats!),
                        ),
                      );
                    },
                    child: const Text('View Detailed Analysis'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitDistributionChart() {
    // Find the maximum value for proper scaling
    double maxDigitCount = _stats!.mostCommonDigitCount.toDouble();
    // Add a little padding (20%) to the top of the chart for better visualization
    double chartMaxY = maxDigitCount * 1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartMaxY,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
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
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        barGroups: List.generate(10, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: (_stats!.mostCommonDigit == i.toString() ?
                _stats!.mostCommonDigitCount.toDouble() :
                (_stats!.leastCommonDigit == i.toString() ?
                _stats!.leastCommonDigitCount.toDouble() :
                (_stats!.mostCommonDigitCount.toDouble() + _stats!.leastCommonDigitCount.toDouble()) / 3)),
                color: i.toString() == _stats!.mostCommonDigit ?
                Colors.blue : (i.toString() == _stats!.leastCommonDigit ?
                Colors.red : Colors.grey),
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPatternSummary() {
    // Check for any significant patterns
    List<Widget> patternItems = [];

    // Check prefix patterns
    Map<String, int> commonPrefixes = Map.from(_stats!.commonPrefixes);
    commonPrefixes.removeWhere((key, value) => value <= 1);

    if (commonPrefixes.isNotEmpty) {
      var topPrefixes = commonPrefixes.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (topPrefixes.isNotEmpty) {
        patternItems.add(
          _buildPatternItem(
            'Common Prefix: ${topPrefixes.first.key}',
            'Appears in ${topPrefixes.first.value} OTPs',
            Icons.format_indent_increase,
            Colors.blue,
          ),
        );
      }
    }

    // Check digit pairs
    Map<String, int> topPairs = Map.from(_stats!.digitPairs);
    topPairs.removeWhere((key, value) => value <= 2);

    if (topPairs.isNotEmpty) {
      var sortedPairs = topPairs.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (sortedPairs.isNotEmpty) {
        patternItems.add(
          _buildPatternItem(
            'Common Sequence: ${sortedPairs.first.key}',
            'Appears ${sortedPairs.first.value} times',
            Icons.linear_scale,
            Colors.purple,
          ),
        );
      }
    }

    // Check position bias
    if (_stats!.positionBias.isNotEmpty) {
      int positionCount = _stats!.positionBias.length;
      patternItems.add(
        _buildPatternItem(
          'Position Bias Detected',
          'Found in $positionCount positions',
          Icons.grid_on,
          Colors.orange,
        ),
      );
    }

    if (patternItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No significant patterns detected',
            style: TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Column(
      children: patternItems,
    );
  }

  Widget _buildPatternItem(String title, String subtitle, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'OTP Randomness Score: ${_stats!.randomnessScore.toStringAsFixed(1)}/10',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Icon(
              _stats!.randomnessScore > 7 ? Icons.check_circle :
              (_stats!.randomnessScore > 4 ? Icons.warning : Icons.error),
              color: _stats!.randomnessScore > 7 ? Colors.green :
              (_stats!.randomnessScore > 4 ? Colors.orange : Colors.red),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _stats!.randomnessScore / 10,
          backgroundColor: Colors.grey[300],
          color: _stats!.randomnessScore > 7 ? Colors.green :
          (_stats!.randomnessScore > 4 ? Colors.orange : Colors.red),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Text(
          _getSecuritySummary(),
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  String _getSecuritySummary() {
    if (_stats!.randomnessScore > 8) {
      return 'Your OTPs appear to be properly randomized with good entropy.';
    } else if (_stats!.randomnessScore > 6) {
      return 'Your OTPs show reasonable randomness but have some minor patterns.';
    } else if (_stats!.randomnessScore > 4) {
      return 'Some concerning patterns found that reduce OTP security.';
    } else {
      return 'Multiple security concerns detected that significantly reduce OTP randomness.';
    }
  }
}