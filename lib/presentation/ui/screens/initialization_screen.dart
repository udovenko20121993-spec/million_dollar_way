import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/market_data_service.dart';
import '../../../screens/home_screen.dart';

/// Екран ініціалізації з тихим завантаженням даних
class InitializationScreen extends ConsumerStatefulWidget {
  const InitializationScreen({super.key});

  @override
  ConsumerState<InitializationScreen> createState() =>
      _InitializationScreenState();
}

class _InitializationScreenState extends ConsumerState<InitializationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Анімація fade-in
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Анімація пульсації для логотипа
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Починаємо анімації та завантаження даних
    _startInitialization();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startInitialization() async {
    // Починаємо анімації
    _fadeController.forward();
    _pulseController.repeat(reverse: true);

    try {
      // Ініціалізуємо Firebase та завантажуємо ціни
      await MarketDataService.instance.init();

      // Чекаємо мінімум 2 секунди для анімації
      await Future.delayed(const Duration(milliseconds: 2000));

      // Переходимо до головного екрану
      if (mounted) {
        _navigateToHome();
      }
    } catch (e) {
      print('Initialization error: $e');
      // Навіть при помилці переходимо до головного екрану
      if (mounted) {
        _navigateToHome();
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Логотип з анімацією пульсації
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: _buildLogo(),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // Текст завантаження
                _buildLoadingText(),

                const SizedBox(height: 16),

                // Прогрес-індикатор
                _buildProgressIndicator(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: [Color(0xFFEAB308), Color(0xFFD4AF37)],
          center: Alignment.center,
          radius: 0.8,
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
      child: const Icon(Icons.trending_up, color: Color(0xFF000000), size: 48),
    );
  }

  Widget _buildLoadingText() {
    return Column(
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
          'Будуємо ваш капітал...',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      width: 200,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 0.7, // Simulate 70% progress
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEAB308), Color(0xFFD4AF37)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
