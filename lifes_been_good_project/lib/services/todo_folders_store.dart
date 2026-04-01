import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class TodoFoldersStore {
  final String dataDir;

  const TodoFoldersStore({required this.dataDir});

  File get _file => File(p.join(dataDir, 'todo_folders.json'));

  Future<List<String>> listFolders() async {
    final set = <String>{'默认'};
    try {
      if (!await _file.exists()) {
        final list = set.toList()..sort();
        return list;
      }
      final content = await _file.readAsString(encoding: utf8);
      final decoded = jsonDecode(content);
      if (decoded is List) {
        for (final e in decoded) {
          final s = e.toString().trim();
          if (s.isNotEmpty) set.add(s);
        }
      }
    } catch (_) {}
    final list = set.toList()..sort();
    return list;
  }

  Future<void> upsertFolder(String name) async {
    final v = name.trim();
    if (v.isEmpty) return;
    final folders = await listFolders();
    final set = folders.toSet()..add(v);
    final list = set.toList()..sort();
    await _file.writeAsString(jsonEncode(list), encoding: utf8);
  }

  Future<void> deleteFolder(String name) async {
    final v = name.trim();
    if (v.isEmpty || v == '默认') return;
    final folders = await listFolders();
    final set = folders.toSet()..remove(v);
    final list = set.toList()..sort();
    await _file.writeAsString(jsonEncode(list), encoding: utf8);
  }
}

