import mermaid from 'mermaid';
import katex from 'katex';
window.orangeRender = async function(kind, source) {
  if (typeof source !== 'string' || source.length > 16384) throw Error('内容超出渲染预算');
  const target = document.getElementById('output');
  target.replaceChildren();
  if (kind === 'mermaid') {
    // No document configuration, callbacks, styling directives or external resources.
    if (/%%\s*\{|^\s*---|\b(?:click|href|callback|image|icon)\b|(?:https?:|file:|data:|javascript:)|<\/?(?:script|iframe|object|embed|img|svg|foreignObject|style|link|meta|a)\b/im.test(source)) {
      throw Error('图表含外部资源、HTML 或交互指令');
    }
    mermaid.initialize({startOnLoad:false, securityLevel:'strict', htmlLabels:false,
      maxTextSize:16384, maxEdges:150, suppressErrorRendering:true, theme:'default',
      fontFamily:'Arial', deterministicIds:true,
      flowchart:{htmlLabels:false, useMaxWidth:false}, sequence:{useMaxWidth:false},
      secure:['securityLevel','startOnLoad','maxTextSize','maxEdges','htmlLabels','themeCSS','fontFamily']});
    const result = await mermaid.render('orangeDiagram', source);
    target.innerHTML = result.svg;
    // Mermaid's strict sanitization is complemented by removing actionable elements.
    target.querySelectorAll('script,foreignObject,iframe,object,embed,image,a').forEach(n => n.remove());
    target.querySelectorAll('*').forEach(n => [...n.attributes].forEach(a => {
      if (/^on/i.test(a.name) || /href$/i.test(a.name)) n.removeAttribute(a.name);
    }));
    const svg = target.querySelector('svg');
    if (!svg) throw Error('图表没有产生图像');
    const vb = svg.viewBox.baseVal;
    if (!Number.isFinite(vb.width) || vb.width <= 0 || vb.height <= 0) throw Error('图表尺寸无效');
    const scale = Math.min(1, 760/vb.width, 1400/vb.height);
    svg.style.maxWidth='none'; svg.setAttribute('width', vb.width*scale); svg.setAttribute('height', vb.height*scale);
  } else {
    katex.render(source, target, {displayMode:kind==='displayMath', throwOnError:true,
      trust:false, strict:'error', maxSize:20, maxExpand:500, output:'html', macros:{}});
  }
  // Force layout before waiting: newly inserted math may only now request fonts.
  target.getBoundingClientRect();
  await document.fonts.ready;
  const box = target.getBoundingClientRect();
  if (box.width > 800 || box.height > 1500 || box.width <= 0 || box.height <= 0) throw Error('排版尺寸超出预算，请查看源码');
  return {x:box.x, y:box.y, width:Math.ceil(box.width), height:Math.ceil(box.height)};
};
