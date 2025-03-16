import 'package:telephony/telephony.dart';
import '../models/sms_message.dart';

class SmsService {
  final Telephony _telephony = Telephony.instance;

  Future<List<SmsMessageModel>> getLastFiveOtpMessages() async {
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

      // Take only the first 5 OTP messages (which are already sorted by date desc)
      final limitedOtpMessages = otpMessages.take(20).toList();

      // Convert to our model
      return limitedOtpMessages.map((message) => SmsMessageModel(
        id: int.parse(message.id.toString()),
        address: message.address ?? 'Unknown',
        body: message.body ?? 'No content',
        date: DateTime.fromMillisecondsSinceEpoch(
          int.parse(message.date.toString()),
        ),
        isRead: message.read == 1,
      )).toList();
    } catch (e) {
      throw Exception('Failed to query SMS messages: $e');
    }
  }
}