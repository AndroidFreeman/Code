import 'dart:convert';

import '../services/native_features.dart';

class TodoFoldersStore {
  final String dataDir;
  final String? nativeLibDir;

  const TodoFoldersStore({required this.dataDir, this.nativeLibDir});

  Future<List<String>> listFolders() async {
    final set = <String>{'默认'};
    try {
      final features = NativeFeatures(dataDir: dataDir, nativeLibDir: nativeLibDir);
      final res = await features.jsonOp(action: 'read', file: 'todo_folders.json');
      if (res['ok'] == true && res['data'] != null) {
        final decoded = res['data'];
        if (decoded is List) {
          for (final e in decoded) {
            final s = e.toString().trim();
            if (s.isNotEmpty) set.add(s);
          }
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
    final features = NativeFeatures(dataDir: dataDir, nativeLibDir: nativeLibDir);
    await features.jsonOp(action: 'write', file: 'todo_folders.json', data: list);
  }

  Future<void> deleteFolder(String name) async {
    final v = name.trim();
    if (v.isEmpty || v == '默认') return;
    final folders = await listFolders();
    final set = folders.toSet()..remove(v);
    final list = set.toList()..sort();
    final features = NativeFeatures(dataDir: dataDir, nativeLibDir: nativeLibDir);
    await features.jsonOp(action: 'write', file: 'todo_folders.json', data: list);
  }
}

