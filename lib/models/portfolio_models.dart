/// Represents a single asset position in the portfolio.
class AssetPosition {
  final String symbol;
  final String name;
  final double quantity;
  final double marketValue;
  final double unrealizedPnl;
  final double unrealizedPnlPercent;

  const AssetPosition({
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.marketValue,
    required this.unrealizedPnl,
    required this.unrealizedPnlPercent,
  });

  factory AssetPosition.fromFirestore(Map<String, dynamic> data) {
    return AssetPosition(
      symbol: data['symbol'] as String? ?? '',
      name: data['name'] as String? ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0.0,
      marketValue: (data['marketValue'] as num?)?.toDouble() ?? 0.0,
      unrealizedPnl: (data['unrealizedPnl'] as num?)?.toDouble() ?? 0.0,
      unrealizedPnlPercent:
          (data['unrealizedPnlPercent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Represents a complete snapshot of the portfolio at a point in time.
class PortfolioSnapshot {
  final double totalValue;
  final double dailyPnl;
  final double dailyPnlPercent;
  final List<AssetPosition> assets;

  const PortfolioSnapshot({
    required this.totalValue,
    required this.dailyPnl,
    required this.dailyPnlPercent,
    required this.assets,
  });

  factory PortfolioSnapshot.fromFirestore(Map<String, dynamic> data) {
    final assetsData = data['assets'] as List<dynamic>? ?? [];
    final assets = assetsData
        .map(
          (assetData) =>
              AssetPosition.fromFirestore(assetData as Map<String, dynamic>),
        )
        .toList();

    return PortfolioSnapshot(
      totalValue: (data['totalValue'] as num?)?.toDouble() ?? 0.0,
      dailyPnl: (data['dailyPnl'] as num?)?.toDouble() ?? 0.0,
      dailyPnlPercent: (data['dailyPnlPercent'] as num?)?.toDouble() ?? 0.0,
      assets: assets,
    );
  }
}
