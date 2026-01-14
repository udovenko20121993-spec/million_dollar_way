import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Сервіс для завантаження та кешування логотипів акцій
class StockLogoService {
  static final StockLogoService _instance = StockLogoService._internal();
  factory StockLogoService() => _instance;
  StockLogoService._internal();

  // Кеш логотипів в пам'яті
  final Map<String, String> _logoCache = {};
  
  // Мапа символів до доменів компаній (для Clearbit)
  static const Map<String, String> _symbolToDomain = {
    // Технології
    'AAPL': 'apple.com',
    'MSFT': 'microsoft.com',
    'GOOGL': 'google.com',
    'GOOG': 'google.com',
    'AMZN': 'amazon.com',
    'META': 'meta.com',
    'NVDA': 'nvidia.com',
    'TSLA': 'tesla.com',
    'AMD': 'amd.com',
    'INTC': 'intel.com',
    'CRM': 'salesforce.com',
    'ORCL': 'oracle.com',
    'ADBE': 'adobe.com',
    'NFLX': 'netflix.com',
    'PYPL': 'paypal.com',
    'CSCO': 'cisco.com',
    'IBM': 'ibm.com',
    'QCOM': 'qualcomm.com',
    'TXN': 'ti.com',
    'AVGO': 'broadcom.com',
    'NOW': 'servicenow.com',
    'UBER': 'uber.com',
    'ABNB': 'airbnb.com',
    'SQ': 'squareup.com',
    'SHOP': 'shopify.com',
    'SNAP': 'snap.com',
    'TWTR': 'twitter.com',
    'X': 'x.com',
    'SPOT': 'spotify.com',
    'ZM': 'zoom.us',
    'DOCU': 'docusign.com',
    'PLTR': 'palantir.com',
    
    // Фінанси
    'JPM': 'jpmorganchase.com',
    'BAC': 'bankofamerica.com',
    'WFC': 'wellsfargo.com',
    'C': 'citigroup.com',
    'GS': 'goldmansachs.com',
    'MS': 'morganstanley.com',
    'BLK': 'blackrock.com',
    'SCHW': 'schwab.com',
    'V': 'visa.com',
    'MA': 'mastercard.com',
    'AXP': 'americanexpress.com',
    'COF': 'capitalone.com',
    
    // Споживчі товари
    'KO': 'coca-cola.com',
    'PEP': 'pepsico.com',
    'WMT': 'walmart.com',
    'COST': 'costco.com',
    'HD': 'homedepot.com',
    'LOW': 'lowes.com',
    'TGT': 'target.com',
    'MCD': 'mcdonalds.com',
    'SBUX': 'starbucks.com',
    'NKE': 'nike.com',
    'DIS': 'disney.com',
    'PG': 'pg.com',
    'JNJ': 'jnj.com',
    'UNH': 'unitedhealthgroup.com',
    'PFE': 'pfizer.com',
    'MRK': 'merck.com',
    'ABBV': 'abbvie.com',
    'LLY': 'lilly.com',
    'TMO': 'thermofisher.com',
    
    // Енергетика
    'XOM': 'exxonmobil.com',
    'CVX': 'chevron.com',
    'COP': 'conocophillips.com',
    'SLB': 'slb.com',
    'OXY': 'oxy.com',
    
    // Телекомунікації
    'T': 'att.com',
    'VZ': 'verizon.com',
    'TMUS': 't-mobile.com',
    
    // Промисловість
    'BA': 'boeing.com',
    'CAT': 'caterpillar.com',
    'DE': 'deere.com',
    'GE': 'ge.com',
    'HON': 'honeywell.com',
    'UPS': 'ups.com',
    'FDX': 'fedex.com',
    'MMM': '3m.com',
    'LMT': 'lockheedmartin.com',
    'RTX': 'rtx.com',
    
    // Нерухомість / REITs
    'O': 'realtyincome.com',
    'AMT': 'americantower.com',
    'PLD': 'prologis.com',
    'EQIX': 'equinix.com',
    'SPG': 'simon.com',
    
    // ETF
    'SPY': 'ssga.com',
    'QQQ': 'invesco.com',
    'VTI': 'vanguard.com',
    'VOO': 'vanguard.com',
    'IVV': 'ishares.com',
    'VIG': 'vanguard.com',
    'SCHD': 'schwab.com',
    'VYM': 'vanguard.com',
    'JEPI': 'jpmorganfunds.com',
  };

  /// Отримати URL логотипу для символу
  String getLogoUrl(String symbol) {
    final upperSymbol = symbol.toUpperCase();
    
    // Перевіряємо кеш
    if (_logoCache.containsKey(upperSymbol)) {
      return _logoCache[upperSymbol]!;
    }
    
    // Шукаємо домен
    final domain = _symbolToDomain[upperSymbol];
    
    if (domain != null) {
      // Clearbit Logo API - безкоштовно
      final url = 'https://logo.clearbit.com/$domain';
      _logoCache[upperSymbol] = url;
      return url;
    }
    
    // Якщо домен невідомий, повертаємо порожній
    return '';
  }

  /// Отримати всі логотипи для списку символів
  Map<String, String> getLogosForSymbols(List<String> symbols) {
    final logos = <String, String>{};
    for (final symbol in symbols) {
      final url = getLogoUrl(symbol);
      if (url.isNotEmpty) {
        logos[symbol] = url;
      }
    }
    return logos;
  }

  /// Перевірити чи доступний логотип (запит HEAD)
  Future<bool> isLogoAvailable(String symbol) async {
    final url = getLogoUrl(symbol);
    if (url.isEmpty) return false;
    
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Завантажити та кешувати логотип у Firestore (для офлайн доступу)
  Future<void> cacheLogoToFirestore(String symbol, String userId) async {
    final url = getLogoUrl(symbol);
    if (url.isEmpty) return;
    
    try {
      // Завантажуємо зображення
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return;
      
      // Конвертуємо в base64
      final base64Image = base64Encode(response.bodyBytes);
      
      // Зберігаємо в Firestore
      await FirebaseFirestore.instance
          .collection('stockLogos')
          .doc(symbol.toUpperCase())
          .set({
        'symbol': symbol.toUpperCase(),
        'url': url,
        'base64': base64Image,
        'contentType': response.headers['content-type'] ?? 'image/png',
        'cachedAt': FieldValue.serverTimestamp(),
      });
      
    } catch (e) {
      print('Error caching logo for $symbol: $e');
    }
  }

  /// Отримати логотип з Firestore кешу
  Future<Uint8List?> getCachedLogo(String symbol) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('stockLogos')
          .doc(symbol.toUpperCase())
          .get();
      
      if (!doc.exists) return null;
      
      final base64Image = doc.data()?['base64'] as String?;
      if (base64Image == null) return null;
      
      return base64Decode(base64Image);
    } catch (e) {
      return null;
    }
  }

  /// Додати власний домен для символу
  void addCustomDomain(String symbol, String domain) {
    _logoCache[symbol.toUpperCase()] = 'https://logo.clearbit.com/$domain';
  }

  /// Перевірити чи є домен для символу
  bool hasDomain(String symbol) {
    return _symbolToDomain.containsKey(symbol.toUpperCase());
  }

  /// Отримати кількість відомих символів
  int get knownSymbolsCount => _symbolToDomain.length;
}

/// Віджет для відображення логотипу акції
class StockLogo extends StatelessWidget {
  final String symbol;
  final double size;
  final Color? backgroundColor;
  final Color? fallbackColor;

  const StockLogo({
    super.key,
    required this.symbol,
    this.size = 40,
    this.backgroundColor,
    this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    final logoService = StockLogoService();
    final url = logoService.getLogoUrl(symbol);

    if (url.isEmpty) {
      return _buildFallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 4),
      child: Container(
        width: size,
        height: size,
        color: backgroundColor ?? Colors.white,
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoading();
          },
        ),
      ),
    );
  }

  Widget _buildFallback() {
    // Генеруємо колір на основі символу
    final color = fallbackColor ?? _getColorForSymbol(symbol);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(size / 4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Center(
        child: Text(
          symbol.length > 2 ? symbol.substring(0, 2) : symbol,
          style: TextStyle(
            color: color,
            fontSize: size / 2.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Center(
        child: SizedBox(
          width: size / 2,
          height: size / 2,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Color _getColorForSymbol(String symbol) {
    // Хешуємо символ для генерації кольору
    final hash = symbol.hashCode;
    final colors = [
      const Color(0xFFD4AF37), // Золотий
      const Color(0xFF00C853), // Зелений
      const Color(0xFF2196F3), // Синій
      const Color(0xFFFF5722), // Помаранчевий
      const Color(0xFF9C27B0), // Фіолетовий
      const Color(0xFFE91E63), // Рожевий
      const Color(0xFF00BCD4), // Бірюзовий
      const Color(0xFFFF9800), // Жовтогарячий
    ];
    return colors[hash.abs() % colors.length];
  }
}

/// Віджет рядка з логотипом акції
class StockLogoTile extends StatelessWidget {
  final String symbol;
  final String? name;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const StockLogoTile({
    super.key,
    required this.symbol,
    this.name,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: StockLogo(symbol: symbol, size: 44),
      title: Text(
        name ?? symbol,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
