document.getElementById('script-status').textContent = '✓ 外置 JavaScript 已执行，外置 CSS 与图片已加载。';
let count = 0;
document.getElementById('counter').addEventListener('click', event => {
  event.currentTarget.textContent = `点击计数：${++count}`;
});
setTimeout(() => {
  document.getElementById('async-content').innerHTML = '<strong>异步内容已就绪</strong><br>这一块由 JavaScript 在页面打开后生成。Finder 的页面快照也会跟随更新。';
}, 1800);
