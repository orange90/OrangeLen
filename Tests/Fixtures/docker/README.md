# Docker 文件预览测试

这些文件全部是合成夹具，供测试 OrangeLen 的显示、搜索、选择和复制。未执行 Docker 构建或 Compose 启动。

## 建议测试顺序

1. 在 Finder 中选中本目录 `docker`，按空格打开文件夹 Quick Look。
2. 在左侧依次点开 `Dockerfile`、`dockerfile.dev`、`Dockerfile.prod`、`Containerfile`：应显示完整源码与行号。
3. 点开 `compose.yaml`、`compose.dev.yaml`、`docker-compose.yml`：应显示 YAML 源码，包括变量、锚点和中文注释；目前没有服务关系图。
4. 点开 `daemon.json`、`docker-config.json`：应显示 JSON 结构树，并可切换原文。
5. 开启目录树的“显示忽略项”，找到 `.dockerignore` 和 `.env.example`，检查隐藏配置正文。
6. 点开 `docker-project.tar` 或 `docker-project.tar.gz`，选择内部代码/配置，检查归档内预览。
7. 关闭预览，分别选单个文件按空格，对比单文件类型分派结果。

## 已知入口差异

| 示例 | OrangeLen 宿主或文件夹内 | Finder 单文件 |
|---|---|---|
| Dockerfile、dockerfile.dev、Dockerfile.prod/test、Containerfile | 按完整文件名识别为源码 | 本机 Dockerfile.dev 已复现只显示系统图标/元数据；其余无后缀或泛用后缀也不能据此承诺调用 OrangeLen |
| .dockerignore、.env.example | 配置源码；默认隐藏，需要显示忽略项 | 类型分派未打通或未实测 |
| compose.yaml、compose.dev.yaml、docker-compose.yml | YAML 源码 | 系统按 YAML 类型选择预览器；需观察是否出现 OrangeLen 工具栏 |
| daemon.json、docker-config.json | JSON 树和原文 | 系统按 JSON 类型选择预览器 |
| docker-project.tar、docker-project.tar.gz | 归档成员列表 | 需观察实际调用；普通 .gz 和 .tar.gz 的处理不同 |

`docker-project.tar` 与 `.tar.gz` 仅是这个示例项目的源码归档，不是 `docker save` 导出的镜像。Dockerfile 使用的镜像标签只是示例，不代表已测试构建或可部署配置。

测试时可记录：文件名、入口、是否有 OrangeLen 工具栏、正文是否显示、源码切换和复制是否正常。
