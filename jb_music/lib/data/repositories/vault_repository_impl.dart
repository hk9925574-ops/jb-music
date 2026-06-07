import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jb_music/domain/repositories/vault_repository.dart';

class VaultRepositoryImpl implements VaultRepository {
  final FlutterSecureStorage _secureStorage;

  // Constructor handles passing storage instances with hardware preference flags
  VaultRepositoryImpl({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true, // Uses hardware-backed cryptographic keys
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  @override
  Future<void> secureSave(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      throw Exception("Cryptographic Vault Write Failure: $e");
    }
  }

  @override
  Future<String?> secureRead(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      throw Exception("Cryptographic Vault Read Failure: $e");
    }
  }

  @override
  Future<void> secureDelete(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      throw Exception("Cryptographic Vault Deletion Failure: $e");
    }
  }

  @override
  Future<void> clearEntireVault() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      throw Exception("Cryptographic Vault Hard Reset Failure: $e");
    }
  }
}