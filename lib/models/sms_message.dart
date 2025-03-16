class SmsMessageModel {
  final int id;
  final String address;
  final String body;
  final DateTime date;
  final bool isRead;
  final String? otpCode; // OTP code if found
  final bool hasOtpString; // Contains "OTP" string but may not have valid code

  SmsMessageModel({
    required this.id,
    required this.address,
    required this.body,
    required this.date,
    required this.isRead,
    this.otpCode,
    this.hasOtpString = false,
  });
}