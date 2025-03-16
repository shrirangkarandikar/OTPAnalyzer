import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../models/analysis_stats.dart';
import '../models/otp_stats.dart';
import '../models/sms_message.dart';
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
  AnalysisStats? _stats;
  List<SmsMessageModel> _allMessages = [];
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
      // Get all messages
      final messages = await _smsService.getAllMessages();

      // Analyze the messages
      final stats = _smsService.analyzeMessages(messages);

      setState(() {
        _allMessages = messages;
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
        title: const Text('OTP Analyzer Dashboard'),
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

    if (_stats == null || _stats!.otpStats.totalCount == 0) {
      return const Center(
        child: Text('No OTP data available. Try receiving some OTP messages first.'),
      );
    }

    final dateFormat = DateFormat('MMM dd, yyyy');

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
            'Based on ${_stats!.totalMessagesRead} messages analyzed from ${dateFormat.format(_stats!.earliestMessageDate)} to ${dateFormat.format(_stats!.latestMessageDate)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Found ${_stats!.otpMessagesCount} messages with valid OTP codes',
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
                  title: 'OTP Messages',
                  value: _stats!.otpMessagesCount.toString(),
                  icon: Icons.sms,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatsCard(
                  title: 'Entropy',
                  value: '${(_stats!.otpStats.totalEntropy / _stats!.otpStats.maxPossibleEntropy * 100).toStringAsFixed(1)}%',
                  icon: Icons.bar_chart,
                  color: _stats!.otpStats.totalEntropy > _stats!.otpStats.maxPossibleEntropy * 0.7 ? Colors.green[50] :
                  (_stats!.otpStats.totalEntropy > _stats!.otpStats.maxPossibleEntropy * 0.5 ? Colors.orange[50] : Colors.red[50]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sender information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person),
                      SizedBox(width: 8),
                      Text(
                        'Sender Analysis',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        const TextSpan(
                          text: 'Most frequent OTP sender: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: '${_stats!.mostFrequentOtpSender} (${_stats!.mostFrequentOtpSenderCount} messages)',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        const TextSpan(
                          text: 'Most frequent overall sender: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: '${_stats!.mostFrequentOverallSender} (${_stats!.mostFrequentOverallSenderCount} messages)',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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

          // Message categories
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Message Categories',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMessageCategoriesChart(),
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
                          builder: (context) => StatsScreen(stats: _stats!.otpStats),
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
    double maxDigitCount = _stats!.otpStats.mostCommonDigitCount.toDouble();
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
                toY: (_stats!.otpStats.mostCommonDigit == i.toString() ?
                _stats!.otpStats.mostCommonDigitCount.toDouble() :
                (_stats!.otpStats.leastCommonDigit == i.toString() ?
                _stats!.otpStats.leastCommonDigitCount.toDouble() :
                (_stats!.otpStats.mostCommonDigitCount.toDouble() + _stats!.otpStats.leastCommonDigitCount.toDouble()) / 3)),
                color: i.toString() == _stats!.otpStats.mostCommonDigit ?
                Colors.blue : (i.toString() == _stats!.otpStats.leastCommonDigit ?
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

  Widget _buildMessageCategoriesChart() {
    // Create a bar chart for message categories
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: math.max(
            _stats!.otpMessagesCount.toDouble(),
            math.max(
              _stats!.otpStringNoCodeCount.toDouble(),
              _stats!.otherMessagesCount.toDouble(),
            ),
          ) * 1.2, // Add 20% padding
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  String label;
                  switch (value.toInt()) {
                    case 0:
                      label = 'OTP';
                      break;
                    case 1:
                      label = 'OTP No Code';
                      break;
                    case 2:
                      label = 'Other';
                      break;
                    default:
                      label = '';
                  }
                  return SideTitleWidget(
                    meta: meta,
                    space: 4,
                    angle: 0,
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  );
                },
                reservedSize: 30,
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
          gridData: FlGridData(show: true, horizontalInterval: 10),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: _stats!.otpMessagesCount.toDouble(),
                  color: Colors.blue,
                  width: 40,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: _stats!.otpStringNoCodeCount.toDouble(),
                  color: Colors.orange,
                  width: 40,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: _stats!.otherMessagesCount.toDouble(),
                  color: Colors.grey,
                  width: 40,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            ),
          ],
        ),
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
              'OTP Randomness Score: ${_stats!.otpStats.randomnessScore.toStringAsFixed(1)}/10',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Icon(
              _stats!.otpStats.randomnessScore > 7 ? Icons.check_circle :
              (_stats!.otpStats.randomnessScore > 4 ? Icons.warning : Icons.error),
              color: _stats!.otpStats.randomnessScore > 7 ? Colors.green :
              (_stats!.otpStats.randomnessScore > 4 ? Colors.orange : Colors.red),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _stats!.otpStats.randomnessScore / 10,
          backgroundColor: Colors.grey[300],
          color: _stats!.otpStats.randomnessScore > 7 ? Colors.green :
          (_stats!.otpStats.randomnessScore > 4 ? Colors.orange : Colors.red),
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
    if (_stats!.otpStats.randomnessScore > 8) {
      return 'Your OTPs appear to be properly randomized with good entropy.';
    } else if (_stats!.otpStats.randomnessScore > 6) {
      return 'Your OTPs show reasonable randomness but have some minor patterns.';
    } else if (_stats!.otpStats.randomnessScore > 4) {
      return 'Some concerning patterns found that reduce OTP security.';
    } else {
      return 'Multiple security concerns detected that significantly reduce OTP randomness.';
    }
  }
}