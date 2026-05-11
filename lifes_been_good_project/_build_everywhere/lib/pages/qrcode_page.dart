import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../main.dart';
import '../services/api_config.dart';
import '../state/session.dart';
import '../widgets/expressive_ui.dart';

import 'package:path/path.dart' as p;

class QrCodePage extends StatefulWidget {
  final Session session;
  const QrCodePage({super.key, required this.session});

  @override
  State<QrCodePage> createState() => _QrCodePageState();
}

class _QrCodePageState extends State<QrCodePage> {
  // Mock data for demonstration purposes, since cloud storage isn't fully set up for this yet
  List<Map<String, String>> _uploadedQRCodes = [];
  bool _isLoading = false;
  bool _isSelectionMode = false;
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadQRCodes();
  }

  Future<void> _loadQRCodes() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (ApiConfig.instance.useCloud) {
        final res = await ApiConfig.instance.get('/api/qrcodes');
        if (res['ok'] == true && res['data'] != null) {
          final data = (res['data'] is List)
              ? res['data'] as List
              : (res['data']['items'] as List?);
          if (data != null) {
            setState(() {
              _uploadedQRCodes.clear();
              _uploadedQRCodes.addAll(
                  data.map((e) => Map<String, String>.from(e as Map)).toList());
            });
          }
        }
      } else {
        final res = await widget.session.features
            .jsonOp(action: 'read', file: 'uploaded_qrcodes.json');
        if (res['ok'] == true && res['data'] != null) {
          final data = res['data']['items'] as List?;
          if (data != null) {
            setState(() {
              _uploadedQRCodes.clear();
              _uploadedQRCodes.addAll(
                  data.map((e) => Map<String, String>.from(e as Map)).toList());
            });
          }
        }
      }
    } catch (_) {}
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveQRCodes() async {
    try {
      if (ApiConfig.instance.useCloud) {
        await ApiConfig.instance
            .post('/api/qrcodes', {'items': _uploadedQRCodes});
      } else {
        await widget.session.features.jsonOp(
          action: 'write',
          file: 'uploaded_qrcodes.json',
          data: {'items': _uploadedQRCodes},
        );
      }
    } catch (_) {}
  }

  Future<void> _uploadQRCode() async {
    final loc = Provider.of<LocaleProvider>(context, listen: false);

    // 校验：每人限1张
    if (_uploadedQRCodes
        .any((element) => element['id'] == widget.session.profile.id)) {
      showExpressiveSnackBar(
          context,
          loc.t('已上传，请先删除再重新上传',
              'Already uploaded, please delete first before re-uploading'));
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.single.path;
        if (path == null) return;

        final file = File(path);
        if (!await file.exists()) return;

        final size = await file.length();
        if (size > 100 * 1024) {
          // 100kB limit
          if (mounted)
            showExpressiveSnackBar(
                context, loc.t('图片不能超过100kB', 'Image cannot exceed 100kB'));
          return;
        }

        final theme = Theme.of(context);
        String finalPath = path;

        // Skip cropping on desktop platforms where image_cropper might not be supported
        if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
          CroppedFile? croppedFile;
          try {
            croppedFile = await ImageCropper().cropImage(
              sourcePath: path,
              aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
              compressFormat: ImageCompressFormat.jpg,
              compressQuality: 80,
              uiSettings: [
                AndroidUiSettings(
                  toolbarTitle: loc.t('裁切二维码', 'Crop QR Code'),
                  toolbarColor: theme.colorScheme.surface,
                  toolbarWidgetColor: theme.colorScheme.onSurface,
                  activeControlsWidgetColor: theme.colorScheme.primary,
                  initAspectRatio: CropAspectRatioPreset.square,
                  lockAspectRatio: true,
                ),
                IOSUiSettings(
                  title: loc.t('裁切二维码', 'Crop QR Code'),
                  aspectRatioLockEnabled: true,
                  resetAspectRatioEnabled: false,
                ),
              ],
            );
          } on MissingPluginException catch (_) {
            if (mounted)
              showExpressiveSnackBar(
                  context,
                  loc.t('裁剪插件未正确安装，请重启应用',
                      'Crop plugin not installed, please restart'));
            return;
          } on PlatformException catch (e) {
            if (e.code == 'photo_access_denied' ||
                e.code == 'camera_access_denied') {
              if (mounted)
                showExpressiveSnackBar(context,
                    loc.t('请授予相册权限', 'Please grant photo permissions'));
            } else {
              if (mounted)
                showExpressiveSnackBar(
                    context,
                    loc.t('图片处理失败: ${e.message}',
                        'Image processing failed: ${e.message}'));
            }
            return;
          }
          if (croppedFile != null) {
            finalPath = croppedFile.path;
          } else {
            return; // user canceled cropping
          }
        }

        // Convert to base64 for persistence and sync
        final bytes = await File(finalPath).readAsBytes();
        final base64Content = base64Encode(bytes);
        final ext = p.extension(finalPath).toLowerCase().replaceAll('.', '');
        final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
        final dataUrl = 'data:$mimeType;base64,$base64Content';

        setState(() {
          _uploadedQRCodes.removeWhere(
              (element) => element['id'] == widget.session.profile.id);
          _uploadedQRCodes.add({
            'id': widget.session.profile.id,
            'name': widget.session.profile.displayName,
            'path': dataUrl,
          });
        });
        unawaited(_saveQRCodes());
        if (mounted)
          showExpressiveSnackBar(
              context, loc.t('上传成功', 'Uploaded successfully'));
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted)
        showExpressiveSnackBar(
            context, loc.t('发生未知错误', 'An unknown error occurred'));
    }
  }

  void _batchDelete({List<String>? ids}) {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('确认删除', 'Confirm Delete')),
        content: Text(loc.t('是否确认删除所选二维码？',
            'Are you sure you want to delete the selected QR codes?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.t('取消', 'Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                if (ids != null) {
                  _uploadedQRCodes
                      .removeWhere((item) => ids.contains(item['id']));
                } else {
                  _uploadedQRCodes.clear();
                }
              });
              unawaited(_saveQRCodes());
              showExpressiveSnackBar(context, loc.t('已删除', 'Deleted'));
            },
            child: Text(loc.t('确定', 'Confirm')),
          ),
        ],
      ),
    );
  }

  void _batchDownload({List<String>? ids}) {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    showExpressiveSnackBar(
        context, loc.t('已开始后台下载...', 'Download started in background...'));
    // Simulate background download
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        showExpressiveSnackBar(
            context, loc.t('批量下载完成', 'Batch download completed'));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context);
    final cs = Theme.of(context).colorScheme;

    bool canDeleteSelection = true;
    if (!widget.session.isTeacher && !widget.session.isPowerCadre) {
      canDeleteSelection =
          _selectedIds.every((id) => id == widget.session.profile.id);
    }

    final width = MediaQuery.of(context).size.width;
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final useDesktopFlow =
        width >= 1024 || (Platform.isAndroid && shortestSide >= 600);
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final showDrawerButton = !useDesktopFlow || isPortrait;

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedIds.clear();
                  });
                },
              ),
              title: Text('${_selectedIds.length} ${loc.t('已选择', 'Selected')}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: _selectedIds.isNotEmpty
                      ? () {
                          // download selected
                          _batchDownload(ids: _selectedIds.toList());
                          setState(() {
                            _isSelectionMode = false;
                            _selectedIds.clear();
                          });
                        }
                      : null,
                ),
                if (canDeleteSelection)
                  IconButton(
                    icon: Icon(Icons.delete, color: cs.error),
                    onPressed: _selectedIds.isNotEmpty
                        ? () {
                            // delete selected
                            _batchDelete(ids: _selectedIds.toList());
                            setState(() {
                              _isSelectionMode = false;
                              _selectedIds.clear();
                            });
                          }
                        : null,
                  ),
              ],
            )
          : AppBar(
              title: Text(loc.t('班级二维码', 'Class QR Codes')),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              leadingWidth:
                  _isSelectionMode ? 56.0 : (showDrawerButton ? 56.0 : 0.0),
              leading: _isSelectionMode
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = false;
                          _selectedIds.clear();
                        });
                      },
                    )
                  : showDrawerButton
                      ? Builder(
                          builder: (context) {
                            return IconButton(
                              icon: const Icon(Icons.menu),
                              onPressed: () {
                                ScaffoldState? scaffold =
                                    Scaffold.maybeOf(context);
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
                if (widget.session.isTeacher || widget.session.isPowerCadre)
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    tooltip: loc.t('更多选项', 'More Options'),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (ctx) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.download),
                                title: Text(loc.t('批量下载', 'Batch Download')),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _batchDownload();
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.delete, color: cs.error),
                                title: Text(loc.t('批量删除', 'Batch Delete'),
                                    style: TextStyle(color: cs.error)),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _batchDelete();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: loc.t('批量下载', 'Batch Download'),
                    onPressed: _batchDownload,
                  ),
                IconButton(
                  icon: const Icon(Icons.upload_rounded),
                  onPressed: _uploadQRCode,
                  tooltip: loc.t('上传我的二维码', 'Upload My QR Code'),
                ),
              ],
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _uploadedQRCodes.isEmpty
              ? Center(
                  child: Text(
                    loc.t('暂无同学上传', 'No classmates uploaded yet'),
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _uploadedQRCodes.length,
                  itemBuilder: (context, index) {
                    final item = _uploadedQRCodes[index];
                    final isSelected = _selectedIds.contains(item['id']);

                    return GestureDetector(
                      onTap: () {
                        if (_isSelectionMode) {
                          setState(() {
                            if (isSelected) {
                              _selectedIds.remove(item['id']);
                              if (_selectedIds.isEmpty) {
                                _isSelectionMode = false;
                              }
                            } else {
                              _selectedIds.add(item['id']!);
                            }
                          });
                        } else {
                          // Fullscreen preview
                          showDialog(
                            context: context,
                            builder: (ctx) => Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: EdgeInsets.zero,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pop(ctx),
                                    child: InteractiveViewer(
                                      panEnabled: true,
                                      minScale: 0.5,
                                      maxScale: 4.0,
                                      child: Image(
                                        image: AvatarImageProvider.get(
                                                item['path']!) ??
                                            const AssetImage(
                                                'assets/images/logo.png'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                      onLongPress: () {
                        if (!_isSelectionMode) {
                          setState(() {
                            _isSelectionMode = true;
                            _selectedIds.add(item['id']!);
                          });
                        }
                      },
                      child: Column(
                        children: [
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: AvatarImageProvider.get(
                                              item['path']!) ??
                                          const AssetImage(
                                              'assets/images/logo.png'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: cs.primary.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.check_circle,
                                          color: Colors.white, size: 36),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['name'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
