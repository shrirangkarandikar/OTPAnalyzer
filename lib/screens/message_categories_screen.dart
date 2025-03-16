import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sms_message.dart';
import '../models/analysis_stats.dart';
import '../models/otp_stats.dart';
import '../services/sms_service.dart';
import '../widgets/sms_message_card.dart';
import 'stats_screen.dart';

class MessageCategoriesScreen extends StatefulWidget {
  final List<SmsMessageModel> messages;

  const MessageCategoriesScreen({
    Key? key,
    required this.messages,
  }) : super(key: key);

  @override
  State<MessageCategoriesScreen> createState() => _MessageCategoriesScreenState();
}

class _MessageCategoriesScreenState extends State<MessageCategoriesScreen> with SingleTickerProviderStateMixin {
  final SmsService _smsService = SmsService();
  late TabController _tabController;
  late List<SmsMessageModel> _otpMessages;
  late List<SmsMessageModel> _otpStringNoCodeMessages;
  late List<SmsMessageModel> _otherMessages;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Categorize messages
    _otpMessages = _smsService.getOtpMessages(widget.messages);
    _otpStringNoCodeMessages = _smsService.getOtpStringNoCodeMessages(widget.messages);
    _otherMessages = _smsService.getOtherMessages(widget.messages);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Categories'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('OTP Messages'),
                Text('(${_otpMessages.length})'),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('OTP No Code'),
                Text('(${_otpStringNoCodeMessages.length})'),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Other'),
                Text('(${_otherMessages.length})'),
              ],
            ),
          ],
          labelPadding: const EdgeInsets.symmetric(vertical: 8.0),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMessageList(_otpMessages),
          _buildMessageList(_otpStringNoCodeMessages),
          _buildMessageList(_otherMessages),
        ],
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