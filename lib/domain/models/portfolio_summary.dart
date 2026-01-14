class PortfolioPosition {
  final String ticker;
  final double quantity;
  final double currentPriceUah;
  final double averageCostUah;
  final double valueUah;
  final double pnlUah;
  final double pnlPercent;

  const PortfolioPosition({
    required this.ticker,
    required this.quantity,
    required this.currentPriceUah,
    required this.averageCostUah,
    required this.valueUah,
    required this.pnlUah,
    required this.pnlPercent,
  });
}

class PortfolioSummary {
  final double totalValueUah;
  final double cashBalanceUah;
  final double dailyChangeUah;
  final double dailyChangePercent;
  final double totalPnlUah;
  final List<PortfolioPosition> positions;
  final Map<String, double> assetBreakdownUah;

  const PortfolioSummary({
    required this.totalValueUah,
    required this.cashBalanceUah,
    required this.dailyChangeUah,
    required this.dailyChangePercent,
    required this.totalPnlUah,
    required this.positions,
    required this.assetBreakdownUah,
  });

  bool get isEmpty => totalValueUah == 0 && positions.isEmpty;

  PortfolioSummary copyWith({
    double? totalValueUah,
    double? cashBalanceUah,
    double? dailyChangeUah,
    double? dailyChangePercent,
    double? totalPnlUah,
    List<PortfolioPosition>? positions,
    Map<String, double>? assetBreakdownUah,
  }) {
    return PortfolioSummary(
      totalValueUah: totalValueUah ?? this.totalValueUah,
      cashBalanceUah: cashBalanceUah ?? this.cashBalanceUah,
      dailyChangeUah: dailyChangeUah ?? this.dailyChangeUah,
      dailyChangePercent: dailyChangePercent ?? this.dailyChangePercent,
      totalPnlUah: totalPnlUah ?? this.totalPnlUah,
      positions: positions ?? this.positions,
      assetBreakdownUah: assetBreakdownUah ?? this.assetBreakdownUah,
    );
  }

  static PortfolioSummary empty() {
    return const PortfolioSummary(
      totalValueUah: 0,
      cashBalanceUah: 0,
      dailyChangeUah: 0,
      dailyChangePercent: 0,
      totalPnlUah: 0,
      positions: [],
      assetBreakdownUah: {},
    );
  }
}
