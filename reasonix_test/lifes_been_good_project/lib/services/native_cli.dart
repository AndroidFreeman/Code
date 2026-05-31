import 'dart:convert';
import 'dart:io';

import 'api_config.dart';

class NativeCli {
  final String exePath;
  final String dataDir;

  const NativeCli({required this.exePath, required this.dataDir});

  Future<Map<String, dynamic>> init({required bool seed}) async {
    if (ApiConfig.instance.useCloud)
      return ApiConfig.instance.get('/api/system/init?seed=$seed');
    final args = <String>['system.init', '--data-dir', dataDir];
    if (seed) args.add('--seed');

    final res = await Process.run(exePath, args,
        stdoutEncoding: utf8, stderrEncoding: utf8);
    return _decode(res);
  }

  Future<Map<String, dynamic>> call(
      String action, Map<String, dynamic> payload) async {
    if (ApiConfig.instance.useCloud) {
      switch (action) {
        case 'students.list':
          return ApiConfig.instance.get('/api/students');
        case 'courses.list':
          return ApiConfig.instance.get('/api/courses');
        case 'profiles.list':
          final codes = payload['class_codes'] as List?;
          final path = (codes != null && codes.isNotEmpty)
              ? '/api/profiles?class_codes=${codes.join(",")}'
              : '/api/profiles';
          return ApiConfig.instance.get(path);
        case 'timetable.list':
          return ApiConfig.instance.get('/api/timetable');
        // Add more if needed, otherwise fallback to error or just return empty
      }
    }
    final request = jsonEncode({'action': action, 'payload': payload});
    final args = <String>['call', '--data-dir', dataDir, '--request', request];
    final res = await Process.run(exePath, args,
        stdoutEncoding: utf8, stderrEncoding: utf8);
    final decoded = _decode(res);

    // Simulated backend filtering for legacy CLI
    if (decoded['ok'] == true && action == 'profiles.list') {
      final codes = payload['class_codes'] as List?;
      if (codes != null && codes.isNotEmpty) {
        final data = decoded['data'] as Map<String, dynamic>;
        final items = (data['items'] as List?) ?? [];
        final filteredItems = items.where((item) {
          final itemClass = (item['class_code'] ?? '').toString().trim();
          if (item['role'] == 'teacher') {
            final teacherClasses =
                itemClass.split('|').map((e) => e.trim()).toList();
            return teacherClasses.any((c) => codes.contains(c));
          }
          return codes.contains(itemClass);
        }).toList();
        data['items'] = filteredItems;
      }
    }

    return decoded;
  }

  Map<String, dynamic> _decode(ProcessResult res) {
    final stdoutStr = (res.stdout is String)
        ? (res.stdout as String)
        : utf8.decode(res.stdout as List<int>);
    final stderrStr = (res.stderr is String)
        ? (res.stderr as String)
        : utf8.decode(res.stderr as List<int>);

    if (stdoutStr.trim().isEmpty) {
      return {
        'ok': false,
        'error': {
          'code': 'empty_output',
          'message':
              stderrStr.trim().isEmpty ? 'empty output' : stderrStr.trim()
        },
      };
    }

    final decoded = jsonDecode(stdoutStr) as Map<String, dynamic>;
    if (decoded['ok'] == true) return decoded;

    if (decoded['error'] is Map<String, dynamic>) return decoded;
    return {
      'ok': false,
      'error': {
        'code': 'unknown_error',
        'message': stderrStr.trim().isEmpty ? 'unknown error' : stderrStr.trim()
      },
    };
  }
}
