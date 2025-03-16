import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/sms_message.dart';

class SmsMessageCard extends StatelessWidget {
  final SmsMessageModel message;

  const SmsMessageCard({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy - HH:mm');
    final formattedDate = dateFormat.format(message.date);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    message.address,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ),
                if (!message.isRead)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              message.body,
              style: const TextStyle(fontSize: 14.0),
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.grey[600],
                  ),
                ),
                if (message.otpCode != null)
                  _buildOtpChip(context, message.otpCode!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpChip(BuildContext context, String otpCode) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: otpCode));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Chip(
        backgroundColor: Colors.blue[100],
        label: Text(
          'OTP: $otpCode',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        avatar: const Icon(Icons.copy, size: 16),
      ),
    );
  }
}