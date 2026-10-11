<?php declare(strict_types=1); ?>
</main>
<footer class="site-footer">
  <div class="container footer-inner">
    <div class="footer-brand">
      <img src="<?= e(asset('assets/img/icon-192.png')) ?>" alt="" width="40" height="40">
      <div>
        <strong><?= e(SITE_NAME) ?></strong>
        <span><?= e(SITE_NAME_EN) ?> · v<?= e(APP_VERSION) ?></span>
      </div>
    </div>
    <nav class="footer-links" aria-label="页脚导航">
      <a href="guide.php">使用指南</a>
      <a href="demo.php">在线体验</a>
      <a href="privacy.php">隐私政策</a>
      <a href="terms.php">用户协议</a>
      <a href="<?= e(GITHUB_URL) ?>" target="_blank" rel="noopener">GitHub</a>
    </nav>
    <p class="footer-note">
      © <?= date('Y') ?> JIACHENG CAO · 基于 <a href="<?= e(GITHUB_URL) ?>/blob/main/LICENSE" target="_blank" rel="noopener">GPL-3.0</a> 开源 · 完全离线，不收集任何数据
    </p>
  </div>
</footer>
<?php if (!empty($page_scripts)): foreach ($page_scripts as $src): ?>
<script src="<?= e(asset($src)) ?>" defer></script>
<?php endforeach; endif; ?>
</body>
</html>
