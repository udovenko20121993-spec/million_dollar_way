import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'ai_assistant_service.dart';
import 'cloud_firestore_service.dart';
import 'midas_ai_service.dart';
import '../domain/models/ibkr_data.dart';

enum MidasVisualState {
  euphoria, // Euphoria - прибуток > 2% за добу
  stability, // Stability - ринок спокійний
  anxiety, // Anxiety - ринок падає або податковий борг
  focus, // Focus - знайдена можливість для закупки
}

class MidasCoreParameters {
  final double pulseSpeed; // 0.1 - 2.0
  final double glowIntensity; // 0.1 - 1.0
  final double turbulence; // 0.0 - 1.0

  MidasCoreParameters({
    required this.pulseSpeed,
    required this.glowIntensity,
    required this.turbulence,
  });

  Map<String, dynamic> toJson() {
    return {
      'pulse_speed': pulseSpeed,
      'glow_intensity': glowIntensity,
      'turbulence': turbulence,
    };
  }
}

class MidasAnalysisResult {
  final MidasVisualState visualState;
  final MidasCoreParameters coreParameters;
  final String midasMessage;

  MidasAnalysisResult({
    required this.visualState,
    required this.coreParameters,
    required this.midasMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'visual_state': visualState.name.toUpperCase(),
      'core_parameters': coreParameters.toJson(),
      'midas_message': midasMessage,
    };
  }
}

class MidasStateController {
  static final MidasStateController _instance =
      MidasStateController._internal();
  factory MidasStateController() => _instance;
  MidasStateController._internal();

  final AiAssistantService _aiService = AiAssistantService();
  final CloudFirestoreService _firestore = CloudFirestoreService();
  final MidasAiService _midasAi = MidasAiService();

  final double _totalValue = 0.0;
  double _dailyChange = 0.0;
  double _taxDebt = 0.0;
  double _plPercentage = 0.0;
  bool _marketOpen = false;
  String _userName = "Олександр";

  MidasVisualState _currentState = MidasVisualState.stability;
  MidasAnalysisResult? _lastAnalysis;

  // Getters
  MidasVisualState get currentState => _currentState;
  double get totalValue => _totalValue;
  double get plPercentage => _plPercentage;
  double get dailyChange => _dailyChange;
  double get taxDebt => _taxDebt;
  bool get marketOpen => _marketOpen;
  String get userName => _userName;
  MidasAnalysisResult? get lastAnalysis => _lastAnalysis;

  // Get user name from Firebase
  void _updateUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null) {
      _userName = user!.displayName!.split(' ')[0];
      if (_userName.isEmpty) _userName = "Олександр";
    }
    _midasAi.initializeUser();
  }

  // Update state based on IBKR and tax data
  Future<MidasAnalysisResult> updateState({
    bool includeAIAnalysis = false,
  }) async {
    try {
      _updateUserName();

      // Get latest IBKR report
      final report = await CloudFirestoreService.getLatestIbkrReport();

      if (report != null) {
        // Calculate metrics
        _plPercentage = calculatePLPercentage(report);
        _dailyChange = calculateDailyChange(report);
        _taxDebt = calculateTaxDebt(report);
        _marketOpen = isMarketOpen();

        // Determine visual state
        _currentState = determineVisualState();

        // Generate AI analysis ONLY if explicitly requested
        if (includeAIAnalysis) {
          _lastAnalysis = await _generateMidasAnalysis();
        } else {
          _lastAnalysis = _createDefaultAnalysis();
        }

        return _lastAnalysis!;
      }
    } catch (e) {
      print('Error updating Midas state: $e');
      _currentState = MidasVisualState.stability;
      _lastAnalysis = MidasAnalysisResult(
        visualState: MidasVisualState.stability,
        coreParameters: MidasCoreParameters(
          pulseSpeed: 0.5,
          glowIntensity: 0.3,
          turbulence: 0.1,
        ),
        midasMessage: "$_userName, система відновлює дані...",
      );
    }

    return _lastAnalysis ??
        MidasAnalysisResult(
          visualState: MidasVisualState.stability,
          coreParameters: MidasCoreParameters(
            pulseSpeed: 0.5,
            glowIntensity: 0.3,
            turbulence: 0.1,
          ),
          midasMessage: "$_userName, очікування даних...",
        );
  }

  double calculatePLPercentage(IBKRReport report) {
    final totalValue = report.lastBalance;
    const initialValue = 100000.0; // Assume $100k initial investment

    if (initialValue == 0) return 0.0;

    return ((totalValue - initialValue) / initialValue) * 100;
  }

  double calculateDailyChange(IBKRReport report) {
    // Simplified daily change calculation
    // In real implementation, this would compare with previous day's value
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    return (random - 50) / 100.0; // -0.5% to +0.5%
  }

  double calculateTaxDebt(IBKRReport report) {
    final dividends = report.totalDividends;
    final realizedPL = report.totalWithdrawals - report.totalDeposits;
    final totalIncome = dividends + realizedPL;

    // 18% PIT + 5% Military tax = 23%
    return totalIncome * 0.23;
  }

  bool isMarketOpen() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final hour = now.hour;

    // Market open: Mon-Fri, 9:30 AM - 4:00 PM EST
    if (weekday >= 1 && weekday <= 5) {
      return hour >= 14 && hour < 21; // Converted to local time
    }
    return false;
  }

  MidasVisualState determineVisualState() {
    // Euphoria: прибуток > 2% за добу
    if (_dailyChange > 2.0) {
      return MidasVisualState.euphoria;
    }

    // Anxiety: ринок падає або є податковий борг
    if (_dailyChange < -1.0 || _taxDebt > 1000) {
      return MidasVisualState.anxiety;
    }

    // Focus: знайдена можливість для закупки (спад > 0.5% але < 1%)
    if (_dailyChange < -0.5 && _dailyChange > -1.0) {
      return MidasVisualState.focus;
    }

    // Stability: ринок спокійний
    return MidasVisualState.stability;
  }

  Future<MidasAnalysisResult> _generateMidasAnalysis() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        return _createDefaultAnalysis();
      }

      // Get tax grounding
      final taxGrounding = await _getTaxGrounding();

      // Build context for AI
      final context =
          '''
ПОРТФЕЛЬНИЙ АНАЛІЗ ДЛЯ $_userName:

СТАН ПОРТФЕЛЯ:
- Загальний P&L: ${_plPercentage.toStringAsFixed(2)}%
- Денна зміна: ${_dailyChange.toStringAsFixed(2)}%
- Податковий борг: ${_taxDebt.toStringAsFixed(2)}₴
- Ринок: ${_marketOpen ? 'відкритий' : 'закритий'}

ПОДАТКОВИЙ КОНТЕКСТ:
$taxGrounding

ВИЗУАЛЬНИЙ СТАН: ${_currentState.name.toUpperCase()}

СТВОРИ АНАЛІЗ У ФОРМАТІ JSON:
{
  "visual_state": "EUPHORIA|STABILITY|ANXIETY|FOCUS",
  "core_parameters": {
    "pulse_speed": 0.1-2.0,
    "glow_intensity": 0.1-1.0,
    "turbulence": 0.0-1.0
  },
  "midas_message": "Одне коротке, потужне речення українською для $_userName"
}

Вимоги:
- Використовуй тільки українську мову
- Будь лаконічним та впевненим
- midas_message має бути професійним та мотивуючим
- Параметри мають відповідати візуальному стану
''';

      final response = await _aiService.getResponseWithGrounding(
        userId: userId,
        userQuery: context,
        useLiveLegislation: true,
        useSearchGrounding: true,
      );

      // Parse JSON response
      return _parseAnalysisResponse(response);
    } catch (e) {
      print('Error generating analysis: $e');
      return _createDefaultAnalysis();
    }
  }

  Future<String> _getTaxGrounding() async {
    try {
      // Simulate tax grounding check
      return '''
ПОДАТКОВІ СТАВКИ УКРАЇНИ (актуальні):
- ПДФО: 18%
- Військовий збір: 5%
- Загальний податок на доходи: 23%
Джерело: tax.gov.ua, zakon.rada.gov.ua
''';
    } catch (e) {
      return 'Податкові ставки: ПДФО 18%, Військовий збір 5%';
    }
  }

  MidasAnalysisResult _parseAnalysisResponse(String response) {
    try {
      // Extract JSON from response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;

      if (jsonStart != -1 && jsonEnd != 0) {
        final jsonString = response.substring(jsonStart, jsonEnd);
        final jsonData = json.decode(jsonString) as Map<String, dynamic>;

        final visualStateStr = jsonData['visual_state'] as String;
        final visualState = MidasVisualState.values.firstWhere(
          (state) => state.name.toUpperCase() == visualStateStr,
          orElse: () => MidasVisualState.stability,
        );

        final coreParams = jsonData['core_parameters'] as Map<String, dynamic>;
        final coreParameters = MidasCoreParameters(
          pulseSpeed: (coreParams['pulse_speed'] as num).toDouble().clamp(
            0.1,
            2.0,
          ),
          glowIntensity: (coreParams['glow_intensity'] as num).toDouble().clamp(
            0.1,
            1.0,
          ),
          turbulence: (coreParams['turbulence'] as num).toDouble().clamp(
            0.0,
            1.0,
          ),
        );

        final message = jsonData['midas_message'] as String;

        return MidasAnalysisResult(
          visualState: visualState,
          coreParameters: coreParameters,
          midasMessage: message,
        );
      }
    } catch (e) {
      print('Error parsing JSON response: $e');
    }

    return _createDefaultAnalysis();
  }

  // Separate method for AI analysis - call only on user request
  Future<MidasAnalysisResult> generateAIAnalysis() async {
    try {
      _updateUserName();

      // Get latest IBKR report
      final report = await CloudFirestoreService.getLatestIbkrReport();

      if (report != null) {
        // Calculate metrics
        _plPercentage = calculatePLPercentage(report);
        _dailyChange = calculateDailyChange(report);
        _taxDebt = calculateTaxDebt(report);
        _marketOpen = isMarketOpen();

        // Determine visual state
        _currentState = determineVisualState();

        // Generate AI analysis
        _lastAnalysis = await _generateMidasAnalysis();

        return _lastAnalysis!;
      }
    } catch (e) {
      print('Error generating AI analysis: $e');
      return _createDefaultAnalysis();
    }

    return _createDefaultAnalysis();
  }

  MidasAnalysisResult _createDefaultAnalysis() {
    return MidasAnalysisResult(
      visualState: _currentState,
      coreParameters: _getParametersForState(_currentState),
      midasMessage: "$_userName, аналіз портфеля триває...",
    );
  }

  // Generate AI narrative using MidasAiService
  Future<String> generateMidasNarrative(MidasVisualState visualState) async {
    final portfolioData = {
      'balance': _totalValue * 0.1, // Припустимо 10% готівки
      'totalValue': _totalValue,
      'dailyChange': _dailyChange,
      'taxDebt': _taxDebt,
    };

    // Передаємо назву стану як рядок
    return await _midasAi.generateMidasNarrative(
      visualState.name,
      portfolioData,
    );
  }

  MidasCoreParameters _getParametersForState(MidasVisualState state) {
    switch (state) {
      case MidasVisualState.euphoria:
        return MidasCoreParameters(
          pulseSpeed: 1.8,
          glowIntensity: 0.9,
          turbulence: 0.2,
        );
      case MidasVisualState.anxiety:
        return MidasCoreParameters(
          pulseSpeed: 1.2,
          glowIntensity: 0.4,
          turbulence: 0.8,
        );
      case MidasVisualState.focus:
        return MidasCoreParameters(
          pulseSpeed: 0.8,
          glowIntensity: 0.6,
          turbulence: 0.3,
        );
      case MidasVisualState.stability:
        return MidasCoreParameters(
          pulseSpeed: 0.5,
          glowIntensity: 0.3,
          turbulence: 0.1,
        );
    }
  }

  // Force update for testing
  void setTestState(
    MidasVisualState state,
    double pl,
    double daily,
    double tax,
  ) {
    _currentState = state;
    _plPercentage = pl;
    _dailyChange = daily;
    _taxDebt = tax;
    _lastAnalysis = MidasAnalysisResult(
      visualState: state,
      coreParameters: _getParametersForState(state),
      midasMessage: "Тестовий режим: ${state.toString().split('.').last}",
    );
  }

  // Get JSON output for visual core
  String getVisualCoreJson() {
    if (_lastAnalysis == null) {
      return json.encode(_createDefaultAnalysis().toJson());
    }
    return json.encode(_lastAnalysis!.toJson());
  }
}
