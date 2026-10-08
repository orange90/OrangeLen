# 大文件首屏优先（2026-10-07）

普通文件阅读入口超过 1 MiB 后以 64 KiB 分页，保留严格 UTF-8/UTF-16 标量边界、字节范围、前后页及阅读位置。此前为超过 5 MiB 后按 512 KiB 分页。

分页正文准备不再等待 Highlight.js。正文先交给 TextKit 并完成预览回调，后台只处理每页前 16,384 UTF-16 单元，随后只更新颜色属性。文件取消检查、文件 generation 和呈现 request 三层检查防止旧结果覆盖新内容。已进入同步 JavaScript 的执行不能中途打断，依靠小输入限制工作量；不宣称完全可抢占。

新增 read_ms、ready_ms、highlight_ms 日志。ready_ms 是读取开始到正文准备完成，不含 Finder 调起扩展时间，也不等同屏幕首帧呈现。

验证：87 项 XCTest 全部通过，含中等文件跨页 Unicode 重组、正文回调先于高亮、选区保持和旧任务防覆盖；Debug 构建、已有 Apple Development 安装与 deep/strict 验签成功。开发版已更新至 ~/Applications/OrangeLen.app。测试日志见 evidence/fast-preview/tests.log。

真实 Finder：6 MB Swift 首屏源码与高亮可见；切到 8.3 MB JSON 标记 CURRENT_FILE_02 匹配；JSON 第一页 1–65534，第二页 65535–131070，UTF 边界与翻页正常。对应扩展正文准备日志约 39 ms 和 128 ms，高亮约 278 ms 和 377 ms。这是少量本机观察，不是前后同条件对照或冷启动分位数。组件测试约 8 MB Swift 正文准备 63 ms，另 1 MiB 文件 20 次热准备 P95 69 ms；不可作为 Finder 端到端时间。

边界：这是第一阶段。仍保留按钮分页，尚未实现连续滚动、下一段预读、可见区动态高亮或大结构文档的渐进树视图。超过 1 MiB 的 Markdown/JSON/CSV 会降级分页源码（之前阈值 5 MiB），后续页语法高亮没有跨页词法上下文，颜色可能不准确；查找、复制、行号限当前页。归档/Notebook 等容器入口仍沿用自身预算。
