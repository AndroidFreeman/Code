import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';

import 'pages/bootstrap_page.dart';
import 'pages/login_page.dart';
import 'pages/shell_page.dart';
import 'services/app_paths.dart';
import 'services/bootstrapper.dart';
import 'services/local_profiles.dart';
import 'services/native_cli.dart';
import 'services/native_features.dart';
import 'state/session.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('zh', 'CN');
  ThemeMode _themeMode = ThemeMode.light;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  bool get isEnglish => _locale.languageCode == 'en';

  static const _settingsFileName = 'app_settings.json';

  Locale _normalizeLocale(Locale input) {
    if (input.languageCode == 'en') return const Locale('en', 'US');
    if (input.languageCode == 'zh') return const Locale('zh', 'CN');
    return input;
  }

  Future<File> _settingsFile() async {
    final dataDir = await AppPaths.dataDir();
    return File(p.join(dataDir.path, _settingsFileName));
  }

  Future<void> load() async {
    try {
      final f = await _settingsFile();
      if (!await f.exists()) return;
      final decoded = jsonDecode(await f.readAsString(encoding: utf8));
      if (decoded is! Map) return;
      final rawLocale = decoded['locale']?.toString().trim();
      if (rawLocale == null || rawLocale.isEmpty) return;
      final parts = rawLocale.replaceAll('-', '_').split('_');
      if (parts.isEmpty) return;
      final lang = parts[0];
      final country =
          (parts.length >= 2 && parts[1].trim().isNotEmpty) ? parts[1] : null;
      _locale = _normalizeLocale(Locale(lang, country));
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final f = await _settingsFile();
      final payload = <String, dynamic>{
        'locale': _locale.toLanguageTag(),
      };
      await f.writeAsString(jsonEncode(payload), encoding: utf8);
    } catch (_) {}
  }

  void setLocale(Locale newLocale) {
    _locale = _normalizeLocale(newLocale);
    notifyListeners();
    unawaited(_save());
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  String t(String zh, String en) {
    return _locale.languageCode == 'en' ? en : zh;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeProvider = LocaleProvider();
  await localeProvider.load();
  runApp(
    ChangeNotifierProvider.value(
      value: localeProvider,
      child: const LifeSystemApp(),
    ),
  );
}

class LifeSystemApp extends StatefulWidget {
  const LifeSystemApp({super.key});

  @override
  State<LifeSystemApp> createState() => _LifeSystemAppState();
}

class _LifeSystemAppState extends State<LifeSystemApp> {
  Session? _session;
  BootstrapResult? _boot;
  bool _autoLoginTried = false;

  Future<void> _tryAutoLogin(BootstrapResult boot) async {
    if (_autoLoginTried) return;
    _autoLoginTried = true;
    try {
      final profile =
          await LocalProfiles.loadAutoLoginProfile(dataDir: boot.dataDir);
      if (profile == null) return;

      final position = await LocalProfiles.loadStudentPosition(
        dataDir: boot.dataDir,
        profile: profile,
      );

      final features = NativeFeatures(
        dataDir: boot.dataDir,
        nativeLibDir: boot.nativeLibDir,
      );
      NativeCli? cli;
      if (File(boot.cliPath).existsSync()) {
        cli = NativeCli(exePath: boot.cliPath, dataDir: boot.dataDir);
      }

      if (!mounted) return;
      setState(() {
        _session = Session(
          cli: cli,
          features: features,
          dataDir: boot.dataDir,
          profile: profile,
          studentPosition: position,
        );
      });
    } catch (_) {
      await LocalProfiles.clearAutoLogin(boot.dataDir);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isEn = localeProvider.isEnglish;
    final fontFamily = isEn ? 'Fredoka' : 'NotoSansSC';

    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: Brightness.light,
        surface: const Color(0xFFF7F7FE),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFEEECF8),
        surfaceContainer: const Color(0xFFE6E0E9),
        surfaceContainerHigh: const Color(0xFFDFDAE3),
        surfaceContainerHighest: const Color(0xFFD7D2DB),
      ),
      useMaterial3: true,
      visualDensity: VisualDensity.comfortable,
      fontFamily: isEn ? 'Fredoka' : 'NotoSansSC',
      fontFamilyFallback: isEn ? const ['NotoSansSC'] : null,
    );

    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      visualDensity: VisualDensity.comfortable,
      fontFamily: isEn ? 'Fredoka' : 'NotoSansSC',
      fontFamilyFallback: isEn ? const ['NotoSansSC'] : null,
    );

    const expressiveRadius = 24.0;
    const extraExpressiveRadius = 32.0;

    return MaterialApp(
      title: "Life's Been Good System",
      debugShowCheckedModeBanner: false,
      locale: localeProvider.locale,
      themeMode: localeProvider.themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      theme: baseTheme.copyWith(
        textTheme: baseTheme.textTheme.apply(
          bodyColor: const Color(0xFF1C1B1F),
          displayColor: const Color(0xFF1C1B1F),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FF),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white.withValues(alpha: 204),
          surfaceTintColor: Colors.transparent,
          foregroundColor: baseTheme.colorScheme.onSurface,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: baseTheme.colorScheme.surfaceContainerLow,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(expressiveRadius),
            side: BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
        ),
        navigationBarTheme: NavigationBarThemeData(
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          elevation: 0,
          backgroundColor: Colors.white.withValues(alpha: 204),
          indicatorColor: baseTheme.colorScheme.secondaryContainer,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(expressiveRadius),
          ),
        ),
        navigationDrawerTheme: NavigationDrawerThemeData(
          backgroundColor: Colors.white.withValues(alpha: 204),
          indicatorColor: baseTheme.colorScheme.secondaryContainer,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(expressiveRadius),
          ),
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: Colors.white.withValues(alpha: 204),
          indicatorColor: baseTheme.colorScheme.secondaryContainer,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(expressiveRadius),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 1,
          hoverElevation: 2,
          focusElevation: 2,
          backgroundColor: baseTheme.colorScheme.primaryContainer,
          foregroundColor: baseTheme.colorScheme.onPrimaryContainer,
          splashColor: baseTheme.colorScheme.primary.withValues(alpha: 26),
          shape: const CircleBorder(),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) {
                if (states.contains(WidgetState.selected)) {
                  return baseTheme.colorScheme.secondaryContainer;
                }
                return null;
              },
            ),
            shape: WidgetStateProperty.resolveWith<OutlinedBorder>(
              (states) {
                if (states.contains(WidgetState.pressed)) {
                  return RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  );
                }
                return const CircleBorder();
              },
            ),
          ),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            side: WidgetStatePropertyAll(
              BorderSide(
                color:
                    baseTheme.colorScheme.outlineVariant.withValues(alpha: 128),
              ),
            ),
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) {
                if (states.contains(WidgetState.selected)) {
                  return baseTheme.colorScheme.primaryContainer;
                }
                return baseTheme.colorScheme.surfaceContainerLow;
              },
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) {
                if (states.contains(WidgetState.selected)) {
                  return baseTheme.colorScheme.onPrimaryContainer;
                }
                return baseTheme.colorScheme.onSurfaceVariant;
              },
            ),
            overlayColor: WidgetStateProperty.resolveWith(
              (states) {
                if (states.contains(WidgetState.pressed)) {
                  return baseTheme.colorScheme.primary.withValues(alpha: 26);
                }
                return null;
              },
            ),
            textStyle: WidgetStatePropertyAll(
              baseTheme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            elevation: 1,
            backgroundColor: baseTheme.colorScheme.primaryContainer,
            foregroundColor: baseTheme.colorScheme.onPrimaryContainer,
            shadowColor: baseTheme.colorScheme.shadow.withValues(alpha: 38),
            surfaceTintColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ).copyWith(
            shape: WidgetStateProperty.resolveWith<OutlinedBorder>(
              (states) {
                if (states.contains(WidgetState.pressed)) {
                  return RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  );
                }
                return const StadiumBorder();
              },
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            backgroundColor: baseTheme.colorScheme.surfaceContainerLow,
            foregroundColor: baseTheme.colorScheme.onSurface,
            side: BorderSide(
              color:
                  baseTheme.colorScheme.outlineVariant.withValues(alpha: 128),
            ),
            elevation: 1,
            shadowColor: baseTheme.colorScheme.shadow.withValues(alpha: 26),
            surfaceTintColor: Colors.transparent,
          ).copyWith(
            shape: WidgetStateProperty.resolveWith<OutlinedBorder>(
              (states) {
                if (states.contains(WidgetState.pressed)) {
                  return RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  );
                }
                return const StadiumBorder();
              },
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom().copyWith(
            shape: WidgetStateProperty.resolveWith<OutlinedBorder>(
              (states) {
                if (states.contains(WidgetState.pressed)) {
                  return RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  );
                }
                return const StadiumBorder();
              },
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: baseTheme.colorScheme.surfaceContainer,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide:
                BorderSide(color: baseTheme.colorScheme.primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(extraExpressiveRadius)),
          backgroundColor: baseTheme.colorScheme.surfaceContainerHighest,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: baseTheme.colorScheme.surfaceContainerHighest,
          shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(extraExpressiveRadius)),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        menuTheme: MenuThemeData(
          style: MenuStyle(
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            )),
            elevation: const WidgetStatePropertyAll(4),
          ),
        ),
      ),
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF8F9FF), Color(0xFFF0F2F8)],
            ),
          ),
          child: child,
        );
      },
      darkTheme: darkTheme.copyWith(
        scaffoldBackgroundColor: darkTheme.colorScheme.surface,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.black.withValues(alpha: 204),
          surfaceTintColor: Colors.transparent,
          foregroundColor: darkTheme.colorScheme.onSurface,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: darkTheme.colorScheme.surfaceContainerLow,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(expressiveRadius),
            side: BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
        ),
        navigationBarTheme: NavigationBarThemeData(
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          elevation: 0,
          backgroundColor: Colors.black.withValues(alpha: 204),
          indicatorColor: darkTheme.colorScheme.secondaryContainer,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(expressiveRadius),
          ),
        ),
        navigationDrawerTheme: NavigationDrawerThemeData(
          backgroundColor: Colors.black.withValues(alpha: 204),
          indicatorColor: darkTheme.colorScheme.secondaryContainer,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(expressiveRadius),
          ),
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: Colors.black.withValues(alpha: 204),
          indicatorColor: darkTheme.colorScheme.secondaryContainer,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(expressiveRadius),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 1,
          hoverElevation: 2,
          focusElevation: 2,
          backgroundColor: darkTheme.colorScheme.primaryContainer,
          foregroundColor: darkTheme.colorScheme.onPrimaryContainer,
          splashColor: darkTheme.colorScheme.primary.withValues(alpha: 26),
          shape: const CircleBorder(),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) {
                if (states.contains(WidgetState.selected)) {
                  return darkTheme.colorScheme.secondaryContainer;
                }
                return null;
              },
            ),
            shape: WidgetStateProperty.resolveWith<OutlinedBorder>(
              (states) {
                if (states.contains(WidgetState.pressed)) {
                  return RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  );
                }
                return const CircleBorder();
              },
            ),
          ),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            side: WidgetStatePropertyAll(
              BorderSide(
                color:
                    darkTheme.colorScheme.outlineVariant.withValues(alpha: 128),
              ),
            ),
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) {
                if (states.contains(WidgetState.selected)) {
                  return darkTheme.colorScheme.primaryContainer;
                }
                return darkTheme.colorScheme.surfaceContainerLow;
              },
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) {
                if (states.contains(WidgetState.selected)) {
                  return darkTheme.colorScheme.onPrimaryContainer;
                }
                return darkTheme.colorScheme.onSurfaceVariant;
              },
            ),
          ),
        ),
      ),
      home: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> primaryAnimation,
            Animation<double> secondaryAnimation) {
          return FadeThroughTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: _boot == null
            ? BootstrapPage(
                key: const ValueKey('boot'),
                onReady: (r) {
                  setState(() {
                    _boot = r;
                  });
                  _tryAutoLogin(r);
                },
              )
            : _session == null
                ? LoginPage(
                    key: const ValueKey('login'),
                    dataDir: _boot!.dataDir,
                    cliPath: _boot!.cliPath,
                    nativeLibDir: _boot!.nativeLibDir,
                    onLoggedIn: (s) {
                      setState(() {
                        _session = s;
                      });
                    },
                  )
                : ShellPage(
                    key: const ValueKey('shell'),
                    session: _session!,
                    onLogout: () {
                      final boot = _boot;
                      if (boot != null) {
                        LocalProfiles.clearAutoLogin(boot.dataDir);
                      }
                      setState(() {
                        _session = null;
                      });
                    },
                  ),
      ),
    );
  }
}
