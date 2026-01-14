import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/sync_settings.dart';
import '../../services/ibkr_service.dart';

class SyncSettingsScreen extends StatefulWidget {
  final String userId;

  const SyncSettingsScreen({super.key, required this.userId});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  late final IbkrService _ibkrService;
  final _tokenController = TextEditingController();
  final _queryIdController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  SyncSettings? _settings;

  // Локальний стан для switches
  bool _isAutoSyncEnabled = false;
  bool _syncOnMarketOpen = true;
  bool _syncOnMarketClose = true;
  bool _showToken = false;

  @override
  void initState() {
    super.initState();
    _ibkrService = IbkrService(userId: widget.userId);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _ibkrService.getSyncSettings();
      setState(() {
        _settings = settings;
        _tokenController.text = settings.ibkrToken ?? '';
        _queryIdController.text = settings.queryId ?? '';
        _isAutoSyncEnabled = settings.isAutoSyncEnabled;
        _syncOnMarketOpen = settings.syncOnMarketOpen;
        _syncOnMarketClose = settings.syncOnMarketClose;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Помилка завантаження: $e');
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      final newSettings = SyncSettings(
        ibkrToken: _tokenController.text.trim(),
        queryId: _queryIdController.text.trim(),
        isAutoSyncEnabled: _isAutoSyncEnabled,
        syncOnMarketOpen: _syncOnMarketOpen,
        syncOnMarketClose: _syncOnMarketClose,
        lastSyncTime: _settings?.lastSyncTime,
        lastSyncStatus: _settings?.lastSyncStatus,
      );

      await _ibkrService.saveSyncSettings(newSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Налаштування збережено'),
            backgroundColor: Color(0xFF00C853),
          ),
        );
      }
    } catch (e) {
      _showError('Помилка збереження: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _testConnection() async {
    if (_tokenController.text.isEmpty || _queryIdController.text.isEmpty) {
      _showError('Введіть токен та Query ID');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Зберігаємо налаштування
      await _saveSettings();

      // Створюємо тестовий звіт для перевірки
      final reportId = await _ibkrService.createReport(
        name: 'Тестовий звіт ${DateTime.now().day}.${DateTime.now().month}',
        queryId: _queryIdController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🚀 Тест запущено! ID: $reportId'),
            backgroundColor: Colors.blueAccent,
          ),
        );
      }
    } catch (e) {
      _showError('Помилка тесту: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _queryIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('Налаштування синхронізації'),
        backgroundColor: const Color(0xFF1A1A1A),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save, color: Color(0xFF00C853)),
              onPressed: _saveSettings,
            ),
        ],
      ),
      body: SafeArea(
        top: false, // AppBar вже обробляє верх
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === СЕКЦІЯ: IBKR CREDENTIALS ===
                  _buildSectionHeader('🔑 IBKR Доступ'),
                  const SizedBox(height: 12),
                  _buildCredentialsCard(),

                  const SizedBox(height: 24),

                  // === СЕКЦІЯ: РОЗКЛАД ===
                  _buildSectionHeader('⏰ Розклад синхронізації'),
                  const SizedBox(height: 12),
                  _buildScheduleCard(),

                  const SizedBox(height: 24),

                  // === СЕКЦІЯ: СТАТУС ===
                  _buildSectionHeader('📊 Статус'),
                  const SizedBox(height: 12),
                  _buildStatusCard(),

                  const SizedBox(height: 24),

                  // === КНОПКИ ===
                  _buildActionButtons(),

                  const SizedBox(height: 32),

                  // === ІНСТРУКЦІЯ ===
                  _buildInstructionsCard(),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCredentialsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // IBKR Token
          TextField(
            controller: _tokenController,
            obscureText: !_showToken,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'IBKR Flex Token',
              labelStyle: const TextStyle(color: Colors.grey),
              hintText: 'Ваш Flex Query Token',
              hintStyle: TextStyle(color: Colors.grey[700]),
              prefixIcon: const Icon(Icons.key, color: Color(0xFFD4AF37)),
              suffixIcon: IconButton(
                icon: Icon(
                  _showToken ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => _showToken = !_showToken),
              ),
              filled: true,
              fillColor: const Color(0xFF0F0F0F),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Query ID
          TextField(
            controller: _queryIdController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Query ID',
              labelStyle: const TextStyle(color: Colors.grey),
              hintText: 'ID вашого Flex Query',
              hintStyle: TextStyle(color: Colors.grey[700]),
              prefixIcon: const Icon(Icons.numbers, color: Color(0xFFD4AF37)),
              filled: true,
              fillColor: const Color(0xFF0F0F0F),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // Головний перемикач
          SwitchListTile(
            title: const Text(
              'Автоматична синхронізація',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _isAutoSyncEnabled ? 'Увімкнено' : 'Вимкнено',
              style: TextStyle(
                color: _isAutoSyncEnabled ? const Color(0xFF00C853) : Colors.grey,
              ),
            ),
            value: _isAutoSyncEnabled,
            onChanged: (value) => setState(() => _isAutoSyncEnabled = value),
            activeColor: const Color(0xFF00C853),
            secondary: Icon(
              _isAutoSyncEnabled ? Icons.sync : Icons.sync_disabled,
              color: _isAutoSyncEnabled ? const Color(0xFF00C853) : Colors.grey,
            ),
          ),

          if (_isAutoSyncEnabled) ...[
            const Divider(color: Colors.white10),

            // Синхронізація при відкритті ринку
            SwitchListTile(
              title: const Text(
                'При відкритті ринку',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                '🕤 9:30 AM ET (NYSE)',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              value: _syncOnMarketOpen,
              onChanged: (value) => setState(() => _syncOnMarketOpen = value),
              activeColor: const Color(0xFF00C853),
              secondary: const Icon(Icons.wb_sunny, color: Colors.orangeAccent),
            ),

            // Синхронізація при закритті ринку
            SwitchListTile(
              title: const Text(
                'При закритті ринку',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                '🕓 4:00 PM ET (NYSE)',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              value: _syncOnMarketClose,
              onChanged: (value) => setState(() => _syncOnMarketClose = value),
              activeColor: const Color(0xFF00C853),
              secondary: const Icon(Icons.nightlight_round, color: Colors.blueAccent),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final lastSync = _settings?.lastSyncTime;
    final lastStatus = _settings?.lastSyncStatus;
    final lastError = _settings?.lastError;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: lastError != null ? Colors.redAccent.withOpacity(0.5) : Colors.white10,
        ),
      ),
      child: Column(
        children: [
          _buildStatusRow(
            'Остання синхронізація',
            IbkrService.formatLastSyncTime(lastSync),
            Icons.access_time,
          ),
          const Divider(color: Colors.white10),
          _buildStatusRow(
            'Статус',
            lastStatus ?? 'Не синхронізовано',
            lastError != null ? Icons.error : Icons.check_circle,
            color: lastError != null ? Colors.redAccent : const Color(0xFF00C853),
          ),
          if (lastError != null) ...[
            const Divider(color: Colors.white10),
            _buildStatusRow(
              'Помилка',
              lastError,
              Icons.warning,
              color: Colors.orangeAccent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, IconData icon,
      {Color color = Colors.grey}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  value,
                  style: TextStyle(color: color, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _testConnection,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Тест з\'єднання'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('Зберегти'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFD4AF37)),
              SizedBox(width: 8),
              Text(
                'Як налаштувати Flex Query',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionStep('1', 'Увійдіть в IBKR Portal'),
          _buildInstructionStep('2', 'Reports → Flex Queries'),
          _buildInstructionStep('3', 'Створіть Activity Flex Query'),
          _buildInstructionStep('4', 'Виберіть період: "One Business Day"'),
          _buildInstructionStep('5', 'Скопіюйте Token та Query ID'),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
