import 'package:flutter/material.dart';
import '../../models/benchmark_data.dart';
import '../../services/benchmark_service.dart';
import 'benchmark_detail_screen.dart';

/// Картка порівняння портфеля з S&P 500
class BenchmarkComparisonCard extends StatefulWidget {
  final String userId;

  const BenchmarkComparisonCard({super.key, required this.userId});

  @override
  State<BenchmarkComparisonCard> createState() => _BenchmarkComparisonCardState();
}

class _BenchmarkComparisonCardState extends State<BenchmarkComparisonCard> {
  BenchmarkComparison? _comparison;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComparison();
  }

  Future<void> _loadComparison() async {
    final service = BenchmarkService(userId: widget.userId);
    final comparison = await service.calculateComparison();
    
    if (mounted) {
      setState(() {
        _comparison = comparison;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingCard();
    }

    if (_comparison == null) {
      return _buildNoDataCard();
    }

    return _buildComparisonCard();
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        children: [
          Icon(Icons.trending_up, color: Colors.grey, size: 24),
          SizedBox(width: 12),
          Text(
            'Недостатньо даних для порівняння',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard() {
    final comparison = _comparison!;
    final isWinning = comparison.isOutperforming;
    final mainColor = isWinning ? const Color(0xFF00C853) : Colors.redAccent;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BenchmarkDetailScreen(userId: widget.userId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              mainColor.withOpacity(0.15),
              const Color(0xFF1A1A1A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: mainColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: mainColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isWinning ? Icons.emoji_events : Icons.trending_down,
                    color: mainColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'vs S&P 500',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        isWinning ? 'Ви перемагаєте! 🏆' : 'S&P 500 попереду',
                        style: TextStyle(
                          color: mainColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Порівняння дохідностей
            Row(
              children: [
                // Ваш портфель
                Expanded(
                  child: _buildReturnColumn(
                    'Ваш портфель',
                    comparison.portfolioReturn,
                    const Color(0xFFD4AF37),
                  ),
                ),
                
                // Роздільник
                Container(
                  height: 50,
                  width: 1,
                  color: Colors.white10,
                ),
                
                // S&P 500
                Expanded(
                  child: _buildReturnColumn(
                    'S&P 500',
                    comparison.benchmarkReturn,
                    Colors.blueAccent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Альфа
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: mainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'α (Альфа): ',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${comparison.alpha >= 0 ? '+' : ''}${comparison.alpha.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: mainColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Різниця у вартості
            Center(
              child: Text(
                _formatValueDifference(comparison),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnColumn(String title, double value, Color color) {
    final isPositive = value >= 0;
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${isPositive ? '+' : ''}${value.toStringAsFixed(2)}%',
          style: TextStyle(
            color: isPositive ? color : Colors.redAccent,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatValueDifference(BenchmarkComparison comparison) {
    final diff = comparison.valueDifference;
    final absDiff = diff.abs();
    
    if (diff >= 0) {
      return 'Ви заробили на \$${absDiff.toStringAsFixed(0)} більше ніж S&P 500';
    } else {
      return 'S&P 500 заробив би на \$${absDiff.toStringAsFixed(0)} більше';
    }
  }
}
