import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../state/cleaner_state.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'about_pages.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final AppSettings _settings;
  late final CleanerState _cleaner;
  late final String _listKey;
  final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  @override
  void initState() {
    super.initState();
    // dispose 里不能再通过 context 查找，提前拿好引用。
    _settings = context.read<AppSettings>();
    _cleaner = context.read<CleanerState>();
    _listKey = _settings.listKey;
  }

  @override
  void dispose() {
    // 排序或显示内容改了，回到浏览页时重新加载。
    if (_settings.listKey != _listKey) {
      final cleaner = _cleaner;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => cleaner.applySettings(),
      );
    }
    super.dispose();
  }

  Future<void> _open(String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('无法打开链接')));
    }
  }

  void _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  Future<void> _pick<T>({
    required String title,
    required List<T> options,
    required T current,
    required String Function(T) label,
    required ValueChanged<T> onPicked,
  }) async {
    final picked = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final o in options)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(label(o)),
                trailing: o == current
                    ? const Icon(Icons.check_rounded, color: Colors.white)
                    : null,
                onTap: () => Navigator.of(context).pop(o),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) onPicked(picked);
  }

  Future<bool> _confirm(String title, String message, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action, style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final cleaner = context.watch<CleanerState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '设置',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _Section(
            title: '浏览',
            children: [
              _Tile(
                icon: Icons.swap_vert_rounded,
                title: '排序方式',
                value: '拍摄时间 · ${s.sortOrder.label}',
                onTap: () => _pick(
                  title: '排序方式',
                  options: SortOrder.values,
                  current: s.sortOrder,
                  label: (o) => '按拍摄时间${o.label}',
                  onPicked: s.setSortOrder,
                ),
              ),
              _Tile(
                icon: Icons.filter_list_rounded,
                title: '显示内容',
                value: s.mediaFilter.label,
                onTap: () => _pick(
                  title: '显示内容',
                  options: MediaFilter.values,
                  current: s.mediaFilter,
                  label: (o) => o.label,
                  onPicked: s.setMediaFilter,
                ),
              ),
              _SwitchTile(
                icon: Icons.info_outline_rounded,
                title: '显示日期和大小',
                value: s.showInfo,
                onChanged: s.setShowInfo,
              ),
            ],
          ),
          _Section(
            title: '视频与实况照片',
            children: [
              _SwitchTile(
                icon: Icons.play_circle_outline_rounded,
                title: '视频自动播放',
                subtitle: '翻到视频时直接开始播放',
                value: s.videoAutoPlay,
                onChanged: s.setVideoAutoPlay,
              ),
              _Tile(
                icon: Icons.motion_photos_on_outlined,
                title: '实况照片',
                value: s.livePlayMode.label,
                onTap: () => _pick(
                  title: '实况照片播放方式',
                  options: LivePlayMode.values,
                  current: s.livePlayMode,
                  label: (o) => switch (o) {
                    LivePlayMode.longPress => '长按照片播放',
                    LivePlayMode.auto => '翻到时自动播放一次',
                  },
                  onPicked: s.setLivePlayMode,
                ),
              ),
              _SwitchTile(
                icon: Icons.volume_off_outlined,
                title: '静音播放',
                value: s.videoMuted,
                onChanged: s.setVideoMuted,
              ),
            ],
          ),
          _Section(
            title: '操作',
            children: [
              _SwitchTile(
                icon: Icons.vibration_rounded,
                title: '震动反馈',
                value: s.haptics,
                onChanged: s.setHaptics,
              ),
              _SwitchTile(
                icon: Icons.verified_user_outlined,
                title: '删除前确认',
                subtitle: '关闭后仍会弹出系统的删除确认',
                value: s.confirmBeforeDelete,
                onChanged: s.setConfirmBeforeDelete,
              ),
            ],
          ),
          _Section(
            title: '数据',
            children: [
              _Tile(
                icon: Icons.layers_clear_outlined,
                title: '清除所有标记',
                value: cleaner.markedCount > 0
                    ? '${cleaner.markedCount} 项'
                    : null,
                destructive: true,
                onTap: cleaner.markedCount == 0
                    ? null
                    : () async {
                        if (await _confirm(
                          '清除所有标记？',
                          '${cleaner.markedCount} 项待删除标记会被清除，照片本身不受影响。',
                          '清除',
                        )) {
                          cleaner.clearAllMarks();
                        }
                      },
              ),
              _Tile(
                icon: Icons.restart_alt_rounded,
                title: '重置浏览进度',
                destructive: true,
                onTap: () async {
                  if (await _confirm('重置浏览进度？', '所有相册都会回到第一张，标记不受影响。', '重置')) {
                    await cleaner.resetProgress();
                  }
                },
              ),
            ],
          ),
          _Section(
            title: '关于',
            children: [
              _Tile(
                icon: Icons.language_rounded,
                title: '产品官网',
                external: true,
                onTap: () => _open(AppLinks.website),
              ),
              _Tile(
                icon: Icons.code_rounded,
                title: 'GitHub',
                external: true,
                onTap: () => _open(AppLinks.github),
              ),
              _Tile(
                icon: Icons.privacy_tip_outlined,
                title: '隐私政策',
                onTap: () => _push(const LegalPage.privacy()),
              ),
              _Tile(
                icon: Icons.description_outlined,
                title: '用户协议',
                onTap: () => _push(const LegalPage.terms()),
              ),
              _Tile(
                icon: Icons.favorite_border_rounded,
                title: '鸣谢',
                onTap: () => _push(const AcknowledgementsPage()),
              ),
              _Tile(
                icon: Icons.article_outlined,
                title: '开源许可',
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: AppInfo.nameZh,
                  applicationIcon: const Padding(
                    padding: EdgeInsets.all(12),
                    child: AppLogo(size: 64),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                const AppLogo(size: 56),
                const SizedBox(height: 10),
                const Text(
                  '${AppInfo.nameZh} · ${AppInfo.nameEn}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<PackageInfo>(
                  future: _info,
                  builder: (context, snap) => Text(
                    snap.hasData
                        ? '版本 ${snap.data!.version} (${snap.data!.buildNumber})'
                        : ' ',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: AppColors.surface,
              child: Column(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        height: 1,
                        thickness: 0.5,
                        indent: 52,
                        color: Colors.white12,
                      ),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
    this.external = false,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final bool external;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.red : Colors.white;
    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: color, fontSize: 16),
                ),
              ),
              if (value != null)
                Text(
                  value!,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 14,
                  ),
                ),
              if (!destructive)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    external
                        ? Icons.open_in_new_rounded
                        : Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                    size: external ? 18 : 22,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: const Color(0xFF34C759),
            ),
          ],
        ),
      ),
    );
  }
}
