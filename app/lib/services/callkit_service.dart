import 'dart:io';

import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart' show Uuid;

import '../models/alarm_payload.dart';

/// CallKit-based DND bypass for iOS.
///
/// We present an "incoming call" with the system ringtone whenever an
/// EE-ALARM push arrives. CallKit rings even in silent mode and through
/// Focus / Do Not Disturb because the OS treats incoming calls as
/// always-deliverable. When the user accepts, [onAccepted] fires.
///
/// On Android, [flutter_callkit_incoming] also draws a full-screen
/// incoming-call UI — used as a UX fallback for the high-importance
/// alarm channel notification.
class CallKitService {
  CallKitService._();
  static final instance = CallKitService._();

  void Function(AlarmPayload payload)? onAccepted;

  Future<void> init() async {
    FlutterCallkitIncoming.onEvent.listen((event) {
      if (event == null) return;
      switch (event.event) {
        case Event.actionCallAccept:
          final payload = AlarmPayload.fromMap(
            (event.body['extra'] as Map?) ?? {},
          );
          onAccepted?.call(payload);
          break;
        case Event.actionCallDecline:
        case Event.actionCallEnded:
        case Event.actionCallTimeout:
          // User dismissed — keep notification banner but stop ringing.
          break;
        default:
          break;
      }
    });
  }

  Future<void> showIncomingCall(AlarmPayload payload) async {
    final params = CallKitParams(
      id: const Uuid().v4(),
      nameCaller: payload.title,
      handle: 'EE-ALARM',
      type: 1,
      textAccept: 'Vaata teadet',
      textDecline: 'Sulge',
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Lugemata EE-ALARM teavitus',
      ),
      extra: payload.toMap(),
      ios: IOSParams(
        iconName: 'CallKitIcon',
        handleType: 'generic',
        supportsVideo: false,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: false,
        supportsHolding: false,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0c0c0c',
        backgroundUrl: '',
        actionColorAccept: '#4CAF50',
        actionColorDecline: '#F44336',
        textColor: '#ffffff',
        incomingCallNotificationChannelName: 'EE-ALARM kõne',
        missedCallNotificationChannelName: 'EE-ALARM lugemata',
      ),
    );

    if (Platform.isIOS || Platform.isAndroid) {
      await FlutterCallkitIncoming.showCallkitIncoming(params);
    }
  }

  Future<void> endAll() => FlutterCallkitIncoming.endAllCalls();
}
