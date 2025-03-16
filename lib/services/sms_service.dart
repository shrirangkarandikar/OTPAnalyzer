import 'package:telephony/telephony.dart';
import '../models/sms_message.dart';
import '../models/analysis_stats.dart';
import '../models/otp_stats.dart';
import '../models/filter_options.dart';
import 'dart:math' as math;
import 'dart:developer' as developer;

class SmsService {
  final Telephony _telephony = Telephony.instance;
  List<SmsMessageModel> _allMessages = [];
  bool _messagesLoaded = false;

  // Get all messages from device
  Future<List<SmsMessageModel>> loadAllMessages() async {
    try {
      // Request permission using telephony package's built-in method
      bool? permissionsGranted = await _telephony.requestPhoneAndSmsPermissions;

      if (permissionsGranted != true) {
        throw Exception('SMS permissions not granted');
      }

      // Get all SMS inbox messages
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

      // Convert to our model and check for OTP content
      _allMessages = messages.map((message) {
        final messageBody = message.body ?? '';
        final hasOtpString = messageBody.toUpperCase().contains("OTP");
        final otpCode = hasOtpString ? extractOtpCode(messageBody) : null;

        return SmsMessageModel(
          id: int.parse(message.id.toString()),
          address: message.address ?? 'Unknown',
          body: messageBody,
          date: DateTime.fromMillisecondsSinceEpoch(
            int.parse(message.date.toString()),
          ),
          isRead: message.read == 1,
          otpCode: otpCode,
          hasOtpString: hasOtpString,
        );
      }).toList();

      _messagesLoaded = true;
      return _allMessages;
    } catch (e) {
      throw Exception('Failed to query SMS messages: $e');
    }
  }

  // Get messages based on filter options
  Future<List<SmsMessageModel>> getFilteredMessages(FilterOptions options) async {
    // Make sure messages are loaded
    if (!_messagesLoaded) {
      await loadAllMessages();
    }

    // Apply filters
    List<SmsMessageModel> filteredMessages;

    switch (options.type) {
      case FilterType.all:
        filteredMessages = List.from(_allMessages);
        break;
      case FilterType.bySender:
        filteredMessages = _allMessages
            .where((msg) => msg.address == options.sender)
            .toList();
        break;
      case FilterType.byDateRange:
        filteredMessages = _allMessages.where((msg) {
          return msg.date.isAfter(options.startDate!) &&
              msg.date.isBefore(options.endDate!.add(const Duration(days: 1)));
        }).toList();
        break;
      default:
        filteredMessages = List.from(_allMessages);
    }

    return filteredMessages;
  }

  // Get the top senders of OTP messages
  List<MapEntry<String, int>> getTopOtpSenders(int count) {
    // Get all messages with OTP codes
    final otpMessages = getOtpMessages(_allMessages);

    // Count by sender
    Map<String, int> senderCounts = {};
    for (var msg in otpMessages) {
      senderCounts[msg.address] = (senderCounts[msg.address] ?? 0) + 1;
    }

    // Sort and take top count
    var sorted = senderCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(math.min(count, sorted.length)).toList();
  }

  String? extractOtpCode(String messageBody) {
    // Define regex patterns for the three formats plus a general 6-digit catch-all
    final List<RegExp> patterns = [
      // Pattern 1: Please use OTP-xxxxxx
      RegExp(r'OTP-(\d{6})(?!\d)'),

      // Pattern 2: The OTP for Reference No yyyyyyyyyy is xxxxxx
      RegExp(r'OTP for.*?Reference No.*?is (\d{6})(?!\d)'),

      // Pattern 3: Your OTP for redemption request... is xxxxxx
      RegExp(r'OTP for redemption request.*?is (\d{6})(?!\d)'),

      // General pattern: Find any 6-digit code after "OTP" (case insensitive)
      RegExp(r'OTP.*?(?<!\d)(\d{6})(?!\d)', caseSensitive: false),

      // Last resort: Just find any isolated 6 consecutive digits
      // This will match a 6-digit number that is not part of a longer number
      RegExp(r'(?<!\d)(\d{6})(?!\d)'),
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

  AnalysisStats analyzeMessages(List<SmsMessageModel> messages) {
    if (messages.isEmpty) {
      return AnalysisStats(
        totalMessagesRead: 0,
        otpMessagesCount: 0,
        otpStringNoCodeCount: 0,
        otherMessagesCount: 0,
        earliestMessageDate: DateTime.now(),
        latestMessageDate: DateTime.now(),
        mostFrequentOtpSender: '',
        mostFrequentOtpSenderCount: 0,
        mostFrequentOverallSender: '',
        mostFrequentOverallSenderCount: 0,
        otpStats: OtpStats.empty(),
      );
    }

    // Categorize messages
    final otpMessages = getOtpMessages(messages);
    final otpStringNoCodeMessages = getOtpStringNoCodeMessages(messages);
    final otherMessages = getOtherMessages(messages);

    // Find date range
    DateTime earliestDate = messages.map((m) => m.date).reduce((a, b) => a.isBefore(b) ? a : b);
    DateTime latestDate = messages.map((m) => m.date).reduce((a, b) => a.isAfter(b) ? a : b);

    // Find most frequent senders
    Map<String, int> otpSenderCounts = {};
    for (var msg in otpMessages) {
      otpSenderCounts[msg.address] = (otpSenderCounts[msg.address] ?? 0) + 1;
    }

    Map<String, int> overallSenderCounts = {};
    for (var msg in messages) {
      overallSenderCounts[msg.address] = (overallSenderCounts[msg.address] ?? 0) + 1;
    }

    String mostFrequentOtpSender = '';
    int mostFrequentOtpSenderCount = 0;

    if (otpSenderCounts.isNotEmpty) {
      var sorted = otpSenderCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      mostFrequentOtpSender = sorted.first.key;
      mostFrequentOtpSenderCount = sorted.first.value;
    }

    String mostFrequentOverallSender = '';
    int mostFrequentOverallSenderCount = 0;

    if (overallSenderCounts.isNotEmpty) {
      var sorted = overallSenderCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      mostFrequentOverallSender = sorted.first.key;
      mostFrequentOverallSenderCount = sorted.first.value;
    }

    // Analyze OTP codes
    final otpStats = analyzeOtpCodes(otpMessages);

    return AnalysisStats(
      totalMessagesRead: messages.length,
      otpMessagesCount: otpMessages.length,
      otpStringNoCodeCount: otpStringNoCodeMessages.length,
      otherMessagesCount: otherMessages.length,
      earliestMessageDate: earliestDate,
      latestMessageDate: latestDate,
      mostFrequentOtpSender: mostFrequentOtpSender,
      mostFrequentOtpSenderCount: mostFrequentOtpSenderCount,
      mostFrequentOverallSender: mostFrequentOverallSender,
      mostFrequentOverallSenderCount: mostFrequentOverallSenderCount,
      otpStats: otpStats,
    );
  }

  // Helper function to calculate Shannon entropy for a frequency map
  double calculateEntropy(Map<String, int> frequencyMap) {
    if (frequencyMap.isEmpty) return 0.0;

    int totalCount = frequencyMap.values.reduce((a, b) => a + b);
    double entropy = 0.0;

    for (var count in frequencyMap.values) {
      double probability = count / totalCount;
      entropy -= probability * (math.log(probability) / math.ln2);
    }

    return entropy;
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

    // Rest of the analyzeOtpCodes function remains the same...
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

    // Calculate entropy metrics
    double digitEntropy = calculateEntropy(digitFrequency);

    // Calculate position entropy
    List<double> positionEntropy = [];
    for (int position = 0; position < 6; position++) {
      if (positionDigitFrequency[position]!.isNotEmpty) {
        positionEntropy.add(calculateEntropy(positionDigitFrequency[position]!));
      } else {
        positionEntropy.add(0.0);
      }
    }

    // Add padding to ensure we have 6 values
    while (positionEntropy.length < 6) {
      positionEntropy.add(0.0);
    }

    // Calculate total entropy (average of all positions)
    double totalEntropy = positionEntropy.reduce((a, b) => a + b) / 6;

    // Maximum possible entropy (log2(10) for 10 possible digits)
    double maxPossibleEntropy = 3.32;

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
      digitEntropy: digitEntropy,
      positionEntropy: positionEntropy,
      totalEntropy: totalEntropy,
      maxPossibleEntropy: maxPossibleEntropy,
    );
  }

  // Get categorized messages
  List<SmsMessageModel> getOtpMessages(List<SmsMessageModel> allMessages) {
    return allMessages.where((msg) => msg.otpCode != null).toList();
  }

  List<SmsMessageModel> getOtpStringNoCodeMessages(List<SmsMessageModel> allMessages) {
    return allMessages.where((msg) => msg.hasOtpString && msg.otpCode == null).toList();
  }

  List<SmsMessageModel> getOtherMessages(List<SmsMessageModel> allMessages) {
    return allMessages.where((msg) => !msg.hasOtpString).toList();
  }
}