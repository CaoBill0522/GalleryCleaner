import 'package:shared_preferences/shared_preferences.dart';

/// 本地持久化：待删除标记、当前相册、每个相册的浏览位置。
///
/// 浏览位置按「相册 + 排序/筛选」分开记，切换设置后再切回来还能接着看。
class MarkStore {
  static const _kMarked = 'marked_ids';
  static const _kAlbum = 'album_id';
  static const _kPosPrefix = 'pos_';

  late SharedPreferences _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
  }

  List<String> get markedIds => _prefs.getStringList(_kMarked) ?? const [];

  Future<void> saveMarked(Iterable<String> ids) =>
      _prefs.setStringList(_kMarked, ids.toList());

  String? get albumId => _prefs.getString(_kAlbum);

  Future<void> saveAlbumId(String id) => _prefs.setString(_kAlbum, id);

  int position(String albumId, String listKey) =>
      _prefs.getInt('$_kPosPrefix${albumId}_$listKey') ?? 0;

  Future<void> savePosition(String albumId, String listKey, int index) =>
      _prefs.setInt('$_kPosPrefix${albumId}_$listKey', index);

  /// 清掉所有相册的浏览位置。
  Future<void> clearPositions() async {
    for (final k in _prefs.getKeys().where((k) => k.startsWith(_kPosPrefix))) {
      await _prefs.remove(k);
    }
  }
}
