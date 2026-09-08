import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'ar_strings.dart';
import 'en_strings.dart';

/// نظام ترجمة بسيط ومباشر (Map-based) يدعم العربية والإنجليزية.
/// الاستخدام: `context.tr('login')`
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('ar'),
    Locale('en'),
  ];

  Map<String, String> get _strings =>
      locale.languageCode == 'ar' ? arStrings : enStrings;

  String translate(String key) => _strings[key] ?? key;

  bool get isArabic => locale.languageCode == 'ar';
  TextDirection get textDirection => isArabic ? TextDirection.rtl : TextDirection.ltr;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// اختصار مريح: `context.tr('key')`
extension LocalizationExtension on BuildContext {
  String tr(String key) => AppLocalizations.of(this).translate(key);
  bool get isArabic => AppLocalizations.of(this).isArabic;
}

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('ar');
  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  void toggle() {
    setLocale(_locale.languageCode == 'ar' ? const Locale('en') : const Locale('ar'));
  }
}
