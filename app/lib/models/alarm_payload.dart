import 'package:firebase_messaging/firebase_messaging.dart';

class AlarmPayload {
  final String eventId;
  final String alertId;
  final String state;
  final String title;
  final String text;
  final String startDate;
  final String endDate;

  const AlarmPayload({
    required this.eventId,
    required this.alertId,
    required this.state,
    required this.title,
    required this.text,
    required this.startDate,
    required this.endDate,
  });

  factory AlarmPayload.fromRemote(RemoteMessage m) {
    final d = m.data;
    return AlarmPayload(
      eventId: d['event_id']?.toString() ?? '',
      alertId: d['alert_id']?.toString() ?? '',
      state: d['state']?.toString() ?? 'OPEN',
      title: d['title']?.toString() ?? m.notification?.title ?? 'EE-ALARM',
      text: d['text']?.toString() ?? m.notification?.body ?? '',
      startDate: d['start_date']?.toString() ?? '',
      endDate: d['end_date']?.toString() ?? '',
    );
  }

  factory AlarmPayload.fromMap(Map<dynamic, dynamic> m) {
    return AlarmPayload(
      eventId: m['event_id']?.toString() ?? '',
      alertId: m['alert_id']?.toString() ?? '',
      state: m['state']?.toString() ?? 'OPEN',
      title: m['title']?.toString() ?? 'EE-ALARM',
      text: m['text']?.toString() ?? '',
      startDate: m['start_date']?.toString() ?? '',
      endDate: m['end_date']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'event_id': eventId,
        'alert_id': alertId,
        'state': state,
        'title': title,
        'text': text,
        'start_date': startDate,
        'end_date': endDate,
      };
}
