import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/alarm_payload.dart';

/// Bridges between FCM/APNs and the platform-native loud-alert path.
///
/// Android: posts a notification on the alarm channel that uses
/// USAGE_ALARM audio attributes + bypassDnd. The channel itself is
/// created on app start with the most permissive settings — when the
/// user grants notification-policy access, the channel actually fires
/// past Do Not Disturb.
///
/// iOS: uses APNs Critical Alerts. The push payload from the backend
/// must include `aps.sound.critical = 1` and `aps.sound.volume`. This
/// bypasses silent-mode + every Focus mode + DND. **Requires the
/// `com.apple.developer.usernotifications.critical-alerts` entitlement
/// granted by Apple Developer Relations.** Until granted, iOS app is
/// not released to the App Store.
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
      requestCriticalPermission: true, // iOS Critical Alerts opt-in
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
      // Critical Alerts permission. Requires Apple-issued entitlement —
      // until granted, this returns false and iOS notifications fall
      // back to standard delivery (which silent-mode users will miss).
      // We do NOT ship iOS to the App Store before the entitlement is
      // approved.
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

    final iosDetails = const DarwinNotificationDetails(
      // Critical Alerts — bypasses silent + DND + every Focus mode.
      // Requires Apple-issued entitlement. Without entitlement this
      // flag is ignored and the notification behaves as standard.
      interruptionLevel: InterruptionLevel.critical,
      sound: 'siren.caf',
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    );

    final androidDetails = AndroidNotificationDetails(
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
    );

    await _plugin.show(
      payload.alertId.hashCode,
      payload.title,
      payload.text,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
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

    final iosDetails = const DarwinNotificationDetails(
      interruptionLevel: InterruptionLevel.critical,
      sound: 'siren.caf',
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    );
    final androidDetails = AndroidNotificationDetails(
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
    );
    await _plugin.show(
      p.alertId.hashCode,
      p.title,
      p.text,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
    debugPrint('local test notification posted');
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
