import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../services/bootstrapper.dart';

class BootstrapPage extends StatefulWidget {
  final void Function(BootstrapResult result) onReady;

  const BootstrapPage({super.key, required this.onReady});

  @override
  State<BootstrapPage> createState() => _BootstrapPageState();
}

class _BootstrapPageState extends State<BootstrapPage> {
  String _status = '准备启动...';
  bool _running = false;
  String _error = '';

  String _displayStatus(LocaleProvider loc) {
    if (!loc.isEnglish) return _status;
    final s = _status.trim();
    const map = <String, String>{
      '准备启动...': 'Starting up...',
      '准备数据目录...': 'Preparing data directory...',
      '检查本地二进制...': 'Checking local binaries...',
      '初始化数据结构...': 'Initializing data...',
      '安装本地 CLI...': 'Installing local CLI...',
      '检查并同步功能二进制...': 'Syncing feature binaries...',
    };
    final direct = map[s];
    if (direct != null) return direct;
    if (s.startsWith('正在安装 ') && s.endsWith('...')) {
      final name = s.substring('正在安装 '.length, s.length - 3);
      return 'Installing $name...';
    }
    return _status;
  }

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    if (_running) return;
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    setState(() {
      _running = true;
      _error = '';
      _status = loc.t('准备启动...', 'Starting up...');
    });

    BootstrapResult? result;
    try {
      result = await Bootstrapper.run(
        onProgress: (m) {
          if (!mounted) return;
          setState(() {
            _status = m;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _running = false;
        _error = loc.t('异常: $e', 'Exception: $e');
      });
      return;
    }

    if (!mounted) return;
    if (result == null || !result.ok) {
      setState(() {
        _running = false;
        _error = loc.isEnglish
            ? (result?.messageEn ?? result?.message ?? 'Unknown error')
            : (result?.message ?? '未知错误');
      });
      return;
    }
    widget.onReady(result);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = Provider.of<LocaleProvider>(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4F7DF3),
              Color(0xFF8B5CF6),
              Color(0xFFF8FAFC),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 38),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 24),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.school, color: cs.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.t('正在准备本地环境', 'Preparing local environment'),
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _displayStatus(loc),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (_error.trim().isNotEmpty) ...[
                    Text(
                      _error,
                      style: TextStyle(color: cs.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _running ? null : _run,
                      child: Text(loc.t('重试', 'Retry')),
                    ),
                  ] else ...[
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
