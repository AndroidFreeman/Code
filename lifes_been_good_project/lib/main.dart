import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:developer' as developer;

import 'pages/bootstrap_page.dart';
import 'pages/login_page.dart';
import 'pages/shell_page.dart';
import 'services/app_paths.dart';
import 'services/android_native_installer.dart';
import 'services/bootstrapper.dart';
import 'services/local_profiles.dart';
import 'services/native_cli.dart';
import 'services/native_features.dart';
import 'services/api_config.dart';
import 'state/session.dart';
import 'widgets/expressive_ui.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('zh', 'CN');
  ThemeMode _themeMode = ThemeMode.light;
  bool _enableQuickRollCall = true;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  bool get isEnglish => _locale.languageCode == 'en';
  bool get enableQuickRollCall => _enableQuickRollCall;

  static const _settingsFileName = 'app_settings.json';

  Locale _normalizeLocale(Locale input) {
    if (input.languageCode == 'en') return const Locale('en', 'US');
    if (input.languageCode == 'zh') return const Locale('zh', 'CN');
    return input;
  }

  Future<void> load() async {
    try {
      final dataDir = await AppPaths.dataDir();
      final nativeLibDir = Platform.isAndroid
          ? await AndroidNativeInstaller.getNativeLibraryDir()
          : null;
      final features =
          NativeFeatures(dataDir: dataDir.path, nativeLibDir: nativeLibDir);
      final res =
          await features.jsonOp(action: 'read', file: _settingsFileName);
      if (res['ok'] != true || res['data'] == null) return;
      final decoded = res['data'];

      if (decoded is Map && decoded.containsKey('themeMode')) {
        final modeIndex = decoded['themeMode'] as int?;
        if (modeIndex != null &&
            modeIndex >= 0 &&
            modeIndex < ThemeMode.values.length) {
          _themeMode = ThemeMode.values[modeIndex];
        }
      }
      if (decoded is! Map) return;

      if (decoded.containsKey('enableQuickRollCall')) {
        _enableQuickRollCall = decoded['enableQuickRollCall'] == true;
      }

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
      final dataDir = await AppPaths.dataDir();
      final nativeLibDir = Platform.isAndroid
          ? await AndroidNativeInstaller.getNativeLibraryDir()
          : null;
      final features =
          NativeFeatures(dataDir: dataDir.path, nativeLibDir: nativeLibDir);
      final payload = <String, dynamic>{
        'locale': _locale.toLanguageTag(),
        'enableQuickRollCall': _enableQuickRollCall,
      };
      await features.jsonOp(
          action: 'write', file: _settingsFileName, data: payload);
    } catch (_) {}
  }

  void setLocale(Locale newLocale) {
    final normalized = _normalizeLocale(newLocale);
    if (_locale == normalized) return;
    _locale = normalized;
    notifyListeners();
    unawaited(_save());
  }

  void setEnableQuickRollCall(bool value) {
    _enableQuickRollCall = value;
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

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final localeProvider = LocaleProvider();
  await localeProvider.load();
  final dataDir = await AppPaths.dataDir();
  await ApiConfig.instance.load(dataDir.path);
  final cliFile = await AppPaths.defaultCliFile();
  final nativeLibDir = Platform.isAndroid
      ? await AndroidNativeInstaller.getNativeLibraryDir()
      : null;
  final initialBoot = BootstrapResult(
    ok: true,
    message: '',
    dataDir: dataDir.path,
    cliPath: cliFile.path,
    nativeLibDir: nativeLibDir,
  );
  final initialSession = _tryFastAutoLogin(initialBoot);
  runApp(
    ChangeNotifierProvider.value(
      value: localeProvider,
      child: LifeSystemApp(
        initialBoot: initialBoot,
        initialSession: initialSession,
      ),
    ),
  );
}

void _logPerf(String step, int elapsedMs) {
  developer.log('⚡ PERF: $step took ${elapsedMs}ms');
}

Session? _tryFastAutoLogin(BootstrapResult boot) {
  final start = DateTime.now();
  try {
    final profile = LocalProfiles.loadAutoLoginProfileFast(
      dataDir: boot.dataDir,
    );
    if (profile == null) return null;

    final position = LocalProfiles.loadStudentPositionFast(
      dataDir: boot.dataDir,
      profile: profile,
    );
    final features = NativeFeatures(
      dataDir: boot.dataDir,
      nativeLibDir: boot.nativeLibDir,
    );
    final cli = File(boot.cliPath).existsSync()
        ? NativeCli(exePath: boot.cliPath, dataDir: boot.dataDir)
        : null;
    final session = Session(
      cli: cli,
      features: features,
      dataDir: boot.dataDir,
      profile: profile.copyWith(position: position),
    );

    _logPerf('_tryFastAutoLogin_init',
        DateTime.now().difference(start).inMilliseconds);

    // Do NOT await preloadAll to avoid blocking startup
    session.preloadAll().then((_) {
      session.startRealtimeSync();
      _logPerf('_tryFastAutoLogin_preloadAll',
          DateTime.now().difference(start).inMilliseconds);
    });

    return session;
  } catch (_) {
    return null;
  }
}

class LifeSystemApp extends StatefulWidget {
  final BootstrapResult? initialBoot;
  final Session? initialSession;

  const LifeSystemApp({
    super.key,
    this.initialBoot,
    this.initialSession,
  });

  @override
  State<LifeSystemApp> createState() => _LifeSystemAppState();
}

class _LifeSystemAppState extends State<LifeSystemApp> {
  late Session? _session = widget.initialSession;
  late BootstrapResult? _boot = widget.initialBoot;
  bool _bootstrapping = false;
  bool _startupSettled = false;
  SystemUiOverlayStyle? _appliedOverlayStyle;
  late final DateTime _startupBeganAt;

  @override
  void initState() {
    super.initState();
    _startupBeganAt = DateTime.now();
    _startupSettled = false;
    unawaited(_ensureBootReady());
  }

  Future<void> _ensureBootReady() async {
    final startEnsure = DateTime.now();
    if (_bootstrapping) return;
    _bootstrapping = true;

    // Background Ping (timeout 800ms) as requested
    ApiConfig.instance
        .get('/api/ping')
        .timeout(const Duration(milliseconds: 800))
        .catchError((_) => {'ok': false})
        .then((res) {
      _logPerf('_ping_server',
          DateTime.now().difference(startEnsure).inMilliseconds);
      if (res['ok'] != true && mounted) {
        final loc = Provider.of<LocaleProvider>(context, listen: false);
        final overlay = Overlay.maybeOf(context);
        if (overlay != null) {
          final entry = OverlayEntry(
            builder: (context) => Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Text(
                      loc.t(
                          '网络异常，已使用离线数据', 'Network error, using offline data'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          overlay.insert(entry);
          Future.delayed(const Duration(seconds: 3), () => entry.remove());
        }
      }
    });

    final bootFuture = Bootstrapper.run();
    // Do not await anything sequentially if we don't have to
    bootFuture.then((result) {
      _logPerf('_bootstrapper_run',
          DateTime.now().difference(startEnsure).inMilliseconds);
      if (!mounted) return;
      setState(() {
        _boot = result;
      });
      if (_session == null && result.ok) {
        _tryAutoLogin(result).then((_) {
          _logPerf('_tryAutoLogin_fallback',
              DateTime.now().difference(startEnsure).inMilliseconds);
          if (mounted) {
            setState(() {
              _startupSettled = true;
            });
          }
          _bootstrapping = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _startupSettled = true;
          });
        }
        _bootstrapping = false;
      }
    }).catchError((_) {
      if (mounted) {
        setState(() {
          _startupSettled = true;
        });
      }
      _bootstrapping = false;
    });
  }

  Future<void> _tryAutoLogin(BootstrapResult boot) async {
    final startTry = DateTime.now();
    try {
      final profile = await LocalProfiles.loadAutoLoginProfile(
        dataDir: boot.dataDir,
      );
      if (profile == null) return;
      _logPerf('_tryAutoLogin_loadProfile',
          DateTime.now().difference(startTry).inMilliseconds);

      final position = await LocalProfiles.loadStudentPosition(
        dataDir: boot.dataDir,
        profile: profile,
      );
      _logPerf('_tryAutoLogin_loadPosition',
          DateTime.now().difference(startTry).inMilliseconds);

      final features = NativeFeatures(
        dataDir: boot.dataDir,
        nativeLibDir: boot.nativeLibDir,
      );
      final cli = File(boot.cliPath).existsSync()
          ? NativeCli(exePath: boot.cliPath, dataDir: boot.dataDir)
          : null;

      // Do NOT run preloadAll here sequentially as it delays the UI from rendering ShellPage
      // ShellPage and sub-pages are already optimized to read SQLite/Cache on their own in initState
      final session = Session(
        cli: cli,
        features: features,
        dataDir: boot.dataDir,
        profile: profile.copyWith(position: position),
      );

      try {
        await LocalProfiles.saveAutoLogin(
          dataDir: boot.dataDir,
          profile: profile.copyWith(position: position),
        );
      } catch (_) {}

      if (mounted) {
        setState(() {
          _session?.dispose();
          _session = session;
        });
      }

      _logPerf('_tryAutoLogin_setSession',
          DateTime.now().difference(startTry).inMilliseconds);

      // Fire and forget preload and realtime sync after UI is unblocked
      session.preloadAll().then((_) {
        session.startRealtimeSync();
        _logPerf('_tryAutoLogin_preloadAllAsync',
            DateTime.now().difference(startTry).inMilliseconds);
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
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final effectiveBrightness = localeProvider.themeMode == ThemeMode.system
        ? platformBrightness
        : (localeProvider.themeMode == ThemeMode.dark
            ? Brightness.dark
            : Brightness.light);
    final overlayStyle = effectiveBrightness == Brightness.dark
        ? const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.light,
          )
        : const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.dark,
          );
    if (_appliedOverlayStyle != overlayStyle) {
      _appliedOverlayStyle = overlayStyle;
      SystemChrome.setSystemUIOverlayStyle(overlayStyle);
    }

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
      fontFamily: fontFamily,
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: MaterialApp(
        title: "Life's Been Good System",
        debugShowCheckedModeBanner: false,
        showSemanticsDebugger: false,
        builder: (context, child) {
          Widget finalChild = child ?? const SizedBox.shrink();
          if (!kIsWeb && Platform.isWindows) {
            finalChild = ExcludeSemantics(child: finalChild);
          }
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF8F9FF), Color(0xFFF0F2F8)],
              ),
            ),
            child: finalChild,
          );
        },
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
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: AppSlidePageTransitionsBuilder(),
              TargetPlatform.iOS: AppSlidePageTransitionsBuilder(),
              TargetPlatform.macOS: AppSlidePageTransitionsBuilder(),
              TargetPlatform.windows: AppSlidePageTransitionsBuilder(),
              TargetPlatform.linux: AppSlidePageTransitionsBuilder(),
            },
          ),
          textTheme: baseTheme.textTheme.apply(
            bodyColor: const Color(0xFF1C1B1F),
            displayColor: const Color(0xFF1C1B1F),
          ),
          scaffoldBackgroundColor: const Color(0xFFF8F9FF),
          appBarTheme: AppBarTheme(
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            foregroundColor: baseTheme.colorScheme.onSurface,
            titleTextStyle: baseTheme.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: baseTheme.colorScheme.onSurface,
            ),
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
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
            backgroundColor: Colors.transparent,
            indicatorColor: baseTheme.colorScheme.secondaryContainer,
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(expressiveRadius),
            ),
          ),
          navigationDrawerTheme: NavigationDrawerThemeData(
            backgroundColor: baseTheme.colorScheme.surface,
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
            elevation: 0,
            hoverElevation: 0,
            focusElevation: 0,
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
                BorderSide.none,
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
              elevation: 0,
              backgroundColor: baseTheme.colorScheme.primaryContainer,
              foregroundColor: baseTheme.colorScheme.onPrimaryContainer,
              shadowColor: Colors.transparent,
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
                color: Colors.transparent,
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
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
            floatingLabelBehavior: FloatingLabelBehavior.always,
            floatingLabelStyle: TextStyle(
              color: baseTheme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
            labelStyle: TextStyle(
              color: baseTheme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            hintStyle: TextStyle(
              color:
                  baseTheme.colorScheme.onSurfaceVariant.withValues(alpha: 150),
            ),
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
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
              elevation: const WidgetStatePropertyAll(0),
              shadowColor: const WidgetStatePropertyAll(Colors.transparent),
              surfaceTintColor: WidgetStatePropertyAll(
                baseTheme.colorScheme.surfaceContainerLowest,
              ),
            ),
          ),
        ),
        darkTheme: darkTheme.copyWith(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: AppSlidePageTransitionsBuilder(),
              TargetPlatform.iOS: AppSlidePageTransitionsBuilder(),
              TargetPlatform.macOS: AppSlidePageTransitionsBuilder(),
              TargetPlatform.windows: AppSlidePageTransitionsBuilder(),
              TargetPlatform.linux: AppSlidePageTransitionsBuilder(),
            },
          ),
          scaffoldBackgroundColor: darkTheme.colorScheme.surface,
          appBarTheme: AppBarTheme(
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            foregroundColor: darkTheme.colorScheme.onSurface,
            titleTextStyle: darkTheme.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: darkTheme.colorScheme.onSurface,
            ),
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: Brightness.light,
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
            backgroundColor: Colors.transparent,
            indicatorColor: darkTheme.colorScheme.secondaryContainer,
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(expressiveRadius),
            ),
          ),
          navigationDrawerTheme: NavigationDrawerThemeData(
            backgroundColor: darkTheme.colorScheme.surface,
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
            elevation: 0,
            hoverElevation: 0,
            focusElevation: 0,
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
                BorderSide.none,
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
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: darkTheme.colorScheme.surfaceContainer,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            floatingLabelStyle: TextStyle(
              color: darkTheme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
            labelStyle: TextStyle(
              color: darkTheme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            hintStyle: TextStyle(
              color:
                  darkTheme.colorScheme.onSurfaceVariant.withValues(alpha: 150),
            ),
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
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
        home: AnimatedSwitcher(
          duration: kAppRouteTransitionDuration,
          switchInCurve: kAppMotionCurve,
          switchOutCurve: kAppMotionCurve,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (child, animation) {
            final curved =
                CurvedAnimation(parent: animation, curve: kAppMotionCurve);
            final isStartupCover =
                (child.key as ValueKey?)?.value == 'startup-cover';
            if (isStartupCover) {
              return FadeTransition(
                opacity: curved,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
                  child: child,
                ),
              );
            }
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.06),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
          child: !_startupSettled
              ? const _StartupCoverPage(key: ValueKey('startup-cover'))
              : (_boot != null && _boot!.ok == false)
                  ? BootstrapPage(
                      key: const ValueKey('boot-error'),
                      onReady: (r) {
                        setState(() {
                          _boot = r;
                        });
                        unawaited(_tryAutoLogin(r));
                      },
                    )
                  : _boot == null
                      ? BootstrapPage(
                          key: const ValueKey('boot'),
                          onReady: (r) {
                            setState(() {
                              _boot = r;
                            });
                            unawaited(_tryAutoLogin(r));
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
                                  _session?.dispose();
                                  _session = s;
                                });
                                _session?.startRealtimeSync();
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
                                  _session?.dispose();
                                  _session = null;
                                });
                              },
                            ),
        ),
      ),
    );
  }
}

class _StartupCoverPage extends StatelessWidget {
  const _StartupCoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.surface,
              cs.surfaceContainerLow,
              cs.surfaceContainer,
            ],
          ),
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.92, end: 1.0),
          duration: const Duration(milliseconds: 420),
          curve: kAppMotionCurve,
          builder: (context, value, child) {
            return Opacity(
              opacity: ((value - 0.92) / 0.08).clamp(0.0, 1.0),
              child: Transform.scale(scale: value, child: child),
            );
          },
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 180),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 160),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Life's Been Good",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
