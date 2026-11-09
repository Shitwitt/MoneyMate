#!/usr/bin/env python3
"""
MoneyMate Business Plan — Financial model for a custom-tailoring + fabric retail/wholesale
business in Jalandhar, Punjab.

All numbers are PLANNING ASSUMPTIONS in INR, built from published market ranges
(IndiaMART/Surat wholesale rate lists, boutique pricing benchmarks, Punjab rents).
Replace the ASSUMPTIONS block with your own real numbers before you take any loan.

Run:  python3 financial_model.py > financial-model.md
"""

from __future__ import annotations

INR = "₹{:,.0f}"


def lkh(x: float) -> str:
    """Format as lakh/crore string."""
    if abs(x) >= 1_00_00_000:
        return f"₹{x / 1_00_00_000:,.2f} Cr"
    return f"₹{x / 1_00_000:,.2f} L"


def table(headers, rows) -> str:
    out = ["| " + " | ".join(headers) + " |",
           "|" + "|".join(["---"] * len(headers)) + "|"]
    for r in rows:
        out.append("| " + " | ".join(str(c) for c in r) + " |")
    return "\n".join(out)


# ---------------------------------------------------------------- ASSUMPTIONS
# --- Tailoring workshop (Stage A) ---
TAILORS = 3                 # paid tailors on shop floor
TAILOR_SALARY = 18000       # per month, Jalandhar skilled tailor
CUTTER_SALARY = 26000       # master cutter (the most important hire)
HELPER_SALARY = 9000        # finishing / pressing / housekeeping
UNITS_PER_TAILOR_PER_DAY = 2.2   # mixed: shirt, trouser, kurta-pyjama, blouse, alteration
WORKING_DAYS = 26
AVG_STITCHING_CHARGE = 950  # blended: alterations ₹250, shirt ₹600, 2-piece suit ₹4,500
CONSUMABLES_PCT = 4         # thread, buttons, zips, interlining, paper, blades
RENT_TAILORING = 32000      # 250–350 sq ft, Model Town / Urban Estate side street
ELEC_TAILORING = 6500
MARKETING_PCT = 5
OTHER_FIXED = 9000          # software, chai-sutta, repairs, accountant, misc

# --- Fabric retail counter (Stage B) ---
FABRIC_METRES_PER_DAY = 26  # retail walk-in metres sold per working day
FABRIC_AVG_SELL = 520       # blended retail price / metre (suiting, shirting, kurta, lining)
FABRIC_GROSS_MARGIN = 0.38  # retailer margin over landed cost
FABRIC_RENT = 45000         # 400–500 sq ft shop on a visible market road
FABRIC_STAFF = 26000        # 1 salesman + 1 cutter/measurer
FABRIC_WASTAGE_PCT = 3      # end-pieces, shrinkage, shop damage, theft

# --- Wholesale / distribution (Stage C) ---
WH_ACTIVE_RETAILERS = 45    # tailors + boutiques + shops buying from you monthly
WH_METRES_PER_RETAILER = 130
WH_AVG_SELL = 400           # wholesale price / metre
WH_GROSS_MARGIN = 0.155
WH_SALES_TEAM = 3           # field sales boys on bike
WH_SALES_SALARY = 16000
WH_INCENTIVE_PCT = 1.5      # incentive on wholesale revenue
WH_GODOWN_RENT = 22000      # 800–1,200 sq ft, Basti Sheikh / Nakodar Road side
WH_TRANSPORT = 18000
WH_CREDIT_COST_PCT = 1.6    # interest + bad-debt provision on 30–45 day credit

GST_TAILORING = 0.05        # SAC 9988 tailoring / job work — 5% from GST 2.0 (Sep 2025)
GST_FABRIC = 0.05           # woven fabric up to ₹2,500/piece — 5%
GST_APPAREL_ABOVE_2500 = 0.18


def tailoring_month(tailors=TAILORS, days=WORKING_DAYS, charge=AVG_STITCHING_CHARGE,
                    upt=UNITS_PER_TAILOR_PER_DAY):
    units = tailors * upt * days
    rev = units * charge
    cons = rev * CONSUMABLES_PCT / 100
    labour = tailors * TAILOR_SALARY + CUTTER_SALARY + HELPER_SALARY
    fixed = RENT_TAILORING + ELEC_TAILORING + OTHER_FIXED
    mkt = rev * MARKETING_PCT / 100
    ebitda = rev - cons - labour - fixed - mkt
    return dict(units=units, rev=rev, cons=cons, labour=labour, fixed=fixed,
                mkt=mkt, ebitda=ebitda, margin=ebitda / rev if rev else 0,
                rev_per_tailor=rev / tailors if tailors else 0)


def fabric_month(metres_per_day=FABRIC_METRES_PER_DAY, sell=FABRIC_AVG_SELL,
                 gm=FABRIC_GROSS_MARGIN, days=WORKING_DAYS):
    metres = metres_per_day * days
    rev = metres * sell
    gp = rev * gm
    wastage = rev * FABRIC_WASTAGE_PCT / 100
    fixed = FABRIC_RENT + FABRIC_STAFF + ELEC_TAILORING + OTHER_FIXED
    ebitda = gp - wastage - fixed
    return dict(metres=metres, rev=rev, gp=gp, wastage=wastage, fixed=fixed,
                ebitda=ebitda, margin=ebitda / rev if rev else 0,
                gp_per_metre=gp / metres if metres else 0)


def wholesale_month(retailers=WH_ACTIVE_RETAILERS, metres=WH_METRES_PER_RETAILER,
                    sell=WH_AVG_SELL, gm=WH_GROSS_MARGIN):
    vol = retailers * metres
    rev = vol * sell
    gp = rev * gm
    team = WH_SALES_TEAM * WH_SALES_SALARY
    inc = rev * WH_INCENTIVE_PCT / 100
    fixed = WH_GODOWN_RENT + WH_TRANSPORT + team + inc + OTHER_FIXED * 2
    credit = rev * WH_CREDIT_COST_PCT / 100
    ebitda = gp - fixed - credit
    return dict(vol=vol, rev=rev, gp=gp, team=team, inc=inc, fixed=fixed,
                credit=credit, ebitda=ebitda, margin=ebitda / rev if rev else 0)


def breakeven_tailoring():
    """Units per month needed to cover all fixed cost at current avg charge."""
    fixed = TAILORS * TAILOR_SALARY + CUTTER_SALARY + HELPER_SALARY + \
        RENT_TAILORING + ELEC_TAILORING + OTHER_FIXED
    contribution = AVG_STITCHING_CHARGE * (1 - (CONSUMABLES_PCT + MARKETING_PCT) / 100)
    return fixed, contribution, fixed / contribution


def fabric_stock_plan():
    """Opening stock plan for a first fabric counter — depth over breadth."""
    plan = [
        # category, metres, landed ₹/m, capital, expected retail ₹/m
        ("Poly-viscose suiting (core, 12 designs)", 240, 190, 435),
        ("Wool / poly-wool blazer suiting (winter)", 150, 420, 850),
        ("Cotton & poly shirting (20 designs)", 200, 110, 240),
        ("Kurta / pathani fabric (cotton, linen-look)", 180, 160, 340),
        ("Trousering (high-twist, stretch, gabardine)", 120, 210, 460),
        ("Lining, interlining, canvas, padding", 200, 70, 145),
        ("Sherwani / wedding fabric (silk, jacquard, velvet)", 80, 620, 1450),
        ("Ladies suit material & dupatta sets (trial)", 120, 180, 420),
    ]
    rows, cap, retail_val = [], 0, 0
    for name, m, cost, sell in plan:
        c = m * cost
        cap += c
        retail_val += m * sell
        rows.append([name, m, INR.format(cost), lkh(c), INR.format(sell),
                     f"{(sell - cost) / cost * 100:.0f}%"])
    rows.append(["**TOTAL**", sum(p[1] for p in plan), "", f"**{lkh(cap)}**", "",
                 f"**{lkh(retail_val)}**"])
    return rows, cap, retail_val


def three_year_plan():
    """Phased P&L. NOTE: it deliberately assumes you climb to A3 premium positioning
    in year 1 instead of staying an A2 average tailor shop — that is the whole point."""
    y1_tail = tailoring_month(tailors=3, upt=1.5, charge=2400)
    y1_fab = fabric_month(metres_per_day=20, sell=500)
    y2_tail = tailoring_month(tailors=5, upt=1.6, charge=2700)
    y2_fab = fabric_month(metres_per_day=32, sell=530)
    y2_wh = wholesale_month(retailers=25, metres=110)
    y3_tail = tailoring_month(tailors=8, upt=1.7, charge=3000)
    y3_fab = fabric_month(metres_per_day=45, sell=560)
    y3_wh = wholesale_month(retailers=60, metres=150)

    def year(tail, fab, wh=None, ramp_tail=0.8, ramp_fab=0.65, ramp_wh=0.55):
        rev = tail["rev"] * 12 * ramp_tail + fab["rev"] * 12 * ramp_fab
        eb = tail["ebitda"] * 12 * ramp_tail + fab["ebitda"] * 12 * ramp_fab
        if wh:
            rev += wh["rev"] * 12 * ramp_wh
            eb += wh["ebitda"] * 12 * ramp_wh
        return rev, eb

    r1, e1 = year(y1_tail, y1_fab)
    r2, e2 = year(y2_tail, y2_fab, y2_wh)
    r3, e3 = year(y3_tail, y3_fab, y3_wh)
    rows = [
        ["Tailoring (stitching + made-to-measure)", lkh(y1_tail["rev"] * 12 * .85),
         lkh(y2_tail["rev"] * 12 * .85), lkh(y3_tail["rev"] * 12 * .85)],
        ["Fabric retail (per metre counter)", lkh(y1_fab["rev"] * 12 * .7),
         lkh(y2_fab["rev"] * 12 * .7), lkh(y3_fab["rev"] * 12 * .7)],
        ["Fabric wholesale / distribution", "—", lkh(y2_wh["rev"] * 12 * .6),
         lkh(y3_wh["rev"] * 12 * .6)],
        ["**Total revenue**", f"**{lkh(r1)}**", f"**{lkh(r2)}**", f"**{lkh(r3)}**"],
        ["**EBITDA (before owner salary & tax)**", f"**{lkh(e1)}**", f"**{lkh(e2)}**",
         f"**{lkh(e3)}**"],
        ["EBITDA margin", f"{e1 / r1 * 100:.1f}%", f"{e2 / r2 * 100:.1f}%",
         f"{e3 / r3 * 100:.1f}%"],
    ]
    return rows, (r1, e1), (r2, e2), (r3, e3)


def capex_plan():
    items = [
        # --- tailoring workshop ---
        ("Lockstitch machines (Juki/Jack class, 3)", 3 * 17000, "A"),
        ("Overlock machine (4-thread)", 32000, "A"),
        ("Button-hole + button-attach machine", 38000, "A"),
        ("Fusing / press machine + steam iron + vacuum table", 45000, "A"),
        ("Cutting table (8x4 ft) + measuring table + racks", 28000, "A"),
        ("Trial-room, mirrors, sofa, fabric display wall, signage", 85000, "A"),
        ("Measurement tablets + billing/GST software + barcode printer", 30000, "A"),
        ("Shop deposit + first 3 months rent (tailoring unit)", 160000, "A"),
        # --- fabric counter ---
        ("Fabric retail: shop deposit + interiors + roll racks + lighting", 420000, "B"),
        ("Fabric retail: opening stock (see stock plan)", 480000, "B"),
        ("Roll-cutting table, measuring machine (yard counter), tagging gun", 65000, "B"),
        # --- wholesale ---
        ("Wholesale: godown deposit + racking + handling equipment", 220000, "C"),
        ("Wholesale: opening stock buffer (rolling)", 1200000, "C"),
        ("Wholesale: 2 second-hand delivery vehicles / EMI down-payment", 300000, "C"),
        ("Working-capital reserve (must not skip)", 500000, "C"),
    ]
    rows = []
    stage_tot = {"A": 0, "B": 0, "C": 0}
    for name, cost, st in items:
        stage_tot[st] += cost
        rows.append([f"Stage {st}", name, lkh(cost)])
    rows.append(["", "**Stage A total — tailor studio**", f"**{lkh(stage_tot['A'])}**"])
    rows.append(["", "**Stage B total — + fabric retail**", f"**{lkh(stage_tot['B'])}**"])
    rows.append(["", "**Stage C total — + wholesale**", f"**{lkh(stage_tot['C'])}**"])
    rows.append(["", "**Grand total (A→B→C over 3 years)**",
                 f"**{lkh(sum(stage_tot.values()))}**"])
    return rows, stage_tot


def sensitivity():
    """How EBITDA responds to the two numbers you actually control."""
    rows = []
    for charge in (700, 850, 950, 1200, 1500):
        line = [INR.format(charge)]
        for t in (2, 3, 5, 8):
            m = tailoring_month(tailors=t, charge=charge)
            line.append(f"{lkh(m['ebitda'] * 12)} ({m['margin'] * 100:.0f}%)")
        rows.append(line)
    return rows


def fabric_price_ladder():
    """Sample price architecture: landed → wholesale → retail → stitched package."""
    rows = []
    cats = [
        ("Economy poly-viscose suiting", 165, 205, 285),
        ("Mid poly-viscose / terry-rayon suiting", 230, 285, 399),
        ("Premium 4-way stretch suiting", 380, 460, 649),
        ("Wool-blend winter suiting", 520, 620, 899),
        ("Cotton shirting", 95, 120, 179),
        ("Kurta / pathani cotton", 145, 180, 269),
        ("Trousering (high twist)", 180, 225, 329),
        ("Sherwani silk / jacquard", 620, 760, 1199),
    ]
    for name, land, wh, ret in cats:
        suit_m = 3.5
        cloth_pkg = suit_m * ret
        stitch = 4500
        rows.append([name, INR.format(land), INR.format(wh),
                     f"{(wh - land) / land * 100:.0f}%", INR.format(ret),
                     f"{(ret - land) / land * 100:.0f}%",
                     INR.format(cloth_pkg + stitch)])
    return rows


def scenarios_tailoring():
    """Three ways to run the same 3-machine shop. Positioning decides everything."""
    defs = [
        # name, tailors, units/tailor/day, blended charge, rent, marketing %
        ("A1 — Volume alteration shop (Sadar Bazar lane)", 3, 3.0, 420, 22000, 2),
        ("A2 — Mid custom tailor (family + wedding orders)", 3, 2.2, 950, 32000, 5),
        ("A3 — Premium made-to-measure studio (Model Town)", 3, 1.4, 2600, 55000, 10),
        ("A4 — A3 at scale: 6 tailors + fabric attach", 6, 1.5, 2600, 55000, 8),
    ]
    rows = []
    for name, tl, upt, charge, rent, mkt in defs:
        units = tl * upt * WORKING_DAYS
        rev = units * charge
        cons = rev * CONSUMABLES_PCT / 100
        labour = tl * (TAILOR_SALARY + 4000 if charge > 1500 else TAILOR_SALARY) \
            + CUTTER_SALARY + HELPER_SALARY
        fixed = rent + ELEC_TAILORING + OTHER_FIXED
        m = rev * mkt / 100
        eb = rev - cons - labour - fixed - m
        rows.append([name, f"{units:.0f}", INR.format(charge), lkh(rev),
                     lkh(eb), f"{eb / rev * 100:.0f}%",
                     INR.format(eb / tl if tl else 0)])
    return rows


def scenarios_fabric():
    """What a fabric counter earns at different footfall / price points."""
    rows = []
    for mpd, sell, gm, rent in [(12, 420, 0.33, 30000), (20, 500, 0.38, 45000),
                                (32, 540, 0.40, 45000), (50, 560, 0.42, 60000)]:
        global FABRIC_RENT
        old = FABRIC_RENT
        FABRIC_RENT = rent
        f = fabric_month(metres_per_day=mpd, sell=sell, gm=gm)
        FABRIC_RENT = old
        rows.append([f"{mpd} m/day", INR.format(sell), f"{gm * 100:.0f}%",
                     lkh(f["rev"]), lkh(f["gp"]), lkh(f["ebitda"]),
                     f"{f['margin'] * 100:.0f}%"])
    return rows


def main() -> str:
    t = tailoring_month()
    f = fabric_month()
    w = wholesale_month()
    be_fixed, be_contrib, be_units = breakeven_tailoring()
    stock_rows, cap, retail_val = fabric_stock_plan()
    yr_rows, y1, y2, y3 = three_year_plan()
    capex_rows, stage_tot = capex_plan()
    sens = sensitivity()
    ladder = fabric_price_ladder()

    o = []
    a = o.append
    a("# Financial Model — Custom Tailoring + Fabric Business, Jalandhar\n")
    a("_Generated by `model/financial_model.py`. Every number below is an assumption "
      "you can change in the ASSUMPTIONS block. Re-run the script after you change it._\n")

    a("## 1. Stage A — the tailoring workshop (steady month)\n")
    a(table(["Line", "Value"], [
        ["Tailors paid", TAILORS],
        ["Units stitched / month", f"{t['units']:.0f}"],
        ["Blended charge / unit", INR.format(AVG_STITCHING_CHARGE)],
        ["Revenue / month", lkh(t["rev"])],
        ["Revenue / tailor / month", INR.format(t["rev_per_tailor"])],
        ["Consumables (4%)", lkh(t["cons"])],
        ["Labour (3 tailors + cutter + helper)", lkh(t["labour"])],
        ["Rent + electricity + fixed", lkh(t["fixed"])],
        ["Marketing (5%)", lkh(t["mkt"])],
        ["**EBITDA / month**", f"**{lkh(t['ebitda'])}**"],
        ["**EBITDA margin**", f"**{t['margin'] * 100:.1f}%**"],
        ["Annualised EBITDA", lkh(t["ebitda"] * 12)],
    ]))
    a("")
    a(f"**Break-even:** fixed cost {lkh(be_fixed)}/month ÷ contribution "
      f"{INR.format(be_contrib)}/unit = **{be_units:.0f} units a month** "
      f"({be_units / WORKING_DAYS:.1f} units a day). Below that you are paying "
      "the rent from your pocket.\n")
    a("### Scenario comparison — same machines, different positioning\n")
    a(table(["Model", "Units / month", "Charge / unit", "Revenue", "EBITDA",
             "EBITDA %", "EBITDA / tailor / month"], scenarios_tailoring()))
    a("")
    a("**This table is the most important page in the whole plan.** A2 (the typical "
      "Jalandhar tailor shop) barely clears its own salaries — the owner works 12 hours "
      "and takes home less than a bank clerk. A3 earns 4–6× more from *fewer* garments "
      "because the charge per unit carries the design consultation, the fabric, the "
      "trial and the guarantee. The move from A2 to A3 is not a skill upgrade, it is a "
      "**product, pricing and shop-front upgrade** — and it is the whole ladder.\n")

    a("## 2. Stage B — adding the fabric (cloth roll) counter\n")
    a(table(["Line", "Value"], [
        ["Retail metres sold / month", f"{f['metres']:.0f} m"],
        ["Blended retail price / metre", INR.format(FABRIC_AVG_SELL)],
        ["Revenue / month", lkh(f["rev"])],
        ["Gross profit (38% margin)", lkh(f["gp"])],
        ["Gross profit / metre", INR.format(f["gp_per_metre"])],
        ["Wastage + shrinkage (3%)", lkh(f["wastage"])],
        ["Rent + staff + utilities", lkh(f["fixed"])],
        ["**EBITDA / month (fabric counter alone)**", f"**{lkh(f['ebitda'])}**"],
        ["**EBITDA margin**", f"**{f['margin'] * 100:.1f}%**"],
    ]))
    a("")
    a("### Opening fabric stock plan — depth over breadth\n")
    a(table(["Category", "Metres", "Landed ₹/m", "Capital", "Retail ₹/m", "Markup"],
            stock_rows))
    a("")
    a(f"Opening stock capital **{lkh(cap)}**, retail value **{lkh(retail_val)}**. "
      "Rule: no single design more than 40 m until it has sold through once, and "
      "30% of stock value must be in the 10 fastest-moving shades (navy, black, "
      "charcoal, grey, beige, olive, maroon).\n")
    a("### Fabric counter scenarios\n")
    a(table(["Footfall converted", "Retail ₹/m", "Gross margin", "Revenue / month",
             "Gross profit", "EBITDA / month", "EBITDA %"], scenarios_fabric()))
    a("")
    a("Note how EBITDA % *rises* with footfall even though rent rises too — because the "
      "rent is fixed and the margin is per metre. **A fabric shop is a traffic "
      "business.** Everything in the marketing section exists to push metres-per-day "
      "from 12 to 32.\n")

    a("## 3. Stage C — wholesale / distribution to tailors & shops\n")
    a(table(["Line", "Value"], [
        ["Active retail buyers / month", WH_ACTIVE_RETAILERS],
        ["Volume / month", f"{w['vol']:,.0f} m"],
        ["Wholesale price / metre", INR.format(WH_AVG_SELL)],
        ["Revenue / month", lkh(w["rev"])],
        ["Gross profit (15.5%)", lkh(w["gp"])],
        ["Sales team + incentive", lkh(w["team"] + w["inc"])],
        ["Godown + transport + overheads", lkh(w["fixed"] - w["team"] - w["inc"])],
        ["Credit cost (interest + bad-debt provision, 1.6%)", lkh(w["credit"])],
        ["**EBITDA / month**", f"**{lkh(w['ebitda'])}**"],
        ["**EBITDA margin**", f"**{w['margin'] * 100:.1f}%**"],
    ]))
    a("")
    a("Wholesale is a **volume + credit-management** business, not a margin business. "
      "The single killer is receivables: 15% gross margin disappears if one buyer out "
      "of ten defaults. Cap credit at 30 days, cap exposure per buyer, and stop supply "
      "the day a buyer crosses the cap.\n")

    a("## 4. Sample price architecture (fabric ladder)\n")
    a(table(["Category", "Landed ₹/m", "Wholesale ₹/m", "Wh margin",
             "Retail ₹/m", "Retail margin", "3.5 m + stitching package"], ladder))
    a("")
    a("The right-hand column is the money shot: **you are the only shop in your market "
      "that can quote 'cloth + fit + finish' as one price.** Readymade shops cannot "
      "sell the fit; freelance tailors cannot sell the cloth.\n")

    a("## 5. Sensitivity — annual tailoring EBITDA\n")
    a("Rows = blended charge per garment, columns = number of tailors.\n")
    a(table(["Charge / unit", "2 tailors", "3 tailors", "5 tailors", "8 tailors"], sens))
    a("")
    a("Read it this way: **hiring a 4th tailor without raising the average charge is "
      "how tailoring shops die.** Charge per unit must rise faster than headcount.\n")

    a("## 6. Capital required, stage by stage\n")
    a(table(["Stage", "Item", "Cost"], capex_rows))
    a("")
    a(f"Practical funding path: Stage A {lkh(stage_tot['A'])} from own money + Mudra "
      f"Kishor/Tarun; Stage B {lkh(stage_tot['B'])} from Stage A profits + a Mudra "
      f"Tarun Plus / MSME term loan; Stage C {lkh(stage_tot['C'])} from bank working-"
      "capital limit (CC/OD against stock & receivables) once you have 2 years of "
      "filed ITR and GST returns.\n")

    a("## 7. Three-year projection\n")
    a(table(["Revenue line", "Year 1", "Year 2", "Year 3"], yr_rows))
    a("")
    a(f"- Year 1 EBITDA {lkh(y1[1])} on revenue {lkh(y1[0])}\n"
      f"- Year 2 EBITDA {lkh(y2[1])} on revenue {lkh(y2[0])}\n"
      f"- Year 3 EBITDA {lkh(y3[1])} on revenue {lkh(y3[0])}\n")

    a("## 8. Tax snapshot used in this model\n")
    a(table(["What you sell", "GST", "Note"], [
        ["Tailoring / stitching on customer's fabric (SAC 9988)", "5%",
         "Reduced from 18% under GST 2.0 effective 22 Sep 2025"],
        ["Woven / knitted fabric, garment up to ₹2,500 per piece", "5%",
         "Cotton fabric, suiting, shirting all sit here"],
        ["Garment / made-up above ₹2,500 per piece", "18%",
         "Per-piece test, not per-bill — a premium suit crosses this"],
        ["Fashion-design + tailoring bundled as a design service", "18%",
         "If you sell 'design' rather than 'stitching', rate changes — ask your CA"],
        ["Composition scheme limit (services)", "₹50 lakh turnover",
         "Above it you must go regular; goods limit is ₹1.5 Cr (verify with CA)"],
        ["GST registration threshold (Punjab)", "₹40 lakh goods / ₹20 lakh services",
         "Register voluntarily earlier — B2B buyers want a GST invoice"],
    ]))
    a("")
    a("> Confirm the current rate with your CA before printing a bill. GST slabs for "
      "apparel changed in September 2025 and can change again.\n")

    a("## 9. The five numbers to check every Sunday\n")
    a(table(["Number", "Target", "Why it kills you if it slips"], [
        ["Units stitched / tailor / day", "≥ 2.2", "Below 1.8 you cannot pay the salary"],
        ["Average charge / unit", "rising 10%/yr", "Flat charge = shrinking real margin"],
        ["Fabric stock turn", "≥ 6× a year", "Dead rolls eat your working capital"],
        ["Receivables days (wholesale)", "≤ 35 days", "Above 60 days you are the bank"],
        ["Repeat-customer share", "≥ 45% by Y2", "Below 30% your product has a problem"],
    ]))
    return "\n".join(o)


if __name__ == "__main__":
    print(main())
