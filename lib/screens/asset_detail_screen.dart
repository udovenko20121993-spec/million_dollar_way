import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../domain/models/user_goal.dart';
import '../theme/app_theme.dart';

class AssetDetailScreen extends ConsumerWidget {
  final AssetType type;

  const AssetDetailScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppThemeExtension>()!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        title: Text(_getScreenTitle()),
        backgroundColor: colors.primaryBackground,
        iconTheme: IconThemeData(color: colors.primaryText),
      ),
      body: SafeArea(
        child: FutureBuilder<AssetAnalysis>(
          future: _loadAssetData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Помилка завантаження даних',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.primaryText,
                  ),
                ),
              );
            }

            final analysis = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок з сумою
                  _buildSummaryCard(analysis, colors, textTheme),
                  const SizedBox(height: 24),

                  // Графік або діаграма
                  _buildChart(analysis, colors, textTheme),
                  const SizedBox(height: 24),

                  // Детальний список
                  _buildDetailsList(analysis, colors, textTheme),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _getScreenTitle() {
    switch (type) {
      case AssetType.total:
        return 'Загальна вартість';
      case AssetType.cash:
        return 'Готівка';
      case AssetType.stocks:
        return 'Акції';
      case AssetType.assets:
        return 'Активи';
    }
  }

  Widget _buildSummaryCard(
    AssetAnalysis analysis,
    AppThemeExtension colors,
    TextTheme textTheme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getScreenTitle(),
            style: textTheme.headlineSmall?.copyWith(
              color: colors.primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            analysis.formattedValue,
            style: textTheme.headlineMedium?.copyWith(
              color: colors.accentHighlight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${analysis.percentage.toStringAsFixed(1)}% від загального капіталу',
            style: textTheme.bodyMedium?.copyWith(color: colors.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(
    AssetAnalysis analysis,
    AppThemeExtension colors,
    TextTheme textTheme,
  ) {
    switch (type) {
      case AssetType.total:
        return _buildDonutChart(analysis, colors, textTheme);
      case AssetType.cash:
        return _buildCashDistribution(analysis, colors, textTheme);
      case AssetType.stocks:
        return _buildStocksChart(analysis, colors, textTheme);
      case AssetType.assets:
        return _buildAssetsChart(analysis, colors, textTheme);
    }
  }

  Widget _buildDonutChart(
    AssetAnalysis analysis,
    AppThemeExtension colors,
    TextTheme textTheme,
  ) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Розподіл капіталу',
            style: textTheme.titleMedium?.copyWith(color: colors.primaryText),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: analysis.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final colors = [
                    const Color(0xFFD4AF37),
                    const Color(0xFF1E88E5),
                    const Color(0xFF43A047),
                    const Color(0xFFE53935),
                    const Color(0xFF8E24AA),
                  ];

                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: item.value,
                    title: '${item.percentage.toStringAsFixed(1)}%',
                    radius: 50,
                    titleStyle: textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashDistribution(
    AssetAnalysis analysis,
    AppThemeExtension colors,
    TextTheme textTheme,
  ) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Розподіл готівки за валютами',
            style: textTheme.titleMedium?.copyWith(color: colors.primaryText),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final items = analysis.items;
                        if (value.toInt() < items.length) {
                          return Text(
                            items[value.toInt()].symbol,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.primaryText,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                barGroups: analysis.items.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value,
                        color: const Color(0xFFD4AF37),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStocksChart(
    AssetAnalysis analysis,
    AppThemeExtension colors,
    TextTheme textTheme,
  ) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Топ-5 компаній у портфелі',
            style: textTheme.titleMedium?.copyWith(color: colors.primaryText),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final items = analysis.items.take(5).toList();
                        if (value.toInt() < items.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              items[value.toInt()].symbol,
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.primaryText,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                barGroups: analysis.items.take(5).toList().asMap().entries.map((
                  entry,
                ) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value,
                        color: const Color(0xFF1E88E5),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetsChart(
    AssetAnalysis analysis,
    AppThemeExtension colors,
    TextTheme textTheme,
  ) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Не-акційні інструменти',
            style: textTheme.titleMedium?.copyWith(color: colors.primaryText),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: analysis.items.isEmpty
                ? Center(
                    child: Text(
                      'Не-акційні активи відсутні',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.secondaryText,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: analysis.items.length,
                    itemBuilder: (context, index) {
                      final item = analysis.items[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colors.accentHighlight.withOpacity(
                            0.2,
                          ),
                          child: Text(
                            item.symbol.substring(0, 2),
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.accentHighlight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.primaryText,
                          ),
                        ),
                        subtitle: Text(
                          '${item.percentage.toStringAsFixed(1)}% від активів',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.secondaryText,
                          ),
                        ),
                        trailing: Text(
                          item.formattedValue,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.accentHighlight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsList(
    AssetAnalysis analysis,
    AppThemeExtension colors,
    TextTheme textTheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Деталізація',
              style: textTheme.titleMedium?.copyWith(color: colors.primaryText),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: analysis.items.length,
            itemBuilder: (context, index) {
              final item = analysis.items[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: colors.accentHighlight.withOpacity(0.2),
                  child: Text(
                    item.symbol.substring(0, 2),
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.accentHighlight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  item.name,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.primaryText,
                  ),
                ),
                subtitle: Text(
                  '${item.percentage.toStringAsFixed(1)}% від ${_getScreenTitle().toLowerCase()}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.secondaryText,
                  ),
                ),
                trailing: Text(
                  item.formattedValue,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.accentHighlight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<AssetAnalysis> _loadAssetData() async {
    // Симуляція завантаження даних
    await Future.delayed(const Duration(milliseconds: 500));

    switch (type) {
      case AssetType.total:
        return AssetAnalysis(
          type: type,
          value: 150000.0,
          percentage: 100.0,
          currency: 'USD',
          items: [
            const AssetItem(
              symbol: 'IBKR',
              name: 'Interactive Brokers',
              value: 120000.0,
              percentage: 80.0,
              currency: 'USD',
            ),
            const AssetItem(
              symbol: 'CASH',
              name: 'Готівка',
              value: 25000.0,
              percentage: 16.7,
              currency: 'USD',
            ),
            const AssetItem(
              symbol: 'BONDS',
              name: 'Облігації',
              value: 5000.0,
              percentage: 3.3,
              currency: 'USD',
            ),
          ],
        );
      case AssetType.cash:
        return AssetAnalysis(
          type: type,
          value: 25000.0,
          percentage: 16.7,
          currency: 'USD',
          items: [
            const AssetItem(
              symbol: 'USD',
              name: 'Долари США',
              value: 15000.0,
              percentage: 60.0,
              currency: 'USD',
            ),
            const AssetItem(
              symbol: 'EUR',
              name: 'Євро',
              value: 7000.0,
              percentage: 28.0,
              currency: 'USD',
            ),
            const AssetItem(
              symbol: 'UAH',
              name: 'Гривні',
              value: 3000.0,
              percentage: 12.0,
              currency: 'USD',
            ),
          ],
        );
      case AssetType.stocks:
        return AssetAnalysis(
          type: type,
          value: 120000.0,
          percentage: 80.0,
          currency: 'USD',
          items: [
            const AssetItem(
              symbol: 'AAPL',
              name: 'Apple Inc.',
              value: 35000.0,
              percentage: 29.2,
              currency: 'USD',
            ),
            const AssetItem(
              symbol: 'GOOGL',
              name: 'Alphabet Inc.',
              value: 25000.0,
              percentage: 20.8,
              currency: 'USD',
            ),
            const AssetItem(
              symbol: 'MSFT',
              name: 'Microsoft Corp.',
              value: 20000.0,
              percentage: 16.7,
              currency: 'USD',
            ),
            const AssetItem(
              symbol: 'TSLA',
              name: 'Tesla Inc.',
              value: 18000.0,
              percentage: 15.0,
              currency: 'USD',
            ),
            const AssetItem(
              symbol: 'AMZN',
              name: 'Amazon.com Inc.',
              value: 22000.0,
              percentage: 18.3,
              currency: 'USD',
            ),
          ],
        );
      case AssetType.assets:
        return AssetAnalysis(
          type: type,
          value: 5000.0,
          percentage: 3.3,
          currency: 'USD',
          items: [
            const AssetItem(
              symbol: 'VOO',
              name: 'Vanguard S&P 500 ETF',
              value: 3000.0,
              percentage: 60.0,
              currency: 'USD',
            ),
            const AssetItem(
              symbol: 'BND',
              name: 'Vanguard Total Bond Market',
              value: 2000.0,
              percentage: 40.0,
              currency: 'USD',
            ),
          ],
        );
    }
  }
}
