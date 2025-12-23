import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:million_dollar_way/models/ibkr_data.dart';

class BalanceChart extends StatefulWidget {
  final List<IBKRTrade> trades;

  const BalanceChart({super.key, required this.trades});

  @override
  State<BalanceChart> createState() => _BalanceChartState();
}

class _BalanceChartState extends State<BalanceChart> {
  List<FlSpot> _allSpots = [];
  List<FlSpot> _visibleSpots = [];
  String _selectedPeriod = 'ALL';

  @override
  void initState() {
    super.initState();
    _calculateAllData();
  }

  void _calculateAllData() {
    if (widget.trades.isEmpty) return;

    final sortedTrades = List<IBKRTrade>.from(widget.trades);
    sortedTrades.sort((a, b) => a.date.compareTo(b.date));

    double currentInvestedValue = 0;
    List<FlSpot> tempSpots = [];

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

    for (var trade in sortedTrades) {
      double quantity = trade.quantity.abs();
      double tradeValue = trade.price * quantity;
      String action = trade.action.toUpperCase();

      if (action.contains('BUY')) {
        currentInvestedValue += tradeValue;
      } else if (action.contains('SELL')) {
        currentInvestedValue -= tradeValue;
        if (currentInvestedValue < 0) currentInvestedValue = 0;
      }

      DateTime date = _parseDate(trade.date);
      tempSpots.add(
        FlSpot(date.millisecondsSinceEpoch.toDouble(), currentInvestedValue),
      );
    }

    setState(() {
      _allSpots = tempSpots;
      _filterData(_selectedPeriod);
    });
  }

  void _filterData(String period) {
    if (_allSpots.isEmpty) return;

    DateTime now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case '1W':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case '1M':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case '3M':
        startDate = now.subtract(const Duration(days: 90));
        break;
      case '6M':
        startDate = now.subtract(const Duration(days: 180));
        break;
      case '1Y':
        startDate = now.subtract(const Duration(days: 365));
        break;
      case 'ALL':
      default:
        startDate = DateTime(2000);
        break;
    }

    List<FlSpot> filtered = _allSpots
        .where((spot) => spot.x >= startDate.millisecondsSinceEpoch)
        .toList();

    if (period != 'ALL' && _allSpots.isNotEmpty) {
      try {
        final lastPointBefore = _allSpots.lastWhere(
          (spot) => spot.x < startDate.millisecondsSinceEpoch,
        );
        filtered.insert(0, lastPointBefore);
      } catch (_) {}
    }

    setState(() {
      _selectedPeriod = period;
      _visibleSpots = filtered;
    });
  }

  DateTime _parseDate(String dateStr) {
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
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ), // Зменшені відступи
      padding: const EdgeInsets.fromLTRB(0, 16, 16, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // ЗМЕНШЕНА ВИСОТА ГРАФІКА
          SizedBox(
            height: 160,
            child: _visibleSpots.isEmpty
                ? const Center(
                    child: Text(
                      "Немає даних",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (spot) => Colors.grey[800]!,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final date = DateTime.fromMillisecondsSinceEpoch(
                                spot.x.toInt(),
                              );
                              final dateStr = DateFormat(
                                'dd.MM.yy',
                              ).format(date);
                              return LineTooltipItem(
                                "$dateStr\n${spot.y.toStringAsFixed(2)} \$",
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.white.withOpacity(0.05),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ), // Прибираємо дати знизу для компактності
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            interval: _calculateYInterval(),
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Text(
                                "${value.toInt()} \$",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 9,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: _visibleSpots.first.x,
                      maxX: _visibleSpots.last.x,
                      minY: 0,
                      maxY: _getMaxY() * 1.1,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _visibleSpots,
                          isCurved: true,
                          color: Colors.blueAccent,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.blueAccent.withOpacity(0.3),
                                Colors.transparent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          // КОМПАКТНІ КНОПКИ
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPeriodButton("1W"),
                _buildPeriodButton("1M"),
                _buildPeriodButton("3M"),
                _buildPeriodButton("6M"),
                _buildPeriodButton("1Y"),
                _buildPeriodButton("ALL"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxY() {
    if (_visibleSpots.isEmpty) return 100;
    return _visibleSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
  }

  double _calculateYInterval() {
    double max = _getMaxY();
    if (max == 0) return 10;
    return max / 3;
  }

  Widget _buildPeriodButton(String text) {
    bool isSelected = _selectedPeriod == text;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: GestureDetector(
        onTap: () => _filterData(text),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.blueAccent
                  : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}
