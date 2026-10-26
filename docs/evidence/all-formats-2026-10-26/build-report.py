"""Build the provider report from captured Finder AX and macOS logs; does not run UI tests."""
import collections
import csv
import datetime as dt
import hashlib
import json
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
manifest = json.loads((HERE / 'manifest.json').read_text())
assert len(manifest) == len({x['extension'] for x in manifest}) == 371
attempts = [json.loads(s) for name in ('finder-attempts.jsonl', 'finder-rechecks.jsonl')
            for s in (HERE / name).read_text().splitlines() if s.strip()]
latest = {x['extension']: x for x in attempts}
assert len(latest) == 371

def epoch(s):
    return dt.datetime.fromisoformat(s.replace('Z', '+00:00')).timestamp()

events = []
for line in (HERE / 'runtime.log').read_text().splitlines():
    try:
        x = json.loads(line)
        if not isinstance(x, dict) or 'eventMessage' not in x:
            continue
        message = x['eventMessage']
        if not any(k in message for k in ('prepare received', 'prepare completed', 'got displayBundleID')):
            continue
        events.append({'id': len(events) + 1, 'timestamp': x['timestamp'],
                       'process_id': x['processID'], 'process_path': x['processImagePath'],
                       'subsystem': x['subsystem'], 'message': message})
    except (ValueError, KeyError):
        continue
starts = collections.defaultdict(list)
success = collections.defaultdict(list)
pending = {}
for x in events:
    match = re.search(r'prepare received extension=OrangeLen type=(\S*)', x['message'])
    if match:
        ext = match.group(1)
        starts[ext].append(x)
        pending[x['process_id']] = ext
    elif 'prepare completed' in x['message'] and x['process_id'] in pending:
        ext = pending.pop(x['process_id'])
        if 'success=true' in x['message']:
            success[ext].append(x['id'])
(HERE / 'provider-events.json').write_text(json.dumps(events, ensure_ascii=False, indent=2) + '\n')

types = {}
for line in (HERE / 'content-types.tsv').read_text().splitlines():
    filename, uti, supertypes = line.split('\t')
    types[filename] = (uti, supertypes)
rows = []
for case in manifest:
    ext = case['extension']
    result = latest[ext]
    state = (HERE / result['ax']).read_text()
    assert case['filename'] in state, (ext, 'wrong preview title')
    assert hashlib.sha256(Path(case['path']).read_bytes()).hexdigest() == case['sha256'], ext
    metadata = result.get('ui_metadata_only', 'QLAXImageAndText_Text' in state)
    own = bool(result['ui_orangelen'])
    assert own == bool(starts[ext]), (ext, 'UI / extension log disagreement')
    assert not result['ui_error'], (ext, result['ui_error'])
    if own:
        assert success[ext], (ext, 'no associated successful callback')
        status = 'OrangeLen'
        process_paths = sorted({x['process_path'] for x in starts[ext]})
        provider = ', '.join(Path(x).name for x in process_paths)
        bundle = 'com.apple.qldisplay.Extensions'
        event_ids = [x['id'] for x in starts[ext]]
        content = 'OrangeLen 界面及内容/结构入口已观察；未逐项验证完整规范或像素效果'
    else:
        status = '系统仅基本信息' if metadata else '系统内容预览'
        process_paths = []
        low, high = epoch(result['opened_at']) - .5, epoch(result['captured_at']) + .3
        candidates = [x for x in events if low <= epoch(x['timestamp']) <= high and 'got displayBundleID' in x['message']]
        assert candidates, (ext, 'missing correlated Finder provider event')
        provider_event = candidates[-1]
        bundle = re.search(r'got displayBundleID (\S+)', provider_event['message']).group(1)
        provider = '系统 Shortcuts 界面' if ext == 'wflow' else bundle
        event_ids = [provider_event['id']]
        content = '仅文件名/大小/修改时间，未显示正文' if metadata else '已看到系统提供的文本/网页/文档/工作流内容'
    rows.append({**case, 'status': status, 'provider': provider, 'display_bundle': bundle,
                 'actual_uti': types[case['filename']][0], 'uti_supertypes': types[case['filename']][1],
                 'verified_at': result['captured_at'], 'ax_evidence': result['ax'],
                 'screenshot': result.get('screenshot'), 'provider_event_ids': event_ids,
                 'success_event_ids': success.get(ext, []), 'process_paths': process_paths,
                 'content_check': content, 'last_run': result.get('run', 'first-pass')})
counts = collections.Counter(x['status'] for x in rows)
assert dict(counts) == {'OrangeLen': 350, '系统仅基本信息': 5, '系统内容预览': 16}, counts
(HERE / 'final-results.json').write_text(json.dumps(rows, ensure_ascii=False, indent=2) + '\n')
summary = {'date': '2026-10-26', 'total_suffixes': 371, 'counts': dict(counts),
           'first_pass_cases': 371, 'independent_rechecks': 30,
           'orangelen_ui_without_callback': 0, 'orangelen_suffixes_with_successful_callback': len(success),
           'scope': 'Finder single-file provider attribution using one bounded synthetic fixture per suffix; not full format compatibility',
           'machine': 'macOS 26.6.2 (25G83), arm64', 'installation': '/Applications/OrangeLen.app, local development build including the SQL fix',
           'preexisting_setting': 'com.apple.HydraQLPreviewExtension is disabled (-); unchanged during this audit; OBJ/STL results depend on this profile',
           'published_release_retested': False,
           'product_code_changed_by_this_audit': False,
           'system_extensions': [x['extension'] for x in rows if x['status'] == '系统内容预览'],
           'metadata_only_extensions': [x['extension'] for x in rows if x['status'] == '系统仅基本信息']}
(HERE / 'summary.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n')
fields = ['index', 'extension', 'category', 'status', 'provider', 'actual_uti', 'filename', 'path', 'sha256',
          'verified_at', 'historical_status', 'historical_date', 'historical_source', 'content_check', 'ax_evidence', 'provider_event_ids']
with (HERE / 'file-list.csv').open('w', encoding='utf-8-sig', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=fields, extrasaction='ignore')
    writer.writeheader()
    writer.writerows({**x, 'provider_event_ids': ','.join(map(str, x['provider_event_ids']))} for x in rows)
lines = ['# 371 个后缀：Finder 实际提供器列表', '',
         '2026-10-26，本机当前开发版（包含本轮 SQL 修复），macOS 26.6.2 / Apple Silicon。', '',
         '**已对 371/371 个后缀进行真实 Finder 选择与 Quick Look 预览切换，并对 30 项进行独立关闭重开补测。350 项由 OrangeLen 接管，16 项由系统显示内容，5 项仅显示系统文件信息。**', '',
         '350 项均同时具有 OrangeLen 专属界面、对应后缀的扩展接收日志和成功回调。21 个非 OrangeLen 项均有本轮 Finder 实际 displayBundleID 日志与界面证据。可见正文中的“OrangeLen”测试文字不作为提供器判断依据。', '',
         '**本机原有设置：Hydra 3D 扩展已停用，本轮未改变它；OBJ/STL 结果适用于这一配置。公开 V1.0 安装包没有重新发布或逐项复测，不能把本机结果外推到所有用户。**', '',
         '归属检查不等于完整格式兼容：源码可能只读原文；模型只读元数据；归档本轮验证目录入口，未对每个成员逐项读取；图形未进行全量像素或视觉正确性验收。每后缀一个小型合成样例，不覆盖任意文件、方言、损坏数据或大文件边界。', '',
         '## 系统内容预览：16 项', '', ', '.join('`.' + x['extension'] + '`' for x in rows if x['status'] == '系统内容预览'), '',
         '## 仅系统文件信息：5 项（不能算预览通过）', '',
         '|后缀|实际类型|本轮观察|', '|---|---|---|']
for x in rows:
    if x['status'] != '系统仅基本信息':
        continue
    reason = ('源码被识别为 MPEG 传输流，系统 Movie 提供器只显示文件卡片' if x['extension'] in ('ts', 'mts') else
              '与 Word 模板后缀冲突，本次系统 PDFKit 路径未显示 DOT 图形' if x['extension'] == 'dot' else
              '系统有具体的压缩 TAR 类型，OrangeLen 现有声明未精确覆盖；系统 Generic 仅显示文件卡片')
    lines.append(f"|`.{x['extension']}`|`{x['actual_uti']}`|{reason}|")
lines += ['', '## 全部 371 项', '',
          '每行“证据”为本机完整 Finder AX 记录；日志事件编号见 [provider-events.json](provider-events.json)，完整字段见 [final-results.json](final-results.json)。原始截图和 AX 按仓库规则仅保留本机。CSV 可用 Excel 打开：[file-list.csv](file-list.csv)。', '',
          '|序号|后缀|本轮实际提供器|实际 UTI|本轮文件|证据|', '|---:|---|---|---|---|---|']
for x in rows:
    lines.append(f"|{x['index']}|`.{x['extension']}`|{x['status']}|`{x['actual_uti']}`|`{x['filename']}`|[Finder AX]({x['ax_evidence']}) / 日志 {','.join(map(str,x['provider_event_ids']))}|")
lines += ['', '## OrangeLen 350 项按类别列出', '']
for category in dict.fromkeys(x['category'] for x in rows):
    subset = [x for x in rows if x['status'] == 'OrangeLen' and x['category'] == category]
    if subset:
        lines += [f'### {category}（{len(subset)} 项）', '', ', '.join('`.'+x['extension']+'`' for x in subset), '']
(HERE / 'file-list.md').write_text('\n'.join(lines) + '\n')
print(json.dumps(summary, ensure_ascii=False, indent=2))
