/// Model representing a taxpayer profile
class TaxpayerProfile {
  final String fullName;
  final String rnokpp; // Tax identification number
  final bool isFop; // Is individual entrepreneur
  final int? fopGroup; // FOP tax group (1, 2, or 3)
  final double taxRate;
  final bool hasVat;
  final double yearlyRevenue;
  final DateTime lastSync;
  final List<String> taxTypes;
  final Map<String, dynamic> additionalData;

  TaxpayerProfile({
    required this.fullName,
    required this.rnokpp,
    required this.isFop,
    this.fopGroup,
    required this.taxRate,
    required this.hasVat,
    required this.yearlyRevenue,
    required this.lastSync,
    this.taxTypes = const [],
    this.additionalData = const {},
  });

  factory TaxpayerProfile.fromMap(Map<String, dynamic> map) {
    return TaxpayerProfile(
      fullName: map['fullName']?.toString() ?? '',
      rnokpp: map['rnokpp']?.toString() ?? '',
      isFop: map['isFop'] as bool? ?? false,
      fopGroup: map['fopGroup'] as int?,
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.0,
      hasVat: map['hasVat'] as bool? ?? false,
      yearlyRevenue: (map['yearlyRevenue'] as num?)?.toDouble() ?? 0.0,
      lastSync: map['lastSync'] != null
          ? DateTime.tryParse(map['lastSync'].toString()) ?? DateTime.now()
          : DateTime.now(),
      taxTypes: List<String>.from(map['taxTypes'] as Iterable? ?? []),
      additionalData: Map<String, dynamic>.from(
        map['additionalData'] as Map? ?? {},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'rnokpp': rnokpp,
      'isFop': isFop,
      'fopGroup': fopGroup,
      'taxRate': taxRate,
      'hasVat': hasVat,
      'yearlyRevenue': yearlyRevenue,
      'lastSync': lastSync.toIso8601String(),
      'taxTypes': taxTypes,
      'additionalData': additionalData,
    };
  }
}
