import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../services/media_service.dart';
import '../state/cleaner_state.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'viewer_page.dart';

/// 申请相册权限，通过后进入浏览页。
class HomeGate extends StatefulWidget {
  const HomeGate({super.key});

  @override
  State<HomeGate> createState() => _HomeGateState();
}

class _HomeGateState extends State<HomeGate> with WidgetsBindingObserver {
  PermissionState? _permission;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _request();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 从系统设置回来后重新检查。
    if (state == AppLifecycleState.resumed &&
        _permission != null &&
        !_started) {
      _request(prompt: false);
    }
  }

  Future<void> _request({bool prompt = true}) async {
    final ps = prompt
        ? await MediaService.requestPermission()
        : await MediaService.checkPermission();
    if (!mounted) return;
    setState(() => _permission = ps);
    if (ps.hasAccess && !_started) {
      _started = true;
      context.read<CleanerState>().init();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ps = _permission;
    final Widget child;
    if (ps == null) {
      child = const Scaffold(
        key: ValueKey('loading'),
        body: Center(child: LogoLoader()),
      );
    } else if (ps.hasAccess) {
      child = const ViewerPage(key: ValueKey('viewer'));
    } else {
      child = _PermissionPage(
        key: const ValueKey('permission'),
        onRecheck: () => _request(prompt: false),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: child,
    );
  }
}

class _PermissionPage extends StatelessWidget {
  const _PermissionPage({super.key, required this.onRecheck});

  final VoidCallback onRecheck;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const LogoLoader(size: 108),
              const SizedBox(height: 28),
              const Text(
                '相册清道夫',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '需要访问相册才能帮你清理',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 32),
              ...const [
                _Feature(
                  icon: Icons.swipe_up_rounded,
                  text: '上滑标记，左右切换，一张张快速过',
                ),
                _Feature(icon: Icons.fact_check_rounded, text: '删除前统一确认，避免删错'),
                _Feature(icon: Icons.lock_rounded, text: '全部在手机本地完成，不上传任何照片'),
              ].indexed.map((e) => StaggerIn(index: e.$1 + 2, child: e.$2)),
              const Spacer(flex: 3),
              const AppButton(
                expand: true,
                icon: Icons.settings_rounded,
                label: '去设置里开启',
                onTap: PhotoManager.openSetting,
              ),
              TextButton(
                onPressed: onRecheck,
                child: const Text(
                  '已开启，重新检查',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
