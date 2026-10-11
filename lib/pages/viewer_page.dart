import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../models/year_month.dart';
import '../state/cleaner_state.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/media_image.dart';
import '../widgets/swipeable_media.dart';
import '../widgets/ui.dart';
import 'review_page.dart';
import 'months_page.dart';
import 'settings_page.dart';

/// iOS 系统相册名默认是英文，这里换成中文；用户自建的相册保持原名。
const _systemAlbumNames = {
  'Recents': '最近项目',
  'Favorites': '个人收藏',
  'Videos': '视频',
  'Selfies': '自拍',
  'Live Photos': '实况照片',
  'Portrait': '人像',
  'Panoramas': '全景照片',
  'Time-lapse': '延时摄影',
  'Slo-mo': '慢动作',
  'Bursts': '连拍快照',
  'Screenshots': '截屏',
  'Screen Recordings': '录屏',
  'Animated': '动图',
  'Long Exposure': '长曝光',
  'Cinematic': '电影效果',
  'Spatial': '空间',
  'RAW': 'RAW',
  'Recently Saved': '最近保存',
  'Recently Added': '最近添加',
  'Imports': '导入',
  'Hidden': '已隐藏',
  'Recently Deleted': '最近删除',
  'Camera': '相机',
  'Screenshot': '截屏',
  'Download': '下载',
};

String albumName(AssetPathEntity a) =>
    a.isAll ? '全部照片' : (_systemAlbumNames[a.name] ?? a.name);

class ViewerPage extends StatefulWidget {
  const ViewerPage({super.key});

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  PageController? _pages;
  int _generation = -1;
  bool _zoomed = false;

  /// 屏幕上的手指数；两指及以上视为缩放，暂停翻页和上下滑。
  int _pointers = 0;
  bool get _multiTouch => _pointers >= 2;
  bool get _gesturesLocked => _zoomed || _multiTouch;

  final Map<String, GlobalKey<SwipeableMediaState>> _itemKeys = {};
  SwipeableMediaState? _dragTarget;

  /// 正在用代码翻向的页（标记后自动翻页 / 撤销跳回），到达后清空。
  /// 只在设置后很短时间内有效，避免中途被点一下停在别处后还沿用旧目标。
  int? _pendingPage;
  DateTime _pendingAt = DateTime(0);

  void _setPending(int page) {
    _pendingPage = page;
    _pendingAt = DateTime.now();
  }

  int? get _livePending =>
      DateTime.now().difference(_pendingAt) < const Duration(milliseconds: 600)
      ? _pendingPage
      : null;

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  /// 相册切换或删除后重新加载时，换一个从当前位置开始的 PageController。
  PageController _controllerFor(CleanerState s) {
    if (_generation != s.generation || _pages == null) {
      final old = _pages;
      if (old != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      }
      _pages = PageController(initialPage: s.currentIndex);
      _generation = s.generation;
      _zoomed = false;
      _pendingPage = null;
      _itemKeys.clear();
    }
    return _pages!;
  }

  bool _onMark(CleanerState s, int index) {
    s.mark(index);
    if (index < s.total - 1) {
      _setPending(index + 1);
      _pages?.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
      return true;
    }
    _toast('已经是最后一张了');
    return false;
  }

  void _undo(CleanerState s) {
    final index = s.undo();
    final pages = _pages;
    if (index == null || pages == null || index == s.currentIndex) return;
    if ((index - s.currentIndex).abs() == 1) {
      _setPending(index);
      pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      pages.jumpToPage(index);
    }
  }

  void _onPointerDown() {
    _pointers++;
    if (_pointers == 2) {
      // 第二根手指落下：已经开始的上下拖动作废，交给缩放。
      _dragTarget?.dragCancel();
      _dragTarget = null;
      setState(() {});
    }
  }

  void _onPointerUp() {
    _pointers = (_pointers - 1).clamp(0, 10);
    if (_pointers == 0) setState(() {});
  }

  /// 上下拖动开始：先把还在进行的翻页动画直接落定，再把手势交给当前那张。
  void _onVerticalDragStart(CleanerState s) {
    var index = s.currentIndex;
    final pages = _pages;
    if (pages != null && pages.hasClients) {
      final page = pages.page ?? index.toDouble();
      // 手指按下会打断翻页动画（甚至还没开始动），所以优先认目标页。
      index = _livePending ?? page.round();
      if ((page - index).abs() > 0.001) pages.jumpToPage(index);
    }
    _pendingPage = null;
    final asset = s.assetAt(index);
    final target = asset == null ? null : _itemKeys[asset.id]?.currentState;
    _dragTarget = (target?.dragStart() ?? false) ? target : null;
  }

  void _finish(CleanerState s) {
    if (s.markedCount == 0) {
      _toast('还没有标记要删除的照片，上滑即可标记');
      return;
    }
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ReviewPage()));
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _pickMonth(CleanerState s) async {
    final picked = await Navigator.of(context)
        .push<YearMonth>(MaterialPageRoute(builder: (_) => const MonthsPage()));
    if (picked == null) return;
    await s.enterMonth(picked == MonthsPage.allTime ? null : picked);
  }

  Future<void> _pickAlbum(CleanerState s) async {
    final picked = await showModalBottomSheet<AssetPathEntity>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (_) => _AlbumSheet(albums: s.albums, current: s.album),
    );
    if (picked != null) await s.selectAlbum(picked);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<CleanerState>();
    final firstLoad = s.loading && s.generation == 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: firstLoad
          ? const Center(child: LogoLoader())
          : Stack(
              children: [
                if (s.total == 0)
                  const _EmptyState()
                else
                  Listener(
                    onPointerDown: (_) => _onPointerDown(),
                    onPointerUp: (_) => _onPointerUp(),
                    onPointerCancel: (_) => _onPointerUp(),
                    child: GestureDetector(
                      onVerticalDragStart: _gesturesLocked
                          ? null
                          : (_) => _onVerticalDragStart(s),
                      onVerticalDragUpdate: _gesturesLocked
                          ? null
                          : (d) => _dragTarget?.dragUpdate(d),
                      onVerticalDragEnd: _gesturesLocked
                          ? null
                          : (d) {
                              _dragTarget?.dragEnd(d);
                              _dragTarget = null;
                            },
                      onVerticalDragCancel: _gesturesLocked
                          ? null
                          : () {
                              _dragTarget?.dragCancel();
                              _dragTarget = null;
                            },
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          final page = _pages?.page;
                          if (n is ScrollUpdateNotification &&
                              n.dragDetails != null) {
                            // 用户自己左右拖了，就不再认之前的目标页。
                            _pendingPage = null;
                          } else if (n is ScrollEndNotification &&
                              page != null &&
                              (page - (_pendingPage ?? -1)).abs() < 0.001) {
                            _pendingPage = null;
                          }
                          return false;
                        },
                        child: PageView.builder(
                          key: ValueKey(s.generation),
                          controller: _controllerFor(s),
                          allowImplicitScrolling: true,
                          physics: _gesturesLocked
                              ? const NeverScrollableScrollPhysics()
                              : const PageScrollPhysics(),
                          itemCount: s.total,
                          onPageChanged: (i) {
                            s.setCurrentIndex(i);
                            if (_zoomed) setState(() => _zoomed = false);
                          },
                          itemBuilder: (context, i) {
                            final asset = s.assetAt(i);
                            if (asset == null) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return _PageDepth(
                              controller: _pages!,
                              index: i,
                              child: SwipeableMedia(
                                key: _itemKeys.putIfAbsent(
                                  asset.id,
                                  () => GlobalKey<SwipeableMediaState>(),
                                ),
                                asset: asset,
                                marked: s.isMarked(asset.id),
                                isCurrent: i == s.currentIndex,
                                onMark: () => _onMark(s, i),
                                onUnmark: () => s.unmark(i),
                                onZoomChanged: (z) =>
                                    setState(() => _zoomed = z),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                // 放大查看时栏位淡出并上下滑走。
                _AutoHide(
                  hidden: _zoomed,
                  offset: const Offset(0, -0.4),
                  child: _TopBar(
                    state: s,
                    onPickAlbum: () => _pickAlbum(s),
                    onPickMonth: () => _pickMonth(s),
                  ),
                ),
                _AutoHide(
                  hidden: _zoomed,
                  offset: const Offset(0, 0.4),
                  child: _BottomBar(
                    state: s,
                    onUndo: () => _undo(s),
                    onFinish: () => _finish(s),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: s.loading
                      ? const ColoredBox(
                          key: ValueKey('loading'),
                          color: Color(0xB30B0C14),
                          child: Center(child: LogoLoader(size: 72)),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
    );
  }
}

const _textShadow = [Shadow(blurRadius: 8, color: Colors.black45)];

/// 翻页时相邻页略微缩小变暗，带一点纵深感。
class _PageDepth extends StatelessWidget {
  const _PageDepth({
    required this.controller,
    required this.index,
    required this.child,
  });

  final PageController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        var d = 0.0;
        if (controller.hasClients && controller.position.haveDimensions) {
          d = ((controller.page ?? index.toDouble()) - index).abs();
        }
        d = d.clamp(0.0, 1.0);
        return Opacity(
          opacity: 1 - 0.45 * d,
          child: Transform.scale(scale: 1 - 0.12 * d, child: child),
        );
      },
      child: child,
    );
  }
}

class _AutoHide extends StatelessWidget {
  const _AutoHide({
    required this.hidden,
    required this.offset,
    required this.child,
  });

  final bool hidden;
  final Offset offset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: hidden,
      child: AnimatedSlide(
        offset: hidden ? offset : Offset.zero,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: hidden ? 0 : 1,
          duration: const Duration(milliseconds: 220),
          child: child,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_outlined, size: 64, color: Colors.white24),
          SizedBox(height: 12),
          Text(
            '这个相册里没有照片或视频',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.state,
    required this.onPickAlbum,
    required this.onPickMonth,
  });

  final CleanerState state;
  final VoidCallback onPickAlbum;
  final VoidCallback onPickMonth;

  @override
  Widget build(BuildContext context) {
    final album = state.album;
    final asset = state.total == 0 ? null : state.assetAt(state.currentIndex);
    final progress = state.total == 0
        ? 0.0
        : (state.currentIndex + 1) / state.total;
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Pressable(
                    onTap: onPickAlbum,
                    child: GlassPanel(
                      radius: 20,
                      padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 104),
                            child: Text(
                              album == null ? '相册' : albumName(album),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.expand_more_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (asset != null)
                    GlassPanel(
                      radius: 20,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${state.currentIndex + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: ' / ${state.total}',
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Pressable(
                    onTap: onPickMonth,
                    child: GlassPanel(
                      radius: 20,
                      padding: const EdgeInsets.all(9),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: state.month == null
                            ? Colors.white
                            : AppColors.red,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Pressable(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    ),
                    child: const GlassPanel(
                      radius: 20,
                      padding: EdgeInsets.all(9),
                      child: Icon(
                        Icons.settings_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ProgressLine(value: progress),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    if (state.month != null)
                      Pressable(
                        onTap: () => state.enterMonth(null),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.month!.label,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.close_rounded,
                                color: Colors.black,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (asset != null && context.watch<AppSettings>().showInfo)
                      Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: _AssetInfo(asset: asset),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Container(
        height: 3,
        color: Colors.white12,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => FractionallySizedBox(
            widthFactor: v.clamp(0.0, 1.0),
            child: const ColoredBox(
              color: Colors.white70,
              child: SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class _AssetInfo extends StatelessWidget {
  const _AssetInfo({required this.asset});

  final AssetEntity asset;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      key: ValueKey(asset.id),
      future: asset.fileSize,
      builder: (context, snap) {
        final parts = [
          formatDateTime(asset.createDateTime),
          if (snap.hasData) formatBytes(snap.data!),
        ];
        return Text(
          parts.join(' · '),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            shadows: _textShadow,
          ),
        );
      },
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.state,
    required this.onUndo,
    required this.onFinish,
  });

  final CleanerState state;
  final VoidCallback onUndo;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final count = state.markedCount;
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassPanel(
                radius: 32,
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Pressable(
                      onTap: state.canUndo ? onUndo : null,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        child: const Icon(
                          Icons.undo_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BumpOnChange(
                            value: count,
                            child: Text(
                              '$count',
                              style: TextStyle(
                                color: count > 0 ? AppColors.red : Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const Text(
                            '待删除',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      label: '完成',
                      icon: Icons.check_rounded,
                      height: 48,
                      color: count > 0 ? AppColors.red : Colors.white,
                      textColor: count > 0 ? Colors.white : Colors.black,
                      onTap: onFinish,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumSheet extends StatelessWidget {
  const _AlbumSheet({required this.albums, required this.current});

  final List<AssetPathEntity> albums;
  final AssetPathEntity? current;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scroll) => ListView.builder(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: albums.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(
                '选择相册',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }
          final a = albums[i - 1];
          return StaggerIn(
            index: i,
            child: _AlbumTile(
              album: a,
              selected: a.id == current?.id,
              onTap: () => Navigator.of(context).pop(a),
            ),
          );
        },
      ),
    );
  }
}

class _AlbumTile extends StatefulWidget {
  const _AlbumTile({
    required this.album,
    required this.selected,
    required this.onTap,
  });

  final AssetPathEntity album;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_AlbumTile> createState() => _AlbumTileState();
}

class _AlbumTileState extends State<_AlbumTile> {
  late final Future<int> _count = widget.album.assetCountAsync;
  late final Future<List<AssetEntity>> _cover = widget.album.getAssetListRange(
    start: 0,
    end: 1,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Pressable(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.surfaceHigh
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: FutureBuilder<List<AssetEntity>>(
                    future: _cover,
                    builder: (context, snap) {
                      final list = snap.data;
                      if (list == null || list.isEmpty) {
                        return const ColoredBox(
                          color: AppColors.surfaceHigh,
                          child: Icon(
                            Icons.photo_album_rounded,
                            color: Colors.white24,
                          ),
                        );
                      }
                      return Image(
                        image: gridThumb(list.first),
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      albumName(widget.album),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FutureBuilder<int>(
                      future: _count,
                      builder: (_, snap) => Text(
                        snap.hasData ? '${snap.data} 项' : ' ',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.selected)
                const Icon(Icons.check_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
