import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../models/year_month.dart';
import '../services/media_service.dart';
import '../state/cleaner_state.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../widgets/media_image.dart';
import '../widgets/ui.dart';

/// 按月清理：按年列出 12 个月，每月显示数量，点进去只清理这个月。
///
/// 选中月份后返回 [YearMonth]；选「全部时间」返回 [MonthsPage.allTime]。
class MonthsPage extends StatefulWidget {
  const MonthsPage({super.key});

  static const allTime = YearMonth(0, 0);

  @override
  State<MonthsPage> createState() => _MonthsPageState();
}

class _MonthsPageState extends State<MonthsPage> {
  late final AppSettings _settings = context.read<AppSettings>();
  late final CleanerState _cleaner = context.read<CleanerState>();

  /// 从新到旧的年份；null 表示还在加载。
  List<int>? _years;
  YearMonth? _oldest;
  YearMonth? _newest;
  final Map<YearMonth, Future<AssetEntity?>> _covers = {};
  bool _disposed = false;

  String _countKey(YearMonth m) => '${_settings.listKey}_${m.key}';

  int? _count(YearMonth m) => _cleaner.monthCounts[_countKey(m)];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _load() async {
    final range = await MediaService.monthRange(_settings);
    if (_disposed) return;
    if (range == null) {
      setState(() => _years = const []);
      return;
    }
    final (oldest, newest) = range;
    setState(() {
      _oldest = oldest;
      _newest = newest;
      _years = [for (var y = newest.year; y >= oldest.year; y--) y];
    });

    // 从最近的月份往前数，同时最多查 6 个月，数到一个刷新一次。
    final pending = <YearMonth>[];
    for (var m = newest; m.compareTo(oldest) >= 0; m = m.previous) {
      if (_count(m) == null) pending.add(m);
    }
    var next = 0;
    Future<void> worker() async {
      while (next < pending.length && !_disposed) {
        final m = pending[next++];
        final n = await MediaService.countInMonth(_settings, m);
        _cleaner.monthCounts[_countKey(m)] = n;
        if (!_disposed) setState(() {});
      }
    }

    await Future.wait(List.generate(6, (_) => worker()));
  }

  bool _inRange(YearMonth m) =>
      _oldest != null &&
      m.compareTo(_oldest!) >= 0 &&
      m.compareTo(_newest!) <= 0;

  Future<AssetEntity?> _cover(YearMonth m) =>
      _covers.putIfAbsent(m, () => MediaService.coverOfMonth(_settings, m));

  @override
  Widget build(BuildContext context) {
    final years = _years;
    final current = context.watch<CleanerState>().month;
    return Scaffold(
      appBar: AppBar(
        title: const Text('按月清理'),
        actions: [
          if (current != null)
            TextButton(
              onPressed: () => Navigator.of(context).pop(MonthsPage.allTime),
              child: const Text('全部时间', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: years == null
          ? const Center(child: LogoLoader(size: 72))
          : years.isEmpty
          ? const Center(
              child: Text(
                '相册里没有照片或视频',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : CustomScrollView(
              slivers: [
                for (final y in years.where((y) => !_emptyYear(y))) ...[
                  SliverToBoxAdapter(child: _yearHeader(y)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.82,
                          ),
                      itemCount: 12,
                      itemBuilder: (context, i) {
                        final m = YearMonth(y, i + 1);
                        return _MonthCell(
                          month: m,
                          count: _inRange(m) ? _count(m) : 0,
                          selected: m == current,
                          cover: _inRange(m) && (_count(m) ?? 0) > 0
                              ? _cover(m)
                              : null,
                          onTap: () => Navigator.of(context).pop(m),
                        );
                      },
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  /// 这一年已经数完且一张都没有，就不显示，免得一屏空月份。
  bool _emptyYear(int year) {
    for (var i = 1; i <= 12; i++) {
      final m = YearMonth(year, i);
      if (!_inRange(m)) continue;
      final n = _count(m);
      if (n == null || n > 0) return false;
    }
    return true;
  }

  Widget _yearHeader(int year) {
    var total = 0;
    var done = true;
    for (var i = 1; i <= 12; i++) {
      final m = YearMonth(year, i);
      if (!_inRange(m)) continue;
      final n = _count(m);
      if (n == null) {
        done = false;
      } else {
        total += n;
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '$year',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            done ? '共 $total 项' : '统计中…',
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.month,
    required this.count,
    required this.selected,
    required this.cover,
    required this.onTap,
  });

  final YearMonth month;

  /// null 表示还在统计。
  final int? count;
  final bool selected;
  final Future<AssetEntity?>? cover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = count;
    final empty = n == 0;
    return Pressable(
      onTap: empty || n == null ? null : onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: empty
                ? Colors.white.withValues(alpha: 0.03)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: selected ? Border.all(color: Colors.white, width: 2) : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (cover != null)
                FutureBuilder<AssetEntity?>(
                  future: cover,
                  builder: (context, snap) {
                    final a = snap.data;
                    if (a == null) return const SizedBox.shrink();
                    return AnimatedOpacity(
                      opacity: 1,
                      duration: const Duration(milliseconds: 200),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.45),
                          BlendMode.darken,
                        ),
                        child: Image(image: gridThumb(a), fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${month.month}月',
                      style: TextStyle(
                        color: empty ? Colors.white24 : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        shadows: const [Shadow(blurRadius: 4)],
                      ),
                    ),
                    Text(
                      n == null ? '…' : (empty ? '—' : '$n 项'),
                      style: TextStyle(
                        color: empty ? Colors.white24 : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        shadows: const [Shadow(blurRadius: 4)],
                      ),
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
