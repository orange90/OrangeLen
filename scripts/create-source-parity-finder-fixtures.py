#!/usr/bin/env python3
"""Prepare numbered synthetic files for real Finder Space verification.

This creates fixtures only. It does not drive Finder or claim UI test results.
Run create-source-parity-fixtures.py first; use CUA for the actual UI audit.
"""
import datetime
import hashlib
import json
import plistlib
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'Tests/Fixtures/source-parity'
DEST = ROOT / 'Tests/Fixtures/source-parity-finder'
FALLBACK = ROOT / 'Tests/Fixtures/source-parity-finder-fallback'
EVIDENCE = ROOT / 'docs/evidence/source-parity-finder-2026-10-16'


def main():
    coverage = json.loads((ROOT / 'docs/evidence/source-parity-2026-10-16/coverage.json').read_text())
    extensions = coverage['new_extensions']
    assert len(extensions) == 215 and len(set(extensions)) == 215
    DEST.mkdir(exist_ok=True)
    FALLBACK.mkdir(exist_ok=True)
    EVIDENCE.mkdir(exist_ok=True)
    cases = []
    for index, ext in enumerate(extensions, 1):
        source = SOURCE / ('sample.' + ext)
        if ext in ('scpt', 'ascr', 'applescript'):
            source = SOURCE / 'compiled.scpt'
        elif ext in ('loctable', 'wflow', 'strings', 'stringsdict', 'entitlements', 'a3x'):
            source = SOURCE / ('binary.' + ext)
        if not source.is_file():
            raise SystemExit(f'Missing {source}; run scripts/create-source-parity-fixtures.py first')
        name = f'{index:03d}-{ext}.{ext}'
        target = DEST / name
        shutil.copyfile(source, target)
        cases.append({'index': index, 'extension': ext, 'filename': name,
                      'source': str(source.relative_to(ROOT)),
                      'sha256': hashlib.sha256(target.read_bytes()).hexdigest()})
    shutil.copyfile(DEST / '187-text.text', FALLBACK / 'plain.text')
    shutil.copyfile(DEST / '203-wflow.wflow', FALLBACK / 'binary.wflow')
    # A generic plist has no Shortcuts actions. This additional, workflow-shaped
    # fixture distinguishes native-provider selection from a rendering failure.
    workflow = {
        'WFWorkflowActions': [{'WFWorkflowActionIdentifier': 'is.workflow.actions.gettext',
                               'WFWorkflowActionParameters': {'WFTextActionText': 'OrangeLen workflow 中文🍊'}}],
        'WFWorkflowClientVersion': '4100', 'WFWorkflowClientRelease': '7.0',
        'WFWorkflowMinimumClientVersion': 900, 'WFWorkflowTypes': [],
        'WFWorkflowInputContentItemClasses': ['WFStringContentItem'], 'WFWorkflowImportQuestions': []}
    (FALLBACK / 'actual-workflow.wflow').write_bytes(plistlib.dumps(workflow, fmt=plistlib.FMT_BINARY))
    manifest = {'created': datetime.datetime.now().astimezone().isoformat(), 'count': len(cases),
                'fixtures': str(DEST), 'cases': cases}
    # Preserve completed UI evidence when merely regenerating its inputs.
    manifest_path = EVIDENCE / 'audit-manifest.json'
    if manifest_path.exists():
        previous = json.loads(manifest_path.read_text())
        assert [(r['filename'], r['sha256']) for r in previous['cases']] == [(r['filename'], r['sha256']) for r in cases], 'Fixtures differ from the recorded UI audit; create a separate evidence directory'
    else:
        manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    print(f'Prepared {len(cases)} numbered files and 3 fallback/control files. No UI tests were run.')


if __name__ == '__main__':
    main()
