<!-- game.build Phase 2 — carved from SKILL.md (WS07 §7.1).
     SKILL.md holds the index and the cross-cutting rules; this file
     holds this phase only. Read it when you reach the phase. -->

## Phase 2: Wireframe Mockups (Staged Approval)

**Goal:** Create HTML/CSS wireframe mockups of all game screens so the user can review the visual design and layout BEFORE any game code is written. This catches layout problems, UX issues, and misunderstandings of the spec early — when changes are free.

**Model:** **Tier 3** (Sonnet) for HTML/CSS authoring; **Tier 0** (orchestrator) for AR-2 + WIREFRAME APPROVAL GATEs. **Stage A specifically:** consider **[Playbook §4 — Judge panel]** (3× Tier-3 authors in `isolation: 'worktree'` + Tier-1 judge) when the brand direction is high-stakes. **Before Stage A authoring:** run **[Playbook §7 — Prior-art briefing]** (Tier 5 Explore agent) so authors start with the pack's existing patterns.

### Staged Approval Strategy

Past sessions showed that building all wireframes upfront led to multiple revision rounds when the user only realized the visual direction was off after seeing them all. **This phase is now split into 4 stages with cheap approval gates between them.** The goal is to lock in the look-and-feel before investing in the full wireframe set.

- **Stage A:** Menu screen at ONE player count (e.g., 4 players selected) → user approval gate
- **Stage B:** Game screen (early state) at 2 players → user approval gate
- **Stage C:** Results screen at 2 players → user approval gate
- **Stage D:** Full wireframe set across min/mid/max player counts + modals → final user approval gate

After each stage, the user can request changes cheaply. Visual direction confirmed early → Stage D is mostly mechanical replication across player counts.

**CRITICAL — Use REAL game assets in every wireframe:**

The wireframes are NOT generic placeholders. Reference the actual character images, background images, and icon via `<img src="../../assets/games/[GAME_NAME_SNAKE]/...">` paths. Apply the spec's exact color palette + Google Fonts to ALL elements: list boxes, settings panels, modal overlays, AppBars, buttons, everything. The wireframe must be visually close to the final game so the user can give meaningful feedback.

- Use the actual icon for the home-screen card mock-up
- **Use the actual background image as the page background on EVERY screen — menu, game, AND results.** This is non-negotiable. Past failure: the Pirate's Grid initial wireframes used a parchment-style placeholder background; the actual user-provided `PiratesGrid-Background.png` was a fully illustrated scene that buried UI elements. Two recurrences across multiple games where Stage A/B/C wireframes silently reverted to a CSS gradient or a plain dark fill instead of `background-image: url('../../assets/games/[GAME_NAME_SNAKE]/images/[GameName]-Background.png')`. Verification: `grep -c '[GameName]-Background' temp_wireframes/[GAME_NAME_SNAKE]/*.html` must report ≥ 1 hit per HTML file.
- Use the actual character images on player tiles, descent tracks, winner card, etc.
- Use the spec's exact hex codes (no "approximate" colors)
- Load the spec's Google Fonts via `<link>` tags
- Match the spec's Style section closely — the wireframe should be nearly indistinguishable from the final game in colors/fonts/imagery

The ONLY stylistic restriction: do NOT use the container app's tokens (Nunito font, Flame Orange `#FF6B35`, etc.).

**CRITICAL — Design for the default headless test viewport (1366×768):**

The parallel UI test runner uses Chrome in headless mode at the default Chrome viewport (1366×768 wide on Windows, sometimes 1280×800 on macOS). Wireframes that look fine at desktop monitor sizes (1920×1080+) but overflow at 1366×768 produce screenshot tests that pass capture but fail layout (clipped buttons, overflowing text, RenderFlex errors). Past failures from the Pirate's Grid build: 76px player-column overflow at default viewport; grid not centered when the height-based cell size shrunk below the width-based one; winner character overflowing on small viewports because the Column had a fixed 420px size. Each cost an iteration round on screenshot review.

- Author every wireframe HTML with a fixed wrapper of `width: 1366px; height: 768px` for the orchestrator's visual review (so the HTML matches what tests see)
- Inside that wrapper, use responsive layout primitives (`LayoutBuilder` equivalents: % widths, `min/max` clamps, flex/grid) so the design adapts gracefully when run-time constraints differ
- Verify in the browser dev tools at exactly 1366×768 — no horizontal scroll, no clipped buttons, no overflow indicators

The orchestrator's AR-2 review explicitly checks the wireframe at this viewport before approving the stage.

### Stage A: Menu screen wireframe + approval

**Sub-agent prompt template (Stage A only):**

> You are completing Phase 2 Stage A (Menu wireframe) for the **[GAME_NAME_DISPLAY]** game build.
>
> **Read first:**
> - Spec file: `[SPEC_PATH]` — focus on "Overview" (player count, Dual/Team), "Style & Visual Identity" (palette + fonts), "Game Options & Settings" (option controls + effects), "Screen Designs" Menu Section, "New Components Required".
> - Section map: [PASTE SECTION MAP TABLE]
> - `docs/architecture/design-system.md` — container vs game tokens rule.
> - Asset paths from Phase 1's manifest at `temp_wireframes/[GAME_NAME_SNAKE]/asset_paths.md` — reference these EXACTLY.
>
> **Output directory:** `temp_wireframes/[GAME_NAME_SNAKE]/`
>
> **Stage A scope (single file):**
> - `menu_4p.html` — menu with 4 players selected, default option values, fully styled
>
> **The wireframe MUST use real game assets** referenced via `<img src="../../assets/games/[GAME_NAME_SNAKE]/...">`:
> - Real icon, real character images (on the player tile section if the spec calls for it — otherwise generic), real background if the spec specifies one for the menu
> - Spec's exact color palette (every box, every border, every text color)
> - Spec's Google Fonts loaded via `<link>` tags and applied to AppBar, headers, body, buttons
> - Real game-themed labels and messaging from the spec — NOT generic Lorem-ipsum
>
> **Layout requirements (apply consistently — these are the patterns the user has called out as bugs in past sessions):**
> - Option boxes have IDENTICAL heights regardless of control type (slider/toggle/dropdown). Use a fixed `min-height` so a slider box and a toggle box render the same height.
> - Spacing between option columns matches spacing between option columns and player list panel below them. Use the same `gap` / `margin` value throughout the right panel.
> - AppBar shows: back button, title (spec's exact text), DartboardConnectionInfo placeholder on the right, **ResumeGameButton positioned to the LEFT of DartboardConnectionInfo** (per `docs/development/resume-game-button.md`)
> - Player list panel populated with 4 player entries. **Use generic placeholder avatars on player tiles (initials/abstract shapes — NOT character images) — per project rule.** The character images go on game-screen + winner-card only.
>
> **Report back:**
> - File path created
> - Asset paths referenced (verify each is a real file via `if -e $path`)
> - Coverage table: each option from spec → its menu control + visible effect
>
> **Hard rules — Do NOT:**
> - Commit to master/main. Do NOT push to remote.
> - Use Nunito or Flame Orange `#FF6B35`.
> - Use generic placeholder colors / fonts / labels — match the spec exactly.
> - Use game characters as player tile avatars (use initials/shapes).
> - Skip the asset paths from `temp_wireframes/[GAME_NAME_SNAKE]/asset_paths.md` (Phase 1 manifest).

After the sub-agent returns, run AR-2 (Stage A subset) on the orchestrator.

### Stage A approval gate

Present the menu wireframe to the user:
- "Open `temp_wireframes/[GAME_NAME_SNAKE]/menu_4p.html` in your browser"
- "Confirm: colors, fonts, layout, character/imagery use, option box heights, spacing"

**STOP and wait for user approval.** Iterate per user feedback (each round = one corrective sub-agent dispatch). Do NOT proceed to Stage B until the user explicitly approves the menu look-and-feel.

### Stage B: Game screen wireframe + approval

**Sub-agent prompt template (Stage B only):**

> You are completing Phase 2 Stage B (Game screen wireframe) for the **[GAME_NAME_DISPLAY]** game build. The orchestrator has already locked in the menu visual direction in Stage A — REUSE the same color palette, fonts, panel styling, AppBar pattern from `menu_4p.html`.
>
> **Output directory:** `temp_wireframes/[GAME_NAME_SNAKE]/`
>
> **Stage B scope (single file):**
> - `game_early_2p.html` — game screen at the START of a game (2 players, all at starting state)
>
> **Layout requirements:**
> - **Game UI fills the full screen height. The dartboard emulator is a transparent OVERLAY anchored to the bottom — NOT a sibling that competes for vertical space.** The most common Phase 2 mistake (re-occurring across at least 3 game builds) is to lay out the wireframe as `Column[gameContent, dartboardEmulator]` where the emulator gets ~150-200px of inline height and the game content gets the rest. That model is WRONG. The emulator only renders when `!dartboardProvider.isConnected`; in production gameplay (board connected) the game content has the FULL screen height. The wireframe must reflect this: gameContent is the entire screen, dartboardEmulator is `position: absolute; bottom: 0; left: 0; right: 0;` at z-index 1 (or `Positioned(bottom: 0)` inside the OUTER Stack — sibling of Scaffold, NOT inside the body Stack). Otherwise the actual game-screen layout shrinks vertically when transplanted from wireframe to Flutter, and per-player columns / grids / tracks overflow at the default 1366×768 headless viewport. Past failure: PG game-screen layout overflowed by 76px because cellSize was clamped against the wireframe's reduced height that already accounted for an inline emulator.
> - AppBar: back button, title, DartboardConnectionInfo on the right (NO ResumeGameButton on game screen)
> - Active player panel (LEFT, 200px wide per spec Section 10B if specified): use the player's CHARACTER IMAGE rendered NATIVELY (no circle clipping, `object-fit: contain`). Apply a shape-conformal `filter: drop-shadow` for active-player glow.
> - Player progress visualization (descent track / coral cards / shields / etc. per spec): use REAL CHARACTER IMAGES, not rocket/circle placeholders. Render them at native size with no circle masking.
> - **Background: use the real background image** from `assets/games/[GAME_NAME_SNAKE]/images/...`. Even if the spec doesn't explicitly call for one on the game screen, use the same background image the menu uses (visual continuity). The background must be visible on the game screen (recurring miss in past sessions).
> - Skip Turn button visible (per spec's screen design)
> - Show every option's visible effect from the Options section (e.g., "HARD LANDING" badge if HL ON, altitude readout, etc.)
>
> **Hard rules — same as Stage A.**

Present `game_early_2p.html` to the user. **Wait for approval.**

### Stage C: Results screen wireframe + approval

**Sub-agent prompt template (Stage C only):**

> You are completing Phase 2 Stage C (Results screen wireframe) for the **[GAME_NAME_DISPLAY]** game build. REUSE the locked-in visual direction from Stage A + Stage B.
>
> **Output directory:** `temp_wireframes/[GAME_NAME_SNAKE]/`
>
> **Stage C scope (single file):**
> - `results_2p.html` — results screen with 2 players, the winner highlighted
>
> **Layout requirements:**
> - AppBar: title (e.g., "[GAME] RESULTS") + DartboardConnectionInfo on right. **NO back button** — results-screen navigation is exclusively via the 3 action buttons (Play Again, Change Settings, Back to Menu). Use `automaticallyImplyLeading: false` on the AppBar.
> - Background: use the real background image (recurring miss — must be visible on results screen)
> - Winner card: real character image at native size (no circle clipping), winner stats, victory styling
> - Player rankings list: generic avatars (initials), NOT character images per the project rule (winner card is the only exception)
> - 3 buttons: Play Again, Change Settings, Back to Menu — colored per spec
>
> **Hard rules — same as Stage A.**

Present `results_2p.html` to the user. **Wait for approval.**

### Stage D: Full wireframe set + final approval

**Sub-agent prompt template (Stage D only):**

> You are completing Phase 2 Stage D (full wireframe set) for the **[GAME_NAME_DISPLAY]** game build. The orchestrator has locked in the menu, game, and results visual direction in Stages A-C. Now produce the full set across player-count variants and add the modals wireframe + index.
>
> **Read first:**
> - The 3 approved wireframes: `menu_4p.html`, `game_early_2p.html`, `results_2p.html` — REUSE their CSS, colors, fonts, structures verbatim
>
> **Output directory:** `temp_wireframes/[GAME_NAME_SNAKE]/`
>
> **Files to create:** Each screen must be shown at multiple player counts to validate scaling. For a game supporting min M / max N players, create wireframes at min, max, and at least one count in between.
>
> Required wireframes:
> - `menu_Xp.html` for each player-count variant (M, mid, N — N being max)
> - `game_early_Xp.html` for each player-count variant
> - `game_midgame_Xp.html` for each player-count variant
> - `game_modals.html` (one file — Remove Darts modal + Edit Score button + Dartboard Paused modal + Save Game modal)
> - `results_Xp.html` for each player-count variant
> - `index.html` linking to all wireframes with brief descriptions
>
> **Each variant inherits the locked-in styling from Stages A-C and varies ONLY player count.**
>
> **Game-modals wireframe (single file with 3 stacked panels):**
> - Game screen with Remove Darts modal overlay (including Edit Score button inside the modal)
> - Dartboard Paused modal state
> - Save Game modal (back-button triggered)
>
> **Hard rules — same as Stage A. Do NOT introduce new colors/fonts; reuse the locked-in CSS.**
>
> **Report back:**
> - Full list of files created (paths)
> - A coverage table mapping each option from the spec's Options section to (a) where its menu control appears and (b) where its game-screen effect is shown
> - Confirmation that no game character images are used as player tile avatars
> - Any spec ambiguities you had to resolve and how

After the sub-agent returns, list the files yourself and spot-check the new player-count variants.

### Adversarial Review AR-2: Wireframe Completeness

> "I will now verify the wireframes against the spec before presenting them to the user:
>
> (a) Every screen from the Screen Designs section has a wireframe (Menu, Game, Results)
> (b) Every option from the Options section has a visible control on the menu wireframe AND a visible effect on the game wireframe
> (c) Every shared component from the New Components section is labeled and positioned on the correct screen
> (d) The color palette matches the spec's Style section exactly (hex codes match)
> (e) The typography matches the spec (correct Google Fonts loaded; no Nunito, no Flame Orange)
> (f) The player list panel type (Dual vs Team) matches the spec
> (g) The game wireframe shows at least two game states (early and mid/late) to demonstrate progression
> (h) Modal overlays are shown (Remove Darts, Save Game, Dartboard Paused)
> (i) Every screen type has wireframes at min player count, max player count, AND at least one count in between
> (j) **ResumeGameButton is positioned to the LEFT of DartboardConnectionInfo on the menu wireframe**
> (k) **No game character images are used as player TILE avatars** (winner card and active-player panel exceptions allowed per spec)
> (l) **Real character images ARE used** on the game screen (descent track / coral cards / shields / etc.) and on the winner card — rendered NATIVELY without circle clipping (no `border-radius: 50%` + `overflow: hidden` masking the character art)
> (m) **Background image is visible** on the game screen and results screen IF the spec specifies one (recurring miss in past sessions — flag it)
> (n) **Option boxes have IDENTICAL heights** regardless of control type (slider, toggle, dropdown all render to the same `min-height`)
> (o) **Spacing is consistent** — gap between option columns equals gap between option columns and the player list panel below
> (p) **Dartboard emulator is positioned as a BOTTOM OVERLAY** that overlaps the bottom of the game UI — NOT as a space-reserving section that the game UI flows around. The game content fills full available height as if the dartboard didn't exist.
>
> Wireframe coverage:
> | Screen/State | Wireframe File | Section Match | Player Counts |
> |-------------|----------------|---------------|---------------|
> | [screen]    | [file]         | [YES/MISSING] | [e.g., 2,5,8] |
>
> Missing elements: [list any gaps]"

Report AR-2 findings. Dispatch a corrective Sonnet sub-agent for any gaps before presenting to the user.

### Stage D: Final wireframe approval gate

Present the full wireframe set to the user:
- List all wireframe files created
- Tell the user to open `temp_wireframes/[GAME_NAME_SNAKE]/index.html` in their browser
- Ask the user to review the full set across player counts and the modals wireframe

**STOP and wait for user approval.**

The user may:
- **Approve** — proceed to Phase 3
- **Request changes** — dispatch a corrective Sonnet sub-agent with specific feedback, present again, wait for approval
- **Request major redesign** — return to the appropriate Stage (A/B/C) for re-approval first

Do NOT proceed to Phase 3 until the user explicitly approves the full wireframe set. This is the cheapest place to catch design issues — before any code is written.

---
