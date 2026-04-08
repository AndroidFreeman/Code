import 'package:flutter/material.dart';

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
      duration: const Duration(milliseconds: 100),
    );
    _animation = Tween<double>(begin: 1.0, end: widget.scale ?? 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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

class ExpressiveSelector extends StatefulWidget {
  final String label;
  final String? value;
  final List<String> items;
  final Function(String) onSelected;
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

class _ExpressiveSelectorState extends State<ExpressiveSelector> {
  final MenuController _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fg = widget.foregroundColor ?? cs.onSurface;
    final bg = widget.backgroundColor ?? cs.surfaceContainerLow;
    final placeholder = Localizations.localeOf(context).languageCode == 'en'
        ? 'None selected'
        : '未选择';
    final menuShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: cs.outlineVariant.withValues(alpha: 128)),
    );

    return MenuAnchor(
      controller: _controller,
      style: MenuStyle(
        elevation: const WidgetStatePropertyAll(1),
        shape: WidgetStatePropertyAll(menuShape),
        backgroundColor: WidgetStatePropertyAll(cs.surface),
        surfaceTintColor: WidgetStatePropertyAll(cs.surface),
        padding:
            const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
      ),
      menuChildren: widget.items
          .map(
            (item) => MenuItemButton(
              onPressed: () {
                _controller.close();
                widget.onSelected(item);
              },
              style: ButtonStyle(
                backgroundColor:
                    const WidgetStatePropertyAll(Colors.transparent),
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              child: Text(
                widget.customLabelBuilder?.call(item) ?? item,
                style: tt.bodyMedium?.copyWith(
                  color: item == '__delete__' ? cs.error : null,
                ),
              ),
            ),
          )
          .toList(growable: false),
      builder: (context, controller, child) {
        return Bounceable(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          child: Container(
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 128)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: (widget.labelTextStyle ??
                              tt.labelSmall?.copyWith(
                                color: fg.withValues(alpha: 179),
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              )) ??
                          TextStyle(
                            color: fg.withValues(alpha: 179),
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.15),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        widget.value == null
                            ? placeholder
                            : (widget.customLabelBuilder?.call(widget.value!) ??
                                widget.value!),
                        key: ValueKey(widget.value ?? placeholder),
                        style: (widget.valueTextStyle ??
                                tt.titleSmall?.copyWith(
                                  color: fg,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                )) ??
                            TextStyle(
                              color: fg,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down_rounded, color: fg, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
