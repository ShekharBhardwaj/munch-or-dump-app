I now have full context on the existing tokens, the verdict enum, and the palette extension. Here is the build spec.

---

# Munch or Dump — Flutter Look-and-Feel Spec (Website Parity)

**Goal:** make the Flutter Home + Result screens read as the same editorial product as the website: warm paper canvas, graph-paper grid, ultra-letter-spaced eyebrows, two-tone bold/muted headlines, a pure-black pill CTA, saturated verdict color, and dense ingredient rows. The current theme is "calm/generic" because its neutrals drift warm-grey and its accents are softened. This spec retunes the neutrals to the website's exact values and adds the missing editorial primitives.

> **Reconciliation note (read first).** The existing `AppColors` keeps verdict hexes that match the website's *ShareCard* palette, not the *web UI*. For screen parity you must use the **web UI** verdict tones below (they differ for several verdicts: ENGINEERED indigo `#6366F1` not violet `#8B5CF6`; BULLSHIT fuchsia `#D946EF` for badges; OKAY `#0EA5E9` bar). Keep the existing `munch/okay/...` constants for share cards, but add a **`VerdictWebPalette`** set for on-screen UI. Likewise, retune `canvas`, `inkPrimary`, `inkSecondary`, `inkMuted`, `hairline` to the exact stone values in §1 — the current warm-grey versions are a big part of why it feels generic.

---

## 1. DESIGN TOKENS

### 1.1 Neutrals (retune existing constants to these exact values)

| Token | Hex | Flutter `Color(...)` | Web source | Current value to replace |
|---|---|---|---|---|
| **Page cream** (`canvas`) | `#F8F7F4` | `0xFFF8F7F4` | `bg-[#F8F7F4]` | was `#F6F6F3` |
| Card surface | `#FFFFFF` | `0xFFFFFFFF` | `bg-white` | keep |
| **Ink** (headings) | `#1C1917` | `0xFF1C1917` | stone-900 | was `#17181C`; existing `AppColors.ink` already `#1C1917` — make this the primary |
| **Muted ink** (body) | `#78716C` | `0xFF78716C` | stone-500 | was `#646973`; existing `AppColors.mutedInk` already correct |
| Faint ink (eyebrows, captions) | `#A8A29E` | `0xFFA8A29E` | stone-400 | was `#9CA0A8` |
| Ghost ink (placeholders, "Unknown") | `#D6D3D1` | `0xFFD6D3D1` | stone-300 | was — add |
| **Hairline** (borders) | `#E7E5E4` | `0xFFE7E5E4` | stone-200 | was `#E9E7E1`; close, retune |
| Hairline-faint (row dividers) | `#F5F5F4` | `0xFFF5F5F4` | stone-100 | add |
| **BLACK CTA** | `#0C0A09` | `0xFF0C0A09` | stone-950 | add (current uses brand emerald for filled buttons — wrong for the hero CTA) |
| CTA hover/pressed | `#292524` | `0xFF292524` | stone-800 | add |

> The eyebrow/faint distinction matters: stone-400 (`#A8A29E`) for eyebrows, stone-500 (`#78716C`) for trust-line muted body, stone-300 (`#D6D3D1`) for empty-state text.

### 1.2 Verdict colors — **web UI palette** (use these on screen)

Each verdict needs five roles. Build a lookup keyed by the existing `Verdict` enum.

| Verdict | `text` (deep, on-card word) | `accent` (bar/stripe) | `tintBg` | `border` | `dot/badge fill` |
|---|---|---|---|---|---|
| **MUNCH** | `#065F46` emerald-800 | `#10B981` | `#ECFDF5` emerald-50 | `#A7F3D0` emerald-200 | `#10B981` |
| **OKAY** | `#075985` sky-800 | `#0EA5E9` (bar) / `#38BDF8` (badge dot) | `#F0F9FF` sky-50 | `#BAE6FD` sky-200 | `#38BDF8` |
| **TREAT** | `#92400E` amber-800 | `#F59E0B` | `#FFFBEB` amber-50 | `#FDE68A` amber-200 | `#F59E0B` |
| **ENGINEERED** | `#3730A3` indigo-800 | `#6366F1` (badge) / `#818CF8` (hero bar) | `#EEF2FF` indigo-50 | `#C7D2FE` indigo-200 | `#6366F1` |
| **DUMP** | `#7F1D1D` red-800 | `#EF4444` (badge) / `#DC2626` (hero bar) | `#FEF2F2` red-50 | `#FECACA` red-200 | `#EF4444` |
| **BULLSHIT** | `#581C87` purple-900 | `#A855F7` (hero bar `#9333EA`/purple-700) | `#FAF5FF` purple-50 / `#FDF4FF` fuchsia-50 | `#F5D0FE` fuchsia-200 | `#D946EF` fuchsia-500 |

Flutter constants (add to a `VerdictWebPalette`):
```dart
// hero/percentile accent (brighter) — for ImpactScore bar, hero top border
munchAccentUi=0xFF10B981, okayAccentUi=0xFF0EA5E9, treatAccentUi=0xFFF59E0B,
engineeredAccentUi=0xFF818CF8, dumpAccentUi=0xFFDC2626, bullshitAccentUi=0xFF9333EA
// deep word color — for the huge verdict word + percentile text uses a mid accent:
//   munch #10B981, okay #0EA5E9, treat #F59E0B, engineered #818CF8, dump #F87171, bullshit #D8B4FE
```

### 1.3 Concern colors (ingredient severity — 4 tiers)

| Level | Dot | Row tint | Name text | Badge bg / text | Expanded body text |
|---|---|---|---|---|---|
| High Concern | `#EF4444` red-500 | `#FEF2F2` red-50 | `#7F1D1D` red-900, w600 | `#FEE2E2` / `#B91C1C` | `#991B1B` red-800 |
| Concerning | `#FB923C` orange-400 | `#FFF7ED` orange-50 | `#7C2D12` orange-900, w600 | `#FFEDD5` / `#B45309` | `#9A3412` orange-800 |
| Moderate | `#FBBF24` amber-400 | none | `#44403C` stone-700 | — (no badge) | `#57534E` stone-600 |
| Safe | `#34D399` emerald-400 | none | `#A8A29E` stone-400 | — | `#78716C` stone-500 |

Impact score: positive `#16A34A` emerald-600 (prefix `+`), negative `#EF4444` red-500 (prefix `-`); only render when `score.abs() >= 2`.

### 1.4 Font decision

Website uses the **system stack** (San Francisco on iOS) at weights 900/700/600/500/400. The Flutter app currently loads **Inter via google_fonts**.

**Decision: keep Inter** — it is closer to SF than any web fallback, ships consistently across iOS/Android, and the app already themes it. The editorial feel comes from **weight + letter-spacing + two-tone color**, not the typeface. Concretely:
- Headlines: `FontWeight.w800` (the website's `font-bold` 700 reads heavier in SF; w800 Inter matches the optical weight). `letterSpacing: -0.5` to `-1.0`, `height: 1.05`.
- Verdict word: `FontWeight.w900` (`font-black`), `letterSpacing: -1.5`, `height: 1.0`, uppercase.
- Eyebrows/badges: see §1.5.

### 1.5 Eyebrow / label style (the signature move)

| Label kind | Size | Weight | LetterSpacing | Transform | Color |
|---|---|---|---|---|---|
| Eyebrow (hero/section) | 12 | w600 | **5.5** (≈0.4em) | UPPERCASE | `#A8A29E` |
| Eyebrow (card category) | 10 | w600 | **3.0** (≈0.3em) | UPPERCASE | `#A8A29E` |
| "VERDICT" eyebrow (result) | 10 | w600 | **4.5** (≈0.45em) | UPPERCASE | `#A8A29E` |
| Section label ("INGREDIENTS") | 12 | w600 | **4.2** (≈0.35em) | UPPERCASE | `#A8A29E` |
| Verdict badge text | 10–12 | **w900** | **1.5** (`tracking-widest`) | UPPERCASE | per-verdict `text` |
| Percentile line | 12 | w600 | **3.0** (≈0.25em) | UPPERCASE | per-verdict accent |
| Per-row badge ("CONCERNING") | 10 | w600 | **0.8** (`tracking-wide`) | UPPERCASE | per-concern |

> Flutter `letterSpacing` is in **logical px**, not em. Convert `Xem * fontSizePx`. e.g. `0.4em` at 12px = **4.8px** — round to 5.5 for optical match since Inter is slightly tighter than SF. Apply spacing as the table prescribes; do not guess.

### 1.6 Radii

| Token | Value | Use |
|---|---|---|
| `rPill` | 999 (`StadiumBorder`) | badges, CTA, pills |
| `rCard` | 16 | cards, search, ingredient container (`rounded-2xl`) |
| `rCardSm` | 12 | claim cards (`rounded-xl`) |
| `rBadgeSm` | 8 | BETA badge, small chips |

> The current `cardTheme` uses radius 18 — change to **16** for web parity.

### 1.7 Spacing scale (use these literals)

`4, 6, 8, 12, 16, 20, 24, 40`. Card interior padding = **24** (`p-6`). Hero vertical = **40** (`pt-10 pb-10`). Search field padding = `20 h × 16 v` (`px-5 py-4`). Content max width = **800** (center + clamp on tablet); search field max = **600**.

### 1.8 Shadows

Subtle and warm — never the default Material grey elevation. Use explicit `BoxShadow`:

```dart
// card resting (shadow-sm)
BoxShadow(color: Color(0x0A1C1917), blurRadius: 8, offset: Offset(0, 2))
// card hover/elevated (shadow-lg)
BoxShadow(color: Color(0x141C1917), blurRadius: 24, offset: Offset(0, 8))
// amber CTA glow (For You unlock button)
BoxShadow(color: Color(0x66F59E0B), blurRadius: 12, offset: Offset(0, 2))
// dark For-You card
BoxShadow(color: Color(0x14FBBF24), blurRadius: 24), BoxShadow(color: Color(0x4D000000), blurRadius: 4, offset: Offset(0,1))
```
Set `Card.elevation: 0` everywhere (already done) and draw shadows manually via `Container(decoration: BoxDecoration(boxShadow: ...))`.

---

## 2. THE GRAPH-PAPER GRID BACKGROUND

A `CustomPainter` drawing a uniform square grid, sitting behind hero/result content on the cream canvas.

**Exact numbers (from web `repeating-linear-gradient`, opacity 0.022):**
- Cell size: **60.0** logical px (both axes).
- Line color: pure black `#000000` at **alpha 0.022** → `Color(0x06000000)` (0.022 × 255 ≈ 5.6 → `0x06`). Use `Color.fromRGBO(0, 0, 0, 0.022)` to be exact.
- Line thickness (`strokeWidth`): **1.0**.
- Fade: **none** on the website (uniform). **Recommendation for mobile:** add a gentle top-down fade so the grid doesn't fight content lower on a scrolling screen — paint at full 0.022 in the top ~420px, then fade to 0 by ~640px using a `ui.Gradient`-driven alpha or a `ShaderMask`. This is optional; if you want strict parity, omit it and keep it uniform.

```dart
class GraphPaperPainter extends CustomPainter {
  const GraphPaperPainter({this.cell = 60, this.fade = true});
  final double cell;
  final bool fade;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromRGBO(0, 0, 0, 0.022)
      ..strokeWidth = 1.0
      ..isAntiAlias = false;
    for (double x = 0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GraphPaperPainter old) => old.cell != cell;
}
```
Usage: stack it under content — `Stack(children: [Positioned.fill(child: CustomPaint(painter: GraphPaperPainter())), content])`. For the optional fade, wrap the `CustomPaint` in a `ShaderMask` with a vertical `LinearGradient(colors:[white, transparent], stops:[0.55, 1.0])` and `BlendMode.dstIn`. Keep `isAntiAlias = false` so 1px lines stay crisp.

---

## 3. SHARED PRIMITIVES TO BUILD

Build these as small stateless widgets in `lib/core/widgets/`. Each spec below is exact.

### 3.1 `Eyebrow`
Letter-spaced uppercase label. Props: `text`, `size = 12`, `spacing = 5.5`, `color = #A8A29E`.
```
Text(text.toUpperCase(), style: TextStyle(fontSize: size, fontWeight: FontWeight.w600,
  letterSpacing: spacing, color: color))
```
Variants by passing size/spacing: hero (12/5.5), card category (10/3.0), section (12/4.2).

### 3.2 `TwoToneHeadline`
Two strings: `dark` and `muted`, stacked or wrapped. `dark` → ink `#1C1917`; `muted` → `#A8A29E`. Style: w800, `height: 1.05`, `letterSpacing: -0.8`, responsive size (mobile 34, tablet 44). Render as a single `RichText`/`Text.rich` with two `TextSpan`s so the muted phrase can wrap naturally (it usually starts the second line). Example copy renders as: **"Know what you're"** (dark) + **"really eating."** (muted).

### 3.3 `BlackCtaButton`
Pure-black pill. Props: `label`, `leadingIcon`, `trailingIcon`, `onTap`.
- Background `#0C0A09`, pressed `#292524`.
- Shape `StadiumBorder`, height **48** (`h-12`), horizontal padding **32** (`px-8`).
- Label: white, w600, size 14.
- Icons: leading `Icons.file_upload_outlined` (15px), trailing `Icons.arrow_forward` (14px), gap **10** (`gap-2.5`). On press, nudge trailing icon `+2px` x (mirror `group-hover:translate-x-0.5`).
- Shadow: card-sm resting → card-hover on press.
> This must NOT use the themed `FilledButton` (which is emerald). Build it bespoke with `InkWell` + `Container`.

### 3.4 `VerdictBadge`
Pill: `[dot] WORD`. Props: `verdict`, `size` ∈ {sm, md, lg, xl}.
- Layout: `Row(mainAxisSize.min)` → dot (6×6 circle, `dot` color) + gap 6 + text.
- Text: w900, UPPERCASE, `letterSpacing 1.5`, color = verdict `text`.
- Container: `tintBg` fill, 1px `border` color, `StadiumBorder`.
- Padding by size: sm `12h/4v` (text 12), md `16h/6v` (text 14), lg `20h/8v` (text 16), xl text 56–96 / padding `0h/16v` (no border fill at xl — used as the hero word, see §6).

### 3.5 `AccentTopBorderCard`
White card with a colored **top stripe**. Props: `accentColor`, `child`, `dashed = false`.
- Outer: `ClipRRect(radius 16)` over a `Container(white, border: 1px #F5F5F4 (or #E7E5E4 on hover), boxShadow: card-sm)`.
- First child = `Container(height: 4, width: ∞, color: accentColor)` (the stripe; `h-1`). Hero variant uses height **8** (`h-2`).
- `dashed: true` → border becomes dashed `#D6D3D1` at 80% opacity (use a `DashedBorder` painter or a package) for "pending/under review".
- Body padding **24**.

### 3.6 `Pill` (country / NOVA / dietary variants)
Generic small pill. Props: `text`, `bg`, `border`, `fg`, `leading` (emoji/icon string), `bold`.
- Style: size 10, w700 (NOVA/dietary) or w600 (country), UPPERCASE for NOVA/dietary, `letterSpacing 0.6`, padding `10h/4v` (`px-2.5 py-1`), `StadiumBorder`, 1px border.
- **NOVA** (`nova_group` → config):
  - 1 → `"NOVA 1 · Unprocessed"` bg `#ECFDF5` / border `#A7F3D0` / fg `#047857`
  - 2 → `"NOVA 2 · Culinary Ingredient"` lime: bg `#F7FEE7` / border `#D9F99D` / fg `#4D7C0F`
  - 3 → `"NOVA 3 · Processed"` bg `#FFFBEB` / border `#FDE68A` / fg `#B45309`
  - 4 → `"NOVA 4 · Ultra-processed"` bg `#FEF2F2` / border `#FECACA` / fg `#DC2626`
- **Country**: neutral — bg `#FAFAF9` / border `#E7E5E4` / fg `#57534E`, leading = flag emoji, format `"🇺🇸 United States"`, NOT uppercase.
- **Dietary positive** (`free: true`): `"✓ Vegan"` etc. — bg `#ECFDF5` / border `#A7F3D0` / fg `#047857`. Keys+labels: `is_vegan→Vegan, is_vegetarian→Vegetarian, is_gluten_free→Gluten Free, is_dairy_free→Dairy Free`.
- **Dietary warning** (`free: false`): `"⚠ Contains Nuts"` etc. — bg `#FEF2F2` / border `#FECACA` / fg `#DC2626`. Keys: `contains_nuts→Contains Nuts, contains_soy→Contains Soy, contains_eggs→Contains Eggs`.

### 3.7 `ConcernDot`
Circle, color from §1.3. Two sizes: row dot **8×8**, legend dot **6×6**. `rounded-full`, no border.

### 3.8 `ImpactScore`
Signed number. Props: `score`. Render only if `score.abs() >= 2`. Text: `"${score>0?'+':''}$score"`, w700, size 12, `fontFeatures:[FontFeature.tabularFigures()]`, color `#16A34A` if positive else `#EF4444`.

### 3.9 `SectionLabel`
Eyebrow flanked by hairlines (the "Recently Analyzed" divider). Layout: `Row(Expanded(Divider 1px #E7E5E4), padding 16h Eyebrow, Expanded(Divider))`. Eyebrow style = section variant (12/4.2/`#A8A29E`), `softWrap: false`.

### 3.10 `GridBackground`
Wrapper that stacks `GraphPaperPainter` under a child on the cream canvas. Props: `child`, `fade = true`. Used by Home hero and Result hero region.

---

## 4. NAVBAR

A custom top bar (not a plain `AppBar` title) pinned at the top of Home. Height **64** (mobile). Background transparent at rest; on scroll past ~20px → `Colors.white.withOpacity(0.8)` + `BackdropFilter(blur: 16)` + 1px bottom border `#E7E5E4` at 60% opacity + card-sm shadow. Animate over 300–500ms.

**Wordmark** — `Text.rich`, base size 20 (`text-xl`), `letterSpacing: -0.4` (`tracking-tight`):
- `"Munch"` → w700, color `#1C1917`
- `"or"` → w300, color `#A8A29E`, with horizontal padding **4** each side (`mx-1`)
- `"Dump"` → w700, color `#1C1917`

```dart
Text.rich(TextSpan(children: [
  TextSpan(text: 'Munch', style: bold),
  TextSpan(text: ' or ', style: light),   // light w300, #A8A29E
  TextSpan(text: 'Dump', style: bold),
]))
```

**BETA badge** (to the right of the wordmark): `Container` with 1px border `#D6D3D1`, radius **8** (`rounded`), padding `6h/2v`, child `Text("BETA")` size **9**, w600, UPPERCASE, `letterSpacing 1.5` (`tracking-widest`), color `#A8A29E`, `height: 1.0` (leading-none).

Right side of nav (optional for the rebuild): a compact black "Analyze" pill mirroring §3.3 at sm size, or a search icon. On mobile keep it minimal — wordmark + BETA left, single avatar/menu icon right (`#44403C`).

---

## 5. HOME SCREEN

Scroll view over `GridBackground`. Center column, max content width 800, generous vertical rhythm. Top to bottom:

1. **Navbar** (§4), then ~24 top gap below it before hero content.

2. **Eyebrow** (centered): `"INGREDIENT INTELLIGENCE"` — §3.1 hero variant (12/5.5/`#A8A29E`). Margin-bottom ~16.

3. **Two-tone headline** (centered, §3.2). Verbatim default copy:
   - dark: `Know what you're`
   - muted: `really eating.`
   (You may later rotate the 12 monthly variants; ship the default now. Other examples for reference, dark / muted: `Whole food` / `or chemistry project?` · `The real horror` / `is in the ingredient list.` · `Eat what you want.` / `Just know what it is.`) Margin-bottom ~20.

4. **Subhead** (centered, max width 500): verbatim
   `Scan what you're actually putting in your body — not what the label wants you to think.`
   Style: size 18 (mobile) / 20, color `#78716C`, `height: 1.5`, w400. Margin-bottom ~24.

5. **Search field** (max width 600, center): `Container` white, radius 16, 1px border `#E7E5E4` (→ `#D6D3D1` + card-md shadow when focused/active), padding `16h × 14v`, `Row`: `Icon(Icons.search, 16, #A8A29E)` + gap 12 + `TextField` (hint `Search a product or brand…`, hint color `#A8A29E`, text `#292524`, size 14, no border). Margin-bottom ~16.

6. **BLACK CTA** (§3.3, centered): label `Analyze a product`, leading `Icons.file_upload_outlined` (15), trailing `Icons.arrow_forward` (14). Margin-bottom ~12.

7. **Caption** (centered): verbatim `Photo · Barcode · Search — verdict in seconds` — size 12, color `#A8A29E`. Margin-bottom ~24.

8. **Trust taglines** (centered, `Wrap` with `gap-x-24 gap-y-8`): three items, each `Text.rich` size 12 — bold part w700 `#292524`, regular part w400 `#78716C`:
   - **`No brand deals.`** ` Ever.`
   - **`Every red flag`** ` named by ingredient.`
   - **`DUMP means dump.`** ` No softening.`
   Margin-bottom ~40.

9. **Section label** (§3.9): `RECENTLY ANALYZED` flanked by hairlines. Margin-bottom ~24.

10. **"Recently analyzed" cards** — list/grid of `AccentTopBorderCard` (§3.5), accent = verdict `accent` color. Each card interior (padding 24):
    - **Row 1:** left = optional flag emoji + `Eyebrow` category (10/3.0, e.g. `FOOD`); right = `VerdictBadge` size sm. `crossAxisAlignment: start`, `spaceBetween`. Margin-bottom ~12.
    - **Row 2:** product name — size 16, w700, `#1C1917`, `height: 1.25`, max 2 lines ellipsis. Empty → `Unknown product` italic w400 `#D6D3D1`. Margin-bottom ~4.
    - **Row 3 (optional):** percentile — `Eyebrow`-style 10/2.0 `#A8A29E`, e.g. `TOP 15% OF SNACKS`. Margin-bottom ~12.
    - **Row 4:** italic take — `short_explanation`, `FontStyle.italic`, size 14, `#78716C`, `height: 1.5`, max 2 lines ellipsis.
    - Pending state → `dashed: true` + 80% opacity + a small `Under Review` neutral pill in Row 1 right.

---

## 6. RESULT SCREEN

Scrollable. The hero region sits on `GridBackground`; below it, white cards on cream. Order:

### 6.1 Product header (above the verdict banner)
- **Eyebrow:** `"${category} · Product Analysis"` UPPERCASE, 12/4.5-ish (`tracking-[0.3em]`→3.6), w500, `#A8A29E`. e.g. `FOOD · PRODUCT ANALYSIS`.
- **Title:** product name, size 30 (mobile) / 36, w700, `#1C1917`, `letterSpacing -0.6`, `height: 1.1`.
- **Meta line:** size 12, `#A8A29E`: `munchordump.com/p/{slug}` then optional `···{last4 barcode}` (monospace, `letterSpacing 1.2`) then optional `· {viewCount} views`.
- **Action row** (`Wrap`, gap 12, small pills size 12 w600, padding `12h/6v`, `StadiumBorder`): `Watch this product` (neutral → amber-tinted `#FFFBEB`/`#FDE68A`/`#B45309` when active, star icon 11) · `Add to cart` (neutral → black `#0C0A09` text white when in cart, basket/check icon 11) · `{brand} brand report →` (text link `#A8A29E`→`#44403C`).

### 6.2 Verdict hero — the centerpiece
A single `AccentTopBorderCard`-style block but **full-bleed within the content column**, centered text:
- **Top border:** height **8**, color = verdict hero bar (MUNCH `#10B981`, OKAY `#0EA5E9`, TREAT `#F59E0B`, ENGINEERED `#818CF8`, DUMP `#DC2626`, BULLSHIT `#9333EA`).
- **Panel background:** verdict `tintBg` (the -50 tint), padding `24h × 40v`, centered.
- **Eyebrow:** `VERDICT` — 10/4.5 (`tracking-[0.45em]`), w600, `#A8A29E`. Margin-bottom ~12.
- **Huge verdict word:** the verdict text, w900, UPPERCASE, `letterSpacing -1.5`, `height: 1.0`, color = verdict `text` deep tone (§1.2 col 1). Size by word length (clamp to screen width):
  - OKAY (4) → ~96 (clamp 80–144)
  - MUNCH/TREAT/DUMP (5) → ~80 (clamp 72–128)
  - BULLSHIT (8) → ~56 (clamp 48–80)
  - ENGINEERED (10) → ~40 (clamp 36–56)
  Implement with `FittedBox(fit: scaleDown)` inside a max-width box so long words never overflow. Margin-bottom ~12.
- **Percentile line:** 12, w600, UPPERCASE, `letterSpacing 3.0`, color = verdict mid accent (munch `#10B981`, okay `#0EA5E9`, treat `#F59E0B`, engineered `#818CF8`, dump `#F87171`, bullshit `#D8B4FE`). **Formula (port exactly):**
  ```
  if (categoryRank != null && categoryTotal != null && categoryTotal > 1)
      → "${ordinal(categoryRank)} cleanest of $categoryTotal ${(subcategory??category??'products').toLowerCase()}"
  else if (percentileRank == null) → render nothing
  else if (percentileRank >= 50)   → "Top ${100 - percentileRank}% of ${(category??'products').toLowerCase()}"
  else                             → "Bottom ${max(percentileRank + 1, 1)}% of ${(category??'products').toLowerCase()}"
  ```
  Examples: pr=10 → `BOTTOM 11% OF FOOD`; pr=75 → `TOP 25% OF FOOD`; rank=3/total=150 → `3RD CLEANEST OF 150 PRODUCTS`. Margin-top ~20.
- **Pill row** (`Wrap`, center, gap 6, margin-top 20): country pill, then NOVA pill, then dietary pills (§3.6) — positives first, then warnings.

### 6.3 Dark gated "FOR YOU" card
`Container`, radius 16, `ClipRRect`. Background = `LinearGradient(begin: topLeft, end: bottomRight, colors:[#1C1710, #2A1E0D, #1A1508], stops:[0,0.5,1])`. Border 1px `#5C3A0E` at ~30% (amber-900/30 → `Color(0x4D78350F)`). Shadows: `0x14FBBF24 blur24` + `0x4D000000 blur4 y1`.

**Signed-out (gated) state:**
- Padding `20h, top 20, bottom 64` (room for the lock overlay).
- `Row`: sparkle icon + `Column`: header + **blurred** dummy note. Note text size 14, w500, color `#E5C97A` (`rgba(253,230,138,0.9)`), wrapped in `ImageFiltered(ImageFilter.blur(sigmaX:6,sigmaY:6))`, `IgnorePointer` + non-selectable. Use the per-verdict dummy note string.
- **Lock overlay** (centered near bottom): a 36×36 circle, fill `Color(0x1FFBBF24)`, 1px border `Color(0x4DFBBF24)`, glow shadow `0x33FBBF24 blur16`, child `Icon(Icons.lock_outline, 15, #FBBF24)`.
- Headline under lock: `Your personalized take is ready` — size 12, w600, centered, color `#CCB066` (`rgba(253,230,138,0.8)`).
- **Amber CTA:** label `Sign in to unlock`, size 12, w700, white, padding `16h/8v`, `StadiumBorder`, background `LinearGradient(135°, [#F59E0B, #D97706])`, shadow `0x66F59E0B blur12 y2`. Routes to login.

**Signed-in + profile + note:** same card, no blur/lock; show real `profileNote` (size 14, w500, `#E5C97A`), then optional signal labels (`signalLabels.join(" · ")`, size 10, `letterSpacing 0.5`, `Color(0x66FBBF24)`), then if AI-tailored `tailored for you ✦` (size 9, `Color(0x59FBBF24)`).

**Signed-in, no profile:** same card; body size 14 `Color(0xB3FDE68A)` with inline link `Set up your profile` (w600, underlined, `#FBBF24`) `+ " to unlock a personalized take on every product."`

### 6.4 Ingredient breakdown
White `Container`, radius 16, 1px border `#E7E5E4`, `ClipRRect`, rows divided by 1px `#F5F5F4`.

- **Header** (padding 24h/16v, `Row` baseline, gap 12): `SectionLabel`-style text `INGREDIENTS` (12/4.2, `#A8A29E`) + count `"$total total"` (size 11, `#D6D3D1`) + if `flagCount>0` ` · $flagCount flagged` (size 11, `#DC2626` red-400-ish — use `#F87171`).
- **Rows** (sorted: flagged first, then by score; safe ones collapsed past a preview of 8). Each row:
  - Background = concern row tint (High `#FEF2F2`, Concerning `#FFF7ED`, else none).
  - Padding `20h/12v`, `Row(crossAxis center, gap 12)`:
    - `ConcernDot` (8×8, §3.7)
    - **Name** (`Expanded`): tappable (navigates to ingredient page) size 14, `height: 1.25`, color+weight per §1.3 (High/Concerning w600 + dark red/orange; Moderate `#44403C`; Safe `#A8A29E`).
    - optional **per-row badge** (only High/Concerning): `Pill`-like, text `HIGH CONCERN` / `CONCERNING`, size 10, w600, UPPERCASE, `letterSpacing 0.8`, padding `8h/2v`, radius pill, colors per §1.3.
    - optional **`ImpactScore`** (§3.8).
    - optional **expand chevron** (only if `explanation != null`): `Icon` or glyph `▾`, size 10, `#A8A29E`, rotate 180° (`AnimatedRotation`, 200ms) when open.
  - **Expanded body** (animate height + fade, 200ms — use `AnimatedSize` + `AnimatedOpacity`): padding `left 40, right 20, vertical 12`, text size 14, `height: 1.5`, color per §1.3 expanded column.
- **"Show more"** (when safe rows collapsed): full-width left-aligned button, padding `20h/12v`, text size 12, `#A8A29E` → `#44403C` on press, bg `#F5F5F4` on press. Copy: `Show $hiddenCount more clean ingredient${hiddenCount==1?'':'s'} →`.
- **Legend** (below container, `Wrap` gap 20, margin-top 12): four items, each 6×6 `ConcernDot` + label size 10 `#A8A29E`: `High Concern`, `Concerning`, `Moderate`, `Safe` (in that order, matching colors red-500 / orange-400 / amber-400 / emerald-400).

### 6.5 Marketing / misleading-claim treatment
Two pieces:

**(a) HealthWash / Honesty Score badge** — `Container` radius 16, padding 20, bg = level tint, 1px border = level border. Top `Row spaceBetween`: left `Column` → `Eyebrow` `HONESTY SCORE` (10/3.5, `#A8A29E`) + level label (size 14, w700, level color); right → big score `Text("$score", size 30, w900, tabularFigures, level color)` + `"/10"` (size 14, w500, `#A8A29E`) + caption `higher = more honest` (size 9, `#A8A29E`). Then a **progress bar**: track `#F5F5F4` height 6 radius pill, fill width `score/10`, height 6, level bar color, `AnimatedContainer` 700ms. Under it `Row spaceBetween`: `0 · Deceptive` / `10 · Honest` (size 9, `#A8A29E`). Then `desc` paragraph (size 12, `#78716C`, `height 1.5`). If misleading claims exist, a divider (1px `#E7E5E4`) + `Eyebrow MISLEADING CLAIMS` + each: `"${claim}"` (size 12, w600, `#44403C`) over `reality` (size 12, `#78716C`).

Honesty levels (displayScore → label / text / barFill, tint always the family -50):
| Score | Label | text / bar |
|---|---|---|
| 10 | Completely Honest | `#047857` / `#10B981` |
| 8–9 | Mostly Honest | `#059669` / `#34D399` |
| 6–7 | Somewhat Misleading | `#B45309` / `#FBBF24` |
| 4–5 | Misleading | `#C2410C` / `#F97316` |
| 2–3 | Health-Washing | `#B91C1C` / `#EF4444` |
| 0–1 | Extreme Health-Washing | `#991B1B` / `#DC2626` |
Descriptions verbatim: 10 `No misleading claims — marketing matches reality.` · 8–9 `Minor puffery, nothing meaningfully deceptive.` · 6–7 `Claims are technically true but selectively framed.` · 4–5 `Marketing significantly overstates product quality.` · 2–3 `Product markets itself as healthy despite being harmful.` · 0–1 `False or highly deceptive health claims on harmful product.`

**(b) Per-claim card** — white `Container` radius 12, padding 20, 1px border = `#FECACA`@80% if misleading else `#E7E5E4`@60%. `Row(start, gap 12)`: a 32×32 circle icon badge (misleading → bg `#FEF2F2`, `Icons.warning_amber_rounded` 14 `#EF4444`; verified → bg `#ECFDF5`, `Icons.check` 14 `#10B981`) + `Column`: `Eyebrow CLAIM` (12, w600, `letterSpacing 1.0`, `#A8A29E`) over `"${claim}"` (size 14, w500, `#292524`), then `Eyebrow REALITY` over `reality` (size 14, `#57534E`).

---

## Build order (suggested)
1. Retune `AppColors` neutrals (§1.1) + add `VerdictWebPalette` (§1.2) and concern colors (§1.3). Fix `cardTheme` radius 16, add the bespoke black CTA color.
2. Ship `GraphPaperPainter` + `GridBackground` (§2, §3.10).
3. Build primitives §3.1–§3.9.
4. Build Navbar (§4), then rebuild Home (§5).
5. Rebuild Result hero (§6.1–6.2), then For-You (§6.3), ingredients (§6.4), claims (§6.5).

**Relevant existing files:**
- `/Users/shekhar/custom_softwares/munchordump/munch-or-dump-app/lib/core/theme/app_colors.dart` — retune neutrals; add web-UI verdict + concern constants.
- `/Users/shekhar/custom_softwares/munchordump/munch-or-dump-app/lib/core/theme/app_theme.dart` — card radius 16; ensure the black CTA is bespoke (do not reuse the emerald `FilledButton`).
- `/Users/shekhar/custom_softwares/munchordump/munch-or-dump-app/lib/core/theme/verdict_palette.dart` — extend (or add a sibling extension) so `colorFor` can return the web-UI `text`/`accent`/`tintBg`/`border` roles, not just one color.