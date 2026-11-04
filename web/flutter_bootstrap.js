{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load({
  config: {
    // Never send user-entered glyphs to Google's fallback-font CDN. Supported
    // scripts are bundled; unknown glyph fallbacks stay on the app's own origin.
    fontFallbackBaseUrl: new URL('fallback-fonts/', document.baseURI).toString()
  }
});
