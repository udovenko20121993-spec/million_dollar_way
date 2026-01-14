import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for secure storage of sensitive data
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _ibkrTokenKey = 'ibkr_token';
  static const String _ibkrQueryIdKey = 'ibkr_query_id';

  /// Check if IBKR credentials are stored
  static Future<bool> hasIbkrCredentials() async {
    try {
      final token = await _storage.read(key: _ibkrTokenKey);
      final queryId = await _storage.read(key: _ibkrQueryIdKey);
      return token != null && token.isNotEmpty &&
          queryId != null && queryId.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get IBKR token
  static Future<String?> getIbkrToken() async {
    return await _storage.read(key: _ibkrTokenKey);
  }

  /// Get IBKR query ID
  static Future<String?> getIbkrQueryId() async {
    return await _storage.read(key: _ibkrQueryIdKey);
  }

  /// Save IBKR credentials
  static Future<void> saveIbkrCredentials({
    required String token,
    required String queryId,
  }) async {
    await _storage.write(key: _ibkrTokenKey, value: token);
    await _storage.write(key: _ibkrQueryIdKey, value: queryId);
  }

  /// Clear IBKR credentials
  static Future<void> clearIbkrCredentials() async {
    await _storage.delete(key: _ibkrTokenKey);
    await _storage.delete(key: _ibkrQueryIdKey);
  }
}
