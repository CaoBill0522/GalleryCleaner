<?php
declare(strict_types=1);

/** 线性图标（24×24，描边）。 */
function svg_icon(string $name): string
{
    static $paths = [
        'swipe' => '<path d="M12 19V5"/><path d="m5 12 7-7 7 7"/>',
        'check-list' => '<path d="m3 17 2 2 4-4"/><path d="m3 7 2 2 4-4"/><path d="M13 6h8M13 12h8M13 18h8"/>',
        'shield' => '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/>',
        'calendar' => '<rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/>',
        'play' => '<rect x="2" y="4" width="20" height="16" rx="3"/><path d="m10 9 5 3-5 3z"/>',
        'live' => '<circle cx="12" cy="12" r="3"/><circle cx="12" cy="12" r="6.5"/><path d="M12 2v1M12 21v1M2 12h1M21 12h1M4.9 4.9l.7.7M18.4 18.4l.7.7M4.9 19.1l.7-.7M18.4 5.6l.7-.7"/>',
        'zoom' => '<circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3M11 8v6M8 11h6"/>',
        'resume' => '<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/><path d="M12 7v5l3 2"/>',
        'lock' => '<rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>',
        'apple' => '<path fill="currentColor" stroke="none" d="M16.37 12.6c-.02-2.2 1.8-3.26 1.88-3.31-1.03-1.5-2.62-1.7-3.18-1.73-1.35-.14-2.65.8-3.33.8-.7 0-1.75-.78-2.88-.76-1.48.02-2.85.86-3.61 2.19-1.54 2.67-.39 6.62 1.1 8.79.74 1.06 1.61 2.25 2.75 2.2 1.11-.04 1.52-.71 2.86-.71 1.33 0 1.71.71 2.88.69 1.19-.02 1.94-1.07 2.66-2.14.84-1.23 1.19-2.43 1.2-2.49-.03-.01-2.3-.88-2.33-3.53zM14.2 6.13c.6-.74 1.01-1.75.9-2.77-.87.04-1.94.59-2.56 1.32-.56.64-1.05 1.68-.92 2.67.98.08 1.97-.49 2.58-1.22z"/>',
        'android' => '<path fill="currentColor" stroke="none" d="M17.6 9.48l1.84-3.18a.38.38 0 0 0-.14-.52.38.38 0 0 0-.52.14l-1.86 3.22a11.3 11.3 0 0 0-9.84 0L5.22 5.92a.38.38 0 0 0-.52-.14.38.38 0 0 0-.14.52L6.4 9.48A10.78 10.78 0 0 0 1 18h22a10.78 10.78 0 0 0-5.4-8.52zM7 15.25A1.25 1.25 0 1 1 8.25 14 1.25 1.25 0 0 1 7 15.25zm10 0A1.25 1.25 0 1 1 18.25 14 1.25 1.25 0 0 1 17 15.25z"/>',
        'github' => '<path fill="currentColor" stroke="none" d="M12 2C6.48 2 2 6.48 2 12c0 4.42 2.87 8.17 6.84 9.5.5.09.68-.22.68-.48v-1.7c-2.78.6-3.37-1.34-3.37-1.34-.45-1.16-1.11-1.47-1.11-1.47-.91-.62.07-.6.07-.6 1 .07 1.53 1.03 1.53 1.03.89 1.53 2.34 1.09 2.91.83.09-.65.35-1.09.63-1.34-2.22-.25-4.55-1.11-4.55-4.94 0-1.09.39-1.98 1.03-2.68-.1-.25-.45-1.27.1-2.65 0 0 .84-.27 2.75 1.02a9.58 9.58 0 0 1 5 0c1.91-1.29 2.75-1.02 2.75-1.02.55 1.38.2 2.4.1 2.65.64.7 1.03 1.59 1.03 2.68 0 3.84-2.34 4.68-4.57 4.93.36.31.68.92.68 1.85v2.74c0 .27.18.58.69.48A10 10 0 0 0 22 12c0-5.52-4.48-10-10-10z"/>',
        'arrow' => '<path d="M5 12h14M13 5l7 7-7 7"/>',
    ];
    $p = $paths[$name] ?? '';
    return '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' . $p . '</svg>';
}

/** 下载按钮组（首页首屏和底部共用）。 */
function download_buttons(): string
{
    $ios = IOS_DOWNLOAD_URL !== ''
        ? '<a class="btn btn-white" href="' . e(IOS_DOWNLOAD_URL) . '" target="_blank" rel="noopener">' . svg_icon('apple') . 'App Store</a>'
        : '<span class="btn btn-grey" aria-disabled="true">' . svg_icon('apple') . 'iPhone <small>即将上架</small></span>';
    $android = '<a class="btn btn-white" href="' . e(ANDROID_DOWNLOAD_URL) . '" target="_blank" rel="noopener">' . svg_icon('android') . 'Android 下载</a>';
    $github = '<a class="btn btn-grey" href="' . e(GITHUB_URL) . '" target="_blank" rel="noopener">' . svg_icon('github') . '源代码</a>';
    return $ios . $android . $github;
}
