import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/million_dollar_service.dart';

class FutureSimulatorWidget extends ConsumerStatefulWidget {
  const FutureSimulatorWidget({super.key});

  @override
  ConsumerState<FutureSimulatorWidget> createState() =>
      _FutureSimulatorWidgetState();
}

class _FutureSimulatorWidgetState extends ConsumerState<FutureSimulatorWidget>
    with TickerProviderStateMixin {
  double _initialAmount = 10000.0;
  int _yearsToProject = 10;
  double _monthlyContribution = 1000.0;
  double _annualReturn = 10.0;
  bool _useCurrentBalance = false;

  late AnimationController _chartAnimationController;
  late AnimationController _fadeAnimationController;

  @override
  void initState() {
    super.initState();
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Завантажуємо поточний баланс
    _loadCurrentBalance();

    // Запускаємо анімації
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chartAnimationController.forward();
      _fadeAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _chartAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  void _loadCurrentBalance() async {
    try {
      final portfolioData = await MillionDollarService.getPortfolioData();
      if (portfolioData != null && mounted) {
        setState(() {
          _initialAmount = portfolioData['totalValue'] as double? ?? 10000.0;
          _useCurrentBalance = true;
        });
      }
    } catch (e) {
      // Якщо не вдалося завантажити, залишаємо значення за замовчуванням
    }
  }

  Map<String, double> _calculateCompoundInterest({
    required double principal,
    required double monthlyContribution,
    required double annualRate,
    required int years,
  }) {
    final monthlyRate = annualRate / 100 / 12;
    final months = years * 12;

    double futureValue = principal;
    for (int i = 0; i < months; i++) {
      futureValue = futureValue * (1 + monthlyRate) + monthlyContribution;
    }

    final totalContributions = principal + (monthlyContribution * months);
    final totalEarnings = futureValue - totalContributions;

    return {
      'futureValue': futureValue,
      'totalContributions': totalContributions,
      'totalEarnings': totalEarnings,
      'monthlyIncome': monthlyContribution,
      'yearlyReturn': (futureValue - principal) / years,
    };
  }

  List<FlSpot> _getChartData(int years) {
    final spots = <FlSpot>[];
    final monthlyRate = _annualReturn / 100 / 12;

    for (int year = 0; year <= years; year++) {
      final months = year * 12;
      double value = _initialAmount;

      for (int i = 0; i < months; i++) {
        value = value * (1 + monthlyRate) + _monthlyContribution;
      }

      spots.add(FlSpot(year.toDouble(), value));
    }

    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final projection = _calculateCompoundInterest(
      principal: _initialAmount,
      monthlyContribution: _monthlyContribution,
      annualRate: _annualReturn,
      years: _yearsToProject,
    );

    return Card(
      color: const Color(0xFF1F1F1F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  color: Color(0xFFD4AF37),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Симулятор майбутнього',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Прогноз зростання вашого капіталу',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB0B0B0),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_useCurrentBalance)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Поточний баланс',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Графік
            SizedBox(
              height: 250,
              child: AnimatedBuilder(
                animation: _chartAnimationController,
                builder: (context, child) {
                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 50000,
                        verticalInterval: 2,
                        getDrawingHorizontalLine: (value) {
                          return const FlLine(
                            color: Color(0xFF333333),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return const FlLine(
                            color: Color(0xFF333333),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 2,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}р',
                                style: const TextStyle(
                                  color: Color(0xFFB0B0B0),
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            interval: 50000,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '\$${(value / 1000).toInt()}k',
                                style: const TextStyle(
                                  color: Color(0xFFB0B0B0),
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: const Color(0xFF333333)),
                      ),
                      minX: 0,
                      maxX: _yearsToProject.toDouble(),
                      minY: 0,
                      maxY: projection['futureValue']! * 1.1,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _getChartData(_yearsToProject),
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFD4AF37).withOpacity(0.8),
                              const Color(0xFFD4AF37),
                            ],
                          ),
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFD4AF37).withOpacity(0.2),
                                const Color(0xFFD4AF37).withOpacity(0.05),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Налаштування
            _buildCompactSettings(),

            const SizedBox(height: 20),

            // Результати
            _buildProjectionResults(projection),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSettings() {
    return Column(
      children: [
        // Початкова сума та роки
        Row(
          children: [
            Expanded(
              child: _buildCompactSlider(
                'Початкова сума',
                '\$${_initialAmount.toStringAsFixed(0)}',
                _initialAmount,
                0.0, // Змінено на 0.0
                1000000.0, // Збільшено до 1,000,000
                (value) => setState(() => _initialAmount = value),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCompactSlider(
                'Період',
                '$_yearsToProject років',
                _yearsToProject.toDouble(),
                0.0, // Змінено на 0.0
                30.0,
                (value) => setState(() => _yearsToProject = value.toInt()),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Щомісячний внесок та дохідність
        Row(
          children: [
            Expanded(
              child: _buildCompactSlider(
                'Щомісячний внесок',
                '\$${_monthlyContribution.toStringAsFixed(0)}',
                _monthlyContribution,
                0.0, // Змінено на 0.0
                10000.0, // Збільшено до 10,000
                (value) => setState(() => _monthlyContribution = value),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCompactSlider(
                'Дохідність',
                '${_annualReturn.toStringAsFixed(1)}%',
                _annualReturn,
                0.0, // Змінено на 0.0
                30.0, // Збільшено до 30%
                (value) => setState(() => _annualReturn = value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactSlider(
    String label,
    String value,
    double currentValue,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    // Додаємо clamping для запобігання помилок
    final clampedValue = currentValue.clamp(min, max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFB0B0B0),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFD4AF37),
            inactiveTrackColor: const Color(0xFF333333),
            thumbColor: const Color(0xFFD4AF37),
            overlayColor: const Color(0xFFD4AF37).withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            trackHeight: 4,
          ),
          child: Slider(
            value: clampedValue, // Використовуємо clamped значення
            min: min,
            max: max,
            divisions: (max - min) > 100 ? ((max - min) / 100).round() : null,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectionResults(Map<String, double> projection) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Прогноз на $_yearsToProject років',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildResultMetric(
                  'Майбутня вартість',
                  '\$${projection['futureValue']!.toStringAsFixed(0)}',
                  const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildResultMetric(
                  'Заробіток',
                  '\$${projection['totalEarnings']!.toStringAsFixed(0)}',
                  const Color(0xFFD4AF37),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildResultMetric(
                  'Внески',
                  '\$${projection['totalContributions']!.toStringAsFixed(0)}',
                  const Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildResultMetric(
                  'Річний дохід',
                  '\$${projection['yearlyReturn']!.toStringAsFixed(0)}',
                  const Color(0xFF9C27B0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFFB0B0B0)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
