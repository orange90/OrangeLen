import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('registration', Path(__file__).resolve().parents[1] / 'audit-type-registration.py')
registration = importlib.util.module_from_spec(spec)
spec.loader.exec_module(registration)


class TypeRegistrationTests(unittest.TestCase):
    def testProductDoesNotRelyOnInstalledDeveloperApps(self):
        report = registration.inspect_product()
        self.assertEqual(report['missingExtensions'], [])
        self.assertEqual(report['unresolvedProductParents'], {})

        self.assertEqual(report['extensionsWithoutPreviewCandidate'], [])

    def testPreviewSupportAloneDoesNotRegisterSuffix(self):
        report = registration.audit(['sql'], [], [], {'Code': ['org.iso.sql']})
        self.assertEqual(report['missingExtensions'], ['sql'])

    def testImportedDeclarationSupportsStringTagsAndInheritedPreview(self):
        product = [{'UTTypeIdentifier': 'example.sql', 'UTTypeConformsTo': 'public.text',
                    'UTTypeTagSpecification': {'public.filename-extension': 'sql'}}]
        system = [{'UTTypeIdentifier': 'public.text'}]
        report = registration.audit(['sql'], product, system, {'Code': ['public.text']})
        self.assertEqual(report['missingExtensions'], [])
        self.assertEqual(report['unresolvedProductParents'], {})
        self.assertEqual(report['rows'][0]['previewCandidates'], ['Code'])

    def testMissingTransitiveParentIsNotHiddenByLocalDeclarations(self):
        product = [{'UTTypeIdentifier': 'example.sql', 'UTTypeConformsTo': ['example.source'],
                    'UTTypeTagSpecification': {'public.filename-extension': ['sql']}},
                   {'UTTypeIdentifier': 'example.source', 'UTTypeConformsTo': ['other.app.text']}]
        report = registration.audit(['sql'], product, [], {'Code': ['example.sql']})
        self.assertEqual(report['unresolvedProductParents']['example.sql'], ['other.app.text'])

    def testKnownSuffixStillNeedsAMatchingPreview(self):
        system = [{'UTTypeIdentifier': 'public.text',
                   'UTTypeTagSpecification': {'public.filename-extension': ['txt']}}]
        report = registration.audit(['txt'], [], system, {'Code': ['example.sql']})
        self.assertEqual(report['missingExtensions'], [])
        self.assertEqual(report['extensionsWithoutPreviewCandidate'], ['txt'])


if __name__ == '__main__':
    unittest.main()
