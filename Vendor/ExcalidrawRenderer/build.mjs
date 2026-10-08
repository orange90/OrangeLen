import {build} from 'esbuild';
import fs from 'node:fs';
import path from 'node:path';
const output = '../../Packages/OrangeLen/Sources/OrangeLenUI/Resources/ExcalidrawRenderer.html';
const result = await build({entryPoints:['entry.js'], bundle:true, minify:true, format:'iife', write:false, legalComments:'eof', platform:'browser', define:{'process.env.NODE_ENV':'"production"','import.meta.url':'"about:blank"'}});
const js = result.outputFiles[0].text.replace(/<\/script/gi, '<\\/script');
// Excalidraw's dynamically loaded fonts are replaced by offline font faces.
let css = '';
const root = 'node_modules/@excalidraw/excalidraw/dist/prod/fonts';
for (const [directory, family] of [['Virgil','Virgil'],['Excalifont','Excalifont'],['Cascadia','Cascadia']]) {
  for (const file of fs.readdirSync(path.join(root,directory)).filter(x => x.endsWith('.woff2'))) {
    css += `@font-face{font-family:"${family}";src:url(data:font/woff2;base64,${fs.readFileSync(path.join(root,directory,file)).toString('base64')}) format('woff2');}`;
  }
}
fs.writeFileSync(output, `<!doctype html><html><head><meta charset="utf-8"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; font-src data:; img-src data:; connect-src 'none'; frame-src 'none'; object-src 'none'; base-uri 'none'; form-action 'none'"><style>${css}html,body{margin:0;background:white}#output{display:inline-block}svg{display:block}</style></head><body><div id="output"></div><script>${js}</script></body></html>`);
let licenses=[];
function walk(dir){for(const entry of fs.readdirSync(dir,{withFileTypes:true})){if(entry.name==='.bin')continue;const p=path.join(dir,entry.name);if(entry.isDirectory())walk(p);else if(/^(license|licence|copying|ofl)(\.|$)/i.test(entry.name))licenses.push(`\n===== ${p} =====\n${fs.readFileSync(p,'utf8')}`);}}
walk('node_modules');fs.writeFileSync('../../docs/licenses/ExcalidrawRenderer-dependencies.txt',licenses.join('\n'));
console.log(`Offline Excalidraw renderer: ${fs.statSync(output).size} bytes`);
