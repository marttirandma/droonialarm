import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/alarm_screen.dart';
import 'screens/county_picker_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/alarm_service.dart';
import 'services/callkit_service.dart';
import 'services/notification_service.dart';
import 'services/registration_service.dart';

/// Background isolate handler for FCM. Must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.instance.init();
  await NotificationService.instance.showAlarmFromRemote(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  await NotificationService.instance.init();
  await CallKitService.instance.init();

  runApp(const DroonialarmApp());
}

class DroonialarmApp extends StatefulWidget {
  const DroonialarmApp({super.key});

  @override
  State<DroonialarmApp> createState() => _DroonialarmAppState();
}

class _DroonialarmAppState extends State<DroonialarmApp> {
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboardingDone') ?? false;
    setState(() => _onboardingDone = done);

    if (done) {
      await RegistrationService.instance.refresh();
    }

    FirebaseMessaging.onMessage.listen((msg) async {
      await NotificationService.instance.showAlarmFromRemote(msg);
      await AlarmService.instance.startSiren();
      if (mounted) {
        navigatorKey.currentState?.pushNamed(
          '/alarm',
          arguments: AlarmPayload.fromRemote(msg),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      navigatorKey.currentState?.pushNamed(
        '/alarm',
        arguments: AlarmPayload.fromRemote(msg),
      );
    });

    CallKitService.instance.onAccepted = (payload) async {
      await AlarmService.instance.startSiren();
      navigatorKey.currentState?.pushNamed(
        '/alarm',
        arguments: payload,
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone == null) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MaterialApp(
      title: 'Droonialarm',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: _onboardingDone! ? '/home' : '/onboarding',
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/counties': (_) => const CountyPickerScreen(),
        '/home': (_) => const HomeScreen(),
        '/alarm': (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments;
          return AlarmScreen(payload: args is AlarmPayload ? args : null);
        },
      },
    );
  }
}

final navigatorKey = GlobalKey<NavigatorState>();
