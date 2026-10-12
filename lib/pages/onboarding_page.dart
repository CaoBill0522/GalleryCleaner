import 'dart:math';

import 'package:flutter/material.dart';

import '../config.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// 首次启动的功能向导：几页带动画的示意，教会基本操作。
///
/// 从设置里再次打开时传 [replay] = true，结束后返回上一页。
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.onDone, this.replay = false});

  /// 首次启动时看完（或跳过）后的回调。
  final VoidCallback? onDone;
  final bool replay;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _Step {
  const _Step(this.title, this.body, this.demo);

  final String title;
  final String body;
  final Widget demo;
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pages = PageController();
  int _index = 0;

  static const _steps = [
    _Step(
      '欢迎使用${AppInfo.nameZh}',
      '一张张过照片，把不要的挑出来，\n确认后一次删干净。',
      _WelcomeDemo(),
    ),
    _Step('左右滑动，切换照片', '照片一张张全屏显示，\n左右滑动看上一张、下一张。', _SwipeSideDemo()),
    _Step('上滑标记，下滑取消', '不要的照片往上一滑，自动跳到下一张。\n标记错了？下滑或点撤销就能恢复。', _SwipeUpDemo()),
    _Step(
      '确认之后才删除',
      '点「完成」逐张核对，想留的点一下保留。\n删除后 30 天内可在「最近删除」找回。',
      _ReviewDemo(),
    ),
  ];

  bool get _last => _index == _steps.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() {
    AppSettings.instance.setOnboardingDone();
    Haptics.light();
    if (widget.replay) {
      Navigator.of(context).pop();
    } else {
      widget.onDone?.call();
    }
  }

  void _next() {
    if (_last) {
      _finish();
    } else {
      _pages.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: _last ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: _last ? null : _finish,
                  child: const Text(
                    '跳过',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _steps.length,
                onPageChanged: (i) {
                  Haptics.selection();
                  setState(() => _index = i);
                },
                itemBuilder: (context, i) => _StepView(step: _steps[i]),
              ),
            ),
            _Dots(count: _steps.length, index: _index),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
              child: AppButton(
                expand: true,
                label: _last ? (widget.replay ? '知道了' : '开始使用') : '下一步',
                icon: _last ? Icons.check_rounded : null,
                onTap: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Expanded(child: Center(child: step.demo)),
          const SizedBox(height: 28),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            step.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == index ? Colors.white : Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

// ---------------- 示意动画 ----------------

/// 示意用的「照片」：渐变天空 + 太阳 + 山。
class _FakePhoto extends StatelessWidget {
  const _FakePhoto(this.palette);

  final int palette;

  static const _palettes = [
    [Color(0xFFFFB36B), Color(0xFF8D4C8C), Color(0xFF4A2E63)],
    [Color(0xFFBFE6FF), Color(0xFF3FA8E0), Color(0xFFE9D3A6)],
    [Color(0xFFF4FBEF), Color(0xFF9ED6A0), Color(0xFF2F6F4E)],
    [Color(0xFF2A1B4D), Color(0xFF13173A), Color(0xFF252A57)],
    [Color(0xFFFFE7C2), Color(0xFFF3A15E), Color(0xFFC0703A)],
    [Color(0xFFE6F0FF), Color(0xFF8FA9E0), Color(0xFF5C6FA8)],
  ];

  @override
  Widget build(BuildContext context) {
    final c = _palettes[palette % _palettes.length];
    return CustomPaint(
      painter: _PhotoPainter(c),
      child: const SizedBox.expand(),
    );
  }
}

class _PhotoPainter extends CustomPainter {
  _PhotoPainter(this.colors);

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors[0], colors[1]],
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset(size.width * .66, size.height * .42),
      size.width * .1,
      Paint()..color = Colors.white.withValues(alpha: .85),
    );
    final hill = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= size.width; x += 4) {
      hill.lineTo(
        x,
        size.height * .66 + sin(x / size.width * 5 + 1) * size.height * .05,
      );
    }
    hill
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hill, Paint()..color = colors[2]);
  }

  @override
  bool shouldRepaint(_PhotoPainter old) => old.colors != colors;
}

/// 小手机外壳。
class _MiniPhone extends StatelessWidget {
  const _MiniPhone({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.52,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF232325),
          borderRadius: BorderRadius.circular(34),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 30,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: ColoredBox(color: AppColors.background, child: child),
        ),
      ),
    );
  }
}

/// 一直循环的动画，t 在 0~1 之间。
class _Looping extends StatefulWidget {
  const _Looping({
    required this.builder,
    this.duration = const Duration(milliseconds: 2600),
  });

  final Widget Function(BuildContext, double t) builder;
  final Duration duration;

  @override
  State<_Looping> createState() => _LoopingState();
}

class _LoopingState extends State<_Looping>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => widget.builder(context, _c.value),
    );
  }
}

/// [t] 在 [a]~[b] 之间时从 0 走到 1，带缓动。
double _seg(
  double t,
  double a,
  double b, [
  Curve curve = Curves.easeInOutCubic,
]) => curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

/// 手指触点。
class _Finger extends StatelessWidget {
  const _Finger({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: .92),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: .25),
              spreadRadius: 9,
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeDemo extends StatelessWidget {
  const _WelcomeDemo();

  @override
  Widget build(BuildContext context) {
    return _Looping(
      duration: const Duration(milliseconds: 3200),
      builder: (context, t) {
        final float = sin(t * 2 * pi) * 6;
        return Transform.translate(
          offset: Offset(0, float),
          child: const AppLogo(size: 132),
        );
      },
    );
  }
}

class _SwipeSideDemo extends StatelessWidget {
  const _SwipeSideDemo();

  @override
  Widget build(BuildContext context) {
    return _MiniPhone(
      child: LayoutBuilder(
        builder: (context, box) => _Looping(
          builder: (context, t) {
            // 0.15~0.55 往左滑到第二张；0.65~0.95 再滑回来
            final go = _seg(t, .15, .55) - _seg(t, .65, .95);
            final w = box.maxWidth;
            final finger = t < .6
                ? _seg(t, .1, .55, Curves.easeInOut)
                : 1 - _seg(t, .62, .95, Curves.easeInOut);
            final fingerOpacity = t < .6
                ? (_seg(t, .08, .14) - _seg(t, .5, .58))
                : (_seg(t, .6, .66) - _seg(t, .9, .98));
            return Stack(
              children: [
                for (var i = 0; i < 2; i++)
                  Positioned(
                    left: (i - go) * w,
                    top: 0,
                    width: w,
                    height: box.maxHeight,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: .8,
                        child: _FakePhoto(i == 0 ? 0 : 1),
                      ),
                    ),
                  ),
                Positioned(
                  left:
                      w *
                          (t < .6
                              ? .72 - .44 * finger
                              : .28 + .44 * (1 - finger)) -
                      17,
                  top: box.maxHeight * .5 - 17,
                  child: _Finger(opacity: fingerOpacity),
                ),
                _ArrowHint(
                  icon: Icons.swap_horiz_rounded,
                  top: box.maxHeight * .12,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SwipeUpDemo extends StatelessWidget {
  const _SwipeUpDemo();

  @override
  Widget build(BuildContext context) {
    return _MiniPhone(
      child: LayoutBuilder(
        builder: (context, box) => _Looping(
          duration: const Duration(milliseconds: 3000),
          builder: (context, t) {
            final h = box.maxHeight;
            final lift = _seg(t, .12, .42, Curves.easeOutCubic); // 手指拖上去
            final fly = _seg(t, .42, .56, Curves.easeInCubic); // 松手飞走
            final next = _seg(t, .52, .66); // 下一张出现
            final dy = -h * .22 * lift - h * .9 * fly;
            final scale = 1 - .18 * lift - .3 * fly;
            final counted = t > .5;
            return Stack(
              children: [
                // 下一张
                Positioned.fill(
                  child: Opacity(
                    opacity: next,
                    child: Center(
                      child: AspectRatio(aspectRatio: .8, child: _FakePhoto(2)),
                    ),
                  ),
                ),
                // 当前这张
                Positioned.fill(
                  child: Opacity(
                    opacity: (1 - fly).clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, dy),
                      child: Transform.scale(
                        scale: scale,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: .8,
                            child: _FakePhoto(0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 红色提示
                Positioned(
                  top: h * .14,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: (lift - fly).clamp(0.0, 1.0),
                    child: Center(
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: AppColors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: box.maxWidth / 2 - 17,
                  top: h * .62 - h * .22 * lift - 17,
                  child: _Finger(opacity: _seg(t, .06, .12) - _seg(t, .42, .5)),
                ),
                // 底部计数
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 14,
                  child: Center(
                    child: AnimatedScale(
                      scale: counted ? 1 : .85,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          counted ? '1 待删除' : '0 待删除',
                          style: TextStyle(
                            color: counted ? AppColors.red : Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReviewDemo extends StatelessWidget {
  const _ReviewDemo();

  @override
  Widget build(BuildContext context) {
    return _MiniPhone(
      child: _Looping(
        duration: const Duration(milliseconds: 2800),
        builder: (context, t) {
          // 第 2 张在动画中途被点了一下保留，之后又恢复
          final kept = t > .35 && t < .85;
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 26, 12, 14),
            child: Column(
              children: [
                const Text(
                  '确认删除',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (var i = 0; i < 6; i++)
                        _MiniTile(
                          palette: i,
                          kept: i == 1 && kept,
                          pressed: i == 1 && (t > .3 && t < .36),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Text(
                    '删除 ${kept ? 5 : 6} 项',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MiniTile extends StatelessWidget {
  const _MiniTile({
    required this.palette,
    required this.kept,
    required this.pressed,
  });

  final int palette;
  final bool kept;
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: pressed ? .9 : (kept ? .92 : 1),
      duration: const Duration(milliseconds: 200),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedOpacity(
              opacity: kept ? .35 : 1,
              duration: const Duration(milliseconds: 200),
              child: ColorFiltered(
                colorFilter: kept
                    ? const ColorFilter.matrix([
                        .33, .33, .33, 0, 0, //
                        .33, .33, .33, 0, 0, //
                        .33, .33, .33, 0, 0, //
                        0, 0, 0, 1, 0,
                      ])
                    : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                child: _FakePhoto(palette),
              ),
            ),
            if (kept)
              const Center(
                child: Text(
                  '保留',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kept ? Colors.black26 : AppColors.red,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: kept
                    ? null
                    : const Icon(
                        Icons.check_rounded,
                        size: 9,
                        color: Colors.white,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrowHint extends StatelessWidget {
  const _ArrowHint({required this.icon, required this.top});

  final IconData icon;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
