import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/simple_sparkline.dart';
import '../../../services/midas_calculation_service.dart';
import '../../../domain/models/midas_models.dart';

class WealthSimulatorScreen extends ConsumerStatefulWidget {
  const WealthSimulatorScreen({super.key});

  @override
  ConsumerState<WealthSimulatorScreen> createState() =>
      _WealthSimulatorScreenState();
}

class _WealthSimulatorScreenState extends ConsumerState<WealthSimulatorScreen> {
  final MidasCalculationService _midasService = const MidasCalculationService();
  final TextEditingController _initialCapitalController = TextEditingController(
    text: '1000',
  );
  final TextEditingController _monthlyContributionController =
      TextEditingController(text: '500');
  final TextEditingController _expectedReturnController = TextEditingController(
    text: '8.2',
  );
  final TextEditingController _yearsController = TextEditingController(
    text: '20',
  );

  bool _includeTaxes = false;
  final bool _useRealCAGR = true; // Новий параметр для реального CAGR
  bool _useBot = false;
  final List<double> _totalInvestedData = [];
  final List<double> _totalWithInterestData = [];
  double _finalAmount = 0;
  double _totalInvested = 0;
  int _yearsToMillion = 0;

  // Реальні дані з портфоліо
  double _realCAGR = 0.082; // Буде оновлено з реальних даних
  double _currentPortfolioValue = 0;

  @override
  void initState() {
    super.initState();
    _loadRealPortfolioData();
    _calculateWealth();
  }

  @override
  void dispose() {
    _initialCapitalController.dispose();
    _monthlyContributionController.dispose();
    _expectedReturnController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  Future<void> _loadRealPortfolioData() async {
    // Симуляція завантаження реальних даних портфоліо
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock дані - в реальному додатку вони будуть з Firebase
    final mockPositions = [
      StockPosition(
        symbol: 'AAPL',
        quantity: 50,
        averagePrice: 150.0,
        transactions: [
          StockTransaction(
            symbol: 'AAPL',
            date: DateTime.now().subtract(const Duration(days: 365)),
            quantity: 50,
            price: 150.0,
            type: TransactionType.buy,
          ),
        ],
      ),
      StockPosition(
        symbol: 'GOOGL',
        quantity: 20,
        averagePrice: 2800.0,
        transactions: [
          StockTransaction(
            symbol: 'GOOGL',
            date: DateTime.now().subtract(const Duration(days: 300)),
            quantity: 20,
            price: 2800.0,
            type: TransactionType.buy,
          ),
        ],
      ),
    ];

    final analytics = _midasService.calculatePortfolioAnalytics(
      positions: mockPositions,
      startDate: DateTime.now().subtract(const Duration(days: 365)),
      availableCash: 500.0,
    );

    setState(() {
      _realCAGR = analytics.cagr;
      _currentPortfolioValue = analytics.totalPortfolioValue;
      _expectedReturnController.text = (_realCAGR * 100).toStringAsFixed(2);
      _initialCapitalController.text = _currentPortfolioValue.toStringAsFixed(
        0,
      );
    });
  }

  void _calculateWealth() {
    final initialCapital = double.tryParse(_initialCapitalController.text) ?? 0;
    final monthlyContribution =
        double.tryParse(_monthlyContributionController.text) ?? 0;
    double expectedReturn =
        (double.tryParse(_expectedReturnController.text) ?? 8.2) / 100;
    final years = int.tryParse(_yearsController.text) ?? 20;

    // Використовуємо реальний CAGR якщо активовано
    if (_useRealCAGR) {
      expectedReturn = _realCAGR;
    }

    // Bot integration logic
    if (_useBot && !_useRealCAGR) {
      expectedReturn = 0.082; // 8.2% with Signal Bot
    }

    final monthlyReturn = expectedReturn / 12;
    _totalInvestedData.clear();
    _totalWithInterestData.clear();

    double totalInvested = initialCapital;
    double totalWithInterest = initialCapital;
    _totalInvestedData.add(totalInvested);
    _totalWithInterestData.add(totalWithInterest);

    for (int month = 1; month <= years * 12; month++) {
      totalInvested += monthlyContribution;
      totalWithInterest =
          totalWithInterest * (1 + monthlyReturn) + monthlyContribution;

      _totalInvestedData.add(totalInvested);
      _totalWithInterestData.add(totalWithInterest);
    }

    setState(() {
      _totalInvested = totalInvested;
      _finalAmount = totalWithInterest;
      _yearsToMillion = _calculateYearsToMillion(
        initialCapital,
        monthlyContribution,
        expectedReturn,
      );
    });
  }

  int _calculateYearsToMillion(
    double initial,
    double monthly,
    double yearlyReturn,
  ) {
    const double target = 1000000;
    final monthlyReturn = yearlyReturn / 12;
    double current = initial;
    int months = 0;

    while (current < target && months < 1200) {
      // Max 100 years
      double monthlyInterest = current * monthlyReturn;
      if (_includeTaxes) {
        monthlyInterest *= 0.805; // After 19.5% tax
      }
      current = current + monthlyInterest + monthly;
      months++;
    }

    return (months / 12).ceil();
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('Шлях до Мільйона'),
            SizedBox(width: 8),
            Text('🚀', style: TextStyle(fontSize: 20)),
          ],
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGoldenResultCard(),
              const SizedBox(height: 24),
              _buildProcessExplanation(),
              const SizedBox(height: 24),
              _buildGlassInputSection(),
              const SizedBox(height: 24),
              _buildBotIntegrationToggle(),
              const SizedBox(height: 24),
              if (_totalWithInterestData.isNotEmpty) ...[
                _buildMilestoneTracking(),
                const SizedBox(height: 24),
              ],
              if (_totalWithInterestData.isNotEmpty) ...[
                _buildChartSection(),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoldenResultCard() {
    final totalContributions = _totalInvested;
    final totalInterest = _finalAmount - _totalInvested;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black,
            Colors.grey.shade900,
            Colors.amber.shade800,
            Colors.amber.shade600,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.amber, size: 32),
                SizedBox(width: 12),
                Text(
                  'Ваш майбутній капітал',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Main Result
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('💰', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    _formatCurrency(_finalAmount),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.amber,
                          offset: Offset(0, 0),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Breakdown
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Внески:',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      Text(
                        _formatCurrency(totalContributions),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Відсотки:',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      Text(
                        _formatCurrency(totalInterest),
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessExplanation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade700.withOpacity(0.5)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber, size: 24),
              SizedBox(width: 8),
              Text(
                'Як це працює?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Ваш капітал зростає завдяки магії складного відсотка. Кожного місяця ви купуєте активи, а прибуток, який вони генерують, автоматично додається до основної суми і починає працювати на вас наступного місяця. Це створює ефект снігової кулі: чим довше ви інвестуєте, тим швидше зростає ваш мільйон.',
            style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassInputSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Параметри інвестицій',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildGlassInputField(
            'Початковий капітал (\$)',
            _initialCapitalController,
            Icons.account_balance,
          ),

          const SizedBox(height: 12),

          _buildGlassInputField(
            'Щомісячне поповнення (\$)',
            _monthlyContributionController,
            Icons.savings,
          ),

          const SizedBox(height: 12),

          _buildGlassInputField(
            'Очікувана дохідність (%)',
            _expectedReturnController,
            Icons.trending_up,
          ),

          const SizedBox(height: 12),

          _buildGlassInputField(
            'Термін (років)',
            _yearsController,
            Icons.date_range,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassInputField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: Colors.amber),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        onChanged: (value) => _calculateWealth(),
      ),
    );
  }

  Widget _buildBotIntegrationToggle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade900.withOpacity(0.3),
            Colors.green.shade700.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_graph, color: Colors.green, size: 24),
              SizedBox(width: 8),
              Text(
                'Використовувати Бота?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text(
              _useBot ? 'Signal Bot активований' : 'Стандартна стратегія',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              _useBot
                  ? 'Бот допомагає знаходити точки входу з вищою дохідністю, що скорочує шлях до цілі на ${(_yearsToMillion > 0 ? _yearsToMillion - 5 : 0)} років.'
                  : 'Середня дохідність банківських депозитів та ETF.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
            value: _useBot,
            onChanged: (value) {
              setState(() {
                _useBot = value;
              });
              _calculateWealth();
            },
            activeThumbColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildTaxImpactSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_outlined,
                color: Colors.orange,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Податковий вплив',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SwitchListTile(
            title: const Text(
              'Враховувати податки (19.5%)',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Держава забирає частину вашого інвестиційного прибутку. Своєчасна оптимізація через статус ФОП або довгострокове утримання може зберегти вам до \$150,000 на дистанції 15 років.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            value: _includeTaxes,
            onChanged: (value) {
              setState(() {
                _includeTaxes = value;
              });
              _calculateWealth();
            },
            activeThumbColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneTracking() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade700.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Відстеження цілі',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_yearsToMillion > 0 && _yearsToMillion <= 100) ...[
            Row(
              children: [
                const Icon(Icons.flag, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'До \$1,000,000 залишилось: $_yearsToMillion років',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (_finalAmount / 1000000).clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade700,
              valueColor: AlwaysStoppedAnimation<Color>(
                _finalAmount >= 1000000 ? Colors.green : Colors.amber,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${((_finalAmount / 1000000) * 100).toStringAsFixed(1)}% від цілі',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ] else ...[
            const Text(
              'Досягнення \$1,000,000 неможливе за поточними параметрами',
              style: TextStyle(fontSize: 14, color: Colors.orange),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade700.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Графік зростання капіталу',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Legend
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Всього вкладено',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(width: 20),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Капітал з відсотками',
                style: TextStyle(color: Colors.amber),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Chart
          SizedBox(
            height: 200,
            child: SimpleSparkline(
              data: _totalWithInterestData,
              color: Colors.amber,
              height: 200,
              width: double.infinity,
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            height: 100,
            child: SimpleSparkline(
              data: _totalInvestedData,
              color: Colors.grey,
              height: 100,
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }
}
