<?php
declare(strict_types=1);

const SITE_NAME = '相册清道夫';
const SITE_NAME_EN = 'Gallery Cleaner';
const SITE_URL = 'https://gallerycleaner.oxoz.cn';
const SITE_TAGLINE = '一张张过照片，上滑标记，确认后一次删干净。';
const SITE_DESCRIPTION = '相册清道夫是一款免费、开源、完全离线的相册清理工具。左右滑动浏览，上滑标记，确认后批量删除，支持按月清理、视频和实况照片，适用于 iPhone 和 Android。';

const GITHUB_URL = 'https://github.com/CaoBill0522/GalleryCleaner';
const ANDROID_DOWNLOAD_URL = GITHUB_URL . '/releases/latest';
/** App Store 上架后填入链接；为空时显示「即将上架」。 */
const IOS_DOWNLOAD_URL = '';

const APP_VERSION = '1.0.0';
const LEGAL_EFFECTIVE_DATE = '2026 年 10 月 11 日';

/** 顶部导航：文件名 => 标题 */
const NAV_ITEMS = [
    'index.php' => '首页',
    'guide.php' => '使用指南',
    'demo.php' => '在线体验',
];

/**
 * 在线体验用的演示照片。日期是虚构的拍摄时间，大小按真实手机照片估算。
 * tag 用来在体验里提示「这张可能是废片」，不影响操作。
 */
const DEMO_PHOTOS = [
    ['file' => '01-sunset.jpg', 'date' => '2026-09-28 18:42', 'size' => 3_480_000],
    ['file' => '02-sunset-dup.jpg', 'date' => '2026-09-28 18:42', 'size' => 3_510_000, 'tag' => '连拍重复'],
    ['file' => '03-sunset-blur.jpg', 'date' => '2026-09-28 18:42', 'size' => 2_960_000, 'tag' => '拍糊了'],
    ['file' => '04-chat.jpg', 'date' => '2026-09-20 21:05', 'size' => 860_000, 'tag' => '聊天截图'],
    ['file' => '05-beach.jpg', 'date' => '2026-08-16 15:20', 'size' => 4_120_000],
    ['file' => '06-receipt.jpg', 'date' => '2026-08-21 09:12', 'size' => 720_000, 'tag' => '支付截图'],
    ['file' => '07-city-night.jpg', 'date' => '2026-08-09 22:10', 'size' => 3_870_000],
    ['file' => '08-dark.jpg', 'date' => '2026-07-30 20:01', 'size' => 1_940_000, 'tag' => '误拍黑屏'],
    ['file' => '09-forest.jpg', 'date' => '2026-07-12 10:30', 'size' => 4_350_000],
    ['file' => '10-desert.jpg', 'date' => '2026-07-03 17:45', 'size' => 3_660_000],
    ['file' => '11-aurora.jpg', 'date' => '2026-06-18 23:50', 'size' => 5_020_000],
    ['file' => '12-flowers.jpg', 'date' => '2026-05-02 11:20', 'size' => 4_480_000],
    ['file' => '13-lake.jpg', 'date' => '2026-04-11 08:15', 'size' => 3_930_000],
    ['file' => '14-fields.jpg', 'date' => '2026-03-22 07:05', 'size' => 3_710_000],
    ['file' => '15-snow.jpg', 'date' => '2026-01-15 13:30', 'size' => 3_280_000],
    ['file' => '16-city-day.jpg', 'date' => '2025-11-08 14:00', 'size' => 3_590_000],
];

function e(?string $s): string
{
    return htmlspecialchars($s ?? '', ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

/** 静态资源加版本号，文件改动后浏览器会重新下载。 */
function asset(string $path): string
{
    $file = __DIR__ . '/../' . $path;
    $v = is_file($file) ? (string) filemtime($file) : APP_VERSION;
    return $path . '?v=' . $v;
}

function current_page(): string
{
    return basename($_SERVER['SCRIPT_NAME'] ?? 'index.php');
}

/** 给在线体验用的照片数据（JSON 安全）。 */
function demo_photos_json(): string
{
    $list = [];
    foreach (DEMO_PHOTOS as $p) {
        $t = DateTimeImmutable::createFromFormat('Y-m-d H:i', $p['date']);
        $list[] = [
            'src' => asset('assets/demo/' . $p['file']),
            'date' => $t ? $t->format('Y年n月j日 H:i') : $p['date'],
            'size' => $p['size'],
            'tag' => $p['tag'] ?? null,
        ];
    }
    return json_encode($list, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_HEX_TAG | JSON_HEX_AMP);
}
