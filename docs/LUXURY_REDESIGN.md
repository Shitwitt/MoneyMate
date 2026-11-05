# Tink 1.2 — editorial / glass design

This redesign interprets the user's November 2026 references with original artwork. It does not reproduce the referenced designers' logos, credit-card networks, banking products, crypto wallets, illustrated mascots or medical/fitness claims.

## Typography

- **Instrument Serif Regular**: Tink logotype, display headlines and large editorial titles. Selected for the high-contrast editorial-serif character of the final reference, not claimed to be that reference's exact licensed font.
- **Source Serif 4**, static optical-size-16 faces at 400/500/600/700: the entire interface's body, controls, inputs, data, amounts and captions. Money retains tabular figures. Source Serif is also a serif: there is no silent switch back to sans-serif for dense UI.
- Existing eight Noto script fallbacks, Poppins/Inter compatibility assets, the offline renderer fallback and all font licenses remain bundled. No runtime font fetching is enabled. Android launcher widgets and the iOS WidgetKit extension use the platform serif design; they do not duplicate Flutter font files into native resources.
- Ordinary text retains contrast-aware neutral inks. Exact brand-violet/white primary labels remain 20sp bold large text, not a claim of normal-text 4.5:1 contrast or independent accessibility certification.

## Navigation and surfaces

A floating, blurred glass capsule contains the configurable main destinations. More remains a separate rounded control. Labels, reordering, replacement destinations, RTL, desktop rail, keyboard/screen-reader actions and the add-transaction FAB are retained. The selected pill uses a deep vermilion/orange metallic gradient and warm halo, inspired by the first reference but darkened enough for readable white labels.

The home header now leads with the icon and editorial Tink wordmark. Cards use softened 28px corners, restrained shadows, engraved line artwork, paper/foil gradients, and a one-shot shine. System/light/dark/Midnight/custom accents and dynamic colors remain connected to the original persisted settings.

## Account artwork

Seven existing account types remain financial types: cash, bank, credit card, debit card, wallet, savings and investment. All are original procedural artwork, preloaded without external images:

- Cash: an abstract currency-note treatment with guilloche-like floral linework, not a replica of a real banknote.
- Bank/savings: architectural bank engraving and pearl/paper styling.
- Debit/credit/wallet/investment: metallic card composition with an original decorative chip, no payment network logo or fabricated account number.
- Finishes: Signature, Onyx, Pearl, Amethyst, Sage and Copper.
- Account editor: live name, type, currency, balance, image and finish preview. The new optional `cardStyle` field defaults to `auto` for old data and roundtrips through the existing JSON/backup format. It changes no account identifier, balance or transaction rule.
- Artwork always says local record/preview, not bank-connected or payment-enabled. Archived/excluded flags and monthly incoming/outgoing summaries remain available.

## Visualizations and truthful data

- Purple semicircular gauge, five-axis multicolour radar, cumulative cashflow line linked to monthly expense bars, gradient income/expense charts, category petals, segmented allocations, entry heatmap and luminous goal/budget rings.
- Category petals compare relative size; exact amounts and percentages remain selectable below the graphic. A geometry-based tap and labelled list are alternatives to colour-only interpretation.
- Cumulative net flow is not account balance or a forecast. Its line panel and the monthly-expense panel use independently labelled scales. Report filters, currency conversion, dates and exports remain connected to the original ledger.
- Heatmap: actual entry counts over thirteen calendar weeks; no fabricated streaks. Date selection has labelled previous/next-day controls.
- Financial pulse is **a local planning estimate**, not a credit score or a bank, insurance, retirement or investment assessment. It uses recorded liquid buffers, recorded current-period savings percentage, actual goal completion, recorded debt exposure and 28-day entry coverage. Unknown inputs stay unavailable; the aggregate needs at least two available indicators. Daily logging is not a financial-health requirement. The information sheet explains every formula. Hidden amounts also hide these financial charts.

## Motion and implementation boundaries

Foil sweeps are finite (1.1 seconds), navigation selection is 160ms, theme blending 480ms and chart reveals 600–700ms. There are no endless decorative tickers. Reduced-motion settings stop sweeps and finish numeric/shape transitions immediately. Decorative painting ignores pointer events and cannot determine dialog intrinsic dimensions.

Finance validation, atomic validate/save/publish, isolated profiles, backup integrity, editor-route completion, the transaction form's own-route closure and the bounded achievement dialog are not replaced by this redesign. Platform permission and signing limitations in README still apply. New visuals are not proof of real-device installation or iOS compilation.

## Verification

`test/luxury_design_test.dart` adds legacy-style roundtrip, estimate availability/future-date handling, all seven account kinds and six finishes at large text, configurable RTL navigation and reduced-motion chart cases. Existing finance/security/persistence and save-under-achievement regression assertions remain in place. The build status records actual CI results rather than treating these instructions as verification.
