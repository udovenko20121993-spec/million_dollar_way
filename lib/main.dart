import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'presentation/road_to_million/midas_screen.dart';
import 'services/notification_service.dart';

void main() async {
  // Обов'язково для асинхронного коду перед runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Ініціалізація Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Налаштування системного UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F0F0F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyMillionDollarApp());
}

class MyMillionDollarApp extends StatefulWidget {
  const MyMillionDollarApp({super.key});

  @override
  State<MyMillionDollarApp> createState() => _MyMillionDollarAppState();
}

class _MyMillionDollarAppState extends State<MyMillionDollarApp> {
  final String userId = "user_test_1";

  @override
  void initState() {
    super.initState();
    // Ініціалізація сповіщень
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      final notificationService = NotificationService();
      await notificationService.init(userId);
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Million Dollar Way',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        primaryColor: const Color(0xFFD4AF37),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          secondary: Color(0xFF00C853),
          surface: Color(0xFF1A1A1A),
          background: Color(0xFF0F0F0F),
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F0F),
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const MidasScreen(),
    );
  }
}
