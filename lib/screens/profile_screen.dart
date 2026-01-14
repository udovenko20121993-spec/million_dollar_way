import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/dps_integration_service.dart';
import '../../services/sts_api_service.dart';
import '../../services/tax_profile_service.dart';
import '../../models/taxpayer_profile.dart';
import '../widgets/security_info_dialog.dart';

/// Екран профілю користувача з синхронізацією ДПС
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final DpsIntegrationService _dpsService = DpsIntegrationService.instance;
  final StsApiService _stsService = StsApiService.instance;
  final TaxProfileService _taxProfileService = TaxProfileService.instance;

  bool _isSyncing = false;
  bool _isAuthenticating = false;
  bool _isDiiaAuthenticating = false;
  TaxpayerProfile? _profile;
  String _selectedProfile = 'civilian';

  // Manual tax profile state
  TaxStatus? _selectedTaxStatus;
  double? _selectedTaxRate;
  bool? _selectedVatPayer;

  @override
  void initState() {
    super.initState();
    _loadCachedProfile();
    _loadTaxProfile();
  }

  void _loadTaxProfile() async {
    await _taxProfileService.initialize();
    setState(() {
      _selectedTaxStatus = _taxProfileService.taxStatus;
      _selectedTaxRate = _taxProfileService.taxRate;
      _selectedVatPayer = _taxProfileService.isVatPayer;
    });
  }

  void _loadCachedProfile() {
    setState(() {
      _profile = _dpsService.cachedProfile ?? _stsService.cachedProfile;

      // Автоматично налаштовуємо калькулятор на основі DPS даних
      if (_profile != null) {
        if (_profile!.isFop) {
          _selectedProfile = 'fop3';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Профіль'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: const Color(0xFFD4AF37),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showSecurityInfo,
            icon: const Icon(Icons.security, color: Color(0xFFD4AF37)),
            tooltip: 'Безпека даних',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAuthStatus(),
            const SizedBox(height: 24),
            _buildManualTaxProfile(),
            const SizedBox(height: 24),
            if (_profile != null) _buildTaxpayerInfo(),
            const SizedBox(height: 24),
            _buildSyncButton(),
            const SizedBox(height: 16),
            _buildSecurityNotice(),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthStatus() {
    final authInfo = _dpsService.authInfo;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (authInfo.status) {
      case DpsAuthStatus.authenticated:
        statusColor = Colors.green;
        statusIcon = Icons.verified_user;
        statusText = 'Автентифіковано в ДПС';
        break;
      case DpsAuthStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Автентифікація...';
        break;
      case DpsAuthStatus.expired:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Сесія закінчилась';
        break;
      case DpsAuthStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        statusText = 'Помилка автентифікації';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.person_outline;
        statusText = 'Не автентифіковано';
    }

    return Card(
      color: const Color(0xFF1A1A1A),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Статус ДПС',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (authInfo.expiresAt != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Діє до:',
                    style: TextStyle(color: Colors.grey[400], fontSize: 10),
                  ),
                  Text(
                    '${authInfo.expiresAt!.hour.toString().padLeft(2, '0')}:${authInfo.expiresAt!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualTaxProfile() {
    return Card(
      color: const Color(0xFF1F1F1F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF1F1F1F), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person_outline, color: Color(0xFF1E88E5), size: 24),
                SizedBox(width: 12),
                Text(
                  'Налаштування податкового профілю',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tax Status Selection
            const Text(
              'Статус:',
              style: TextStyle(
                color: Color(0xFFB0B0B0),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1F1F1F)),
              ),
              child: DropdownButton<TaxStatus>(
                value: _selectedTaxStatus,
                hint: const Text(
                  'Оберіть статус',
                  style: TextStyle(color: Color(0xFFB0B0B0)),
                ),
                dropdownColor: const Color(0xFF1F1F1F),
                style: const TextStyle(color: Colors.white),
                items: TaxStatus.values.map((status) {
                  return DropdownMenuItem<TaxStatus>(
                    value: status,
                    child: Text(
                      status.displayName,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (TaxStatus? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedTaxStatus = newValue;
                      // Auto-set recommended tax rate
                      _selectedTaxRate = _taxProfileService
                          .getRecommendedTaxRate();
                    });
                    _taxProfileService.saveTaxStatus(newValue);
                  }
                },
              ),
            ),

            const SizedBox(height: 20),

            // Tax Rate Input
            const Text(
              'Ставка податку (%):',
              style: TextStyle(
                color: Color(0xFFB0B0B0),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1F1F1F)),
              ),
              child: TextField(
                controller: TextEditingController(
                  text: _selectedTaxRate?.toString(),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Введіть ставку податку',
                  hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
                ),
                onChanged: (value) {
                  final rate = double.tryParse(value);
                  if (rate != null && rate >= 0 && rate <= 100) {
                    setState(() {
                      _selectedTaxRate = rate;
                    });
                    _taxProfileService.saveTaxRate(rate);
                  }
                },
              ),
            ),

            const SizedBox(height: 20),

            // VAT Payer Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Платник ПДВ:',
                  style: TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Switch(
                  value: _selectedVatPayer ?? false,
                  onChanged: (value) {
                    setState(() {
                      _selectedVatPayer = value;
                    });
                    _taxProfileService.saveVatPayerStatus(value);
                  },
                  activeThumbColor: const Color(0xFF1E88E5),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Current Profile Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D).withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF1E88E5).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Поточний профіль:',
                    style: TextStyle(
                      color: Color(0xFF1E88E5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _taxProfileService.getTaxProfileDescription(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxpayerInfo() {
    if (_profile == null) return const SizedBox.shrink();

    return Card(
      color: const Color(0xFF1A1A1A),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Color(0xFFD4AF37)),
                const SizedBox(width: 8),
                const Text(
                  'Дані платника податків',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_profile!.needsSync)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Потрібна синхронізація',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('ПІБ:', _profile!.fullName),
            _buildInfoRow('РНОКПП:', _profile!.rnokpp),
            _buildInfoRow('Статус:', _profile!.isFop ? 'ФОП' : 'Фізична особа'),
            if (_profile!.isFop) ...[
              _buildInfoRow('Група ФОП:', _profile!.fopGroupDescription),
              _buildInfoRow('Ставка:', _profile!.taxRateDescription),
            ],
            _buildInfoRow('ПДВ:', _profile!.hasVat ? 'Є' : 'Немає'),
            _buildInfoRow(
              'Річний дохід:',
              '${_profile!.yearlyRevenue.toStringAsFixed(0)} грн',
            ),
            _buildInfoRow(
              'Остання синхронізація:',
              '${_profile!.lastSync.day.toString().padLeft(2, '0')}.${_profile!.lastSync.month.toString().padLeft(2, '0')} ${_profile!.lastSync.hour.toString().padLeft(2, '0')}:${_profile!.lastSync.minute.toString().padLeft(2, '0')}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncButton() {
    final dpsAuthInfo = _dpsService.authInfo;
    final stsAuthInfo = _stsService.isAuthenticated;

    return Column(
      children: [
        // Преміум кнопка Дія.Підпис
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0066CC), Color(0xFF004499)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0066CC).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _isDiiaAuthenticating ? null : _authenticateWithDiia,
            icon: _isDiiaAuthenticating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.verified_user, color: Colors.white),
            label: Text(
              _isDiiaAuthenticating
                  ? 'Автентифікація...'
                  : 'Авторизуватися через Дія.Підпис',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Стандартна кнопка ДПС
        if (dpsAuthInfo.status != DpsAuthStatus.authenticated && !stsAuthInfo)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isAuthenticating ? null : _authenticate,
              icon: _isAuthenticating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Icon(Icons.login),
              label: Text(
                _isAuthenticating ? 'Автентифікація...' : 'Увійти через ДПС',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

        // Кнопка синхронізації
        if ((dpsAuthInfo.status == DpsAuthStatus.authenticated ||
                stsAuthInfo) &&
            _profile != null)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isSyncing ? null : _syncData,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Icon(Icons.sync),
              label: Text(
                _isSyncing ? 'Синхронізація...' : 'Синхронізувати дані',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSecurityNotice() {
    final isStsAuthenticated = _stsService.isAuthenticated;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isStsAuthenticated
            ? const Color(0xFF1A3A4A)
            : const Color(0xFF1A3A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isStsAuthenticated
              ? const Color(0xFF0066CC)
              : const Color(0xFF4CAF50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isStsAuthenticated ? Icons.verified_user : Icons.shield,
                color: isStsAuthenticated
                    ? const Color(0xFF0066CC)
                    : const Color(0xFF4CAF50),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isStsAuthenticated
                    ? '🔐 Дія.Підпис активовано'
                    : '🔒 Ваші дані захищені',
                style: TextStyle(
                  color: isStsAuthenticated
                      ? const Color(0xFF0066CC)
                      : const Color(0xFF4CAF50),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isStsAuthenticated
                ? 'Ми не маємо доступу до вашого підпису. Ви лише надаєте дозвіл на читання даних з кабінету ДПС через Дія.Підпис.'
                : 'Ми не зберігаємо ваші паролі. Доступ до даних здійснюється через офіційний API ДПС з тимчасовими токенами.',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showSecurityInfo,
            child: Text(
              isStsAuthenticated
                  ? 'Дізнатися більше про Дія.Підпис →'
                  : 'Дізнатися більше про безпеку →',
              style: TextStyle(
                color: isStsAuthenticated
                    ? const Color(0xFF0066CC)
                    : const Color(0xFF4CAF50),
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _authenticateWithDiia() async {
    setState(() {
      _isDiiaAuthenticating = true;
    });

    try {
      final launched = await _stsService.launchDiiaAuth();

      if (launched) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text(
                '🔐 Автентифікація Дія.Підпис',
                style: TextStyle(color: Color(0xFFD4AF37)),
              ),
              content: const Text(
                'Відкрито браузер для автентифікації.\n\n'
                'Після успішного входу поверніться до додатку для продовження.',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Color(0xFFD4AF37)),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Не вдалося відкрити Дія.Підпис'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Помилка автентифікації: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isDiiaAuthenticating = false;
      });
    }
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
    });

    try {
      await _dpsService.initiateAuth();
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Автентифікація успішна!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Помилка автентифікації: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  Future<void> _syncData() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      TaxSyncResult result;

      // Пріоритет STS (Дія.Підпис)
      if (_stsService.isAuthenticated) {
        result = await _stsService.fullSync();
      } else {
        result = await _dpsService.syncTaxpayerData();
      }

      if (result.success && result.profile != null) {
        setState(() {
          _profile = result.profile;
        });

        if (mounted) {
          String source = _stsService.isAuthenticated
              ? 'STS (Дія.Підпис)'
              : 'ДПС';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Дані синхронізовано з $source: ${result.profile!.fullName}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Помилка синхронізації: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Помилка: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  void _showSecurityInfo() {
    String securityExplanation;

    if (_stsService.isAuthenticated) {
      securityExplanation = _stsService.getDiiaSecurityExplanation();
    } else {
      securityExplanation = _dpsService.getSecurityExplanation();
    }

    showDialog(
      context: context,
      builder: (context) =>
          SecurityInfoDialog(securityExplanation: securityExplanation),
    );
  }
}
