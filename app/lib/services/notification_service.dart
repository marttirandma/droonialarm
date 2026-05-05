import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/alarm_payload.dart';
import 'callkit_service.dart';

/// Bridges between FCM/APNs and the platform-native loud-alert path.
///
/// Android: posts a notification on the alarm channel that uses
/// USAGE_ALARM audio attributes + bypassDnd. The channel itself is
/// created on app start with the most permissive settings — when the
/// user grants notification-policy access, the channel actually fires
/// past Do Not Disturb.
///
/// iOS: routes to CallKit so a "phone call" rings the device with the
/// system ringtone — passes silent mode + Focus modes by design.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  static const _alarmChannelId = 'alarm_channel';
  static const _alarmChannelName = 'EE-ALARM (möirgav)';
  static const _alarmChannelDesc =
      'Hädaolukorra teavitused — möirgab läbi DND ja vaikse režiimi.';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
    );
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));

    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        _alarmChannelId,
        _alarmChannelName,
        description: _alarmChannelDesc,
        importance: Importance.max,
        enableVibration: true,
        // siren.mp3 must live at android/app/src/main/res/raw/siren.mp3
        sound: RawResourceAndroidNotificationSound('siren'),
        playSound: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ));
    }

    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
      );
    }

    _ready = true;
  }

  Future<void> showAlarmFromRemote(RemoteMessage message) async {
    final payload = AlarmPayload.fromRemote(message);

    if (Platform.isIOS) {
      // iOS DND-bypass goes via CallKit, NOT a banner notification.
      // The data-only push triggers the CallKit incoming-call UI.
      await CallKitService.instance.showIncomingCall(payload);
      return;
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _alarmChannelId,
        _alarmChannelName,
        channelDescription: _alarmChannelDesc,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('siren'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: true,
        ongoing: true,
        autoCancel: false,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(payload.text),
      ),
    );

    await _plugin.show(
      payload.alertId.hashCode,
      payload.title,
      payload.text,
      details,
      payload: payload.toMap().toString(),
    );
  }

  /// Show a local test alarm (used by Settings → "Test alarm").
  Future<void> showTestAlarm() async {
    final p = AlarmPayload(
      eventId: '0',
      alertId: 'test-${DateTime.now().millisecondsSinceEpoch}',
      state: 'OPEN',
      title: 'TEST EE-ALARM',
      text: 'Droonialarm — testpush. See on harjutus, ärge muretsege.',
      startDate: DateTime.now().toUtc().toIso8601String(),
      endDate: '',
    );
    if (Platform.isIOS) {
      await CallKitService.instance.showIncomingCall(p);
      return;
    }
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _alarmChannelId,
        _alarmChannelName,
        channelDescription: _alarmChannelDesc,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('siren'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: true,
      ),
    );
    await _plugin.show(p.alertId.hashCode, p.title, p.text, details);
    debugPrint('local test notification posted');
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
