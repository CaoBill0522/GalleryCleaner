import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../state/settings.dart';
import '../theme.dart';
import 'inline_video.dart';
import 'live_photo.dart';
import 'media_image.dart';

/// 全屏的单张照片/视频：上滑标记删除，下滑取消标记，双指缩放。
///
/// 上下拖动由浏览页统一识别后通过 [SwipeableMediaState] 的 drag* 方法转发进来，
/// 这样翻页动画还没结束时连续上滑也不会丢手势。
class SwipeableMedia extends StatefulWidget {
  const SwipeableMedia({
    super.key,
    required this.asset,
    required this.marked,
    required this.isCurrent,
    required this.onMark,
    required this.onUnmark,
    required this.onZoomChanged,
  });

  final AssetEntity asset;
  final bool marked;
  final bool isCurrent;

  /// 照片开始飞出时调用；返回 true 表示会翻到下一张（照片保持在屏幕外）。
  final bool Function() onMark;
  final VoidCallback onUnmark;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<SwipeableMedia> createState() => SwipeableMediaState();
}

class SwipeableMediaState extends State<SwipeableMedia>
    with SingleTickerProviderStateMixin {
  static const _distanceThreshold = 120.0;
  static const _velocityThreshold = 700.0;

  late final AnimationController _offset = AnimationController.unbounded(
    vsync: this,
  );
  final TransformationController _zoom = TransformationController();

  double _rawDy = 0;
  bool _dragging = false;
  bool _ready = false;
  bool _flying = false;
  bool _zoomed = false;
  Timer? _resetTimer;

  bool get _isVideo => widget.asset.type == AssetType.video;

  @override
  void didUpdateWidget(SwipeableMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget;
    if (old.isCurrent && !widget.isCurrent) {
      if (_zoomed) setState(_resetZoom);
      // 飞出去的照片：等翻页动画结束后悄悄放回原位，往回翻时能看到它。
      if (_offset.value != 0) {
        _resetTimer?.cancel();
        _resetTimer = Timer(const Duration(milliseconds: 400), () {
          if (mounted && !widget.isCurrent) _offset.value = 0;
        });
      }
    } else if (!old.isCurrent &&
        widget.isCurrent &&
        !_dragging &&
        _offset.value != 0) {
      // 例如撤销后跳回这张：从上方落回来。
      _resetTimer?.cancel();
      _animateTo(0);
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _offset.dispose();
    _zoom.dispose();
    super.dispose();
  }

  bool get _allowedDirection => widget.marked ? _rawDy > 0 : _rawDy < 0;

  /// 返回 false 表示这张正在飞出，不接收新的拖动。
  bool dragStart() {
    if (_flying) return false;
    _resetTimer?.cancel();
    _offset.stop();
    // 刚飞出去还没复位的照片，从当前位置继续。
    _rawDy = _offset.value;
    _dragging = true;
    return true;
  }

  void dragUpdate(DragUpdateDetails d) {
    _rawDy += d.delta.dy;
    // 不允许的方向加阻尼，只做轻微跟手。
    _offset.value = _allowedDirection ? _rawDy : _rawDy * 0.25;
    final ready = _allowedDirection && _rawDy.abs() > _distanceThreshold;
    if (ready != _ready) {
      _ready = ready;
      // 越过阈值时轻震一下，提示「松手就生效」。
      if (ready) Haptics.selection();
    }
  }

  void dragCancel() {
    _dragging = false;
    _ready = false;
    _rawDy = 0;
    _animateTo(0);
  }

  void dragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    final dy = _rawDy;
    _rawDy = 0;
    _dragging = false;
    _ready = false;
    if (!widget.marked &&
        dy < 0 &&
        (dy < -_distanceThreshold || v < -_velocityThreshold)) {
      _flyAway();
    } else if (widget.marked &&
        dy > 0 &&
        (dy > _distanceThreshold || v > _velocityThreshold)) {
      Haptics.light();
      widget.onUnmark();
      _animateTo(0);
    } else {
      _animateTo(0);
    }
  }

  /// 立刻标记并翻页，同时让照片往上飞出，连续快速上滑也不会丢。
  Future<void> _flyAway() async {
    final height = MediaQuery.of(context).size.height;
    _flying = true;
    Haptics.medium();
    final advanced = widget.onMark();
    await _offset
        .animateTo(
          -height,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInCubic,
        )
        .orCancel
        .catchError((_) {});
    _flying = false;
    if (mounted && !advanced) _animateTo(0);
  }

  /// 回弹带一点过冲，手感更有弹性。
  void _animateTo(double target) => _offset.animateTo(
    target,
    duration: const Duration(milliseconds: 380),
    curve: Curves.easeOutBack,
  );

  /// 双指缩放：放大后通知浏览页锁住翻页和上下滑，缩回原大小后解锁。
  void _onZoomUpdate() {
    final zoomed = _zoom.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed) {
      setState(() => _zoomed = zoomed);
      widget.onZoomChanged(zoomed);
    }
  }

  void _onZoomEnd() {
    if (_zoom.value.getMaxScaleOnAxis() > 1.01) return;
    _zoom.value = Matrix4.identity();
    if (_zoomed) {
      setState(() => _zoomed = false);
      widget.onZoomChanged(false);
    }
  }

  void _resetZoom() {
    _zoomed = false;
    _zoom.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    final Widget image = InteractiveViewer(
      transformationController: _zoom,
      minScale: 1,
      maxScale: 6,
      // 没放大时单指不拖图，交给翻页和上下滑。
      panEnabled: _zoomed,
      onInteractionUpdate: (_) => _onZoomUpdate(),
      onInteractionEnd: (_) => _onZoomEnd(),
      child: SizedBox.expand(
        child: MediaImage(asset: widget.asset, hiRes: _zoomed),
      ),
    );
    final Widget content;
    if (_isVideo) {
      // 控制条放在页面底栏上方。
      content = InlineVideo(
        asset: widget.asset,
        isCurrent: widget.isCurrent,
        controlsBottom: pad.bottom + 96,
      );
    } else if (widget.asset.isLivePhoto) {
      content = LivePhotoLayer(
        asset: widget.asset,
        isCurrent: widget.isCurrent,
        badgeTop: pad.top + 112,
        child: image,
      );
    } else {
      content = image;
    }

    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) {
        final dy = _offset.value;
        final h = MediaQuery.of(context).size.height;
        // 拖得越远越小、越斜；往上飞出时再逐渐淡出。
        final t = (dy.abs() / h).clamp(0.0, 1.0);
        final scale = 1 - (dy < 0 ? 0.32 : 0.12) * t;
        final opacity = dy < 0 ? (1 - (t - 0.25).clamp(0.0, 1.0) * 1.2) : 1.0;
        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.translationValues(0, dy, 0)
                  ..rotateZ(dy / h * 0.14)
                  ..scaleByDouble(scale, scale, 1, 1),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    child!,
                    if (widget.marked && !_zoomed)
                      IgnorePointer(
                        child: ColoredBox(
                          color: AppColors.red.withValues(alpha: 0.14),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _DragHint(dy: dy, marked: widget.marked),
            if (widget.marked && dy == 0 && !_zoomed)
              _MarkedBadge(lifted: _isVideo),
          ],
        );
      },
      child: content,
    );
  }
}

/// 拖动时的提示：边缘渐变光 + 带进度环的图标。
class _DragHint extends StatelessWidget {
  const _DragHint({required this.dy, required this.marked});

  final double dy;
  final bool marked;

  @override
  Widget build(BuildContext context) {
    final deleting = !marked && dy < 0;
    final restoring = marked && dy > 0;
    if (!deleting && !restoring) return const SizedBox.shrink();
    final progress = (dy.abs() / SwipeableMediaState._distanceThreshold).clamp(
      0.0,
      1.0,
    );
    final ready = progress >= 1;
    final color = deleting ? AppColors.red : Colors.white;
    final iconColor = deleting || !ready ? Colors.white : Colors.black;
    final pad = MediaQuery.of(context).padding;
    final text = deleting
        ? (ready ? '松手标记删除' : '继续上滑')
        : (ready ? '松手取消标记' : '继续下滑');

    final badge = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 76,
          height: 76,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: ready ? 76 : 62,
                height: ready ? 76 : 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ready ? color : Colors.black.withValues(alpha: 0.45),
                ),
              ),
              SizedBox(
                width: 76,
                height: 76,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  color: color,
                  backgroundColor: Colors.white12,
                ),
              ),
              Icon(
                deleting ? Icons.delete_rounded : Icons.restore_rounded,
                color: iconColor,
                size: ready ? 34 : 28,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
          ),
        ),
      ],
    );

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: (deleting ? AppColors.red : Colors.black).withValues(
              alpha: (deleting ? 0.18 : 0.3) * progress,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: deleting ? pad.top + 96 : null,
            bottom: deleting ? null : pad.bottom + 150,
            child: Opacity(
              opacity: (progress * 1.6).clamp(0.0, 1.0),
              child: Transform.scale(scale: 0.7 + 0.3 * progress, child: badge),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkedBadge extends StatelessWidget {
  const _MarkedBadge({this.lifted = false});

  /// 视频有控制条，角标往上挪一点。
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom + (lifted ? 170 : 112);
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutBack,
            builder: (context, v, child) => Transform.scale(
              scale: v,
              child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    '已标记删除 · 下滑取消',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
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
