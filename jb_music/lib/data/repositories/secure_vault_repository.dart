// lib/data/repositories/secure_vault_repository.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jb_music/domain/repositories/vault_repository.dart';

class SecureVaultRepository implements VaultRepository {
  final FlutterSecureStorage _storage;

  SecureVaultRepository()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  // ── Write ──────────────────────────────────────────────────────────────────
  @override
  Future<void> secureSave(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      debugPrint('🔐 Vault saved: "$key"');
    } catch (e) {
      debugPrint('❌ Vault save error [$key]: $e');
      rethrow;
    }
  }

  // ── Read ───────────────────────────────────────────────────────────────────
  @override
  Future<String?> secureRead(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('❌ Vault read error [$key]: $e');
      return null;
    }
  }

  // ── Read with fallback ─────────────────────────────────────────────────────
  Future<String> secureReadOrDefault(String key, String defaultValue) async {
    return (await secureRead(key)) ?? defaultValue;
  }

  // ── Check existence ────────────────────────────────────────────────────────
  Future<bool> hasKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      debugPrint('❌ Vault containsKey error [$key]: $e');
      return false;
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  @override
  Future<void> secureDelete(String key) async {
    try {
      await _storage.delete(key: key);
      debugPrint('🗑️ Vault deleted: "$key"');
    } catch (e) {
      debugPrint('❌ Vault delete error [$key]: $e');
    }
  }

  // ── Read all keys ──────────────────────────────────────────────────────────
  Future<List<String>> getAllKeys() async {
    try {
      final all = await _storage.readAll();
      return all.keys.toList();
    } catch (e) {
      debugPrint('❌ Vault getAllKeys error: $e');
      return [];
    }
  }

  // ── Clear all ──────────────────────────────────────────────────────────────
  @override
  Future<void> clearEntireVault() async {
    try {
      await _storage.deleteAll();
      debugPrint('🧹 Vault cleared');
    } catch (e) {
      debugPrint('❌ Vault clearAll error: $e');
    }
  }
}