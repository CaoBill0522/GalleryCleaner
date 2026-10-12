<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/config.php';

$page_title = '使用指南';
$page_description = '图库清道夫使用指南：授权、手势操作、标记与撤销、确认删除、找回误删、按月清理、视频与实况照片、设置说明。';
$page_scripts = ['assets/js/guide.js'];

function shot(string $file, string $alt): string
{
    return '<div class="guide-shot"><img src="' . e(asset("assets/img/screens/$file.jpg")) . '" alt="' . e($alt) . '" loading="lazy" width="640" height="1391"></div>';
}

$toc = [
    'start' => '开始使用',
    'browse' => '浏览与手势',
    'mark' => '标记与撤销',
    'review' => '确认删除',
    'restore' => '找回误删',
    'months' => '按月清理',
    'media' => '视频与实况照片',
    'settings' => '设置说明',
    'tips' => '清理小技巧',
];

require __DIR__ . '/includes/header.php';
?>
<div class="container doc-hero">
  <h1>使用指南</h1>
  <p>五分钟掌握图库清道夫。想先上手试试？去 <a href="demo.php">在线体验</a>。</p>
</div>

<div class="container doc-layout">
  <nav class="toc" aria-label="目录">
    <p>目录</p>
    <ol>
      <?php foreach ($toc as $id => $label): ?>
        <li><a href="#<?= e($id) ?>"><?= e($label) ?></a></li>
      <?php endforeach; ?>
    </ol>
  </nav>

  <article>
    <section class="guide-section" id="start">
      <h2><span class="n">1</span>开始使用</h2>
      <div class="guide-body no-shot">
        <div class="guide-text">
          <p>第一次打开时，App 会请求访问相册。请选择 <strong>「允许完全访问」</strong>，这样才能浏览和清理全部照片。</p>
          <p>如果当时选了「选择照片」或「不允许」，可以到系统设置里修改：</p>
          <ul>
            <li><strong>iPhone：</strong>设置 → App → 图库清道夫 → 照片 → 完全访问</li>
            <li><strong>Android：</strong>设置 → 应用 → 图库清道夫 → 权限 → 照片和视频 → 始终允许全部</li>
          </ul>
          <div class="callout">图库清道夫只在手机本地读取相册，不联网、不上传。详见 <a href="privacy.php">隐私政策</a>。</div>
        </div>
      </div>
    </section>

    <section class="guide-section" id="browse">
      <h2><span class="n">2</span>浏览与手势</h2>
      <div class="guide-body">
        <div class="guide-text">
          <p>打开后直接进入浏览页，照片一张张全屏显示，默认按拍摄时间从新到旧排列。</p>
          <table class="gesture-table">
            <thead><tr><th>手势</th><th>作用</th></tr></thead>
            <tbody>
              <tr><td>左右滑动</td><td>上一张 / 下一张</td></tr>
              <tr><td>上滑</td><td>标记删除，自动跳到下一张</td></tr>
              <tr><td>下滑</td><td>取消当前照片的标记（只对已标记的照片有效）</td></tr>
              <tr><td>双指张合</td><td>放大或缩小；放大后单指拖动查看细节</td></tr>
              <tr><td>长按</td><td>播放实况照片（可在设置中改为自动播放）</td></tr>
            </tbody>
          </table>
          <p>顶部从左到右依次是：<strong>相册切换</strong>、<strong>当前位置</strong>（如 7 / 1200）、<strong>按月清理</strong>和<strong>设置</strong>。下面的细进度条显示看到了哪里，右侧是拍摄时间和文件大小。</p>
        </div>
        <?= shot('viewer', '浏览页') ?>
      </div>
    </section>

    <section class="guide-section" id="mark">
      <h2><span class="n">3</span>标记与撤销</h2>
      <div class="guide-body">
        <div class="guide-text">
          <p>遇到不想要的照片，<strong>往上滑</strong>。手指拖动时屏幕上方会出现红色的垃圾桶和进度圈，圈满后松手就会标记，手机会轻震一下。</p>
          <p>标记 <strong>不会立刻删除</strong>，照片只是被放进「待删除」列表。已标记的照片会带上红色遮罩和「已标记删除 · 下滑取消」的提示。</p>
          <ul>
            <li>标记错了？在这张照片上 <strong>往下滑</strong> 就能取消。</li>
            <li>或者点底部左边的 <strong>撤销按钮</strong>，撤回上一步，App 会自动跳回那张照片。</li>
            <li>底部中间的数字是当前待删除的数量。</li>
          </ul>
          <div class="callout">标记会自动保存。中途退出 App，下次打开时标记和浏览进度都还在。</div>
        </div>
        <?= shot('swipe-up', '上滑标记') ?>
      </div>
    </section>

    <section class="guide-section" id="review">
      <h2><span class="n">4</span>确认删除</h2>
      <div class="guide-body">
        <div class="guide-text">
          <p>浏览完后点右下角的 <strong>「完成」</strong>，进入确认页：</p>
          <ol>
            <li>顶部显示将删除多少项、能释放多少空间。</li>
            <li>下方宫格列出全部待删除的照片。点照片可以看大图，大图里同样支持双指缩放和播放视频。</li>
            <li>想保留某一张，点它右上角的 <strong>红色圆圈</strong>，照片变灰并显示「保留」。</li>
            <li>确认无误后点 <strong>「删除 N 项」</strong>，再在弹窗中确认。</li>
            <li>系统还会弹出一次删除确认（iPhone 上是系统对话框），点「删除」完成。</li>
          </ol>
          <p>如果不想要 App 自己的那一层确认，可以在设置里关闭「删除前确认」，系统的确认仍然会保留。</p>
        </div>
        <?= shot('review', '确认删除页') ?>
      </div>
    </section>

    <section class="guide-section" id="restore">
      <h2><span class="n">5</span>找回误删</h2>
      <div class="guide-body no-shot">
        <div class="guide-text">
          <p>图库清道夫不会直接抹掉照片，而是交给系统删除：</p>
          <ul>
            <li><strong>iPhone：</strong>照片进入系统「照片」App 的 <strong>「最近删除」</strong>（在「相簿」的「实用工具」分组下），保留 30 天。打开后选中照片，点「恢复」即可。</li>
            <li><strong>Android 11 及以上：</strong>照片进入系统 <strong>回收站</strong>，一般保留 30 天。在系统相册或 Google 相册的「回收站」中恢复，不同品牌入口略有不同。</li>
          </ul>
          <div class="callout red"><strong>Android 10 及以下</strong> 没有系统回收站，删除后无法恢复，请在确认页仔细核对。</div>
          <p>另外，照片待在「最近删除」或回收站里时仍然占用空间。想马上腾出空间，需要在系统相册里清空它们。</p>
        </div>
      </div>
    </section>

    <section class="guide-section" id="months">
      <h2><span class="n">6</span>按月清理</h2>
      <div class="guide-body">
        <div class="guide-text">
          <p>照片太多不知道从哪开始？点顶部的 <strong>日历按钮</strong>，打开按月清理：</p>
          <ul>
            <li>按年份列出每个月，有照片的月份显示当月封面和数量，空的月份变灰。</li>
            <li>点某个月，就只浏览和清理这个月的照片。</li>
            <li>按月模式下，日历按钮变红，进度条下方会出现月份标签，点标签上的 × 回到全部时间。</li>
          </ul>
          <p>每个月的浏览进度会单独记住。比如先清理旅行那个月，改天再接着清理别的月份。</p>
        </div>
        <?= shot('months', '按月清理') ?>
      </div>
    </section>

    <section class="guide-section" id="media">
      <h2><span class="n">7</span>视频与实况照片</h2>
      <div class="guide-body">
        <div class="guide-text">
          <p><strong>视频</strong>在当前页直接播放，点中间的播放按钮开始。底部控制条包括：</p>
          <ul>
            <li>播放 / 暂停、当前时间和总时长</li>
            <li><strong>精细拖动：</strong>按住进度条后，手指往上移，拖动会逐级变慢（半速、四分之一速、精细），方便找到想看的那一帧</li>
            <li><strong>倍速：</strong>点「1×」在 0.5× / 1× / 1.25× / 1.5× / 2× 之间切换</li>
            <li><strong>静音：</strong>点喇叭图标切换，App 会记住你的选择</li>
          </ul>
          <p><strong>实况照片</strong>（iPhone）左上角带「实况」标记，默认长按播放，也可以在设置里改为翻到时自动播放一次。</p>
        </div>
        <?= shot('video', '视频播放') ?>
      </div>
    </section>

    <section class="guide-section" id="settings">
      <h2><span class="n">8</span>设置说明</h2>
      <div class="guide-body">
        <div class="guide-text">
          <p>点顶部右侧的齿轮进入设置：</p>
          <ul>
            <li><strong>排序方式：</strong>按拍摄时间从新到旧，或从旧到新</li>
            <li><strong>显示内容：</strong>照片和视频 / 仅照片 / 仅视频</li>
            <li><strong>显示日期和大小：</strong>浏览时是否显示拍摄时间和文件大小</li>
            <li><strong>视频自动播放、实况照片、静音播放：</strong>视频和实况的播放方式</li>
            <li><strong>震动反馈：</strong>滑动、标记时的轻震</li>
            <li><strong>删除前确认：</strong>是否显示 App 自己的删除确认弹窗</li>
            <li><strong>清除所有标记、重置浏览进度：</strong>重新开始整理时使用，不会影响照片本身</li>
          </ul>
        </div>
        <?= shot('settings', '设置页') ?>
      </div>
    </section>

    <section class="guide-section" id="tips">
      <h2><span class="n">9</span>清理小技巧</h2>
      <div class="guide-body no-shot">
        <div class="guide-text">
          <ul>
            <li><strong>先清截图：</strong>截图通常是最容易删、数量最多的。在相册切换里选「截屏」，几分钟就能清掉一大批。</li>
            <li><strong>再清视频：</strong>设置里切到「仅视频」，按大小判断，视频往往最占空间。</li>
            <li><strong>连拍只留一张：</strong>连续几张相似的照片，放大对比后只留最清楚的那张。</li>
            <li><strong>按月慢慢来：</strong>用按月清理，每天清一个月，不知不觉就整理完了。</li>
            <li><strong>宁可多留：</strong>拿不准的先跳过，下次再看。</li>
          </ul>
        </div>
      </div>
    </section>
  </article>
</div>
<?php require __DIR__ . '/includes/footer.php'; ?>
