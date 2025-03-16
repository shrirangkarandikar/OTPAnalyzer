import 'package:intl/intl.dart';
import '../models/analysis_stats.dart';
import '../models/filter_options.dart';

class ComparisonResult {
  final AnalysisStats firstStats;
  final AnalysisStats secondStats;
  final FilterOptions firstFilter;
  final FilterOptions secondFilter;

  ComparisonResult({
    required this.firstStats,
    required this.secondStats,
    required this.firstFilter,
    required this.secondFilter,
  });

  // Calculate differences between key metrics
  double get entropyDifference => secondStats.otpStats.totalEntropy - firstStats.otpStats.totalEntropy;
  double get randomnessScoreDifference => secondStats.otpStats.randomnessScore - firstStats.otpStats.randomnessScore;
  int get otpCountDifference => secondStats.otpMessagesCount - firstStats.otpMessagesCount;

  // Get description of filters for display
  String getFilterDescription(FilterOptions filter) {
    switch (filter.type) {
      case FilterType.all:
        return 'All OTPs';
      case FilterType.bySender:
        return 'OTPs from ${filter.sender}';
      case FilterType.byDateRange:
        final DateFormat formatter = DateFormat('MMM d, yyyy');
        return 'OTPs from ${formatter.format(filter.startDate!)} to ${formatter.format(filter.endDate!)}';
      default:
        return 'Unknown Filter';
    }
  }

  // Helper for comparing digit frequency
  Map<String, int> getDigitFrequencyDifference() {
    final Map<String, int> result = {};

    // Assume 10 digits (0-9)
    for (int i = 0; i < 10; i++) {
      String digit = i.toString();
      int firstCount = 0;
      int secondCount = 0;

      // Count occurrences in first dataset
      if (digit == firstStats.otpStats.mostCommonDigit) {
        firstCount = firstStats.otpStats.mostCommonDigitCount;
      } else if (digit == firstStats.otpStats.leastCommonDigit) {
        firstCount = firstStats.otpStats.leastCommonDigitCount;
      }

      // Count occurrences in second dataset
      if (digit == secondStats.otpStats.mostCommonDigit) {
        secondCount = secondStats.otpStats.mostCommonDigitCount;
      } else if (digit == secondStats.otpStats.leastCommonDigit) {
        secondCount = secondStats.otpStats.leastCommonDigitCount;
      }

      // Store the difference
      result[digit] = secondCount - firstCount;
    }

    return result;
  }
}