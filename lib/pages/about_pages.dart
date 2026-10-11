import 'package:flutter/material.dart';

import '../config.dart';
import '../theme.dart';

/// 隐私政策 / 用户协议。
class LegalPage extends StatelessWidget {
  const LegalPage.privacy({super.key}) : title = '隐私政策', sections = _privacy;

  const LegalPage.terms({super.key}) : title = '用户协议', sections = _terms;

  final String title;
  final List<(String, String)> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          const Text(
            '生效日期：${AppInfo.legalEffectiveDate}',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
          for (final (h, body) in sections) ...[
            const SizedBox(height: 20),
            Text(
              h,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.7,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

const _privacy = [
  (
    '概述',
    '${AppInfo.nameZh}（以下简称「本应用」）是一款在手机本地运行的相册整理工具。我们非常重视你的隐私，本政策说明本应用如何处理你的信息。',
  ),
  ('我们不收集任何个人信息', '本应用不包含账号系统，不接入任何统计、广告或第三方数据分析服务，也不会把你的照片、视频或其他任何数据上传到网络。'),
  (
    '相册访问权限',
    '本应用需要相册访问权限，仅用于在本机上展示照片和视频、读取拍摄时间和文件大小，以及在你确认后删除你选中的项目。删除操作由系统执行，删除前系统会再次向你确认，删除的项目会进入系统的「最近删除」或回收站。',
  ),
  (
    '本地存储的数据',
    '为了让你中途退出后能接着整理，本应用会在本机保存：待删除标记（照片的系统标识，不含照片内容）、各相册的浏览位置，以及你的设置。这些数据只保存在本机，卸载应用后会一并清除。你也可以在「设置 → 数据」中随时清除。',
  ),
  ('外部链接', '设置页中的产品官网、GitHub 等链接会用系统浏览器打开，相关页面的隐私处理以对应网站的政策为准。'),
  ('政策更新', '本政策如有更新，会在应用内的此页面公布。'),
  ('联系我们', '如有任何问题，欢迎通过 GitHub 项目页面反馈。'),
];

const _terms = [
  ('接受协议', '使用${AppInfo.nameZh}（以下简称「本应用」）即表示你同意本协议。如不同意，请停止使用本应用。'),
  ('服务内容', '本应用帮助你逐张浏览相册、标记不需要的照片和视频，并在你确认后批量删除。本应用免费提供，所有操作均在本机完成。'),
  (
    '删除操作',
    '照片和视频的删除由你主动确认后执行，并经过系统的二次确认。删除的项目会进入系统的「最近删除」（iOS）或回收站（Android 11 及以上），在系统规定的期限内可以恢复，超过期限后将被永久删除。请在删除前仔细核对，因误删造成的数据损失由你自行承担。',
  ),
  (
    '免责声明',
    '本应用按「现状」提供，不对其适用性、准确性或不间断运行作任何明示或暗示的保证。对于使用本应用导致的任何直接或间接损失，在法律允许的范围内，开发者不承担责任。建议定期备份重要照片。',
  ),
  ('知识产权', '本应用的名称、图标和界面设计归开发者所有。本应用使用的第三方开源组件，其权利归各自作者所有，详见「开源许可」。'),
  ('协议变更', '开发者可能会更新本协议，更新后会在应用内的此页面公布，继续使用即视为接受更新后的协议。'),
];

/// 鸣谢：本应用依赖的开源项目。
class AcknowledgementsPage extends StatelessWidget {
  const AcknowledgementsPage({super.key});

  static const _items = [
    ('Flutter', 'Google 出品的跨平台 UI 框架', 'BSD-3-Clause'),
    ('photo_manager', '相册读取与删除', 'Apache-2.0'),
    ('photo_manager_image_provider', '相册缩略图加载', 'Apache-2.0'),
    ('video_player', '视频与实况照片播放', 'BSD-3-Clause'),
    ('provider', '状态管理', 'MIT'),
    ('shared_preferences', '本地保存设置和标记', 'BSD-3-Clause'),
    ('url_launcher', '打开外部链接', 'BSD-3-Clause'),
    ('package_info_plus', '读取版本号', 'BSD-3-Clause'),
    ('flutter_launcher_icons', '生成应用图标', 'MIT'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('鸣谢')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 16),
            child: Text(
              '${AppInfo.nameZh}基于以下开源项目构建，感谢所有作者和贡献者。完整许可证文本见「设置 → 开源许可」。',
              style: TextStyle(color: AppColors.textSecondary, height: 1.6),
            ),
          ),
          for (final (name, desc, license) in _items)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    license,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
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
