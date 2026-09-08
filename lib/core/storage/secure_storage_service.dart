import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

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
      _storage.write(key: StorageKeys.accessToken, value: token);

  Future<String?> getAccessToken() => _storage.read(key: StorageKeys.accessToken);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: StorageKeys.refreshToken, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: StorageKeys.refreshToken);

  // ---------------- User profile (raw JSON string) ----------------
  Future<void> saveUserProfile(String jsonString) =>
      _storage.write(key: StorageKeys.userProfile, value: jsonString);

  Future<String?> getUserProfile() => _storage.read(key: StorageKeys.userProfile);

  // ---------------- Locale / Theme (اختياري تخزينها هنا أو في SharedPreferences) ----------------
  Future<void> saveLocale(String localeCode) =>
      _storage.write(key: StorageKeys.appLocale, value: localeCode);

  Future<String?> getLocale() => _storage.read(key: StorageKeys.appLocale);

  // ---------------- Clear (تسجيل الخروج) ----------------
  Future<void> clearSession() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.delete(key: StorageKeys.userProfile);
  }

  Future<void> clearAll() => _storage.deleteAll();
}
