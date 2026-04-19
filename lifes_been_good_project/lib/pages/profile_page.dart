import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/profile.dart';
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

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      if (!mounted) return;
      final path = result.files.single.path!;

      if (Platform.isWindows || Platform.isLinux) {
        setState(() {
          _avatarPath = path;
        });
        return;
      }

      final loc = Provider.of<LocaleProvider>(context, listen: false);
      final theme = Theme.of(context);

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
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
  }

  Future<void> _save() async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    setState(() {
      _loading = true;
      _status = '';
    });

    try {
      await LocalProfiles.updateProfile(
        dataDir: widget.session.dataDir,
        profileId: widget.session.profile.id,
        displayName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        dorm: _dormCtrl.text.trim(),
        avatar: _avatarPath,
        signature: _signatureCtrl.text.trim(),
      );

      // Update session profile in memory using copyWith to preserve position and other fields
      widget.session.profile = widget.session.profile.copyWith(
        displayName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        dorm: _dormCtrl.text.trim(),
        avatar: _avatarPath,
        signature: _signatureCtrl.text.trim(),
      );

      if (mounted) {
        showExpressiveSnackBar(context, loc.t('保存成功', 'Saved'));
        setState(() {}); // refresh UI
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.profile.displayWithRealName),
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
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(32),
                        image: _avatarPath.isNotEmpty &&
                                File(_avatarPath).existsSync()
                            ? DecorationImage(
                                image: FileImage(File(_avatarPath)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child:
                          _avatarPath.isEmpty || !File(_avatarPath).existsSync()
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
