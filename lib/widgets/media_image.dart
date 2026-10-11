import 'dart:math';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

/// 按比例缩放到最长边为 [longest] 的缩略图尺寸。
ThumbnailSize thumbSizeFor(AssetEntity asset, int longest) {
  final size = asset.orientatedSize;
  if (size.width <= 0 || size.height <= 0) return ThumbnailSize.square(longest);
  final scale = min(1.0, longest / max(size.width, size.height));
  return ThumbnailSize(
    max(1, (size.width * scale).round()),
    max(1, (size.height * scale).round()),
  );
}

ImageProvider gridThumb(AssetEntity asset) => AssetEntityImageProvider(
  asset,
  isOriginal: false,
  thumbnailSize: thumbSizeFor(asset, 360),
);

/// 全屏展示用：先显示小图，高清图加载完再淡入。
class MediaImage extends StatelessWidget {
  const MediaImage({super.key, required this.asset, this.hiRes = false});

  final AssetEntity asset;

  /// 放大查看时加载更清晰的版本。
  final bool hiRes;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenLongest =
        (max(mq.size.width, mq.size.height) * mq.devicePixelRatio).round();
    final longest = hiRes ? 4096 : min(screenLongest, 2560);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image(
          image: AssetEntityImageProvider(
            asset,
            isOriginal: false,
            thumbnailSize: thumbSizeFor(asset, 360),
          ),
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
        Image(
          image: AssetEntityImageProvider(
            asset,
            isOriginal: false,
            thumbnailSize: thumbSizeFor(asset, longest),
          ),
          fit: BoxFit.contain,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, sync) {
            if (sync) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 150),
              child: child,
            );
          },
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
