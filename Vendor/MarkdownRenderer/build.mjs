import {build} from 'esbuild';
import fs from 'node:fs';
import path from 'node:path';
const output = '../../Packages/OrangeLen/Sources/OrangeLenUI/Resources/RichRenderer.html';
const result = await build({entryPoints:['entry.js'], bundle:true, minify:true, format:'iife', write:false, legalComments:'eof', platform:'browser'});
const js=result.outputFiles[0].text.replace(/<\/script/gi, '<\\/script');
let css=fs.readFileSync('node_modules/katex/dist/katex.min.css','utf8');
css=css.replace(/url\(([^)]+)\)/g, (_,file) => {
 const name=file.replace(/["']/g,'');
 const bytes=fs.readFileSync(path.join('node_modules/katex/dist',name));
 return `url(data:font/${name.endsWith('woff2')?'woff2':name.endsWith('woff')?'woff':'ttf'};base64,${bytes.toString('base64')})`;
});
fs.mkdirSync(path.dirname(output),{recursive:true});
fs.writeFileSync(output, `<!doctype html><html><head><meta charset="utf-8"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; font-src data:; img-src 'none'; connect-src 'none'; frame-src 'none'; object-src 'none'; base-uri 'none'; form-action 'none'"><style>${css}\nhtml,body{margin:0;background:#f8f9fa;color:#202124;font:18px Arial}#output{display:inline-block;padding:8px;max-width:780px;box-sizing:border-box}svg{display:block} .katex-display{margin:4px 0}</style></head><body><div id="output"></div><script>${js}</script></body></html>`);
// Include licenses of all locked packages in the vendored dependency tree, not only top-level libraries.
let licenses=[];
function walk(dir){ for(const entry of fs.readdirSync(dir,{withFileTypes:true})){ if(entry.name==='.bin')continue; const p=path.join(dir,entry.name); if(entry.isDirectory())walk(p);else if(/^(license|licence|copying)(\.|$)/i.test(entry.name))licenses.push(`\n===== ${p} =====\n${fs.readFileSync(p,'utf8')}`); }}
walk('node_modules'); fs.writeFileSync('../../docs/licenses/MarkdownRenderer-dependencies.txt',licenses.join('\n'));
console.log(`Vendored offline renderer: ${fs.statSync(output).size} bytes; ${licenses.length} license files`);
