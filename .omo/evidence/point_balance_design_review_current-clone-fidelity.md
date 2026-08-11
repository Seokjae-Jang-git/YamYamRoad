# Point Balance Redesign — Observable Visual Fidelity Review

## Recommendation

**APPROVE**

The current 390×844 widget-test captures show no observable layout, hierarchy, or overflow defect. The balance UI is composed from live reusable Flutter widgets and uses the feature-local `PointBalanceColors` palette. Existing feature-local literal styling is in scope for this repository and is not a blocker for this review.

## Evidence inspected

- Current uncommitted source:
  - `lib/point/point_main_screen.dart`
  - `lib/point/widgets/point_balance_widgets.dart`
  - `lib/point/widgets/point_shop_dialogs.dart`
  - `lib/point/widgets/point_shop_tab_bar.dart`
- Current preview harness and balance semantics:
  - `lib/point/point_balance_redesign_preview_test.dart`
  - `lib/point/logic/point_usage_calculator.dart`
- Current 390×844 logical / 1170×2532 physical widget-test captures:
  - `lib/point/goldens/redesign_point_balance_header.png`
  - `lib/point/goldens/redesign_point_purchase_confirm.png`
  - `lib/point/goldens/redesign_point_purchase_complete.png`

The test font renders Korean glyphs as tofu squares. The screenshots were therefore judged for geometry, hierarchy, panel spacing, and clipping; source was checked for the Korean copy and the displayed balance semantics.

## Findings

### CRITICAL

None.

### HIGH

None.

### MEDIUM

None.

### LOW

None observed in the supplied states.

## Verified behavior

- The app bar keeps a short title on the left and a right-aligned total/free/paid disclosure via the live `PointBalanceHeader` ([point_main_screen.dart:101](../../lib/point/point_main_screen.dart#L101)–[point_main_screen.dart:120](../../lib/point/point_main_screen.dart#L120), [point_balance_widgets.dart:52](../../lib/point/widgets/point_balance_widgets.dart#L52)–[point_balance_widgets.dart:80](../../lib/point/widgets/point_balance_widgets.dart#L80)). The header capture fits all visible elements without collision or clipping.
- The confirmation dialog has a clear current → used → remaining sequence, with free and paid amounts in every balance/usage panel and an explicit free-first note ([point_shop_dialogs.dart:46](../../lib/point/widgets/point_shop_dialogs.dart#L46)–[point_shop_dialogs.dart:67](../../lib/point/widgets/point_shop_dialogs.dart#L67)). Its capture has no panel or action-row overlap.
- The completion dialog clearly reports the free and paid amounts actually used and the current remaining free/paid balance ([point_shop_dialogs.dart:147](../../lib/point/widgets/point_shop_dialogs.dart#L147)–[point_shop_dialogs.dart:155](../../lib/point/widgets/point_shop_dialogs.dart#L155)). Repeating the free-first sentence here is optional because the displayed usage already makes the allocation observable.
- `PointUsageCalculator` consumes free points before paid points ([point_usage_calculator.dart:44](../../lib/point/logic/point_usage_calculator.dart#L44)–[point_usage_calculator.dart:53](../../lib/point/logic/point_usage_calculator.dart#L53)); the preview values show 1,000 free and 500 paid consumed for a 1,500-point purchase.
- The creamy ivory surface, chocolate text, muted brown labels, and coral emphasis are visually consistent across the header, tabs, panels, dialogs, and primary action. The balance view is a real widget hierarchy using `PointBalanceHeader`, `PointBalancePanel`, `PointUsagePanel`, `PointAmountRow`, and `_PointSummaryPanel` ([point_balance_widgets.dart:17](../../lib/point/widgets/point_balance_widgets.dart#L17)–[point_balance_widgets.dart:227](../../lib/point/widgets/point_balance_widgets.dart#L227)); no raster image substitutes for live UI.

## Blockers

None.
