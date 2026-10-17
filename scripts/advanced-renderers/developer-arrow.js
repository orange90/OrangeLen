import {RecordBatchReader, Message, compressionRegistry, CompressionType} from 'apache-arrow';
import {Zstd} from '@hpcc-js/wasm/zstd';import lz4 from 'lz4js';
const MAX=64*1024*1024;
function key(bytes){let h=2166136261;for(const b of bytes)h=Math.imul(h^b,16777619);return bytes.length+':'+(h>>>0);}
export async function decodeArrow(bytes){
 if(bytes.length>25*1024*1024)throw Error('Arrow input 25 MiB');
 const magic=new TextDecoder().decode(bytes.subarray(0,6));if(magic.startsWith('FEA1'))throw Error('Legacy Feather V1 unsupported; export Feather V2 / Arrow IPC');
 const view=new DataView(bytes.buffer,bytes.byteOffset,bytes.byteLength),expected=new Map();let pos=magic==='ARROW1'?8:0,end=bytes.length,expanded=0,messages=0,totalRows=0;
 if(magic==='ARROW1'){if(bytes.length<18||new TextDecoder().decode(bytes.subarray(-6))!=='ARROW1')throw Error('Arrow footer');end=bytes.length-10-view.getInt32(bytes.length-10,true);if(end<8||end>bytes.length-10)throw Error('Arrow footer range');}
 function integer(n,max=MAX){if(!Number.isSafeInteger(n)||n<0||n>max)throw Error('Arrow metadata budget');return n;}
 while(pos<end){
  if(++messages>10000||pos+4>end)throw Error('Arrow message budget');let size=view.getInt32(pos,true);pos+=4;
  if(size===-1){if(pos+4>end)throw Error('Arrow continuation');size=view.getInt32(pos,true);pos+=4;}
  if(size===0){if(magic!=='ARROW1'&&pos!==end)throw Error('Arrow trailing bytes');break;}
  integer(size,1024*1024);if(pos+size>end)throw Error('Arrow metadata range');const message=Message.decode(bytes.subarray(pos,pos+size));pos+=size;
  const bodyLength=integer(message.bodyLength,25*1024*1024);if(pos+bodyLength>end)throw Error('Arrow body range');let h=message.header();if(message.isDictionaryBatch())h=h.data;
  if(message.isSchema()){let fields=0;function check(f,d){if(++fields>256||d>32)throw Error('Arrow schema budget');for(const c of f.type.children||[])check(c,d+1);}for(const f of h.fields)check(f,0);}
  else if(message.isRecordBatch()||message.isDictionaryBatch()){
   integer(h.length,10000000);if(message.isRecordBatch())totalRows+=h.length;if(h.buffers.length>10000||h.nodes.length>10000)throw Error('Arrow buffer budget');
   for(const b of h.buffers){integer(b.offset,bodyLength);integer(b.length,bodyLength);if(b.offset+b.length>bodyLength)throw Error('Arrow buffer range');let n=b.length;
    if(h.compression&&n){if(n<8)throw Error('Arrow compressed prefix');const raw=view.getBigInt64(pos+b.offset,true);if(raw===-1n)n-=8;else{if(raw<0n||raw>BigInt(MAX))throw Error('Arrow decompression budget');n=Number(raw);const k=key(bytes.subarray(pos+b.offset+8,pos+b.offset+b.length));if(expected.has(k)&&expected.get(k)!==n)throw Error('Arrow compression size mismatch');expected.set(k,n);}}
    expanded+=n;if(expanded>MAX)throw Error('Arrow expanded buffers 64 MiB');
   }
  }else throw Error('Unsupported Arrow message');pos+=bodyLength;
 }
 const z=await Zstd.load();function amount(data){const n=expected.get(key(data));if(n===undefined)throw Error('Unvalidated compressed buffer');return n;}
 compressionRegistry.set(CompressionType.LZ4_FRAME,{decode(data){const n=amount(data),out=new Uint8Array(n),size=lz4.decompressFrame(data,out);if(size!==n)throw Error('LZ4 size mismatch');return out;}});
 compressionRegistry.set(CompressionType.ZSTD,{decode(data){const n=amount(data);const heap=z._mainModule.dataToHeap(data);try{const size=z.frameContentSize(heap);if(size.error||!size.known||size.size!==n||z._zstdClass.findFrameCompressedSize(heap.ptr,heap.size)!==data.length)throw Error('ZSTD frame size missing or inconsistent');}finally{z._mainModule.free(heap);}const out=z.decompress(data);if(out.length!==n)throw Error('ZSTD size mismatch');return out;}});
 const reader=RecordBatchReader.from(bytes);reader.open();const columns=reader.schema.fields.map(f=>f.name+' ('+f.type+')'),rows=[];let textBytes=0;
 function cell(v){if(v==null)return 'NULL';if(typeof v==='object'){if(v instanceof Date)return v.toISOString();if(ArrayBuffer.isView(v))return Array.from(v).slice(0,64).join(', ');return JSON.stringify(v,(_,x)=>typeof x==='bigint'?String(x):x).slice(0,4096);}return String(v).slice(0,4096);}
 for(const batch of reader){for(let i=0;i<batch.numRows&&rows.length<500;i++){const row=columns.map((_,j)=>cell(batch.getChildAt(j).get(i)));textBytes+=row.reduce((n,c)=>n+c.length,0);if(textBytes>1000000)throw Error('Arrow sample text budget');rows.push(row);}if(rows.length>=500)break;}
 return {columns,rows,totalRows,summary:'Arrow IPC / Feather V2 · '+totalRows+' rows · '+columns.length+' columns\nSample: first '+rows.length+' rows (maximum 500) · file/stream, LZ4/ZSTD · no execution'};
}
window.orangeArrow=async url=>decodeArrow(new Uint8Array(await(await fetch(url)).arrayBuffer()));
