import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'presentation/road_to_million/midas_screen.dart';

void main() async {
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

class MyMillionDollarApp extends StatelessWidget {
  const MyMillionDollarApp({super.key});

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
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F0F),
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      home: const MidasScreen(),
    );
  }
}
