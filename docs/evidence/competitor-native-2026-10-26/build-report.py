"""Correlate real Finder Space captures with provider entry and completion logs.

Raw OS logs, AX dumps, screenshots and fixture copies are local evidence, ignored
by Git. This script validates those inputs and writes the reviewable summaries.
"""
import datetime as dt
import hashlib
import json
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
TARGETS = ['ts', 'mts', 'dot', 'html', 'htm', 'xhtml', 'txt', 'pdf', 'csv', 'svg', 'text']


def read(name):
    return json.loads((HERE / name).read_text())


def write(name, value):
    (HERE / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def epoch(value):
    return dt.datetime.fromisoformat(value.replace('Z', '+00:00')).timestamp()


def latest(name):
    rows = [json.loads(s) for s in (HERE / name).read_text().splitlines() if s.strip()]
    return {r['extension']: r for r in rows}


events_by_key = {}
markers = ('got displayBundleID', 'prepare received', 'prepare completed',
           'audit received', 'audit completed', 'Preview request:',
           'HTML built for', 'Highlight succeeded')
for filename in ['runtime.log', 'dotviewer-runtime.log']:
    for line in (HERE / filename).read_text().splitlines():
        try:
            record = json.loads(line)
        except ValueError:
            continue
        message = record.get('eventMessage', '')
        if not any(marker in message for marker in markers):
            continue
        event = dict(timestamp=record['timestamp'], message=message,
                     subsystem=record.get('subsystem'), process_id=record.get('processID'),
                     process_path=record.get('processImagePath'))
        events_by_key[(event['timestamp'], event['process_id'], message)] = event
events = sorted(events_by_key.values(), key=lambda e: epoch(e['timestamp']))
for index, event in enumerate(events, 1):
    event['id'] = index
write('provider-events.json', events)


def window(capture):
    return [e for e in events if epoch(capture['opened_at']) <= epoch(e['timestamp'])
            <= epoch(capture['captured_at']) + .1]


def actual_requests(es):
    return [e for e in es if any(s in e['message'] for s in
            ('prepare received', 'audit received', 'Preview request:'))]


manifest = {r['extension']: r for r in read('manifest.json')}
for case in manifest.values():
    assert hashlib.sha256(Path(case['path']).read_bytes()).hexdigest() == case['sha256']

results = []
controls = []
for run, control_ext in [('pique', 'vpptoken'), ('dotviewer', 'mud')]:
    captures = latest(run + '.jsonl')
    assert set(captures) == set(TARGETS + [control_ext])
    for ext in [control_ext] + TARGETS:
        cap = captures[ext]
        case = manifest[ext]
        state = (HERE / cap['ax']).read_text()
        assert 'window Quick Look' in state and case['filename'] in state
        es = window(cap)
        providers = [e for e in es if 'got displayBundleID' in e['message']]
        assert len(providers) == 1, (run, ext, providers)
        assert not cap['orangelen']
        requests = actual_requests(es)
        if ext == control_ext:
            if run == 'pique':
                assert any(e['message'] == 'audit received plugin=Pique file=00-control.vpptoken'
                           for e in requests)
                assert any(e['message'] == 'audit completed plugin=Pique success=true file=00-control.vpptoken'
                           for e in es)
                assert 'OrangeLen Pique control' in state and 'synthetic-test-token' in state
                owner = 'Pique native preview extension'
            else:
                assert any(e['message'] == 'Preview request: 00-control.mud ext=mud key=mud'
                           for e in requests)
                assert any(e['message'] == 'HTML built for 00-control.mud' for e in es)
                assert 'Lisp 1 lines' in state and 'native-control' in state
                owner = 'dotViewer native preview extension'
            assert not cap['metadata_only']
        else:
            assert not requests, (run, ext, requests)
            assert cap['metadata_only'] == (ext in ['ts', 'mts', 'dot'])
            owner = 'system metadata only' if cap['metadata_only'] else 'system content preview'
        result = dict(**case, **{k: v for k, v in cap.items() if k not in case},
                      owner=owner, actual_request_event_ids=[e['id'] for e in requests],
                      display_event_id=providers[0]['id'],
                      display_bundle=providers[0]['message'].split('got displayBundleID ')[1].split()[0])
        (controls if ext == control_ext else results).append(result)

sql = latest('production.jsonl')['sql']
state = (HERE / sql['ax']).read_text()
es = window(sql)
requests = actual_requests(es)
assert sql['orangelen'] and not sql['metadata_only'] and 'Display Settings' in state
assert len(requests) == 1
assert requests[0]['message'] == 'prepare received extension=OrangeLen type=sql'
assert requests[0]['process_path'].startswith('/Applications/OrangeLen.app/Contents/PlugIns/')
assert any(e['message'] == 'prepare completed success=true'
           and e['process_id'] == requests[0]['process_id'] for e in es)
controls.append(dict(**sql, owner='OrangeLen production native extension',
                     actual_request_event_ids=[e['id'] for e in requests]))


def registry(filename):
    entries = {}
    for line in (HERE / filename).read_text().splitlines():
        m = re.match(r'^([+\- ])\s+([^\s(]+)\([^)]*\)\s+([A-F0-9-]{36})\s+', line)
        if m:
            entries[m[2]] = (m[1], m[3])
    return entries


before, after = registry('registry-before.txt'), registry('registry-after.txt')
assert len(before) == len(after) == 26
assert before == after
assert not any('dotViewer' in key or 'pique' in key for key in after)
write('results.json', results)
write('controls.json', controls)
summary = dict(date='2026-10-26', baseline_commit=read('experiment.json')['baseline_commit'],
               machine='macOS 26.6.2 (25G83), arm64', real_finder_target_cases=len(results),
               native_competitor_controls_passed=2, production_sql_control_passed=True,
               original_suffixes_repaired=0, target_provider_requests=0,
               remaining_metadata_only=['ts', 'mts', 'dot'],
               remaining_system_content=TARGETS[3:],
               registry_elections_unchanged=True, comparison_extensions_unregistered=True,
               helper_enabled=False, product_code_changed=False,
               scope='Two comparison builds on this Mac; not an impossibility proof for all native approaches.')
write('summary.json', summary)
table = ['# 两款插件的 Finder 空格逐项对照', '',
         '归属结合真实入口日志与界面判断。Web2 也能显示第三方生成的 HTML，不能单凭显示 bundle 判断生成者。', '',
         '|插件|后缀|真实入口事件|显示 bundle|最终界面|证据|',
         '|---|---|---|---|---|---|']
for r in controls[:2] + results:
    ids = ', '.join(map(str, r['actual_request_event_ids'])) or '无'
    table.append(f"|{r['run']}|`.{r['extension']}`|{ids}|`{r['display_bundle']}`|{r['owner']}|[AX]({r['ax']}) / [截图]({r['screenshot']})|")
(HERE / 'file-list.md').write_text('\n'.join(table).rstrip() + '\n')
print(json.dumps(summary, ensure_ascii=False, indent=2))
