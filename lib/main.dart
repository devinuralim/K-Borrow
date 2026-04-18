import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import Screen
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/riwayat_peminjaman_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  importance: Importance.max,
  playSound: true,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 1. Setup Channel untuk Android
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 2. Inisialisasi Local Notifications (PENTING!)
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    // 3. Minta izin notifikasi (Khusus Android 13+)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

  } catch (e) {
    debugPrint('Firebase Error: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  bool savedDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(MyApp(savedDarkMode: savedDarkMode));
}

class MyApp extends StatefulWidget {
  final bool savedDarkMode;
  const MyApp({super.key, required this.savedDarkMode});

  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.light);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    MyApp.themeNotifier.value =
        widget.savedDarkMode ? ThemeMode.dark : ThemeMode.light;

    // Jalankan listener notifikasi
    _setupNotificationListeners();
    setupInteractedMessage();
  }

  // 🔥 FUNGSI BARU: Agar notifikasi muncul saat aplikasi TERBUKA (Foreground)
  void _setupNotificationListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
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
      }
    });
  }

  Future<void> setupInteractedMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _handleMessage(initialMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    if (message.data['screen'] == 'HOME_SCREEN' ||
        message.data['screen'] == 'notification_center') {
      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, currentMode, _) {
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
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1d3557)),
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