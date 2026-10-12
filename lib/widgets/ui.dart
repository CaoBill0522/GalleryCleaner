import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

/// 限制内容最大宽度并居中，避免在 iPad 等大屏上拉得过宽。手机上不受影响。
class MaxWidth extends StatelessWidget {
  const MaxWidth({super.key, required this.child, this.width = 640});

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    // 只在水平方向居中；高度跟随内容，放在底栏等位置时不会被撑满。
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: child,
      ),
    );
  }
}

/// 毛玻璃底板。
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = 22,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.tint = const Color(0x8C1C1C1E),
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tint,
            borderRadius: r,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// 按下时轻微缩小的点击区域。
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null && v != _down) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.93 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: widget.onTap == null ? 0.4 : 1,
          duration: const Duration(milliseconds: 200),
          child: widget.child,
        ),
      ),
    );
  }
}

/// 纯色胶囊按钮，默认白底黑字。
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.color = Colors.white,
    this.textColor = Colors.black,
    this.height = 52,
    this.expand = false,
    this.loading = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color color;
  final Color textColor;
  final double height;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final content = loading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: textColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: textColor, size: 20),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
    return Pressable(
      onTap: loading ? null : onTap,
      child: Container(
        height: height,
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: content,
      ),
    );
  }
}

/// 数值变化时轻弹一下。
class BumpOnChange extends StatelessWidget {
  const BumpOnChange({super.key, required this.value, required this.child});

  final Object value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: Tween(begin: 0.6, end: 1.0).animate(anim),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: KeyedSubtree(key: ValueKey(value), child: child),
    );
  }
}

/// 从 0 滚动到目标值的数字。
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 1100),
    this.delay = Duration.zero,
  });

  final int value;
  final Widget Function(BuildContext, int) builder;
  final Duration duration;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final total = duration + delay;
    final start = delay.inMilliseconds / max(1, total.inMilliseconds);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      builder: (context, t, _) {
        final local = t <= start ? 0.0 : (t - start) / (1 - start);
        final eased = Curves.easeOutCubic.transform(local);
        return builder(context, (value * eased).round());
      },
    );
  }
}

/// 延迟一段时间后淡入上浮，用于列表依次出现。
class StaggerIn extends StatefulWidget {
  const StaggerIn({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    // 首屏依次出现；滚动后才构建的项直接出现，不再等待。
    final delay = Duration(
      milliseconds: widget.index <= 18 ? 35 * widget.index : 0,
    );
    Future.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curve,
      child: ScaleTransition(
        scale: Tween(begin: 0.85, end: 1.0).animate(curve),
        child: widget.child,
      ),
    );
  }
}

/// 加载时呼吸缩放的应用图标。
class LogoLoader extends StatefulWidget {
  const LogoLoader({super.key, this.size = 96});

  final double size;

  @override
  State<LogoLoader> createState() => _LogoLoaderState();
}

class _LogoLoaderState extends State<LogoLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(
        begin: 0.92,
        end: 1.04,
      ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: AppLogo(size: widget.size),
    );
  }
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.23),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.23),
        child: Image.asset('assets/icon/icon.png', width: size, height: size),
      ),
    );
  }
}

/// 数值变化时平滑过渡到新值。
class AnimatedInt extends StatelessWidget {
  const AnimatedInt({super.key, required this.value, required this.builder});

  final int value;
  final Widget Function(BuildContext, int) builder;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => builder(context, v.round()),
    );
  }
}
