import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'package:million_dollar_way/presentation/ui/screens/golden_home_screen_new_user.dart';

class AppSplashScreen extends ConsumerStatefulWidget {
  const AppSplashScreen({super.key});

  @override
  ConsumerState<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends ConsumerState<AppSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    // Анімація логотипу
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    // Анімація тексту
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    // Запускаємо анімації
    _startAnimations();

    // Таймер для переходу через 2 секунди
    Timer(const Duration(seconds: 2), () {
      _navigateToHome();
    });
  }

  void _startAnimations() async {
    // Спочатку показуємо логотип
    _logoController.forward();

    // Потім текст через 300мс
    await Future.delayed(const Duration(milliseconds: 300));
    _textController.forward();
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const GoldenHomeScreenNewUser(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Золотий логотип
              AnimatedBuilder(
                animation: _logoAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEAB308), Color(0xFFD4AF37)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEAB308).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.monetization_on,
                        size: 60,
                        color: Colors.black,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Текст "Million Dollar Way"
              AnimatedBuilder(
                animation: _textAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _textAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_textAnimation),
                      child: Column(
                        children: [
                          const Text(
                            'Million Dollar Way',
                            style: TextStyle(
                              color: Color(0xFFEAB308),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ваш шлях до фінансової свободи',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 64),

              // Індикатор завантаження
              AnimatedBuilder(
                animation: _logoAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _logoAnimation,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFFEAB308).withOpacity(0.6),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Painter для малювання золотого 'M'
class GoldenMPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEAB308)
      ..style = PaintingStyle.fill
      ..strokeWidth = 3.0;

    final path = Path();

    // Малюємо стилізовану букву 'M'
    final width = size.width;
    final height = size.height;

    // Ліва нога 'M'
    path.moveTo(width * 0.2, height * 0.8);
    path.lineTo(width * 0.2, height * 0.2);

    // Верхній пік 'M'
    path.lineTo(width * 0.35, height * 0.5);
    path.lineTo(width * 0.5, height * 0.2);

    // Правий пік 'M'
    path.lineTo(width * 0.65, height * 0.5);
    path.lineTo(width * 0.8, height * 0.2);

    // Права нога 'M'
    path.lineTo(width * 0.8, height * 0.8);

    // Закриваємо фігуру
    path.lineTo(width * 0.6, height * 0.8);
    path.lineTo(width * 0.5, height * 0.6);
    path.lineTo(width * 0.4, height * 0.8);
    path.close();

    canvas.drawPath(path, paint);

    // Додаємо світіння
    final glowPaint = Paint()
      ..color = const Color(0xFFEAB308).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);

    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
