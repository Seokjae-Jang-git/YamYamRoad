# AI recommendation conversation — clone/design-system fidelity review

**Recommendation: REQUEST_CHANGES**

## Goal and success criteria reviewed

- Verify the AI recommendation Flutter page is a live component tree rather than a raster substitute.
- Verify the repaired recommendation reasons render as distinct vertical bullets, without Korean final-syllable orphan lines.
- Verify `_AiRecommendationTokens` materially centralizes the page's colors, spacing, and typography.
- Ignore the square Material icons in the headless captures, as instructed.

## Evidence inspected

- Source and complete available change surface: `lib/AI/ai_recommendation_page.dart` (untracked, therefore no Git diff exists to inspect; modified 2026-07-28 18:09:27.102).
- Fresh RGBA PNG evidence, both 780 × 1688 and newer than the source:
  - `C:\Users\TJ-BU-708-12\AppData\Local\Temp\yamyam_ai_recommendation_initial_v2.png` (18:10:10.413)
  - `C:\Users\TJ-BU-708-12\AppData\Local\Temp\yamyam_ai_recommendation_result_v2.png` (18:10:10.704)
- Static source inspection found no `Image`, `AssetImage`, `DecorationImage`, `MemoryImage`, `NetworkImage`, or `FileImage` rendering API in the reviewed page.

## Findings

### CRITICAL

None. The screen is assembled from live Flutter widgets (`Scaffold`, `ListView`, `Container`, `Text`, `ActionChip`, and buttons). It does not use a screenshot, raster image, or background image as the UI.

### HIGH

1. **Styling is only partly token-driven.** `_AiRecommendationTokens` usefully centralizes the main palette, several gaps/radii, and headline text styles at `lib/AI/ai_recommendation_page.dart:20-77`. However, primitives still embed one-off layout and text style values: the guide body style at `433-438`; bubble width/padding/corner/text tokens at `488-516`; result icon/gap/empty state styles at `675`, `683`, `687-690`; reason heading and vertical rhythm at `727-736`; choice-wrap/chip spacing and styles at `778-804`; and loading/restart control metrics at `822-832`, `853-865`. This fails the stated rigorous token-driven requirement and remains a design-system blocker.

2. **The initial capture contains an unnatural Korean word break.** In `yamyam_ai_recommendation_initial_v2.png`, the guide message wraps `결과는` as `결` / `과는`. That is a one-syllable word fragment at normal mobile scale. The text is rendered by the guide `Text` at `lib/AI/ai_recommendation_page.dart:431-438`. This is separate from the repaired result reasons and still requires correction before approval.

### MEDIUM

1. **The supplied result capture is scrolled into the conversation and cannot verify the full result-state page chrome.** It begins with the lower portion of a previous message rather than the `AppBar` visible in the initial capture. The source does retain a fixed `Scaffold.appBar` at `lib/AI/ai_recommendation_page.dart:254-271`, so this is an evidence-coverage gap rather than a proven implementation defect. A full result-state capture is required for full-page fidelity approval.

### LOW

None. The square icons visible in both captures were excluded from findings per the task constraint.

## Verified good

- `_ChatBubble` (`459-520`), `_ChoiceWrap` (`764-812`), `_RecommendationSection` (`650-706`), and `_RecommendationReasons` (`708-750`) are real, focused page primitives reused by the live state tree.
- The result reasons are now rendered as a vertical `Column`; each row has an independent bullet `Text` and an `Expanded` reason `Text` (`722-748`). In the fresh result capture, every reason is a separate bullet line and no final Korean syllable is stranded in those reason rows.
- Layer order is coherent and visible: guide → assistant/user messages → recommendation sections → persistent restart action. The result cards use live text and borders; no visual region is rasterized.
- Main colors, principal spacing steps, radii, and several text roles are centralised in the local token layer (`20-77`), an improvement over scattered palette literals.

## Blockers before approval

1. Move all remaining visual metrics and text roles cited in the HIGH token finding into the token system (or an existing project design-token system), then consume those tokens from the primitives.
2. Prevent the guide copy from splitting `결과는` into `결` / `과는`, and recapture the initial state.
3. Supply a fresh full-frame result-state capture after the fixes so the page chrome and full result state can be checked together.
