// lib/services/twilio_service.dart

import 'package:twilio_flutter/twilio_flutter.dart';
import 'package:flutter/material.dart';

class TwilioService {
  final TwilioFlutter _twilioFlutter;
  final String _myTwilioNumber;

  TwilioService()
    : _myTwilioNumber = 'YOUR_TWILIO_PHONE_NUMBER',
      _twilioFlutter = TwilioFlutter(
        accountSid: 'YOUR_ACCOUNT_SID',
        authToken: 'YOUR_AUTH_TOKEN',
        twilioNumber: 'YOUR_TWILIO_PHONE_NUMBER',
      );

  /// Sends a WhatsApp message to a specified recipient using the sendSMS method.
  Future<void> sendWhatsAppMessage(
    String recipientNumber,
    String messageBody,
  ) async {
    // The Twilio number and recipient number must be prefixed with 'whatsapp:'
    final String twilioWhatsAppNumber = 'whatsapp:$_myTwilioNumber';
    final String toWhatsAppNumber = 'whatsapp:$recipientNumber';

    try {
      final TwilioResponse response = await _twilioFlutter.sendSMS(
        toNumber: toWhatsAppNumber,
        messageBody: messageBody,
        // from: twilioWhatsAppNumber,
      );

      if (response.responseState == ResponseState.SUCCESS) {
        debugPrint('WhatsApp message sent successfully to $recipientNumber!');
      } else {
        debugPrint('Failed to send WhatsApp message: ${response.errorData}');
      }
    } catch (e) {
      debugPrint('Exception while sending WhatsApp message: $e');
    }
  }
}
