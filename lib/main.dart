import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'utils/notification_service.dart';

// ✅ ต้องมีเพื่อให้ GlobalMaterialLocalizations ฯลฯ ใช้งานได้
import 'package:flutter_localizations/flutter_localizations.dart';

// ✅ gen-l10n
import 'package:to_dolist/l10n/app_localizations.dart';

import 'firebase_options.dart';
import 'splash_page.dart';
import 'login_page.dart';
import 'db/settings_dao.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final settings = AppSettings();
  await settings.loadFromDb();
  await NotificationService.instance.init();
  runApp(
    AppSettingsScope(
      settings: settings,
      child: MyApp(settings: settings),
    ),
  );
}

/// ✅ เก็บค่า theme/locale และ settings อื่น ๆ ให้ทั้งแอพ (persist ด้วย SQLite)
class AppSettings extends ChangeNotifier {
  Locale _locale = const Locale('th', 'TH');

  // ✅ ธีมหลักคือ "สว่าง" และให้เลือกได้แค่ light/dark
  String _themePref = 'light';

  // ✅ Settings เพิ่มเติม (เก็บลง SQLite)
  String _dateFormat = 'dd-MM-yyyy';
  int _reminderMinutes = 10;
  bool _notificationsEnabled = true;

  Locale get locale => _locale;

  ThemeMode get themeMode =>
      (_themePref == 'dark') ? ThemeMode.dark : ThemeMode.light;

  String get themePref => _themePref;

  String get dateFormat => _dateFormat;
  int get reminderMinutes => _reminderMinutes;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> loadFromDb() async {
    final dao = SettingsDao.instance;

    final theme = await dao.getString(SettingsDao.kThemeMode);
    final lang = await dao.getString(SettingsDao.kLanguage);
    final fmt = await dao.getString(SettingsDao.kDateFormat);
    final mins = await dao.getInt(SettingsDao.kReminderMinutes);
    final noti = await dao.getBool(SettingsDao.kNotificationsEnabled);

    _themePref = (theme == 'dark') ? 'dark' : 'light';

    if (lang == 'en') _locale = const Locale('en', 'US');
    if (lang == 'th') _locale = const Locale('th', 'TH');

    if (fmt != null) _dateFormat = fmt;
    if (mins != null) _reminderMinutes = mins;
    if (noti != null) _notificationsEnabled = noti;

    notifyListeners();
  }

  Future<void> setLocale(Locale l) async {
    if (_locale == l) return;

    _locale = l;

    final tag = '${l.languageCode}_${l.countryCode ?? ''}';
    await initializeDateFormatting(tag, null);

    notifyListeners();

    await SettingsDao.instance.setString(
      SettingsDao.kLanguage,
      l.languageCode == 'en' ? 'en' : 'th',
    );
  }

  Future<void> setThemePref(String pref) async {
    if (pref != 'light' && pref != 'dark') return;
    if (_themePref == pref) return;

    _themePref = pref;
    notifyListeners();

    await SettingsDao.instance.setString(SettingsDao.kThemeMode, pref);
  }

  Future<void> setThemeMode(ThemeMode m) async {
    if (m == ThemeMode.dark) return setThemePref('dark');
    return setThemePref('light');
  }

  Future<void> toggleDark(bool isDark) =>
      setThemePref(isDark ? 'dark' : 'light');

  Future<void> setDateFormat(String fmt) async {
    _dateFormat = fmt;
    notifyListeners();
    await SettingsDao.instance.setString(SettingsDao.kDateFormat, fmt);
  }

  Future<void> setReminderMinutes(int minutes) async {
    _reminderMinutes = minutes;
    notifyListeners();
    await SettingsDao.instance.setInt(SettingsDao.kReminderMinutes, minutes);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    await SettingsDao.instance.setBool(
      SettingsDao.kNotificationsEnabled,
      enabled,
    );
  }
}

/// ✅ ทำให้หน้าอื่นเรียกใช้ AppSettings ได้ (Theme/Language)
class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope not found');
    return scope!.notifier!;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.settings});
  final AppSettings settings;

  static const _blue = Color(0xFF2E5E8D);
  static const _ink = Color(0xFF1F3346);

  ThemeData _lightTheme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _blue,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF6F7FB),
        elevation: 0,
        foregroundColor: _ink,
        centerTitle: false,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  ThemeData _darkTheme() {
    const bg = Color(0xFF0B1220);
    const surface = Color(0xFF121B2D);
    const surface2 = Color(0xFF18243A);
    const outline = Color(0x26FFFFFF);
    const onBg = Color(0xFFE8EEF8);
    const muted = Color(0xFF9BB0CC);
    const primary = Color(0xFF6FB5FF);

    final base = ThemeData.dark();

    final scheme = ColorScheme.fromSeed(
      seedColor: _blue,
      brightness: Brightness.dark,
    ).copyWith(
      primary: primary,
      surface: surface,
      onSurface: onBg,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        foregroundColor: onBg,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(
        color: outline,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        textColor: onBg,
        iconColor: primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        tileColor: surface2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        hintStyle: const TextStyle(color: muted),
        labelStyle: const TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.2),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return muted;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return const Color(0xFF5C6F8A);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withOpacity(0.35);
          }
          return const Color(0xFF2A364A);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return surface2;
        }),
        checkColor: const WidgetStatePropertyAll(Color(0xFF06101F)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        side: const BorderSide(color: outline),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: onBg),
        bodySmall: TextStyle(color: muted),
        titleMedium: TextStyle(color: onBg, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (_, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (_, __) => settings.locale,
          theme: _lightTheme(),
          darkTheme: _darkTheme(),
          themeMode: settings.themeMode,
          home: const SplashPage(),
          routes: {
            '/login': (_) => const LoginPage(),
          },
        );
      },
    );
  }
}