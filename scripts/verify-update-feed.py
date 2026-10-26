#!/usr/bin/env python3
"""Validate release routing/metadata; Sparkle validates archive signatures at runtime."""
import argparse
import base64
from pathlib import Path
import plistlib
import xml.etree.ElementTree as ET

SPARKLE = "{http://www.andymatuschak.org/xml-namespaces/sparkle}"
FEED_URL = "https://github.com/orange90/OrangeLen/releases/latest/download/appcast.xml"


def validate(feed, info, archive):
    if info.get("SUFeedURL") != FEED_URL:
        raise ValueError("Unexpected update feed URL")
    if len(base64.b64decode(info.get("SUPublicEDKey", ""), validate=True)) != 32:
        raise ValueError("Missing or invalid Sparkle public key")
    items = ET.parse(feed).getroot().findall("channel/item")
    if len(items) != 1:
        raise ValueError("Expected exactly one current release")
    item = items[0]
    version = info["CFBundleShortVersionString"]
    if item.findtext(SPARKLE + "version") != info["CFBundleVersion"]:
        raise ValueError("Appcast build does not match packaged app")
    if item.findtext(SPARKLE + "shortVersionString") != version:
        raise ValueError("Appcast version does not match packaged app")
    if item.findtext(SPARKLE + "minimumSystemVersion") != info["LSMinimumSystemVersion"]:
        raise ValueError("Appcast minimum macOS does not match packaged app")
    enclosure = item.find("enclosure")
    expected = f"https://github.com/orange90/OrangeLen/releases/download/V{version}/{archive.name}"
    if enclosure is None or enclosure.get("url") != expected:
        raise ValueError("Archive must use the immutable versioned GitHub Release URL")
    if int(enclosure.get("length", "0")) != archive.stat().st_size:
        raise ValueError("Archive size mismatch")
    if len(base64.b64decode(enclosure.get(SPARKLE + "edSignature", ""), validate=True)) != 64:
        raise ValueError("Missing or malformed archive signature")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("feed", type=Path)
    parser.add_argument("--app", required=True, type=Path)
    parser.add_argument("--archive", required=True, type=Path)
    args = parser.parse_args()
    with (args.app / "Contents/Info.plist").open("rb") as handle:
        validate(args.feed, plistlib.load(handle), args.archive)
    print("Update feed metadata verified; archive signature is enforced by Sparkle.")
