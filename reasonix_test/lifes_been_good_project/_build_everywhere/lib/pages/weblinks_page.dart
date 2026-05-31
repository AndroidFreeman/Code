import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../state/session.dart';
import '../widgets/expressive_ui.dart';

class WeblinksPage extends StatefulWidget {
  final Session session;
  const WeblinksPage({super.key, required this.session});

  @override
  State<WeblinksPage> createState() => _WeblinksPageState();
}

class _WeblinksPageState extends State<WeblinksPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _links = [];

  bool get _canEdit {
    final role = widget.session.profile.role;
    final pos = widget.session.studentPosition;
    if (role == 'teacher') return true;
    if (pos == 'monitor' || pos == 'study' || pos == 'publicity') return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    try {
      final features = widget.session.features;
      final res = await features.jsonOp(action: 'read', file: 'weblinks.json');
      if (res['ok'] == true && res['data'] != null) {
        final data = res['data'] as List;
        _links = data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveLinks() async {
    try {
      final features = widget.session.features;
      await features.jsonOp(
          action: 'write', file: 'weblinks.json', data: _links);
    } catch (_) {}
  }

  Future<void> _addLink() async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController(text: 'https://');
    final detailCtrl = TextEditingController();

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('添加常用网站', 'Add Web Link')),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration:
                    InputDecoration(labelText: loc.t('网站名称', 'Site Name')),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlCtrl,
                decoration: InputDecoration(labelText: loc.t('网站链接', 'URL')),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: detailCtrl,
                decoration:
                    InputDecoration(labelText: loc.t('详细信息', 'Details')),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.t('取消', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.t('确定', 'OK')),
          ),
        ],
      ),
    );

    if (res == true) {
      final name = nameCtrl.text.trim();
      final url = urlCtrl.text.trim();
      final detail = detailCtrl.text.trim();
      if (name.isEmpty || url.isEmpty) return;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        showExpressiveSnackBar(
            context,
            loc.t('链接必须以 http:// 或 https:// 开头',
                'URL must start with http:// or https://'));
        return;
      }

      if (_links.any((e) => e['url'] == url)) {
        showExpressiveSnackBar(
            context, loc.t('该域名已存在', 'Domain already exists'));
        return;
      }

      setState(() {
        _links.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': name,
          'url': url,
          'detail': detail,
          'clicks': 0,
        });
      });
      await _saveLinks();
    }
  }

  Future<void> _editLink(int index) async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final nameCtrl = TextEditingController(text: _links[index]['name']);
    final urlCtrl = TextEditingController(text: _links[index]['url']);
    final detailCtrl =
        TextEditingController(text: _links[index]['detail'] ?? '');

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('编辑网站', 'Edit Web Link')),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration:
                    InputDecoration(labelText: loc.t('网站名称', 'Site Name')),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlCtrl,
                decoration: InputDecoration(labelText: loc.t('网站链接', 'URL')),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: detailCtrl,
                decoration:
                    InputDecoration(labelText: loc.t('详细信息', 'Details')),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.t('取消', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.t('保存', 'Save')),
          ),
        ],
      ),
    );

    if (res == true) {
      final name = nameCtrl.text.trim();
      final url = urlCtrl.text.trim();
      final detail = detailCtrl.text.trim();
      if (name.isEmpty || url.isEmpty) return;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        showExpressiveSnackBar(
            context,
            loc.t('链接必须以 http:// 或 https:// 开头',
                'URL must start with http:// or https://'));
        return;
      }

      final otherLinks = List.from(_links)..removeAt(index);
      if (otherLinks.any((e) => e['url'] == url)) {
        showExpressiveSnackBar(
            context, loc.t('该域名已存在', 'Domain already exists'));
        return;
      }

      setState(() {
        _links[index]['name'] = name;
        _links[index]['url'] = url;
        _links[index]['detail'] = detail;
      });
      await _saveLinks();
    }
  }

  Future<void> _deleteLink(int index) async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('删除网站', 'Delete Web Link')),
        content: Text(loc.t('确定要删除吗？', 'Are you sure you want to delete?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.t('取消', 'Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.t('删除', 'Delete')),
          ),
        ],
      ),
    );

    if (res == true) {
      setState(() {
        _links.removeAt(index);
      });
      await _saveLinks();
    }
  }

  Future<void> _launchUrl(int index) async {
    final urlStr = _links[index]['url'] as String;
    final uri = Uri.tryParse(urlStr);
    if (uri != null) {
      setState(() {
        _links[index]['clicks'] = (_links[index]['clicks'] as int? ?? 0) + 1;
      });
      _saveLinks(); // no await
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context);
    final cs = Theme.of(context).colorScheme;

    final width = MediaQuery.of(context).size.width;
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final useDesktopFlow =
        width >= 1024 || (Platform.isAndroid && shortestSide >= 600);
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final showDrawerButton = !useDesktopFlow || isPortrait;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('常用网站', 'Web Links')),
        leadingWidth: showDrawerButton ? 56.0 : 0.0,
        leading: showDrawerButton
            ? Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      ScaffoldState? scaffold = Scaffold.maybeOf(context);
                      if (scaffold != null && !scaffold.hasDrawer) {
                        scaffold = scaffold.context
                            .findAncestorStateOfType<ScaffoldState>();
                      }
                      scaffold?.openDrawer();
                    },
                  );
                },
              )
            : const SizedBox.shrink(),
        actions: [
          if (_canEdit)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addLink,
              tooltip: loc.t('添加网站', 'Add Link'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _links.isEmpty
              ? Center(
                  child: Text(
                    loc.t('暂无常用网站', 'No web links yet'),
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _links.length,
                  itemBuilder: (context, index) {
                    final item = _links[index];
                    final uri = Uri.tryParse(item['url'] ?? '');
                    final host = uri?.host ?? '';

                    return Card(
                      elevation: 0,
                      color: cs.surfaceContainerLow,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.language, color: cs.primary),
                        ),
                        title: Text(item['name'] ?? '',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(host,
                                style: TextStyle(color: cs.onSurfaceVariant)),
                            if ((item['detail'] ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(item['detail'] ?? '',
                                    style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 12)),
                              ),
                          ],
                        ),
                        trailing: _canEdit
                            ? PopupMenuButton<String>(
                                onSelected: (val) {
                                  if (val == 'edit') _editLink(index);
                                  if (val == 'delete') _deleteLink(index);
                                },
                                itemBuilder: (ctx) => [
                                  PopupMenuItem(
                                      value: 'edit',
                                      child: Text(loc.t('编辑', 'Edit'))),
                                  PopupMenuItem(
                                      value: 'delete',
                                      child: Text(loc.t('删除', 'Delete'),
                                          style: TextStyle(color: cs.error))),
                                ],
                              )
                            : null,
                        onTap: () => _launchUrl(index),
                      ),
                    );
                  },
                ),
    );
  }
}
