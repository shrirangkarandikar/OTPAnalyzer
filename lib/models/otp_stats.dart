class OtpStats {
  final int totalCount;
  final double averageValue;
  final int minValue;
  final int maxValue;
  final String mostCommonDigit;
  final int mostCommonDigitCount;
  final String leastCommonDigit;
  final int leastCommonDigitCount;

  // Pattern analysis fields
  final Map<String, int> commonPrefixes; // Maps prefix to count
  final Map<String, int> commonSuffixes; // Maps suffix to count
  final Map<String, int> digitPairs; // Maps digit pairs to count
  final Map<int, int> positionBias; // Maps position to most common digit
  final double randomnessScore; // 0-10 score of randomness

  // Entropy metrics
  final double digitEntropy; // Shannon entropy for all digits
  final List<double> positionEntropy; // Entropy at each position
  final double totalEntropy; // Overall entropy score
  final double maxPossibleEntropy; // Maximum theoretical entropy

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
    required this.digitEntropy,
    required this.positionEntropy,
    required this.totalEntropy,
    required this.maxPossibleEntropy,
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
      digitEntropy: 0.0,
      positionEntropy: List.filled(6, 0.0),
      totalEntropy: 0.0,
      maxPossibleEntropy: 3.32, // log2(10) for 10 possible digits
    );
  }
}