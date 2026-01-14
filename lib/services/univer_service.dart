import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/custom_portfolio_models.dart';

/// Service for managing Univer.ua assets
class UniverService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get all Univer assets for a user
  Future<List<UniverAsset>> getUniverAssets(String userId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('univer_assets')
          .get();

      return snapshot.docs
          .map((doc) => UniverAsset.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      print('Error loading Univer assets: $e');
      return [];
    }
  }

  /// Add a new Univer asset
  Future<void> addUniverAsset(String userId, UniverAsset asset) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('univer_assets')
          .doc(asset.id)
          .set(asset.toFirestore());
    } catch (e) {
      throw Exception('Failed to add Univer asset: $e');
    }
  }

  /// Update an existing Univer asset
  Future<void> updateUniverAsset(String userId, UniverAsset asset) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('univer_assets')
          .doc(asset.id)
          .update(asset.toFirestore());
    } catch (e) {
      throw Exception('Failed to update Univer asset: $e');
    }
  }

  /// Delete a Univer asset
  Future<void> deleteUniverAsset(String userId, String assetId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('univer_assets')
          .doc(assetId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete Univer asset: $e');
    }
  }
}
