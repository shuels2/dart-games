<!-- game.build Phase 4 — carved from SKILL.md (WS07 §7.1).
     SKILL.md holds the index and the cross-cutting rules; this file
     holds this phase only. Read it when you reach the phase. -->

## Phase 4: Screens, UI, and Play-to-Complete


> ### LAYOUT LINT — run this as soon as the screens are authored, BEFORE AR-4
>
> 1. `flutter test test/meta/` — this now covers the back-arrow size and its
>    three hover-suppression properties, AppBar title fonts, raw Material
>    colours, option wiring, and dead widget keys. Do NOT hand-grep those; the
>    tests are faster and fail loudly.
> 2. Then work `reference/layout-constants.md` for what is NOT automated: the
>    dual-list / options-row recipe, where the exact numbers are per-game
>    design decisions but the RELATIONSHIP between them is fixed.
>
> The `listGap: 4` row in that file is the one people get wrong — setting it
> to match the options-row `SizedBox(width: 8)` makes the pane gap visibly
> WIDER, for a reason that is not obvious from the code. Read the note.

**Goal:** Create all three screens with full visual theming, shared component integration, and Play-to-Complete strategy + button + runner wiring.

**Model:**
- **Screen authoring (Task 5):** consider **[Playbook §5 — Worktree-parallel screen authoring]** (3× Tier-3 Sonnet in `isolation: 'worktree'`, one per screen file, then orchestrator merges and edits cross-cutting files). Falls back to serial Tier-3 if worktree setup fails.
- **Prior-art briefing (before Task 5):** **[Playbook §7]** — Tier 5 Explore survey of similar existing games.
- **Config factories + key registration + Play-to-Complete strategy + main.dart wiring:** **Tier 3** (Sonnet), orchestrator-owned.
- **AR-4 Integration Audit:** **[Playbook §1 — Workflow orchestration]** — pipeline over 34 rows with Tier-4 grep + Tier-1/Tier-2 verify + Tier-0 synthesis. For "Recurring miss" rows (RESPONSIVE `(yy)`, background image `(u)`, ChangeNotifier disposed `(oo)`, no-auto-navigate `(z)`, batch stats `(e)`), also run **[Playbook §2 — Adversarial verify]** (3× Tier-1 skeptics per finding).
- **Any corrective dispatch:** apply **[Playbook §9 — Corrective re-audit rule]** — re-verify the specific row after every fix.

### Delegate to Sonnet sub-agent

**Sub-agent prompt template:**

> You are completing Phase 4 (Screens, UI, and Play-to-Complete) for the **[GAME_NAME_DISPLAY]** game build.
>
> **Read first:**
> - Spec file: `[SPEC_PATH]` — focus on Overview (Dual vs Team panel), Style (colors + fonts), Options (controls and effects), Screen Designs (widget keys + layout), New Components (config factory methods).
> - Section map: [PASTE SECTION MAP TABLE]
> - `docs/architecture/shared-systems.md`
> - `docs/architecture/design-system.md` — game screens MUST NOT use container tokens (no Nunito, no Flame Orange)
> - `docs/development/game-integration.md` — full integration checklist including `(route) => false` rule
> - `docs/development/widget-keys.md` — including the `HomeKeys.[gameName]Card` requirement
> - `docs/development/dartboard-emulator.md` — **including the Play-to-Complete architecture (Strategy interface, Button factory, Runner wiring) — this is mandatory.**
> - `lib/widgets/dartboard_emulator/play_to_complete_strategy.dart` — the actual interface (3 methods, all take `BuildContext context`)
> - `lib/widgets/dartboard_emulator/play_to_complete_runner.dart` — the runner: constructor takes strategy + mockApi + context + optional `onComplete`; exposes `run()`, `cancel()`, `dispose()`
> - `lib/services/play_to_complete/target_tag_strategy.dart` — canonical reference strategy implementation
> - `lib/screens/games/target_tag/target_tag_game_screen.dart` — canonical Play-to-Complete wiring (field name `_playToCompleteRunner`, `_onPlayToComplete()`, `_onCancelAutoPlay()`, dispose)
> - `docs/development/resume-game-button.md` — exact menu state setup (`_hasSavedGames`, `_checkForSavedGames()`, `addPostFrameCallback`)
> - `docs/development/dartboard-paused-modal.md` — the conditional: show only if `!dartboardProvider.isEmulator && status != connected && status != emulator`
> - `lib/widgets/dartboard_paused_modal/dartboard_status_announcer.dart` — wraps the game screen's outer `PopScope`; fires `onPaused` / `onReconnected` callbacks on dartboard status transitions for the voice counterpart to the visual paused modal
> - `docs/development/save-resume-game.md` — `_deleteResumedSavedGame()` runs INDEPENDENTLY in `addPostFrameCallback`, NOT awaited inline after `_updatePlayerStats()`
> - `docs/development/announcement-system.md` — `announceRemoveDarts` MUST be called UNCONDITIONALLY on takeout (not inside a precedence `else` block)
> - At least one existing game's screens for reference (e.g., `lib/screens/games/target_tag/`, including its play-to-complete integration)
> - The wireframes from Phase 2: `temp_wireframes/[GAME_NAME_SNAKE]/`
>
> **Tasks:**
>
> **1. Add widget keys to `lib/constants/test_keys.dart`:**
> - `[GAME_NAME_PASCAL]MenuKeys` — every key from the spec's Menu screen design
> - `[GAME_NAME_PASCAL]GameKeys` — every key from the spec's Game screen design
> - `[GAME_NAME_PASCAL]ResultsKeys` — every key from the spec's Results screen design
> - **Add `HomeKeys.[gameName]Card`** to the existing `HomeKeys` class for the home-screen card
>
> **2. Create config factory methods (ADD to existing files):**
> - `AddPlayerDialogConfig.[gameName]()` in `lib/widgets/add_player/add_player_dialog_config.dart`
> - `EditScoreDialogConfig.[gameName]()` in `lib/widgets/edit_score/edit_score_dialog_config.dart`
> - `DartboardSectionConfig.[gameName]()`, `DartboardFABConfig.[gameName]()`, **`PlayToCompleteButtonConfig.[gameName]()`** all in `lib/widgets/dartboard_emulator/dartboard_emulator_config.dart`
> - **Player list panel — TWO SEPARATE FILES depending on type:**
>   - For Dual: `DualPlayerListPanelConfig.[gameName]()` in `lib/widgets/player_list_panel/dual_player_list_panel_config.dart`
>   - For Team: `TeamPlayerListPanelConfig.[gameName]()` in `lib/widgets/player_list_panel/team_player_list_panel_config.dart` (NOT in dual_player_list_panel_config.dart — these are separate files)
> - `RemoveDartsModalConfig.[gameName]()` in `lib/widgets/remove_darts_modal/remove_darts_modal_config.dart`
> - `DartboardConnectionInfoConfig.[gameName]()` in `lib/widgets/dartboard_connection_info/dartboard_connection_info_config.dart`
> - `DartboardPausedModalConfig.[gameName]()` in `lib/widgets/dartboard_paused_modal/dartboard_paused_modal_config.dart`
> - `SaveGameModalConfig.[gameName]()` in `lib/widgets/save_game_modal/save_game_modal_config.dart`
> - `ResumeGameModalConfig.[gameName]()` in `lib/widgets/resume_game_modal/resume_game_modal_config.dart`
>
> **2a. CONDITIONAL — Bonus-Buff emulator toggle buttons (ONLY if the spec defines bonus buffs):**
>
> If the spec includes a `bonus_buffs` option AND an enum of named buffs (like `BonusBuff` in Monster Mash or `ReefBuff` in Reef Royale), the game gets a column of emulator-only buff-toggle buttons flanking the dartboard for visual testing. Reference: `docs/development/dartboard-emulator.md` § Buff-Toggle Buttons.
>
> Required pieces:
> - Add `BuffToggleButtonConfig.[gameName]([BuffEnum] buff)` factory to `lib/widgets/dartboard_emulator/dartboard_emulator_config.dart` — one branch per buff value, with colors matching the spec's buff palette. Reference the existing `monsterMash(BonusBuff)` and `reefRoyale(ReefBuff)` factories for the per-buff-color pattern.
> - Add `void setActiveBuff([BuffEnum]? buff)` to the game's provider — mutates `_currentGame.activeBuff` and calls `notifyListeners()`. Mirror `ReefRoyaleProvider.setActiveBuff`.
> - In the game screen's `DartboardEmulatorSection` call, pass:
>   - `buffToggles`: a `List<BuffToggleSpec<Object>>` built from `[BuffEnum].values` (only when `_mockApi != null`), each spec carrying `buff`, `label` (from the model's `getBuffDisplayName`), `isActive: currentGame.activeBuff == b`, `isEnabled: currentGame.bonusBuffsEnabled`, `buttonKey: DartboardEmulatorKeys.buffToggleButton(b.name)`, and `config: BuffToggleButtonConfig.[gameName](b)`.
>   - `onBuffToggle`: cast the `Object buff` back to the game's enum and call `setActiveBuff(current == b ? null : b)` so tapping the active button clears it.
>
> Visibility / enabled state rules — these are intentional and MUST be preserved:
> - **No buttons rendered when there's no current game.** The emulator section is hidden entirely when the game hasn't started — no special handling needed beyond `_mockApi != null`.
> - **Buttons render but are DISABLED (40% opacity, no taps) when `bonusBuffsEnabled` is false.** The user can see the affordance exists, but toggling wouldn't influence the active game's natural roll, so the buttons remain non-interactive. The `isEnabled` flag on each `BuffToggleSpec` carries this; do NOT instead conditionally omit the buttons.
> - **Round-roll overwrites are expected.** When a round ends, the model's RNG may overwrite a manually-toggled buff. This is the intended natural game flow; do NOT add a "buff lock" mechanism.
>
> Tests (lightweight — visual testing feature, NOT a gameplay path):
> - `setActiveBuff` provider test (state mutation + listener notification + null clears). Mirror the `setActiveBuff` group in `test/providers/monster_mash_provider_game_test.dart`.
> - No additional integration test required — the shared `BuffToggleColumn` widget test in `test/widgets/buff_toggle_column_test.dart` already covers button rendering, tap-callback firing, disabled-state behavior, and active-state styling, and is generic across buff enums.
>
> Skip this entire sub-step if the spec does NOT include bonus buffs.
>
> **3. Create the Play-to-Complete strategy:**
> - File: `lib/services/play_to_complete/[GAME_NAME_SNAKE]_strategy.dart`
> - Implement `PlayToCompleteStrategy` (from `lib/widgets/dartboard_emulator/play_to_complete_strategy.dart`). The interface has THREE methods — **all take `BuildContext context`, NOT a provider**. The strategy itself calls `context.read<[GAME_NAME_PASCAL]Provider>()` to access state.
>   - `SimulatedThrow? getNextThrow(BuildContext context)` — returns the next dart action as a `SimulatedThrow` (fields `score`, `multiplier`, `baseScore`), or `null` when the game is done.
>   - `bool isGameComplete(BuildContext context)` — returns `true` when the win condition is met.
>   - `bool shouldAutoTakeout(BuildContext context)` — returns `true` if takeout should fire automatically after this throw.
> - Reference `lib/services/play_to_complete/target_tag_strategy.dart` (canonical) for the pattern. Also study the other 4 game strategies (`carnival_derby_strategy.dart`, `clockwork_quest_strategy.dart`, `monster_mash_strategy.dart`, `reef_royale_strategy.dart`) to confirm the convention.
>
> **4. Create `lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_menu_screen.dart`:**
> - Use the correct PlayerListPanel per spec (Dual vs Team)
> - **DualPlayerListPanel layout — MUST have bounded height** (recurring crash in past sessions): the panel's internal Column has `Expanded` children that crash with unbounded height constraints. Wrap pattern:
>   - In wide layout (constraints.maxWidth > 800): `Expanded(child: DualPlayerListPanel(...))` so the panel takes remaining vertical space in the right-panel Column.
>   - In narrow scrollable layout (constraints.maxWidth <= 800): `SizedBox(height: 400, child: DualPlayerListPanel(...))` because `Expanded` cannot live inside a `SingleChildScrollView`.
>   - Reference: `monster_mash_menu_screen.dart` line 715 — `Expanded(child: DualPlayerListPanel(...))`.
> - **DualPlayerListPanel alignment + spacing — MUST match the options-row exactly** (recurring miss across builds — Carnival Derby, Reef Royale, Clockwork Quest, Lunar Lander, Pirate's Grid, AND Gladiator Arena all shipped with this wrong on first cycle and required a polish pass). The two list panes must visually align with the option boxes above them: the AVAILABLE pane's left edge = the left option box's left edge, the SELECTED pane's right edge = the right option box's right edge, and the gap between the two panes = the gap between the two option boxes in a row.
>
>   The `DualPlayerListPanelConfig` has THREE knobs that control this:
>   - `availableContainerMargin` (defaults to `EdgeInsets.only(left: 16.0)`)
>   - `selectedContainerMargin` (defaults to `EdgeInsets.only(right: 16.0)`)
>   - `listGap` (defaults to `16`)
>
>   **The defaults are wrong for the canonical menu layout.** Every game's factory MUST explicitly override:
>   ```dart
>   availableContainerMargin: EdgeInsets.zero,
>   selectedContainerMargin: EdgeInsets.zero,
>   listGap: 4,  // ← NOT the same as the SizedBox(width: N) in the options row — see below
>   ```
>
>   **CRITICAL — `listGap` value is COUNTERINTUITIVE.** The instinct is to make `listGap` equal to the `SizedBox(width: N)` between the option boxes (e.g. `8` if options use `SizedBox(width: 8)`). **THAT IS WRONG.** Using `listGap: 8` produces a VISIBLY WIDER gap between the panes than between the options because the SHARED `dual_player_list_panel.dart` widget hardcodes `padding: EdgeInsets.all(16.0)` inside each section (lines 89 + 212). That 16px inner padding pushes the list content (player tiles) 16px in from each pane's visible border, while options-row content typically only has 12-16px horizontal padding inside its boxes. The net visual gap between PANES (including the 16+16 inner padding) is much wider than the visual gap between OPTIONS at the same `listGap == option-row-SizedBox` value. Empirically, `listGap: 4` (HALF of the options-row SizedBox value) compensates for this and makes the visible BOX-to-BOX gap appear to match.
>
>   **Recommended option-box internal padding:** `EdgeInsets.symmetric(horizontal: 16, vertical: 8)` to match the panes' inner 16px horizontal padding. With both at 16px horizontal, the option-content x-positions and player-tile x-positions visually align (the option labels/controls sit at the same indent inside the option box as the player tiles do inside the pane). Combined with `listGap: 4`, this produces a visually balanced layout.
>
>   **Recipe (apply EXACTLY in the new game's factory + menu screen):**
>   - In `DualPlayerListPanelConfig.[gameName]()`:
>     ```dart
>     availableContainerMargin: EdgeInsets.zero,
>     selectedContainerMargin: EdgeInsets.zero,
>     listGap: 4,
>     ```
>   - In the menu's `_buildTargetScoreBox()` and `_buildToggleBox()`:
>     ```dart
>     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
>     ```
>   - In the settings row's `Row` between option boxes:
>     ```dart
>     const SizedBox(width: 8),  // visible options-row gap
>     ```
>
>   Why these specific values: the SHARED widget's hardcoded `EdgeInsets.all(16)` is the constant that drives everything else. Until the shared widget is updated to expose a `sectionPadding` config knob, every game must work around it via the smaller `listGap`. If you need a different visual gap, scale `listGap` proportionally — but document it in your factory with a comment explaining the perceived-vs-actual distinction.
>
>   **AR-4 audit (mandatory grep):**
>   ```
>   grep -nA1 '[GAME_NAME_PASCAL]\b\|gladiatorArena\b' \
>     lib/widgets/player_list_panel/dual_player_list_panel_config.dart \
>     | grep -E 'availableContainerMargin|selectedContainerMargin|listGap'
>   ```
>   Must show: `availableContainerMargin: EdgeInsets.zero`, `selectedContainerMargin: EdgeInsets.zero`, `listGap: 4` (NOT 8 — see counterintuitive note above). Then visually compare the screenshot at the menu_4_players_ready or menu_default state — the gap between AVAILABLE/SELECTED panes should look EQUAL to the gap between TARGET SCORE/DOUBLE FINISH boxes, and the player tiles' left edge should align with the option labels' left edge.
> - **Generic avatars only on player TILE — do NOT assign game character images to player tile avatars**
> - All settings from the Options section with correct controls bound to provider state. **Option boxes MUST have IDENTICAL heights** regardless of control type (slider/toggle/dropdown). Use a fixed `min-height` so visual rhythm stays consistent across the settings row.
> - Add Player Dialog integration
> - DartboardConnectionInfo in AppBar (right side)
> - **ResumeGameButton in AppBar, positioned to the LEFT of DartboardConnectionInfo**
> - **AppBar back arrow — canonical pattern (mandatory, identical on the menu AND game screens):**
>   ```dart
>   leading: IconButton(
>     key: [GAME_NAME_PASCAL]MenuKeys.backButton, // or GameKeys.backButton on game screen
>     icon: const Icon(Icons.arrow_back, color: [SPEC_TEXT_COLOR], size: 32),
>     onPressed: () => Navigator.of(context).pop(), // or game-screen save-modal logic
>     hoverColor: Colors.transparent,
>     highlightColor: Colors.transparent,
>     splashColor: Colors.transparent,
>   ),
>   ```
>   - **Icon size MUST be 32** — matches Clockwork Quest, Reef Royale, Monster Mash, Carnival Derby, Target Tag (all 5 reference games)
>   - **All three hover-suppression properties (`hoverColor`, `highlightColor`, `splashColor`) MUST be `Colors.transparent`** — eliminates the default IconButton hover/splash effect for tablet/touch UX
>   - **Each screen's back arrow MUST use its own keys class** (`MenuKeys.backButton`, `GameKeys.backButton`) — never reuse another game's key class. Define `backButton` on each Keys class even if not currently referenced by tests.
>   - **Menu and game screens MUST be identical in size, color, and hover-suppression** — a consistent, predictable back-arrow experience.
>   - **Results screen MUST NOT have a back arrow** — set `automaticallyImplyLeading: false` on the AppBar and do NOT supply a `leading:` widget. Navigation off the results screen is exclusively via the 3 action buttons (Play Again, Change Settings, Back to Menu). Reference: Clockwork Quest, Reef Royale, Monster Mash, Target Tag, Carnival Derby — all 5 reference games omit the back arrow on results.
> - **initState pattern (mandatory — Tiki Golf reference):**
>   ```dart
>   @override
>   void initState() {
>     super.initState();
>
>     // 1. Settings hydration. RULE: every option must hydrate as
>     //        widget.initialX ?? <default>
>     //    and NOTHING else. NO fallback to provider.currentGame.
>     //    NO fallback to a provider.pendingMenuSettings layer.
>     //
>     //    - widget.initialX is supplied ONLY by the results screen's
>     //      "Change Settings" navigation (the constructor wires the
>     //      just-played values forward so the user doesn't have to re-pick).
>     //    - Every OTHER entry (home-screen tap, back-from-game,
>     //      back-from-results-without-Change-Settings) leaves
>     //      widget.initialX null → defaults apply.
>     //
>     //    Past failure (audit-fixed in tiki-golf-dev): every game except
>     //    Tiki Golf, Monster Mash, Reef Royale, Target Tag, Clockwork
>     //    Quest, and Carnival Derby had a `lastGame = provider.currentGame`
>     //    fallback here, which made the prior game's settings re-appear
>     //    when the user tapped the game card on the home screen.
>     _settingA = widget.initialSettingA ?? <default_A>;
>     _settingB = widget.initialSettingB ?? <default_B>;
>     // ... etc for every spec-defined setting
>
>
>     // 2. Initial saved-games check — if any saves exist on first menu entry,
>     //    AUTO-OPEN the resume modal. Subsequent re-checks (after games
>     //    complete or user actions) only update _hasSavedGames; they do NOT
>     //    auto-open the modal.
>     WidgetsBinding.instance.addPostFrameCallback((_) async {
>       final hasSaved = await SaveGameService().hasSavedGames('[GAME_NAME_SNAKE]');
>       if (mounted) {
>         setState(() {
>           _hasSavedGames = hasSaved;
>           _showResumeModal = hasSaved;  // ← auto-open on initial load
>         });
>       }
>     });
>   }
>
>   /// Refresh the Resume button enabled state. Called by the
>   /// `Navigator.push(...).then((_) => _checkForSavedGames())` callback
>   /// after the user returns from the game screen (save-and-back,
>   /// finished game, etc.). DOES NOT touch `_showResumeModal` —
>   /// auto-popup is INITIAL-ENTRY-ONLY so the user is not interrupted
>   /// with the modal after they have just chosen to save and exit.
>   Future<void> _checkForSavedGames() async {
>     final hasSaved = await SaveGameService().hasSavedGames('[GAME_NAME_SNAKE]');
>     if (mounted) {
>       setState(() => _hasSavedGames = hasSaved);
>     }
>   }
>   ```
>   Reference: `clockwork_quest_menu_screen.dart` lines 63-77 + 79-84.
>
>   **ANTI-PATTERN (do NOT do this):**
>   ```dart
>   // ❌ WRONG — auto-popup logic INSIDE _checkForSavedGames() means
>   //    the Resume modal pops up every time the user returns from the
>   //    game screen via Navigator.push.then((_) => _checkForSavedGames()).
>   //    Tiki Golf shipped with this bug; symptom: start game → throw
>   //    dart → back → Save Game modal → tap Save → Resume Game modal
>   //    immediately pops up on the menu. The user did NOT ask to
>   //    resume — they asked to save and exit.
>   //
>   //    A "_initialSavedCheckDone" guard does NOT fix this: the gate
>   //    only trips when hasSaved is true on the FIRST check, which
>   //    is false in the normal fresh-entry case, so it never trips
>   //    and the bug persists. The fix is to keep auto-popup logic
>   //    INLINE in initState (see the correct pattern above).
>   Future<void> _checkForSavedGames() async {
>     final hasSaved = await SaveGameService().hasSavedGames('[GAME]');
>     if (mounted) {
>       setState(() {
>         _hasSavedGames = hasSaved;
>         if (hasSaved && !_initialSavedCheckDone) {
>           _showResumeModal = true;        // ← BUG: re-fires on return
>           _initialSavedCheckDone = true;
>         }
>       });
>     }
>   }
>   ```
>   Regression guard: `integration_test/[GAME_NAME_SNAKE]/save_resume/save_and_back_no_auto_resume_modal_test.dart` (see Tiki Golf's copy for the canonical template).
> - **MENU SCREEN STRUCTURE — outer-Stack modal pattern (MANDATORY, apply EXACTLY — same shape as game screen):**
>   The menu screen wraps `Scaffold` in an outer `Stack` so menu modals paint OVER the AppBar (back arrow, ResumeGameButton, DartboardConnectionInfo). The build method's return value is `Stack`, NOT `Scaffold`.
>   ```dart
>   @override
>   Widget build(BuildContext context) {
>     final dartboardProvider = context.watch<DartboardProvider>();
>     // ...other watch calls and computations...
>     return Stack(
>       children: [
>         // 1. Scaffold — AppBar (back + ResumeGameButton if saved games + DartboardConnectionInfo)
>         //    + body (background, options, player list panel).
>         Scaffold(
>           appBar: AppBar(...),
>           body: Stack(children: [bg, content]),
>         ),
>         // 2. ResumeGameModal (conditional) — auto-shown on initial entry if saved
>         //    games exist; or on tap of ResumeGameButton in AppBar.
>         if (_showResumeModal) ResumeGameModal(...),
>         // 3. DartboardPausedModal (conditional) — LAST child; paints on top.
>         //    Same conditional as the game screen's paused modal.
>         if (!dartboardProvider.isEmulator &&
>             dartboardProvider.status != DartboardConnectionStatus.connected &&
>             dartboardProvider.status != DartboardConnectionStatus.emulator)
>           DartboardPausedModal(config: DartboardPausedModalConfig.[gameName]()),
>       ],
>     );
>   }
>   // 4. AddPlayerDialog — NOT an outer-Stack child. It is a routed dialog
>   //    (`showAddPlayerDialog()`) launched from INSIDE `DualPlayerListPanel` (the
>   //    shared player list panel widget — see `lib/widgets/player_list_panel/`).
>   //    The menu screen passes `addPlayerButtonKey` + `addPlayerButtonEmptyStateKey`
>   //    to the panel; the panel handles the dialog internally. The menu screen
>   //    file does NOT call `showAddPlayerDialog` directly. As a routed dialog it
>   //    paints above all outer-Stack siblings (including DartboardPausedModal)
>   //    when shown.
>   ```
>   Reference: any menu screen for the canonical pattern (e.g. `lunar_lander_menu_screen.dart` lines ~105-225).
> - Start button enable/disable logic (min players per spec Overview)
> - **Spacing consistency:** the gap between option columns MUST equal the gap between the option row and the player list panel below. Use a single spacing constant.
>
> **5. Create `lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_game_screen.dart`:**
> - Game board / play area per the Screen Designs section layout
> - **Background image (if spec specifies one):** render it as `Positioned.fill(child: Image.asset(BACKGROUND_PATH, fit: BoxFit.cover))` as the FIRST child of the body Stack — AppBar + game content render on top of it. **Recurring miss in past sessions:** specs often list a background image but the implementation never uses it. Reference `clockwork_quest_results_screen.dart` lines ~222-228 for the canonical pattern.
> - **RESPONSIVE SCREEN LAYOUT (MANDATORY, applies to game AND results screens):** the screen must render cleanly at every viewport size from ~800x600 up to ~1920x1080 with NO RenderFlex overflow. Two acceptable patterns:
>   1. **`LayoutBuilder` + scale factor** — wrap content-heavy subtrees (active player tile, winner section, opponent tiles, treasure map) in `LayoutBuilder(builder: (context, constraints) { final scale = min(constraints.maxWidth / baselineW, constraints.maxHeight / baselineH).clamp(0.5, 1.0); ... })` and multiply every fixed dimension (avatar size, `fontSize`, `padding`, spacer heights, dart-indicator size) by `scale`. Reference: `treasure_divide_game_screen.dart::_buildActivePlayerPanel` (solo baseline 680 + vertical padding baseline, team baseline 940 + vertical padding baseline, worst-case content computed against actual line-height ~1.35× fontSize).
>   2. **`FittedBox` + fixed baseline** — wrap the whole body in `FittedBox(fit: BoxFit.contain, alignment: Alignment.topCenter, child: SizedBox(width: 1600, height: 900, child: ...))`. Everything inside renders at the design baseline and `FittedBox` scales the whole subtree uniformly. Preserves aspect ratio (letterboxes if viewport aspect differs). Reference: `treasure_divide_results_screen.dart::_buildResultsBody`.
>   NEVER ship fixed pixel sizes (avatar 360, fontSize 44, etc.) at the raw widget tree unless it's already inside one of these two patterns. **Recurring miss:** Treasure Divide originally shipped both game AND results screens with fixed pixel sizes, causing hours of RenderFlex overflow debugging on smaller viewports before the LayoutBuilder / FittedBox retrofit landed. Verified by AR-4 row (yy).
> - **GAME SCREEN STRUCTURE — outer-Stack modal pattern (MANDATORY, apply EXACTLY):**
>   The game screen wraps `Scaffold` in an outer `Stack` whose siblings are the 4 visible modals, the dartboard emulator section, AND the dartboard emulator FAB. This is required so gameplay-screen modals paint OVER the AppBar (and so SaveGameModal/PausedModal cover the FAB too). A modal placed inside the Scaffold's `body:` cannot paint over the `appBar:` slot — the back arrow stays tappable behind the modal, which is the wrong UX. The FAB is moved OUT of `Scaffold.floatingActionButton` and into the outer Stack as a `Positioned` child between the emulator section and `SaveGameModal`, so it's blocked by Save/Paused but NOT by RemoveDartsModal (the user must be able to FAB-toggle the emulator visibility during takeout). Reference: any of the 6 game screens (e.g. `lunar_lander_game_screen.dart`, `clockwork_quest_game_screen.dart`).
>   ```dart
>   @override
>   Widget build(BuildContext context) {
>     // Provider data MUST be hoisted to the top of build() (not inside a
>     // Consumer<X> subtree) so the outer-Stack modals below can reference it.
>     final dartboardProvider = context.watch<DartboardProvider>();
>     final provider = context.watch<[GAME]Provider>();
>     final playerProvider = context.watch<PlayerProvider>();
>     // ... compute currentPlayer, dartsThrown, shouldPromptTakeout, etc. ...
>
>     return PopScope(
>       canPop: !hasDartsThrown || _showSaveModal,
>       onPopInvokedWithResult: (didPop, result) {
>         if (didPop || _showSaveModal) return;
>         setState(() => _showSaveModal = true);
>       },
>       child: Stack(
>         children: [
>           // 1. Scaffold — contains AppBar + body (background + main game content).
>           //    Body Stack contains ONLY background and main game UI — NO modals here.
>           //    NO floatingActionButton — moved to outer-Stack layer 4 below.
>           Scaffold(
>             appBar: AppBar(...),
>             body: Stack(
>               children: [
>                 // 1a. Background image (if any) — first child of body Stack.
>                 if (BACKGROUND_PATH != null)
>                   Positioned.fill(child: Image.asset(BACKGROUND_PATH, fit: BoxFit.cover)),
>                 // 1b. Main game content — Column with Expanded(game area).
>                 Column(...),
>               ],
>             ),
>           ),
>           // 2. RemoveDartsModal (conditional) — turn-end takeout overlay, painted
>           //    BEHIND the emulator so DARTS REMOVED stays visible/tappable on top
>           //    of the takeout modal. Paints OVER the AppBar — blocks back arrow.
>           if (shouldPromptTakeout) RemoveDartsModal(...),
>           // 3. DartboardEmulatorSection — wrapped in Positioned(left:0, right:0, bottom:0).
>           //    Sits ABOVE RemoveDartsModal so DARTS REMOVED paints on top of the
>           //    takeout overlay. Sits BELOW SaveGameModal/PausedModal so those
>           //    modals' buttons aren't intercepted by the emulator section.
>           //    NOTE: this is an outer-Stack sibling (NOT a body-Stack child) so the
>           //    Save/Paused modals above it can also cover the AppBar.
>           //    The Play To Complete button is INSIDE the emulator section's Column
>           //    (above the dartboard), so it lives at this same layer; it is disabled
>           //    when shouldPromptTakeout=true.
>           Positioned(left: 0, right: 0, bottom: 0,
>               child: DartboardEmulatorSection(...)),
>           // 4. DartboardEmulatorFAB (Positioned end-float) — moved OUT of
>           //    Scaffold.floatingActionButton into the outer Stack so RemoveDartsModal
>           //    (layer 2) does NOT block the FAB tap. The user must be able to toggle
>           //    emulator visibility during takeout (e.g. to hide the emulator and
>           //    re-show it on the takeout flow). SaveGameModal (5) and
>           //    DartboardPausedModal (6) still cover the FAB — correct, those modals
>           //    indicate states where toggling emulator visibility is irrelevant.
>           //    In real games (physical dartboard connected), DartboardEmulatorFAB
>           //    returns SizedBox.shrink anyway (`isConnected` short-circuit), so this
>           //    layer is a no-op outside emulator/test mode.
>           Positioned(right: 16, bottom: 16, child: DartboardEmulatorFAB(...)),
>           // 5. SaveGameModal (conditional) — explicit user action (back-button save flow).
>           //    Paints OVER the AppBar AND the FAB — blocks both.
>           if (_showSaveModal) SaveGameModal(...),
>           // 6. DartboardPausedModal (conditional) — MUST BE THE LAST CHILD.
>           //    Disconnected state means the dartboard hardware can't register input.
>           //    Paints OVER the AppBar AND the FAB. Auto-dismisses on reconnect.
>           if (!dartboardProvider.isEmulator &&
>               dartboardProvider.status != DartboardConnectionStatus.connected &&
>               dartboardProvider.status != DartboardConnectionStatus.emulator)
>             DartboardPausedModal(...),
>         ],
>       ),
>     );
>   }
>
>   // Dartboard pause / reconnect voice announcements are handled by
>   // a single `DartboardStatusAnnouncer` mounted at the app root
>   // (in `main.dart`, wrapping `MaterialApp`). The global announcer
>   // uses `GlobalConnectionAnnouncer.instance.announceGamePaused` /
>   // `announceConnectionRestored`. New game screens do NOT need to
>   // wrap themselves — adding a per-screen wrap would double-fire
>   // the announcement. The visual `DartboardPausedModal` is still
>   // mounted per-screen as shown above.
>   // 6. EditScoreDialog — NOT an outer-Stack child. It is a Flutter routed dialog
>   //    (`showDialog()`) launched from the "Edit Score" button INSIDE RemoveDartsModal.
>   //    Navigator routes always paint above the underlying page, so when shown it
>   //    sits above ALL outer-Stack layers (including DartboardPausedModal).
>   ```
>
>   **Why this structure — outer Stack wrapping Scaffold:**
>   - **App-root `VirtualKeyboardScaffold` sits ABOVE this whole outer Stack — automatic, no per-game wiring.** `main.dart` wraps every routed page via `MaterialApp.builder` in a `VirtualKeyboardScaffold`. When a `TextField` gains focus on a touch device, the touch keyboard slides up as a `Positioned(bottom: 0)` overlay that structurally paints above every layer of the game screen's outer Stack — including `DartboardPausedModal` (layer 6). New games inherit this automatically; do not build a "must-be-above-everything" modal inside this Stack that assumes it can outrank the keyboard. Gameplay screens have no `TextField` widgets so during play the keyboard never appears — the note is only relevant for menu / add-player / edit-name dialog surfaces where text entry can happen.
>   - **AppBar must be blocked when any modal is open.** The AppBar's leading IconButton (back arrow) is tappable. If a modal is a body-Stack child, it sits inside Scaffold's body slot and cannot paint over the AppBar — the back arrow stays tappable behind the modal, leading to confusing or destructive taps (e.g. re-triggering the save flow on top of the takeout flow). Outer-Stack siblings of the Scaffold paint OVER the entire Scaffold, including the AppBar slot.
>   - **FAB must be blocked too.** `Scaffold.floatingActionButton` paints above the body, so a body-Stack modal cannot cover the FAB. Outer-Stack siblings cover everything in the Scaffold including the FAB.
>   - **The body Stack now contains ONLY background + main game content.** The 4 modals + emulator section are all outer-Stack siblings. The internal z-order rationale (RemoveDarts < Emulator < Save < Paused) is unchanged from the prior body-Stack design — only the parent Stack moved.
>   - **EditScoreDialog already covers the AppBar+FAB by being a routed dialog** — it doesn't need to be in the outer Stack.
>   - **Provider data must be hoisted to the top of `build()`** so outer-Stack modals can reference `currentPlayer`, `shouldPromptTakeout`, etc. Use `context.watch<XProvider>()` at the start of `build()` rather than wrapping a subtree in `Consumer<X>`. The entire build rebuilds on provider notifications either way; outer-Stack siblings cannot otherwise access variables computed inside a nested `Consumer` builder.
>   - **Game/Player providers in the RESULTS screen MUST also use `context.watch` (not `context.read`).** The results screen has early-return paths for `currentGame == null` and `winners.isEmpty`/`winnerId == null`. If the screen builds before the provider state is fully populated AND uses `context.read`, the screen never re-renders when the data arrives — it stays stuck on a "No game data" / "No winner found" placeholder, hiding the Play Again / Change Settings / Back to Menu buttons and breaking every results-screen test. **Pattern recurrence:** Lunar Lander (round 2 fix), Monster Mash + Reef Royale + Target Tag (round 4 fix). Carnival Derby uses `Consumer2<HorseRaceProvider, PlayerProvider>` which is also fine. Clockwork Quest uses `Provider.of<X>(context)` (defaults to listen=true, equivalent to `context.watch`). All new games' results screens MUST use `context.watch` — verify in AR-4 below. The DartboardProvider can stay on `context.watch` (no change). Background services (e.g. VictoryMusicService, SaveGameService cleanup) are fine to fetch via `context.read` from inside `initState` / `addPostFrameCallback` — only the BUILD METHOD'S provider lookups for the game/player providers need `context.watch`.
>
>   **Why the modal z-order is what it is — semantic z-stacking driven by where each interactive button lives:**
>   - **RemoveDartsModal at the back of the modal stack**: its only interactive widget (Edit Score button) is in the centered card. The actual dismissal trigger is the DARTS REMOVED button INSIDE the dartboard emulator section. RemoveDartsModal therefore goes behind the emulator so DARTS REMOVED stays visible/tappable.
>   - **DartboardEmulatorSection above RemoveDartsModal**: its DARTS REMOVED button must paint on top of the takeout overlay so the user can finish the takeout. Sits at `Positioned(bottom: 0)` so it only covers the bottom strip of the screen.
>   - **SaveGameModal above the emulator**: the user explicitly tapped back to save — that intent wins over the takeout flow. The Don't Save button is at the bottom of the modal's centered card; painting SaveGameModal above the emulator means Don't Save isn't covered by the emulator section.
>   - **DartboardPausedModal at the very top of the outer Stack**: the dartboard is disconnected; the game can't reliably register state changes regardless of what the user taps. Painting Paused above everything visually communicates "non-functional state."
>   - **EditScoreDialog above the entire outer Stack as a routed dialog**: it is a focused, blocking interaction the user explicitly opened from inside RemoveDartsModal. Implementing it as a `showDialog()` route automatically gives it correct z-order above every outer-Stack layer, plus a barrier scrim and modal focus trap for free. The dialog's `barrierDismissible: false` and explicit Save / Cancel buttons mean it owns the user's attention until dismissed.
>   - **EditScoreDialog auto-cancels on dartboard disconnect (already implemented in `lib/widgets/edit_score/edit_score_dialog.dart`)**: because the dialog is a route, layer 5 (`DartboardPausedModal`) cannot paint above it. The shared `showEditScoreDialog` therefore watches `DartboardProvider` and, when the paused condition (`!isEmulator && status != connected && status != emulator`) becomes true, schedules a post-frame `Navigator.pop()` WITHOUT calling `onSubmit`. No score updates while disconnected — when the dartboard reconnects the user can re-open Edit Score from RemoveDartsModal. Game screens do NOT need to wire anything game-specific for this; it's centralized in the shared dialog. **Rule: any future routed dialog launched from the gameplay screen must replicate this auto-cancel-on-disconnect pattern, or layer 5 will be visually shadowed by the dialog.**
>   - **Edit Score button placement and flow (mandatory, identical across all games)**: the Edit Score button MUST live inside RemoveDartsModal and ONLY inside RemoveDartsModal — never as a standalone widget on the game screen, never in the AppBar, never in any other modal. Pass it in via `editScoreButtonKey: [GAME]GameKeys.editScoreButton` + `onEditScore: () => showEditScoreDialog(...)`. The user flow is: (1) takeout begins (3 darts thrown OR Skip Turn) → RemoveDartsModal renders → (2) user taps Edit Score → EditScoreDialog routes over the page → (3) user taps Save (provider scores updated) OR Cancel (no update) → dialog pops → (4) user is back on the game screen with RemoveDartsModal still visible (`shouldPromptTakeout` is still true) → (5) user can re-open Edit Score, or tap DARTS REMOVED inside the emulator section to finish the takeout and start the next turn. This means Edit Score is **gated by takeout** — a player cannot edit scores mid-turn (only after their 3 darts are in / they skipped), which prevents partial-turn corrections from desyncing announcements and turn state.
>   **The dartboard emulator is a TEMPORARY OVERLAY, not reserved space in the visual hierarchy.** The primary game UI (descent area, player panels, scores) should be designed to fill the FULL available screen height. Reference `monster_mash_game_screen.dart` for canonical full-height game UI + Positioned emulator overlay.
> - DartboardEmulatorFAB
> - **PlayToCompleteRunner integration:**
>   - Field: `PlayToCompleteRunner? _playToCompleteRunner;`
>   - Method: `_onPlayToComplete()` instantiates the runner with `[GAME_NAME_PASCAL]Strategy`
>   - Method: `_onCancelAutoPlay()` cancels the runner
>   - Auto-play guards on announcement and takeout chains (skip when runner is active)
>   - Dispose the runner in `dispose()`
> - RemoveDartsModal overlay (with Edit Score button inside — do NOT add a custom remove-darts button outside the modal, and do NOT add an Edit Score button anywhere outside this modal — see "Edit Score button placement and flow" rule above)
> - **`DartboardEmulatorSection` MUST be passed `dartboardKey: _dartboardKey`** (CRITICAL — silent breakage if omitted). The takeout-prompt overlay's "Remove Darts" button calls `dartboardKey?.currentState?.removeDarts()` to clear the local dart positions and fire the `onRemoveDarts` callback. Without the key the tap is a silent no-op and the turn never advances — the user is stuck on a "Remove Your Darts" overlay that won't dismiss. Required wiring in the game-screen `State` class:
>   ```dart
>   import '../../../widgets/interactive_dartboard.dart';
>   // ...
>   final GlobalKey<InteractiveDartboardState> _dartboardKey =
>       GlobalKey<InteractiveDartboardState>();
>   // ...
>   DartboardEmulatorSection(
>     dartboardKey: _dartboardKey,            // ← MANDATORY
>     onRemoveDarts: () { _mockApi?.simulateTakeoutFinished(); },
>     // ... other params
>   )
>   ```
>   Verified by AR-4 row (h2). Reference: any other game's screen (Pirate's Grid, Tiki Golf, Monster Mash) for the canonical wiring.
> - DartboardPausedModal overlay — show only when `!dartboardProvider.isEmulator && status != connected && status != emulator`
> - SaveGameModal (back button + PopScope pattern)
> - Skip turn button
> - **Skip Turn 0-darts bypass (mandatory, identical across all 6 games)**: the Skip Turn `onPressed` handler MUST branch on `dartsThrown`. With darts on the board (`dartsThrown > 0`), follow the normal takeout flow — schedule `_audioQueue?.announceRemoveDarts(...)` after 1500ms (where applicable) and `_mockApi?.simulateTakeoutStarted()` after 3500ms so RemoveDartsModal renders and the user is prompted to take out the darts. With NO darts on the board (`dartsThrown == 0`), there is nothing to remove, so schedule `_mockApi!.simulateTakeoutFinished()` (or `_handleTakeoutFinished()` when `_mockApi == null`) after 500ms — this short-circuits the takeout overlay and advances the player directly. Reference: `lunar_lander_game_screen.dart` and `clockwork_quest_game_screen.dart` skip-turn handlers (canonical bypass pattern). Without the bypass, players see a "Remove Your Darts" modal with no darts on the board — confusing UX. The Skip Turn `onPressed` MUST also be guarded by `provider.shouldPromptTakeout ? null : ...` so the button is disabled while a takeout is already in progress.
>   ```dart
>   onPressed: provider.shouldPromptTakeout
>       ? null
>       : () {
>           final dartsThrown = provider.getCurrentPlayerDartsThrown();
>           provider.skipTurn();
>           if (dartsThrown > 0) {
>             // Darts on board — wait for physical takeout or emulator's
>             // DARTS REMOVED button. Optional 1500ms `announceRemoveDarts`
>             // call then 3500ms `simulateTakeoutStarted`.
>             Future.delayed(const Duration(milliseconds: 1500), () {
>               if (mounted) _audioQueue?.announceRemoveDarts(/* args */);
>             });
>             Future.delayed(const Duration(milliseconds: 3500), () {
>               if (mounted) _mockApi?.simulateTakeoutStarted();
>             });
>           } else {
>             // No darts on board — auto-finish takeout to advance the player
>             // directly. RemoveDartsModal never renders for this path.
>             Future.delayed(const Duration(milliseconds: 500), () {
>               if (mounted) {
>                 if (_mockApi != null) {
>                   _mockApi!.simulateTakeoutFinished();
>                 } else {
>                   _handleTakeoutFinished();
>                 }
>               }
>             });
>           }
>         },
>   ```
>   **Verification:** UI tests for skip-turn-no-darts MUST NOT call `clickDartsRemoved` after Skip Turn — the player auto-advances. Tests for skip-turn-with-darts-thrown MUST `await tester.pump(const Duration(seconds: 4))` (or longer) after `clickSkipTurn` to let the 3500ms `simulateTakeoutStarted` schedule fire before tapping DARTS REMOVED.
> - DartboardConnectionInfo in AppBar
> - **`announceRemoveDarts` is called UNCONDITIONALLY on takeout** (not inside a precedence `else`; the call is independent of which moment-announcement won precedence)
> - **Victory flow MUST wait for DARTS REMOVED (mandatory):** When `hasWinner` becomes true after a dart throw, the game screen MUST NOT auto-navigate to the results screen. The RemoveDartsModal must still appear, the Edit Score button must remain accessible, and navigation to results must ONLY happen through the takeout flow: user clicks DARTS REMOVED → `_handleTakeoutFinished()` checks `hasWinner` → if true, calls `_handleGameWon()`.
>
>   **Prohibited patterns:**
>   - Do NOT add `if (provider.hasWinner) { addPostFrameCallback(_handleGameWon) }` in `build()`.
>   - Do NOT auto-call `simulateTakeoutStarted()` / `simulateTakeoutFinished()` on a winning turn.
>   - Do NOT call `_handleGameWon()` directly from the dart-event handler.
>
>   **Why:** The Edit Score button lives inside the RemoveDartsModal. If the game auto-navigates on a winning turn, the player cannot correct a mistaken score that triggered a false victory. The DARTS REMOVED step is the user's last chance to review and edit before the victory flow fires.
>
>   **Correct `shouldPromptTakeout` condition:** `dartsThrown >= 3 || provider.hasWinner` — ensures RemoveDartsModal always shows on a winning turn.
>
>   **Standardized `_handleTakeoutFinished()` pattern (all 6 games follow this):**
>   ```dart
>   void _handleTakeoutFinished() {
>     final provider = context.read<[Game]Provider>();
>     if (!mounted) return;
>
>     if (provider.hasWinner) {
>       _handleGameWon();
>       return;
>     }
>
>     if (!provider.isGameActive) return;
>
>     provider.handleTakeoutFinished(); // or confirmDartsRemoved() / advanceTurn()
>     // Game-specific: announce turn, scroll to player, check buffs
>     setState(() {});
>   }
>   ```
>
>   **Standardized `_handleGameWon()` pattern (all 9 games follow this):**
>   ```dart
>   void _handleGameWon() {
>     if (_gameCompleted) return;
>     _gameCompleted = true;
>
>     void navigateToResults() {
>       if (!mounted) return;
>       Navigator.pushReplacement(context,
>         MaterialPageRoute(builder: (_) => const [Game]ResultsScreen()));
>     }
>
>     if (_dartboardEmulatorController.isAutoPlaying) {
>       navigateToResults();
>     } else {
>       // Announce winner (MANDATORY — every game must announce here)
>       final provider = context.read<[Game]Provider>();
>       final playerProvider = context.read<PlayerProvider>();
>       final winnerId = provider.currentGame?.winnerId;
>       if (winnerId != null) {
>         final winner = playerProvider.allPlayers.firstWhere(
>           (p) => p.id == winnerId,
>           orElse: () => playerProvider.allPlayers.first,
>         );
>         _audioQueue?.announceWinner(winner.name);
>       }
>       _audioQueue?.whenIdle().then((_) {
>         Future.delayed(const Duration(milliseconds: 250), navigateToResults);
>       });
>     }
>   }
>   ```
>
>   Key requirements:
>   - (1) `_gameCompleted` guard prevents double navigation.
>   - (2) `isAutoPlaying` check skips the delay and announcement for Play-to-Complete.
>   - (3) Winner announcement fires, then `whenIdle()` waits for TTS to finish before navigating.
>   - (4) 250ms post-idle delay provides a brief transition pause after the announcement completes.
>   - (5) Navigation uses `Navigator.pushReplacement` with `MaterialPageRoute` (NOT `pushReplacementNamed`).
>   - (6) `hasWinner` check is at the TOP of `_handleTakeoutFinished`, BEFORE calling the provider advance method.
>   - (7) The game's announcement helper MUST have a public `announceWinner(String playerName)` method (or equivalent like `announceVictory`) AND a `Future<void> whenIdle()` method that delegates to `_queue.whenIdle()`.
>   - (8) The `_audioQueue` field (typed as the game's `AnnouncementHelper`) MUST be initialized in `_initializeGame()`.
>   - (9) **Victory announcements must ONLY fire from `_handleGameWon()`** — never from `_handleDartThrow()` or the per-dart precedence chain. The standard announcement sequence on a winning dart is: dart-hit sound → remove darts (1.5s) → takeout → victory announcement (in `_handleGameWon`) → `whenIdle()` → 250ms → navigate to results.
>   - (10) **Do NOT use a fixed `Future.delayed(3000ms)` for victory navigation** — use `_audioQueue?.whenIdle().then((_) { Future.delayed(250ms, navigateToResults); })` so navigation timing adapts to actual announcement duration.
>
>   **Reference:** All 9 game screens follow this pattern. Use any as reference.
> - **Edit Score `initialSegments` MUST map a thrown miss (score 0) to `'Miss'`, NOT `'-'`.** The shared EditScoreDialog distinguishes between:
>   - `'-'` or empty → dart NOT yet thrown (`ring=null` → invalidates the dialog Save button)
>   - `'Miss'` → dart thrown as a miss (`ring='Miss'` → valid)
>   - `'S20'` / `'D20'` / `'T20'` → numeric scoring darts
>   - `'Bull'` (50) / `'25'` (outer bull)
>
>   Edit Score is only accessible AFTER the turn ends (3 darts thrown), so all 3 segments should be valid (`'Miss'`, `'Bull'`, `'25'`, or `'SX'`/`'DX'`/`'TX'` for some X). NEVER pass `'-'` for a thrown miss — it disables Save. The `onSubmit` handler must explicitly handle each segment type (`Miss`, `Bull`, `25`, regex match for `SDTsdt\d+`).
> - **Score display pattern — Total Score vs Dart Throw (choose ONE per game):**
>
>   **Pattern A — Total Score Display** (Carnival Derby, Lunar Lander): The D1/D2/D3 labels on the game screen AND the Edit Score dialog score boxes show the **calculated point value** (e.g., "60" for T20, "20" for S20). Use this when the game's scoring is based on POINT VALUES that affect player position/score (points toward target, altitude descent).
>   - `EditScoreDialogConfig` factory MUST include `scoreDisplayTransform: _gameScoreDisplay` — a static method that converts segment strings to point values (S20→"20", D13→"26", T20→"60").
>   - **Provider MUST store raw segment strings** alongside calculated scores. The game model needs a `currentTurnDartSegments` field (`Map<String, List<String>>`) that stores the original sector strings ('S20', 'D15', 'T20', 'Bull', 'Miss'). The game screen passes the raw sector string from the dart event through to the provider's `processDartThrow(sector: sector)`. Without this, the Edit Score dialog cannot reconstruct the correct ring+number pre-selection — converting calculated values back to segments is lossy (e.g., score 40 becomes 'S40' which has no matching number on the dartboard grid). The `onEditScore` handler reads `provider.getCurrentTurnDartSegments(playerId)` to get proper segments for `initialSegments`. The field must be serialized in `toJson`/`fromJson` for save/resume, cleared in `advanceToNextPlayer`, and rebuilt during `editPlayerScore` replay.
>   - **Test constraint:** Single values (S5, S10) cause duplicate text matches in the dialog because the score display AND number button show the same value. Tests MUST use Double or Triple values (D5, T5) so the score display differs from the number button (D5 → score display "10", number button "5").
>
>   **Pattern B — Dart Throw Display** (Target Tag, Monster Mash, Reef Royale, Clockwork Quest): The D1/D2/D3 labels show the **raw segment string** (e.g., "S20", "T20", "Bull"). Use this when the game's scoring is based on TARGETS HIT (reef claiming, gear activation, shield damage, elimination).
>   - `EditScoreDialogConfig` factory does NOT include `scoreDisplayTransform` (default null — raw segment string shown).
>   - **Test constraint:** No duplicate text issue since "S20" ≠ "20".
>
>   **If unsure which pattern applies to a new game, ASK THE USER before implementing.** The choice affects the Edit Score dialog config, test design, and dart indicator display. Getting it wrong means rework across multiple files.
> - All option effects visible per the spec's Options section
> - **Generic avatars only on player TILE / rankings list — do NOT assign game character images to player avatars there.** Character images go on:
>   - The active player panel (LEFT side of game screen) — render character at native size, NO circle clipping (no `border-radius: 50%` + `overflow: hidden` masking the cute character art into a circle). Use `BoxFit.contain`. Apply shape-conformal `filter: drop-shadow` for active-player glow.
>   - The descent track / coral cards / shields / etc. (per spec's Screen Designs) — same: native size, no circle clipping.
>   - The results screen winner card — same.
>
> **6. Create `lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_results_screen.dart`:**
> - **RESPONSIVE SCREEN LAYOUT (MANDATORY):** apply the same responsive rule documented under Task 5's "RESPONSIVE SCREEN LAYOUT" bullet — either `LayoutBuilder` + scale factor OR `FittedBox` + fixed baseline. Reference: `treasure_divide_results_screen.dart::_buildResultsBody` uses the FittedBox pattern at 1600×900 to scale the whole body (winner section + rankings + action buttons) uniformly. Verified by AR-4 row (yy).
> - **RESULTS SCREEN STRUCTURE — outer-Stack modal pattern (MANDATORY, apply EXACTLY — same shape as game/menu screens):**
>   The results screen wraps `Scaffold` in an outer `Stack` so DartboardPausedModal can paint OVER the AppBar when the dartboard disconnects on this screen. The build method's return value is `Stack`, NOT `Scaffold`.
>   ```dart
>   @override
>   Widget build(BuildContext context) {
>     final dartboardProvider = context.watch<DartboardProvider>();
>     // ...other watch calls and computations...
>     return Stack(
>       children: [
>         // 1. Scaffold — AppBar (NO back arrow + title + DartboardConnectionInfo)
>         //    + body (background, winner card, rankings, action buttons).
>         Scaffold(
>           appBar: AppBar(automaticallyImplyLeading: false, ...),
>           body: ...,
>         ),
>         // 2. DartboardPausedModal (conditional) — LAST child; paints on top.
>         //    Same conditional as the game and menu screens.
>         if (!dartboardProvider.isEmulator &&
>             dartboardProvider.status != DartboardConnectionStatus.connected &&
>             dartboardProvider.status != DartboardConnectionStatus.emulator)
>           DartboardPausedModal(config: DartboardPausedModalConfig.[gameName]()),
>       ],
>     );
>   }
>   ```
>   Reference: any results screen for the canonical pattern (e.g. `lunar_lander_results_screen.dart`).
>   **If a future feature adds another modal to the results screen** (e.g. a confirm-delete dialog, a stats dialog), follow the same outer-Stack-wrapping-Scaffold pattern: add the new modal as another outer-Stack sibling above the Scaffold and below DartboardPausedModal (which is always the last child). Routed dialogs (`showDialog`) are also fine and will paint above the entire outer Stack — for those, follow the EditScoreDialog auto-cancel-on-disconnect rule documented in the game-screen section above.
> - **Background image (if spec specifies one):** render it as `Positioned.fill(child: Image.asset(BACKGROUND_PATH, fit: BoxFit.cover))` as the FIRST child of the body Stack — winner card + rankings + buttons render on top of it. Reference: `clockwork_quest_results_screen.dart` lines ~222-228.
> - Winner display + rankings (**winner card uses character art rendered NATIVELY without circle clipping** — no `border-radius: 50%` + `overflow: hidden`. Use `BoxFit.contain` and `filter: drop-shadow` for any glow effect. Player tiles in the rankings list use generic avatars per project rule.)
> - Victory music integration via VictoryMusicService
> - Player stats update for ALL players (winners AND losers) with the SAME `gameDuration` value. **MUST batch in a single call** — `await playerProvider.batchUpdatePlayerStats([for (final id in playerIds) PlayerStatsUpdate(playerId: id, won: ..., gameName: ..., gameDuration: ..., dartThrows: ..., turns: ..., playerCount: ...)]);`. Do NOT loop `playerProvider.updatePlayerStats(...)` per player — every shipped game uses the batch call (server-side `POST /api/v1/players/history/batch` wraps the inserts in a single transaction, saving N-1 HTTP round-trips per match). Reference: any results screen (e.g. `reef_royale_results_screen.dart` `_updatePlayerStats` body, ~line 113). Per-finding history: `docs/perf-audits/2026-05-05-full.md` finding A1.
> - **Auto-delete saved game**: `_deleteResumedSavedGame()` runs INDEPENDENTLY in `WidgetsBinding.instance.addPostFrameCallback(...)` — it is NOT awaited inline after `_updatePlayerStats()` (per `save-resume-game.md`)
> - Play Again, Change Settings, Back to Menu buttons
> - **Exit / Back-to-Home button: use `Navigator.popUntil(context, (route) => route.isFirst)`. NEVER use `pushNamedAndRemoveUntil('/', (route) => false)`** — the `(route) => false` predicate breaks the navigation stack (per `docs/development/game-integration.md`).
> - **Change Settings button: use `Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => [GAME_NAME_PASCAL]MenuScreen()), (route) => route.isFirst)`** — keeps home in the stack so the menu's back button still works. NEVER use `(route) => false`.
> - DartboardConnectionInfo in AppBar
>
> **7. Add the game card to `lib/screens/home_screen.dart`:**
> - Use the icon from `assets/games/[GAME_NAME_SNAKE]/icons/icon.png` (or whatever the spec specifies)
> - Tag the card with `key: HomeKeys.[gameName]Card` (added in step 1)
> - Set `'gameId': '[GAME_NAME_SNAKE]'` on the card map so the filter bar can match it against the filter registry (per Rule §42)
> - Wire navigation to the route name (added in step 8)
> - Match the visual style of existing cards
>
> **7a. Register filter metadata in `lib/constants/game_filter_registry.dart`:**
>
> The home-screen filter bar reads `GameFilterRegistry` to decide which cards to render given the user's filter selections. Every game MUST register an entry — without it, the card shows but the user can't filter to it / away from it consistently.
>
> Add a `GameMetadata` entry with all five fields populated:
> ```dart
> GameMetadata(
>   gameId: '[GAME_NAME_SNAKE]',          // matches the card's gameId
>   displayName: '[GAME_NAME_DISPLAY]',   // e.g. "Pirate's Grid"
>   maxPlayers: MaxPlayersBucket.<one>,   // twoOnly | upToEight | upToTen
>   gameplayStyles: {GameplayStyle.<one or more>}, // race | versus | strategy
>   playerInteraction: PlayerInteraction.<one>,    // parallel | light | heavy
>   gameLength: GameLength.<one>,         // quick | medium | long (at default settings)
>   soloTeam: SoloTeamSupport.<one>,      // soloOnly | soloOrTeam
> ),
> ```
> Decision guide:
> - **maxPlayers** — `MaxPlayersBucket.twoOnly` if exactly 2; `upToEight` if up to 8; `upToTen` if up to 10. Add a new bucket if the new game has a different cap.
> - **gameplayStyles** — `race` (first to a goal, no inter-player effects), `versus` (direct attacks/eliminations), `strategy` (claim positions/patterns). Set may contain multiple if the game spans styles; existing games each have one.
> - **playerInteraction** — `parallel` (no inter-player effects, side-by-side races), `light` (occasional disruption like steal/buff/claim), `heavy` (direct attacks/damage/eliminations).
> - **gameLength** — `quick` (< 10 min at defaults), `medium` (10–25 min), `long` (25+ min). At-default-settings duration only.
> - **soloTeam** — `soloOrTeam` if the spec calls out a Team mode toggle; `soloOnly` otherwise.
>
> If the spec introduces a new filter criterion entirely (e.g. "Family-friendly" / "Adult"), add the enum to `lib/models/game_metadata.dart`, add the field to `GameMetadata`, populate it for ALL existing games' registry entries, and add a dropdown to `lib/widgets/game_filter_bar/game_filter_bar.dart`. Then add a `FilterCriterion` enum value and the `HomeKeys.filter<NewCriterion>Button` + per-option key in `lib/constants/test_keys.dart`. Past failure: if the registry entry is missing, the card silently fails the orphan check in `test/models/game_metadata_test.dart` → game appears unfiltered but doesn't appear in any filtered view.
>
> **8. Register the provider in `lib/main.dart` MultiProvider, and add routes for the three new screens.**
>
> **9. Run `flutter test` to verify no regressions across the full suite.**
>
> **Report back:**
> - File paths created and modified
> - The full text of each new factory method (for orchestrator review)
> - Confirmation that `announceRemoveDarts` is called unconditionally in the game screen's takeout handler (cite line number)
> - Confirmation that `_deleteResumedSavedGame()` runs independently in addPostFrameCallback on the results screen (cite line number)
> - Confirmation that the Play-to-Complete strategy + button + runner are wired (cite the file paths and runner instantiation line)
> - Confirmation that `(route) => false` is NOT used anywhere in the new screens (grep result)
> - Confirmation that game characters are NOT used as player avatars (grep for character image asset paths in the menu / game screens)
> - Test results from `flutter test` (X/Y passing)
>
> **Hard rules — Do NOT:**
> - Commit to master/main. Do NOT push to remote.
> - Modify the dartboard emulator core code (`lib/widgets/dartboard_emulator/dartboard_emulator.dart`) — only ADD config entries to the config file
> - Modify any other game's screens or providers
> - Add a custom "remove darts" button outside RemoveDartsModal
> - Use game characters as player avatars
> - Use `(route) => false` in any Navigator call
> - Use Nunito font or Flame Orange in any game-screen styling
> - Skip running `flutter test`

After the sub-agent returns:
- Run `git diff lib/main.dart` and read each new screen file yourself
- `grep -n 'announceRemoveDarts' lib/screens/games/[GAME_NAME_SNAKE]/`
- `grep -rn '(route) => false' lib/screens/games/[GAME_NAME_SNAKE]/` (must return zero matches)
- `grep -rn 'addPostFrameCallback' lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_results_screen.dart`
- before AR-4

### Adversarial Review AR-4: Integration Audit

> "I will now act as the Integration Agent. For each item below, I will verify it is actually present in the code — not just planned, but imported AND instantiated:
>
> (a) PlayerProvider used for user management
> (b) GameAnnouncementQueueService used (NOT DartAnnouncerService directly)
> (c) VictoryMusicService called on results screen
> (d) DartboardProvider used for dart input
> (e) **Stats persistence MUST batch:** read the results screen's `_updatePlayerStats` body and verify it calls `playerProvider.batchUpdatePlayerStats([...])` exactly once with one `PlayerStatsUpdate` per player. Verify the file does NOT contain a `for (... in playerIds) await playerProvider.updatePlayerStats(...)` loop. The legacy per-player `updatePlayerStats` API still exists but the results screen MUST use the batch path so the server-side single-transaction route fires once instead of N times. Reference: any results screen (e.g. `monster_mash_results_screen.dart::_updatePlayerStats`). Per-finding history: `docs/perf-audits/2026-05-05-full.md` finding A1.
> (f) Every shared widget from the spec's Definition-of-Done functional-completeness list is instantiated in a screen
> (g) All 3 AppBars have: back button + title + DartboardConnectionInfo
> (g1) **Back arrow consistency** — read the `leading: IconButton(...)` block on the MENU and GAME screens and verify ALL of: (1) `Icon` size is `32`, (2) all three of `hoverColor`, `highlightColor`, `splashColor` are `Colors.transparent`, (3) each screen's IconButton uses its OWN keys class (`MenuKeys.backButton`, `GameKeys.backButton` — never another game's class). Menu and game MUST be identical in size, color treatment, and hover suppression. Reference: Monster Mash, Carnival Derby for the canonical pattern.
> (g2) **Results screen has NO back arrow** — read the results-screen AppBar and verify `automaticallyImplyLeading: false` is set AND no `leading:` widget is supplied. Confirm the 3 action buttons (Play Again, Change Settings, Back to Menu) are the only navigation off the results screen.
> (g3) **AppBar title strings match the naming convention** — see the "Universal Rule: AppBar Title Naming Convention" section at the top of this skill. Read the actual `title: Text('...')` string on all THREE screens and verify:
>    - Menu screen title matches the pattern `[Game Name] Game Setup` (case per game's own home-card casing).
>    - Results screen title matches the pattern `[Game Name] Results` (same case rule).
>    - Gameplay screen title is either `[Game Name]` or a spec-declared themed phrase.
>    - **NO screen uses** `[Name] SETUP` (missing "Game"), `[Name] Game Over`, `[Name] — Game Over`, `[Name] Race Results`, or any other historical variant.
>    - Cite the exact string + file:line from each screen. Grep sanity:
>    ```bash
>    grep -nE "title: (Transform\.translate|Text)" \
>      lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_menu_screen.dart \
>      lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_game_screen.dart \
>      lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_results_screen.dart
>    ```
>    Then read the matching Text() literal on each line.
> (g4) **All 3 AppBar titles use IDENTICAL font style** — read the `GoogleFonts.<family>(...)` call on all three screens and diff them ignoring the title string. `fontFamily`, `fontSize`, `fontWeight`, `letterSpacing`, `color`, `shadows` MUST be pixel-for-pixel identical across menu / gameplay / results. If any screen wraps its title in `Transform.translate(offset: Offset(x, y))`, the SAME offset MUST wrap the title on the other two screens (per-screen visual nudges are not allowed). Mandatory grep:
>    ```bash
>    grep -nA 10 "title: (Transform\.translate|Text)" \
>      lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_{menu,game,results}_screen.dart
>    ```
>    Compare the three blocks — every arg except the title string itself MUST match. Recurring miss: earlier builds shipped different `fontSize` values on menu vs. gameplay vs. results, resulting in inconsistent AppBar heights.
> (g5) **UI-test string assertions match the new naming convention** — grep every UI test file that references the game's setup/results screens for old title strings that would have been valid pre-normalization:
>    ```bash
>    grep -nE "find\.text\('[A-Z][A-Za-z ']+ (SETUP|Game Over|Race Results)'\)" \
>      integration_test/[GAME_NAME_SNAKE]/
>    ```
>    Any match is a stale test hardcoding an old title format — update the string to match the current app title (`[Name] Game Setup` / `[Name] Results`).
> (h) **No custom 'remove darts' button exists outside RemoveDartsModal** — grep `lib/screens/games/[GAME_NAME_SNAKE]/` for any button labeled "Remove" outside the modal
> (h1) **No Edit Score button exists outside RemoveDartsModal** — grep the game screen for any `key: ...editScoreButton` or `'Edit Score'` button outside RemoveDartsModal. The button must ONLY be wired via `RemoveDartsModal(editScoreButtonKey: ..., onEditScore: () => showEditScoreDialog(...))`. No standalone Edit Score button on the game screen, in the AppBar, or anywhere else.
> (h2) **`DartboardEmulatorSection` MUST receive `dartboardKey: _dartboardKey`** — verify the game-screen `State` class declares `final GlobalKey<InteractiveDartboardState> _dartboardKey = GlobalKey<InteractiveDartboardState>();` AND the `DartboardEmulatorSection(...)` invocation passes `dartboardKey: _dartboardKey` (alongside `onRemoveDarts: () { _mockApi?.simulateTakeoutFinished(); }`). The "Remove Darts" button inside the takeout-prompt overlay (`dartboard_emulator_section.dart` `_buildDisabledOverlay`) is wired as `onPressed: () => dartboardKey?.currentState?.removeDarts()` — if the key is null, the tap is a silent no-op and the turn never advances. The user sees a "Remove Your Darts" overlay that won't dismiss. **Mandatory grep audit:**
>    ```
>    grep -nE "GlobalKey<InteractiveDartboardState>" lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_game_screen.dart
>    grep -nE "dartboardKey:\s*_dartboardKey" lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_game_screen.dart
>    ```
>    Both greps must return at least one hit. Confirm the same file also `import`s `'../../../widgets/interactive_dartboard.dart';` so `InteractiveDartboardState` resolves. **Recurring miss:** Treasure Divide shipped without this key and the takeout overlay's "Remove Darts" button silently no-op'd until reported in production — the screen-construction template + AR-4 row both grew out of that fix. Reference: any other game's screen for the canonical wiring (Pirate's Grid, Tiki Golf, Monster Mash all follow the pattern).
> (i) Correct PlayerListPanel pattern (Dual vs Team) — and the Team config lives in `team_player_list_panel_config.dart`, not `dual_player_list_panel_config.dart`
> (j) SaveGameModal uses PopScope + outer Stack on game screen (sibling of Scaffold, not body-Stack child)
> (k) **Menu screen outer-Stack modal pattern**: build() returns `Stack`, NOT Scaffold. Outer-Stack siblings (back → front): Scaffold → `if (_showResumeModal) ResumeGameModal(...)` → conditional `DartboardPausedModal(...)` (last child, same paused condition as game screen). AddPlayerDialog is NOT a Stack child — it's a routed dialog launched from inside `DualPlayerListPanel` via `showAddPlayerDialog()` (the panel handles it; menu screen passes `addPlayerButtonKey` only).
> (k1) **Results screen outer-Stack modal pattern**: build() returns `Stack`, NOT Scaffold. Outer-Stack siblings (back → front): Scaffold → conditional `DartboardPausedModal(...)` (last child, same paused condition). `context.watch<DartboardProvider>()` must be at the top of build().
> (l) ResumeGameButton appears in menu screen AppBar, positioned to the LEFT of DartboardConnectionInfo
> (m) **`announceRemoveDarts` is called UNCONDITIONALLY in the game-screen takeout handler** (the call is not inside a precedence `else` block) — read the actual code and trace the call site
> (n) **DartboardPausedModal shown only when** `!dartboardProvider.isEmulator && status != connected && status != emulator` — read the actual conditional
> (o) **`Navigator.popUntil(context, (route) => route.isFirst)` is used for Back-to-Home** and `(route) => false` is NOT used anywhere — grep result
> (p) **`_deleteResumedSavedGame()` runs INDEPENDENTLY in `addPostFrameCallback`** on the results screen — not awaited inline after `_updatePlayerStats()`
> (q) **PlayToCompleteRunner is wired:** strategy file exists at `lib/services/play_to_complete/[GAME_NAME_SNAKE]_strategy.dart`, `PlayToCompleteButtonConfig.[gameName]()` exists, runner field is on game screen state, runner is disposed in `dispose()`
> (r) **`HomeKeys.[gameName]Card`** exists in `lib/constants/test_keys.dart` and is used on the home_screen.dart card
> (s) **Game characters are NOT used as player TILE avatars** in the player tile / rankings list — grep `lib/screens/games/[GAME_NAME_SNAKE]/` for character image asset paths in player tile / rankings list contexts (must return zero matches there). They ARE allowed on the active player panel + descent/coral/shield game UI + winner card.
> (t) No Nunito font or Flame Orange (`#FF6B35`) used in game-screen styling
> (u) **Background image (if spec specifies one) IS rendered on game AND results screens.** Grep for the background asset path in `lib/screens/games/[GAME_NAME_SNAKE]/`. Must appear in both `[GAME_NAME_SNAKE]_game_screen.dart` AND `[GAME_NAME_SNAKE]_results_screen.dart` if a background asset is in the spec's Asset Checklist. Recurring miss in past sessions.
> (v) **Outer-Stack modal pattern on the game screen (CRITICAL — wrong structure silently breaks AppBar blocking AND the takeout/Don't Save flows):** the build method must `return PopScope(child: Stack(children: [Scaffold(...), ...modals + emulator + FAB]))`. Verify by reading the actual `return` statement: (1) PopScope's child is `Stack`, NOT `Scaffold`. (2) The Scaffold is the FIRST child of the outer Stack. (3) The Scaffold has NO `floatingActionButton:` argument — the FAB is moved to the outer Stack (see step 5). (4) Inside the Scaffold's `body: Stack(...)`, the children are ONLY the background image and the main game Column — **NO modals inside body**. (5) The outer-Stack siblings AFTER the Scaffold appear in this exact order: `RemoveDartsModal` (conditional, back) → `Positioned(bottom: 0, child: DartboardEmulatorSection)` → `Positioned(right: 16, bottom: 16, child: DartboardEmulatorFAB)` → `SaveGameModal` (conditional) → `DartboardPausedModal` (conditional, last/front). Semantics: takeout overlay sits behind the emulator so DARTS REMOVED stays tappable; FAB sits ABOVE RemoveDartsModal so the user can toggle emulator visibility during takeout (RemoveDartsModal does NOT block the FAB); save modal beats takeout AND covers the FAB so Don't Save isn't intercepted by the emulator section AND emulator toggling is irrelevant during save flow; paused-disconnect modal beats everything; the modals cover the AppBar back arrow so no AppBar control is reachable while a modal is up. The FAB is layer 4 because in real games (physical dartboard) `DartboardEmulatorFAB.build` returns `SizedBox.shrink` anyway, so this layering is only meaningful in emulator/test mode.
> (v1) **No modals inside `Scaffold.body` Stack** — grep `lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_game_screen.dart` for `RemoveDartsModal(`, `SaveGameModal(`, `DartboardPausedModal(`, `DartboardEmulatorSection(`, `DartboardEmulatorFAB(`. Each must appear EXACTLY ONCE, and the surrounding context (find the parent `Stack(children:` it lives in by reading 50 lines up) must be the OUTER Stack (sibling of Scaffold inside PopScope.child), NOT the inner body Stack. The Scaffold MUST NOT have `floatingActionButton:` or `floatingActionButtonLocation:` arguments — the FAB lives in the outer Stack as `Positioned(right: 16, bottom: 16, child: DartboardEmulatorFAB(...))`. If any of the five widgets is inside `body: Stack(...)`, OR the FAB is still on `Scaffold.floatingActionButton`, the layered behavior breaks.
> (v2) **Provider data hoisted to top of `build()`** — read the first ~20 lines of the build method and verify `context.watch<DartboardProvider>()`, `context.watch<[GAME]Provider>()`, and (when needed for outer-Stack modals) `context.watch<PlayerProvider>()` are called there. Variables computed inside a `Consumer<X>` builder are NOT visible to outer-Stack siblings; this fails compilation or silently strips data from the modals.
> (v3) **Results screen uses `context.watch` (NOT `context.read`) for the game and player providers in `build()`** — read the first ~10 lines of the results screen's build method and verify the game-specific provider AND `PlayerProvider` are accessed via `context.watch` (or `Provider.of<X>(context)` which defaults to listen=true, or wrapped in a `Consumer`). If they use `context.read` AND the screen has any early-return path for `currentGame == null` / `winners.isEmpty` / `winnerId == null`, the screen will get stuck on the placeholder when the test/user reaches it before provider data finishes loading — Play Again / Change Settings / Back to Menu buttons never appear. Recurring miss: caught in Lunar Lander, Monster Mash, Reef Royale, Target Tag in past sessions. The `DartboardProvider` itself can stay on `context.watch` (it's already correct in all games).
> (w) **DualPlayerListPanel has bounded height** on the menu screen — wrapped in `Expanded(...)` for wide layout AND `SizedBox(height: ...)` for narrow scrollable layout. Read the menu screen and verify both branches.
> (x) **Menu screen initState hydrates settings via `widget.initialX ?? <default>` ONLY — no fallback to `provider.currentGame` or any `provider.pendingMenuSettings`-style layer.** Read `initState()` and verify EVERY spec-defined setting matches this pattern. The `widget.initialX` constructor params are wired by the results screen's CHANGE SETTINGS navigation, which is the only path that should preserve the just-played values; every other entry (home-screen tap, back-from-game, etc.) must show defaults. Past failure: Tiki Golf + Gladiator Arena + Lunar Lander + Pirate's Grid all originally fell back to `provider.currentGame`, which meant tapping the game card on the home screen kept the prior session's settings instead of resetting them. Confirm there is no `final lastGame = ...currentGame` line in initState, no `??` chain reading from a provider, and no `provider.pendingX` fallback either.
> (y) **Menu screen initState auto-shows resume modal when saved games exist on initial entry** — `setState(() { _hasSavedGames = hasSaved; _showResumeModal = hasSaved; })` inside the initial `addPostFrameCallback`. **Equally important: `_checkForSavedGames()` must ONLY refresh `_hasSavedGames`** — it must NOT touch `_showResumeModal`, and the menu must NOT define an `_initialSavedCheckDone`-style gate. Auto-popup is INITIAL-ENTRY-ONLY; the helper is called by `Navigator.push(...).then((_) => _checkForSavedGames())` after every game-screen pop (save-and-back, finished game), and re-popping the modal there interrupts the user immediately after they chose to save and exit. **Mandatory grep audit:**
>     ```
>     grep -nE "_showResumeModal\s*=|_initialSavedCheckDone" \
>       lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_menu_screen.dart
>     ```
>     Must show: `_showResumeModal = hasSaved` (or `= true`) ONLY inside the initial `addPostFrameCallback` block, plus the `_showResumeModal = false` lines in the modal's close-callbacks and the AppBar `ResumeGameButton` `_showResumeModal = true` callback. Must show ZERO occurrences of `_initialSavedCheckDone`. **Regression guard:** `integration_test/[GAME_NAME_SNAKE]/save_resume/save_and_back_no_auto_resume_modal_test.dart` — throws a dart, hits back, taps Save, then asserts `ElementFinders.getResumeGameModalOverlay()` is `findsNothing` on the menu. Past failure: Tiki Golf shipped with the `_initialSavedCheckDone` anti-pattern; symptom was start game → throw dart → back → Save → menu screen immediately auto-popped the Resume modal.
> (z) **Victory flow waits for DARTS REMOVED** — the game screen MUST NOT auto-navigate to results when `hasWinner` becomes true. Grep the game screen for `addPostFrameCallback(_handleGameWon)` and `simulateTakeoutFinished` inside `hasWinner` blocks — neither should exist. `_handleGameWon()` must ONLY be called from `_handleTakeoutFinished()`. The `shouldPromptTakeout` condition should be `dartsThrown >= 3 || provider.hasWinner` so RemoveDartsModal (and the Edit Score button inside it) is always accessible after a winning turn.
> (aa) **Edit Score `initialSegments` maps thrown miss (score 0) to `'Miss'`, NOT `'-'`.** Read the menu/game screen's onEditScore handler and verify the segment building. The `'-'` value invalidates the dialog Save button; thrown misses must be `'Miss'`.
> (bb) **Character images on game screen + winner card are rendered NATIVELY (no circle clipping).** Grep for `border-radius:.*5[0-9]%` and `BorderRadius.circular(.*5[0-9]\.0` near `Image.asset(.*characters/`. Avatar widgets in the player tile / rankings list MAY use circles (initials placeholders); the active player panel + descent/coral/shield + winner card MUST NOT clip the character art.
> (cc) **Sound effect files follow naming convention** — list all files in `assets/games/[GAME_NAME_SNAKE]/sounds/` and verify every filename uses the `GameName-SoundName.mp3` pattern (PascalCase, hyphen separator). No snake_case filenames.
> (dd) **Sound effects config `_basePath` has no `assets/` prefix** — read the `_basePath` constant in `lib/services/[GAME_NAME_SNAKE]_sound_effects.dart` and verify it starts with `'games/'` not `'assets/games/'`.
> (ee) **Sound effects config has trim times** — verify every `SoundEffectConfig` has a non-null `endSeconds` value matching the spec's Asset Checklist.
> (ff) **Announcement helper has `dispose()` method** — read the helper class and verify a `void dispose()` method exists that calls `_queueService.dispose()`.
> (ff-b) **Announcement helper has `whenIdle()` method** — read the helper class and verify a `Future<void> whenIdle()` method exists that delegates to `_queue.whenIdle()` (or `_queueService.whenIdle()`). This is used by `_handleGameWon()` to wait for the victory announcement to finish before navigating.
> (gg) **Game screen calls `announceGameStart()` in `_initializeGame()`** — grep the game screen for `announceGameStart` and verify it fires after `_audioQueue` creation. Also verify first turn is announced with a 2s delay.
> (hh) **Game screen disposes `_audioQueue`** — read the `dispose()` method and verify `_audioQueue?.dispose()` is present.
> (ii) **Per-dart announcements wired in `_handleDartThrow`** — verify the game screen calls announcement methods after `processDartThrow()` with an `isAutoPlaying` guard. Announcements must follow precedence (milestone > advance > miss). **Victory announcements must NOT fire from the dart-throw handler** — they fire only from `_handleGameWon()` after the takeout flow completes. This ensures the standard sequence: dart hit → remove darts → takeout → victory announcement.
> (ii-b) **Victory announcement fires ONLY from `_handleGameWon()`, NEVER from `_handleDartThrow()` or the per-dart precedence chain** — grep the game screen for `announceVictory\|announceWinner\|announceMatchVictory` and verify every match is inside `_handleGameWon()`. If the announcement helper has a `pickAndAnnounceMoment()` method, verify that `hasWinner: true` is never passed to it (or the victory branch is unreachable). The standard victory sequence across all 9 games is: winning dart hit → per-dart announcement (gear activated / score / etc.) → remove darts (1.5s) → takeout → `_handleTakeoutFinished()` detects winner → `_handleGameWon()` fires `announceVictory` → `whenIdle()` → 250ms → navigate to results. Violating this order causes the victory fanfare to play before "remove your darts", which sounds wrong.
> (ii-c) **Victory navigation uses `whenIdle()` + 250ms, NOT a fixed 3000ms delay** — grep the game screen for `Future.delayed.*3000.*navigateToResults` — must return zero hits. Grep for `whenIdle()` inside `_handleGameWon()` — must return one hit. The pattern is `_audioQueue?.whenIdle().then((_) { Future.delayed(const Duration(milliseconds: 250), navigateToResults); })`. A fixed 3000ms delay either cuts off long announcements or wastes time after short ones.
> (ii-d) **Winning dart STILL gets its per-dart announcement** — the `hasWinner` flag must NOT suppress the per-dart score/hit announcement on the winning throw. Only the victory announcement is deferred to `_handleGameWon()`. Verify by tracing the announcement code path when `hasWinner == true`: the per-dart announcement (score readout, gear activated, flag planted, elimination, descent, etc.) must still fire. Common violations: (1) announcement helper's `pickAndAnnounceMoment()` has a `if (hasWinner) return;` early exit — remove it or restructure so score branches still fire; (2) game screen wraps the entire announcement call in `if (!provider.hasWinner)` — remove the guard; (3) fact-flag computation excludes the winning dart (e.g. `justPlantedFlag = ... && !justWonMatch`) — add a separate dart-level announcement inside the `justWonMatch` block. The correct sequence is: winning dart hit announcement → remove darts → takeout → victory announcement. All 9 games follow this pattern.
> (ii-e) **Speed Play timer starts AFTER turn announcement finishes** — if the game has a per-turn countdown timer (Speed Play), the timer must NOT start until the turn announcement has finished playing. Grep for `_startSpeedPlayTimer` in the game screen and verify every call site (game init, takeout finished, timer expired) uses `_audioQueue?.whenIdle().then((_) { if (mounted) _startSpeedPlayTimer...; })` to defer the timer start. The only exception is `_onCancelAutoPlay` (auto-play cancelled mid-run) where the timer should start immediately since no announcement is playing. Starting the timer before the announcement finishes means the player loses seconds while the TTS is still talking. Reference: Gladiator Arena and Pirates Grid both follow this pattern.
> (jj) **Game-with-announcements integration test exists** — verify `test/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_game_with_announcements_test.dart` exists with lifecycle, moment, precedence, and auto-play suppression tests.
> (kk) **DartboardPausedModal UI tests exist** — verify `integration_test/[GAME_NAME_SNAKE]/pause_modal/` directory exists with 3 test files: `menu_pause_test.dart` (7 tests), `gameplay_pause_test.dart` (8 tests), `results_pause_test.dart` (5 tests). These verify the pause modal appears on disconnect, blocks all interaction (AppBar, buttons, modals), and dismisses on reconnect. The gameplay test must verify EditScoreDialog auto-closes on disconnect.
> (ll) **Continuous-animation subtrees wrapped in `RepaintBoundary`** — grep `lib/screens/games/[GAME_NAME_SNAKE]/` and `lib/widgets/[GAME_NAME_SNAKE]_*` for every `AnimatedBuilder(` and verify a `RepaintBoundary` ancestor wraps the animated subtree as closely as possible. Without it, animation frames dirty sibling widgets and force the entire screen to repaint per frame. Also flag any AnimationController-driven custom widget that paints continuously (background pulses, progress glow, character animations) without an enclosing `RepaintBoundary`. Reference: `lib/widgets/carnival_string_lights.dart` `_buildBulb` for the canonical pattern. Per-finding history: `docs/perf-audits/2026-05-05-full.md` finding A4.
> (mm) **No `Opacity`/`Transform`/`Color` inside `AnimatedBuilder.builder` driven by an AnimationController** — grep for `Opacity(opacity:` inside `AnimatedBuilder(...).builder` callbacks. Use `FadeTransition(opacity: anim, ...)` (or `SlideTransition`/`ScaleTransition`/`RotationTransition`) outside the builder instead — `Opacity` allocates a saveLayer per frame whereas the transition widgets short-circuit. Same rule for animated `Transform.translate`/`Transform.rotate` inside a builder. Per-finding history: `docs/perf-audits/2026-05-05-full.md` finding A5.
> (nn) **No empty `setState(() {})` as a rebuild hack** — grep `lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_*.dart` for `setState\(\(\) \{\}\)`. If the rebuild is needed because a `Provider` field changed, the provider's own `notifyListeners()` covers it — no setState required. If local widget state is changing, give the field an actual setter call inside the setState closure (e.g. `setState(() { _foo = bar; })`). An empty setState hides the dependency, causes spurious full-subtree rebuilds, and tends to multiply over time as code is copy-pasted between games. **Permitted exception:** rebuilding after assigning a local non-Provider field (e.g. `_mockApi = ...` in `_initializeGame`) — in that case the field assignment IS the state change and an empty closure is acceptable; cite this case in the AR-4 report. Per-finding history: `docs/perf-audits/2026-05-05-full.md` finding C3.
> (oo) **Menu screen `initState` calls `await playerProvider.loadPlayers()`, then `if (!mounted) return;`, then `playerProvider.clearSelection()` inside its `addPostFrameCallback`** — read the menu screen's `initState()` and verify all three are present, in that order, before any preselect logic (`selectPlayer(...)` / `getPlayerById(...)`). Without `clearSelection()`, `_selectedPlayers` on `PlayerProvider` is shared global state that LEAKS across games — entering the new game shows whatever players were selected on the previously-visited game's menu. Without `loadPlayers()`, players added on the home / options screen since the app booted won't appear in the new game's roster. The `if (!mounted) return;` between the two is MANDATORY (Accumulated Build Quality Rules § 72) — `loadPlayers` is an HTTP roundtrip and the widget may unmount during the gap (user backs out, dartboard disconnect grabs nav, integration-test teardown). Touching the provider after disposal triggers a `"ChangeNotifier was used after being disposed"` assertion. Reference: post-fix menu screens after commit `a6170d5`. Recurring miss: shipped in all 9 menu screens until 2026-05-31 — surfaced as `target_tag/pause_modal/menu_pause_test.dart` after-test-completed exception.
>
> (rr) **`voice_enabled=false` in `resetServerState`** (Rule 68) — read both `integration_test/shared/settings_helpers.dart` and `test/shared/settings_helpers.dart` and verify each contains a `http.put(Uri.parse(ApiConfig.url('/api/v1/settings/voice_enabled')), ..., body: jsonEncode({'value': 'false'}))` call inside `static Future<void> resetServerState`. Confirm both files are byte-identical via `diff -q integration_test/shared/settings_helpers.dart test/shared/settings_helpers.dart` (per Rule 26). FAIL if either is missing the PUT or the files differ.
> (ss) **`pumpUntilResults` (not fixed pump) after every game completion** (Rule 69) — for each test file under `integration_test/[GAME_NAME_SNAKE]/`, grep for `clickDartsRemoved(tester)\|completeGameToVictory` and inspect the next 20 lines. If a results-screen assertion follows (any `getPlayAgainButton`, `_results_*_button`, `_results_winner_*`, victory headline text, or `VictoryMusicService`), the wait between them MUST be `await ResultsHelpers.pumpUntilResults(tester, config);` — NOT `await tester.pump(const Duration(seconds: 4));` followed by bare pumps. Allowed exception: the per-turn skip-turn-with-darts-thrown wait (4 s for `simulateTakeoutStarted`) is unrelated; cite explicitly in the report when seen.
> (tt) **5 s settle before VictoryMusicService / stats assertions** (Rule 70) — for every test file matching `*winner_stats_updated_test.dart`, `*victory_music_initialized_test.dart`, `*edit_creates_winner_stats_test.dart`, or any test asserting `VictoryMusicService\(\).isInitialized\|\.gamesPlayed\|\.gamesWon\|\.gameHistory`, verify the line ordering: `pumpUntilResults(tester, config)` line < `pump(const Duration(seconds: 5))` line < two bare `pump()`s < the `expect(...)` line. Programmatic check: for each affected test, capture the line numbers of the three constructs and assert strict ordering.
> (uu) **Screenshot / showcase inline 300-iter poll** (Rule 71) — locate every `*_screenshot_test.dart` and `*_showcase_test.dart` under `integration_test/[GAME_NAME_SNAKE]/`. For each test, find every place that completes a game and then captures a results-screen screenshot or asserts on a results-screen widget. Grep for `for \(int _i = 0; _i < 300; _i\+\+\)` followed by `pump\(const Duration\(milliseconds: 300\)\)` and the game's Play Again finder break condition. Must be present at each such site. Flag any remaining `pump(const Duration(seconds: 4))` followed by a results-screen assertion / screenshot capture as a violation.
> (vv) **`mounted` guard after every `PlayerProvider` await** (Rule 72) — grep `lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_menu_screen.dart`, `lib/screens/options_screen.dart`, and `lib/widgets/player_list_panel/*.dart` for `await playerProvider\.\|await _playerProvider!\.`. For each match, read 5–10 lines below; verify EITHER (a) the next provider/setState/context use is preceded by `if (!mounted) return;`, OR (b) no further provider/setState/context use occurs before the function returns. The results-screen `batchUpdatePlayerStats` pattern (inside `try`/`catch` with no mutation after the await) is the only allowed bare-await pattern.
> (ww) **Real-time pumps around popup interactions** (Rule 73) — for every UI test under `integration_test/[GAME_NAME_SNAKE]/menu_and_settings/` (or any test that taps a `DropdownButton`, `PopupMenuButton`, or `tester.tapAt(const Offset(...))` overlay-dismiss), grep within 5 lines for either a follow-up `tester.pump(const Duration(milliseconds: [0-9]+))` (correct) OR a `PumpSequences.simpleUpdate` (violation). Flag every `simpleUpdate` between a popup-related tap and the next gesture.
> (xx) **No intermediate-state stats assertions** (Rule 74) — grep every test file under `integration_test/[GAME_NAME_SNAKE]/` for the substring `results screen not yet loaded` (case-insensitive). Must return zero hits. Also grep for `expect\(.*\.gamesPlayed,\s*0` and `expect\(.*\.gamesWon,\s*0` in the same test body as `clickDartsRemoved\|completeGameToVictory`. Must return zero hits. Either match indicates the broken intermediate-state pattern.
> (yy) **Responsive layout on GAME AND RESULTS screens (MANDATORY GATE — NEVER skip, NEVER defer, NEVER rationalize past — must pass to proceed).** No size thresholds. No "the avatars are only 180 px so it's fine" arguments. No "the Row has some Flexible children so it can't overflow" arguments. **Either pattern is present, or this row FAILS. Period.** For each screen verify one of the two acceptable patterns is present:
>    ```
>    grep -nE "LayoutBuilder\(|FittedBox\(fit: BoxFit\.contain|FittedBox\(BoxFit\.contain" \
>      lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_game_screen.dart \
>      lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_results_screen.dart
>    ```
>    - `[GAME_NAME_SNAKE]_game_screen.dart` must return at least one hit for `LayoutBuilder(` OR `FittedBox(...BoxFit.contain`.
>    - `[GAME_NAME_SNAKE]_results_screen.dart` must return at least one hit for `LayoutBuilder(` OR `FittedBox(...BoxFit.contain`.
>    Read the matched call site(s) and verify actual scaling: for `LayoutBuilder`, the `builder` closure must compute a `scale` from constraints against a fixed baseline (`min(maxW / baselineW, maxH / baselineH).clamp(0.5, 1.0)` or similar) AND every nearby fixed-size widget (avatar size, `fontSize`, padding, spacer heights, dart-indicator size) must be multiplied by that `scale`. For `FittedBox`, verify the child is a `SizedBox(width: X, height: Y, child: ...)` with fixed baseline dimensions — a bare `FittedBox` without a sized child does nothing useful.
>    **FAIL this row unconditionally** if either screen contains ANY fixed-pixel size (an integer literal appearing as `fontSize:`, `size:`, `height:`, `width:`, `radius:`, `dartIndicatorSize`, `avatarSize`, an `EdgeInsets` const, or a `SizedBox` const) OUTSIDE one of the two responsive patterns. The presence of `Flexible` / `Expanded` children does NOT exempt the screen — those handle horizontal-slack distribution, not scale-to-viewport. This rule aligns with Task 5's absolute "NEVER ship fixed pixel sizes... unless it's already inside one of these two patterns" — if you see any wording elsewhere in this skill that could be read as an escape hatch (size thresholds, "plausibly exceed", "if avatars are large", etc.), treat that language as OBSOLETE and follow this row's absolute rule. **Recurring miss:** Treasure Divide shipped both screens without responsiveness, causing hours of RenderFlex overflow debugging on smaller viewports before the retrofit landed. Reference patterns: `treasure_divide_game_screen.dart::_buildActivePlayerPanel` (LayoutBuilder + scale) and `treasure_divide_results_screen.dart::_buildResultsBody` (FittedBox + 1600×900 baseline).
>
> (pp) **Accumulated Build Quality Rules compliance** — review the "## Accumulated Build Quality Rules" section at the end of this skill. For each of the 34 rules, note whether it applies to this game and verify compliance:
> - Rule 1 (Character Randomization): applies if the game has more characters than players. Verify `_characterPaths` is shuffled in `initState`, not hardcoded by player index.
> - Rule 2 (Shape-following glow): applies if active-player characters have transparent PNG backgrounds. Verify `ImageFiltered`+`ColorFiltered` approach, NOT `BoxShadow` on Container.
> - Rule 3 (Per-player controls in player column): verify dart indicators and skip-turn button are in the player display column, not AppBar.
> - Rule 4 (Dart indicator hit tracking): applies if indicators show player color for hits vs neutral for misses. Verify `_currentTurnHits` tracked at throw time, cleared on turn change.
> - Rule 5 (All badge states): verify rankings/results badges show WIN, LOSS, and DRAW — no empty transparent loser state.
> - Rule 6 (Icon vs emoji): verify flag/bullet indicators use `Icon(...)` not emoji where player color matters.
> - Rule 7 (Text readability): verify significant text over background images uses 4-corner shadow outline.
> - Rule 8 (Settings + player persistence): verify `_changeSettings` passes all settings AND `initialSelectedPlayerIds` as constructor params; menu screen re-selects players in `addPostFrameCallback`.
> - Rule 9 (Randomized grid targets): applies to grid-based games. Verify targets shuffle from full 1–20 range with `Random?` parameter — no hardcoded layouts.
> - Rule 10 (Play-to-complete steal loop prevention): applies if game has steal/takeover mechanics. Verify non-winner always misses, winner only targets empty cells.
> - Rule 11 (Test keys for dynamic values): verify widget keys on runtime-determined values; ProviderHelpers expose them.
> - Rule 12 (`completeGameToVictory` dynamic reads): verify helper reads actual targets from provider — no hardcoded numbers; `throwForCellTarget` dispatch included.
> - Rule 13 (LayoutBuilder for game boards): verify game board elements use proportional sizing from `LayoutBuilder`, not fixed pixel sizes. Grid container margin is subtracted from available width before computing sibling column widths.
> - Rule 14 (Background texture opacity): verify texture images use ≥ 0.50 opacity; verify files actually exist at their paths.
> - Rule 15 (Inline `[DIAG]` reason strings): verify every navigation-dependent `findsOneWidget` in UI tests embeds an inline diagnostic in `reason:` — built from already-imported `ElementFinders` methods, not via a new shared helper. Apply to every nav-back, tap-then-expect, and modal-action assertion.
> - Rule 16 (`ensureVisible` before scrollable-content taps): verify `tester.ensureVisible(button); await tester.pump();` precedes every tap on a button inside a `SingleChildScrollView` — results-screen actions, save/resume modal buttons. `clickPlayAgain`/`clickChangeSettings`/`clickSelectDifferentGame` in `shared/results_helpers.dart` must include this from day one.
> - Rule 17 (Save/Resume real-flow): verify any test that taps Resume sets up the saved game via the in-game Save flow, NOT `preSaveGame(GameSaveConfig.foo())`. `preSaveGame` is only for tests that verify the resume modal appears in the saved-games list.
> - Rule 18 (Resume tile selection): verify every test that taps Resume calls `UITestHelpers.selectSavedGameTile(tester, savedId)` first — the Resume button is disabled until a tile is selected.
> - Rule 19 (`Navigator.push` not `pushReplacement`): verify `_startGame` in the menu screen uses `Navigator.push` so the menu stays on the route stack — back-from-game and Save-modal-Save both pop to menu.
> - Rule 20 (`_resetTurnForPlayer` undoes match-level): verify the provider's edit-score reset captures `winnerId == playerId`, `matchWinnerId == playerId`, and `isMatchDraw && !thisTurnWonMatch` BEFORE clearing round-level fields, then undoes `roundsWon` decrement, `matchWinnerId = null`, `isMatchDraw = false`, `state = GameState.playing`, `gameEndTime = null` for the affected paths.
> - Rule 21 (Edit dialog fills dropped darts): verify "edit removes winner" tests explicitly set ALL three darts in the dialog (typically `setDart1/2/3('Miss')`) — provider drops post-win Miss throws via the `!isGameActive` early return, so the initial segments only contain the winning dart.
> - Rule 22 (`_parseSegment` Miss representations): verify the helper accepts `'Miss'`, `'M'`, `'miss'`, `'-'`, `'—'`, and empty string as miss; lowercase `d`/`t` regex prefixes; `ensureVisible` on every ring/number tap.
> - Rule 23 (Strategy returns miss-shaped throw): verify `getNextThrow` returns `SimulatedThrow(score: 0, multiplier: 'miss', baseScore: 0)` for deliberate-miss turns, NOT `null`. Null is the runner's STOP signal.
> - Rule 24 (Inner LayoutBuilder for player column): verify `_buildPlayerColumn` wraps its body in a `LayoutBuilder` that clamps `charSize` against `columnConstraints.maxHeight`, with reserve `220 + (game.speedPlay ? 56 : 0)` for active and `80` for inactive.
> - Rule 25 (RGB-byte color comparison): verify visual-validation tests compare `color.red`/`green`/`blue` directly, NOT `color.value`.
> - Rule 26 (Shared helper sync): verify every shared-helper file in `integration_test/shared/` has an identical counterpart in `test/shared/`. Run `diff -q` on each pair.
> - Rule 27 (Runtime target lookup): if rule 9 applies (randomized targets), verify a `get[GameName]CellTargetNumber(tester, row, col)` helper exists in `provider_helpers.dart` and EVERY gameplay test that throws a specific dart uses it; verify a `throwForCellTarget(tester, target)` dispatch helper handles the `single`/`double`/`triple`/`bull` multiplier chooser.
>
> - **(zz) Option wiring trace.** For EVERY option in the spec's Options
>   section, cite four links with file:line:
>   1. **CONTROL** — the menu widget, its key in `[Game]MenuKeys`, and the
>      `onChanged`/`onTap` that writes the state field.
>   2. **HANDOFF** — that field appearing in the `provider.startGame(...)`
>      argument list.
>   3. **CONSUMPTION** — the provider or model reading it.
>   4. **EFFECT** — a keyed widget or branch on the game screen that renders
>      differently because of it.
>   A broken link at any step means the option does nothing the player can
>   see. Report the row as FAIL and dispatch a corrective sub-agent.
>   `flutter test test/meta/option_wiring_lint_test.dart` checks link 2
>   mechanically for every game — run it first and only hand-trace what it
>   cannot see (links 1, 3, 4).

> For each item I will cite the file and line number, or report MISSING.
> I will list every gap found."

Report AR-4 findings. Dispatch a corrective Sonnet sub-agent for any gaps before proceeding.

---

### GATE 1.5: Compile, Lint, and Boot Smoke (NON-NEGOTIABLE — before Phase 5)

**Why this gate exists.** Before it, the first time the app actually *ran* was
the screenshot phase. Every boot-time defect — a null in `initState`, an
unregistered provider, a home card that navigates nowhere, a web-only compile
error — surfaced there, as a capture that hung or produced a black frame, and
each one cost a full chromedriver cycle to diagnose. Gates 1-3 run
`flutter test`, which compiles `lib/` but never boots the app.

Run all four steps. Do not enter Phase 5 until every one is green.

**1. Analyze — zero errors:**
```bash
flutter analyze lib/ test/
```
Warnings are acceptable; errors are not. A pre-existing error anywhere in
`lib/` fails this gate — fix it or report it, do not route around it.

**2. Meta lints — these encode the rules this skill used to enforce by prose:**
```bash
flutter test test/meta/
```
- `game_style_lint_test.dart` — no raw Material palette colours in the new
  game, AppBar title uses a display font, back button is 32px with all three
  hover/highlight/splash colours transparent.
- `option_wiring_lint_test.dart` — every mutable menu setting reaches
  `provider.startGame(...)`. This is the "the toggle renders, toggles,
  persists, and changes nothing" failure, and it is invisible to behaviour
  tests.

A new game starts at zero violations. Do NOT add it to any baseline.

**3. Non-UI tests for the new game:**
```bash
flutter test test/providers/[GAME_SNAKE]_provider_game_test.dart \
             test/providers/[GAME_SNAKE]_save_restore_test.dart \
             test/models/[GAME_SNAKE]_serialization_test.dart
```

**4. Boot smoke — one drive test, under 90 seconds:**

Author `integration_test/[GAME_SNAKE]/visual_validation/boot_smoke_test.dart`:
ONE `testWidgets`, helpers inlined per the screenshot-test rules. It must:

1. Boot the app and find `HomeKeys.[game]Card`.
2. Tap it; assert the menu AppBar title renders.
3. Add two players; assert Start becomes enabled.
4. Start; assert the game screen's root key is present.
5. Throw one dart through the mock API; assert provider state changed.
6. Back out; choose DON'T SAVE; assert the menu is showing.

Zero uncaught exceptions throughout. Run it with the STEP 1 preflight
(`Phase 8 → STEP 1 PRE-FLIGHT`), which is also mandatory here.

On failure: fix the app, re-run. This test stays in the tree — Phase 8's
STEP 1 re-runs it as its own preflight step 0, so a regression that would
break the screenshot run is caught in 90 seconds rather than 10 minutes.

**Record in the build-state file:** `gates.gate1_5 = "PASS@<git sha>"`.

---
---
