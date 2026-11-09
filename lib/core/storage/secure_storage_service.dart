import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppConstants {
  static const _StorageKeys storageKeys = _StorageKeys();
}

class _StorageKeys {
  const _StorageKeys();

  final String accessToken = 'access_token';
  final String refreshToken = 'refresh_token';
  final String userProfile = 'user_profile';
  final String appLocale = 'app_locale';
}

/// خدمة مركزية للتعامل مع Secure Storage
/// تُستخدم لتخزين JWT Access/Refresh Tokens وبيانات المستخدم بأمان
class SecureStorageService {
  SecureStorageService._internal();
  static final SecureStorageService instance = SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ---------------- Tokens ----------------
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: AppConstants.storageKeys.accessToken, value: token);

  Future<String?> getAccessToken() =>
      _storage.read(key: AppConstants.storageKeys.accessToken);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: AppConstants.storageKeys.refreshToken, value: token);

  Future<String?> getRefreshToken() =>
      _storage.read(key: AppConstants.storageKeys.refreshToken);

  // ---------------- User profile (raw JSON string) ----------------
  Future<void> saveUserProfile(String jsonString) => _storage.write(
      key: AppConstants.storageKeys.userProfile, value: jsonString);

  Future<String?> getUserProfile() =>
      _storage.read(key: AppConstants.storageKeys.userProfile);

  // ---------------- Locale / Theme (اختياري تخزينها هنا أو في SharedPreferences) ----------------
  Future<void> saveLocale(String localeCode) => _storage.write(
      key: AppConstants.storageKeys.appLocale, value: localeCode);

  Future<String?> getLocale() =>
      _storage.read(key: AppConstants.storageKeys.appLocale);

  // ---------------- Clear (تسجيل الخروج) ----------------
  Future<void> clearSession() async {
    await _storage.delete(key: AppConstants.storageKeys.accessToken);
    await _storage.delete(key: AppConstants.storageKeys.refreshToken);
    await _storage.delete(key: AppConstants.storageKeys.userProfile);
  }

  Future<void> clearAll() => _storage.deleteAll();
}
