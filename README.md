# تطبيق إدارة أصول الجامعة (University Assets Management App)

تطبيق Flutter كامل لإدارة أصول الجامعة (حواسيب، طابعات) وطلبات الصيانة، مبني ليترابط
مع باك إند `university-assets-api`، بالاعتماد على الشاشات الفعلية الموجودة في لوحة الإدارة الحالية.

## المعمارية

هيكلة **Feature-first** مبسطة (Clean-ish Architecture):

```
lib/
├── main.dart                  # نقطة الدخول
├── app.dart                   # جذر التطبيق: Providers + MaterialApp + الثيم + الترجمة
├── core/                      # كل ما هو مشترك بين الميزات
│   ├── constants/              # ثوابت API، الأدوار، الحالات
│   ├── network/                 # Dio + Interceptors (Auth/Error) + ApiException
│   ├── storage/                  # Secure Storage (JWT Tokens)
│   ├── theme/                     # AppTheme / AppColors (Material 3)
│   ├── localization/               # عربي/إنجليزي + RTL
│   ├── utils/                        # Validators
│   └── widgets/                       # عناصر واجهة مشتركة (أزرار، حقول، Status Chip...)
├── models/                      # نماذج البيانات (User, Computer, Printer, MaintenanceOrder...)
└── features/
    ├── auth/                    # تسجيل الدخول + استعادة كلمة المرور
    ├── dashboard/                 # لوحة التحكم الرئيسية والإحصائيات
    ├── assets/                      # قائمة/تفاصيل الأصول (حواسيب + طابعات)
    ├── maintenance/                    # طلبات الصيانة (قائمة/تفاصيل/نموذج جديد)
    ├── users/                             # إدارة المستخدمين (Admin فقط)
    └── shared/                              # التنقل الرئيسي + شاشة البداية + الحساب الشخصي
```

كل Feature يتبع نفس التقسيم الداخلي: `data/` (Repository يتحدث مباشرة مع Dio)
→ `providers/` (ChangeNotifier يدير الحالة) → `views/` (الشاشات فقط، بدون منطق شبكة).

## إدارة الحالة

تم استخدام **Provider** (`ChangeNotifier` + `MultiProvider`) لبساطته وسرعة الدمج.
يمكن استبداله بـ Riverpod لاحقًا بسهولة لأن منطق الأعمال معزول بالكامل داخل الـ Providers/Repositories.

## الشبكة (Dio)

- `DioClient` (Singleton): نسخة Dio واحدة لكل التطبيق.
- `AuthInterceptor`: يضيف `Authorization: Bearer <token>` تلقائيًا، ويحاول تجديد
  التوكن عبر Refresh Token عند استلام `401`، ثم يعيد تنفيذ الطلب الأصلي تلقائيًا.
- `ErrorInterceptor`: يحوّل كل أخطاء Dio إلى `ApiException` برسائل عربية واضحة.
- `PrettyDioLogger`: لتسهيل تتبع الطلبات أثناء التطوير.

## التخزين الآمن

`flutter_secure_storage` لتخزين:
- `access_token` / `refresh_token` (JWT)
- بيانات المستخدم الحالي (لعرضها فورًا عند إعادة فتح التطبيق دون انتظار الشبكة)

## الربط بالـ Backend

عدّل عنوان السيرفر في:
```dart
// lib/core/constants/api_constants.dart
static const String baseUrl = 'http://<IP_OR_DOMAIN>:<PORT>/api';
```
أو مرّره وقت التشغيل/البناء:
```
flutter run --dart-define=API_BASE_URL=http://192.168.1.66:3000/api
```

### نقاط النهاية المتوقعة (بناءً على شاشات النظام الحالي)

| الميزة | Endpoint |
|---|---|
| تسجيل الدخول | `POST /auth/login` |
| استعادة كلمة المرور | `POST /auth/forgot-password` |
| تجديد التوكن | `POST /auth/refresh` |
| المستخدمون | `GET/POST/PUT/DELETE /users` |
| الكليات | `GET/POST/PUT/DELETE /colleges` |
| الموظفون | `GET/POST/PUT/DELETE /employees` |
| الحواسيب | `GET/POST/PUT/DELETE /computers` |
| الطابعات | `GET/POST/PUT/DELETE /printers` |
| طلبات الصيانة | `GET/POST/PUT/DELETE /maintenance-orders` |
| التقارير | `GET /reports/computers|printers|maintenance-orders` |
| سجل النشاطات | `GET /activity-logs` |

> ⚠️ عدّل المسارات في `api_constants.dart` إذا اختلفت التسمية الفعلية في `university-assets-api`
> (مثلًا snake_case بدل camelCase، أو بادئة `/v1`).

## الأدوار والصلاحيات (Role-Based Access)

| الدور | الوصول |
|---|---|
| **Admin (مدير)** | كل الشاشات + إدارة المستخدمين |
| **Employee (موظف)** | لوحة التحكم، الأصول، إنشاء طلبات صيانة |
| **Technician (فني)** | لوحة التحكم، الأصول، متابعة/تحديث حالة طلبات الصيانة |

يتم تحديد الدور تلقائيًا من استجابة تسجيل الدخول، ويُبنى شريط التنقل السفلي
(`main_navigation_screen.dart`) ديناميكيًا حسب الدور.

## التشغيل

> **ملاحظة مهمة:** هذا المشروع يحتوي على كود Dart/Flutter فقط (مجلد `lib/`) دون مجلدات
> المنصات (`android/`, `ios/`, ...) لأنها تُولَّد تلقائيًا. **أول خطوة بعد فك الضغط:**

```bash
cd university_assets_app
flutter create . --project-name university_assets_app --org com.university.assets
flutter pub get
flutter run
```

الأمر `flutter create .` يضيف مجلدات `android/` و`ios/` (وغيرها) دون المساس بملفات
`lib/` أو `pubspec.yaml` الموجودة.


## ما تم تنفيذه

- [x] هيكلية المجلدات + `pubspec.yaml`
- [x] Dio + Interceptors (Auth/Error) + Secure Storage
- [x] AppTheme (Material 3، فاتح/داكن) + ترجمة عربي/إنجليزي (RTL)
- [x] Auth: تسجيل الدخول + استعادة كلمة المرور
- [x] Dashboard بإحصائيات وإجراءات سريعة
- [x] الأصول: قائمة + بحث/فلترة + تفاصيل
- [x] الصيانة: قائمة + تفاصيل + تحديث الحالة (فني/مدير) + نموذج طلب جديد
- [x] المستخدمون (Admin): قائمة بالأدوار
- [x] التنقل الرئيسي حسب الدور + شاشة حساب شخصي (تبديل اللغة + تسجيل الخروج)

## للتوسّع لاحقًا

- شاشات الكليات/الموظفين الكاملة (CRUD) لدور Admin
- شاشة سجل النشاطات
- شاشات التقارير مع تصدير PDF/Excel (مطابقة لتقارير النظام الأصلي)
- الإشعارات الفورية (Push/WebSocket) لطلبات الصيانة الجديدة
