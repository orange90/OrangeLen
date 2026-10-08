import {exportToSvg, restoreElements} from '@excalidraw/excalidraw';

window.orangeRender = async (_kind, source) => {
  const scene = JSON.parse(source);
  const elements = restoreElements(scene.elements, null, {repairBindings: true});
  if (!elements.length) {
    document.getElementById('output').textContent = '空白画布';
    return {width: 400, height: 200};
  }
  const svg = await exportToSvg({
    elements, files: scene.files, exportPadding: 24,
    appState: {viewBackgroundColor: scene.background, exportBackground: true, exportWithDarkMode: false, exportEmbedScene: false},
    renderEmbeddables: false, skipInliningFonts: true,
  });
  // Static drawing only: no links, foreign content or event handlers survive.
  svg.querySelectorAll('foreignObject,script,iframe,style').forEach(node => node.remove());
  svg.querySelectorAll('a').forEach(node => node.replaceWith(...node.childNodes));
  for (const node of svg.querySelectorAll('*')) {
    for (const attr of [...node.attributes]) {
      if (/^on/i.test(attr.name) || ((attr.localName === 'href') && !/^(#|data:image\/png;base64,)/.test(attr.value))) node.removeAttributeNode(attr);
    }
  }
  const box = svg.viewBox.baseVal;
  if (![box.width, box.height].every(v => Number.isFinite(v) && v > 0 && v <= 2000000)) throw new Error('画布尺寸超出预算');
  const scale = Math.min(1, 800 / box.width, 1500 / box.height);
  const width = Math.max(1, Math.ceil(box.width * scale));
  const height = Math.max(1, Math.ceil(box.height * scale));
  svg.setAttribute('width', width); svg.setAttribute('height', height);
  document.getElementById('output').replaceChildren(svg);
  await document.fonts.ready;
  await Promise.all([...svg.querySelectorAll('image')].map(node => new Promise(resolve => {
    const image = new Image(); image.onload = image.onerror = resolve;
    image.src = node.getAttribute('href') || node.getAttribute('xlink:href') || '';
    if (!image.src || image.complete) resolve();
  })));

  return {width, height};
};
