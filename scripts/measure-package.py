#!/usr/bin/env python3
"""Measure app size; compare engine/font bytes and localization values."""
import argparse
import importlib.util
import json
from pathlib import Path

spec = importlib.util.spec_from_file_location("packaging", Path(__file__).with_name("deduplicate-resources.py"))
packaging = importlib.util.module_from_spec(spec)
spec.loader.exec_module(packaging)


def measure(app):
    files = [p for p in app.rglob("*") if p.is_file() and not p.is_symlink()]
    legacy, original = {}, {}
    for name in packaging.RESOURCE_BUNDLES:
        copies = list(app.rglob(name))
        legacy[name] = len(copies)
        if copies:
            part = packaging.payload(copies[0] / "Contents/Resources")
            if original.keys() & part.keys():
                raise ValueError("Overlapping resource names")
            original.update(part)
    frameworks = list(app.rglob("OrangeLenResources.framework"))
    if frameworks:
        _, resources = packaging.framework_resources(app)
        content = packaging.payload(resources)
        shared_bytes = sum(p.stat().st_size for p in resources.rglob("*") if p.is_file())
    else:
        content, shared_bytes = original, 0
    return {"logicalBytes": sum(p.stat().st_size for p in files),
            "legacyBundleCopies": legacy, "sharedFrameworkCopies": len(frameworks),
            "sharedResourceBytes": shared_bytes, "payload": content}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", type=Path)
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--allow-resource-change", action="append", default=[])
    args = parser.parse_args()
    report = {"product": measure(args.app)}
    packaging.consolidate(args.app, verify_only=True)
    if args.baseline:
        report["baseline"] = measure(args.baseline)
        before, after = report["baseline"]["payload"], report["product"]["payload"]
        if before.keys() != after.keys():
            raise ValueError("Resource files were added or removed")
        changed = sorted(name for name in before if before[name] != after[name])
        if set(changed) != set(args.allow_resource_change):
            raise ValueError(f"Unexpected resource content changes: {changed}")
        report["intentionallyUpdatedResources"] = changed
        report["savedBytes"] = report["baseline"]["logicalBytes"] - report["product"]["logicalBytes"]
    text = json.dumps(report, indent=2) + "\n"
    print(text, end="")
    if args.output:
        args.output.write_text(text)


if __name__ == "__main__":
    main()
