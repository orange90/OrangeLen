import {Graphviz} from '@hpcc-js/wasm/graphviz';
window.orangeRender=async(kind,source)=>{
 if(source.length>65536)throw Error('DOT source 64 KiB');if(/\b(image|shapefile|imagepath)\s*=/i.test(source))throw Error('External DOT images unsupported');
 const g=await Graphviz.load(),svg=g.layout(source,'svg','dot');if(svg.length>2000000)throw Error('DOT output budget');const doc=new DOMParser().parseFromString(svg,'image/svg+xml');
 for(const el of doc.querySelectorAll('script,foreignObject,image,style'))el.remove();for(const el of doc.querySelectorAll('*'))for(const a of [...el.attributes])if(a.name.toLowerCase().startsWith('on')||a.name.includes('href'))el.removeAttribute(a.name);
 document.getElementById('root').replaceChildren(document.importNode(doc.documentElement,true));return {width:Math.min(1824,Math.max(300,document.body.scrollWidth)),height:Math.min(1824,Math.max(200,document.body.scrollHeight)),x:0,y:0};
};
