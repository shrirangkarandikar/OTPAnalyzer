import 'otp_stats.dart';

class AnalysisStats {
  final int totalMessagesRead;
  final int otpMessagesCount;
  final int otpStringNoCodeCount;
  final int otherMessagesCount;
  final DateTime earliestMessageDate;
  final DateTime latestMessageDate;
  final String mostFrequentOtpSender;
  final int mostFrequentOtpSenderCount;
  final String mostFrequentOverallSender;
  final int mostFrequentOverallSenderCount;
  final OtpStats otpStats;

  AnalysisStats({
    required this.totalMessagesRead,
    required this.otpMessagesCount,
    required this.otpStringNoCodeCount,
    required this.otherMessagesCount,
    required this.earliestMessageDate,
    required this.latestMessageDate,
    required this.mostFrequentOtpSender,
    required this.mostFrequentOtpSenderCount,
    required this.mostFrequentOverallSender,
    required this.mostFrequentOverallSenderCount,
    required this.otpStats,
  });
}