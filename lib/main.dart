import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/riwayat_peminjaman_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Channel untuk notifikasi penting',
  importance: Importance.max,
  playSound: true,
);

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await saveFcmNotification(message);
}

Future<void> saveFcmNotification(RemoteMessage message) async {
  final prefs = await SharedPreferences.getInstance();
  final oldData = prefs.getStringList('fcm_notifications') ?? [];

  final String title =
      message.notification?.title ?? message.data['title'] ?? 'Notifikasi';

  final String body =
      message.notification?.body ??
      message.data['body'] ??
      message.data['message'] ??
      '';

  final notif = {
    'id': DateTime.now().millisecondsSinceEpoch.toString(),
    'title': title,
    'body': body,
    'screen': message.data['screen'] ?? '',
    'created_at': DateTime.now().toIso8601String(),
  };

  oldData.insert(0, jsonEncode(notif));

  if (oldData.length > 50) {
    oldData.removeRange(50, oldData.length);
  }

  await prefs.setStringList('fcm_notifications', oldData);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (e) {
    debugPrint('Firebase Error: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final bool savedDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(MyApp(savedDarkMode: savedDarkMode));
}

class MyApp extends StatefulWidget {
  final bool savedDarkMode;

  const MyApp({super.key, required this.savedDarkMode});

  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  State<MyApp> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void initState() {
    super.initState();

    MyApp.themeNotifier.value = widget.savedDarkMode
        ? ThemeMode.dark
        : ThemeMode.light;

    setupNotificationListeners();
    setupInteractedMessage();
  }

  void setupNotificationListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await saveFcmNotification(message);

      final RemoteNotification? notification = message.notification;

      final String title =
          notification?.title ?? message.data['title'] ?? 'Notifikasi';

      final String body =
          notification?.body ??
          message.data['body'] ??
          message.data['message'] ??
          '';

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        ),
      );
    });
  }

  Future<void> setupInteractedMessage() async {
    final RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();

    if (initialMessage != null) {
      await saveFcmNotification(initialMessage);
      handleMessage(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await saveFcmNotification(message);
      handleMessage(message);
    });
  }

  void handleMessage(RemoteMessage message) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/home',
      (route) => false,
    );
  }

  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'K2NET Inventory',
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            useMaterial3: true,
            primaryColor: const Color(0xFF1d3557),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1d3557),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1d3557),
              brightness: Brightness.dark,
            ),
          ),
          routes: {
            '/home': (context) => const HomeScreen(),
            '/riwayat_peminjaman': (context) => const RiwayatPeminjamanScreen(),
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
