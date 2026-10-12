<?php
/**
 * 页面头部。调用前可设置：
 *   $page_title       页面标题（不含站点名）
 *   $page_description 页面描述
 *   $body_class       body 上的额外 class
 */
declare(strict_types=1);
require_once __DIR__ . '/config.php';

$page_title = $page_title ?? null;
$full_title = $page_title ? $page_title . ' - ' . SITE_NAME : SITE_NAME . ' · ' . SITE_NAME_EN . ' - 滑动清理相册';
$page_description = $page_description ?? SITE_DESCRIPTION;
$canonical = SITE_URL . '/' . (current_page() === 'index.php' ? '' : current_page());
?>
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <title><?= e($full_title) ?></title>
  <meta name="description" content="<?= e($page_description) ?>">
  <meta name="theme-color" content="#0a0a0a">
<?php if (IOS_APP_ID !== ''): ?>
  <meta name="apple-itunes-app" content="app-id=<?= e(IOS_APP_ID) ?>">
<?php endif; ?>
  <link rel="canonical" href="<?= e($canonical) ?>">
  <link rel="icon" type="image/png" sizes="32x32" href="<?= e(asset('assets/img/favicon-32.png')) ?>">
  <link rel="apple-touch-icon" href="<?= e(asset('assets/img/apple-touch-icon.png')) ?>">
  <meta property="og:type" content="website">
  <meta property="og:title" content="<?= e($full_title) ?>">
  <meta property="og:description" content="<?= e($page_description) ?>">
  <meta property="og:image" content="<?= e(SITE_URL . '/assets/img/icon-512.png') ?>">
  <meta property="og:url" content="<?= e($canonical) ?>">
  <link rel="stylesheet" href="<?= e(asset('assets/css/site.css')) ?>">
</head>
<body class="<?= e($body_class ?? '') ?>">
<a class="skip-link" href="#main">跳到正文</a>
<header class="site-header">
  <div class="container header-inner">
    <a class="brand" href="index.php">
      <img src="<?= e(asset('assets/img/icon-192.png')) ?>" alt="" width="32" height="32">
      <span><?= e(SITE_NAME) ?></span>
    </a>
    <nav class="site-nav" aria-label="主导航">
      <?php foreach (NAV_ITEMS as $file => $label): ?>
        <a href="<?= e($file) ?>"<?= current_page() === $file ? ' aria-current="page"' : '' ?>><?= e($label) ?></a>
      <?php endforeach; ?>
      <a href="<?= e(GITHUB_URL) ?>" target="_blank" rel="noopener" class="nav-github" aria-label="GitHub">
        <svg viewBox="0 0 16 16" width="20" height="20" aria-hidden="true"><path fill="currentColor" d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0 0 16 8c0-4.42-3.58-8-8-8z"/></svg>
      </a>
    </nav>
  </div>
</header>
<main id="main">
