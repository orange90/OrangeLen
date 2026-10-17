from pathlib import Path
import json, zipfile
import pyarrow as pa
import pyarrow.feather as feather
import onnx
from onnx import helper, TensorProto
root=Path(__file__).resolve().parents[1]/'Tests/Fixtures/developer-batch1'
root.mkdir(parents=True,exist_ok=True)
table=pa.table({'name':['Orange','中文样本 🍊','Agent'], 'tokens':[128,256,512], 'score':[0.9,None,0.75]})
for name,kind,compression in [('dataset.arrow','file',None),('stream.ipc','stream',None),('compressed.feather','file','lz4'),('zstd.feather','file','zstd')]:
 with pa.OSFile(str(root/name),'wb') as sink:
  with (pa.ipc.new_file if kind=='file' else pa.ipc.new_stream)(sink,table.schema,options=pa.ipc.IpcWriteOptions(compression=compression)) as writer:writer.write_table(table)
feather.write_feather(table,root/'legacy.feather',version=1)
model=helper.make_model(helper.make_graph([helper.make_node('Relu',['input'],['output'],name='activation')],'Orange test',[helper.make_tensor_value_info('input',TensorProto.FLOAT,['batch',3])],[helper.make_tensor_value_info('output',TensorProto.FLOAT,['batch',3])]),producer_name='OrangeLen fixture',opset_imports=[helper.make_opsetid('',18)])
onnx.save(model,root/'model.onnx')
(root/'broken.onnx').write_bytes(b'\x08\xff\xff')
(root/'junit.xml').write_text('''<?xml version="1.0"?><testsuites><testsuite name="Orange"><testcase classname="Preview" name="reads Chinese 🍊" time="0.02"/><testcase classname="Preview" name="missing model" time="0.12"><failure message="Expected model">AssertionError: model not found\npreview.swift:42</failure></testcase><testcase classname="Preview" name="optional GPU"><skipped message="No GPU required"/></testcase></testsuite></testsuites>''')
(root/'scan.sarif').write_text(json.dumps({'version':'2.1.0','runs':[{'tool':{'driver':{'name':'Fixture scanner'}},'results':[{'ruleId':'ORANGE001','level':'warning','message':{'text':'示例：检查空值 🍊'},'locations':[{'physicalLocation':{'artifactLocation':{'uri':'src/reader.py'},'region':{'startLine':42}}}]}]}]},ensure_ascii=False))
(root/'api.yaml').write_text('''openapi: 3.0.3
info:
  title: Orange API
  version: 1.0.0
paths:
  /models:
    get:
      summary: List models 🍊
      operationId: listModels
      responses:
        '200':
          description: OK
''')
(root/'architecture.gv').write_text('digraph Orange { rankdir=LR; input [label="Input"]; model [label="ONNX model"]; output [label="Preview"]; input -> model -> output; }')
(root/'architecture.dot').write_text((root/'architecture.gv').read_text())
with zipfile.ZipFile(root/'orange_demo-1.0-py3-none-any.whl','w',zipfile.ZIP_DEFLATED) as z:
 z.writestr('orange_demo/__init__.py','"""Orange demo — not executed."""\nVERSION = "1.0"\n')
 z.writestr('orange_demo-1.0.dist-info/METADATA','Metadata-Version: 2.1\nName: orange-demo\nVersion: 1.0\nSummary: 中文 package 🍊\nRequires-Dist: numpy>=1.24\n\nDemo package\n')
 z.writestr('orange_demo-1.0.dist-info/WHEEL','Wheel-Version: 1.0\nRoot-Is-Purelib: true\nTag: py3-none-any\n')
with zipfile.ZipFile(root/'orange-demo.vsix','w',zipfile.ZIP_DEFLATED) as z:
 z.writestr('extension/package.json',json.dumps({'name':'orange-demo','displayName':'Orange demo 🍊','version':'1.0.0','publisher':'fixture','engines':{'vscode':'^1.90.0'},'main':'./extension.js'},ensure_ascii=False))
 z.writestr('extension/extension.js','exports.activate = () => {}; // Preview does not run this\n')
 z.writestr('extension.vsixmanifest','<PackageManifest Version="2.0.0"/>')
samples={
 'pyi':'def predict(text: str) -> list[float]: ...\n',
 'pyx':'cdef int square(int x):\n    return x * x\n',
 'pxd':'cdef int square(int x)\n','pxi':'cdef int count = 3\n',
 'cu':'__global__ void scale(float *x) { x[threadIdx.x] *= 2.0f; }\n','cuh':'__global__ void scale(float *x);\n',
 'cc':'#include <string>\nint main() { return 0; }\n','cxx':'template<class T> T twice(T n) { return n + n; }\n','hh':'#pragma once\nclass Reader {};\n','hxx':'#pragma once\nstruct Model {};\n','ipp':'template<class T> T twice(T n) { return n+n; }\n','tpp':'template<class T> T value() { return T{}; }\n','inl':'inline int count() { return 3; }\n',
 'kts':'plugins { kotlin("jvm") version "2.0.0" }\n','gradle':'plugins { id "java" }\n','groovy':'println "Orange preview"\n','cmake':'add_library(orange reader.cpp)\n','mk':'all:\n\t@echo Orange preview\n',
 'mdc':'---\ndescription: Orange coding rules\nalwaysApply: true\n---\n# Rules 🍊\nPreserve source text.\n',
 'http':'### List models\nGET https://example.com/models\nAccept: application/json\n','rest':'POST https://example.com/models\nContent-Type: application/json\n\n{"name":"orange"}\n',
 'j2':'Hello {{ name }}!\n','jinja':'{% for model in models %}{{ model }}{% endfor %}\n','jinja2':'{{ prompt }}\n','tmpl':'{{ .Name }}\n','tpl':'{{ include "orange.name" . }}\n',
 'rst':'Orange documentation\n====================\n\nRead-only preview.\n','adoc':'= Orange documentation\n\nRead-only preview.\n','asciidoc':'= Orange documentation\n\nRead-only preview.\n'}
for ext,text in samples.items():(root/('sample.'+ext)).write_text(text)
(root/'.cursorrules').write_text('Preserve source text. Do not execute preview content.\n')
(root/'README.md').write_text('# Developer batch 1 fixtures\n\nSynthetic fixtures for Finder Space verification. legacy.feather and broken.onnx are intentional failures. HTTP, code, model and package content must never execute.\n')
print(root, len(list(root.iterdir())), 'fixtures')
