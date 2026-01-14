import 'package:flutter/material.dart';
import '../../../services/tax_calculation_service.dart';
import '../tax_symbol_detail_screen.dart';

class TaxTradesList extends StatelessWidget {
  final List<FifoMatch> matches;
  final int year;

  const TaxTradesList({super.key, required this.matches, required this.year});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Немає реалізованих продажів у цьому році'),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          const ListTile(
            title: Text('FIFO-матчі'),
            subtitle: Text('Натисни для деталей'),
          ),
          ...matches.map(
            (match) => ListTile(
              title: Text(match.symbol),
              subtitle: Text(
                'Прибуток: ${match.profitUah.toStringAsFixed(2)} грн',
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaxSymbolDetailScreen(
                    year: year,
                    symbol: match.symbol,
                    summary: null, // TODO: Calculate or pass proper summary
                    matches: [match],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
