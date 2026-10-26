#!/usr/bin/env python3
"""Audit suffix registration using only the product and macOS CoreTypes.

Never query UTType/Launch Services: installed developer tools can hide missing
declarations. This checks declaration coverage, not Finder provider selection.
"""
import argparse
import json
from pathlib import Path
import plistlib
import re

ROOT = Path(__file__).resolve().parents[1]
CORE_TYPES = Path('/System/Library/CoreServices/CoreTypes.bundle')


def declarations(paths):
    result = []
    for path in sorted(paths):
        info = plistlib.loads(path.read_bytes())
        for key in ('UTExportedTypeDeclarations', 'UTImportedTypeDeclarations'):
            for item in info.get(key, []):
                result.append(dict(item, source=str(path)))
    return result


def values(value):
    return [value] if isinstance(value, str) else value


def inventory(path):
    text = path.read_text()
    extensions = set()
    for line in text.splitlines():
        if line.startswith('|'):
            extensions.update(re.findall(r'`\.([^`]+)`', line))
    expected = int(re.search(r'\*\*(\d+) unique extensions', text)[1])
    if len(extensions) != expected:
        raise ValueError(f'Inventory count mismatch: {len(extensions)} != {expected}')
    return sorted(extensions)


def audit(extensions, product, system, previews):
    def by_suffix(items):
        result = {}
        for item in items:
            tags = item.get('UTTypeTagSpecification', {})
            for ext in values(tags.get('public.filename-extension', [])):
                result.setdefault(ext.lower(), set()).add(item['UTTypeIdentifier'])
        return result

    own = by_suffix(product)
    builtin = by_suffix(system)
    parents = {}
    for item in system + product:
        parents.setdefault(item['UTTypeIdentifier'], set()).update(values(item.get('UTTypeConformsTo', [])))

    def ancestors(identifier):
        seen, pending = set(), [identifier]
        while pending:
            current = pending.pop()
            if current in seen:
                continue
            seen.add(current)
            pending.extend(parents.get(current, []))
        return seen

    rows = []
    for ext in sorted(extensions):
        own_types, system_types = own.get(ext, set()), builtin.get(ext, set())
        types = own_types | system_types
        known = set().union(*(ancestors(t) for t in types)) if types else set()
        rows.append({
            'extension': ext,
            'coverage': 'app' if own_types else 'core-types' if system_types else 'missing',
            'appTypes': sorted(own_types),
            'coreTypes': sorted(system_types),
            'previewCandidates': sorted(name for name, supported in previews.items() if known.intersection(supported)),
        })
    # Even a declared suffix can depend on a parent supplied only by another app.
    parent_gaps = {}
    for item in product:
        unknown = ancestors(item['UTTypeIdentifier']) - parents.keys()
        if unknown:
            parent_gaps[item['UTTypeIdentifier']] = sorted(unknown)
    return {
        'scope': 'Product declarations plus this OS CoreTypes; excludes Xcode and other apps, including Notes.',
        'finderVerified': False,
        'counts': {k: sum(r['coverage'] == k for r in rows) for k in ('app', 'core-types', 'missing')},
        'missingExtensions': [r['extension'] for r in rows if r['coverage'] == 'missing'],
        'extensionsWithoutPreviewCandidate': [r['extension'] for r in rows if not r['previewCandidates']],
        'unresolvedProductParents': parent_gaps,
        'rows': rows,
    }


def inspect_product(app=None):
    if app:
        app_info = app / 'Contents/Info.plist'
        preview_paths = sorted((app / 'Contents/PlugIns').glob('*.appex/Contents/Info.plist'))
    else:
        app_info = ROOT / 'App/Info.plist'
        preview_paths = [ROOT / 'PreviewExtension/Info.plist'] + sorted((ROOT / 'PreviewExtension/Generated').glob('*-Info.plist'))
    if len(preview_paths) != 7:
        raise ValueError(f'Expected seven preview extensions, found {len(preview_paths)}')
    previews = {}
    for path in preview_paths:
        info = plistlib.loads(path.read_bytes())
        previews[info['OrangeLenPreviewCategory']] = info['NSExtension']['NSExtensionAttributes']['QLSupportedContentTypes']
    system_paths = list(CORE_TYPES.rglob('Info.plist'))
    if not system_paths:
        raise ValueError('macOS CoreTypes declarations unavailable; cannot establish a system baseline')
    report = audit(inventory(ROOT / 'docs/format-count.md'), declarations([app_info]), declarations(system_paths), previews)
    report['appInfo'] = str(app_info)
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--app', type=Path, help='Inspect a built app; otherwise inspect generated source plists')
    parser.add_argument('--output', type=Path, help='Save the complete per-extension JSON report')
    args = parser.parse_args()
    report = inspect_product(args.app)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({k: v for k, v in report.items() if k != 'rows'}, indent=2))
    return 1 if (report['missingExtensions'] or report['unresolvedProductParents']
                 or report['extensionsWithoutPreviewCandidate']) else 0


if __name__ == '__main__':
    raise SystemExit(main())
