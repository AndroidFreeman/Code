import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import '../models/profile.dart';
import '../services/api_config.dart';
import '../services/native_cli.dart';
import '../services/native_features.dart';
import '../services/accounting_service.dart';

class SessionDataChange {
  final Set<String> modules;
  final bool remote;
  final DateTime occurredAt;

  const SessionDataChange({
    required this.modules,
    this.remote = false,
    required this.occurredAt,
  });

  bool affects(Iterable<String> interestedModules) {
    for (final module in interestedModules) {
      if (modules.contains(module) || modules.contains('all')) {
        return true;
      }
    }
    return false;
  }
}

class Session extends ChangeNotifier {
  final NativeCli? cli;
  final NativeFeatures features;
  final String dataDir;
  Profile _profile;
  late final AccountingService accounting;
  final StreamController<SessionDataChange> _dataChanges =
      StreamController<SessionDataChange>.broadcast();
  HttpClient? _eventClient;
  StreamSubscription<String>? _eventLineSub;
  Timer? _eventReconnectTimer;
  bool _disposed = false;
  bool _realtimeRequested = false;

  final Map<String, dynamic> preloadedData = {};
  final Map<String, String> preloadedSignatures = {};

  Future<void> preloadAll() async {
    // 并发执行预加载，提升启动速度
    try {
      final futures = <Future>[];

      if (await features.hasFeature('profiles_list')) {
        List<String> classes = [];
        if (isTeacher) {
          classes = profile.classCode
              .split('|')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        } else {
          classes = [profile.classCode.trim()];
        }

        futures.add(features.listProfiles(classCodes: classes).then((res) {
          if (res['ok'] == true) preloadedData['profiles'] = res['data'];
        }));
      }

      if (await features.hasFeature('timetable_list')) {
        futures.add(
            features.jsonOp(action: 'read', file: 'timetable.json').then((res) {
          if (res['ok'] == true) preloadedData['timetable'] = res['data'];
        }));
      }

      if (await features.hasFeature('todos_list')) {
        futures
            .add(features.csvOp(action: 'read', file: 'todos.csv').then((res) {
          if (res['ok'] == true) preloadedData['todos'] = res['data'];
        }));
      }

      if (await features.hasFeature('courses_list')) {
        futures.add(features.listCourses().then((res) {
          if (res['ok'] == true) preloadedData['courses'] = res['data'];
        }));
      }

      futures.add(features.listClasses().then((classesRes) {
        if (classesRes['ok'] == true)
          preloadedData['classes'] = classesRes['data'];
      }));

      if (await features.hasFeature('students_list')) {
        futures.add(features.listStudents().then((res) {
          if (res['ok'] == true) preloadedData['students'] = res['data'];
        }));
      }

      await Future.wait(futures);
    } catch (_) {}
  }

  Session({
    required this.cli,
    required this.features,
    required this.dataDir,
    required Profile profile,
  }) : _profile = profile {
    accounting = AccountingService(
        dataDir: dataDir, nativeLibDir: features.nativeLibDir);
  }

  Profile get profile => _profile;

  set profile(Profile newProfile) {
    if (_profile != newProfile) {
      _profile = newProfile;
      notifyListeners();
    }
  }

  void updateProfile(Profile newProfile) {
    profile = newProfile;
  }

  bool get isTeacher => profile.role.trim().toLowerCase() == 'teacher';
  bool get isStudent => !isTeacher;

  static const cadreRoles = [
    'psychological',
    'life',
    'publicity',
    'monitor',
    'study',
    'organize',
    'branch_secretary',
    '心理',
    '生活',
    '宣传',
    '班长',
    '学习',
    '组织',
    '团支书',
  ];
  static const powerCadreRoles = [
    'monitor',
    'study',
    'publicity',
    '班长',
    '学习',
    '宣传',
    '宣委',
  ];

  String get studentPosition => profile.position;
  String get normalizedPosition => studentPosition.trim().toLowerCase();

  bool get isCadre {
    final p = normalizedPosition;
    if (p.isEmpty) return false;
    return cadreRoles.any((role) {
      final r = role.toLowerCase();
      return p == r || p.contains(r);
    });
  }

  bool get isPowerCadre {
    final p = normalizedPosition;
    if (p.isEmpty) return false;
    return powerCadreRoles.any((role) {
      final r = role.toLowerCase();
      return p == r || p.contains(r);
    });
  }

  bool get canTakeAttendance => isTeacher || isPowerCadre;
  bool get canViewStudents => isTeacher || isPowerCadre;
  bool get canDeleteStudents => isTeacher;

  Stream<SessionDataChange> watchDataChanges(Iterable<String> modules) {
    final interested = modules.toSet();
    return _dataChanges.stream.where((event) => event.affects(interested));
  }

  void startRealtimeSync() {
    _realtimeRequested = true;
    if (!ApiConfig.instance.useCloud || _disposed) return;
    if (_eventLineSub != null) return;
    unawaited(_connectEventStream());
  }

  void stopRealtimeSync() {
    _realtimeRequested = false;
    _eventReconnectTimer?.cancel();
    _eventReconnectTimer = null;
    _eventLineSub?.cancel();
    _eventLineSub = null;
    _eventClient?.close(force: true);
    _eventClient = null;
  }

  Future<void> _connectEventStream() async {
    stopRealtimeSync();
    _realtimeRequested = true;
    if (!ApiConfig.instance.useCloud || _disposed) return;
    try {
      final client = HttpClient();
      final req = await client.getUrl(
        Uri.parse(ApiConfig.instance.urlFor('/api/events/stream')),
      );
      req.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      final res = await req.close();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        client.close(force: true);
        _scheduleRealtimeReconnect();
        return;
      }
      _eventClient = client;
      _eventLineSub =
          res.transform(utf8.decoder).transform(const LineSplitter()).listen(
                _handleEventLine,
                onError: (_) => _scheduleRealtimeReconnect(),
                onDone: _scheduleRealtimeReconnect,
                cancelOnError: true,
              );
    } catch (_) {
      _scheduleRealtimeReconnect();
    }
  }

  void _handleEventLine(String line) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('data:')) return;
    final payload = trimmed.substring(5).trim();
    if (payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      final modulesRaw = decoded is Map
          ? ((decoded['modules'] as List?) ?? const <dynamic>[])
          : const <dynamic>[];
      final modules = modulesRaw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet();
      if (modules.isEmpty) return;
      notifyDataChanged(modules: modules, remote: true);
    } catch (_) {}
  }

  void _scheduleRealtimeReconnect() {
    _eventLineSub?.cancel();
    _eventLineSub = null;
    _eventClient?.close(force: true);
    _eventClient = null;
    if (!_realtimeRequested || !ApiConfig.instance.useCloud || _disposed) {
      return;
    }
    _eventReconnectTimer?.cancel();
    _eventReconnectTimer = Timer(
      const Duration(seconds: 2),
      () => _connectEventStream(),
    );
  }

  void notifyDataChanged({
    Iterable<String> modules = const ['all'],
    bool remote = false,
  }) {
    _dataChanges.add(SessionDataChange(
      modules: modules.toSet(),
      remote: remote,
      occurredAt: DateTime.now(),
    ));
  }

  void logout() {
    // This is a hook for the UI to trigger logout.
    // The actual navigation and state clearing is usually handled by the parent (BootstrapPage/ShellPage).
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stopRealtimeSync();
    _dataChanges.close();
    super.dispose();
  }
}
