import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/custom_portfolio_models.dart';
import '../../providers/investment_snapshot_provider.dart';

class DaughterFundScreen extends ConsumerStatefulWidget {
  const DaughterFundScreen({super.key});

  @override
  ConsumerState<DaughterFundScreen> createState() => _DaughterFundScreenState();
}

class _DaughterFundStats {
  final double currentValue;
  final double targetValue;
  final double totalInvested;
  final double profit;
  final double passiveIncome;
  final double weeklyContribution;
  final double goalProgress;
  final double leafRichness;
  final double recentDividendAmount;

  const _DaughterFundStats({
    required this.currentValue,
    required this.targetValue,
    required this.totalInvested,
    required this.profit,
    required this.passiveIncome,
    required this.weeklyContribution,
    required this.goalProgress,
    required this.leafRichness,
    required this.recentDividendAmount,
  });

  factory _DaughterFundStats.fromSnapshot(
    InvestmentSnapshot snapshot, {
    required DateTime daughterBirthday,
    required DateTime comingOfAgeDate,
  }) {
    final daughterAssets = snapshot.univerAssets
        .where((asset) => asset.belongsToDaughter)
        .toList();

    final currentValue = daughterAssets.fold<double>(
      0,
      (sum, asset) => sum + asset.currentMarketValue + asset.accruedInterest,
    );
    final totalInvested = daughterAssets.fold<double>(
      0,
      (sum, asset) => sum + asset.initialInvestment,
    );
    final passiveIncome = daughterAssets.fold<double>(
      0,
      (sum, asset) => sum + asset.totalDividendsPaid,
    );
    final profit = currentValue - totalInvested;

    final weeklyContribution = daughterAssets.fold<double>(
      0,
      (sum, asset) =>
          sum + math.max(0, asset.couponRate * asset.nominalValue / 5200),
    );

    final totalDays = comingOfAgeDate
        .difference(daughterBirthday)
        .inDays
        .clamp(1, 365 * 18);
    final elapsedDays = DateTime.now()
        .difference(daughterBirthday)
        .inDays
        .clamp(0, totalDays);
    final progress = elapsedDays / totalDays;

    final recentDividends = snapshot.dividends
        .where(
          (d) =>
              d.date.isAfter(DateTime.now().subtract(const Duration(days: 30))),
        )
        .fold<double>(0, (sum, d) => sum + d.netAmount);

    const targetValue = 100000.0;
    final leafRichness = (currentValue / targetValue).clamp(0.2, 1.2);

    return _DaughterFundStats(
      currentValue: currentValue,
      targetValue: targetValue,
      totalInvested: totalInvested,
      profit: profit,
      passiveIncome: passiveIncome,
      weeklyContribution: weeklyContribution,
      goalProgress: (currentValue / targetValue).clamp(0.0, 1.0),
      leafRichness: leafRichness,
      recentDividendAmount: recentDividends,
    );
  }
}

class _DaughterFundScreenState extends ConsumerState<DaughterFundScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _countdownTimer;
  Duration _timeLeft = Duration.zero;
  final DateTime _comingOfAgeDate = DateTime(DateTime.now().year + 10, 6, 1);
  late final Duration _totalCountdownDuration;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _totalCountdownDuration = _comingOfAgeDate.difference(DateTime.now());
    _updateTimeLeft();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeLeft();
    });
  }

  void _updateTimeLeft() {
    setState(() {
      _timeLeft = _comingOfAgeDate.difference(DateTime.now());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(investmentSnapshotProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFFF8E1),
        foregroundColor: const Color(0xFF5D4037),
        title: const Text('Золоте дерево доньки'),
      ),
      body: snapshot.when(
        data: (data) => _buildContent(context, data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Не вдалося завантажити дані: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, InvestmentSnapshot? data) {
    if (data == null) {
      return const Center(
        child: Text(
          'Дані фонду ще збираються...',
          style: TextStyle(color: Color(0xFF8D6E63)),
        ),
      );
    }

    final stats = _DaughterFundStats.fromSnapshot(
      data,
      daughterBirthday: DateTime(DateTime.now().year - 8, 6, 1),
      comingOfAgeDate: _comingOfAgeDate,
    );
    final hasRecentDividends = stats.recentDividendAmount > 0;
    final sparkleBoost = hasRecentDividends ? 1.6 : 1.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCountdownCard(),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE082), Color(0xFFFFCA28)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x80FBC02D),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Фонд майбутнього',
                      style: TextStyle(
                        color: Color(0xFF5D4037),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₴${stats.currentValue.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF4E342E),
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Ціль: ₴${stats.targetValue.toStringAsFixed(0)}',
                      style: const TextStyle(color: Color(0xFF6D4C41)),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 320,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _GoldenTreePainter(
                            growthFactor: stats.goalProgress,
                            sparklePhase: _controller.value,
                            sparkleIntensity: sparkleBoost,
                            leafRichness: stats.leafRichness,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Поточна вартість фонду',
                      value: '₴${stats.currentValue.toStringAsFixed(0)}',
                      subtitle: 'оновлено автоматично',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Вкладено всього',
                      value: '₴${stats.totalInvested.toStringAsFixed(0)}',
                      subtitle: 'ваші поповнення',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatCard(
                    title: 'Пасивний дохід',
                    value: '₴${stats.passiveIncome.toStringAsFixed(0)}',
                    subtitle: 'дивіденди фонду',
                  ),
                  _StatCard(
                    title: 'Прибуток / збиток',
                    value: '₴${stats.profit.toStringAsFixed(0)}',
                    subtitle: stats.profit >= 0
                        ? 'золотий приріст'
                        : 'тимчасове просідання',
                  ),
                  _StatCard(
                    title: 'Тижневий внесок',
                    value: '₴${stats.weeklyContribution.toStringAsFixed(0)}',
                    subtitle: 'автоматичне поповнення',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildCountdownProgress(),
              const SizedBox(height: 24),
              _buildMilestones(stats),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMilestones(_DaughterFundStats stats) {
    final milestones = [
      const _Milestone(label: 'Освіта', amount: 20000),
      const _Milestone(label: 'Подорожі', amount: 40000),
      const _Milestone(label: 'Перший автомобіль', amount: 60000),
      const _Milestone(label: 'Перший бізнес', amount: 90000),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Майбутні подарунки золотої доньки',
            style: TextStyle(
              color: Color(0xFF4E342E),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          ...milestones.map((m) {
            final unlocked = stats.currentValue >= m.amount;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    unlocked
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: unlocked ? const Color(0xFF66BB6A) : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.label,
                          style: TextStyle(
                            color: unlocked
                                ? const Color(0xFF4E342E)
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text('₴${m.amount.toStringAsFixed(0)}'),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCountdownCard() {
    final months = _timeLeft.inDays ~/ 30;
    final days = _timeLeft.inDays % 30;
    final hours = _timeLeft.inHours % 24;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CountdownUnit(value: months, label: 'місяців'),
          _CountdownUnit(value: days, label: 'днів'),
          _CountdownUnit(value: hours, label: 'годин'),
        ],
      ),
    );
  }

  Widget _buildCountdownProgress() {
    final totalSeconds = _totalCountdownDuration.inSeconds.clamp(
      1,
      double.maxFinite.toInt(),
    );
    final progress = 1 - (_timeLeft.inSeconds / totalSeconds);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Прогрес до повноліття',
          style: TextStyle(
            color: Color(0xFF4E342E),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: progress.clamp(0.0, 1.0),
            color: const Color(0xFFFFCA28),
            backgroundColor: const Color(0xFFFFF3E0),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${(progress * 100).toStringAsFixed(1)}% шляху пройдено',
          style: const TextStyle(color: Color(0xFF6D4C41)),
        ),
      ],
    );
  }
}

class _GoldenTreePainter extends CustomPainter {
  final double growthFactor;
  final double sparklePhase;
  final double sparkleIntensity;
  final double leafRichness;
  final math.Random _random = math.Random();

  _GoldenTreePainter({
    required this.growthFactor,
    required this.sparklePhase,
    required this.sparkleIntensity,
    required this.leafRichness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    final trunkPaint = Paint()
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final trunkHeight = size.height * (0.2 + growthFactor * 0.5);
    final trunkPath = Path()
      ..moveTo(size.width / 2, size.height)
      ..cubicTo(
        size.width / 2 - 20,
        size.height - trunkHeight * 0.4,
        size.width / 2 + 20,
        size.height - trunkHeight * 0.7,
        size.width / 2,
        size.height - trunkHeight,
      );
    canvas.drawPath(trunkPath, trunkPaint);

    final leafPaint = Paint()..style = PaintingStyle.fill;
    final leafCount = (100 + leafRichness * 200).toInt();
    for (var i = 0; i < leafCount; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final radius =
          size.width * 0.18 + growthFactor * 90 * _random.nextDouble();
      final centerX = size.width / 2 + radius * math.cos(angle);
      final centerY =
          size.height - trunkHeight - radius * 0.6 * math.sin(angle.abs());
      final leafColor = Color.lerp(
        const Color(0xFFFFF59D),
        const Color(0xFFFFAB00),
        _random.nextDouble(),
      );
      leafPaint.color = leafColor ?? const Color(0xFFFFD54F);
      canvas.drawCircle(
        Offset(centerX, centerY),
        4 + growthFactor * 4,
        leafPaint,
      );
    }

    final sparklePaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final sparkleCount = (25 * sparkleIntensity).toInt();
    for (var i = 0; i < sparkleCount; i++) {
      final t = (sparklePhase + i / 30) % 1.0;
      final x = size.width * (0.3 + 0.4 * math.sin(t * math.pi * 2 + i));
      final y = size.height * (0.3 + 0.4 * math.cos(t * math.pi * 2 + i));
      final radius = 1.5 + math.sin(t * math.pi) * 2 * sparkleIntensity;
      canvas.drawCircle(Offset(x, y), radius, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GoldenTreePainter oldDelegate) {
    return oldDelegate.growthFactor != growthFactor ||
        oldDelegate.sparklePhase != sparklePhase;
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6D4C41),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF4E342E),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  final int value;
  final String label;

  const _CountdownUnit({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4E342E),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF8D6E63))),
      ],
    );
  }
}

class _Milestone {
  final String label;
  final double amount;

  const _Milestone({required this.label, required this.amount});
}
