class OtpStats {
  final int totalCount;
  final double averageValue;
  final int minValue;
  final int maxValue;
  final String mostCommonDigit;
  final int mostCommonDigitCount;
  final String leastCommonDigit;
  final int leastCommonDigitCount;

  // New pattern analysis fields
  final Map<String, int> commonPrefixes; // Maps prefix to count
  final Map<String, int> commonSuffixes; // Maps suffix to count
  final Map<String, int> digitPairs; // Maps digit pairs to count
  final Map<int, int> positionBias; // Maps position to most common digit
  final double randomnessScore; // 0-10 score of randomness

  OtpStats({
    required this.totalCount,
    required this.averageValue,
    required this.minValue,
    required this.maxValue,
    required this.mostCommonDigit,
    required this.mostCommonDigitCount,
    required this.leastCommonDigit,
    required this.leastCommonDigitCount,
    required this.commonPrefixes,
    required this.commonSuffixes,
    required this.digitPairs,
    required this.positionBias,
    required this.randomnessScore,
  });

  factory OtpStats.empty() {
    return OtpStats(
      totalCount: 0,
      averageValue: 0,
      minValue: 0,
      maxValue: 0,
      mostCommonDigit: '',
      mostCommonDigitCount: 0,
      leastCommonDigit: '',
      leastCommonDigitCount: 0,
      commonPrefixes: {},
      commonSuffixes: {},
      digitPairs: {},
      positionBias: {},
      randomnessScore: 10.0,
    );
  }
}