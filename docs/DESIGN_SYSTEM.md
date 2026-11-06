# Tink 1.3 design system — reference batch 1

The current coffee/peach direction supersedes [the 1.2 editorial/glass design](LUXURY_REDESIGN.md). [Batch scope and deliberate differences](REFERENCE_BATCH_01.md).

## Shared foundations

- Coffee canvas `#1A100E`, Home/card `#231A15`, tool tiles `#271E19`, balance/FAB brown `#72361E`, primary peach `#FFB59A`, muted dark ink `#D9C4BA`.
- Light canvas `#FFF8F2`, cards `#FFFDF9`, body ink `#2D211A`; semantic income/expense/transfer have separate light ink and dark pastel variants.
- System/light/dark/**Just Black** plus opt-in Android dynamic color and saved custom accents. Just Black is not premium-gated. A UI-revision migration changes old defaults once, not newly selected custom accents on every launch.
- Offline licensed Quicksand 400–700; Noto Latin, Arabic, Indic, Thai and CJK fallback. Exact reference font is unknown; this is a deliberate licensed approximation. Tabular amount style, actual-record figures, full-value money semantics and text-scale/RTL-aware layouts. See [font sources/licenses](../assets/fonts/README.md).
- Shared `core/theme/` tokens; `shared/reference_components.dart`, `widgets.dart`, `forms.dart`, `wavy_ring.dart` and `daily_spend_chart.dart`. Rounded tonal cards, pills/segments, wavy progress, summary columns, form/editor/picker/empty/loading components apply throughout, not just Home.

## Home and preview rules

Default Home/Accounts/Reports/Search navigation, brown add FAB, profile/menu/grid controls, hideable balance/cashflow comparisons, ordered two-column tool cards, swipeable budgets, weekly bars, cumulative 30-day expenses, actual earned badge and usable templates. Narrow phones switch to one column above 130% text; saved order also applies to templates and last-earned cards. Missing historical comparison is labeled, not treated as a fabricated percentage. Future dates are not included in recorded charts; unknown future week days are outlined, not predictions.

Tour phone previews mount the real feature widgets in independent in-memory providers, using decorative fixed-scale light English previews and excluding their semantics. They cannot save into user data. Interactive real screens honor user locale, theme and text scale. No fake OS/status bar, copied screenshot backdrop, private chat-head photo or proprietary reference logo is bundled.

## Motion

Finite ease-out transitions; reference helpers default 240ms, app theme 280ms, charts 500ms. Reduced-motion disables reference/theme/chart animations. There is no continuous celebration blocking forms. Static references do not determine the original app's animation timings. Platform/third-party animations and every individual transition are not independently certified.

## Measured fixed-palette contrast

WCAG relative-luminance formula, sRGB components. These are **specific solid color pairs**, not a blanket AA certification. Text on alpha-tinted, custom or dynamic surfaces must be checked in context. Color is supplemented with labels, percentages and descriptions.

| Pair | Foreground / background | Ratio |
|---|---|---|
| Peach on coffee | `#FFB59A` / `#1A100E` | 10.96:1 |
| Light ink on Home tile | `#F8E8DD` / `#271E19` | 13.67:1 |
| Muted ink on coffee | `#D9C4BA` / `#1A100E` | 11.17:1 |
| Hero light ink on brown | `#F8E8DD` / `#72361E` | 7.77:1 |
| Light body ink on warm-white | `#2D211A` / `#FFF8F2` | 14.85:1 |
| Light muted ink on warm-white | `#705C4F` / `#FFF8F2` | 5.99:1 |
| Income ink on light card | `#36582B` / `#FFFDF9` | 7.99:1 |
| Expense ink on light card | `#8D343F` / `#FFFDF9` | 7.67:1 |
| Dark income on tile | `#A7C994` / `#271E19` | 8.88:1 |
| Dark expense on tile | `#EEB5B8` / `#271E19` | 9.28:1 |
| Brown on peach | `#2D211A` / `#FFB59A` | 9.17:1 |
| Due tile ink | `#FFE0D2` / `#72361E` | 7.45:1 |
| Yearly tile ink | `#F5E6A7` / `#49430C` | 8.01:1 |
| Income tile ink | `#A7E3B0` / `#074926` | 7.16:1 |
| Expense tile ink | `#FFBDC3` / `#700F18` | 7.52:1 |

Prior violet/white 3.63:1 was a historical 1.2 large-text-only pair; it is not evidence for the new palette. Tinted feature cards use `readableTint` for an appropriate foreground. Screen-reader navigation, native pickers, complex scripts, actual devices and extreme display/font settings still need the documented QA checks.

## Safety and truthful numbers

Charts and previews use ledger calculations or explicitly fictional isolated demo records. The record indicator is not a credit/health/AI score. Safe to spend remains a conservative planning estimate in Net worth details. Account finishes are bookkeeping artwork, not issued payment cards, bank connections, crypto custody or realistic bank logos. Data/backups are unencrypted; interface PIN is not database encryption.
