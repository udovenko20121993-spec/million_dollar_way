import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/ibkr_data.dart';

class CapitalChart extends StatefulWidget {
  final List<IBKRTrade> trades;

  const CapitalChart({super.key, required this.trades});

  @override
  State<CapitalChart> createState() => _CapitalChartState();
}

class _CapitalChartState extends State<CapitalChart> {
  List<FlSpot> _spots = [];

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  // Перераховуємо дані при оновленні віджета
  @override
  void didUpdateWidget(covariant CapitalChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trades != widget.trades) {
      _prepareData();
    }
  }

  void _prepareData() {
    if (widget.trades.isEmpty) {
      setState(() => _spots = []);
      return;
    }

    // 1. Сортуємо угоди за датою
    final sortedTrades = List<IBKRTrade>.from(widget.trades);
    sortedTrades.sort((a, b) => a.date.compareTo(b.date));

    double currentBalance = 0;
    List<FlSpot> tempSpots = [];

    // Додаємо стартову точку (0)
    if (sortedTrades.isNotEmpty) {
      DateTime firstDate = _parseDate(sortedTrades.first.date);
      tempSpots.add(
        FlSpot(
          firstDate
              .subtract(const Duration(days: 1))
              .millisecondsSinceEpoch
              .toDouble(),
          0,
        ),
      );
    }

    // 2. Рахуємо накопичувальний баланс
    for (var trade in sortedTrades) {
      double amount = trade.price * trade.quantity.abs();

      // Логіка: BUY збільшує вкладений капітал, SELL зменшує (або навпаки, залежно від того, що саме ви хочете бачити: NAV чи Cash)
      // Для графіка "Капіталу" (вартості портфеля) ми зазвичай додаємо вартість при покупці
      if (trade.action.toUpperCase().contains('BUY')) {
        currentBalance += amount;
      } else if (trade.action.toUpperCase().contains('SELL')) {
        currentBalance -= amount;
        if (currentBalance < 0) currentBalance = 0;
      }

      DateTime date = _parseDate(trade.date);
      tempSpots.add(
        FlSpot(date.millisecondsSinceEpoch.toDouble(), currentBalance),
      );
    }

    setState(() {
      _spots = tempSpots;
    });
  }

  DateTime _parseDate(String dateStr) {
    // Обробка формату IBKR (20250121 або 20250121;153020)
    String cleanDate = dateStr.contains(';') ? dateStr.split(';')[0] : dateStr;
    try {
      if (cleanDate.length == 8) {
        return DateTime.parse(
          "${cleanDate.substring(0, 4)}-${cleanDate.substring(4, 6)}-${cleanDate.substring(6, 8)}",
        );
      }
    } catch (_) {}
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    if (_spots.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            "Даних недостатньо",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.70,
      child: Padding(
        padding: const EdgeInsets.only(
          right: 18,
          left: 12,
          top: 24,
          bottom: 12,
        ),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(
              show: false,
            ), // Приховали підписи для чистоти (як у вашому прикладі)
            borderData: FlBorderData(show: false),
            minX: _spots.first.x,
            maxX: _spots.last.x,
            minY: 0,
            maxY: _getMaxY() * 1.1, // +10% відступу зверху
            lineBarsData: [
              LineChartBarData(
                spots: _spots,
                isCurved: true,
                color: const Color(0xFF00C853), // Ваш зелений колір
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00C853).withOpacity(0.3),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            // Тултіп при натисканні (показує дату і суму)
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (spot) => Colors.grey[900]!,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final date = DateTime.fromMillisecondsSinceEpoch(
                      spot.x.toInt(),
                    );
                    return LineTooltipItem(
                      "${DateFormat('dd.MM.yy').format(date)}\n${spot.y.toStringAsFixed(0)} \$",
                      const TextStyle(color: Colors.white),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _getMaxY() {
    if (_spots.isEmpty) return 100;
    return _spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
  }
}
