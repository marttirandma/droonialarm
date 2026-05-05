import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Registers the device's push token + selected counties with the
/// alarm backend, and (re)subscribes the FCM topics that the backend
/// dispatches to.
class RegistrationService {
  RegistrationService._();
  static final instance = RegistrationService._();

  // TODO before release: replace with the production backend URL.
  static const _backendUrl = 'https://alarm.droonialarm.ee';

  Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final counties = prefs.getStringList('counties') ?? const ['national'];

    String? token;
    if (Platform.isIOS) {
      // iOS uses APNs directly via VoIP push — we still grab the FCM token
      // for analytics/symmetry.
      token = await FirebaseMessaging.instance.getAPNSToken();
    } else {
      token = await FirebaseMessaging.instance.getToken();
    }
    if (token == null || token.isEmpty) {
      debugPrint('[register] no push token yet — skipping');
      return;
    }

    if (Platform.isAndroid) {
      // Subscribe to per-county FCM topics that the backend pushes to.
      for (final c in counties) {
        await FirebaseMessaging.instance.subscribeToTopic('ehak_${c.toLowerCase()}');
      }
    }

    try {
      final res = await http.post(
        Uri.parse('$_backendUrl/v1/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'platform': Platform.isIOS ? 'ios' : 'android',
          'token': token,
          'counties': counties,
        }),
      );
      debugPrint('[register] status=${res.statusCode}');
    } catch (e) {
      debugPrint('[register] backend error: $e');
    }
  }
}
