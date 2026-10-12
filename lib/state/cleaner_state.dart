import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/year_month.dart';
import '../services/mark_store.dart';
import '../services/media_service.dart';
import 'settings.dart';

class _UndoEntry {
  const _UndoEntry(this.id, this.index, this.marked);

  final String id;
  final int index;

  /// 这次操作是「标记」还是「取消标记」。
  final bool marked;
}

class CleanerState extends ChangeNotifier {
  CleanerState(this._store, this._settings);

  static const _pageSize = 60;
  static const _prefetch = 8;

  final MarkStore _store;
  final AppSettings _settings;

  bool loading = true;
  List<AssetPathEntity> albums = const [];
  AssetPathEntity? album;
  int total = 0;
  int currentIndex = 0;

  /// 每次重新加载相册时递增，浏览页据此重建 PageController。
  int generation = 0;

  /// 按月清理时的月份；null 表示全部时间。
  YearMonth? month;

  /// 日历页的每月数量缓存，删除或改设置后清空。
  final Map<String, int> monthCounts = {};

  /// 浏览位置按「排序/筛选 + 月份」分开记。
  String get _posKey => '${_settings.listKey}_${month?.key ?? 'all'}';

  final Map<int, AssetEntity> _cache = {};
  final Set<int> _loadingPages = {};
  final LinkedHashSet<String> _marked = LinkedHashSet();
  final List<_UndoEntry> _undo = [];

  int get markedCount => _marked.length;
  List<String> get markedIds => _marked.toList();
  bool get canUndo => _undo.isNotEmpty;
  bool isMarked(String id) => _marked.contains(id);

  Future<void> init() async {
    await _store.load();
    _marked.addAll(_store.markedIds);
    await reloadAlbums(preferredId: _store.albumId);
  }

  /// 重新读取相册。相册在读取过程中被改动（例如 iCloud 正在同步）时
  /// 可能失败，这时稍等重试一次；无论成败都不会让加载遮罩卡住。
  Future<void> reloadAlbums({String? preferredId, int? keepIndex}) async {
    loading = true;
    notifyListeners();
    for (var attempt = 0; ; attempt++) {
      try {
        albums = await MediaService.loadAlbums(_settings, month: month);
        final target =
            albums.where((a) => a.id == preferredId).firstOrNull ??
            albums.firstOrNull;
        await _openAlbum(target, keepIndex: keepIndex);
        return;
      } catch (e) {
        if (attempt >= 1) {
          debugPrint('reloadAlbums failed: $e');
          loading = false;
          generation++;
          notifyListeners();
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  Future<void> selectAlbum(AssetPathEntity a) async {
    if (a.id == album?.id) return;
    loading = true;
    notifyListeners();
    await _openAlbum(a);
  }

  Future<void> _openAlbum(AssetPathEntity? a, {int? keepIndex}) async {
    album = a;
    _cache.clear();
    _loadingPages.clear();
    _undo.clear();
    if (a == null) {
      total = 0;
      currentIndex = 0;
    } else {
      // 换掉旧的 AssetPathEntity，保证数量是最新的。
      // 插件的 obtainForNewProperties 会把时间上限重置为「现在」，
      // 按月筛选会失效，所以直接调底层方法并保留原来的时间范围。
      final fresh = await AssetPathEntity.obtainPathFromProperties(
        id: a.id,
        albumType: a.albumType,
        type: a.type,
        optionGroup: a.filterOption,
        maxDateTimeToNow: false,
      );
      album = fresh;
      total = await fresh.assetCountAsync;
      final saved = keepIndex ?? _store.position(fresh.id, _posKey);
      currentIndex = total == 0 ? 0 : saved.clamp(0, total - 1);
      _store.saveAlbumId(fresh.id);
      await _loadPage(currentIndex ~/ _pageSize, notify: false);
    }
    generation++;
    loading = false;
    notifyListeners();
  }

  /// 取第 [index] 张；还没加载时返回 null 并触发加载。
  AssetEntity? assetAt(int index) {
    final e = _cache[index];
    if (e == null && index >= 0 && index < total) {
      _loadPage(index ~/ _pageSize);
    }
    return e;
  }

  Future<void> _loadPage(int page, {bool notify = true}) async {
    final a = album;
    if (a == null || !_loadingPages.add(page)) return;
    final start = page * _pageSize;
    final end = min(start + _pageSize, total);
    try {
      final list = await a.getAssetListRange(start: start, end: end);
      if (a != album) return; // 加载期间已切换相册
      for (var i = 0; i < list.length; i++) {
        _cache[start + i] = list[i];
      }
    } finally {
      _loadingPages.remove(page);
    }
    if (notify) notifyListeners();
  }

  void setCurrentIndex(int index) {
    if (index == currentIndex) return;
    currentIndex = index;
    final a = album;
    if (a != null) _store.savePosition(a.id, _posKey, index);
    // 提前加载后面的页，滑动时不卡顿。
    final ahead = min(index + _prefetch, total - 1);
    if (ahead >= 0 && !_cache.containsKey(ahead)) _loadPage(ahead ~/ _pageSize);
    notifyListeners();
  }

  void mark(int index) => _setMarkAt(index, true);

  void unmark(int index) => _setMarkAt(index, false);

  void _setMarkAt(int index, bool marked) {
    final e = _cache[index];
    if (e == null || isMarked(e.id) == marked) return;
    _apply(e.id, marked);
    _undo.add(_UndoEntry(e.id, index, marked));
    notifyListeners();
  }

  /// 撤销上一次操作，返回该照片的位置，便于跳回去。
  int? undo() {
    if (_undo.isEmpty) return null;
    final entry = _undo.removeLast();
    _apply(entry.id, !entry.marked);
    notifyListeners();
    return entry.index;
  }

  /// 确认页里的勾选/取消。
  void setMarked(String id, bool marked) {
    if (isMarked(id) == marked) return;
    _apply(id, marked);
    _undo.clear();
    notifyListeners();
  }

  /// 排序或显示内容改了之后重新加载。
  Future<void> applySettings() {
    monthCounts.clear();
    return reloadAlbums(preferredId: album?.id);
  }

  /// 进入某个月（null 回到全部时间）。按月时总是从「全部照片」里筛选。
  Future<void> enterMonth(YearMonth? m) async {
    if (m == month) return;
    month = m;
    await reloadAlbums(preferredId: m == null ? album?.id : null);
  }

  /// 清除所有待删除标记。
  void clearAllMarks() {
    _marked.clear();
    _undo.clear();
    _store.saveMarked(_marked);
    notifyListeners();
  }

  /// 所有相册都回到第一张。
  Future<void> resetProgress() async {
    await _store.clearPositions();
    await reloadAlbums(preferredId: album?.id, keepIndex: 0);
  }

  /// 去掉已经不存在于相册里的标记。
  void dropMissing(Iterable<String> ids) {
    var changed = false;
    for (final id in ids) {
      changed |= _marked.remove(id);
    }
    if (changed) {
      _store.saveMarked(_marked);
      notifyListeners();
    }
  }

  void _apply(String id, bool marked) {
    if (marked) {
      _marked.add(id);
    } else {
      _marked.remove(id);
    }
    _store.saveMarked(_marked);
  }

  /// 删除给定的照片，返回实际删除的 id。
  Future<List<String>> delete(List<AssetEntity> assets) async {
    final deleted = await MediaService.delete(assets);
    if (deleted.isEmpty) return deleted;
    final deletedSet = deleted.toSet();
    // 当前位置之前被删掉的照片数，用来让删除后仍停在原来那张附近。
    final removedBefore = _cache.entries
        .where((e) => e.key < currentIndex && deletedSet.contains(e.value.id))
        .length;
    _marked.removeAll(deletedSet);
    monthCounts.clear();
    await _store.saveMarked(_marked);
    await reloadAlbums(
      preferredId: album?.id,
      keepIndex: max(0, currentIndex - removedBefore),
    );
    return deleted;
  }
}
