import 'package:flutter/material.dart';
import '../models/sms_message.dart';
import '../models/otp_stats.dart';
import '../services/sms_service.dart';
import '../widgets/sms_message_card.dart';

class DetailedAnalysisScreen extends StatefulWidget {
  const DetailedAnalysisScreen({Key? key}) : super(key: key);

  @override
  State<DetailedAnalysisScreen> createState() => _DetailedAnalysisScreenState();
}

class _DetailedAnalysisScreenState extends State<DetailedAnalysisScreen> {
  final SmsService _smsService = SmsService();
  List<SmsMessageModel> _allMessages = [];
  List<SmsMessageModel> _otpMessages = [];
  Map<String, List<SmsMessageModel>> _categorizedOtps = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final messages = await _smsService.getAllMessages();

      // Get only messages with OTP codes
      final otpMessages = _smsService.getOtpMessages(messages);

      // Categorize OTPs
      final categorized = _categorizeOtps(otpMessages);

      setState(() {
        _allMessages = messages;
        _otpMessages = otpMessages;
        _categorizedOtps = categorized;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load messages: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, List<SmsMessageModel>> _categorizeOtps(List<SmsMessageModel> messages) {
    final Map<String, List<SmsMessageModel>> result = {
      'sequential': [],
      'same_digits': [],
      'palindrome': [],
      'rising': [],
      'falling': [],
      'alternating': [],
      'other': [],
    };

    for (final msg in messages) {
      if (msg.otpCode == null) continue;

      final otp = msg.otpCode!;
      bool categorized = false;

      // Check for sequential digits (e.g., 123456)
      bool isSequential = true;
      for (int i = 0; i < otp.length - 1; i++) {
        if (int.parse(otp[i]) + 1 != int.parse(otp[i + 1])) {
          isSequential = false;
          break;
        }
      }
      if (isSequential) {
        result['sequential']!.add(msg);
        categorized = true;
      }

      // Check for all same digits (e.g., 555555)
      bool isAllSame = true;
      final firstDigit = otp[0];
      for (int i = 1; i < otp.length; i++) {
        if (otp[i] != firstDigit) {
          isAllSame = false;
          break;
        }
      }
      if (isAllSame) {
        result['same_digits']!.add(msg);
        categorized = true;
      }

      // Check for palindrome (same forwards and backwards)
      final reversed = otp.split('').reversed.join();
      if (otp == reversed) {
        result['palindrome']!.add(msg);
        categorized = true;
      }

      // Check for rising pattern
      bool isRising = true;
      for (int i = 0; i < otp.length - 1; i++) {
        if (int.parse(otp[i]) >= int.parse(otp[i + 1])) {
          isRising = false;
          break;
        }
      }
      if (isRising) {
        result['rising']!.add(msg);
        categorized = true;
      }

      // Check for falling pattern
      bool isFalling = true;
      for (int i = 0; i < otp.length - 1; i++) {
        if (int.parse(otp[i]) <= int.parse(otp[i + 1])) {
          isFalling = false;
          break;
        }
      }
      if (isFalling) {
        result['falling']!.add(msg);
        categorized = true;
      }

      // Check for alternating pattern
      bool isAlternating = true;
      for (int i = 0; i < otp.length - 2; i++) {
        if (otp[i] != otp[i + 2]) {
          isAlternating = false;
          break;
        }
      }
      if (isAlternating) {
        result['alternating']!.add(msg);
        categorized = true;
      }

      // If not categorized in any special pattern
      if (!categorized) {
        result['other']!.add(msg);
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detailed OTP Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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

    if (_otpMessages.isEmpty) {
      return const Center(
        child: Text('No OTP messages found'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analyzed ${_otpMessages.length} OTP messages out of ${_allMessages.length} total messages',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          // Display each pattern category
          _buildPatternCategory('Sequential Digits', _categorizedOtps['sequential']!, Icons.linear_scale, Colors.purple[100]),
          _buildPatternCategory('Same Digits', _categorizedOtps['same_digits']!, Icons.filter_9_plus, Colors.blue[100]),
          _buildPatternCategory('Palindromes', _categorizedOtps['palindrome']!, Icons.compare_arrows, Colors.green[100]),
          _buildPatternCategory('Rising Pattern', _categorizedOtps['rising']!, Icons.trending_up, Colors.orange[100]),
          _buildPatternCategory('Falling Pattern', _categorizedOtps['falling']!, Icons.trending_down, Colors.red[100]),
          _buildPatternCategory('Alternating Pattern', _categorizedOtps['alternating']!, Icons.swap_vert, Colors.teal[100]),
          _buildPatternCategory('Other OTPs', _categorizedOtps['other']!, Icons.tag, Colors.grey[100]),
        ],
      ),
    );
  }

  Widget _buildPatternCategory(String title, List<SmsMessageModel> messages, IconData icon, Color? color) {
    // Skip empty categories
    if (messages.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: color,
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon),
                    const SizedBox(width: 8),
                    Text(
                      '$title (${messages.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (title != 'Other OTPs')
                  Text(
                    _getPatternDescription(title),
                    style: const TextStyle(fontSize: 12),
                  ),
                const SizedBox(height: 16),
                ExpansionTile(
                  title: const Text('View OTPs'),
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return SmsMessageCard(message: messages[index]);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _getPatternDescription(String patternType) {
    switch (patternType) {
      case 'Sequential Digits':
        return 'OTPs with consecutive increasing numbers (e.g., 123456). These can be easier to guess.';
      case 'Same Digits':
        return 'OTPs with all identical digits (e.g., 555555). These are very predictable and insecure.';
      case 'Palindromes':
        return 'OTPs that read the same backward as forward (e.g., 123321). These have fewer possible combinations.';
      case 'Rising Pattern':
        return 'OTPs with strictly increasing digits (e.g., 135789). These show a predictable pattern.';
      case 'Falling Pattern':
        return 'OTPs with strictly decreasing digits (e.g., 987432). These show a predictable pattern.';
      case 'Alternating Pattern':
        return 'OTPs with alternating digits (e.g., 121212). These show a highly predictable pattern.';
      default:
        return '';
    }
  }
}