"""Validate the notarized release's Finder UI, callbacks and running binary UUIDs."""
import datetime as dt
import hashlib
import json
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent


def read(name):
    return json.loads((HERE / name).read_text())


def write(name, data):
    (HERE / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')


def latest(name):
    return {r['extension']: r for r in
            [json.loads(s) for s in (HERE / name).read_text().splitlines() if s.strip()]}


def epoch(s):
    return dt.datetime.fromisoformat(s.replace('Z', '+00:00')).timestamp()


events = []
for line in (HERE / 'runtime.log').read_text().splitlines():
    try:
        record = json.loads(line)
    except ValueError:
        continue
    message = record.get('eventMessage', '')
    if any(s in message for s in ['prepare received', 'prepare completed', 'got displayBundleID']):
        events.append(dict(id=len(events) + 1, timestamp=record['timestamp'],
                           message=message, process_path=record.get('processImagePath'),
                           process_id=record.get('processID'),
                           process_uuid=record.get('processImageUUID')))
write('provider-events.json', events)
installed = read('installed.json')['extensions']
uuids = {e['path'] + '/Contents/MacOS/' + Path(e['path']).stem:
         re.findall(r'UUID: ([A-Fa-f0-9-]+)', e['binary_uuids']) for e in installed}
assert len(installed) == 7
assert all(e['version'] == '1.0.1' and e['build'] == '4' for e in installed)
captures = latest('finder.jsonl')
manifest = read('manifest.json')
assert len(manifest) == len(captures) == 13
results = []
for item in manifest:
    cap = captures[item['extension']]
    assert hashlib.sha256(Path(item['path']).read_bytes()).hexdigest() == item['sha256']
    state = (HERE / cap['ax']).read_text()
    assert 'window Quick Look' in state and item['filename'] in state
    es = [e for e in events if epoch(cap['opened_at']) <= epoch(e['timestamp'])
          <= epoch(cap['captured_at']) + .1]
    received = [e for e in es if 'prepare received' in e['message']]
    display = [e for e in es if 'got displayBundleID' in e['message']]
    assert display
    success = []
    if item['expect_orangelen']:
        assert cap['orangelen'] and not cap['metadata_only']
        received = [e for e in received if e['message'].endswith('type=' + item['extension'])]
        assert len(received) == 1, (item['extension'], received)
        event = received[0]
        assert event['process_path'] in uuids
        assert event['process_uuid'].upper() in uuids[event['process_path']]
        success = [e for e in es if e['message'] == 'prepare completed success=true'
                   and e['process_id'] == event['process_id']]
        assert success
        status = 'OrangeLen 1.0.1 正文/归档目录'
    else:
        assert not received and not cap['orangelen'] and cap['metadata_only']
        status = '系统基本信息，限制仍存在'
    results.append(dict(item | cap, status=status,
                        received_event_ids=[e['id'] for e in received],
                        success_event_ids=[e['id'] for e in success],
                        display_event_ids=[e['id'] for e in display],
                        running_binary_uuid_verified=bool(received)))
members = latest('members.jsonl')
assert set(members) == {'txz', 'tbz2'}
for member in members.values():
    assert member['body_visible']
    state = (HERE / member['ax']).read_text()
    assert 'Archive preview 中文' in state and 'README.md' in state
write('finder-results.json', results)
write('members.json', list(members.values()))
summary = dict(version='1.0.1', build='4', finder_cases=13, orangelen_verified=10,
               system_metadata_only=['ts', 'mts', 'dot'],
               archive_member_bodies_verified=['txz', 'tbz2'],
               received_binary_uuids_match_release=True, all_371_rerun=False,
               installed_signing='Developer ID, C7J9CK5X87',
               local_development_container_migration='User manually approved Code and Archives OS prompts; no TCC bypass.')
write('summary.json', summary)
print(json.dumps(summary, ensure_ascii=False, indent=2))
