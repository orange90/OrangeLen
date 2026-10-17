import {build} from 'esbuild';import fs from 'node:fs';
for(const [name,entry] of [['Arrow','developer-arrow.js'],['Dot','developer-dot.js']]){
 const result=await build({entryPoints:[entry],bundle:true,platform:'browser',format:'iife',write:false,minify:true});
 fs.writeFileSync('../../Packages/OrangeLen/Sources/OrangeLenUI/Resources/'+name+'Renderer.html','<!doctype html><html><head><meta charset="utf-8"><style>body{margin:12px;background:white}svg{max-width:1800px;max-height:1800px}</style></head><body><div id="root"></div><script>'+result.outputFiles[0].text.replace(/<\/script/gi,'<\\/script')+'</script></body></html>');
}
const notices=[];
for(const name of ['apache-arrow','@hpcc-js/wasm','lz4js']) {
 const dir='node_modules/'+name,pkg=JSON.parse(fs.readFileSync(dir+'/package.json'));
 const license=fs.readdirSync(dir).find(x=>/^LICENSE(?:\.|$)/i.test(x));
 notices.push(name+' '+pkg.version+'\n'+(license?fs.readFileSync(dir+'/'+license,'utf8'):pkg.license));
}
notices.push('Apache Arrow NOTICE\n'+fs.readFileSync('node_modules/apache-arrow/NOTICE.txt','utf8'));
notices.push('Graphviz: see Graphviz-LICENSE.txt (EPL-1.0); source: https://gitlab.com/graphviz/graphviz\nZstandard: see Zstandard-LICENSE.txt (BSD); source: https://github.com/facebook/zstd\nLZ4js 0.2.0 by John Chadwick, ISC; source: https://github.com/Benzinga/lz4js');
fs.writeFileSync('../../docs/licenses/DeveloperRenderer-dependencies.txt',notices.map(s=>s.replace(/\r\n/g,'\n').trimEnd()).join('\n\n')+'\n');
