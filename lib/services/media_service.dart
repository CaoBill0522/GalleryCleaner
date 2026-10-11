import 'dart:io';

import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/year_month.dart';
import '../state/settings.dart';

class MediaService {
  static const _permissionOption = PermissionRequestOption(
    androidPermission: AndroidPermission(
      type: RequestType.common,
      mediaLocation: false,
    ),
  );

  static Future<PermissionState> requestPermission() =>
      PhotoManager.requestPermissionExtend(requestOption: _permissionOption);

  /// 只查询，不弹系统授权框。
  static Future<PermissionState> checkPermission() =>
      PhotoManager.getPermissionState(requestOption: _permissionOption);

  static RequestType requestType(AppSettings settings) =>
      switch (settings.mediaFilter) {
        MediaFilter.all => RequestType.common,
        MediaFilter.photos => RequestType.image,
        MediaFilter.videos => RequestType.video,
      };

  /// Android 上按拍摄时间（毫秒）筛选和排序；没有拍摄时间的用加入时间兜底。
  /// 插件默认用的是「加入设备的时间」，迁移过来的照片会被分到迁移当月。
  static const _androidTakenMs =
      'COALESCE(NULLIF(datetaken, 0), date_added * 1000)';

  /// 排序 + 可选的时间范围。
  static PMFilter filter(
    AppSettings settings, {
    YearMonth? month,
    bool? ascending,
  }) {
    final asc = ascending ?? settings.sortOrder == SortOrder.oldestFirst;
    if (Platform.isAndroid) {
      // 插件在自定义 where 时不再自动加媒体类型限制，这里自己补上
      // （MediaStore: 1 = 图片，3 = 视频）。
      final type = switch (settings.mediaFilter) {
        MediaFilter.all => 'media_type IN (1, 3)',
        MediaFilter.photos => 'media_type = 1',
        MediaFilter.videos => 'media_type = 3',
      };
      final range = month == null
          ? ''
          : ' AND $_androidTakenMs >= ${month.start.millisecondsSinceEpoch}'
                ' AND $_androidTakenMs <= ${month.end.millisecondsSinceEpoch}';
      return CustomFilter.sql(
        where: '$type$range',
        orderBy: [OrderByItem(_androidTakenMs, asc)],
      );
    }
    return FilterOptionGroup(
      orders: [OrderOption(type: OrderOptionType.createDate, asc: asc)],
      createTimeCond: month == null
          ? DateTimeCond(min: DateTime(1970), max: DateTime(2100))
          : DateTimeCond(min: month.start, max: month.end),
    );
  }

  /// 全部相册（第一个是「全部」），按设置排序和筛选；空相册不显示。
  /// 传入 [month] 时只包含这个月的照片。
  static Future<List<AssetPathEntity>> loadAlbums(
    AppSettings settings, {
    YearMonth? month,
  }) async {
    final albums = await PhotoManager.getAssetPathList(
      type: requestType(settings),
      filterOption: filter(settings, month: month),
    );
    final counts = await Future.wait(albums.map((a) => a.assetCountAsync));
    return [
      for (var i = 0; i < albums.length; i++)
        if (albums[i].isAll || counts[i] > 0) albums[i],
    ];
  }

  /// 相册里最早和最新的月份；相册为空时返回 null。
  static Future<(YearMonth, YearMonth)?> monthRange(
    AppSettings settings,
  ) async {
    Future<AssetEntity?> edge(bool ascending) async {
      final list = await PhotoManager.getAssetListRange(
        start: 0,
        end: 1,
        type: requestType(settings),
        filterOption: filter(settings, ascending: ascending),
      );
      return list.firstOrNull;
    }

    final oldest = await edge(true);
    final newest = await edge(false);
    if (oldest == null || newest == null) return null;
    return (
      YearMonth.of(oldest.createDateTime),
      YearMonth.of(newest.createDateTime),
    );
  }

  /// 某个月有多少项。
  static Future<int> countInMonth(AppSettings settings, YearMonth month) =>
      PhotoManager.getAssetCount(
        type: requestType(settings),
        filterOption: filter(settings, month: month),
      );

  /// 某个月最新的一张，用作封面。
  static Future<AssetEntity?> coverOfMonth(
    AppSettings settings,
    YearMonth month,
  ) async {
    final list = await PhotoManager.getAssetListRange(
      start: 0,
      end: 1,
      type: requestType(settings),
      filterOption: filter(settings, month: month, ascending: false),
    );
    return list.firstOrNull;
  }

  /// 批量删除，返回真正被删除的 id（用户在系统弹窗里取消则为空）。
  ///
  /// iOS：进入「最近删除」，30 天内可恢复。
  /// Android 11+：移入系统回收站；更老的系统直接删除。
  static Future<List<String>> delete(List<AssetEntity> assets) async {
    if (assets.isEmpty) return const [];
    if (Platform.isAndroid) {
      try {
        return await PhotoManager.editor.android.moveToTrash(assets);
      } on PlatformException {
        // Android 10 及以下没有回收站。
      }
    }
    return PhotoManager.editor.deleteWithIds(assets.map((e) => e.id).toList());
  }
}
