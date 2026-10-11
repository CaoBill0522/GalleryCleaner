import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../state/cleaner_state.dart';
import '../utils/format.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../widgets/inline_video.dart';
import '../widgets/media_image.dart';
import '../widgets/ui.dart';
import 'done_page.dart';

/// 删除前的确认页：宫格列出所有标记项，可取消勾选，确认后批量删除。
class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  List<AssetEntity>? _assets;
  final Map<String, int> _sizes = {};
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<CleanerState>();
    final ids = state.markedIds;
    final found = await Future.wait(ids.map(AssetEntity.fromId));
    final assets = found.whereType<AssetEntity>().toList();
    // 在别处已经被删掉的照片，顺手清掉标记。
    final alive = assets.map((e) => e.id).toSet();
    state.dropMissing(ids.where((id) => !alive.contains(id)));
    if (!mounted) return;
    setState(() => _assets = assets);

    final sizes = await Future.wait(
      assets.map((a) => a.fileSize.catchError((_) => 0)),
    );
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < assets.length; i++) {
        _sizes[assets[i].id] = sizes[i];
      }
    });
  }

  Future<void> _confirmDelete(List<AssetEntity> selected, int bytes) async {
    // 关掉「删除前确认」后跳过这一步，直接交给系统确认框。
    final ok =
        !AppSettings.instance.confirmBeforeDelete ||
        await _askConfirm(selected, bytes);
    if (!ok || !mounted) return;
    await _delete(selected);
  }

  Future<bool> _askConfirm(List<AssetEntity> selected, int bytes) async {
    final ok = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '取消',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, _, _) =>
          _ConfirmDialog(count: selected.length, bytes: bytes),
      transitionBuilder: (context, anim, _, child) {
        final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.85, end: 1.0).animate(curve),
            child: child,
          ),
        );
      },
    );
    return ok == true;
  }

  Future<void> _delete(List<AssetEntity> selected) async {
    setState(() => _deleting = true);
    final state = context.read<CleanerState>();
    List<String> deleted;
    try {
      deleted = await state.delete(selected);
    } catch (e) {
      deleted = const [];
      if (mounted) _toast('删除失败：$e');
    }
    if (!mounted) return;
    setState(() => _deleting = false);
    if (deleted.isEmpty) {
      _toast('没有删除任何照片');
      return;
    }
    Haptics.heavy();
    final freed = deleted.fold<int>(0, (sum, id) => sum + (_sizes[id] ?? 0));
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => DonePage(count: deleted.length, bytes: freed),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _openViewer(int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) =>
            _ReviewViewer(assets: _assets!, initialIndex: index),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CleanerState>();
    final assets = _assets;
    final selected =
        assets?.where((a) => state.isMarked(a.id)).toList() ?? const [];
    final bytes = selected.fold<int>(0, (sum, a) => sum + (_sizes[a.id] ?? 0));
    final allSelected = assets != null && selected.length == assets.length;
    final sizesReady = assets != null && _sizes.length == assets.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '确认删除',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (assets != null && assets.isNotEmpty)
            TextButton(
              onPressed: () {
                Haptics.selection();
                for (final a in assets) {
                  state.setMarked(a.id, !allSelected);
                }
              },
              child: Text(
                allSelected ? '全部保留' : '全选',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: assets == null
          ? const Center(child: LogoLoader(size: 72))
          : assets.isEmpty
          ? const Center(
              child: Text(
                '没有待删除的照片',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _SummaryCard(
                    count: selected.length,
                    bytes: bytes,
                    sizesReady: sizesReady,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Text(
                      '点照片看大图，点右上角圆圈可以保留这张',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                    itemCount: assets.length,
                    itemBuilder: (context, i) {
                      final a = assets[i];
                      return StaggerIn(
                        index: i,
                        child: _GridTile(
                          asset: a,
                          selected: state.isMarked(a.id),
                          onTap: () => _openViewer(i),
                          onToggle: () {
                            Haptics.selection();
                            state.setMarked(a.id, !state.isMarked(a.id));
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: AppButton(
            expand: true,
            color: AppColors.red,
            textColor: Colors.white,
            icon: selected.isEmpty ? null : Icons.delete_rounded,
            label: selected.isEmpty ? '没有选中要删除的照片' : '删除 ${selected.length} 项',
            loading: _deleting,
            onTap: selected.isEmpty
                ? null
                : () => _confirmDelete(selected, bytes),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.count,
    required this.bytes,
    required this.sizesReady,
  });

  final int count;
  final int bytes;
  final bool sizesReady;

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(color: AppColors.textTertiary, fontSize: 13);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('将删除', style: label),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      AnimatedInt(
                        value: count,
                        builder: (_, v) => Text(
                          '$v',
                          style: const TextStyle(
                            color: AppColors.red,
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const Text(
                        ' 项',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('可释放', style: label),
                  const SizedBox(height: 4),
                  sizesReady
                      ? AnimatedInt(
                          value: bytes,
                          builder: (_, v) => Text(
                            formatBytes(v),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            Platform.isIOS ? '删除后会进入「最近删除」，30 天内可以找回' : '删除后会进入系统回收站，可以找回',
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// 保留时变灰的滤镜。
const _grayscale = ColorFilter.matrix([
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0,
]);

class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.asset,
    required this.selected,
    required this.onTap,
    required this.onToggle,
  });

  final AssetEntity asset;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final image = Image(image: gridThumb(asset), fit: BoxFit.cover);
    return Pressable(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1 : 0.9,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'review-${asset.id}',
                child: AnimatedOpacity(
                  opacity: selected ? 1 : 0.45,
                  duration: const Duration(milliseconds: 220),
                  child: selected
                      ? image
                      : ColorFiltered(colorFilter: _grayscale, child: image),
                ),
              ),
              if (asset.type == AssetType.video)
                Positioned(
                  left: 6,
                  bottom: 5,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      Text(
                        formatDuration(asset.videoDuration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          shadows: [Shadow(blurRadius: 4)],
                        ),
                      ),
                    ],
                  ),
                ),
              AnimatedOpacity(
                opacity: selected ? 0 : 1,
                duration: const Duration(milliseconds: 220),
                child: const Center(
                  child: Text(
                    '保留',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(blurRadius: 6)],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggle,
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: selected
                          ? Container(
                              key: const ValueKey('on'),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.red,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            )
                          : Container(
                              key: const ValueKey('off'),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black26,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({required this.count, required this.bytes});

  final int count;
  final int bytes;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.red,
                  ),
                  child: const Icon(
                    Icons.delete_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '删除 $count 项？',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '预计释放 ${formatBytes(bytes)}\n'
                  '${Platform.isIOS ? '30 天内可在「最近删除」中恢复' : '可在系统回收站中恢复'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Pressable(
                        onTap: () => Navigator.of(context).pop(false),
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Text(
                            '再看看',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: '删除',
                        height: 50,
                        color: AppColors.red,
                        textColor: Colors.white,
                        onTap: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 确认页里点开的大图：可左右翻看、双指缩放，并切换勾选。
class _ReviewViewer extends StatefulWidget {
  const _ReviewViewer({required this.assets, required this.initialIndex});

  final List<AssetEntity> assets;
  final int initialIndex;

  @override
  State<_ReviewViewer> createState() => _ReviewViewerState();
}

class _ReviewViewerState extends State<_ReviewViewer> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;
  int _pointers = 0;
  bool _zoomed = false;

  bool get _locked => _zoomed || _pointers >= 2;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _setPointers(int n) {
    final wasLocked = _locked;
    _pointers = n.clamp(0, 10);
    if (wasLocked != _locked) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CleanerState>();
    final asset = widget.assets[_index];
    final marked = state.isMarked(asset.id);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          '${_index + 1} / ${widget.assets.length}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: Listener(
        onPointerDown: (_) => _setPointers(_pointers + 1),
        onPointerUp: (_) => _setPointers(_pointers - 1),
        onPointerCancel: (_) => _setPointers(_pointers - 1),
        child: PageView.builder(
          controller: _pages,
          physics: _locked
              ? const NeverScrollableScrollPhysics()
              : const PageScrollPhysics(),
          itemCount: widget.assets.length,
          onPageChanged: (i) => setState(() {
            _index = i;
            _zoomed = false;
          }),
          itemBuilder: (context, i) {
            final a = widget.assets[i];
            return _ZoomablePage(
              asset: a,
              isCurrent: i == _index,
              onZoomChanged: (z) => setState(() => _zoomed = z),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: marked
                ? Pressable(
                    key: const ValueKey('keep'),
                    onTap: () {
                      Haptics.light();
                      state.setMarked(asset.id, false);
                    },
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restore_rounded, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            '保留这张（取消删除）',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : AppButton(
                    key: const ValueKey('mark'),
                    expand: true,
                    color: AppColors.red,
                    textColor: Colors.white,
                    icon: Icons.delete_rounded,
                    label: '重新标记删除',
                    onTap: () {
                      Haptics.medium();
                      state.setMarked(asset.id, true);
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _ZoomablePage extends StatefulWidget {
  const _ZoomablePage({
    required this.asset,
    required this.isCurrent,
    required this.onZoomChanged,
  });

  final AssetEntity asset;
  final bool isCurrent;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomablePage> createState() => _ZoomablePageState();
}

class _ZoomablePageState extends State<_ZoomablePage> {
  final TransformationController _zoom = TransformationController();
  bool _zoomed = false;

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  void _update() {
    final z = _zoom.value.getMaxScaleOnAxis() > 1.01;
    if (z != _zoomed) {
      setState(() => _zoomed = z);
      widget.onZoomChanged(z);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.asset;
    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          transformationController: _zoom,
          minScale: 1,
          maxScale: 6,
          panEnabled: _zoomed,
          onInteractionUpdate: (_) => _update(),
          onInteractionEnd: (_) {
            if (_zoom.value.getMaxScaleOnAxis() <= 1.01) {
              _zoom.value = Matrix4.identity();
            }
            _update();
          },
          child: SizedBox.expand(
            child: Hero(
              tag: 'review-${a.id}',
              child: MediaImage(asset: a, hiRes: _zoomed),
            ),
          ),
        ),
        if (a.type == AssetType.video)
          InlineVideo(
            asset: a,
            isCurrent: widget.isCurrent,
            controlsBottom: 12,
          ),
      ],
    );
  }
}
