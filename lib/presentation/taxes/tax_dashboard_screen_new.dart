import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/remote/firestore_service.dart';
import '../../domain/models/custom_portfolio_models.dart';
import '../../domain/models/ibkr_data.dart';
import '../../domain/models/user_tax_profile.dart';
import '../../providers/investment_snapshot_provider.dart';
import '../../services/pdf_export_service.dart';
import '../../services/tax_calculation_service.dart';
import '../widgets/tax_profile_banner.dart';
import 'widgets/tax_summary_grid.dart';
import 'widgets/tax_trades_list.dart';

class TaxDashboardScreen extends ConsumerStatefulWidget {
  final String userId;
  final int year;

  const TaxDashboardScreen({
    super.key,
    required this.userId,
    required this.year,
  });

  @override
  ConsumerState<TaxDashboardScreen> createState() => _TaxDashboardScreenState();
}

class _TaxDashboardScreenState extends ConsumerState<TaxDashboardScreen> {
  final _taxService = TaxCalculationService();
  final _pdfService = PdfExportService();
  final _firestore = FirestoreService();

  late int _selectedYear;
  int _profileRevision = 0;
  bool _isExporting = false;
  UserTaxProfile? _cachedProfile;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.year;
  }

  List<int> get _availableYears {
    final current = DateTime.now().year;
    return List<int>.generate(5, (index) => current - index);
  }

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(investmentSnapshotProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Податковий дашборд')),
      body: snapshotAsync.when(
        loading: () => const _CenteredLoader(),
        error: (err, stack) => _ErrorState(message: err.toString()),
        data: (snapshot) {
          if (snapshot == null) {
            return const _ErrorState(
              message: 'Потрібно синхронізувати портфель з IBKR',
            );
          }

          return FutureBuilder<_TaxComputationResult>(
            future: _computeTaxData(snapshot, _profileRevision),
            builder: (context, taxSnap) {
              if (taxSnap.connectionState == ConnectionState.waiting) {
                return const _CenteredLoader();
              }
              if (taxSnap.hasError) {
                return _ErrorState(message: taxSnap.error.toString());
              }
              final result = taxSnap.data;
              if (result == null) {
                return const _ErrorState(message: 'Дані недоступні');
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _profileRevision++;
                  });
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildYearSelector(),
                      const SizedBox(height: 16),
                      _SnapshotHighlightsCard(snapshot: snapshot),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TaxProfileBanner(profile: result.taxProfile),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () =>
                                _showProfileEditor(result.taxProfile),
                            icon: const Icon(Icons.edit),
                            label: const Text('Редагувати'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TaxSummaryGrid(
                        report: result.yearlyReport,
                        potential: result.potentialReport,
                      ),
                      const SizedBox(height: 16),
                      _buildDividendCard(result),
                      const SizedBox(height: 16),
                      _buildCapitalGainsCard(result),
                      const SizedBox(height: 16),
                      if (result.yearlyReport.matches.isEmpty)
                        _PlaceholderCard(
                          title: 'Немає проданих угод у $_selectedYear році',
                          subtitle:
                              'Коли ви зафіксуєте прибуток, тут з’явиться детальна аналітика FIFO.',
                        )
                      else
                        TaxTradesList(
                          matches: result.yearlyReport.matches,
                          year: _selectedYear,
                        ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _isExporting
                              ? null
                              : () => _exportPdf(result),
                          icon: _isExporting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.picture_as_pdf),
                          label: const Text('Експортувати PDF'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildYearSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Податковий рік', style: Theme.of(context).textTheme.titleMedium),
        DropdownButton<int>(
          value: _selectedYear,
          items: _availableYears
              .map(
                (year) => DropdownMenuItem<int>(
                  value: year,
                  child: Text(year.toString()),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedYear = value;
              _profileRevision++;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDividendCard(_TaxComputationResult result) {
    final hasDividends = result.dividends.isNotEmpty;
    final numberFormat = NumberFormat.currency(
      locale: 'uk_UA',
      symbol: '₴',
      decimalDigits: 2,
    );

    if (!hasDividends) {
      return const _PlaceholderCard(
        title: 'Дивіденди відсутні',
        subtitle:
            'Як тільки ви отримаєте виплати, Мідас автоматично порахує податок.',
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Дивідендні податки',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(
                    'ПДФО ${result.dividendPitRate * 100}% + ВЗ ${result.dividendMilitaryRate * 100}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricTile(
                  label: 'Отримано дивідендів',
                  value: numberFormat.format(result.dividendGross),
                ),
                _MetricTile(
                  label: 'Утримано брокером',
                  value: numberFormat.format(result.dividendWithheld),
                ),
                _MetricTile(
                  label: 'ПДФО 18%',
                  value: numberFormat.format(result.dividendPitAmount),
                ),
                _MetricTile(
                  label: 'Військовий збір 5%',
                  value: numberFormat.format(result.dividendMilitaryAmount),
                ),
                _MetricTile(
                  label: result.dividendDue >= 0 ? 'Доплата' : 'Переплата',
                  value: numberFormat.format(result.dividendDue),
                  valueColor: result.dividendDue > 0
                      ? Colors.orange
                      : Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapitalGainsCard(_TaxComputationResult result) {
    final report = result.yearlyReport;
    final numberFormat = NumberFormat.currency(locale: 'uk_UA', symbol: '₴');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Продажі цінних паперів (FIFO)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Податок ${(report.taxRate * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricTile(
                  label: 'Дохід від продажів',
                  value: numberFormat.format(report.grossProceedsUah),
                ),
                _MetricTile(
                  label: 'Собівартість',
                  value: numberFormat.format(report.totalCostsUah),
                ),
                _MetricTile(
                  label: 'Прибуток',
                  value: numberFormat.format(report.netProfitUah),
                  valueColor: report.netProfitUah >= 0
                      ? Colors.green
                      : Colors.redAccent,
                ),
                _MetricTile(
                  label: 'Орієнтовний податок',
                  value: numberFormat.format(report.estimatedTaxUah),
                  valueColor: Colors.redAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<_TaxComputationResult> _computeTaxData(
    InvestmentSnapshot snapshot,
    int revision,
  ) async {
    final reports = await _firestore.getReports(widget.userId).first;
    if (reports.isEmpty) {
      throw Exception('Немає синхронізованих звітів IBKR');
    }

    final latestReport = _pickLatest(reports);
    final profile =
        _cachedProfile ??
        await _firestore.getUserTaxProfile(widget.userId) ??
        _defaultProfile();
    _cachedProfile ??= profile;

    final yearlyReport = _taxService.calculateYearlyTaxReport(
      trades: latestReport.trades,
      year: _selectedYear,
      taxProfile: profile,
    );

    final dividends = latestReport.dividends
        .where((d) => d.date.year == _selectedYear)
        .toList();
    final processedDividends = dividends
        .map(
          (d) => ProcessedDividend(
            assetSymbol: d.symbol,
            date: d.date,
            grossAmount: d.grossAmount,
            taxWithheld: d.withholdingTax,
          ),
        )
        .toList();

    final rates = _resolveRates(profile);
    final grossDividends = dividends.fold<double>(
      0,
      (sum, d) => sum + d.grossAmount,
    );
    final withheld = dividends.fold<double>(
      0,
      (sum, d) => sum + d.withholdingTax,
    );
    final pitAmount = grossDividends * rates.pit;
    final militaryAmount = grossDividends * rates.military;
    final dividendDue = (pitAmount + militaryAmount) - withheld;

    final potentialReport = PotentialTaxReport(
      unrealizedProfitUah: 0,
      estimatedTaxUah: yearlyReport.estimatedTaxUah,
      taxRate: yearlyReport.taxRate,
      holdings: const [],
      warnings: yearlyReport.warnings,
    );

    return _TaxComputationResult(
      yearlyReport: yearlyReport,
      potentialReport: potentialReport,
      taxProfile: profile,
      ibkrReport: latestReport,
      dividends: dividends,
      processedDividends: processedDividends,
      dividendGross: grossDividends,
      dividendWithheld: withheld,
      dividendPitAmount: pitAmount,
      dividendMilitaryAmount: militaryAmount,
      dividendDue: dividendDue,
      dividendPitRate: rates.pit,
      dividendMilitaryRate: rates.military,
    );
  }

  Future<void> _exportPdf(_TaxComputationResult result) async {
    setState(() {
      _isExporting = true;
    });
    try {
      await _pdfService.exportTaxReport(
        trades: result.ibkrReport.trades,
        year: _selectedYear,
        matches: result.yearlyReport.matches,
        dividends: result.processedDividends,
        dividendPitRate: result.dividendPitRate,
        dividendMilitaryRate: result.dividendMilitaryRate,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Помилка експорту: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  IBKRReport _pickLatest(List<IBKRReport> reports) {
    return reports.reduce((a, b) {
      final timeA = a.lastSyncTime ?? a.uploadDate;
      final timeB = b.lastSyncTime ?? b.uploadDate;
      return timeB.isAfter(timeA) ? b : a;
    });
  }

  UserTaxProfile _defaultProfile() {
    return UserTaxProfile(
      name: 'Олександр',
      profile: TaxProfile.civilian,
      isMilitaryExemptionActive: false,
      updatedAt: DateTime.now(),
    );
  }

  _TaxRates _resolveRates(UserTaxProfile profile) {
    switch (profile.profile) {
      case TaxProfile.military:
        return const _TaxRates(pit: 0.18, military: 0.0);
      case TaxProfile.fop3:
        return const _TaxRates(pit: 0.05, military: 0.01);
      case TaxProfile.civilian:
        return _TaxRates(
          pit: 0.18,
          military: profile.isMilitaryExemptionActive ? 0.0 : 0.05,
        );
    }
  }

  Future<void> _showProfileEditor(UserTaxProfile profile) async {
    final nameController = TextEditingController(text: profile.name);
    TaxProfile tempProfile = profile.profile;
    bool isExempt = profile.isMilitaryExemptionActive;

    final updated = await showModalBottomSheet<UserTaxProfile>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Налаштування податкового профілю',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Ім'я для звіту",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Тип профілю'),
                  Column(
                    children: TaxProfile.values
                        .map(
                          (p) => RadioListTile<TaxProfile>(
                            value: p,
                            groupValue: tempProfile,
                            onChanged: (val) {
                              if (val == null) return;
                              setModalState(() {
                                tempProfile = val;
                              });
                            },
                            title: Text(p.displayName),
                            subtitle: Text(p.description),
                          ),
                        )
                        .toList(),
                  ),
                  if (tempProfile == TaxProfile.civilian) ...[
                    SwitchListTile(
                      value: isExempt,
                      onChanged: (val) {
                        setModalState(() {
                          isExempt = val;
                        });
                      },
                      title: const Text('Пільга з військового збору'),
                    ),
                  ] else
                    const SizedBox.shrink(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Скасувати'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final updatedProfile = UserTaxProfile(
                              name: nameController.text.trim().isEmpty
                                  ? profile.name
                                  : nameController.text.trim(),
                              profile: tempProfile,
                              isMilitaryExemptionActive:
                                  tempProfile == TaxProfile.civilian
                                  ? isExempt
                                  : false,
                              updatedAt: DateTime.now(),
                            );
                            Navigator.pop(context, updatedProfile);
                          },
                          child: const Text('Зберегти'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (updated != null) {
      await _firestore.saveUserTaxProfile(widget.userId, updated);
      setState(() {
        _cachedProfile = updated;
        _profileRevision++;
      });
    }
  }
}

class _SnapshotHighlightsCard extends StatelessWidget {
  final InvestmentSnapshot snapshot;

  const _SnapshotHighlightsCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.currency(
      locale: 'uk_UA',
      symbol: '₴',
      decimalDigits: 0,
    );
    final summary = snapshot.accountSummary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _MetricTile(
              label: 'Поточна вартість портфеля',
              value: numberFormat.format(summary.currentBalance),
            ),
            _MetricTile(
              label: 'Прибуток / збиток',
              value: numberFormat.format(summary.totalProfitLoss),
              valueColor: summary.totalProfitLoss >= 0
                  ? Colors.green
                  : Colors.redAccent,
            ),
            _MetricTile(
              label: 'Річна доходність',
              value: '${summary.totalYieldPercentage.toStringAsFixed(1)}%',
            ),
            _MetricTile(
              label: 'Пасивний дохід 12м',
              value:
                  '${summary.annualPassiveIncomePercentage.toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricTile({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PlaceholderCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message, textAlign: TextAlign.center));
  }
}

class _TaxComputationResult {
  final YearlyTaxReport yearlyReport;
  final PotentialTaxReport potentialReport;
  final UserTaxProfile taxProfile;
  final IBKRReport ibkrReport;
  final List<IBKRDividend> dividends;
  final List<ProcessedDividend> processedDividends;
  final double dividendGross;
  final double dividendWithheld;
  final double dividendPitAmount;
  final double dividendMilitaryAmount;
  final double dividendDue;
  final double dividendPitRate;
  final double dividendMilitaryRate;

  const _TaxComputationResult({
    required this.yearlyReport,
    required this.potentialReport,
    required this.taxProfile,
    required this.ibkrReport,
    required this.dividends,
    required this.processedDividends,
    required this.dividendGross,
    required this.dividendWithheld,
    required this.dividendPitAmount,
    required this.dividendMilitaryAmount,
    required this.dividendDue,
    required this.dividendPitRate,
    required this.dividendMilitaryRate,
  });
}

class _TaxRates {
  final double pit;
  final double military;

  const _TaxRates({required this.pit, required this.military});
}
