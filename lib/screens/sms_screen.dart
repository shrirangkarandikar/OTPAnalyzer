import 'package:flutter/material.dart';
import '../services/sms_service.dart';
import '../models/sms_message.dart';
import '../models/otp_stats.dart';
import '../widgets/sms_message_card.dart';
import 'stats_screen.dart';

class SmsScreen extends StatefulWidget {
  const SmsScreen({Key? key}) : super(key: key);

  @override
  State<SmsScreen> createState() => _SmsScreenState();
}

class _SmsScreenState extends State<SmsScreen> {
  final SmsService _smsService = SmsService();
  List<SmsMessageModel> _messages = [];
  OtpStats? _stats;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final messages = await _smsService.getOtpMessages(limit: 5);
      final stats = _smsService.analyzeOtpCodes(messages);

      setState(() {
        _messages = messages;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load messages: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Messages'),
        actions: [
          if (_stats != null && _stats!.totalCount > 0)
            IconButton(
              icon: const Icon(Icons.bar_chart),
              tooltip: 'View Analysis',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StatsScreen(stats: _stats!),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadMessages,
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
              onPressed: _loadMessages,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sms_failed,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No OTP messages found',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try receiving an OTP via SMS',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              onPressed: _loadMessages,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Summary card
        if (_stats != null && _stats!.totalCount > 0)
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics_outlined),
                      const SizedBox(width: 8),
                      Text(
                        'OTP Analysis Available',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Analyzed ${_stats!.totalCount} OTP codes',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StatsScreen(stats: _stats!),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('View Analysis'),
                  ),
                ],
              ),
            ),
          ),

        // Message list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              return SmsMessageCard(message: _messages[index]);
            },
          ),
        ),
      ],
    );
  }
}