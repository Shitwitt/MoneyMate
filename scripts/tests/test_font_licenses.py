"""OFL reserved-name and metadata-only font-rename regressions (stdlib only)."""
import hashlib
from pathlib import Path
import struct
import unittest

ROOT = Path(__file__).resolve().parents[2]
FONTS = ROOT / "assets" / "fonts"


def tables(path):
    data = path.read_bytes()
    count = struct.unpack_from(">H", data, 4)[0]
    result = {}
    for i in range(count):
        tag, _checksum, offset, size = struct.unpack_from(">4sIII", data, 12 + 16 * i)
        result[tag.decode("ascii")] = data[offset:offset + size]
    return result


def primary_names(data):
    _format, count, offset = struct.unpack_from(">HHH", data)
    for i in range(count):
        platform, _encoding, _lang, name_id, length, start = struct.unpack_from(
            ">HHHHHH", data, 6 + 12 * i)
        if name_id in (1, 3, 4, 6, 16, 17, 18, 21, 22, 25):
            raw = data[offset + start:offset + start + length]
            yield raw.decode("utf-16-be" if platform in (0, 3) else "mac_roman")


# Baseline captured before changing name records. Every other SFNT table
# except head (whole-font checksum) must remain byte-identical.
EXPECTED = {'Bold': {'GDEF': 'ec883df53eb17013f2fb7d55b7c778df0a8b3dad851e093f95470aa068a66c2c',
          'GPOS': '90ef6b3e020a477d78cfd18f9e930bc96ef6f1067253529fb22cbd52e60356a3',
          'GSUB': '539bba2a7f77e5d752b0ec6acdc6ad174830c8e2bc86ede03fb9c02903999f1e',
          'OS/2': 'aacc5b347329cbfc0cba176c977a125e4e7b8476a4d8a070ab4104ad5a245caf',
          'STAT': '032afe914c4598999697b351544069c5186e3607705305c074272a907fc5e49b',
          'cmap': '730869a7a9f97f8ec059804355fe866e46898a7616e960004039f73c3c6d6424',
          'gasp': '4ca731f86ad506ac0e320283dc9461926346de3c4d91d539ea7f6620d3826940',
          'glyf': 'e54c0ef1ea0e4d8e40b27af50d78555b41321bed5e3c1bbd3adb1cd5e80dbeb0',
          'hhea': '0f93659a3c941596ab37b402252eb8e593113cb0a43383917450bbf537113a95',
          'hmtx': '4354b590aaeff1aac02bef804a2fa6e949b8aeba18974a61d58a21c2d0bae004',
          'loca': 'd79cf663a85ae9d92783ca0666c4a5ee5b81b21353fd5523bbd130f8415666de',
          'maxp': '42d41028b1b8d62998ca7a87a49dfec6a9b303d1f1af09d362bb1c5386d84b50',
          'post': 'ba8f0e9b29f0c3bc99a9ba240cbce7193a3d1741cc5aa3d1d3cc5110eb38c541',
          'prep': '907c4106ff9989c1805827d5581bdf107a253b098cb71eb374f5e47c35604452'},
 'Medium': {'GDEF': 'ec883df53eb17013f2fb7d55b7c778df0a8b3dad851e093f95470aa068a66c2c',
            'GPOS': 'b92cc2f91f658ed2a69445ca3a2b57b8bf77f9ce3a8cc7af3b6efe8daa0bbeb9',
            'GSUB': '539bba2a7f77e5d752b0ec6acdc6ad174830c8e2bc86ede03fb9c02903999f1e',
            'OS/2': 'e65dd7419d471e67331b2da5ee65fbba4acdebd1cd99641656d0c9c4daa10694',
            'STAT': '6236d3a9e35130cf1053b89fcbf1b2b2402e8243b16c18752d1f660edc2926b1',
            'cmap': '730869a7a9f97f8ec059804355fe866e46898a7616e960004039f73c3c6d6424',
            'gasp': '4ca731f86ad506ac0e320283dc9461926346de3c4d91d539ea7f6620d3826940',
            'glyf': '804d37276a948255911ad720aebd36a620172eabe1c1806573371b4038c343f4',
            'hhea': '029c835db35be2650eafd656ff166343c082de53e62ca3c5249ab9c4e23125e6',
            'hmtx': 'fde940158b015d578999e2c43a2f24732802e67a37d28af8a3a0263287cf6c95',
            'loca': 'e8beffbdb8053a62db2782b8530d6343f07c28656a8d4c59a6f43a19267de2ab',
            'maxp': '42d41028b1b8d62998ca7a87a49dfec6a9b303d1f1af09d362bb1c5386d84b50',
            'post': 'ba8f0e9b29f0c3bc99a9ba240cbce7193a3d1741cc5aa3d1d3cc5110eb38c541',
            'prep': '907c4106ff9989c1805827d5581bdf107a253b098cb71eb374f5e47c35604452'},
 'Regular': {'GDEF': 'ec883df53eb17013f2fb7d55b7c778df0a8b3dad851e093f95470aa068a66c2c',
             'GPOS': '9aa4483e74147dacb67bf38fc318060bda65283b756dd62202c939d5b54ad30a',
             'GSUB': '539bba2a7f77e5d752b0ec6acdc6ad174830c8e2bc86ede03fb9c02903999f1e',
             'OS/2': 'dcba791ce6d7e951003e3188d4f686f2aac217be7f9b4affeda35f5595604b82',
             'STAT': '9a695bc95875929de1b7d9f8ba38a79c08e9cd78967de0f483592bd7b1e02d04',
             'cmap': '730869a7a9f97f8ec059804355fe866e46898a7616e960004039f73c3c6d6424',
             'gasp': '4ca731f86ad506ac0e320283dc9461926346de3c4d91d539ea7f6620d3826940',
             'glyf': '4b14f4291afc689208a2201ea95baad53264641391f553ddd2c5a22dc19edb96',
             'hhea': '7969a42ef3a2d2c8d12e00df9bcb62809c357fbef4cdf884c7dffe087da42d37',
             'hmtx': '24b82e056d96bc77884ce2f05903bc82d4658c633336d91b05100069ef2cb835',
             'loca': '120365118a47458761e7e3439d1d46c24e3ac87af5b8cc8efa8f57b17b2f85ca',
             'maxp': '42d41028b1b8d62998ca7a87a49dfec6a9b303d1f1af09d362bb1c5386d84b50',
             'post': 'ba8f0e9b29f0c3bc99a9ba240cbce7193a3d1741cc5aa3d1d3cc5110eb38c541',
             'prep': '907c4106ff9989c1805827d5581bdf107a253b098cb71eb374f5e47c35604452'},
 'SemiBold': {'GDEF': 'ec883df53eb17013f2fb7d55b7c778df0a8b3dad851e093f95470aa068a66c2c',
              'GPOS': '619e54d80cca363e5fdd5b8c0771c46ab244c53492a5d1bc2ac317ea2acb14fe',
              'GSUB': '539bba2a7f77e5d752b0ec6acdc6ad174830c8e2bc86ede03fb9c02903999f1e',
              'OS/2': '0b5bc89eca7403c43e732761aee35a02fcf4597d84c53358e9ae93aa72f72d51',
              'STAT': '109a242cfd82db962bbe67cca299b85b7dcf585382552acef9ad3ef51f8402bf',
              'cmap': '730869a7a9f97f8ec059804355fe866e46898a7616e960004039f73c3c6d6424',
              'gasp': '4ca731f86ad506ac0e320283dc9461926346de3c4d91d539ea7f6620d3826940',
              'glyf': '56f6e22294c4371b0c0d71d071be6230c1c3ce6e982a191e1cb959a0650dc66f',
              'hhea': '8aff12629e4c46370fac52401abf3982ab0b10428bae8f14bd347d19e49a2ebf',
              'hmtx': 'cc8a49450373628d17b81a6f3e5a57864c5396f251afb565a87e0b1c19714bba',
              'loca': 'dc378e5da557a2e261daf0661c4f08bdd8adba31d296ae8c002f006cfa128aa4',
              'maxp': '42d41028b1b8d62998ca7a87a49dfec6a9b303d1f1af09d362bb1c5386d84b50',
              'post': 'ba8f0e9b29f0c3bc99a9ba240cbce7193a3d1741cc5aa3d1d3cc5110eb38c541',
              'prep': '907c4106ff9989c1805827d5581bdf107a253b098cb71eb374f5e47c35604452'}}


class FontLicenseTests(unittest.TestCase):
    def test_modified_fonts_do_not_use_reserved_primary_name(self):
        self.assertFalse(list(FONTS.glob("Quicksand-*.ttf")))
        for style in EXPECTED:
            names = list(primary_names(tables(FONTS / f"TinkRounded-{style}.ttf")["name"]))
            self.assertTrue(any("TinkRounded" in n for n in names))
            self.assertFalse(any("quicksand" in n.lower() for n in names))

    def test_metadata_rename_preserves_glyph_metrics_and_layout(self):
        for style, baseline in EXPECTED.items():
            actual = tables(FONTS / f"TinkRounded-{style}.ttf")
            self.assertEqual(set(actual) - {"name", "head"}, set(baseline))
            for tag, expected in baseline.items():
                self.assertEqual(hashlib.sha256(actual[tag]).hexdigest(), expected,
                                 f"{style} {tag} changed")

    def test_registered_weights_and_attribution(self):
        manifest = (ROOT / "pubspec.yaml").read_text()
        self.assertIn("family: TinkRounded", manifest)
        for style, weight in {"Regular":400, "Medium":500, "SemiBold":600, "Bold":700}.items():
            self.assertIn(f"assets/fonts/TinkRounded-{style}.ttf", manifest)
            data = tables(FONTS / f"TinkRounded-{style}.ttf")["OS/2"]
            self.assertEqual(struct.unpack_from(">H", data, 4)[0], weight)
        license_text = (FONTS / "OFL-Quicksand.txt").read_text()
        self.assertIn("Reserved Font Name", license_text)
        self.assertIn("SIL OPEN FONT LICENSE Version 1.1", license_text)


if __name__ == "__main__":
    unittest.main()
