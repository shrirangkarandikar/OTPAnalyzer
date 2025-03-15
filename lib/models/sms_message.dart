class SmsMessageModel {
  final int id;
  final String address;
  final String body;
  final DateTime date;
  final bool isRead;

  SmsMessageModel({
    required this.id,
    required this.address,
    required this.body,
    required this.date,
    required this.isRead,
  });
}
