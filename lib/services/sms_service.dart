import 'package:telephony/telephony.dart';
import '../models/sms_message.dart';
import '../models/otp_stats.dart';

class SmsService {
  final Telephony _telephony = Telephony.instance;

  Future<List<SmsMessageModel>> getOtpMessages({int limit = 50}) async {
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

      // Take only the specified number of OTP messages (which are already sorted by date desc)
      final limitedOtpMessages = limit > 0 ? otpMessages.take(limit).toList() : otpMessages;

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

      // General pattern: Find any 6-digit code after "OTP" (case insensitive)
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

  OtpStats analyzeOtpCodes(List<SmsMessageModel> messages) {
    // Extract all valid OTP codes
    final otpCodes = messages
        .where((msg) => msg.otpCode != null)
        .map((msg) => msg.otpCode!)
        .toList();

    if (otpCodes.isEmpty) {
      return OtpStats.empty();
    }

    // Convert to integers for analysis
    final otpInts = otpCodes.map((otp) => int.parse(otp)).toList();

    // Find most common digit
    Map<String, int> digitFrequency = {};
    for (var otp in otpCodes) {
      for (var i = 0; i < otp.length; i++) {
        String digit = otp[i];
        digitFrequency[digit] = (digitFrequency[digit] ?? 0) + 1;
      }
    }

    // Sort by frequency to find most and least common digit
    var sortedDigits = digitFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate average value
    double average = otpInts.reduce((a, b) => a + b) / otpInts.length;

    // Find minimum and maximum values
    int min = otpInts.reduce((a, b) => a < b ? a : b);
    int max = otpInts.reduce((a, b) => a > b ? a : b);

    // Check if any OTPs are sequential digits (e.g., 123456)
    bool hasSequential = otpCodes.any((otp) {
      for (var i = 0; i < otp.length - 1; i++) {
        if (int.parse(otp[i]) + 1 != int.parse(otp[i + 1])) {
          return false;
        }
      }
      return true;
    });

    // Check if any OTPs have all same digits (e.g., 555555)
    bool hasAllSameDigits = otpCodes.any((otp) {
      final firstDigit = otp[0];
      return otp.split('').every((digit) => digit == firstDigit);
    });

    // Count how many OTPs are palindromes (same forwards and backwards)
    int palindromeCount = otpCodes.where((otp) {
      return otp == otp.split('').reversed.join();
    }).length;

    // Check for patterns (rising, falling, alternating)
    int risingPatterns = 0;
    int fallingPatterns = 0;
    int alternatingPatterns = 0;

    for (var otp in otpCodes) {
      bool isRising = true;
      bool isFalling = true;
      bool isAlternating = true;

      for (var i = 0; i < otp.length - 1; i++) {
        int current = int.parse(otp[i]);
        int next = int.parse(otp[i + 1]);

        if (current >= next) isRising = false;
        if (current <= next) isFalling = false;
        if (i < otp.length - 2) {
          int afterNext = int.parse(otp[i + 2]);
          if (current != afterNext) isAlternating = false;
        }
      }

      if (isRising) risingPatterns++;
      if (isFalling) fallingPatterns++;
      if (isAlternating) alternatingPatterns++;
    }

    // Build stats object
    return OtpStats(
      totalCount: otpCodes.length,
      averageValue: average,
      minValue: min,
      maxValue: max,
      mostCommonDigit: sortedDigits.first.key,
      mostCommonDigitCount: sortedDigits.first.value,
      leastCommonDigit: sortedDigits.last.key,
      leastCommonDigitCount: sortedDigits.last.value,
      hasSequentialOtp: hasSequential,
      hasAllSameDigitsOtp: hasAllSameDigits,
      palindromeCount: palindromeCount,
      risingPatternCount: risingPatterns,
      fallingPatternCount: fallingPatterns,
      alternatingPatternCount: alternatingPatterns,
    );
  }
}