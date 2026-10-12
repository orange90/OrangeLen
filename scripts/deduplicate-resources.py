#!/usr/bin/env python3
"""Verify all resource content, then remove redundant SwiftPM bundles.
The containing app keeps one standard embedded OrangeLenResources.framework.
Renderer/font bytes and localization key/value pairs must match before removal.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess

RESOURCE_BUNDLES = ("OrangeLen_OrangeLenCore.bundle", "OrangeLen_OrangeLenUI.bundle")
MANIFEST_NAME = "OrangeLenResourceManifest.json"


def inventory(root):
    result = {}
    for path in sorted(root.rglob("*")):
        if path.is_symlink():
            raise ValueError(f"Unexpected resource symlink: {path}")
        if path.is_file():
            result[str(path.relative_to(root))] = hashlib.sha256(path.read_bytes()).hexdigest()
    if not result:
        raise ValueError(f"Empty resources: {root}")
    return result


def payload(root):
    result = {}
    for path in sorted(root.rglob("*")):
        if path.is_symlink():
            raise ValueError(f"Unexpected resource symlink: {path}")
        if not path.is_file() or path.name in ("Info.plist", MANIFEST_NAME):
            continue
        relative = path.relative_to(root)
        key = "/".join(part.lower() if part.endswith(".lproj") else part for part in relative.parts)
        data = path.read_bytes()
        if path.suffix == ".strings":
            values = plistlib.loads(subprocess.check_output(["/usr/bin/plutil", "-convert", "xml1", "-o", "-", str(path)]))
            if not isinstance(values, dict) or not all(isinstance(k, str) and isinstance(v, str) for k, v in values.items()):
                raise ValueError(f"Invalid localization dictionary: {path}")
            data = json.dumps(values, sort_keys=True, ensure_ascii=False).encode("utf-8")
        if key in result:
            raise ValueError(f"Conflicting resource names: {key}")
        result[key] = hashlib.sha256(data).hexdigest()
    if not result:
        raise ValueError(f"Empty resource payload: {root}")
    return result


def framework_resources(app):
    framework = app / "Contents/Frameworks/OrangeLenResources.framework"
    resources = (framework / "Resources").resolve()
    if not resources.is_relative_to(app.resolve()) or not resources.is_dir():
        raise ValueError("Missing embedded resource framework")
    with (resources / "Info.plist").open("rb") as handle:
        if plistlib.load(handle).get("CFBundleIdentifier") != "local.OrangeLen.Resources":
            raise ValueError("Unexpected resource framework")
    return framework, resources


def consolidate(app, verify_only=False, sign=True):
    if app.is_symlink() or not app.is_dir() or app.suffix != ".app":
        raise ValueError("Expected a built application directory")
    app = app.resolve()
    with (app / "Contents/Info.plist").open("rb") as handle:
        if plistlib.load(handle).get("CFBundleIdentifier") != "local.OrangeLen":
            raise ValueError("Only the OrangeLen product can be consolidated")
    framework, resources = framework_resources(app)
    manifest_file = resources / MANIFEST_NAME
    plans, expected, owners = [], {}, set()
    for name in RESOURCE_BUNDLES:
        copies = sorted(app.rglob(name))
        if copies:
            original = payload(copies[0] / "Contents/Resources")
            for duplicate in copies:
                if duplicate.is_symlink() or payload(duplicate / "Contents/Resources") != original:
                    raise ValueError(f"Resource inventory differs; refusing removal: {duplicate}")
                plans.append(duplicate)
                for ancestor in duplicate.parents:
                    if ancestor == app:
                        break
                    if ancestor.suffix in (".xpc", ".appex"):
                        owners.add(ancestor)
            if set(expected) & set(original):
                raise ValueError("Resource names overlap between packages")
            expected.update(original)
    actual = payload(resources)
    if expected:
        if actual != expected:
            raise ValueError(f"Shared framework payload differs; missing={sorted(expected.keys()-actual.keys())}, extra={sorted(actual.keys()-expected.keys())}, changed={sorted(k for k in expected.keys() & actual.keys() if expected[k] != actual[k])}")
    else:
        if not manifest_file.is_file():
            raise ValueError("No original resource bundles or preservation manifest")
        expected = json.loads(manifest_file.read_text())["payload"]
        if actual != expected:
            raise ValueError("Shared resources differ from the preservation manifest")
    if verify_only and plans:
        raise ValueError(f"Product still contains {len(plans)} duplicate bundles")
    removed_bytes = sum(path.stat().st_size for bundle in plans for path in bundle.rglob("*") if path.is_file())
    if not verify_only:
        # Verification of every bundle and the full shared payload is complete.
        manifest_file.write_text(json.dumps({"payload": expected}, indent=2) + "\n")
        for bundle in plans:
            shutil.rmtree(bundle)
        if sign and os.environ.get("CODE_SIGNING_ALLOWED", "YES") != "NO":
            identity = os.environ.get("EXPANDED_CODE_SIGN_IDENTITY") or os.environ.get("CODE_SIGN_IDENTITY") or "-"
            # The framework manifest changed its seal. Preserve runtime flags;
            # changed nested XPC/appex seals are rebuilt deepest first.
            for owner in [framework] + sorted(owners, key=lambda path: len(path.parts), reverse=True):
                subprocess.run(["/usr/bin/codesign", "--force", "--sign", identity,
                    "--preserve-metadata=identifier,entitlements,flags", "--timestamp=none", str(owner)], check=True)
    if any(list(app.rglob(name)) for name in RESOURCE_BUNDLES):
        raise ValueError("Redundant package resource bundle remains")
    if payload(resources) != expected:
        raise ValueError("Canonical resource content changed")
    return {"removedBundles": len(plans), "removedBytes": removed_bytes,
            "payload": expected, "sharedFrameworkCopies": len(list(app.rglob("OrangeLenResources.framework")))}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", type=Path)
    parser.add_argument("--verify-only", action="store_true")
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    report = consolidate(args.app, verify_only=args.verify_only)
    if report["sharedFrameworkCopies"] != 1:
        raise ValueError("Expected exactly one resource framework")
    if args.report:
        args.report.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Package resources: one shared framework; removed {report['removedBundles']} package bundles / {report['removedBytes'] / 2**20:.2f} MiB")


if __name__ == "__main__":
    main()
