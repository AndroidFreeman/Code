import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/api_config.dart';

const Curve kAppMotionCurve = Cubic(0.2, 0.0, 0.0, 1.0);
const Curve kAppEmphasisCurve = Cubic(0.2, 0.0, 0.0, 1.0);
const Duration kAppRouteTransitionDuration = Duration(milliseconds: 200);
const Duration kAppMotionDuration = Duration(milliseconds: 200);

class AvatarImageProvider {
  static const int _maxCacheEntries = 64;
  static final Map<String, ImageProvider> _cache = {};
  static final Map<String, DecorationImage> _decCache = {};
  static final List<String> _evictionQueue = [];

  static ImageProvider? get(String path) {
    if (path.isEmpty) return null;
    if (_cache.containsKey(path)) return _cache[path];

    ImageProvider? provider;
    if (path.startsWith('http')) {
      provider = NetworkImage(ApiConfig.replaceLocalhost(path));
    } else if (path.startsWith('data:image')) {
      final base64String = path.split(',').last;
      try {
        provider = MemoryImage(base64Decode(base64String));
      } catch (_) {
        return null;
      }
    } else if (File(path).existsSync()) {
      provider = FileImage(File(path));
    }

    if (provider != null) {
      _cache[path] = provider;
      _evictionQueue.add(path);
      // Evict oldest entries if cache exceeds the limit
      while (_evictionQueue.length > _maxCacheEntries) {
        final oldest = _evictionQueue.removeAt(0);
        _cache.remove(oldest);
        _decCache.remove(oldest);
      }
    }
    return provider;
  }

  static DecorationImage? getDecorationImage(String path) {
    if (path.isEmpty) return null;
    if (_decCache.containsKey(path)) return _decCache[path];

    final provider = get(path);
    if (provider == null) return null;

    final dec = DecorationImage(image: provider, fit: BoxFit.contain);
    _decCache[path] = dec;
    return dec;
  }

  static void evict(String path) {
    _cache.remove(path);
    _decCache.remove(path);
    _evictionQueue.remove(path);
  }
}

class AppSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const AppSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final forward = CurvedAnimation(parent: animation, curve: kAppMotionCurve);
    final reverse = CurvedAnimation(
      parent: secondaryAnimation,
      curve: kAppMotionCurve,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 0.92, end: 1.0).animate(forward),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(forward),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.04, 0),
          ).animate(reverse),
          child: child,
        ),
      ),
    );
  }
}

class AppScalePageRoute<T> extends PageRouteBuilder<T> {
  AppScalePageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool fullscreenDialog = false,
  }) : super(
          settings: settings,
          fullscreenDialog: fullscreenDialog,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final forward = CurvedAnimation(
              parent: animation,
              curve: kAppMotionCurve,
            );
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(forward),
                child: child,
              ),
            );
          },
        );
}

class AppSlidePageRoute<T> extends PageRouteBuilder<T> {
  AppSlidePageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool fullscreenDialog = false,
  }) : super(
          settings: settings,
          fullscreenDialog: fullscreenDialog,
          transitionDuration: kAppRouteTransitionDuration,
          reverseTransitionDuration: kAppRouteTransitionDuration,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final forward = CurvedAnimation(
              parent: animation,
              curve: kAppMotionCurve,
            );
            final reverse = CurvedAnimation(
              parent: secondaryAnimation,
              curve: kAppMotionCurve,
            );
            return FadeTransition(
              opacity: Tween<double>(begin: 0.92, end: 1.0).animate(forward),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0),
                  end: Offset.zero,
                ).animate(forward),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset.zero,
                    end: const Offset(-0.04, 0),
                  ).animate(reverse),
                  child: child,
                ),
              ),
            );
          },
        );
}

class Bounceable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final GestureTapDownCallback? onTapDown;
  final VoidCallback? onLongPress;
  final double? scale;
  final HitTestBehavior behavior;

  const Bounceable({
    super.key,
    required this.child,
    this.onTap,
    this.onTapDown,
    this.onLongPress,
    this.scale,
    this.behavior = HitTestBehavior.deferToChild,
  });

  @override
  State<Bounceable> createState() => _BounceableState();
}

class _BounceableState extends State<Bounceable>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: kAppMotionDuration,
    );
    _animation = Tween<double>(begin: 1.0, end: widget.scale ?? 0.98).animate(
      CurvedAnimation(parent: _controller, curve: kAppMotionCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _controller.forward(),
      onPointerUp: (_) => _controller.reverse(),
      onPointerCancel: (_) => _controller.reverse(),
      child: GestureDetector(
        behavior: widget.behavior,
        onTap: widget.onTap,
        onTapDown: widget.onTapDown,
        onLongPress: widget.onLongPress,
        child: ScaleTransition(
          scale: _animation,
          child: widget.child,
        ),
      ),
    );
  }
}

class SoftPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Duration duration;
  final double pressedScale;
  final Color? pressedColor;
  final HitTestBehavior behavior;

  const SoftPressable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.duration = kAppMotionDuration,
    this.pressedScale = 0.985,
    this.pressedColor,
    this.behavior = HitTestBehavior.deferToChild,
  });

  @override
  State<SoftPressable> createState() => _SoftPressableState();
}

class _SoftPressableState extends State<SoftPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scale = widget.pressedScale.clamp(0.94, 0.995);
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? scale : 1.0,
        duration: widget.duration,
        curve: kAppMotionCurve,
        child: AnimatedContainer(
          duration: widget.duration,
          curve: kAppMotionCurve,
          decoration: BoxDecoration(
            color: _pressed
                ? (widget.pressedColor ??
                    cs.primaryContainer.withValues(alpha: 64))
                : Colors.transparent,
            borderRadius: widget.borderRadius,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class ExpressiveSelector extends StatefulWidget {
  final String label;
  final String? value;
  final List<String> items;
  final Function(String) onSelected;
  final IconData? leadingIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String Function(String)? customLabelBuilder;
  final EdgeInsetsGeometry? padding;
  final TextStyle? labelTextStyle;
  final TextStyle? valueTextStyle;

  const ExpressiveSelector({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onSelected,
    this.leadingIcon,
    this.backgroundColor,
    this.foregroundColor,
    this.customLabelBuilder,
    this.padding,
    this.labelTextStyle,
    this.valueTextStyle,
  });

  @override
  State<ExpressiveSelector> createState() => _ExpressiveSelectorState();
}

class _ExpressiveSelectorState extends State<ExpressiveSelector>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  late AnimationController _animCtrl;
  late Animation<double> _heightAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _heightAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeInOutCubic,
    );
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleOpen() {
    if (_isOpen) {
      _isOpen = false;
      _animCtrl.reverse().then((_) {
        if (!_isOpen) _removeOverlay();
      });
    } else {
      _isOpen = true;
      _showOverlay();
      _animCtrl.forward();
    }
    setState(() {});
  }

  void _showOverlay() {
    _removeOverlay();
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        final tt = Theme.of(context).textTheme;
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 4),
            child: Material(
              color: Colors.transparent,
              child: AnimatedBuilder(
                animation: _animCtrl,
                builder: (context, child) {
                  return FractionalTranslation(
                    translation: Offset(0, -0.05 * (1 - _animCtrl.value)),
                    child: Opacity(
                      opacity: _opacityAnim.value,
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: _heightAnim.value,
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
                  child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 160),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.items.map((item) {
                        final isSelected = item == widget.value;
                        return InkWell(
                          onTap: () {
                            _toggleOpen();
                            widget.onSelected(item);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Text(
                              widget.customLabelBuilder?.call(item) ?? item,
                              style: tt.bodyMedium?.copyWith(
                                color: item == '__delete__'
                                    ? cs.error
                                    : cs.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fg = widget.foregroundColor ?? cs.onSurface;
    final bg = widget.backgroundColor ?? cs.surfaceContainerLow;
    final resolvedFg = ensureContrast(bg, fg);
    final valueText = widget.value == null
        ? null
        : (widget.customLabelBuilder?.call(widget.value!) ?? widget.value!);
    final placeholder = Localizations.localeOf(context).languageCode == 'en'
        ? 'None selected'
        : '未选择';

    return CompositedTransformTarget(
      link: _layerLink,
      child: Semantics(
        button: true,
        expanded: _isOpen,
        child: Bounceable(
          onTap: _toggleOpen,
          child: AnimatedContainer(
            duration: kAppMotionDuration,
            curve: kAppMotionCurve,
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bg == cs.surfaceContainerLow ? Colors.transparent : bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.leadingIcon != null) ...[
                  Icon(
                    widget.leadingIcon,
                    size: 20,
                    color: resolvedFg.withValues(alpha: 166),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    valueText ?? placeholder,
                    overflow: TextOverflow.ellipsis,
                    style: (widget.valueTextStyle ??
                            tt.titleMedium?.copyWith(
                              color: valueText == null
                                  ? resolvedFg.withValues(alpha: 166)
                                  : resolvedFg,
                              fontWeight: FontWeight.bold,
                            )) ??
                        TextStyle(
                          color: valueText == null
                              ? resolvedFg.withValues(alpha: 166)
                              : resolvedFg,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: resolvedFg, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showExpressiveSnackBar(BuildContext context, String message,
    {Duration? duration}) {
  final cs = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: TextStyle(color: cs.onPrimaryContainer)),
      duration: duration ?? const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      backgroundColor: cs.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}

Color resolveAccessibleOnColor(Color background) {
  final darkContrast =
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark;
  return darkContrast ? Colors.white : const Color(0xFF1A1B20);
}

Color blendColors(Color a, Color b, double t) {
  return Color.lerp(a, b, t.clamp(0.0, 1.0)) ?? a;
}

double contrastRatio(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

Color ensureContrast(Color background, Color preferredForeground) {
  final candidates = <Color>[
    preferredForeground,
    resolveAccessibleOnColor(background),
    Colors.black,
    Colors.white,
  ];
  for (final candidate in candidates) {
    if (contrastRatio(background, candidate) >= 4.5) {
      return candidate;
    }
  }
  return resolveAccessibleOnColor(background);
}
