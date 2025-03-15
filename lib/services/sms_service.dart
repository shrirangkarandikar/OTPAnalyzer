import 'package:telephony/telephony.dart';
import '../models/sms_message.dart';

class SmsService {
  final Telephony _telephony = Telephony.instance;

  Future<List<SmsMessageModel>> getLastFiveMessages() async {
    try {
      // Get SMS inbox messages
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

      // Take only the first 5 messages
      final limitedMessages = messages.take(5).toList();

      // Convert to our model
      return limitedMessages.map((message) => SmsMessageModel(
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