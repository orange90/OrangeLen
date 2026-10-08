---
title: OrangeLen 阅读体验
version: 0.2
language: 中文 / English
---

# OrangeLen · 项目阅读

从 Finder 打开文档，沿着大纲读代码、数据和图表。原文保持完整，可随时切换源码。

> [!TIP]
> 目录侧栏会跟随阅读位置。点击图表可以放大，拖动即可平移。

## 语言高亮

```python
def greet(name: str) -> str:
    # 字符串中的 return 不会被误认为关键字
    return f"你好，{name} 🍊"
```

```typescript
interface Preview {
  source: string;
  readonly: boolean;
}
const preview: Preview = { source: "class return 42", readonly: true };
```

## 数据保真

JSON 原始大整数和重复键可以直接核对，数据库排序会使用原始类型[^data]。

| 文件 | 阅读方式 |
| --- | --- |
| 项目目录 | 左侧选文件，右侧连续阅读 |
| SQLite | 每页 500 行，列标题排序 |
| 压缩包 | 目录树、完整路径筛选、大小排序 |

## 图表

```mermaid
flowchart LR
  A[Finder 选中文件] --> B[按空格预览]
  B --> C[目录 / 数据 / 图表]
  C --> D[核对并复制原文]
```

公式：$E=mc^2$。

## 本地图片

![本地示例](sample.png)

## 阅读记录

保存文档后会自动更新。阅读位置和源码模式尽量保留，远程图片仍需主动点击才加载。

[^data]: 数据库在**只读内存快照**中读取，不执行文件里的 SQL。BLOB 显示字节数。
