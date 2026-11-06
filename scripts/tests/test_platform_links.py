"""Static platform contracts, not an Android/iOS build or device certification."""
import pathlib
import plistlib
import unittest
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[2]
ANDROID = '{http://schemas.android.com/apk/res/android}'


class PlatformLinksTest(unittest.TestCase):
    def setUp(self):
        self.manifest = ET.parse(ROOT / 'android/app/src/main/AndroidManifest.xml')

    def test_mobile_schemes_add_tink_and_preserve_existing_links(self):
        schemes = {entry.get(ANDROID + 'scheme') for entry in self.manifest.findall('.//data')}
        self.assertTrue({'tink', 'paisa'}.issubset(schemes))
        plist = plistlib.loads((ROOT / 'ios/Runner/Info.plist').read_bytes())
        ios = {scheme for item in plist['CFBundleURLTypes'] for scheme in item['CFBundleURLSchemes']}
        self.assertTrue({'tink', 'paisa'}.issubset(ios))

    def test_widgets_keep_component_ids_but_use_tink_names_and_launch_links(self):
        widgets = {entry.get(ANDROID + 'name'): entry.get(ANDROID + 'label')
                   for entry in self.manifest.findall('.//receiver')
                   if entry.get(ANDROID + 'name', '').endswith('Widget')}
        self.assertEqual(widgets, {'.BalanceWidget': 'Tink · Balance',
                                   '.BudgetWidget': 'Tink · Budget',
                                   '.QuickAddWidget': 'Tink · Quick add'})
        android = (ROOT / 'android/app/src/main/java/com/example/paisaclone/MoneyWidgets.kt').read_text()
        ios = (ROOT / 'ios/PaisaWidgets/PaisaWidgets.swift').read_text()
        for source in (android, ios):
            self.assertIn('tink://quick_add', source)
            self.assertIn('tink://home', source)
            self.assertNotIn('"paisa://', source)

    def test_release_stays_offline_and_does_not_claim_reference_website(self):
        permissions = {entry.get(ANDROID + 'name') for entry in self.manifest.findall('.//uses-permission')}
        self.assertNotIn('android.permission.INTERNET', permissions)
        hosts = {entry.get(ANDROID + 'host') for entry in self.manifest.findall('.//data')}
        self.assertNotIn('paisa-tracker.app', hosts)


if __name__ == '__main__':
    unittest.main()
