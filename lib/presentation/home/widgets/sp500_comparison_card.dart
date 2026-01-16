import 'package:flutter/material.dart';
import 'package:million_dollar_way/models/ibkr_data.dart';
import 'package:million_dollar_way/services/sp500_service.dart';
import 'package:million_dollar_way/services/sp500_simulator.dart';

class Sp500ComparisonCard extends StatelessWidget {
  final IBKRReport report;

  const Sp500ComparisonCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final positionsValue = report.assets.fold<double>(0, (sum, a) => sum + a.value);

    if (report.trades.isEmpty || positionsValue <= 0) {
      return const SizedBox.shrink();
    }

    final service = Sp500Service();
    final simulator = Sp500Simulator(service);

    return FutureBuilder(
      future: service.fetchDailyClose(),
      builder: (context, snapshot) {
        Widget child;
        if (snapshot.connectionState == ConnectionState.waiting) {
          child = _buildLoading();
        } else if (snapshot.hasError || !snapshot.hasData) {
          child = _buildError();
        } else {
          final spSeries = snapshot.data!;
          final result = simulator.simulate(
            trades: report.trades,
            sp500DailyClose: spSeries,
          );

          final spValue = result.sp500ValueNow;
          if (spValue <= 0) {
            child = _buildError();
          } else {
            final diff = positionsValue - spValue;
            final diffPct = spValue != 0 ? (diff / spValue) * 100 : 0.0;
            child = _buildContent(
              portfolioValue: positionsValue,
              sp500Value: spValue,
              diff: diff,
              diffPct: diffPct,
            );
          }
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: child,
        );
      },
    );
  }

  Widget _buildLoading() {
    return const Row(
      children: [
        SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            "Рахую порівняння з S&P 500…",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return const Text(
      "Не вдалося завантажити дані S&P 500 для порівняння.",
      style: TextStyle(color: Colors.white70),
    );
  }

  Widget _buildContent({
    required double portfolioValue,
    required double sp500Value,
    required double diff,
    required double diffPct,
  }) {
    final isBetter = diff >= 0;
    final color = isBetter ? const Color(0xFF00C853) : Colors.redAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Порівняння з S&P 500",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _metric(
                title: "Портфель (позиції)",
                value: "${portfolioValue.toStringAsFixed(0)}\$",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metric(
                title: "S&P 500 (якби)",
                value: "${sp500Value.toStringAsFixed(0)}\$",
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              Icon(
                isBetter ? Icons.trending_up : Icons.trending_down,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${isBetter ? '+' : ''}${diff.toStringAsFixed(0)}\$ (${isBetter ? '+' : ''}${diffPct.toStringAsFixed(2)}%)",
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
              const Text(
                "vs S&P500",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Логіка: ті ж суми BUY/SELL інвестуються/виводяться з S&P 500 у дні угод.",
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }

  Widget _metric({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

