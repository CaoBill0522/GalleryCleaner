<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/config.php';

http_response_code(404);
$page_title = '页面不存在';

require __DIR__ . '/includes/header.php';
?>
<div class="container doc-hero" style="text-align:center;padding:120px 0">
  <h1>这一页被清理掉了</h1>
  <p>你要找的页面不存在。</p>
  <p style="margin-top:32px"><a class="btn btn-white" href="index.php">回到首页</a></p>
</div>
<?php require __DIR__ . '/includes/footer.php'; ?>
