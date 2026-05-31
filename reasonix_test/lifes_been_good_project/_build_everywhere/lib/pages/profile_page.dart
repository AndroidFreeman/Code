import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../services/local_profiles.dart';
import '../state/session.dart';
import '../widgets/expressive_ui.dart';

class ProfilePage extends StatefulWidget {
  final Session session;

  const ProfilePage({super.key, required this.session});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = false;
  String _status = '';
  String _avatarPath = '';

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _dormCtrl;
  late TextEditingController _signatureCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.session.profile;
    _nameCtrl = TextEditingController(text: p.displayName);
    _phoneCtrl = TextEditingController(text: p.phone);
    _emailCtrl = TextEditingController(text: p.email);
    _dormCtrl = TextEditingController(text: p.dorm);
    _signatureCtrl = TextEditingController(text: p.signature);
    _avatarPath = p.avatar;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _dormCtrl.dispose();
    _signatureCtrl.dispose();
    super.dispose();
  }

  bool _isPickingAvatar = false;

  Future<void> _pickAvatar() async {
    if (_isPickingAvatar) return;
    _isPickingAvatar = true;
    final loc = Provider.of<LocaleProvider>(context, listen: false);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.single.path;
        if (path == null || path.isEmpty) {
          if (mounted)
            showExpressiveSnackBar(
                context, loc.t('无法读取文件', 'Failed to read file'));
          return;
        }

        final file = File(path);
        if (!await file.exists()) {
          if (mounted)
            showExpressiveSnackBar(
                context, loc.t('文件不存在', 'File does not exist'));
          return;
        }

        final size = await file.length();
        if (size == 0) {
          if (mounted)
            showExpressiveSnackBar(context, loc.t('文件为空', 'File is empty'));
          return;
        }
        // Limit to 2MB to prevent OOM on Android
        if (size > 2 * 1024 * 1024) {
          if (mounted)
            showExpressiveSnackBar(context,
                loc.t('图片过大，请选择小于 2MB 的图片', 'Image too large, must be < 2MB'));
          return;
        }

        if (!mounted) return;

        if (Platform.isWindows || Platform.isLinux) {
          setState(() {
            _avatarPath = path;
          });
          return;
        }

        final theme = Theme.of(context);
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 80,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: loc.t('裁切头像', 'Crop Avatar'),
              toolbarColor: theme.colorScheme.surface,
              toolbarWidgetColor: theme.colorScheme.onSurface,
              activeControlsWidgetColor: theme.colorScheme.primary,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: loc.t('裁切头像', 'Crop Avatar'),
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
            WebUiSettings(
              context: context,
              presentStyle: WebPresentStyle.dialog,
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _avatarPath = croppedFile.path;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        showExpressiveSnackBar(
            context, '${loc.t('选择图片失败', 'Failed to pick image')}: $e');
      }
    } finally {
      _isPickingAvatar = false;
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Provider.of<LocaleProvider>(context, listen: false)
            .t('确认退出', 'Confirm Logout')),
        content: Text(Provider.of<LocaleProvider>(context, listen: false)
            .t('您确定要退出当前账号吗？', 'Are you sure you want to logout?')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(Provider.of<LocaleProvider>(context, listen: false)
                  .t('取消', 'Cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(Provider.of<LocaleProvider>(context, listen: false)
                  .t('退出', 'Logout'))),
        ],
      ),
    );
    if (confirm == true) {
      widget.session.logout();
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _save() async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    setState(() {
      _loading = true;
      _status = '';
    });

    try {
      String finalAvatar = _avatarPath;
      if (_avatarPath.isNotEmpty &&
          !_avatarPath.startsWith('http') &&
          !_avatarPath.startsWith('data:image')) {
        final file = File(_avatarPath);
        if (await file.exists()) {
          final size = await file.length();
          if (size > 10 * 1024 * 1024) {
            throw Exception(loc.t('图片过大，无法保存', 'Image too large to save'));
          }
          final bytes = await file.readAsBytes();
          final ext = _avatarPath.contains('.')
              ? _avatarPath
                  .substring(_avatarPath.lastIndexOf('.'))
                  .toLowerCase()
              : '.jpg';
          final format =
              ext == '.png' ? 'png' : (ext == '.gif' ? 'gif' : 'jpeg');
          final base64String = base64Encode(bytes);
          finalAvatar = 'data:image/$format;base64,$base64String';
        }
      } else if (_avatarPath.startsWith('data:image')) {
        finalAvatar = _avatarPath;
      }

      await LocalProfiles.updateProfile(
        dataDir: widget.session.dataDir,
        profileId: widget.session.profile.id,
        displayName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        dorm: _dormCtrl.text.trim(),
        avatar: finalAvatar,
        signature: _signatureCtrl.text.trim(),
      );

      // Update session profile in memory using copyWith to preserve position and other fields
      widget.session.profile = widget.session.profile.copyWith(
        displayName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        dorm: _dormCtrl.text.trim(),
        avatar: finalAvatar,
        signature: _signatureCtrl.text.trim(),
      );
      widget.session.notifyDataChanged(modules: const ['profiles']);

      if (mounted) {
        setState(() {
          _avatarPath = finalAvatar;
        });
        showExpressiveSnackBar(context, loc.t('保存成功', 'Saved'));
      }
    } catch (e) {
      setState(() {
        _status = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String? _resolveAvatarUrlOrPath(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    if (v.startsWith('data:image')) return v;
    final uri = Uri.tryParse(v);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return v;
    }
    if (uri != null && uri.scheme == 'file') {
      return uri.toFilePath();
    }
    if (v.contains(':\\') || v.startsWith('/')) return v;
    return '${widget.session.dataDir}/$v';
  }

  DecorationImage? _getAvatarImage() {
    final resolved = _resolveAvatarUrlOrPath(_avatarPath) ?? '';
    return AvatarImageProvider.getDecorationImage(resolved);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.profile.displayWithRealName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_status.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(28),
                ),
                child:
                    Text(_status, style: TextStyle(color: cs.onErrorContainer)),
              ),

            // Avatar section
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                        image: _getAvatarImage(),
                      ),
                      alignment: Alignment.center,
                      child: _avatarPath.isEmpty
                          ? Text(
                              widget.session.profile.displayName.isNotEmpty
                                  ? widget.session.profile.displayName
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 40,
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.surface, width: 2),
                        ),
                        child: Icon(Icons.camera_alt,
                            size: 20, color: cs.onPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline),
                        hintText: loc.t('用户名 / 昵称', 'Username / Nickname'),
                        filled: true,
                        fillColor:
                            cs.surfaceContainerHighest.withValues(alpha: 77),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneCtrl,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.phone_outlined),
                        hintText: loc.t('手机号', 'Phone'),
                        filled: true,
                        fillColor:
                            cs.surfaceContainerHighest.withValues(alpha: 77),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailCtrl,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_outlined),
                        hintText: loc.t('邮箱', 'Email'),
                        filled: true,
                        fillColor:
                            cs.surfaceContainerHighest.withValues(alpha: 77),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _dormCtrl,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.home_outlined),
                        hintText: loc.t('寝室', 'Dormitory'),
                        filled: true,
                        fillColor:
                            cs.surfaceContainerHighest.withValues(alpha: 77),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _signatureCtrl,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.edit_note),
                        hintText: loc.t('个性签名', 'Bio'),
                        filled: true,
                        fillColor:
                            cs.surfaceContainerHighest.withValues(alpha: 77),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text(loc.t('保存修改', 'Save Changes'),
                        style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
