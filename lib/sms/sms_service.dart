import 'package:http/http.dart' as http;

class SMSService {





  static Future<void> sendSMS({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      String formattedNumber = formatPhoneNumber(phoneNumber);
      if (formattedNumber.isEmpty) {
        throw Exception('Invalid phone number: $phoneNumber');
      }

      final Uri uri = Uri.parse(
        'your_sms_api_url?api_key=your_api_key&type=text&contacts=$formattedNumber&senderid=your_sender_id&msg=${Uri.encodeComponent(message)}',
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        print('Full Response: ${response.body}');
        if (response.body.contains('1003')) {
          print('SMS sent successfully.');
        } else {
          print('Unexpected response: ${response.body}');
        }
      } else {
        throw Exception(
            'Failed to send SMS. Status Code: ${response.statusCode}, Response: ${response.body}');
      }
    } catch (e) {
      print('Error while sending SMS: $e');
      rethrow;
    }
  }

  static Future<void> sendBulkSMS({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    try {
      final List<String> formattedNumbers = phoneNumbers
          .map((number) => formatPhoneNumber(number))
          .where((formattedNumber) => formattedNumber.isNotEmpty)
          .toList();

      if (formattedNumbers.isEmpty) {
        throw Exception('No valid phone numbers found.');
      }

      final String joinedNumbers = formattedNumbers.join(',');

      final Uri uri = Uri.parse(
        'your_sms_api_url?api_key=your_api_key&type=text&contacts=$joinedNumbers&senderid=your_sender_id&msg=${Uri.encodeComponent(message)}',
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        print('Bulk SMS sent successfully: ${response.body}');
      } else {
        throw Exception(
            'Failed to send Bulk SMS. Status Code: ${response.statusCode}, Response: ${response.body}');
      }
    } catch (e) {
      print('Error while sending Bulk SMS: $e');
      rethrow;
    }
  }

  static String formatPhoneNumber(String phoneNumber) {
    phoneNumber = phoneNumber.replaceAll(RegExp(r'\D'), ''); 

    if (phoneNumber.length == 11 && phoneNumber.startsWith('0')) {
      return '880${phoneNumber.substring(1)}';
    }

    if (phoneNumber.length == 13 && phoneNumber.startsWith('880')) {
      return phoneNumber;
    }

    return '';
  }
}
