class SmsMessageModel {
  final int id;
  final String address;
  final String body;
  final DateTime date;
  final bool isRead;
  final String? otpCode; // Added OTP code field

  SmsMessageModel({
    required this.id,
    required this.address,
    required this.body,
    required this.date,
    required this.isRead,
    this.otpCode,
  });
}