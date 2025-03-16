import 'package:telephony/telephony.dart';
import '../models/sms_message.dart';

class SmsService {
  final Telephony _telephony = Telephony.instance;

  Future<List<SmsMessageModel>> getLastFiveOtpMessages() async {
    try {
      // Request permission using telephony package's built-in method
      bool? permissionsGranted = await _telephony.requestPhoneAndSmsPermissions;

      if (permissionsGranted != true) {
        throw Exception('SMS permissions not granted');
      }

      // Get all SMS inbox messages - we'll filter for OTP ourselves
      final messages = await _telephony.getInboxSms(
        columns: [
          SmsColumn.ID,
          SmsColumn.ADDRESS,
          SmsColumn.BODY,
          SmsColumn.DATE,
          SmsColumn.READ,
        ],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      // Filter messages containing "OTP" (case insensitive)
      final otpMessages = messages.where((message) =>
      message.body != null &&
          message.body!.toUpperCase().contains("OTP")
      ).toList();

      // Take only the first 5 OTP messages (which are already sorted by date desc)
      final limitedOtpMessages = otpMessages.take(5).toList();

      // Convert to our model and extract OTP code
      return limitedOtpMessages.map((message) {
        String? otpCode = extractOtpCode(message.body ?? '');

        return SmsMessageModel(
          id: int.parse(message.id.toString()),
          address: message.address ?? 'Unknown',
          body: message.body ?? 'No content',
          date: DateTime.fromMillisecondsSinceEpoch(
            int.parse(message.date.toString()),
          ),
          isRead: message.read == 1,
          otpCode: otpCode,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to query SMS messages: $e');
    }
  }

  String? extractOtpCode(String messageBody) {
    // Define regex patterns for the three formats plus a general 6-digit catch-all
    final List<RegExp> patterns = [
      // Pattern 1: Please use OTP-xxxxxx
      RegExp(r'OTP-(\d{6})'),

      // Pattern 2: The OTP for Reference No yyyyyyyyyy is xxxxxx
      RegExp(r'OTP for.*?Reference No.*?is (\d{6})'),

      // Pattern 3: Your OTP for redemption request... is xxxxxx
      RegExp(r'OTP for redemption request.*?is (\d{6})'),

      // General pattern: Find any 6-digit code after "OTP" or "otp" or "Otp"
      RegExp(r'OTP.*?(\d{6})', caseSensitive: false),

      // Last resort: Just find any 6 consecutive digits
      RegExp(r'\b(\d{6})\b'),
    ];

    // Try each pattern in sequence until we find a match
    for (var pattern in patterns) {
      final match = pattern.firstMatch(messageBody);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }

    return null; // No OTP found
  }
}