# 公式、图表与图片

普通正文仍可选择复制：中文、English、emoji 👩🏽‍💻。行内公式 $E = mc^2$ 与 $\frac{a+b}{c}$ 应与文字一起排版。

## 块级公式

$$
\int_0^1 x^2\,dx = \frac{1}{3}
$$

$$
\begin{pmatrix} a & b \\ c & d \end{pmatrix}
\quad \sum_{i=1}^{n} i = \frac{n(n+1)}{2}
$$

## Mermaid 流程图

```mermaid
flowchart LR
    A[选择 Markdown] --> B{本地内容?}
    B -->|是| C[直接渲染]
    B -->|远程图片| D[等待用户点击]
    D --> E[安全下载与解码]
```

## Mermaid 时序图

```mermaid
sequenceDiagram
    participant U as 用户
    participant P as 预览
    U->>P: 打开文件
    P-->>U: 正文与占位
    U->>P: 加载远程图片
    P-->>U: 图片或错误提示
```

## 本地图片

![本地棋盘](sample.png)

## 远程图片（不会自动联网）

![W3C 标志，点击加载](https://www.w3.org/assets/logos/w3c-2025-transitional/w3c-72x48.png)

## 安全回归

原始 HTML 只显示，不执行：<script>alert('never execute')</script>。

这张图片必须阻止访问：![私有地址](https://127.0.0.1/private.png)

下面图表包含交互指令，应拒绝渲染，源码仍可查看和复制：

```mermaid
flowchart LR
 A --> B
 click A "https://example.com"
```
