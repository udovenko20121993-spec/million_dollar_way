import 'package:shared_preferences/shared_preferences.dart';

enum TaxStatus {
  privateIndividual('Приватна особа'),
  fopGroup1('ФОП 1 група'),
  fopGroup2('ФОП 2 група'),
  fopGroup3('ФОП 3 група');

  const TaxStatus(this.displayName);
  final String displayName;
}

class TaxProfileService {
  static TaxProfileService? _instance;
  static TaxProfileService get instance => _instance ??= TaxProfileService._();

  TaxProfileService._();

  static const String _keyTaxStatus = 'tax_status';
  static const String _keyTaxRate = 'tax_rate';
  static const String _keyIsVatPayer = 'is_vat_payer';
  static const String _keyStrategyMode = 'investment_strategy_mode';

  TaxStatus? _taxStatus;
  double? _taxRate;
  bool? _isVatPayer;
  String _investmentStrategyMode = 'Действие';

  // Getters
  TaxStatus? get taxStatus => _taxStatus;
  double? get taxRate => _taxRate;
  bool? get isVatPayer => _isVatPayer;
  String get investmentStrategyMode => _investmentStrategyMode;

  // Initialize and load saved settings
  Future<void> initialize() async {
    await loadSettings();
  }

  // Load settings from SharedPreferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load tax status
      final statusIndex = prefs.getInt(_keyTaxStatus);
      if (statusIndex != null &&
          statusIndex >= 0 &&
          statusIndex < TaxStatus.values.length) {
        _taxStatus = TaxStatus.values[statusIndex];
      } else {
        _taxStatus = TaxStatus.privateIndividual; // Default
      }

      // Load tax rate
      _taxRate =
          prefs.getDouble(_keyTaxRate) ??
          18.0; // Default for private individual

      // Load VAT payer status
      _isVatPayer = prefs.getBool(_keyIsVatPayer) ?? false; // Default

      // Load strategy mode
      _investmentStrategyMode = prefs.getString(_keyStrategyMode) ?? 'Действие';

      print(
        '✅ Tax profile loaded: ${_taxStatus?.displayName}, Rate: $_taxRate%, VAT: $_isVatPayer',
      );
    } catch (e) {
      print('❌ Error loading tax profile: $e');
      // Set defaults if loading fails
      _taxStatus = TaxStatus.privateIndividual;
      _taxRate = 18.0;
      _isVatPayer = false;
    }
  }

  Future<void> saveInvestmentStrategyMode(String mode) async {
    final normalized = mode == 'Ребаланс' ? 'Ребаланс' : 'Действие';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyStrategyMode, normalized);
      _investmentStrategyMode = normalized;
    } catch (e) {
      print('❌ Error saving investment strategy mode: $e');
    }
  }

  String getInvestmentStrategyMode() {
    return _investmentStrategyMode;
  }

  // Save tax status
  Future<void> saveTaxStatus(TaxStatus status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyTaxStatus, status.index);
      _taxStatus = status;
      print('✅ Tax status saved: ${status.displayName}');
    } catch (e) {
      print('❌ Error saving tax status: $e');
    }
  }

  // Save tax rate
  Future<void> saveTaxRate(double rate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyTaxRate, rate);
      _taxRate = rate;
      print('✅ Tax rate saved: $rate%');
    } catch (e) {
      print('❌ Error saving tax rate: $e');
    }
  }

  // Save VAT payer status
  Future<void> saveVatPayerStatus(bool isVatPayer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsVatPayer, isVatPayer);
      _isVatPayer = isVatPayer;
      print('✅ VAT payer status saved: $isVatPayer');
    } catch (e) {
      print('❌ Error saving VAT payer status: $e');
    }
  }

  // Get tax profile description for AI
  String getTaxProfileDescription() {
    if (_taxStatus == null || _taxRate == null || _isVatPayer == null) {
      return 'Профіль не налаштовано';
    }

    String vatStatus = _isVatPayer! ? 'є платником ПДВ' : 'не є платником ПДВ';
    return 'Користувач: ${_taxStatus!.displayName}, ставка податку: $_taxRate%, $vatStatus';
  }

  // Get recommended tax rate based on status
  double getRecommendedTaxRate() {
    switch (_taxStatus) {
      case TaxStatus.privateIndividual:
        return 18.0; // ПДФО
      case TaxStatus.fopGroup1:
        return 10.0; // ЄСВ 10%
      case TaxStatus.fopGroup2:
        return 20.0; // ЄСВ 20%
      case TaxStatus.fopGroup3:
        return 5.0; // 5% з обороту
      case null:
        return 18.0; // Default
    }
  }

  // Clear all settings
  Future<void> clearSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyTaxStatus);
      await prefs.remove(_keyTaxRate);
      await prefs.remove(_keyIsVatPayer);

      _taxStatus = TaxStatus.privateIndividual;
      _taxRate = 18.0;
      _isVatPayer = false;

      print('✅ Tax profile settings cleared');
    } catch (e) {
      print('❌ Error clearing tax profile: $e');
    }
  }
}
