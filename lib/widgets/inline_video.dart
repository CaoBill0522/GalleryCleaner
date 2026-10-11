import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

import '../state/settings.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'media_image.dart';
import 'ui.dart';

const _speeds = [0.5, 1.0, 1.25, 1.5, 2.0];

/// 在当前页里直接播放的视频：封面 + 播放器 + 底部控制条。
///
/// 只有当前页才持有播放器，翻走后释放，避免同时占用多个解码器。
class InlineVideo extends StatefulWidget {
  const InlineVideo({
    super.key,
    required this.asset,
    required this.isCurrent,
    this.controlsBottom = 0,
  });

  final AssetEntity asset;
  final bool isCurrent;

  /// 控制条距离底部的距离，用来避开页面自己的底栏。
  final double controlsBottom;

  @override
  State<InlineVideo> createState() => _InlineVideoState();
}

class _InlineVideoState extends State<InlineVideo> {
  VideoPlayerController? _c;
  bool _loading = false;
  String? _error;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    if (widget.isCurrent && AppSettings.instance.videoAutoPlay) _start();
  }

  @override
  void didUpdateWidget(InlineVideo old) {
    super.didUpdateWidget(old);
    if (old.isCurrent && !widget.isCurrent) {
      _release();
    } else if (!old.isCurrent &&
        widget.isCurrent &&
        AppSettings.instance.videoAutoPlay) {
      _start();
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  void _release() {
    final c = _c;
    _c = null;
    c?.dispose();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _start() async {
    if (_c != null || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final file = await widget.asset.file;
      if (file == null) throw Exception('无法读取视频文件');
      final c = VideoPlayerController.file(file);
      await c.initialize();
      if (!mounted || !widget.isCurrent) {
        c.dispose();
        return;
      }
      await c.setVolume(AppSettings.instance.videoMuted ? 0 : 1);
      await c.setPlaybackSpeed(_speed);
      c.addListener(_onTick);
      await c.play();
      setState(() {
        _c = c;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '视频加载失败';
        });
      }
    }
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _togglePlay() {
    final c = _c;
    if (c == null) {
      _start();
      return;
    }
    if (c.value.isPlaying) {
      c.pause();
    } else {
      // 播完了再点从头开始。
      if (c.value.position >= c.value.duration) c.seekTo(Duration.zero);
      c.play();
    }
  }

  void _toggleMute() {
    final muted = !AppSettings.instance.videoMuted;
    AppSettings.instance.setVideoMuted(muted);
    _c?.setVolume(muted ? 0 : 1);
    Haptics.selection();
    setState(() {});
  }

  void _cycleSpeed() {
    final i = _speeds.indexOf(_speed);
    _speed = _speeds[(i + 1) % _speeds.length];
    _c?.setPlaybackSpeed(_speed);
    Haptics.selection();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final ready = c != null && c.value.isInitialized;
    final playing = ready && c.value.isPlaying;
    return Stack(
      fit: StackFit.expand,
      children: [
        MediaImage(asset: widget.asset),
        if (ready)
          Center(
            child: AspectRatio(
              aspectRatio: c.value.aspectRatio,
              child: VideoPlayer(c),
            ),
          ),
        // 中间的大播放按钮：只在没在播放时出现。
        Center(
          child: AnimatedOpacity(
            opacity: playing ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: playing,
              child: Pressable(
                onTap: _togglePlay,
                child: GlassPanel(
                  radius: 40,
                  padding: const EdgeInsets.all(14),
                  child: _loading
                      ? const SizedBox(
                          width: 46,
                          height: 46,
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 46,
                        ),
                ),
              ),
            ),
          ),
        ),
        if (_error != null)
          Align(
            alignment: const Alignment(0, 0.2),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        Positioned(
          left: 12,
          right: 12,
          bottom: widget.controlsBottom,
          child: _Controls(
            duration: ready ? c.value.duration : widget.asset.videoDuration,
            position: ready ? c.value.position : Duration.zero,
            playing: playing,
            muted: AppSettings.instance.videoMuted,
            speed: _speed,
            enabled: ready,
            onPlay: _togglePlay,
            onMute: _toggleMute,
            onSpeed: _cycleSpeed,
            onSeek: (d) => c?.seekTo(d),
          ),
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.duration,
    required this.position,
    required this.playing,
    required this.muted,
    required this.speed,
    required this.enabled,
    required this.onPlay,
    required this.onMute,
    required this.onSpeed,
    required this.onSeek,
  });

  final Duration duration;
  final Duration position;
  final bool playing;
  final bool muted;
  final double speed;
  final bool enabled;
  final VoidCallback onPlay;
  final VoidCallback onMute;
  final VoidCallback onSpeed;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    const timeStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    final speedLabel = speed == speed.roundToDouble()
        ? '${speed.toInt()}×'
        : '$speed×';
    return GlassPanel(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(4, 2, 8, 2),
      child: Row(
        children: [
          IconButton(
            onPressed: onPlay,
            icon: Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
            ),
          ),
          Text(formatDuration(position), style: timeStyle),
          Expanded(
            child: _Scrubber(
              duration: duration,
              position: position,
              enabled: enabled,
              onSeek: onSeek,
            ),
          ),
          Text(formatDuration(duration), style: timeStyle),
          const SizedBox(width: 4),
          _SmallButton(
            onTap: onSpeed,
            child: Text(
              speedLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _SmallButton(
            onTap: onMute,
            child: Icon(
              muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(width: 40, height: 40, child: Center(child: child)),
    );
  }
}

/// 可精确拖动的进度条。
///
/// 按住后手指往上移，拖动速度会逐级变慢（类似系统播放器的精细拖动），
/// 拖动时在上方显示精确到 0.1 秒的时间。按下就独占手势，不会误触翻页或上下滑。
class _Scrubber extends StatefulWidget {
  const _Scrubber({
    required this.duration,
    required this.position,
    required this.enabled,
    required this.onSeek,
  });

  final Duration duration;
  final Duration position;
  final bool enabled;
  final ValueChanged<Duration> onSeek;

  @override
  State<_Scrubber> createState() => _ScrubberState();
}

class _ScrubberState extends State<_Scrubber> {
  static const _tiers = [
    (0.0, 1.0, '全速拖动'),
    (50.0, 0.5, '半速拖动'),
    (110.0, 0.25, '四分之一速拖动'),
    (170.0, 0.1, '精细拖动'),
  ];

  /// 拖动中的进度（0~1），为 null 表示没在拖。
  double? _drag;
  double _startY = 0;
  int _tier = 0;
  Timer? _seekThrottle;
  Duration? _pendingSeek;

  double get _value {
    final total = widget.duration.inMilliseconds;
    if (total <= 0) return 0;
    return (widget.position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  void _seek(double v) {
    final d = Duration(
      milliseconds: (widget.duration.inMilliseconds * v).round(),
    );
    // 拖动时最多每 60ms 真正 seek 一次，画面跟手又不会卡。
    _pendingSeek = d;
    _seekThrottle ??= Timer(const Duration(milliseconds: 60), () {
      _seekThrottle = null;
      final p = _pendingSeek;
      if (p != null) widget.onSeek(p);
    });
  }

  @override
  void dispose() {
    _seekThrottle?.cancel();
    super.dispose();
  }

  void _down(PointerDownEvent e, double width) {
    if (!widget.enabled) return;
    _startY = e.position.dy;
    _tier = 0;
    final v = (e.localPosition.dx / width).clamp(0.0, 1.0);
    setState(() => _drag = v);
    _seek(v);
  }

  void _move(PointerMoveEvent e, double width) {
    final drag = _drag;
    if (drag == null) return;
    final up = (_startY - e.position.dy).clamp(0.0, double.infinity);
    var tier = 0;
    for (var i = 0; i < _tiers.length; i++) {
      if (up >= _tiers[i].$1) tier = i;
    }
    if (tier != _tier) Haptics.selection();
    _tier = tier;
    final v = (drag + e.delta.dx / width * _tiers[tier].$2).clamp(0.0, 1.0);
    setState(() => _drag = v);
    _seek(v);
  }

  void _up() {
    final drag = _drag;
    if (drag == null) return;
    _seekThrottle?.cancel();
    _seekThrottle = null;
    widget.onSeek(
      Duration(milliseconds: (widget.duration.inMilliseconds * drag).round()),
    );
    setState(() => _drag = null);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final v = _drag ?? _value;
        final dragging = _drag != null;
        final preview = Duration(
          milliseconds: (widget.duration.inMilliseconds * v).round(),
        );
        // EagerGestureRecognizer 一按下就赢得手势竞争，翻页和上下滑都不会抢走。
        return RawGestureDetector(
          gestures: {
            EagerGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                  EagerGestureRecognizer.new,
                  (_) {},
                ),
          },
          child: Listener(
            onPointerDown: (e) => _down(e, width),
            onPointerMove: (e) => _move(e, width),
            onPointerUp: (_) => _up(),
            onPointerCancel: (_) => _up(),
            child: SizedBox(
              height: 44,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: LayoutBuilder(
                      builder: (context, track) => Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.centerLeft,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: dragging ? 6 : 3,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: dragging ? 6 : 3,
                            width: track.maxWidth * v,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          Positioned(
                            left: track.maxWidth * v - (dragging ? 9 : 6),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: dragging ? 18 : 12,
                              height: dragging ? 18 : 12,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (dragging)
                    Positioned(
                      left: (width * v - 60).clamp(-40.0, width - 80),
                      bottom: 46,
                      child: Container(
                        width: 120,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _preciseTime(preview),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            Text(
                              _tier == 0 ? '上移手指可精细调节' : _tiers[_tier].$3,
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String _preciseTime(Duration d) {
  final tenths = (d.inMilliseconds % 1000) ~/ 100;
  return '${formatDuration(d)}.$tenths';
}
