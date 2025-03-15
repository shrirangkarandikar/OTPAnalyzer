import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/sms_service.dart';
import '../models/sms_message.dart';
import '../widgets/sms_message_card.dart';

class SmsScreen extends StatefulWidget {
  const SmsScreen({Key? key}) : super(key: key);

  @override
  State<SmsScreen> createState() => _SmsScreenState();
}

class _SmsScreenState extends State<SmsScreen> {
  final SmsService _smsService = SmsService();
  List<SmsMessageModel> _messages = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoadMessages();
  }

  Future<void> _requestPermissionAndLoadMessages() async {
    final status = await Permission.sms.request();
    
    if (status.isGranted) {
      try {
        final messages = await _smsService.getLastFiveMessages();
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to load messages: $e';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = 'SMS permission denied';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    await _requestPermissionAndLoadMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Last 5 SMS Messages'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshMessages,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
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
              onPressed: _refreshMessages,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Text('No SMS messages found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return SmsMessageCard(message: _messages[index]);
      },
    );
  }
}
