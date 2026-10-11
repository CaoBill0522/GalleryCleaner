<p align="center">
  <img src="assets/icon/icon.png" width="120" alt="相册清道夫图标">
</p>

<h1 align="center">相册清道夫 · Gallery Cleaner</h1>

<p align="center">
  一张张过照片，上滑标记，确认后一次删干净。<br>
  <a href="https://gallerycleaner.oxoz.cn">官网</a>
</p>

---

手机相册里堆满了截图、连拍、重复照片，系统相册删起来又慢又容易删错。相册清道夫把清理变成「刷卡片」：左右切换，上滑标记，全部看完后在确认页统一核对，再一次性删除。

## 功能

- **滑动清理**：左右滑动切换照片，上滑标记删除，下滑取消标记，支持撤销
- **先标记、后删除**：标记不会立刻删除，完成后进入确认页逐张核对，可以随时取消某一张
- **安全删除**：删除走系统接口，照片进入 iOS「最近删除」或 Android 回收站，30 天内可以找回
- **按月清理**：日历视图按月统计照片数量，可以只清理某一个月
- **视频和实况照片**：视频在当前页直接播放，支持倍速、静音和精细拖动进度条；实况照片支持长按播放或自动播放
- **双指缩放**：看清细节再决定要不要删
- **断点续看**：标记和浏览进度保存在本地，下次打开接着清理
- **相册与筛选**：可切换相册，可按拍摄时间正序或倒序，可只看照片或只看视频
- **完全离线**：不联网、不上传、不收集任何数据

## 操作方式

| 手势 | 作用 |
| --- | --- |
| 左右滑动 | 上一张 / 下一张 |
| 上滑 | 标记删除，并自动跳到下一张 |
| 下滑（已标记的照片） | 取消标记 |
| 双指张合 | 放大 / 缩小 |
| 长按实况照片 | 播放实况 |

## 平台支持

| 平台 | 最低版本 |
| --- | --- |
| iOS | iOS 15 |
| Android | Android 7.0（API 24） |

实况照片仅在 iOS 上支持。Android 11 以下的系统没有回收站，删除后无法恢复。

## 从源码构建

需要 [Flutter](https://flutter.dev) 3.47 或更高版本。

```bash
git clone https://github.com/CaoBill0522/GalleryCleaner.git
cd GalleryCleaner
flutter pub get
flutter run
```

打包发布版：

```bash
flutter build apk --release   # Android
flutter build ios --release   # iOS，需要在 Xcode 中配置自己的签名团队
```

iOS 工程里的签名团队是作者自己的，构建前请在 Xcode 的 Runner → Signing & Capabilities 中改成你自己的团队。

## 项目结构

```
lib/
├── main.dart              # 入口
├── config.dart            # 官网、GitHub 等外部链接
├── theme.dart             # 配色与主题
├── models/                # 数据模型（年月等）
├── services/              # 相册读取、删除、本地存储
├── state/                 # 状态管理（清理进度、设置）
├── pages/                 # 页面：浏览、确认删除、按月、设置、关于
└── widgets/               # 组件：滑动卡片、视频播放、实况照片等
assets/icon/               # 应用图标及生成脚本
```

应用图标由 `assets/icon/generate_icon.swift` 绘制，改完后执行下面的命令重新生成各尺寸图标：

```bash
swift assets/icon/generate_icon.swift assets/icon
dart run flutter_launcher_icons
```

## 隐私

相册清道夫只在本机读取相册，不包含任何网络请求、统计或广告 SDK。本地只保存待删除标记（照片的系统 ID）、浏览进度和设置，卸载即清除。完整内容见应用内「设置 → 隐私政策」。

## 许可证

本项目基于 [GNU General Public License v3.0](LICENSE) 开源。你可以自由使用、修改和分发，但基于本项目发布的作品也必须以 GPL-3.0 开源。

Copyright (C) 2026 JIACHENG CAO

## 致谢

基于 [Flutter](https://flutter.dev) 构建，使用了 [photo_manager](https://pub.dev/packages/photo_manager)、[video_player](https://pub.dev/packages/video_player)、[provider](https://pub.dev/packages/provider) 等开源项目，完整列表见应用内「设置 → 鸣谢」与「开源许可」。

---

# English

**Gallery Cleaner** is a swipe-based photo library cleaner for iOS and Android, built with Flutter.

- Swipe left/right to browse, swipe up to mark for deletion, swipe down to unmark
- Review all marked items before deleting them in one batch; deleted items go to the system's Recently Deleted / Trash
- Monthly calendar view to clean one month at a time
- Inline video player with speed control and fine scrubbing; Live Photo playback on iOS
- Fully offline: no network access, no analytics, no data collection

Build with `flutter pub get && flutter run` (Flutter 3.47+).

Licensed under the [GNU General Public License v3.0](LICENSE).
