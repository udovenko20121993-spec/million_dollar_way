import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../services/calculator_service.dart';
import '../../services/tax_monitor_service.dart';
import '../../services/dps_integration_service.dart';
import '../../models/tax_config.dart';
import '../../models/taxpayer_profile.dart';
import '../../domain/models/user_tax_profile.dart';

/// Екран калькулятора податків з живими оновленнями та поясненнями
class TaxCalculatorScreen extends ConsumerStatefulWidget {
  const TaxCalculatorScreen({super.key});

  @override
  ConsumerState<TaxCalculatorScreen> createState() =>
      _TaxCalculatorScreenState();
}

class _TaxCalculatorScreenState extends ConsumerState<TaxCalculatorScreen> {
  final _incomeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isCalculating = false;
  TaxCalculationResult? _result;
  TaxConfig _taxConfig = TaxConfig.initial();
  String _selectedProfile = 'civilian';
  bool _militaryExemption = false;
  bool _useDpsData = false;
  TaxpayerProfile? _dpsProfile;

  final DpsIntegrationService _dpsService = DpsIntegrationService.instance;

  @override
  void initState() {
    super.initState();
    _initializeTaxConfig();
  }

  void _initializeTaxConfig() {
    // Підписуємось на оновлення конфігурації
    TaxMonitorService.instance.configStream.listen((config) {
      if (mounted) {
        setState(() {
          _taxConfig = config;
        });
      }
    });

    // Запускаємо моніторинг
    TaxMonitorService.instance.startMonitoring();

    // Завантажуємо DPS профіль
    _loadDpsProfile();
  }

  void _loadDpsProfile() {
    setState(() {
      _dpsProfile = _dpsService.cachedProfile;
      _useDpsData = _dpsProfile != null;

      // Автоматично налаштовуємо калькулятор на основі DPS даних
      if (_dpsProfile != null) {
        _incomeController.text = (_dpsProfile!.yearlyRevenue / 12)
            .toStringAsFixed(0);
        if (_dpsProfile!.isFop) {
          _selectedProfile = 'fop';
        }
      }
    });
  }

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  Future<void> _calculateTaxes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCalculating = true;
      _result = null;
    });

    try {
      double income;
      TaxProfile? profile;

      if (_useDpsData && _dpsProfile != null) {
        // Використовуємо дані з ДПС
        income =
            double.tryParse(_incomeController.text) ??
            (_dpsProfile!.yearlyRevenue / 12);
        profile = _dpsProfile!.isFop ? TaxProfile.fop3 : TaxProfile.civilian;
      } else {
        // Використовуємо ручне введення
        income = double.tryParse(_incomeController.text) ?? 0.0;
        profile = _getTaxProfile(_selectedProfile);
      }

      final result = await CalculatorService.instance.calculateTaxes(
        monthlyIncome: income,
        userId: 'demo_user',
        taxProfile: profile,
        isMilitaryExemptionActive: _militaryExemption,
        taxConfig: _taxConfig,
        taxpayerProfile: _useDpsData ? _dpsProfile : null,
      );

      setState(() {
        _result = result;
        _isCalculating = false;
      });
    } catch (e) {
      setState(() {
        _isCalculating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Помилка розрахунку: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  TaxProfile _getTaxProfile(String profileKey) {
    switch (profileKey) {
      case 'military':
        return TaxProfile.military;
      case 'civilian':
        return TaxProfile.civilian;
      default:
        return TaxProfile.civilian;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Податковий калькулятор'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: const Color(0xFFD4AF37),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTaxConfigStatus(),
            const SizedBox(height: 24),
            _buildDpsOptions(),
            const SizedBox(height: 24),
            _buildIncomeForm(),
            const SizedBox(height: 24),
            if (!_useDpsData) _buildProfileSettings(),
            const SizedBox(height: 24),
            _buildCalculateButton(),
            const SizedBox(height: 24),
            if (_result != null) _buildResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildDpsOptions() {
    return Card(
      color: const Color(0xFF1A1A1A),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance, color: Color(0xFFD4AF37)),
                SizedBox(width: 8),
                Text(
                  'Дані з ДПС',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_dpsProfile != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3A1A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF4CAF50)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_user,
                          color: Color(0xFF4CAF50),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_dpsProfile!.fullName} (${_dpsProfile!.fopGroupDescription})',
                            style: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Річний дохід: ${_dpsProfile!.yearlyRevenue.toStringAsFixed(0)} грн',
                      style: TextStyle(color: Colors.grey[300], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            SwitchListTile(
              title: const Text(
                'Використовувати дані з ДПС',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                _dpsProfile != null
                    ? 'Розрахунок на основі офіційних даних'
                    : 'Спочатку синхронізуйте дані в профілі',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              value: _useDpsData && _dpsProfile != null,
              onChanged: _dpsProfile != null
                  ? (value) {
                      setState(() {
                        _useDpsData = value;
                        if (value && _dpsProfile != null) {
                          _incomeController.text =
                              (_dpsProfile!.yearlyRevenue / 12).toStringAsFixed(
                                0,
                              );
                        }
                      });
                    }
                  : null,
              activeThumbColor: const Color(0xFFD4AF37),
              inactiveThumbColor: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxConfigStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _taxConfig.isLive
            ? const Color(0xFF1A3A1A)
            : const Color(0xFF3A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD4AF37)),
      ),
      child: Row(
        children: [
          Icon(
            _taxConfig.isLive ? Icons.sync : Icons.sync_disabled,
            color: _taxConfig.isLive ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _taxConfig.isLive
                  ? '🔴 Податкові ставки оновлені: ${DateFormat('HH:mm').format(_taxConfig.lastUpdated)}'
                  : '⚠️ Офлайн режим',
              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeForm() {
    return Card(
      color: const Color(0xFF1A1A1A),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Місячний дохід',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _incomeController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Введіть суму доходу',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(
                    Icons.attach_money,
                    color: Color(0xFFD4AF37),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введіть суму доходу';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Введіть коректну суму';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSettings() {
    return Card(
      color: const Color(0xFF1A1A1A),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Податковий профіль',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedProfile,
              style: const TextStyle(color: Colors.white),
              dropdownColor: const Color(0xFF2A2A2A),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'civilian', child: Text('Цивільний')),
                DropdownMenuItem(value: 'military', child: Text('Військовий')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedProfile = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text(
                'Пільга по військовому збору',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Звільнення від сплати військового збору',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              value: _militaryExemption,
              onChanged: (value) {
                setState(() {
                  _militaryExemption = value ?? false;
                });
              },
              activeColor: const Color(0xFFD4AF37),
              checkColor: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isCalculating ? null : _calculateTaxes,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4AF37),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isCalculating
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Розраховую...'),
                ],
              )
            : const Text(
                'Розрахувати податки',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: const Color(0xFF1A1A1A),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Результати розрахунку',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTotalTax(),
                const SizedBox(height: 16),
                _buildTaxBreakdown(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildExplanationSection(),
      ],
    );
  }

  Widget _buildTotalTax() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD4AF37)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Загальний податок:',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          Text(
            '${_result!.totalTax.toStringAsFixed(2)} грн',
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Деталізація:',
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ..._result!.breakdown.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showTaxInfo(entry.key),
                        child: const Icon(
                          Icons.info_outline,
                          color: Color(0xFFD4AF37),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${entry.value.toStringAsFixed(2)} грн',
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildExplanationSection() {
    return Card(
      color: const Color(0xFF1A1A1A),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text(
                  'Як це розраховано?',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFFD4AF37),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _result!.explanation,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_result!.appliedArticles.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Застосовані статті:',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ..._result!.appliedArticles.map(
                    (article) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        '• $article',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTaxInfo(String taxName) async {
    final explanation = await CalculatorService.instance.getTaxExplanation(
      taxName,
    );

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(
            taxName,
            style: const TextStyle(color: Color(0xFFD4AF37)),
          ),
          content: Text(
            explanation,
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Закрити',
                style: TextStyle(color: Color(0xFFD4AF37)),
              ),
            ),
          ],
        ),
      );
    }
  }
}
