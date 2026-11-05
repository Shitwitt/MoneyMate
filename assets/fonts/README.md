# Bundled, offline fonts

Current UI: **Quicksand** regular/medium/semibold/bold (400/500/600/700),
locally instantiated from the Google Fonts variable TTF. It is a licensed
rounded approximation, **not an identified exact font from the references**.
Amounts request OpenType tabular figures. No font is fetched at runtime.

| Family | Source | License here |
|---|---|---|
| Quicksand | `google/fonts`, `ofl/quicksand` | `OFL-Quicksand.txt` |
| Noto Sans Thai | `google/fonts`, `ofl/notosansthai` | `OFL-NotoSansThai.txt` |
| Noto Sans CJK SC (Han, kana, Hangul) | `notofonts/noto-cjk`, Sans/OTF/SimplifiedChinese | `OFL-NotoSansCJK.txt` |
| Noto Sans + Arabic, Devanagari, Bengali, Gurmukhi, Gujarati, Tamil, Telugu | Google Noto | `OFL.txt` |
| Inter | Google Fonts / Rasmus Andersson | `Inter-OFL.txt` |
| Poppins | Google Fonts / Indian Type Foundry | `Poppins-OFL.txt` |
| Instrument Serif | Google Fonts / Instrument | `instrumentserif-OFL.txt` |
| Source Serif 4 | Google Fonts / Adobe | `sourceserif4-OFL.txt` |

Inter/Poppins and the previous 1.2 serif fonts remain for compatibility and
older components; they are not the new primary UI. PDF output uses bundled
Noto fallbacks. The web bootstrap aliases local Inter for Flutter's default
CanvasKit Roboto fallback to avoid a CDN request; the small compatibility web
WOFF2 uses the same Inter license. Family/weight registration lives in
`pubspec.yaml`; shared type/fallback styles are in `lib/core/theme/`.

SIL Open Font License 1.1 permits bundling and modification subject to its
conditions, notices and reserved-name restrictions. These files are not
proprietary Paisa artwork. Support is tested for selected glyphs/scripts, not
all Unicode or every locale's typography. Device rendering/complex-script
printing still need QA.
