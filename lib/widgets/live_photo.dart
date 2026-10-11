import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

import '../state/settings.dart';
import 'ui.dart';

/// 实况照片的动态部分：盖在静态照片上播放，播完淡出。
///
/// 按设置「长按播放」或「翻到时自动播放一次」。
class LivePhotoLayer extends StatefulWidget {
  const LivePhotoLayer({
    super.key,
    required this.asset,
    required this.isCurrent,
    required this.child,
    this.badgeTop = 0,
  });

  final AssetEntity asset;
  final bool isCurrent;

  /// 静态照片。
  final Widget child;

  /// 「实况」标记距顶部的距离，用来避开顶栏。
  final double badgeTop;

  @override
  State<LivePhotoLayer> createState() => _LivePhotoLayerState();
}

class _LivePhotoLayerState extends State<LivePhotoLayer> {
  VideoPlayerController? _c;
  bool _visible = false;
  bool _holding = false;

  bool get _auto => AppSettings.instance.livePlayMode == LivePlayMode.auto;

  @override
  void initState() {
    super.initState();
    if (widget.isCurrent && _auto) _play();
  }

  @override
  void didUpdateWidget(LivePhotoLayer old) {
    super.didUpdateWidget(old);
    if (old.isCurrent && !widget.isCurrent) {
      _stop(release: true);
    } else if (!old.isCurrent && widget.isCurrent && _auto) {
      _play();
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  Future<void> _ensure() async {
    if (_c != null) return;
    final file = await widget.asset.fileWithSubtype;
    if (file == null || !mounted) return;
    final c = VideoPlayerController.file(file);
    await c.initialize();
    if (!mounted) {
      c.dispose();
      return;
    }
    c.addListener(_onTick);
    _c = c;
  }

  void _onTick() {
    final c = _c;
    if (c == null || !mounted) return;
    // 播到结尾：长按中就停在最后一帧，否则淡出回到静态照片。
    final ended =
        c.value.isInitialized &&
        !c.value.isPlaying &&
        c.value.position >= c.value.duration - const Duration(milliseconds: 50);
    if (ended && !_holding && _visible) setState(() => _visible = false);
  }

  Future<void> _play() async {
    try {
      await _ensure();
    } catch (_) {
      return;
    }
    final c = _c;
    if (c == null || !mounted) return;
    await c.setVolume(AppSettings.instance.videoMuted ? 0 : 1);
    await c.seekTo(Duration.zero);
    await c.play();
    if (mounted) setState(() => _visible = true);
  }

  void _stop({bool release = false}) {
    _c?.pause();
    if (mounted) setState(() => _visible = false);
    if (release) {
      final c = _c;
      _c = null;
      // 等淡出动画结束再释放。
      Future.delayed(const Duration(milliseconds: 300), () => c?.dispose());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    return GestureDetector(
      onLongPressStart: (_) {
        _holding = true;
        Haptics.light();
        _play();
      },
      onLongPressEnd: (_) {
        _holding = false;
        _stop();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (c != null && c.value.isInitialized)
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: _visible ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: c.value.aspectRatio,
                    child: VideoPlayer(c),
                  ),
                ),
              ),
            ),
          Positioned(
            top: widget.badgeTop,
            left: 14,
            child: IgnorePointer(
              child: GlassPanel(
                radius: 12,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _visible
                          ? Icons.motion_photos_on_rounded
                          : Icons.motion_photos_on_outlined,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '实况',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
