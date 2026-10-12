import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';

class DonePage extends StatefulWidget {
  const DonePage({super.key, required this.count, required this.bytes});

  final int count;
  final int bytes;

  @override
  State<DonePage> createState() => _DonePageState();
}

class _DonePageState extends State<DonePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// 0~1 区间内的一段，用来给各个元素错开节奏。
  Animation<double> _interval(
    double begin,
    double end, [
    Curve c = Curves.easeOutCubic,
  ]) => CurvedAnimation(
    parent: _c,
    curve: Interval(begin, end, curve: c),
  );

  @override
  Widget build(BuildContext context) {
    final textIn = _interval(0.45, 0.8);
    return Scaffold(
      body: SafeArea(
        child: MaxWidth(
          width: 520,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 3),
                SizedBox(
                  width: 220,
                  height: 220,
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) => CustomPaint(
                      painter: _CheckPainter(
                        ring: _interval(0, 0.4).value,
                        check: _interval(0.3, 0.55).value,
                        burst: _interval(0.45, 1, Curves.easeOut).value,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: textIn,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(textIn),
                    child: Column(
                      children: [
                        const Text(
                          '清理完成',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _Stat(
                                label: '删除',
                                child: CountUp(
                                  value: widget.count,
                                  delay: const Duration(milliseconds: 700),
                                  builder: (_, v) => _bigNumber('$v', ' 项'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _Stat(
                                label: '释放空间',
                                child: CountUp(
                                  value: widget.bytes,
                                  delay: const Duration(milliseconds: 700),
                                  builder: (_, v) {
                                    final parts = formatBytes(v).split(' ');
                                    return _bigNumber(parts[0], ' ${parts[1]}');
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          Platform.isIOS
                              ? '在系统相册清空「最近删除」后空间才会真正释放'
                              : '清空系统回收站后空间才会真正释放',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 4),
                FadeTransition(
                  opacity: _interval(0.7, 1),
                  child: AppButton(
                    expand: true,
                    label: '继续清理',
                    icon: Icons.auto_awesome_rounded,
                    onTap: () =>
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bigNumber(String number, String unit) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: unit,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          child,
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// 圆环画出 → 对勾划出 → 一圈小点向外散开。
class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.ring, required this.check, required this.burst});

  final double ring;
  final double check;
  final double burst;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.3;
    final rect = Rect.fromCircle(center: c, radius: r);
    // 圆环
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * ring,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );

    // 对勾
    if (check > 0) {
      final path = Path()
        ..moveTo(c.dx - r * 0.42, c.dy + r * 0.02)
        ..lineTo(c.dx - r * 0.1, c.dy + r * 0.34)
        ..lineTo(c.dx + r * 0.46, c.dy - r * 0.3);
      final metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * check),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // 散开的光点
    if (burst > 0 && burst < 1) {
      const n = 14;
      for (var i = 0; i < n; i++) {
        final angle = 2 * pi * i / n + 0.2;
        final dist = r * (1.15 + 0.55 * burst) + (i.isEven ? 8 : 0);
        final p = c + Offset(cos(angle), sin(angle)) * dist;
        const color = Colors.white;
        canvas.drawCircle(
          p,
          (i.isEven ? 5 : 3.5) * (1 - burst),
          Paint()..color = color.withValues(alpha: 1 - burst),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.ring != ring || old.check != check || old.burst != burst;
}
