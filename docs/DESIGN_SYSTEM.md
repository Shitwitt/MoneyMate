# Tink 1.2 design system

## Direction and provenance
An original editorial/glass finance interface: neutral canvas, large serif tabular
amounts, engraved bank/cash/card artwork and a luminous warm navigation pill. Stable Money and the supplied
screens are references for clarity and polish, not copied products or promised
banking capabilities. The head/yellow-spark icon is an original scalable redraw
of the user's first reference. Six introductory compositions are original Flutter
vector drawings; there are no photos, realistic 3D characters or proprietary bank
logos. The yellow spark stays in the mark; data visualizations may also use labelled warm/lime accents. See [the reference interpretation and chart rules](LUXURY_REDESIGN.md).

## Source of truth

| File | Responsibility |
|---|---|
| `lib/core/theme/app_colors.dart` | Brand, neutral, semantic and chart palettes |
| `lib/core/theme/app_text_styles.dart` | Instrument Serif display, Source Serif 4 UI/data, tabular figures and locale fallbacks |
| `lib/core/theme/app_spacing.dart` | 4/8/12/16/20/24/32/40/48 spacing, 56 buttons, 72 navigation |
| `lib/core/theme/app_radius.dart` | 12 small, 16 buttons/inputs, 28 cards, 32 sheets |
| `lib/core/theme/theme.dart` | Light/dark/Midnight Material 3 themes and route motion |
| `lib/core/theme/app_theme.dart` | Compatibility entry point for existing screen callers |
| `lib/shared/tink_components.dart` | Buttons, cards, icons, progress, chart frame, badge, mark and finite motion |
| `lib/shared/widgets.dart` | AmountText, SectionHeader, StatCard, EmptyState, FeaturePage, skeleton and exports |
| `lib/features/transactions/transaction_tile.dart` | Adaptive semantic transaction row and receipt/edit actions |
| `lib/shared/luxury_components.dart` | Foil shine, editorial wordmark, glass configurable navigation |
| `lib/shared/account_artwork.dart` | Seven account types, six original bank/card/cash finishes |
| `lib/shared/pulse_charts.dart` | Transparent pulse gauge/radar and 13-week record calendar |
| `lib/shared/cashflow_composition.dart` | Linked cumulative-net and monthly-expense panels |
| `lib/shared/charts.dart` | Accessible trends and selectable petal/segmented category allocations |

`FeaturePage`, global component themes, shared money/transaction components and
cards apply the system to every existing finance/settings screen, rather than
limiting the redesign to the introduction and dashboard.

## Color tokens

| Role | Light | Dark |
|---|---|---|
| Brand / pressed / pale | `#916CFF` / `#7A55F0` / `#EDE7FF` | Brand retained; optional highlight `#A78BFF` |
| Main background | `#F7F7FB` | `#121218` |
| Card | `#FFFFFF` | `#1B1B23` |
| Divider | `#ECECF2` | `#2A2A33` |
| Primary text | `#0B0B0F` | White |
| Secondary text | `#5A5A66` | `#A5A5B2` |
| Decorative tertiary | `#8A8A96` | `#8A8A96` |
| Income accent / readable ink | `#12B76A` / `#067647` | `#34D399` |
| Expense accent / readable ink | `#F04438` / `#B42318` | `#F87171` |
| Transfer accent / readable ink | `#2E90FA` / `#175CD3` | `#60A5FA` |
| Warning accent / readable ink | `#F79009` / `#93370D` | Warm yellow/orange |
| Semantic backgrounds | `#E8F8F0`, `#FEECEB`, `#FFF6E6`, `#EAF3FF` | Tinted neutral surfaces |

Violet denotes primary actions, selection, progress, links and highlights, never
income/expense semantics. Categories retain meaningful/user-chosen colors. New
food, transport and shopping categories use orange, blue and pink respectively.
Credit-account overview cards use dark surfaces with readable white text and
recorded balances; they do not represent a real issued card.

### The exact-violet/white contrast conflict

White on `#916CFF` is **3.63:1**: sufficient for WCAG AA **large text**, not normal
body text. The primary-button label is deliberately **20sp / weight 700** (above
18.67px bold) so exact violet + white remains AA at its intended size. Pressed
`#7A55F0` on white is **4.79:1**. Normal-size links and selected text use readable
violet ink `#5530B0`; that ink on pale violet is **7.17:1**. Secondary body text on
the main light canvas is **6.36:1**. Semantic light-card income/expense inks are
**5.69:1** and **6.57:1** against white. Decorative tertiary gray is not the body
caption color. Inputs use a stronger visible neutral outline than decorative
dividers. Dark destructive confirmations use ink on coral (**7.10:1**), not
white on coral; their light-mode white/dark-red pair is **6.57:1**. A
custom/personalized primary foreground is selected by contrast.

These are design-token checks, not an independent audit or blanket certification
of every platform state. Continue the real-device accessibility checklist.

## Typography

- Instrument Serif Regular: large editorial display and Tink branding, an original licensed interpretation of the supplied serif reference, not a claim of exact font identification.
- Source Serif 4 400/500/600/700: every body, caption, control and data style. Display 36/32, page 28, H1 24, H2 20, H3 18, body 16/14, labels 13, captions 12, metadata 11.
- Monetary values explicitly use Source Serif 4 with tabular figures. Currency precision, Indian/international grouping and amount hiding still come from existing settings.
- Comfortable 1.35–1.45 body line heights; high-contrast display serif uses tighter title line heights. The wordmark is a fixed-size graphic-like brand label with full semantics, not financial content.
- Fonts are licensed local assets; Google Fonts runtime fetching is disabled. Eight Noto fallback families preserve the 13 starter locales/RTL. Old Poppins/Inter assets and CanvasKit's local Inter compatibility alias remain for compatibility, not as the main UI type. Native launcher widgets use platform serif fonts.
- Existing starter translations cover shell/actions; many feature-specific and
  introductory sentences remain English. This is not full translated-copy coverage.

## Components and motion

`PrimaryButton`, `SecondaryButton`, `AppCard`, `AmountText`, `TransactionTile`,
`CategoryIcon`, `ProgressBar`, `ProgressRing`, `SectionHeader`, `EmptyState`,
`StatCard`, `ChartCard`, `PremiumBadge` are reusable, not screen-only sketches.
Sheets, dialogs, chips, selectors, form fields and calculator controls inherit
the same Material 3 theme. Minimum actionable targets are 48 logical pixels.

Animations use ease-out-cubic/ease-in-out, finite 150–280ms micro/navigation
transitions and 380–700ms chart/amount/progress entrances. Splash fades/scales
0.95 → 1; intro illustration motion is a small one-shot float. Home cards enter
subtly; money counts up. The entry sheet slides, its Save state briefly checks,
and selection changes animate. Budget overrun gets one outline pulse. Goal rings,
gradient bars/rings, petal reveal, radar/gauge reveals, comparative cashflow, calendar entrances and the Pro badge
have restrained animations. Glass pills transition over 160ms, theme shifts blend over 480ms and foil sweeps finish after 1.1 seconds. Reduced-motion preferences remove primary entrances;
forms never depend on waiting for looping animation. Preserve the shared editor's
`route.completed` await before caller-owned controller disposal.

## Compatibility and scope

Version is `1.2.0+3`; Android minimum remains 24. Internal package/database/archive/
URI IDs intentionally stay compatible with the original app. No financial API,
banking connection, investment order, money transfer, card issuance or real
purchase is added by the design references. All financial actions are local
bookkeeping/planning; Pro is still a free persisted simulation. Storage/backups
are not encrypted, and an app PIN is not at-rest database encryption.
