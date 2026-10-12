# 高级 AI 产出预览合成示例

所有数据为合成内容，未使用私人项目或实际模型权重。

- diagram.drawio：同一图的原始和压缩页面；board.canvas / card.md：文本与授权本地文件卡片。
- comfy.json、comfy-api.json、n8n.json、dify.yml：四种工作流结构；workflows.n8np：TAR/GZIP 型 n8n 包。
- component.jsx / component.tsx / document.mdx：单文件 React / MDX 内容。
- document.tex / document.typ：文字、标题、列表及数学排版。
- table.parquet：Snappy 压缩的三列、三行；array.npy / fortran.npy / arrays.npz：数组、存储顺序和多数组容器。
- weights.safetensors / sample.latent / model.gguf：仅一个小张量和合成元数据。
- mesh.obj / mesh.stl / mesh.gltf / mesh.glb：静态三角形或四面体，GLTF 使用内嵌 buffer。
- generation.jpg / generation.xmp / generation.jpg.json：EXIF/XMP/授权 sidecar；credentials.c2pa：不含真实签名的合成 JUMBF 结构。

Finder 空格预览此目录后点选文件，或主应用打开文件。单文件调用取决于实际系统类型与其他处理器；外部文件卡片/sidecar 只在目录权限范围内读取。
