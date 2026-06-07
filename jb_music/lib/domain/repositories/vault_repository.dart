// lib/domain/repositories/vault_repository.dart

abstract class VaultRepository {
  /// Securely save a key-value pair
  Future<void> secureSave(String key, String value);

  /// Securely read a value by key — returns null if not found
  Future<String?> secureRead(String key);

  /// Delete a single key from the vault
  Future<void> secureDelete(String key);

  /// Wipe all stored vault data
  Future<void> clearEntireVault();
}