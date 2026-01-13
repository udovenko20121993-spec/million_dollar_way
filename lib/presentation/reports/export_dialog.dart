import 'package:flutter/material.dart';
import '../../services/export_service.dart';

class ExportDialog extends StatefulWidget {
  final String userId;
  final String reportId;
  final String reportName;

  const ExportDialog({
    super.key,
    required this.userId,
    required this.reportId,
    required this.reportName,
  });

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  final ExportService _exportService = ExportService();
  
  List<int> _availableYears = [];
  int? _selectedYear;
  bool _isLoading = true;
  bool _isExporting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadYears();
  }

  Future<void> _loadYears() async {
    try {
      final years = await _exportService.getAvailableYears(
        widget.userId,
        widget.reportId,
      );
      setState(() {
        _availableYears = years;
        _selectedYear = years.isNotEmpty ? years.first : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _export(String type) async {
    setState(() => _isExporting = true);

    try {
      switch (type) {
        case 'trades':
          await _exportService.exportTradesToCsv(
            widget.userId,
            widget.reportId,
            year: _selectedYear,
          );
          break;
        case 'dividends':
          await _exportService.exportDividendsToCsv(
            widget.userId,
            widget.reportId,
            year: _selectedYear,
          );
          break;
        case 'cashflow':
          await _exportService.exportCashFlowToCsv(
            widget.userId,
            widget.reportId,
            year: _selectedYear,
          );
          break;
        case 'full':
          if (_selectedYear != null) {
            await _exportService.exportFullTaxReport(
              widget.userId,
              widget.reportId,
              _selectedYear!,
            );
          }
          break;
      }
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Експорт завершено!'),
            backgroundColor: Color(0xFF00C853),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Помилка: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === ЗАГОЛОВОК ===
            _buildHeader(),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              _buildError()
            else ...[
              // === ВИБІР РОКУ ===
              _buildYearSelector(),
              const SizedBox(height: 20),

              // === КНОПКИ ЕКСПОРТУ ===
              _buildExportButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF00C853).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.file_download,
            color: Color(0xFF00C853),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Експорт даних',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.reportName,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          const Text(
            'Рік:',
            style: TextStyle(color: Colors.grey),
          ),
          const Spacer(),
          if (_availableYears.isEmpty)
            const Text(
              'Немає даних',
              style: TextStyle(color: Colors.grey),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<int>(
                value: _selectedYear,
                dropdownColor: const Color(0xFF2C2C2C),
                underline: const SizedBox.shrink(),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00C853)),
                style: const TextStyle(
                  color: Color(0xFF00C853),
                  fontWeight: FontWeight.bold,
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Всі роки'),
                  ),
                  ..._availableYears.map((year) => DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  )),
                ],
                onChanged: (value) => setState(() => _selectedYear = value),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExportButtons() {
    return Column(
      children: [
        // Повний податковий звіт
        if (_selectedYear != null)
          _buildExportButton(
            icon: Icons.description,
            title: 'Річний податковий звіт',
            subtitle: 'Повний звіт для податкової за $_selectedYear рік',
            color: const Color(0xFFD4AF37),
            onTap: () => _export('full'),
          ),
        
        const SizedBox(height: 8),
        
        // Угоди
        _buildExportButton(
          icon: Icons.trending_up,
          title: 'Угоди (CSV)',
          subtitle: 'Всі купівлі та продажі',
          color: Colors.blueAccent,
          onTap: () => _export('trades'),
        ),
        
        const SizedBox(height: 8),
        
        // Дивіденди
        _buildExportButton(
          icon: Icons.payments,
          title: 'Дивіденди (CSV)',
          subtitle: 'Виплати дивідендів з податками',
          color: Colors.orangeAccent,
          onTap: () => _export('dividends'),
        ),
        
        const SizedBox(height: 8),
        
        // Грошові потоки
        _buildExportButton(
          icon: Icons.swap_vert,
          title: 'Грошові потоки (CSV)',
          subtitle: 'Депозити та виведення',
          color: Colors.purpleAccent,
          onTap: () => _export('cashflow'),
        ),
      ],
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isExporting ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (_isExporting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

/// Показати діалог експорту
void showExportDialog(
  BuildContext context, {
  required String userId,
  required String reportId,
  required String reportName,
}) {
  showDialog(
    context: context,
    builder: (ctx) => ExportDialog(
      userId: userId,
      reportId: reportId,
      reportName: reportName,
    ),
  );
}
