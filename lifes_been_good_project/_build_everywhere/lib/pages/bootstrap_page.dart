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
  bool _running = false;
  String _error = '';

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
    });

    late final BootstrapResult result;
    try {
      result = await Bootstrapper.run(
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
    if (!result.ok) {
      setState(() {
        _running = false;
        _error = loc.isEnglish
            ? (result.messageEn ?? result.message)
            : result.message;
      });
      return;
    }
    widget.onReady(result);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = Provider.of<LocaleProvider>(context);
    if (_error.trim().isEmpty) {
      return const Scaffold(
        body: SizedBox.expand(),
      );
    }
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 96)),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    loc.t('启动失败', 'Startup failed'),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: cs.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _running ? null : _run,
                    child: Text(loc.t('重试', 'Retry')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
