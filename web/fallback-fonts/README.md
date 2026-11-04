# Offline web-engine compatibility font

The WOFF2 file in `roboto/v32/` is **Inter Regular**, losslessly repackaged from
`assets/fonts/Inter-Regular.ttf` with fontTools/Brotli. Its internal family name
and glyphs are unchanged; the SIL Open Font License is included here.

The path matches Flutter **3.47.9** CanvasKit's historical default-Roboto request.
The engine supports registering a face under a family alias, so this local Inter
face also handles that compatibility request during `flutter run -d chrome`.
It is not a proprietary font or a claim that Inter is Roboto.

For release builds, `scripts/create_web_cache.py` registers the existing bundled
Inter face as the engine's `Roboto` fallback in `FontManifest.json`, avoiding even
that extra compatibility request. The UI continues to select Poppins/Inter.
`flutter_bootstrap.js` keeps any additional glyph-fallback requests on the app's
own origin, never Google's CDN. The supported language scripts are bundled.
Unbundled scripts/emoji may display missing glyphs rather than downloading fonts.

This directory is web-only; it does not change the verified Android APK. Recheck
the engine's default URL and the browser offline smoke test when upgrading Flutter.
