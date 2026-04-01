import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/profile.dart';
import '../services/local_profiles.dart';
import '../services/native_cli.dart';
import '../services/native_features.dart';
import '../state/session.dart';
import '../widgets/expressive_ui.dart';

class LoginPage extends StatefulWidget {
  final String dataDir;
  final String cliPath;
  final String? nativeLibDir;
  final void Function(Session session) onLoggedIn;

  const LoginPage({
    super.key,
    required this.dataDir,
    required this.cliPath,
    this.nativeLibDir,
    required this.onLoggedIn,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  bool _loading = false;
  String _status = '';

  String _role = 'student';
  bool _isRegister = false;

  final _accountCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  List<String> _allClasses = [];
  String? _selectedClass;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await LocalProfiles.getAllClasses(widget.dataDir);
      if (mounted) {
        setState(() {
          _allClasses = classes;
          if (classes.isNotEmpty) {
            _selectedClass = classes.first;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _accountCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String _t(bool isEn, String zh, String en) => isEn ? en : zh;

  String _accountLabel(bool isEn) {
    if (_role == 'teacher') return _t(isEn, '工号', 'Staff ID');
    return _t(isEn, '学号', 'Student ID');
  }

  String _translateKnownError(bool isEn, String msg) {
    if (!isEn) return msg;
    final m = msg.trim();
    const map = <String, String>{
      '账号或密码错误': 'Incorrect account or password',
      '工号已存在': 'Staff ID already exists',
      '学号已存在': 'Student ID already exists',
      '密码至少 6 位': 'Password must be at least 6 characters',
      '账号不能为空': 'Account cannot be empty',
      '老师工号必须以 T 开头': 'Staff ID must start with "T"',
      '学生学号必须以 S 开头': 'Student ID must start with "S"',
      '请输入姓名': 'Please enter your name',
    };
    return map[m] ?? msg;
  }

  Future<void> _submit() async {
    final isEn = Provider.of<LocaleProvider>(context, listen: false)
            .locale
            .languageCode ==
        'en';
    final account = _accountCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text;
    final classCode = _selectedClass ?? 'CLS1';

    final validateMsg = LocalProfiles.validateAccountNo(
      role: _role,
      accountNo: account,
    );
    if (validateMsg != null) {
      setState(() {
        _status = _translateKnownError(isEn, validateMsg);
      });
      return;
    }

    if (account.isEmpty || password.isEmpty) {
      setState(() {
        _status = _t(isEn, '请输入${_accountLabel(isEn)}和密码',
            'Please enter ${_accountLabel(isEn)} and password');
      });
      return;
    }
    if (_isRegister && name.isEmpty) {
      setState(() {
        _status = _t(isEn, '请输入姓名', 'Please enter your name');
      });
      return;
    }
    if (_isRegister && password.length < 6) {
      setState(() {
        _status =
            _t(isEn, '密码至少 6 位', 'Password must be at least 6 characters');
      });
      return;
    }

    setState(() {
      _loading = true;
      _status = '';
    });

    try {
      Profile profile;
      if (_isRegister) {
        profile = await LocalProfiles.register(
          dataDir: widget.dataDir,
          role: _role,
          accountNo: account,
          fullName: name,
          password: password,
          phone: phone,
          classCode: classCode,
        );
      }
      profile = await LocalProfiles.login(
        dataDir: widget.dataDir,
        role: _role,
        accountNo: account,
        password: password,
      );

      final position = await LocalProfiles.loadStudentPosition(
        dataDir: widget.dataDir,
        profile: profile,
      );

      final features = NativeFeatures(
        dataDir: widget.dataDir,
        nativeLibDir: widget.nativeLibDir,
      );
      NativeCli? cli;
      if (File(widget.cliPath).existsSync()) {
        cli = NativeCli(exePath: widget.cliPath, dataDir: widget.dataDir);
      }
      final session = Session(
        cli: cli,
        features: features,
        dataDir: widget.dataDir,
        profile: profile,
        studentPosition: position,
      );
      try {
        await LocalProfiles.saveAutoLogin(
          dataDir: widget.dataDir,
          profileId: profile.id,
        );
      } catch (_) {}
      if (!mounted) return;
      widget.onLoggedIn(session);
    } catch (e) {
      setState(() {
        _loading = false;
        _status = _translateKnownError(isEn, e.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isEn = localeProvider.locale.languageCode == 'en';

    final roleLabel = _role == 'teacher'
        ? _t(isEn, '老师', 'Teacher')
        : _t(isEn, '学生', 'Student');
    final titleText = _isRegister
        ? _t(isEn, '$roleLabel 注册', '$roleLabel Sign up')
        : _t(isEn, '$roleLabel 登录', '$roleLabel Sign in');
    final subtitleText = _isRegister
        ? _t(isEn, '请填写信息完成注册', 'Fill in the form to create your account')
        : _t(isEn, '欢迎回来，请登录您的账号', 'Welcome back. Please sign in');

    final roleSelector = SegmentedButton<String>(
      segments: [
        ButtonSegment(
            value: 'student',
            label: Text(_t(isEn, '学生', 'Student')),
            icon: const Icon(Icons.person)),
        ButtonSegment(
            value: 'teacher',
            label: Text(_t(isEn, '老师', 'Teacher')),
            icon: const Icon(Icons.school)),
      ],
      selected: {_role},
      onSelectionChanged: _loading
          ? null
          : (v) {
              setState(() {
                _role = v.first;
              });
            },
    );

    final modeToggle = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isRegister
              ? _t(isEn, '已有账号？', 'Already have an account?')
              : _t(isEn, '没有账号？', "Don't have an account?"),
          style: tt.bodyMedium?.copyWith(color: cs.outline),
        ),
        TextButton(
          onPressed: _loading
              ? null
              : () {
                  setState(() {
                    _isRegister = !_isRegister;
                    _status = '';
                  });
                },
          child: Text(
              _isRegister
                  ? _t(isEn, '立即登录', 'Sign in')
                  : _t(isEn, '立即注册', 'Sign up'),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );

    final card = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Card(
        elevation: 0,
        color: cs.surface.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.auto_awesome, size: 48, color: cs.primary),
                const SizedBox(height: 16),
                Text(
                  titleText,
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitleText,
                  style: tt.bodyMedium?.copyWith(color: cs.outline),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                roleSelector,
                const SizedBox(height: 24),
                TextField(
                  controller: _accountCtrl,
                  enabled: !_loading,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.account_circle_outlined),
                    labelText: _accountLabel(isEn),
                    hintText: _t(isEn, '请输入${_accountLabel(isEn)}',
                        'Enter ${_accountLabel(isEn)}'),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_isRegister) ...[
                  TextField(
                    controller: _nameCtrl,
                    enabled: !_loading,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.badge_outlined),
                      labelText: _t(isEn, '姓名', 'Name'),
                      hintText: _t(isEn, '请输入真实姓名', 'Enter your name'),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_role == 'student') ...[
                    DropdownButtonFormField<String>(
                      value: _selectedClass,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.class_outlined),
                        labelText: _t(isEn, '班级', 'Class'),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _allClasses
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: _loading
                          ? null
                          : (v) => setState(() => _selectedClass = v),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _phoneCtrl,
                    enabled: !_loading,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.phone_outlined),
                      labelText: _t(isEn, '电话', 'Phone'),
                      hintText: _t(isEn, '请输入联系电话', 'Enter your phone number'),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _passwordCtrl,
                  enabled: !_loading,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline),
                    labelText: _t(isEn, '密码', 'Password'),
                    hintText: _t(isEn, '请输入密码', 'Enter password'),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_status.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.errorContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Text(
                      _status,
                      style: tt.bodySmall?.copyWith(color: cs.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Bounceable(
                  onTap: _loading ? null : _submit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isRegister
                                ? _t(isEn, '创建账户', 'Create account')
                                : _t(isEn, '登 录', 'Sign in'),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                modeToggle,
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primaryContainer.withOpacity(0.4),
                  cs.surface,
                  cs.tertiaryContainer.withOpacity(0.2),
                ],
              ),
            ),
          ),
          // Language Switcher
          Positioned(
            top: 48,
            right: 24,
            child: Bounceable(
              onTap: () {
                localeProvider
                    .setLocale(isEn ? const Locale('zh') : const Locale('en'));
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.language, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      isEn ? 'English' : '中文',
                      style: tt.labelLarge?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Decorative circles
          Positioned(
            top: -100,
            right: -100,
            child: IgnorePointer(
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: cs.secondary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(80),
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: card,
            ),
          ),
        ],
      ),
    );
  }
}
