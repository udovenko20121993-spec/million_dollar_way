import 'package:flutter/material.dart';

import '../../domain/models/custom_portfolio_models.dart';

class PortfolioHeatmap extends StatelessWidget {
  final List<PortfolioAsset> assets;

  const PortfolioHeatmap({super.key, required this.assets});

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2C2C2C)),
        ),
        child: const Center(
          child: Text(
            'Немає активів для теплової карти',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    final maxValue = assets.fold<double>(
      0,
      (prev, asset) => asset.marketValue > prev ? asset.marketValue : prev,
    );
    final tiles =
        assets
            .map(
              (asset) => _HeatTileData(
                symbol: asset.symbol,
                marketValue: asset.marketValue,
                changePercent: asset.dailyChangePercent != 0
                    ? asset.dailyChangePercent
                    : asset.totalProfitLossPercent,
                weight: maxValue > 0
                    ? asset.marketValue / maxValue
                    : asset.portfolioShare,
              ),
            )
            .toList()
          ..sort((a, b) => b.marketValue.compareTo(a.marketValue));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF101010),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Теплова карта портфеля',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: tiles.map((tile) => _HeatTile(data: tile)).toList(),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _LegendDot(color: Color(0xFFE53935), label: 'У збитку'),
              SizedBox(width: 16),
              _LegendDot(color: Color(0xFFFFB300), label: 'Нейтрально'),
              SizedBox(width: 16),
              _LegendDot(color: Color(0xFF43A047), label: 'В прибутку'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatTileData {
  final String symbol;
  final double marketValue;
  final double changePercent;
  final double weight;

  _HeatTileData({
    required this.symbol,
    required this.marketValue,
    required this.changePercent,
    required this.weight,
  });
}

class _HeatTile extends StatelessWidget {
  final _HeatTileData data;
  const _HeatTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final size = (90 + (data.weight * 140)).clamp(70.0, 190.0);
    final color = _mapChangeToColor(data.changePercent);

    return Tooltip(
      message:
          '${data.symbol}\nРинкова вартість: \$${data.marketValue.toStringAsFixed(0)}\nЗміна: ${data.changePercent.toStringAsFixed(2)}%',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.85), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          data.symbol,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _mapChangeToColor(double percent) {
    if (percent > 6) return const Color(0xFF2E7D32);
    if (percent > 0) return const Color(0xFF43A047);
    if (percent < -8) return const Color(0xFFB71C1C);
    if (percent < 0) return const Color(0xFFE53935);
    return const Color(0xFFFFB300);
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
