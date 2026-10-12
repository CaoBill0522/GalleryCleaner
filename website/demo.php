<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/config.php';

$page_title = '在线体验';
$page_description = '在浏览器里体验图库清道夫：左右切换、上滑标记、确认后删除。使用演示照片，不会影响你的设备。';
$page_scripts = ['assets/js/sim.js'];

require __DIR__ . '/includes/header.php';
?>
<div class="container demo-page">
  <div class="demo-side">
    <h1>在线体验</h1>
    <p>这是一台「网页里的手机」，界面和操作都和 App 一样。里面有 16 张演示照片，混着连拍重复、拍糊了、聊天截图这些「废片」，试着把它们清理掉。</p>
    <ul>
      <li><span class="kbd">↑</span>上滑：标记删除，自动跳到下一张</li>
      <li><span class="kbd">↓</span>下滑：取消已标记的照片</li>
      <li><span class="kbd">← →</span>左右滑：切换照片</li>
      <li><span class="kbd">⌘Z</span>或底部撤销按钮：撤回上一步</li>
    </ul>
  </div>

  <?php $sim_controls = true; require __DIR__ . '/includes/simulator.php'; ?>

  <div class="demo-side right">
    <ul>
      <li><strong>1.</strong> 把不想要的照片都上滑标记</li>
      <li><strong>2.</strong> 点右下角「完成」进入确认页</li>
      <li><strong>3.</strong> 想保留的点右上角圆圈取消勾选</li>
      <li><strong>4.</strong> 点「删除」，看看能释放多少空间</li>
    </ul>
    <p style="margin-top:24px">真实 App 里还有按月清理、视频播放、实况照片和双指缩放。<a href="guide.php">查看使用指南</a></p>
  </div>
</div>
<?php require __DIR__ . '/includes/footer.php'; ?>
