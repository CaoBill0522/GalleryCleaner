// 使用指南：滚动时高亮目录中当前所在的章节。
(() => {
  const links = [...document.querySelectorAll('.toc a')];
  const sections = links.map((a) => document.querySelector(a.getAttribute('href'))).filter(Boolean);
  if (!sections.length) return;
  const setActive = (id) => links.forEach((a) => a.classList.toggle('active', a.getAttribute('href') === `#${id}`));
  const observer = new IntersectionObserver(
    (entries) => {
      const visible = entries.filter((e) => e.isIntersecting).sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top);
      if (visible[0]) setActive(visible[0].target.id);
    },
    { rootMargin: '-80px 0px -60% 0px' },
  );
  sections.forEach((s) => observer.observe(s));
})();
