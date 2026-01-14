import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// Переконайся, що шлях правильний.
// Якщо файли просто в папці lib, видали 'presentation/road_to_million/'
import 'presentation/road_to_million/midas_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Ініціалізуємо Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization error: $e');
    // Продовжуємо роботу навіть якщо Firebase не ініціалізовано
  }
  
  // Гарантуємо, що системний рядок (годинник, батарея) буде прозорим/темним
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // Білі іконки (годинник)
      systemNavigationBarColor: Color(0xFF0F0F0F), // Колір смужки знизу
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyMillionDollarApp());
}

class MyMillionDollarApp extends StatelessWidget {
  const MyMillionDollarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Прибираємо стрічку "Debug"
      title: 'Million Dollar Way',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        primaryColor: const Color(0xFFD4AF37),
        fontFamily: 'Roboto', // Або системний шрифт iOS
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F0F),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      // Одразу запускаємо наш головний екран
      home: const MidasScreen(),
    );
  }
}
