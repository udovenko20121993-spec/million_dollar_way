import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:million_dollar_way/services/time_machine_service.dart';
import 'package:million_dollar_way/services/user_state_service.dart';
import 'package:million_dollar_way/presentation/ui/screens/golden_home_screen.dart';

class TimeMachineScreen extends ConsumerStatefulWidget {
  const TimeMachineScreen({super.key});

  @override
  ConsumerState<TimeMachineScreen> createState() => _TimeMachineScreenState();
}

class _TimeMachineScreenState extends ConsumerState<TimeMachineScreen>
    with TickerProviderStateMixin {
  double _monthlyInvestment = 500.0;
  int _years = 10;
  BacktestResult? _backtestResult;
  bool _isCalculating = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _runBacktest();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _runBacktest() async {
    setState(() {
      _isCalculating = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    final result = TimeMachineService.instance.runBacktest(
      monthlyInvestment: _monthlyInvestment,
      years: _years,
    );

    setState(() {
      _backtestResult = result;
      _isCalculating = false;
    });
  }

  void _onMonthlyInvestmentChanged(double value) {
    setState(() {
      _monthlyInvestment = value;
    });
    _runBacktest();
  }

  void _onYearsChanged(int value) {
    setState(() {
      _years = value;
    });
    _runBacktest();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              _buildHeader(),
              const SizedBox(height: 40),

              // Інпути
              _buildInputs(),
              const SizedBox(height: 40),

              // Результати
              if (_backtestResult != null) ...[
                _buildRealityCheckCard(),
                const SizedBox(height: 40),
              ],

              // Кнопка дії
              _buildActionCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.hourglass_full,
                    color: Color(0xFFEAB308),
                    size: 32,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Машина часу Million Dollar Way 🚀',
                      style: TextStyle(
                        color: Color(0xFFEAB308),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Подивіться, скільки ви б заробили, якби почали 10 років тому',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputs() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAB308).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Щомісячна інвестиція
          Text(
            'Щомісячна інвестиція: ${TimeMachineService.instance.formatCurrency(_monthlyInvestment)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: _monthlyInvestment,
            min: 50,
            max: 5000,
            divisions: 99,
            activeColor: const Color(0xFFEAB308),
            inactiveColor: Colors.grey.shade700,
            onChanged: _onMonthlyInvestmentChanged,
          ),
          const SizedBox(height: 24),

          // Період
          Text(
            'Період: $_years років',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [5, 10, 20, 30].map((years) {
              final isSelected = years == _years;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _onYearsChanged(years),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFEAB308)
                            : Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$years',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRealityCheckCard() {
    if (_backtestResult == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAB308), Color(0xFFD4AF37)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEAB308).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔍 Reality Check',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Результати
          _buildResultRow(
            'Ви б інвестували:',
            TimeMachineService.instance.formatCurrency(
              _backtestResult!.totalInvested,
            ),
            Colors.black87,
          ),

          _buildResultRow(
            'Ваш капітал сьогодні:',
            TimeMachineService.instance.formatCurrency(
              _backtestResult!.currentValue,
            ),
            Colors.black87,
          ),

          _buildResultRow(
            TimeMachineService.instance.getRealWorldComparison(
              _backtestResult!.currentValue,
              _backtestResult!.currentValueWithAlpha,
            ),
            '',
            Colors.black,
            isBold: true,
          ),

          const SizedBox(height: 20),

          // Мотиваційний текст
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              TimeMachineService.instance.getMotivationalText(_years),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAB308).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'Час дії!',
            style: TextStyle(
              color: Color(0xFFEAB308),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await UserStateService.instance.markTimeMachineSeen();

                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const GoldenHomeScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEAB308),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
              child: const Text(
                'ПОЧАТИ СВІЙ ШЛЯХ ЗАРАЗ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Приєднуйтесь до тисяч інвесторів, які вже будують своє майбутнє',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
