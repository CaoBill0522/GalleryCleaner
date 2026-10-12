<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/config.php';
require_once __DIR__ . '/includes/icons.php';

$page_scripts = ['assets/js/sim.js'];

$features = [
    ['swipe', true, '滑动清理', '左右切换，上滑标记，下滑取消。一只手就能快速过完几千张照片。'],
    ['check-list', false, '先标记，后删除', '标记不会立刻删除。全部看完后在确认页逐张核对，留下想要的。'],
    ['shield', false, '可以找回', '删除走系统接口，照片进入「最近删除」或回收站，30 天内可以恢复。'],
    ['calendar', false, '按月清理', '日历视图统计每个月有多少张，可以只清理某一个月。'],
    ['play', false, '视频直接播放', '在当前页播放视频，支持倍速、静音和精细拖动进度条。'],
    ['live', false, '实况照片', '支持长按播放或自动播放实况，确认动态部分再决定。'],
    ['zoom', false, '双指缩放', '放大看清细节：是不是糊了、有没有闭眼，一看便知。'],
    ['resume', false, '断点续看', '标记和浏览进度保存在手机上，下次打开接着清理。'],
];

$shots = [
    ['viewer', '浏览：一次只看一张'],
    ['swipe-up', '上滑：标记要删除的'],
    ['marked', '已标记：随时下滑取消'],
    ['review', '确认：逐张核对'],
    ['confirm', '删除前再确认一次'],
    ['done', '清理完成'],
    ['months', '按月清理'],
    ['video', '视频页内播放'],
    ['settings', '设置'],
];

$faqs = [
    ['删除后还能找回吗？', 'iPhone 上删除的照片会进入系统相册的「最近删除」，30 天内可以恢复；Android 11 及以上会进入系统回收站。Android 10 及以下系统没有回收站，删除后无法恢复，请在确认页仔细核对。'],
    ['会上传我的照片吗？', '不会。图库清道夫没有任何联网功能，不包含统计、广告或第三方 SDK，所有操作都在手机本地完成。代码完全开源，可以在 GitHub 上查看。'],
    ['标记了但还没删除，退出 App 会丢吗？', '不会。标记和每个相册的浏览进度都保存在手机上，下次打开可以接着清理。'],
    ['为什么删除后手机空间没有变大？', '照片在「最近删除」或回收站里时仍然占用空间。在系统相册里清空「最近删除」或回收站后，空间才会真正释放。'],
    ['收费吗？', '完全免费，没有内购，也没有广告。'],
];

require __DIR__ . '/includes/header.php';
?>

<section class="hero">
  <div class="container hero-inner">
    <div>
      <img class="hero-logo" src="<?= e(asset('assets/img/icon-192.png')) ?>" alt="图库清道夫图标" width="84" height="84">
      <h1><?= e(SITE_NAME) ?><span><?= e(SITE_NAME_EN) ?></span></h1>
      <p class="hero-lead"><?= e(SITE_TAGLINE) ?><br>删错了也能在「最近删除」里找回。</p>
      <div class="hero-actions"><?= download_buttons() ?></div>
      <ul class="hero-points">
        <li>免费，无广告</li>
        <li>完全离线</li>
        <li>开源</li>
        <li>iPhone 与 Android</li>
      </ul>
    </div>
    <div id="demo">
      <?php $sim_controls = false; require __DIR__ . '/includes/simulator.php'; ?>
      <p class="sim-tip">↑ 这是可以直接上手的在线体验，试试在屏幕上往上滑。<a href="demo.php">全屏体验</a></p>
    </div>
  </div>
</section>

<section class="section">
  <div class="container center">
    <p class="eyebrow">三步清理</p>
    <h2 class="section-title">像刷卡片一样整理相册</h2>
    <p class="section-lead">系统相册删照片又慢又容易删错。图库清道夫把清理拆成三步：看、标记、确认。</p>
  </div>
  <div class="container steps">
    <div class="step">
      <span class="step-num">1</span>
      <h3>上滑标记</h3>
      <p>一张张浏览，不要的往上一滑，自动跳到下一张。</p>
      <div class="step-shot"><img src="<?= e(asset('assets/img/screens/swipe-up.jpg')) ?>" alt="上滑标记删除的界面" loading="lazy" width="640" height="1391"></div>
    </div>
    <div class="step">
      <span class="step-num">2</span>
      <h3>统一确认</h3>
      <p>看完点「完成」，在确认页逐张核对，想留的点一下保留。</p>
      <div class="step-shot"><img src="<?= e(asset('assets/img/screens/review.jpg')) ?>" alt="确认删除页面" loading="lazy" width="640" height="1391"></div>
    </div>
    <div class="step">
      <span class="step-num">3</span>
      <h3>批量删除</h3>
      <p>一次删除全部标记，照片进入「最近删除」，30 天内可找回。</p>
      <div class="step-shot"><img src="<?= e(asset('assets/img/screens/done.jpg')) ?>" alt="清理完成页面" loading="lazy" width="640" height="1391"></div>
    </div>
  </div>
</section>

<section class="section">
  <div class="container">
    <p class="eyebrow">功能</p>
    <h2 class="section-title">该有的都有，不该有的一个没有</h2>
    <div class="features">
      <?php foreach ($features as [$ic, $red, $title, $desc]): ?>
        <div class="feature">
          <div class="feature-icon<?= $red ? ' red' : '' ?>"><?= svg_icon($ic) ?></div>
          <h3><?= e($title) ?></h3>
          <p><?= e($desc) ?></p>
        </div>
      <?php endforeach; ?>
    </div>
  </div>
</section>

<section class="section" id="screenshots">
  <div class="container">
    <p class="eyebrow">截图</p>
    <h2 class="section-title">深色界面，专注照片本身</h2>
  </div>
  <div class="gallery" tabindex="0" aria-label="应用截图，可左右滚动">
    <?php foreach ($shots as [$file, $caption]): ?>
      <figure class="shot">
        <div class="shot-frame"><img src="<?= e(asset("assets/img/screens/$file.jpg")) ?>" alt="<?= e($caption) ?>" loading="lazy" width="640" height="1391"></div>
        <figcaption><?= e($caption) ?></figcaption>
      </figure>
    <?php endforeach; ?>
  </div>
</section>

<section class="section">
  <div class="container">
    <div class="privacy-band">
      <div class="big-icon"><?= svg_icon('lock') ?></div>
      <div>
        <h2>你的照片，只在你的手机上</h2>
        <p>图库清道夫不联网、不上传、不收集任何数据，没有账号，也没有统计和广告。代码以 GPL-3.0 开源，任何人都可以检查。<a href="privacy.php">阅读隐私政策</a></p>
      </div>
    </div>
  </div>
</section>

<section class="section">
  <div class="container center">
    <p class="eyebrow">常见问题</p>
    <h2 class="section-title">你可能想知道</h2>
  </div>
  <div class="container faq">
    <?php foreach ($faqs as [$q, $a]): ?>
      <details>
        <summary><?= e($q) ?></summary>
        <p><?= e($a) ?></p>
      </details>
    <?php endforeach; ?>
    <p style="margin-top:24px;color:var(--text-2)">更多操作说明见 <a href="guide.php">使用指南</a>。</p>
  </div>
</section>

<section class="section">
  <div class="container download-card">
    <h2 class="section-title">现在就清理一下相册</h2>
    <p class="section-lead" style="margin-inline:auto">免费下载，几分钟就能清出几个 G。</p>
    <div class="hero-actions"><?= download_buttons() ?></div>
  </div>
</section>

<?php require __DIR__ . '/includes/footer.php'; ?>
