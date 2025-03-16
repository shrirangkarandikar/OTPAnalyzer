import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sms_message.dart';
import '../models/analysis_stats.dart';
import '../models/otp_stats.dart';
import '../services/sms_service.dart';
import '../widgets/sms_message_card.dart';
import 'stats_screen.dart';

class MessageCategoriesScreen extends StatefulWidget {
  const MessageCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<MessageCategoriesScreen> createState() => _MessageCategoriesScreenState();
}

class _MessageCategoriesScreenState extends State<MessageCategoriesScreen> with SingleTickerProviderStateMixin {
  final SmsService _smsService = SmsService();
  List<SmsMessageModel> _allMessages = [];
  AnalysisStats? _stats;
  bool _isLoading = true;
  String _errorMessage = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMessages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final messages = await _smsService.getAllMessages();
      final stats = _smsService.analyzeMessages(messages);

      setState(() {
        _allMessages = messages;
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
        title: const Text('Message Categories'),
        actions: [
          if (_stats != null)
            IconButton(
              icon: const Icon(Icons.bar_chart),
              tooltip: 'View Analysis',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StatsScreen(stats: _stats!.otpStats),
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
        bottom: _isLoading ? null : TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'OTP Messages (${_stats?.otpMessagesCount ?? 0})'),
            Tab(text: 'OTP No Code (${_stats?.otpStringNoCodeCount ?? 0})'),
            Tab(text: 'Other (${_stats?.otherMessagesCount ?? 0})'),
          ],
        ),
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

    if (_allMessages.isEmpty) {
      return const Center(
        child: Text('No messages found'),
      );
    }

    return Column(
      children: [
        // Stats summary card
        if (_stats != null)
          _buildStatsSummaryCard(),

        // Message categories
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMessageList(_smsService.getOtpMessages(_allMessages)),
              _buildMessageList(_smsService.getOtpStringNoCodeMessages(_allMessages)),
              _buildMessageList(_smsService.getOtherMessages(_allMessages)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSummaryCard() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final stats = _stats!;

    return Card(
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
                  'Message Analysis Summary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            Text(
              'Analyzed ${stats.totalMessagesRead} total messages from ${dateFormat.format(stats.earliestMessageDate)} to ${dateFormat.format(stats.latestMessageDate)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Found ${stats.otpMessagesCount} messages with valid OTP codes',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),

            // Most frequent senders
            if (stats.mostFrequentOtpSender.isNotEmpty)
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    const TextSpan(
                      text: 'Most frequent OTP sender: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: '${stats.mostFrequentOtpSender} (${stats.mostFrequentOtpSenderCount} messages)',
                    ),
                  ],
                ),
              ),

            if (stats.mostFrequentOverallSender.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      const TextSpan(
                        text: 'Most frequent overall sender: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: '${stats.mostFrequentOverallSender} (${stats.mostFrequentOverallSenderCount} messages)',
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

  Widget _buildMessageList(List<SmsMessageModel> messages) {
    if (messages.isEmpty) {
      return const Center(
        child: Text('No messages in this category'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return SmsMessageCard(message: messages[index]);
      },
    );
  }
}