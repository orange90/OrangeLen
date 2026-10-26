"""Validate native research captures without treating the discarded helper as a fix."""
import datetime as dt
import hashlib
import json
from pathlib import Path

HERE=Path(__file__).resolve().parent

def ep(s): return dt.datetime.fromisoformat(s.replace('Z','+00:00')).timestamp()
def jsonl(name): return [json.loads(s) for s in (HERE/name).read_text().splitlines() if s.strip()]
events=[]
for line in (HERE/'runtime.log').read_text().splitlines():
    try:
        x=json.loads(line); msg=x.get('eventMessage','')
        if any(k in msg for k in ('got displayBundleID','prepare received','prepare completed','helper received','helper completed','helper enabled','helper stopped','label-probe received','label-probe completed')):
            events.append({'id':len(events)+1,'timestamp':x['timestamp'],'message':msg,'process_id':x['processID'],'process_path':x['processImagePath']})
    except (ValueError,AttributeError): pass
(HERE/'provider-events.json').write_text(json.dumps(events,ensure_ascii=False,indent=2)+'\n')
rows={r['extension']:r for r in jsonl('unique-label.jsonl')}
manifest=json.loads((HERE/'label-manifest.json').read_text())
assert len(manifest)==len(rows)==12
results=[]
for case in manifest:
    r=rows[case['extension']]
    assert hashlib.sha256(Path(case['path']).read_bytes()).hexdigest()==case['sha256']
    state=(HERE/r['ax']).read_text()
    assert case['filename'] in state and 'window Quick Look' in state
    es=[e for e in events if ep(r['opened_at'])<=ep(e['timestamp'])<=ep(r['captured_at'])+.2]
    providers=[e for e in es if 'got displayBundleID' in e['message']]
    assert providers,case
    if case['extension']=='control':
        assert 'OrangeLen native file-type label diagnostic' in state
        calls=[e for e in es if e['message']=='label-probe received file=00-control']
        assert calls
        assert any(e['message']=='label-probe completed success=true file=00-control' for e in events)
        status='原生标签测试扩展（对照）'
    else:
        assert not r['orangelen']
        assert not any('prepare received' in e['message'] or 'label-probe received' in e['message'] for e in es)
        assert 'OrangeLen native file-type label diagnostic' not in state
        if case['extension'] in ('ts','mts','dot'): assert r['metadata_only']
        status='系统文件信息，未修复' if r['metadata_only'] else '系统正文，接管未解决'
    provider=providers[-1]
    results.append({**case,**r,'status':status,'display_provider':provider['message'].split('got displayBundleID ')[1].split()[0], 'display_event_id':provider['id']})
assert sum(r['metadata_only'] for r in results)==3
(HERE/'native-label-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n')
metadata={r['extension']:r for r in jsonl('metadata-override.jsonl')}
metaresults=[]
for ext,r in metadata.items():
    assert r['metadata_only'] and not r['orangelen']
    es=[e for e in events if ep(r['opened_at'])<=ep(e['timestamp'])<=ep(r['captured_at'])+.2]
    assert not any('prepare received' in e['message'] for e in es)
    providers=[e for e in es if 'got displayBundleID' in e['message']]
    assert providers
    metaresults.append({**r,'display_event_id':providers[-1]['id'],'display_provider':providers[-1]['message'].split('got displayBundleID ')[1].split()[0]})
(HERE/'native-trial-results.json').write_text(json.dumps(metaresults,ensure_ascii=False,indent=2)+'\n')
manual=[]
for ext,needle in [('ts','const answer: number = 42'),('mts','const message'),('dot','Graphviz DOT')]:
    assert needle in (HERE/f'manual-demo-{ext}-ax.txt').read_text()
    calls=[e for e in events if f'trigger=manual-demo type={ext} ' in e['message']]
    assert calls
    call=calls[-1]; request=call['message'].split('request=')[1]
    completed=[e for e in events if 'helper completed' in e['message'] and 'success=true' in e['message'] and f'type={ext} request={request}' in e['message']]
    assert completed
    manual.append({'extension':ext,'trigger':'manual-demo','receive_event_id':call['id'],'success_event_id':completed[-1]['id'],'request_id':request,'process_path':call['process_path'],'ax':f'manual-demo-{ext}-ax.txt','screenshot':f'screenshots/manual-demo-{ext}.png','finder_space_verified':False,'native_extension_verified':False,'adopted':False})
assert not any('helper enabled' in e['message'] or 'trigger=finder-space' in e['message'] for e in events)
(HERE/'manual-demo-results.json').write_text(json.dumps(manual,ensure_ascii=False,indent=2)+'\n')
control=jsonl('restored-control.jsonl')[-1]
assert control['orangelen']
es=[e for e in events if ep(control['opened_at'])<=ep(e['timestamp'])<=ep(control['captured_at'])+.2]
received=[e for e in es if e['message']=='prepare received extension=OrangeLen type=sql']
assert received and all(e['process_path'].startswith('/Applications/OrangeLen.app/Contents/PlugIns/') for e in received)
assert any(e['message']=='prepare completed success=true' and e['process_id']==received[-1]['process_id'] for e in es)
summary={'date':'2026-10-26','machine':'macOS 26.6.2 (25G83), arm64','native_newly_fixed':0,'native_label_cases':11,'native_label_control_passed':True,
         'remaining_metadata_only':['ts','mts','dot'],'remaining_system_content':['html','htm','xhtml','txt','pdf','csv','svg','text'],
         'resource_type_setter_succeeded_but_actual_types_unchanged':3,'spotlight_metadata_override_failed':3,
         'helper_build':'success','helper_manual_rendering_verified':['ts','mts','dot'],'helper_space_enabled':False,'finder_space_helper_verified':False,
         'user_choice':'Native Quick Look extensions only; helper rejected, exited and unregistered','diagnostic_native_extension_unregistered':True,
         'production_sql_control_passed':True,'installed_product_changed':False,'system_preferences_changed_this_turn':False,'published_release_updated':False}
(HERE/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
p=HERE/'README.md';s=p.read_text();s=s.replace('本轮尚未新增任何已验收的 Finder 空格接管修复。','**本轮新增原生修复 0 项；剩余 11 项仍未解决。** 用户明确限定只接受原生 Quick Look 扩展。')
s=s.replace('原型程序仅在本机 `build/remaining11-research/finder-helper/DerivedData/Build/Products/Debug/FinderSpaceHelper.app`，没有安装到 Applications 或发布。','辅助原型未安装到 Applications 或发布，已退出并注销；可执行 app 已归档，不再处于可发现的 `.app` 路径。')
section=['','## 专用 OSType 标签原生实测','',
         '独立构建签名的原生 `.appex`，宿主导出 `local.orangelen.native-source-label`，仅绑定独有四字符文件类型 `OLSc`，不抢占 TS/MTS 等后缀。所有写标签操作仅发生在新建测试副本。','',
         '无后缀控制文件被正确识别为该新类型，Finder 空格出现专属诊断正文，且有 `label-probe received` / `completed success=true`。同样的标签加到其余 11 个原后缀，实际 UTI 均不变；Finder 空格仍由系统提供内容或文件卡片。这排除了“通用 TEXT 标签过于宽泛”的解释。','',
         '见 [类型查询](unique-label-types.tsv)、[样例哈希](label-manifest.json)、[逐项结果](native-label-results.json)、[原生扩展源码](native-label-probe/Provider.swift) 及 [宿主/扩展声明](native-label-probe/project.yml)。该扩展用于验证标签选型，不把诊断正文计作正式 OrangeLen 产品修复。','',
         '|后缀|Finder 实际显示提供器|最终界面|日志事件|证据|','|---|---|---|---|---|']
for r in results:
    section.append(f"|`{'.'+r['extension'] if r['extension']!='control' else '无后缀对照'}`|`{r['display_provider']}`|{r['status']}|{r['display_event_id']}|[AX]({r['ax']}) / [截图]({r['screenshot']})|")
section += ['', '## 清理与恢复检查','',
            '原生标签测试扩展已从 PluginKit 注销，测试宿主已从 Launch Services 注销并移出 `.app` 路径；辅助原型同样已退出并注销，始终未启用空格监听或请求辅助功能授权。生产应用及系统文件均未改动。',
            '两处生产 OrangeLen 安装的 deep/strict 签名检查通过。既有 Hydra / Shortcuts 为 ignore、系统桥接为 default，本轮未修改这些偏好。清理后 SQL 再次 Finder 空格显示正式 OrangeLen 控件与正文，`/Applications/OrangeLen.app` 的 Code 扩展接收并成功回调；日志索引见 [provider-events.json](provider-events.json)。',
            '本机生成器按时间窗口复核真实 Finder 提供器和正反例，运行 `python3 docs/evidence/remaining11-2026-10-26/build-report.py` 可重建结构化结果。原始日志、AX、截图仅保留本机。',
            '当前结论仅为这些已测试原生路径在本机失败，不声称所有未来系统或一切可能方案均不可能。没有可交付且符合“原始后缀 + 原生 Quick Look 扩展”要求的新修复。','']
# Regeneration replaces this generated section, leaving the authored investigation intact.
if '\n## 专用 OSType 标签原生实测\n' in s:s=s.split('\n## 专用 OSType 标签原生实测\n')[0]
p.write_text(s+'\n'.join(section))
print(json.dumps(summary,ensure_ascii=False,indent=2))
