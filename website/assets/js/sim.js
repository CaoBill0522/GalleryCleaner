/*
 * 图库清道夫 · 在线体验
 * 在网页里还原 App 的核心流程：左右切换、上滑标记、下滑取消、撤销、确认页、删除、完成页。
 * 页面上每个 .sim 元素都会变成一台可操作的「手机」。
 */
(() => {
  'use strict';

  const ICONS = {
    album: '<rect x="3" y="3" width="18" height="18" rx="3"/><circle cx="9" cy="9" r="2"/><path d="m21 15-5-5L5 21"/>',
    chevron: '<path d="m6 9 6 6 6-6"/>',
    back: '<path d="m15 18-6-6 6-6"/>',
    calendar: '<rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18M8 14h.01M12 14h.01M16 14h.01M8 18h.01M12 18h.01M16 18h.01"/>',
    gear: '<path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/>',
    undo: '<path d="M9 14 4 9l5-5"/><path d="M4 9h10.5a5.5 5.5 0 0 1 0 11H11"/>',
    check: '<path d="M20 6 9 17l-5-5"/>',
    trash: '<path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>',
    restore: '<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/>',
    sparkle: '<path d="M12 3l1.9 5.1L19 10l-5.1 1.9L12 17l-1.9-5.1L5 10l5.1-1.9z"/><path d="M19 15l.8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8z"/>',
  };

  const icon = (name, cls = '') =>
    `<svg class="sim-ico ${cls}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICONS[name]}</svg>`;

  function fmtBytes(bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    let v = bytes;
    let u = 0;
    while (v >= 1024 && u < units.length - 1) {
      v /= 1024;
      u++;
    }
    return `${v.toFixed(u === 0 || v >= 100 ? 0 : 1)} ${units[u]}`;
  }

  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  const THRESHOLD = 0.22; // 上下滑超过屏幕高度的这个比例才生效
  const SPRING = 'cubic-bezier(.34,1.56,.64,1)';

  class Sim {
    constructor(root) {
      this.root = root;
      this.source = JSON.parse(root.dataset.photos || '[]');
      this.build();
      this.restart();
      this.bind();
    }

    // ---------- 状态 ----------

    restart() {
      this.photos = this.source.map((p, i) => ({ ...p, id: i }));
      this.index = 0;
      this.marked = new Set();
      this.undoStack = [];
      this.drag = null;
      this.busy = false;
      this.coachShown = true;
      this.el.coach.hidden = false;
      this.buildSlides();
      this.show('viewer');
      this.render();
    }

    get current() {
      return this.photos[this.index];
    }

    isMarked(p) {
      return p && this.marked.has(p.id);
    }

    // ---------- 结构 ----------

    build() {
      this.root.insertAdjacentHTML(
        'beforeend',
        `
        <div class="sim-status" aria-hidden="true"><span>9:41</span><span class="sim-battery"></span></div>
        <section class="sim-screen sim-viewer">
          <div class="sim-stage"><div class="sim-strip"></div></div>
          <div class="sim-top">
            <div class="sim-row">
              <button type="button" class="sim-pill sim-album" data-act="album">${icon('album')}<span>全部照片</span>${icon('chevron', 'sm')}</button>
              <span class="sim-pill sim-count"><b>1</b><i> / 1</i></span>
              <button type="button" class="sim-pill sim-round" data-act="calendar" aria-label="按月清理">${icon('calendar')}</button>
              <button type="button" class="sim-pill sim-round" data-act="settings" aria-label="设置">${icon('gear')}</button>
            </div>
            <div class="sim-progress"><i></i></div>
            <div class="sim-meta"><span class="sim-tag" hidden></span><span class="sim-info"></span></div>
          </div>
          <div class="sim-bottom">
            <button type="button" class="sim-undo" data-act="undo" aria-label="撤销" disabled>${icon('undo')}</button>
            <div class="sim-counter"><b>0</b><span>待删除</span></div>
            <button type="button" class="sim-finish-btn" data-act="finish">${icon('check')}<span>完成</span></button>
          </div>
          <div class="sim-coach" aria-hidden="true">
            <div class="sim-coach-hand"><i></i></div>
            <p>上滑标记删除<br><small>左右滑动切换照片</small></p>
          </div>
        </section>

        <section class="sim-screen sim-review" hidden>
          <header class="sim-head">
            <button type="button" class="sim-back" data-act="back" aria-label="返回">${icon('back')}</button>
            <h3>确认删除</h3>
            <button type="button" class="sim-link" data-act="toggleAll">全部保留</button>
          </header>
          <div class="sim-scroll">
            <div class="sim-summary">
              <div><small>将删除</small><p><b class="sim-sum-n">0</b> 项</p></div>
              <div class="right"><small>可释放</small><p><b class="sim-sum-size">0 B</b></p></div>
              <em>删除后会进入「最近删除」，30 天内可以找回</em>
            </div>
            <p class="sim-note">点照片右上角的圆圈，可以保留这张</p>
            <div class="sim-grid"></div>
          </div>
          <div class="sim-foot"><button type="button" class="sim-btn red" data-act="delete">${icon('trash')}<span>删除</span></button></div>
        </section>

        <section class="sim-screen sim-done" hidden>
          <svg class="sim-done-check" viewBox="0 0 120 120" aria-hidden="true">
            <circle cx="60" cy="60" r="44" />
            <path d="M40 61 L54 75 L82 46" />
          </svg>
          <h3>清理完成</h3>
          <div class="sim-stats">
            <div><p><b class="sim-done-n">0</b> 项</p><small>删除</small></div>
            <div><p><b class="sim-done-size">0</b> <span class="sim-done-unit">MB</span></p><small>释放空间</small></div>
          </div>
          <p class="sim-done-note">这只是演示，你的设备没有任何改动</p>
          <button type="button" class="sim-btn white" data-act="continue">${icon('sparkle')}<span>继续清理</span></button>
          <button type="button" class="sim-link" data-act="restart">重新开始体验</button>
        </section>

        <div class="sim-modal" hidden>
          <div class="sim-dialog" role="dialog" aria-modal="true" aria-label="确认删除">
            <div class="sim-dialog-icon">${icon('trash')}</div>
            <h4>删除 <span class="sim-dlg-n">0</span> 项？</h4>
            <p>预计释放 <span class="sim-dlg-size">0 B</span><br>30 天内可在「最近删除」中恢复</p>
            <div class="sim-dialog-actions">
              <button type="button" class="sim-btn grey" data-act="cancelDelete">再看看</button>
              <button type="button" class="sim-btn red" data-act="confirmDelete">删除</button>
            </div>
          </div>
        </div>
        <div class="sim-toast" role="status" aria-live="polite"></div>
        `,
      );
      const $ = (s) => this.root.querySelector(s);
      this.el = {
        viewer: $('.sim-viewer'),
        review: $('.sim-review'),
        done: $('.sim-done'),
        stage: $('.sim-stage'),
        strip: $('.sim-strip'),
        count: $('.sim-count'),
        progress: $('.sim-progress i'),
        info: $('.sim-info'),
        tag: $('.sim-tag'),
        undo: $('.sim-undo'),
        counter: $('.sim-counter'),
        counterNum: $('.sim-counter b'),
        finish: $('.sim-finish-btn'),
        coach: $('.sim-coach'),
        grid: $('.sim-grid'),
        sumN: $('.sim-sum-n'),
        sumSize: $('.sim-sum-size'),
        toggleAll: $('[data-act="toggleAll"]'),
        deleteBtn: $('.sim-foot .sim-btn'),
        modal: $('.sim-modal'),
        dlgN: $('.sim-dlg-n'),
        dlgSize: $('.sim-dlg-size'),
        doneN: $('.sim-done-n'),
        doneSize: $('.sim-done-size'),
        doneUnit: $('.sim-done-unit'),
        toast: $('.sim-toast'),
      };
    }

    buildSlides() {
      this.el.strip.innerHTML = this.photos
        .map(
          (p, i) => `
          <div class="sim-slide" style="left:${i * 100}%" data-i="${i}">
            <div class="sim-card"><img alt="演示照片 ${i + 1}" draggable="false"><div class="sim-tint"></div></div>
            <div class="sim-hint" aria-hidden="true">
              <div class="sim-hint-ring"><svg viewBox="0 0 40 40"><circle cx="20" cy="20" r="18"/></svg>${icon('trash', 'del')}${icon('restore', 'res')}</div>
              <span></span>
            </div>
            <div class="sim-badge" aria-hidden="true">${icon('trash')}已标记删除 · 下滑取消</div>
          </div>`,
        )
        .join('');
      this.slides = [...this.el.strip.children];
    }

    slideOf(i) {
      return this.slides[i];
    }

    // ---------- 渲染 ----------

    show(name) {
      for (const k of ['viewer', 'review', 'done']) this.el[k].hidden = k !== name;
      this.screen = name;
    }

    render() {
      const n = this.photos.length;
      if (n === 0) return;
      this.index = Math.max(0, Math.min(this.index, n - 1));
      this.setStrip(0, true);

      // 只给附近几张设置图片地址，减少流量
      this.slides.forEach((s, i) => {
        const img = s.querySelector('img');
        if (Math.abs(i - this.index) <= 2 && !img.src) img.src = this.photos[i].src;
        s.classList.toggle('is-marked', this.isMarked(this.photos[i]));
      });

      const p = this.current;
      this.el.count.innerHTML = `<b>${this.index + 1}</b><i> / ${n}</i>`;
      this.el.progress.style.width = `${((this.index + 1) / n) * 100}%`;
      this.el.info.textContent = `${p.date} · ${fmtBytes(p.size)}`;
      this.el.tag.hidden = !p.tag;
      this.el.tag.textContent = p.tag ? `可能是：${p.tag}` : '';

      const count = this.marked.size;
      if (this.el.counterNum.textContent !== String(count)) {
        this.el.counterNum.textContent = count;
        this.bump(this.el.counter);
      }
      this.el.counter.classList.toggle('has', count > 0);
      this.el.finish.classList.toggle('red', count > 0);
      this.el.undo.disabled = this.undoStack.length === 0;
    }

    setStrip(dx, animate) {
      const s = this.el.strip;
      s.style.transition = animate && !reduceMotion ? 'transform .32s cubic-bezier(.2,.8,.2,1)' : 'none';
      s.style.transform = `translateX(calc(${-this.index * 100}% + ${dx}px))`;
    }

    setCard(i, dy, animate, curve = 'cubic-bezier(.2,.8,.2,1)', dur = 0.32) {
      const slide = this.slideOf(i);
      if (!slide) return;
      const card = slide.querySelector('.sim-card');
      const h = this.el.stage.clientHeight || 1;
      const t = Math.min(Math.abs(dy) / h, 1);
      const scale = 1 - (dy < 0 ? 0.32 : 0.12) * t;
      const opacity = dy < 0 ? Math.max(0, 1 - Math.max(0, t - 0.25) * 1.2) : 1;
      card.style.transition = animate && !reduceMotion ? `transform ${dur}s ${curve}, opacity ${dur}s ease` : 'none';
      card.style.transform = `translateY(${dy}px) rotate(${(dy / h) * 8}deg) scale(${scale})`;
      card.style.opacity = opacity;
      this.setHint(slide, dy);
    }

    setHint(slide, dy) {
      const marked = slide.classList.contains('is-marked');
      const hint = slide.querySelector('.sim-hint');
      const deleting = !marked && dy < 0;
      const restoring = marked && dy > 0;
      const h = this.el.stage.clientHeight || 1;
      const progress = Math.min(Math.abs(dy) / (h * THRESHOLD), 1);
      slide.classList.toggle('dragging', Math.abs(dy) > 1);
      if (!deleting && !restoring) {
        hint.style.opacity = 0;
        slide.style.setProperty('--wash', 0);
        return;
      }
      const ready = progress >= 1;
      hint.classList.toggle('del', deleting);
      hint.classList.toggle('ready', ready);
      hint.style.opacity = Math.min(progress * 1.6, 1);
      hint.style.setProperty('--p', progress);
      hint.querySelector('span').textContent = deleting
        ? ready ? '松手标记删除' : '继续上滑'
        : ready ? '松手取消标记' : '继续下滑';
      slide.style.setProperty('--wash', progress);
      slide.classList.toggle('washing-del', deleting);
      if (ready && !this.drag?.ready) this.vibrate(8);
      if (this.drag) this.drag.ready = ready;
    }

    bump(el) {
      el.classList.remove('bump');
      void el.offsetWidth;
      el.classList.add('bump');
    }

    toast(text) {
      const t = this.el.toast;
      t.textContent = text;
      t.classList.add('show');
      clearTimeout(this.toastTimer);
      this.toastTimer = setTimeout(() => t.classList.remove('show'), 1800);
    }

    vibrate(ms) {
      if (navigator.vibrate) navigator.vibrate(ms);
    }

    hideCoach() {
      if (!this.coachShown) return;
      this.coachShown = false;
      this.el.coach.classList.add('out');
      setTimeout(() => (this.el.coach.hidden = true), 300);
    }

    // ---------- 操作 ----------

    go(i) {
      const n = this.photos.length;
      if (i < 0) {
        this.toast('已经是第一张了');
        i = 0;
      } else if (i > n - 1) {
        this.toast('已经是最后一张了');
        i = n - 1;
      }
      const old = this.index;
      this.index = i;
      this.render();
      // 翻页动画结束后，把离开的那张复位
      if (old !== i) setTimeout(() => this.setCard(old, 0, false), 360);
    }

    mark() {
      const p = this.current;
      if (!p || this.isMarked(p) || this.busy) return;
      this.hideCoach();
      this.marked.add(p.id);
      this.undoStack.push({ id: p.id, marked: true });
      this.vibrate(15);
      const i = this.index;
      const h = this.el.stage.clientHeight;
      this.busy = true;
      this.setCard(i, -h * 1.05, true, 'cubic-bezier(.5,0,.75,0)', 0.28);
      setTimeout(() => {
        this.busy = false;
        if (i < this.photos.length - 1) {
          this.go(i + 1);
          if (this.queuedMark) {
            this.queuedMark = false;
            this.command('mark');
          }
        } else {
          this.queuedMark = false;
          this.render();
          this.setCard(i, 0, true, SPRING, 0.45);
          this.toast('已经是最后一张了，点「完成」去确认');
        }
      }, reduceMotion ? 0 : 230);
    }

    unmark() {
      const p = this.current;
      if (!p || !this.isMarked(p)) return;
      this.marked.delete(p.id);
      this.undoStack.push({ id: p.id, marked: false });
      this.vibrate(10);
      this.render();
      this.setCard(this.index, 0, true, SPRING, 0.45);
    }

    undo() {
      const last = this.undoStack.pop();
      if (!last) return;
      if (last.marked) this.marked.delete(last.id);
      else this.marked.add(last.id);
      const i = this.photos.findIndex((p) => p.id === last.id);
      if (i >= 0) {
        this.index = i;
        this.render();
        this.setCard(i, 0, true, SPRING, 0.45);
      } else {
        this.render();
      }
    }

    // ---------- 手势 ----------

    onDown(e) {
      if (this.screen !== 'viewer' || this.busy || e.button > 0) return;
      this.hideCoach();
      this.drag = {
        x: e.clientX, y: e.clientY, axis: null, dx: 0, dy: 0,
        lx: e.clientX, ly: e.clientY, lt: performance.now(), vx: 0, vy: 0, ready: false,
      };
      this.el.stage.setPointerCapture(e.pointerId);
    }

    onMove(e) {
      const d = this.drag;
      if (!d) return;
      const now = performance.now();
      const dt = Math.max(now - d.lt, 1);
      d.vx = (e.clientX - d.lx) / dt;
      d.vy = (e.clientY - d.ly) / dt;
      d.lx = e.clientX;
      d.ly = e.clientY;
      d.lt = now;
      d.dx = e.clientX - d.x;
      d.dy = e.clientY - d.y;
      if (!d.axis) {
        if (Math.hypot(d.dx, d.dy) < 8) return;
        d.axis = Math.abs(d.dx) > Math.abs(d.dy) ? 'x' : 'y';
      }
      e.preventDefault();
      if (d.axis === 'x') {
        const atEdge = (this.index === 0 && d.dx > 0) || (this.index === this.photos.length - 1 && d.dx < 0);
        this.setStrip(atEdge ? d.dx * 0.3 : d.dx, false);
      } else {
        const marked = this.isMarked(this.current);
        const allowed = marked ? d.dy > 0 : d.dy < 0;
        this.setCard(this.index, allowed ? d.dy : d.dy * 0.25, false);
      }
    }

    onUp() {
      const d = this.drag;
      this.drag = null;
      if (!d || !d.axis) return;
      const w = this.el.stage.clientWidth;
      const h = this.el.stage.clientHeight;
      if (d.axis === 'x') {
        if (d.dx < -w * 0.2 || (d.vx < -0.5 && d.dx < -20)) this.go(this.index + 1);
        else if (d.dx > w * 0.2 || (d.vx > 0.5 && d.dx > 20)) this.go(this.index - 1);
        else this.setStrip(0, true);
        return;
      }
      const marked = this.isMarked(this.current);
      const far = h * THRESHOLD;
      if (!marked && d.dy < 0 && (d.dy < -far || d.vy < -0.7)) {
        this.mark();
      } else if (marked && d.dy > 0 && (d.dy > far || d.vy > 0.7)) {
        this.unmark();
      } else {
        this.setCard(this.index, 0, true, SPRING, 0.45);
      }
    }

    // ---------- 确认页 ----------

    openReview() {
      if (this.marked.size === 0) {
        this.toast('还没有标记，上滑即可标记');
        return;
      }
      this.reviewItems = this.photos.filter((p) => this.marked.has(p.id));
      this.el.grid.innerHTML = this.reviewItems
        .map(
          (p, k) => `
          <button type="button" class="sim-tile" data-id="${p.id}" style="--k:${k}" aria-pressed="true" aria-label="照片 ${k + 1}，点按切换保留">
            <img src="${p.src}" alt="" draggable="false">
            <span class="sim-keep">保留</span>
            <span class="sim-check">${icon('check')}</span>
          </button>`,
        )
        .join('');
      this.show('review');
      this.el.review.querySelector('.sim-scroll').scrollTop = 0;
      this.renderReview();
    }

    renderReview() {
      const selected = this.reviewItems.filter((p) => this.marked.has(p.id));
      const bytes = selected.reduce((s, p) => s + p.size, 0);
      this.el.sumN.textContent = selected.length;
      this.el.sumSize.textContent = fmtBytes(bytes);
      this.el.toggleAll.textContent = selected.length === this.reviewItems.length ? '全部保留' : '全选';
      this.el.deleteBtn.disabled = selected.length === 0;
      this.el.deleteBtn.querySelector('span').textContent =
        selected.length === 0 ? '没有选中要删除的照片' : `删除 ${selected.length} 项`;
      for (const tile of this.el.grid.children) {
        const on = this.marked.has(Number(tile.dataset.id));
        tile.classList.toggle('off', !on);
        tile.setAttribute('aria-pressed', String(on));
      }
      this.pending = { selected, bytes };
    }

    toggleTile(id) {
      if (this.marked.has(id)) this.marked.delete(id);
      else this.marked.add(id);
      this.undoStack = [];
      this.vibrate(8);
      this.renderReview();
    }

    toggleAll() {
      const all = this.reviewItems.every((p) => this.marked.has(p.id));
      for (const p of this.reviewItems) all ? this.marked.delete(p.id) : this.marked.add(p.id);
      this.renderReview();
    }

    askDelete() {
      const { selected, bytes } = this.pending;
      if (!selected.length) return;
      this.el.dlgN.textContent = selected.length;
      this.el.dlgSize.textContent = fmtBytes(bytes);
      this.el.modal.hidden = false;
      requestAnimationFrame(() => this.el.modal.classList.add('open'));
    }

    closeModal() {
      this.el.modal.classList.remove('open');
      setTimeout(() => (this.el.modal.hidden = true), 200);
    }

    doDelete() {
      const { selected, bytes } = this.pending;
      this.closeModal();
      const gone = new Set(selected.map((p) => p.id));
      this.photos = this.photos.filter((p) => !gone.has(p.id));
      for (const id of gone) this.marked.delete(id);
      this.undoStack = [];
      this.vibrate([10, 40, 20]);
      this.showDone(selected.length, bytes);
    }

    showDone(count, bytes) {
      this.show('done');
      const done = this.el.done;
      done.classList.remove('play');
      void done.offsetWidth;
      done.classList.add('play');
      const [num, unit] = fmtBytes(bytes).split(' ');
      this.el.doneUnit.textContent = unit;
      this.countUp(this.el.doneN, count, 0);
      this.countUp(this.el.doneSize, Number(num), num.includes('.') ? 1 : 0);
    }

    countUp(el, target, digits) {
      const start = performance.now();
      const dur = reduceMotion ? 0 : 1000;
      const delay = reduceMotion ? 0 : 550;
      const step = (now) => {
        const t = Math.min(Math.max((now - start - delay) / (dur || 1), 0), 1);
        const eased = 1 - Math.pow(1 - t, 3);
        el.textContent = (target * eased).toFixed(digits);
        if (t < 1) requestAnimationFrame(step);
      };
      requestAnimationFrame(step);
    }

    continueCleaning() {
      if (this.photos.length === 0) {
        this.restart();
        this.toast('照片都清理完了，已重新开始');
        return;
      }
      this.buildSlides();
      this.show('viewer');
      this.render();
    }

    // ---------- 事件 ----------

    bind() {
      const stage = this.el.stage;
      stage.addEventListener('pointerdown', (e) => this.onDown(e));
      stage.addEventListener('pointermove', (e) => this.onMove(e));
      stage.addEventListener('pointerup', () => this.onUp());
      stage.addEventListener('pointercancel', () => this.onUp());
      stage.addEventListener('lostpointercapture', () => this.onUp());

      this.root.addEventListener('click', (e) => {
        const tile = e.target.closest('.sim-tile');
        if (tile) return this.toggleTile(Number(tile.dataset.id));
        const btn = e.target.closest('[data-act]');
        if (!btn) return;
        const act = btn.dataset.act;
        const actions = {
          undo: () => this.undo(),
          finish: () => this.openReview(),
          back: () => {
            this.show('viewer');
            this.render();
          },
          toggleAll: () => this.toggleAll(),
          delete: () => this.askDelete(),
          cancelDelete: () => this.closeModal(),
          confirmDelete: () => this.doDelete(),
          continue: () => this.continueCleaning(),
          restart: () => this.restart(),
          album: () => this.toast('相册切换请在 App 中体验'),
          calendar: () => this.toast('按月清理请在 App 中体验'),
          settings: () => this.toast('设置页请在 App 中体验'),
        };
        actions[act]?.();
      });

      this.root.addEventListener('keydown', (e) => this.onKey(e));
    }

    onKey(e) {
      if (this.screen !== 'viewer') return false;
      const map = {
        ArrowLeft: () => this.go(this.index - 1),
        ArrowRight: () => this.go(this.index + 1),
        ArrowUp: () => this.command('mark'),
        ArrowDown: () => this.command('unmark'),
      };
      if ((e.key === 'z' || e.key === 'Z') && (e.metaKey || e.ctrlKey)) {
        e.preventDefault();
        this.undo();
        return true;
      }
      const fn = map[e.key];
      if (!fn) return false;
      e.preventDefault();
      this.hideCoach();
      fn();
      return true;
    }

    /** 页面上的按钮/键盘指令 */
    command(name) {
      if (this.screen !== 'viewer') {
        this.toast('请先返回浏览页');
        return;
      }
      this.hideCoach();
      switch (name) {
        case 'prev': return this.go(this.index - 1);
        case 'next': return this.go(this.index + 1);
        case 'mark':
          // 上一张还在飞出时按下，等翻到下一张再标记
          if (this.busy) return void (this.queuedMark = true);
          if (this.isMarked(this.current)) return this.toast('这张已经标记了，下滑可以取消');
          return this.mark();
        case 'unmark':
          if (!this.isMarked(this.current)) return this.toast('这张还没有标记');
          return this.unmark();
      }
    }
  }

  // ---------- 启动 ----------

  const sims = [...document.querySelectorAll('.sim')].map((el) => new Sim(el));
  if (!sims.length) return;
  const primary = sims[0];

  document.querySelectorAll('[data-sim]').forEach((btn) =>
    btn.addEventListener('click', () => primary.command(btn.dataset.sim)),
  );

  // 手机在视口里时，方向键直接控制它（不抢输入框的按键）
  let visible = false;
  new IntersectionObserver(([entry]) => (visible = entry.intersectionRatio > 0.4), {
    threshold: [0, 0.4, 1],
  }).observe(primary.root);
  document.addEventListener('keydown', (e) => {
    if (!visible || e.defaultPrevented) return;
    if (e.target.closest('input, textarea, select, [contenteditable]')) return;
    if (primary.root.contains(e.target)) return; // 已在 root 上处理
    primary.onKey(e);
  });

  window.addEventListener('resize', () => sims.forEach((s) => s.screen === 'viewer' && s.render()));
})();
