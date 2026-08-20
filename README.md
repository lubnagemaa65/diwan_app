<<<<<<< HEAD
# Facility App (Flutter)

Native mirror of the web dashboard, with mock data now and a clean path
to a real REST API later. See `lib/features/auth/repository/auth_repository.dart`
for the exact spots marked for future `http.post`/`http.get` calls.

## Demo accounts (mock)
| Role       | Email                          | Password     |
|------------|---------------------------------|--------------|
| Admin      | admintest@local.com             | admintest123 |
| Technician | technicanusertest@local.com     | tech1234     |
| Employee   | emptest@local                   | emptest123   |

## Project structure
```
lib/
  core/
    constants/app_constants.dart   # API base URL + endpoint placeholders
    theme/app_colors.dart          # palette + ThemeData
    mock/mock_data.dart            # static data for all 3 dashboards
  features/
    auth/
      models/user_model.dart
      repository/auth_repository.dart   # mock now, HTTP-ready later
      controller/auth_controller.dart   # ChangeNotifier state
      screens/login_screen.dart
    dashboard/
      widgets/  custom_app_bar.dart, app_drawer.dart, role_badge.dart
      admin/admin_dashboard_screen.dart
      technician/technician_dashboard_screen.dart
      employee/employee_dashboard_screen.dart
  main.dart
```

## ⚠️ About the APK
This project was generated in a sandbox that has **no Flutter SDK, no
Android SDK, and no network access** — so an actual `.apk` binary could
not be compiled here. What's included instead is everything needed to
produce a small one yourself, two ways:

### Option A — Let GitHub build it for you (no local install needed)
1. Push this folder to a new GitHub repo.
2. The workflow at `.github/workflows/build-apk.yml` is already wired up.
   Go to the repo's **Actions** tab → run **"Build Small Release APK"**
   (or just push to `main`).
3. Download the `release-apks` artifact when it finishes — you'll get
   three APKs (`armeabi-v7a`, `arm64-v8a`, `x86_64`), each only
   containing native code for that architecture instead of one bloated
   universal APK.

### Option B — Build locally (if you have Flutter installed)
```bash
# 1. Scaffold the native android/ (and ios/) folders, which aren't
#    included here since they require the Flutter SDK to generate correctly:
flutter create --platforms=android,ios --org com.yourcompany .

# 2. Merge the size-optimized settings into android/app/build.gradle:
#    open android_config/app/build.gradle.snippet and merge its
#    android { ... } contents into the generated file.
cp android_config/app/proguard-rules.pro android/app/proguard-rules.pro

# 3. Get packages
flutter pub get

# 4. Build the smallest possible release APK
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/debug-info
```
Output lands in `build/app/outputs/flutter-apk/`. Typical result: each
per-ABI APK is roughly **6–9 MB**, vs ~20 MB+ for an unsplit debug-signed
universal APK.

### Why each flag matters (size impact, largest first)
1. **`--split-per-abi`** — biggest win. Ships only the native code for
   one CPU architecture per APK instead of arm+arm64+x86 bundled together.
2. **`minifyEnabled true` / `shrinkResources true`** (in the gradle
   snippet) — R8 strips unused Dart-generated Java/Kotlin glue and
   unused Android resources.
3. **`--obfuscate --split-debug-info=...`** — shrinks and obfuscates
   compiled Dart code; keep the `debug-info` folder privately if you
   ever need to symbolicate a crash report.
4. Icon tree-shaking and resource shrinking happen automatically in
   `--release` mode — no unused Material icon glyphs get bundled.
5. If you publish to Play Store instead of sideloading, prefer
   `flutter build appbundle` — Play's dynamic delivery does this
   splitting (and more, like per-density image splitting) automatically
   and usually yields an even smaller download for end users.

### Before shipping
- Replace `signingConfig signingConfigs.debug` in the gradle snippet
  with a real release keystore — the debug signing config is only there
  so the build works before you set one up.
- Replace `applicationId "com.example.facility_app"` with your own.
=======
# diwan_app
>>>>>>> 3ac57030da1f9fab6162b9020366e4740221e489
