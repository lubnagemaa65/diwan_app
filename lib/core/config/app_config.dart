/// إعدادات عامة على مستوى التطبيق.
///
/// [useMockData] هو المفتاح الرئيسي: عندما يكون `true`، تعمل كل الـ Repositories
/// (Auth, Assets, Maintenance, Users) على بيانات وهمية محلية بدل الاتصال الفعلي
/// بالـ API عبر Dio. هذا يسمح بتجربة كل شاشات التطبيق (تسجيل الدخول، لوحة التحكم،
/// الأصول، الصيانة...) دون الحاجة لتشغيل الباك إند فعليًا.
///
/// للعودة للعمل مع الباك إند الحقيقي `university-assets-api`، غيّر القيمة إلى `false`
/// فقط — لا حاجة لتعديل أي شاشة أو Provider، لأن التبديل يحدث داخل طبقة الـ Repository.
class AppConfig {
  AppConfig._();

  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: true,
  );

  /// مدة تأخير اصطناعية لمحاكاة زمن استجابة الشبكة في وضع Mock
  /// (تجعل شاشات التحميل/الـ Skeleton تظهر بشكل طبيعي أثناء العرض التجريبي)
  static const Duration mockNetworkDelay = Duration(milliseconds: 600);
}
