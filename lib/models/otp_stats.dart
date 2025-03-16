class OtpStats {
  final int totalCount;
  final double averageValue;
  final int minValue;
  final int maxValue;
  final String mostCommonDigit;
  final int mostCommonDigitCount;
  final String leastCommonDigit;
  final int leastCommonDigitCount;
  final bool hasSequentialOtp;
  final bool hasAllSameDigitsOtp;
  final int palindromeCount;
  final int risingPatternCount;
  final int fallingPatternCount;
  final int alternatingPatternCount;

  OtpStats({
    required this.totalCount,
    required this.averageValue,
    required this.minValue,
    required this.maxValue,
    required this.mostCommonDigit,
    required this.mostCommonDigitCount,
    required this.leastCommonDigit,
    required this.leastCommonDigitCount,
    required this.hasSequentialOtp,
    required this.hasAllSameDigitsOtp,
    required this.palindromeCount,
    required this.risingPatternCount,
    required this.fallingPatternCount,
    required this.alternatingPatternCount,
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
      hasSequentialOtp: false,
      hasAllSameDigitsOtp: false,
      palindromeCount: 0,
      risingPatternCount: 0,
      fallingPatternCount: 0,
      alternatingPatternCount: 0,
    );
  }
}