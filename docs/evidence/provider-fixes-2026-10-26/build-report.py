"""Correlate captured Finder windows with timed provider callbacks. No UI is simulated."""
import collections
import datetime as dt
import hashlib
import json
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent

def epoch(s):
    return dt.datetime.fromisoformat(s.replace('Z', '+00:00')).timestamp()

def read_jsonl(name):
    return [json.loads(s) for s in (HERE / name).read_text().splitlines() if s.strip()]

manifest = json.loads((HERE / 'manifest.json').read_text())
final = read_jsonl('final.jsonl')
assert len(manifest) == len(final) == len({r['extension'] for r in final}) == 21
events = []
for s in (HERE / 'runtime.log').read_text().splitlines():
    try:
        x = json.loads(s)
        msg = x.get('eventMessage', '')
        if any(k in msg for k in ('prepare received', 'prepare completed', 'probe received', 'probe completed', 'got displayBundleID')):
            events.append(dict(id=len(events)+1, timestamp=x['timestamp'], message=msg,
                               process_id=x['processID'], process_path=x['processImagePath']))
    except (ValueError, AttributeError):
        continue
(HERE / 'provider-events.json').write_text(json.dumps(events, ensure_ascii=False, indent=2)+'\n')
rows = []
for case, result in zip(manifest, final):
    ext = case['extension']
    assert ext == result['extension']
    assert hashlib.sha256(Path(case['path']).read_bytes()).hexdigest() == case['sha256']
    state = (HERE / result['ax']).read_text()
    assert 'window Quick Look' in state and case['filename'] in state
    own = result['orangelen']
    low, high = epoch(result['opened_at']), epoch(result['captured_at']) + .2
    window_events = [x for x in events if low <= epoch(x['timestamp']) <= high]
    received = [x for x in window_events if x['message'] == f'prepare received extension=OrangeLen type={ext}']
    assert own == bool(received), (ext, 'UI / callback mismatch')
    provider_events = [x for x in window_events if 'got displayBundleID' in x['message']]
    assert provider_events, ext
    provider = re.search(r'got displayBundleID (\S+)',provider_events[-1]['message']).group(1)
    success = []
    if own:
        for call in received:
            completed = [x for x in window_events if x['process_id'] == call['process_id'] and epoch(x['timestamp']) >= epoch(call['timestamp']) and x['message'] == 'prepare completed success=true']
            assert completed, (ext, 'missing success callback')
            assert call['process_path'].startswith('/Applications/OrangeLen.app/Contents/PlugIns/'), call
            success.extend(x['id'] for x in completed)
        if ext in ('txz', 'tbz2'):
            member = (HERE / f'{ext}-member-ax.txt').read_text()
            assert 'README.md' in member and '**OrangeLen archive**' in member and 'Archive preview 中文🍊' in member
            content = '目录及 README.md 成员正文均已实际打开'
        elif ext == 'wflow':
            assert 'WFWorkflowActions' in state and 'OrangeLen workflow 中文🍊' in state
            content = '二进制 plist 转 XML，动作及中文正文可读；依赖 Shortcuts 偏好设置'
        else:
            text = Path(case['path']).read_text()
            assert text.splitlines()[0] in state
            content = 'OrangeLen 正文区域包含样例源码/日志/差异内容'
        status = 'OrangeLen'
    else:
        assert not any(x['message'].startswith('probe received') for x in window_events)
        status = '系统仅文件信息' if result['metadata_only'] else '系统正文'
        content = '仍无正文，未修复' if result['metadata_only'] else '正文由系统提供，OrangeLen 接管未解决'
    rows.append({**case, **result, 'status':status, 'provider':provider, 'content_check':content,
                 'display_event_ids':[provider_events[-1]['id']], 'receive_event_ids':[x['id'] for x in received],
                 'success_event_ids':success, 'process_paths':sorted({x['process_path'] for x in received})})
counts = collections.Counter(x['status'] for x in rows)
assert dict(counts) == {'系统仅文件信息':3,'OrangeLen':10,'系统正文':8}, counts
probes = read_jsonl('data-provider-probe.jsonl')
assert len(probes) == len({x['extension'] for x in probes}) == 12
assert not any(x.get('probe') or x.get('orangelen') for x in probes)
probe_calls = [x for x in events if x['message'].startswith('probe received')]
assert probe_calls and {x['message'].split('type=')[-1] for x in probe_calls} == {'orangeprobe'}
assert 'OrangeLen native data-provider diagnostic' in (HERE/'probe-control-ax.txt').read_text()
assert not read_jsonl('workflow-restored.jsonl')[0]['orangelen']
summary = {'date':'2026-10-26','machine':'macOS 26.6.2 (25G83), arm64','cases':21,'counts':dict(counts),
           'fixed_extensions':[x['extension'] for x in rows if x['orangelen']],
           'unresolved_extensions':[x['extension'] for x in rows if not x['orangelen']],
           'priority_five_fixed':['txz','tbz2'],'priority_five_unresolved':['ts','mts','dot'],
           'ui_callback_mismatches':0,'data_provider_control_passed':True,'data_provider_blocked_cases':12,
           'tests_passed':21,'published_release_updated':False,
           'workflow_preference':'Shortcuts QuickLookExtension ignored; prior default saved by scripts/prefer-workflow-preview.sh; affects .shortcut too',
           'system_bridge_preference':'restored to default; ignore experiment had no effect on TS/TXT/CSV',
           'diagnostic_extension':'unregistered after testing; not part of product',
           'whole_371_rerun':False,'inferred_371_overlay':{'OrangeLen':360,'system_content':8,'metadata_only':3},
           'scope':'One bounded fixture per suffix. All 21 individually opened using Finder Space and correlated with live logs. Other 350 retain earlier audit evidence; 360 is an overlay, not a fresh whole-suite run.'}
(HERE/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
(HERE/'final-results.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n')
lines=['# 剩余 21 种文件：修复与 Finder 验收','',
       '2026-10-26，本机开发版，macOS 26.6.2 (25G83) / Apple Silicon。','',
       '**10 种已由 OrangeLen 接管并显示正文或归档目录/成员；11 种尚未解决。原先没有正文的 5 种中修复了 TXZ、TBZ2，TS、MTS、DOT 仍只有系统文件卡片。不能称为 21 种全部修好。**','',
       '最终 21 项均逐个在 Finder 选中并按空格，核对实际窗口文件名、OrangeLen 专属控件、扩展接收及成功回调。10 项 OrangeLen 回调进程均来自 `/Applications/OrangeLen.app`，没有以系统正文冒充 OrangeLen 的项目。','',
       '## 实施的修复','',
       '- Code 扩展补充本机精确类型：`public.zsh-script`、`public.bash-script`、`com.apple.rez-source`、`public.protobuf-source`、`com.apple.log`、`public.patch-file`。覆盖 ZSH/BASH/R/PROTO/LOG/DIFF/PATCH；读取器按后缀选择语言，R 不按系统 Rez 类型渲染。',
       '- Archives 补充 `org.tukaani.tar-xz-archive`、`public.tar-bzip2-archive`，覆盖 TXZ/TBZ2。两者都实际选择 README.md，正文含中文及表情，见本机成员截图/AX。',
       '- 同步 `public.xhtml` 声明后本机仍走系统 Web2，未计作修复成功。',
       '- WFLOW 通过可恢复的用户扩展偏好接管，显示二进制 plist 转 XML 的动作正文；不执行工作流。','',
       '## WFLOW 设置与恢复','',
       '当前已启用 OrangeLen 偏好。Apple 的同一扩展也处理 `.shortcut`，因此其系统动作卡片预览同时被停用。启用前的 `default` 已保存在 `~/Library/Application Support/OrangeLen/workflow-preview-election`。已实测启用 → OrangeLen、恢复 → 系统、再次启用 → OrangeLen。','',
       '```bash','./scripts/prefer-workflow-preview.sh status','./scripts/prefer-workflow-preview.sh restore','```','',
       '这项设置不是安装包自动修复；其他用户仍须自行选择。原有 Hydra 设置保持不变，临时系统桥接设置已恢复。','',
       '## 仍未解决的原生分派','',
       '- TS/MTS：实际 UTI 是 MPEG/AVCHD 传输流，Finder 选择 Movie，未调用 OrangeLen。DOT：与 Word 模板冲突，选择 PDFKit，仅文件信息。',
       '- HTML/HTM/XHTML/CSV/SVG：选择系统 Web2；TXT/TEXT：选择系统 Text；PDF：选择系统 PDFKit。它们能显示系统正文，但没有本轮 OrangeLen 接收回调。',
       '- 为排除扩展实现方式影响，独立构建 Apple `QLPreviewProvider` / `QLPreviewReply` 数据式扩展。控制后缀 `.orangeprobe` 出现专属诊断正文及接收/成功日志；12 个原阻塞后缀均没有调用此扩展。测试扩展随后注销，不计入正式修复。',
       '- 临时停用系统 QLPreviewGenerationExtension 后，TS/TXT/CSV 仍不改变分派；已恢复原来的 default。现有公开原生路径下尚未找到经本机验证可接管这 11 项的方法；本报告不声称平台永久不可能。','',
       '## 逐项结果','',
       '事件编号见 [provider-events.json](provider-events.json)，详细字段/样例 SHA256 见 [final-results.json](final-results.json)。AX、原始日志及截图按仓库规则保留本机。','',
       '|后缀|修复前|最终实际提供器|正文检查|调用日志事件|Finder 证据|','|---|---|---|---|---|---|']
for x in rows:
    ids=x['receive_event_ids']+x['success_event_ids'] if x['orangelen'] else x['display_event_ids']
    provider='OrangeLen' if x['orangelen'] else x['provider'].replace('com.apple.qldisplay.','系统 ')
    lines.append(f"|`.{x['extension']}`|{x['before']}|{provider}|{x['content_check']}|{', '.join(map(str,ids))}|[AX]({x['ax']}) / [截图]({x['screenshot']})|")
lines += ['', '## 验证范围','',
          '相关 21 项内部测试通过，Debug 构建成功；`~/Applications` 与 `/Applications` 两处安装均通过 deep/strict 签名检查。内部测试仅证明读取器，不替代上表 Finder 证明。',
          '本轮重新检查的是剩余 21 项。与先前 350 项记录叠加得到 360 / 8 / 3；这不是新版本全部 371 项重新运行的结果。公开 V1.0 安装包未更新，Intel、其他 macOS、任意文件及完整格式规范未在本轮验收。',
          '原始 371 审计报告保留当时 350 / 16 / 5 快照，不改写历史结果。', '']
(HERE/'README.md').write_text('\n'.join(lines))
print(json.dumps(summary,ensure_ascii=False,indent=2))
