import 'package:telephony/telephony.dart';
import '../models/sms_message.dart';
import '../models/otp_stats.dart';
import 'dart:math' as math;

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

    // Analyze prefixes (first 2 digits)
    Map<String, int> prefixFrequency = {};
    for (var otp in otpCodes) {
      if (otp.length >= 2) {
        String prefix = otp.substring(0, 2);
        prefixFrequency[prefix] = (prefixFrequency[prefix] ?? 0) + 1;
      }
    }

    // Analyze suffixes (last 2 digits)
    Map<String, int> suffixFrequency = {};
    for (var otp in otpCodes) {
      if (otp.length >= 2) {
        String suffix = otp.substring(otp.length - 2);
        suffixFrequency[suffix] = (suffixFrequency[suffix] ?? 0) + 1;
      }
    }

    // Analyze digit pairs
    Map<String, int> digitPairFrequency = {};
    for (var otp in otpCodes) {
      for (var i = 0; i < otp.length - 1; i++) {
        String pair = otp.substring(i, i + 2);
        digitPairFrequency[pair] = (digitPairFrequency[pair] ?? 0) + 1;
      }
    }

    // Analyze position bias
    Map<int, Map<String, int>> positionDigitFrequency = {};
    for (int position = 0; position < 6; position++) {
      positionDigitFrequency[position] = {};
    }

    for (var otp in otpCodes) {
      for (var i = 0; i < math.min(otp.length, 6); i++) {
        String digit = otp[i];
        positionDigitFrequency[i]![digit] = (positionDigitFrequency[i]![digit] ?? 0) + 1;
      }
    }

    // Find most common digit at each position
    Map<int, int> positionBias = {};
    for (int position = 0; position < 6; position++) {
      if (positionDigitFrequency[position]!.isNotEmpty) {
        var mostCommon = positionDigitFrequency[position]!.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        if (mostCommon.isNotEmpty) {
          positionBias[position] = int.parse(mostCommon.first.key);
        }
      }
    }

    // Calculate randomness score (0-10)
    double randomnessScore = 10.0;

    // Reduce score based on prefix/suffix frequency
    if (prefixFrequency.isNotEmpty) {
      var mostCommonPrefix = prefixFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      double prefixRatio = mostCommonPrefix.first.value / otpCodes.length;
      if (prefixRatio > 0.2) { // More than 20% have same prefix
        randomnessScore -= (prefixRatio - 0.2) * 10;
      }
    }

    // Check position bias
    int totalPositions = 6;
    double expectedFrequency = 0.1; // With 10 possible digits (0-9)
    double biasScore = 0;

    for (int position = 0; position < 6; position++) {
      if (positionDigitFrequency[position]!.isNotEmpty) {
        var digitCounts = positionDigitFrequency[position]!.values.toList();
        int totalDigits = digitCounts.reduce((a, b) => a + b);

        // Calculate chi-square-like statistic for position
        double positionBiasScore = 0;
        for (var count in digitCounts) {
          double frequency = count / totalDigits;
          double deviation = frequency - expectedFrequency;
          positionBiasScore += (deviation * deviation);
        }

        biasScore += positionBiasScore;
      }
    }

    // Reduce score based on average position bias
    randomnessScore -= math.min(3.0, biasScore * 5);

    // Ensure score is between 0 and 10
    randomnessScore = math.max(0, math.min(10, randomnessScore));

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
      commonPrefixes: prefixFrequency,
      commonSuffixes: suffixFrequency,
      digitPairs: digitPairFrequency,
      positionBias: positionBias,
      randomnessScore: randomnessScore,
    );
  }
}