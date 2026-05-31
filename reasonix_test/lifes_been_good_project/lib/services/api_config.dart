import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

class ApiConfig extends ChangeNotifier {
  bool useCloud = true;
  String cloudIp = 'http://47.115.173.254:8080';
  String token = '';

  static final ApiConfig instance = ApiConfig._();
  ApiConfig._();

  Future<void> load(String dataDir) async {
    try {
      final f = File(p.join(dataDir, 'cloud_config.json'));
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString());
        useCloud = data['useCloud'] ?? true;
        cloudIp = data['cloudIp'] ?? 'http://47.115.173.254:8080';
        token = data['token'] ?? '';
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiConfig.load error: $e');
      }
    }
  }

  Future<void> save(String dataDir) async {
    try {
      final f = File(p.join(dataDir, 'cloud_config.json'));
      await f.writeAsString(jsonEncode({
        'useCloud': useCloud,
        'cloudIp': cloudIp,
        'token': token,
      }));
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiConfig.save error: $e');
      }
    }
  }

  static String replaceLocalhost(String url) {
    if (!instance.useCloud) return url;
    final cloudBase = instance.cloudIp.trim();
    if (cloudBase.isEmpty) return url;

    // Parse the cloud base to get just the host (and port)
    String hostPort = cloudBase.replaceFirst(RegExp(r'^https?://'), '');
    if (hostPort.endsWith('/')) {
      hostPort = hostPort.substring(0, hostPort.length - 1);
    }

    return url
        .replaceAll('localhost', hostPort)
        .replaceAll('127.0.0.1', hostPort);
  }

  String _cleanUrl(String path) {
    var base = cloudIp.trim();
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    if (!path.startsWith('/')) {
      path = '/$path';
    }
    return '$base$path';
  }

  String urlFor(String path) => _cleanUrl(path);

  Map<String, String> _authHeaders() {
    final headers = <String, String>{};
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final res = await http.get(Uri.parse(_cleanUrl(path)), headers: _authHeaders());
      return _parseResponse(res);
    } catch (e) {
      return {
        'ok': false,
        'error': {'code': 'network_error', 'message': e.toString()}
      };
    }
  }

  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      headers.addAll(_authHeaders());
      final res = await http.post(
        Uri.parse(_cleanUrl(path)),
        headers: headers,
        body: jsonEncode(body),
      );
      return _parseResponse(res);
    } catch (e) {
      return {
        'ok': false,
        'error': {'code': 'network_error', 'message': e.toString()}
      };
    }
  }

  Future<Map<String, dynamic>> put(String path,
      [Map<String, dynamic>? body]) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      headers.addAll(_authHeaders());
      final res = await http.put(
        Uri.parse(_cleanUrl(path)),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _parseResponse(res);
    } catch (e) {
      return {
        'ok': false,
        'error': {'code': 'network_error', 'message': e.toString()}
      };
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final res = await http.delete(Uri.parse(_cleanUrl(path)), headers: _authHeaders());
      return _parseResponse(res);
    } catch (e) {
      return {
        'ok': false,
        'error': {'code': 'network_error', 'message': e.toString()}
      };
    }
  }

  Map<String, dynamic> _parseResponse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return {'ok': true};
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded.containsKey('ok')) {
          final map = Map<String, dynamic>.from(decoded as Map);
          // C CLI returns arrays wrapped in {"items": [...]}, so we mimic this
          // without mutating the original decoded map
          if (map['data'] is List) {
            map['data'] = {'items': map['data']};
          }
          return map;
        }
        return {
          'ok': true,
          'data': decoded is List ? {'items': decoded} : decoded
        };
      } catch (_) {
        return {'ok': true, 'data': res.body};
      }
    } else {
      return {
        'ok': false,
        'error': {'code': 'http_${res.statusCode}', 'message': res.body}
      };
    }
  }
}
