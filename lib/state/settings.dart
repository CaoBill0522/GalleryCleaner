import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SortOrder { newestFirst, oldestFirst }

enum MediaFilter { all, photos, videos }

enum LivePlayMode { longPress, auto }

extension LivePlayModeLabel on LivePlayMode {
  String get label => switch (this) {
    LivePlayMode.longPress => '长按播放',
    LivePlayMode.auto => '自动播放',
  };
}

extension SortOrderLabel on SortOrder {
  String get label => switch (this) {
    SortOrder.newestFirst => '从新到旧',
    SortOrder.oldestFirst => '从旧到新',
  };
}

extension MediaFilterLabel on MediaFilter {
  String get label => switch (this) {
    MediaFilter.all => '照片和视频',
    MediaFilter.photos => '仅照片',
    MediaFilter.videos => '仅视频',
  };
}

/// 用户设置，保存在本地。
class AppSettings extends ChangeNotifier {
  AppSettings._();

  /// 震动等不方便拿 context 的地方直接读这个实例。
  static final AppSettings instance = AppSettings._();

  static const _kSort = 'settings_sort';
  static const _kOnboarding = 'onboarding_done';
  static const _kFilter = 'settings_filter';
  static const _kHaptics = 'settings_haptics';
  static const _kInfo = 'settings_info';
  static const _kConfirm = 'settings_confirm_delete';
  static const _kLive = 'settings_live_mode';
  static const _kVideoAuto = 'settings_video_autoplay';
  static const _kMuted = 'settings_video_muted';

  late SharedPreferences _prefs;

  SortOrder sortOrder = SortOrder.newestFirst;
  MediaFilter mediaFilter = MediaFilter.all;
  bool haptics = true;

  /// 是否已经看过首次启动的功能向导。
  bool onboardingDone = false;
  bool showInfo = true;
  bool confirmBeforeDelete = true;
  LivePlayMode livePlayMode = LivePlayMode.longPress;
  bool videoAutoPlay = false;

  /// 视频和实况照片是否静音；播放器里切换后会记住。
  bool videoMuted = false;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    sortOrder = SortOrder.values[(_prefs.getInt(_kSort) ?? 0).clamp(0, 1)];
    mediaFilter =
        MediaFilter.values[(_prefs.getInt(_kFilter) ?? 0).clamp(0, 2)];
    haptics = _prefs.getBool(_kHaptics) ?? true;
    onboardingDone = _prefs.getBool(_kOnboarding) ?? false;
    showInfo = _prefs.getBool(_kInfo) ?? true;
    confirmBeforeDelete = _prefs.getBool(_kConfirm) ?? true;
    livePlayMode =
        LivePlayMode.values[(_prefs.getInt(_kLive) ?? 0).clamp(0, 1)];
    videoAutoPlay = _prefs.getBool(_kVideoAuto) ?? false;
    videoMuted = _prefs.getBool(_kMuted) ?? false;
  }

  /// 排序和显示内容共同决定浏览列表；浏览位置按它分开记。
  String get listKey => '${sortOrder.index}${mediaFilter.index}';

  void setSortOrder(SortOrder v) {
    sortOrder = v;
    _prefs.setInt(_kSort, v.index);
    notifyListeners();
  }

  void setMediaFilter(MediaFilter v) {
    mediaFilter = v;
    _prefs.setInt(_kFilter, v.index);
    notifyListeners();
  }

  void setOnboardingDone() {
    onboardingDone = true;
    _prefs.setBool(_kOnboarding, true);
  }

  void setHaptics(bool v) {
    haptics = v;
    _prefs.setBool(_kHaptics, v);
    notifyListeners();
  }

  void setShowInfo(bool v) {
    showInfo = v;
    _prefs.setBool(_kInfo, v);
    notifyListeners();
  }

  void setLivePlayMode(LivePlayMode v) {
    livePlayMode = v;
    _prefs.setInt(_kLive, v.index);
    notifyListeners();
  }

  void setVideoAutoPlay(bool v) {
    videoAutoPlay = v;
    _prefs.setBool(_kVideoAuto, v);
    notifyListeners();
  }

  void setVideoMuted(bool v) {
    videoMuted = v;
    _prefs.setBool(_kMuted, v);
    notifyListeners();
  }

  void setConfirmBeforeDelete(bool v) {
    confirmBeforeDelete = v;
    _prefs.setBool(_kConfirm, v);
    notifyListeners();
  }
}

/// 遵循「震动反馈」开关的震动。
class Haptics {
  static bool get _on => AppSettings.instance.haptics;

  static void selection() {
    if (_on) HapticFeedback.selectionClick();
  }

  static void light() {
    if (_on) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (_on) HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (_on) HapticFeedback.heavyImpact();
  }
}
