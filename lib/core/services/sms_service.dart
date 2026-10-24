import 'package:flutter/services.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/sms_parser.dart';

/// Service responsible for hardware-level SMS queries and safe parsing.
/// Respects user privacy: only queries when authorized, handles missing telephony cursors,
/// and returns clean parsed candidates without persisting raw SMS bodies.
class SmsService {
  final SmsQuery _query = SmsQuery();

  /// Checks the current SMS permission status.
  Future<PermissionStatus> getPermissionStatus() async {
    return await Permission.sms.status;
  }

  /// Requests runtime SMS permissions from the user.
  Future<PermissionStatus> requestPermission() async {
    return await Permission.sms.request();
  }

  /// Queries the SMS inbox, filters bank transactions, and returns parsed transaction items.
  /// Throws user-facing exceptions when permissions are unavailable or hardware is incompatible.
  Future<List<ParsedSmsTransaction>> readAndParseSms() async {
    const int count = 200;
    final status = await getPermissionStatus();
    if (!status.isGranted && !status.isLimited) {
      throw Exception(
        'SMS access is unavailable. Enable SMS permission in Android Settings, then tap Scan again.',
      );
    }

    final List<SmsMessage> messages;
    try {
      messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: count,
        sort: true,
      );
    } on PlatformException catch (e) {
      // Handles empty cursors on devices without SIM or where the system inbox is empty
      if (e.code == 'invalid_response' ||
          e.code == 'no_cursor' ||
          e.message?.contains('cursor') == true) {
        return [];
      }
      if (e.code == 'permission_denied' ||
          e.message?.contains('permission') == true) {
        throw Exception(
          'SMS permission was denied by Android. Grant SMS access in App Settings and retry.',
        );
      }
      throw Exception('SMS reading error: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Failed to read messages from device: $e');
    }

    final List<ParsedSmsTransaction> transactions = [];
    for (final message in messages) {
      final String? sender = message.address;
      final String? body = message.body;
      final DateTime? date = message.date;

      if (sender == null || body == null || body.trim().isEmpty) {
        continue;
      }

      // Parse individual message
      final parsed = SmsParser.parseSms(
        sender: sender,
        body: body,
        date: date ?? DateTime.now(),
      );

      if (parsed != null) {
        transactions.add(parsed);
      }
    }

    // Sort transactions by date descending (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }
}
