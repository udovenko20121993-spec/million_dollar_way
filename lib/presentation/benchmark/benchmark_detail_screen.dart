import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/benchmark_data.dart';
import '../../services/benchmark_service.dart';

/// Детальний екран порівняння портфеля з S&P 500
class BenchmarkDetailScreen extends StatefulWidget {
  final String userId;

  const BenchmarkDetailScreen({super.key, required this.userId});

  @override
  State<BenchmarkDetailScreen> createState() => _BenchmarkDetailScreenState();
}

class _BenchmarkDetailScreenState extends State<BenchmarkDetailScreen> {
  late BenchmarkService _service;
  BenchmarkComparison? _comparison;
  List<PeriodComparison> _periodComparisons = [];
  bool _isLoading = true;
  String _selectedPeriod = 'ALL';

  @override
  void initState() {
    super.initState();
    _service = BenchmarkService(userId: widget.userId);
    _loadData();
  }

  Future<void> _loadData() async {
    final comparison = await _service.calculateComparison();
    final periods = await _service.getPeriodComparisons();

    if (mounted) {
      setState(() {
        _comparison = comparison;
        _periodComparisons = periods;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Порівняння з S&P 500'),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _comparison == null
                ? _buildNoDataState()
                : _buildContent(),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          const Text(
            'Недостатньо даних',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Потрібні угоди для порівняння',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Головна картка результату
          _buildResultCard(),
          
          const SizedBox(height: 24),

          // Вибір періоду
          _buildPeriodSelector(),

          const SizedBox(height: 24),

          // Графік порівняння
          _buildComparisonChart(),

          const SizedBox(height: 24),

          // Таблиця порівняння по періодах
          _buildPeriodTable(),

          const SizedBox(height: 24),

          // Пояснення
          _buildExplanationCard(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final comparison = _comparison!;
    final isWinning = comparison.isOutperforming;
    final mainColor = isWinning ? const Color(0xFF00C853) : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            mainColor.withOpacity(0.2),
            const Color(0xFF1A1A1A),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: mainColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Іконка результату
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isWinning ? Icons.emoji_events : Icons.trending_down,
              color: mainColor,
              size: 40,
            ),
          ),

          const SizedBox(height: 16),

          // Статус
          Text(
            isWinning ? 'Ви перемагаєте ринок! 🏆' : 'Ринок попереду 📉',
            style: TextStyle(
              color: mainColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          // Дохідності
          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                  'Ваш портфель',
                  '${comparison.portfolioReturn >= 0 ? '+' : ''}${comparison.portfolioReturn.toStringAsFixed(2)}%',
                  '\$${comparison.portfolioValue.toStringAsFixed(0)}',
                  const Color(0xFFD4AF37),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricBox(
                  'S&P 500',
                  '${comparison.benchmarkReturn >= 0 ? '+' : ''}${comparison.benchmarkReturn.toStringAsFixed(2)}%',
                  '\$${comparison.benchmarkValue.toStringAsFixed(0)}',
                  Colors.blueAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Альфа
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Альфа (α)',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${comparison.alpha >= 0 ? '+' : ''}${comparison.alpha.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: mainColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getAlphaDescription(comparison.alpha),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox(String title, String percent, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Text(
            percent,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['1M', '3M', 'YTD', '1Y', 'ALL'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = period),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.grey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildComparisonChart() {
    final comparison = _comparison!;
    
    if (comparison.portfolioHistory.isEmpty || comparison.benchmarkHistory.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text('Недостатньо даних для графіка', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    // Підготовка даних для графіка
    final portfolioSpots = <FlSpot>[];
    final benchmarkSpots = <FlSpot>[];

    for (int i = 0; i < comparison.portfolioHistory.length; i++) {
      portfolioSpots.add(FlSpot(
        i.toDouble(),
        comparison.portfolioHistory[i].returnPercent,
      ));
    }

    for (int i = 0; i < comparison.benchmarkHistory.length && i < comparison.portfolioHistory.length; i++) {
      benchmarkSpots.add(FlSpot(
        i.toDouble(),
        comparison.benchmarkHistory[i].returnPercent,
      ));
    }

    final maxY = [
      ...portfolioSpots.map((s) => s.y),
      ...benchmarkSpots.map((s) => s.y),
    ].reduce((a, b) => a > b ? a : b);

    final minY = [
      ...portfolioSpots.map((s) => s.y),
      ...benchmarkSpots.map((s) => s.y),
    ].reduce((a, b) => a < b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Динаміка дохідності',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Легенда
          Row(
            children: [
              _buildLegendItem('Ваш портфель', const Color(0xFFD4AF37)),
              const SizedBox(width: 20),
              _buildLegendItem('S&P 500', Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white10,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (portfolioSpots.length - 1).toDouble(),
                minY: minY - 5,
                maxY: maxY + 5,
                lineBarsData: [
                  // Портфель
                  LineChartBarData(
                    spots: portfolioSpots,
                    isCurved: true,
                    color: const Color(0xFFD4AF37),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFD4AF37).withOpacity(0.1),
                    ),
                  ),
                  // S&P 500
                  LineChartBarData(
                    spots: benchmarkSpots,
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildPeriodTable() {
    if (_periodComparisons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Порівняння по періодах',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Заголовок таблиці
          Row(
            children: [
              const Expanded(flex: 2, child: Text('Період', style: TextStyle(color: Colors.grey, fontSize: 12))),
              const Expanded(child: Text('Портфель', style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center)),
              const Expanded(child: Text('S&P 500', style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center)),
              const Expanded(child: Text('Альфа', style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center)),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(color: Colors.white10),

          // Рядки таблиці
          ..._periodComparisons.map((p) => _buildPeriodRow(p)),
        ],
      ),
    );
  }

  Widget _buildPeriodRow(PeriodComparison period) {
    final isWinning = period.isOutperforming;
    final alphaColor = isWinning ? const Color(0xFF00C853) : Colors.redAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              BenchmarkService.getPeriodName(period.period),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              '${period.portfolioReturn >= 0 ? '+' : ''}${period.portfolioReturn.toStringAsFixed(1)}%',
              style: TextStyle(
                color: period.portfolioReturn >= 0 ? const Color(0xFFD4AF37) : Colors.redAccent,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '${period.benchmarkReturn >= 0 ? '+' : ''}${period.benchmarkReturn.toStringAsFixed(1)}%',
              style: TextStyle(
                color: period.benchmarkReturn >= 0 ? Colors.blueAccent : Colors.redAccent,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: alphaColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${period.alpha >= 0 ? '+' : ''}${period.alpha.toStringAsFixed(1)}%',
                style: TextStyle(color: alphaColor, fontSize: 12, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: const Color(0xFFD4AF37).withOpacity(0.8), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Що таке Альфа?',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Альфа (α) показує на скільки ваш портфель перевершує або відстає від ринку (S&P 500).',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          const SizedBox(height: 8),
          _buildExplanationItem('α > 0', 'Ви перемагаєте ринок', const Color(0xFF00C853)),
          _buildExplanationItem('α = 0', 'Ви йдете нарівні з ринком', Colors.grey),
          _buildExplanationItem('α < 0', 'Ринок випереджає вас', Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            'S&P 500 — індекс 500 найбільших компаній США. Це стандартний бенчмарк для оцінки інвестицій.',
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationItem(String alpha, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$alpha — $description',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _getAlphaDescription(double alpha) {
    if (alpha > 10) {
      return 'Відмінний результат! Ви значно випереджаєте ринок';
    } else if (alpha > 5) {
      return 'Чудовий результат! Ваша стратегія працює';
    } else if (alpha > 0) {
      return 'Добре! Ви трохи випереджаєте ринок';
    } else if (alpha > -5) {
      return 'Невелике відставання від ринку';
    } else {
      return 'Варто переглянути стратегію';
    }
  }
}
