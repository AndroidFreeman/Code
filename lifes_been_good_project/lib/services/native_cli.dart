import 'dart:convert';
import 'dart:io';

class NativeCli {
  final String exePath;
  final String dataDir;

  const NativeCli({required this.exePath, required this.dataDir});

  Future<Map<String, dynamic>> init({required bool seed}) async {
    final args = <String>['system.init', '--data-dir', dataDir];
    if (seed) args.add('--seed');

    final res = await Process.run(exePath, args, stdoutEncoding: utf8, stderrEncoding: utf8);
    return _decode(res);
  }

  Future<Map<String, dynamic>> call(String action, Map<String, dynamic> payload) async {
    final request = jsonEncode({'action': action, 'payload': payload});
    final args = <String>['call', '--data-dir', dataDir, '--request', request];
    final res = await Process.run(exePath, args, stdoutEncoding: utf8, stderrEncoding: utf8);
    return _decode(res);
  }

  Map<String, dynamic> _decode(ProcessResult res) {
    final stdoutStr = (res.stdout is String) ? (res.stdout as String) : utf8.decode(res.stdout as List<int>);
    final stderrStr = (res.stderr is String) ? (res.stderr as String) : utf8.decode(res.stderr as List<int>);

    if (stdoutStr.trim().isEmpty) {
      return {
        'ok': false,
        'error': {'code': 'empty_output', 'message': stderrStr.trim().isEmpty ? 'empty output' : stderrStr.trim()},
      };
    }

    final decoded = jsonDecode(stdoutStr) as Map<String, dynamic>;
    if (decoded['ok'] == true) return decoded;

    if (decoded['error'] is Map<String, dynamic>) return decoded;
    return {
      'ok': false,
      'error': {'code': 'unknown_error', 'message': stderrStr.trim().isEmpty ? 'unknown error' : stderrStr.trim()},
    };
  }
}

