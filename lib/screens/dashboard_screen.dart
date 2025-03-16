import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/otp_stats.dart';
import '../services/sms_service.dart';
import '../widgets/stats_card.dart';
import 'stats_screen.dart'; // Import stats_screen.dart

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
                  title: 'Avg. Value',
                  value: _stats!.averageValue.toStringAsFixed(0),
                  icon: Icons.calculate,
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

  Widget _buildSecurityIndicator() {
    // Determine security score based on patterns detected
    int securityIssues = 0;
    if (_stats!.hasSequentialOtp) securityIssues++;
    if (_stats!.hasAllSameDigitsOtp) securityIssues++;
    if (_stats!.palindromeCount > 0) securityIssues++;
    if (_stats!.risingPatternCount > 0) securityIssues++;
    if (_stats!.fallingPatternCount > 0) securityIssues++;
    if (_stats!.alternatingPatternCount > 0) securityIssues++;

    int securityScore = 10 - securityIssues;
    securityScore = securityScore.clamp(0, 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Security Score: ${securityScore.toStringAsFixed(1)}/10',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Icon(
              securityScore > 7 ? Icons.check_circle :
              (securityScore > 4 ? Icons.warning : Icons.error),
              color: securityScore > 7 ? Colors.green :
              (securityScore > 4 ? Colors.orange : Colors.red),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: securityScore / 10,
          backgroundColor: Colors.grey[300],
          color: securityScore > 7 ? Colors.green :
          (securityScore > 4 ? Colors.orange : Colors.red),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Text(
          securityScore > 7 ? 'Your OTPs appear to be properly randomized.' :
          (securityScore > 4 ? 'Some pattern concerns found in your OTPs.' :
          'Multiple security concerns detected in your OTPs.'),
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}