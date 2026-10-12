import importlib.util
from pathlib import Path
import plistlib
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("packaging", Path(__file__).resolve().parents[1] / "deduplicate-resources.py")
packaging = importlib.util.module_from_spec(spec)
spec.loader.exec_module(packaging)


class ResourcePackagingTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.app = Path(self.temporary.name) / "OrangeLen.app"
        (self.app / "Contents").mkdir(parents=True)
        (self.app / "Contents/Info.plist").write_bytes(plistlib.dumps({"CFBundleIdentifier": "local.OrangeLen"}))
        self.shared = self.app / "Contents/Frameworks/OrangeLenResources.framework/Resources"
        self.shared.mkdir(parents=True)
        (self.shared / "Info.plist").write_bytes(plistlib.dumps({"CFBundleIdentifier": "local.OrangeLen.Resources"}))
        self.copies = []
        for resource in packaging.RESOURCE_BUNDLES:
            data = plistlib.dumps({"title": "Preview"}) if "Core" in resource else bytes(range(256))
            relative = "en.lproj/Localizable.strings" if "Core" in resource else "renderer.bin"
            destination = self.shared / relative
            destination.parent.mkdir(exist_ok=True)
            destination.write_bytes(data)
            for parent in ("Contents/Resources", "Contents/PlugIns/Code.appex/Contents/Resources",
                           "Contents/PlugIns/Folders.appex/Contents/Resources"):
                bundle = self.app / parent / resource
                path = bundle / "Contents/Resources" / relative
                path.parent.mkdir(parents=True)
                path.write_bytes(data)
                self.copies.append(bundle)

    def testConsolidatesWithoutChangingAnyResourceAndIsIdempotent(self):
        expected = packaging.payload(self.shared)
        report = packaging.consolidate(self.app, sign=False)
        self.assertEqual(report["removedBundles"], 6)
        self.assertEqual(report["payload"], expected)
        self.assertEqual(packaging.payload(self.shared), expected)
        self.assertEqual(packaging.consolidate(self.app, sign=False)["removedBundles"], 0)
        packaging.consolidate(self.app, verify_only=True)

    def testMismatchRefusesAllRemovals(self):
        (self.copies[-1] / "Contents/Resources/extra-font.otf").write_bytes(b"font")
        with self.assertRaises(ValueError):
            packaging.consolidate(self.app, sign=False)
        self.assertTrue(all(bundle.is_dir() for bundle in self.copies))

    def testVerificationNeverModifiesProduct(self):
        with self.assertRaises(ValueError):
            packaging.consolidate(self.app, verify_only=True)
        self.assertTrue(all(bundle.is_dir() for bundle in self.copies))

    def testMissingSharedResourceAndSymlinkRefused(self):
        file = self.shared / "renderer.bin"
        file.unlink()
        with self.assertRaises(ValueError):
            packaging.consolidate(self.app, sign=False)
        file.symlink_to(self.copies[-1] / "Contents/Resources/renderer.bin")
        with self.assertRaises(ValueError):
            packaging.consolidate(self.app, sign=False)
        self.assertTrue(all(bundle.is_dir() for bundle in self.copies))

    def testUnrelatedAppRefused(self):
        (self.app / "Contents/Info.plist").write_bytes(plistlib.dumps({"CFBundleIdentifier": "unrelated.app"}))
        with self.assertRaises(ValueError):
            packaging.consolidate(self.app, sign=False)


if __name__ == "__main__":
    unittest.main()
