import base64
import importlib.util
from pathlib import Path
import tempfile
import unittest
import xml.etree.ElementTree as ET

spec = importlib.util.spec_from_file_location('feed', Path(__file__).resolve().parents[1] / 'verify-update-feed.py')
feed = importlib.util.module_from_spec(spec)
spec.loader.exec_module(feed)


class UpdateFeedTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        self.archive = root / 'OrangeLen-1.0.3-universal.dmg'
        self.archive.write_bytes(b'fixture')
        self.path = root / 'appcast.xml'
        self.info = {'SUFeedURL': feed.FEED_URL, 'SUPublicEDKey': base64.b64encode(bytes(32)).decode(),
                     'CFBundleVersion': '6', 'CFBundleShortVersionString': '1.0.3', 'LSMinimumSystemVersion': '14.0'}
        self.tree = ET.Element('rss')
        item = ET.SubElement(ET.SubElement(self.tree, 'channel'), 'item')
        for key, value in [('version', '6'), ('shortVersionString', '1.0.3'), ('minimumSystemVersion', '14.0')]:
            ET.SubElement(item, feed.SPARKLE + key).text = value
        self.enclosure = ET.SubElement(item, 'enclosure', {
            'url': 'https://github.com/orange90/OrangeLen/releases/download/V1.0.3/' + self.archive.name,
            'length': str(self.archive.stat().st_size),
            feed.SPARKLE + 'edSignature': base64.b64encode(bytes(64)).decode()})

    def check(self):
        ET.ElementTree(self.tree).write(self.path)
        feed.validate(self.path, self.info, self.archive)

    def testValidReleaseMetadata(self):
        self.check()

    def testWrongOrMutableDownloadURLRejected(self):
        for url in ['http://github.com/asset.dmg', 'https://github.com/orange90/OrangeLen/releases/latest/download/' + self.archive.name,
                    'https://example.com/' + self.archive.name]:
            with self.subTest(url=url):
                self.enclosure.set('url', url)
                with self.assertRaises(ValueError): self.check()

    def testChangedArchiveRejected(self):
        self.archive.write_bytes(b'changed archive')
        with self.assertRaises(ValueError): self.check()

    def testMissingSignatureRejected(self):
        del self.enclosure.attrib[feed.SPARKLE + 'edSignature']
        with self.assertRaises(ValueError): self.check()

    def testWrongBuildAndMinimumOSRejected(self):
        for key in ['CFBundleVersion', 'LSMinimumSystemVersion']:
            original = self.info[key]
            self.info[key] = '999'
            with self.assertRaises(ValueError): self.check()
            self.info[key] = original

    def testWrongFeedOrPublicKeyRejected(self):
        for key in ['SUFeedURL', 'SUPublicEDKey']:
            original = self.info[key]
            self.info[key] = ''
            with self.assertRaises(ValueError): self.check()
            self.info[key] = original


if __name__ == '__main__':
    unittest.main()
