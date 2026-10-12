<?php
/**
 * 在线体验：一台可操作的「手机」，界面和交互还原 App 的浏览、标记、确认、删除流程。
 * 由 assets/js/sim.js 驱动；照片数据来自 config.php 的 DEMO_PHOTOS。
 *
 * 可选变量：$sim_controls = true 时在手机下方显示键盘/按钮操作区。
 */
declare(strict_types=1);
require_once __DIR__ . '/config.php';
$sim_controls = $sim_controls ?? true;
?>
<div class="sim-wrap">
  <div class="phone" aria-label="图库清道夫在线体验">
    <div class="phone-screen sim" data-photos="<?= e(demo_photos_json()) ?>" tabindex="0">
      <div class="sim-island" aria-hidden="true"></div>
      <noscript><p class="sim-noscript">在线体验需要开启 JavaScript。</p></noscript>
    </div>
  </div>
  <?php if ($sim_controls): ?>
  <div class="sim-controls" aria-label="体验操作">
    <button type="button" data-sim="prev" title="上一张（←）"><span aria-hidden="true">←</span>上一张</button>
    <button type="button" data-sim="mark" class="danger" title="标记删除（↑）"><span aria-hidden="true">↑</span>标记</button>
    <button type="button" data-sim="unmark" title="取消标记（↓）"><span aria-hidden="true">↓</span>取消</button>
    <button type="button" data-sim="next" title="下一张（→）"><span aria-hidden="true">→</span>下一张</button>
  </div>
  <p class="sim-tip">用鼠标或手指在手机屏幕上拖动，或者使用键盘方向键。演示照片均为插画，删除不会影响你的设备。</p>
  <?php endif; ?>
</div>
