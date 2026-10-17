#!/usr/bin/env python3
"""Keep source suffix declarations in project.yml aligned with the registry.

Does not rewrite unrelated XcodeGen configuration or historical test reports.
Run xcodegen generate after applying changes. --check is read-only.
"""
import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / 'Packages/OrangeLen/Sources/OrangeLenCore/Resources/SourceCodeFormats.json'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    manifest = json.loads(REGISTRY.read_text())
    all_extensions = [ext for group in manifest['groups'].values() for ext in group]
    assert len(set(all_extensions)) == len(all_extensions), 'Duplicate source suffix'
    project = ROOT / 'project.yml'
    old = project.read_text()
    source = old
    pattern = r'(UTTypeIdentifier: local\.orangelen\.developer-source\n(?:(?!UTTypeIdentifier:).)*?public\.filename-extension: )\[([^\n]+)\]'
    match = re.search(pattern, source, flags=re.DOTALL)
    assert match, 'Missing developer-source declaration'
    current = set(re.findall(r'[a-zA-Z0-9+_-]+', match.group(2)))
    extensions = sorted(current | set(all_extensions))
    source = source[:match.start()] + match.group(1) + json.dumps(extensions) + source[match.end():]
    pattern = r'(QLSupportedContentTypes: )\[([^\n]+)\]'
    match = re.search(pattern, source)
    assert match, 'Missing Code Quick Look content types'
    # Preserve order of existing types and add concrete aliases captured in the
    # registry. Never register broad public.data or public.item as catch-alls.
    types = re.findall(r'[a-zA-Z0-9._-]+', match.group(2))
    for type_id in manifest['contentTypes']:
        if type_id not in types:
            types.append(type_id)
    source = source[:match.start()] + match.group(1) + '[' + ', '.join(types) + ']' + source[match.end():]
    if args.check:
        assert source == old, 'Run scripts/sync-source-formats.py and xcodegen generate'
    else:
        project.write_text(source)
    print(f'{len(all_extensions)} registry suffixes; {len(extensions)} declared source aliases; {len(types)} Code content types')


if __name__ == '__main__':
    main()
