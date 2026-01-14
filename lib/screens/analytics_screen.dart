import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/ibkr_data.dart';
import '../services/ai_tax_service.dart';
import '../services/cloud_firestore_service.dart';
import '../services/secure_storage_service.dart';
import '../widgets/future_simulator_widget.dart';
import 'ibkr_connection_screen.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _performanceData;
  List<IBKRReport>? _reports;
  String? _error;
  Map<String, dynamic>? _aiTaxAnalysis;
  bool _isCalculatingTaxes = false;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check if we have IBKR credentials
      final hasCredentials = await SecureStorageService.hasIbkrCredentials();

      if (!hasCredentials) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Load performance data and reports
      final performanceData =
          await CloudFirestoreService.getPortfolioPerformance();
      final reports = await CloudFirestoreService.getAllIbkrReports();

      setState(() {
        _performanceData = performanceData;
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Помилка завантаження аналітики: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateTaxesWithAI() async {
    if (_reports == null || _reports!.isEmpty) return;

    setState(() {
      _isCalculatingTaxes = true;
    });

    try {
      final taxAnalysis = await AiTaxService.calculateUkrainianTaxes(
        reports: _reports!,
        taxProfile: 'Резидент України',
        militaryTaxRate: 0.05, // 5% Military tax (Law 4015-IX)
        pitRate: 0.18, // 18%
      );

      setState(() {
        _aiTaxAnalysis = taxAnalysis;
        _isCalculatingTaxes = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Податковий аналіз завершено!'),
            backgroundColor: Color(0xFF43A047),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isCalculatingTaxes = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка розрахунку податків: $e'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Аналітика'),
        backgroundColor: const Color(0xFF0D0D0D),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_performanceData != null)
            IconButton(
              onPressed: _loadAnalyticsData,
              icon: const Icon(Icons.refresh),
              tooltip: 'Оновити дані',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1E88E5)),
            SizedBox(height: 16),
            Text(
              'Завантаження аналітики...',
              style: TextStyle(color: Color(0xFFB0B0B0)),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFE53935)),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFFE53935)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAnalyticsData,
              child: const Text('Повторити'),
            ),
          ],
        ),
      );
    }

    if (_performanceData == null || _reports == null || _reports!.isEmpty) {
      return _buildConnectIbkrScreen();
    }

    return _buildAnalyticsContent();
  }

  Widget _buildConnectIbkrScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Color(0xFF1E88E5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Потрібні дані для аналітики',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Підключіть Interactive Brokers для перегляду\nаналітики портфеля та податків',
            style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => const IbkrConnectionScreen(),
                ),
              );
              if (result == true) {
                _loadAnalyticsData();
              }
            },
            icon: const Icon(Icons.link),
            label: const Text('Підключити IBKR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Симулятор майбутнього
          const FutureSimulatorWidget(),

          const SizedBox(height: 20),

          // Portfolio Performance Overview
          Card(
            color: const Color(0xFF1F1F1F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF1F1F1F), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Показники портфеля',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Поточна вартість',
                          '\$${_formatCurrency(_performanceData!['currentValue'])}',
                          _performanceData!['changePercent'] >= 0
                              ? const Color(0xFF43A047)
                              : const Color(0xFFE53935),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          'Зміна',
                          '${_performanceData!['changePercent'] >= 0 ? '+' : ''}${_performanceData!['changePercent'].toStringAsFixed(2)}%',
                          _performanceData!['changePercent'] >= 0
                              ? const Color(0xFF43A047)
                              : const Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Performance Chart
          Card(
            color: const Color(0xFF1F1F1F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF1F1F1F), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Динаміка портфеля',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(height: 200, child: _buildPerformanceChart()),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tax Overview
          Card(
            color: const Color(0xFF1F1F1F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF1F1F1F), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Податковий огляд',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (_aiTaxAnalysis == null)
                        ElevatedButton.icon(
                          onPressed: _isCalculatingTaxes
                              ? null
                              : _calculateTaxesWithAI,
                          icon: _isCalculatingTaxes
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(
                            _isCalculatingTaxes ? 'Аналіз...' : 'AI Аналіз',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_aiTaxAnalysis != null)
                    _buildAiTaxAnalysis()
                  else
                    _buildTaxOverview(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Reports History
          Card(
            color: const Color(0xFF1F1F1F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF1F1F1F), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Історія звітів',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_reports!.length} звітів',
                        style: const TextStyle(
                          color: Color(0xFFB0B0B0),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._reports!
                      .take(5)
                      .map((report) => _buildReportItem(report)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    final dataPoints =
        _performanceData!['dataPoints'] as List<Map<String, dynamic>>;

    if (dataPoints.isEmpty) {
      return const Center(
        child: Text(
          'Недостатньо даних для графіка',
          style: TextStyle(color: Color(0xFFB0B0B0)),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xFF1F1F1F)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: dataPoints.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                (entry.value['value'] as num).toDouble(),
              );
            }).toList(),
            isCurved: true,
            color: const Color(0xFF1E88E5),
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxOverview() {
    // Calculate estimated taxes (simplified for demo)
    final currentValue = _performanceData!['currentValue'] as double;
    final previousValue = _performanceData!['previousValue'] as double;
    final profit = currentValue - previousValue;

    // Ukrainian tax rates (simplified)
    const pitRate = 0.18; // 18% PIT
    const militaryRate = 0.05; // 5% Military tax (Law 4015-IX)
    const totalTaxRate = pitRate + militaryRate;

    final estimatedTax = profit > 0 ? profit * totalTaxRate : 0.0;

    return Column(
      children: [
        _buildTaxItem(
          'ПДФО (18%)',
          '\$${(profit * pitRate).toStringAsFixed(2)}',
          const Color(0xFF1E88E5),
        ),
        _buildTaxItem(
          'Військовий збір (5%)',
          '\$${(profit * militaryRate).toStringAsFixed(2)}',
          const Color(0xFFFB8C00),
        ),
        _buildTaxItem(
          'Загальний податок',
          '\$${estimatedTax.toStringAsFixed(2)}',
          const Color(0xFF43A047),
        ),
      ],
    );
  }

  Widget _buildAiTaxAnalysis() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E88E5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFF1E88E5),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AI-аналіз податків завершено',
                  style: TextStyle(
                    color: Color(0xFF1E88E5),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'Оновлено: ${_formatDate(DateTime.now())}',
                style: const TextStyle(color: Color(0xFF757575), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildTaxOverview(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF43A047).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Рекомендації:',
                style: TextStyle(
                  color: Color(0xFF43A047),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• Розглянути оптимізацію термінів закриття позицій\n• Використати податкові збитки для зменшення навантаження\n• Конвертувати дивіденди в гривню за вигідним курсом',
                style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportItem(IBKRReport report) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDate(report.uploadDate),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${report.positions.length} активів',
                style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
              ),
            ],
          ),
          Text(
            '\$${_formatCurrency(report.lastBalance)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTaxItem(String title, String amount, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
