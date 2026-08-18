<!-- game.build Phase 5 — carved from SKILL.md (WS07 §7.1).
     SKILL.md holds the index and the cross-cutting rules; this file
     holds this phase only. Read it when you reach the phase. -->

## Phase 5: Announcement and Sound System

**Goal:** Implement the full announcement system with stacking prevention.

**Model:** **Tier 0** (orchestrator) designs stacking precedence; **Tier 3** (Sonnet) implements helper + sounds + tests; **Tier 0** runs AR-5. **After test authoring:** run **[Playbook §10 — Test-smell reviewer]** on the new announcement tests.

### Step 5A: Orchestrator designs stacking precedence (BEFORE delegation)

Before invoking the sub-agent, work through the worst-case stacking analysis on the orchestrator. This is the design that the implementer will follow:

1. List every announcement event in the spec's Announcements section.
2. Identify the worst-case dart throw — the single dart that could trigger the most simultaneous events.
3. Define the precedence order: which event wins when multiple fire on the same dart.
4. Confirm the rule: max 2 announcements per dart (1 moment + Remove Darts), and "Remove your darts" is NEVER suppressed.
5. Document the precedence chain as numbered rules — this becomes input to the sub-agent prompt.

### Step 5B: Delegate to Sonnet sub-agent

**Sub-agent prompt template:**

> You are completing Phase 5 (Announcement and Sound System) for the **[GAME_NAME_DISPLAY]** game build.
>
> **Read first:**
> - Spec file: `[SPEC_PATH]` — focus on the Asset Checklist (sound files with start/end times) and Announcements & Sound Effects section.
> - Section map: [PASTE SECTION MAP TABLE]
> - `docs/development/announcement-system.md`
> - At least one existing game's announcement helper for reference (e.g., `lib/services/target_tag_announcement_helper.dart`)
>
> **Stacking precedence rules (from orchestrator design — IMPLEMENT EXACTLY):**
>
> [PASTE NUMBERED PRECEDENCE RULES FROM STEP 5A]
>
> Hard rules:
> - Max 2 announcements fire per dart event (1 moment announcement + Remove Darts)
> - "Remove your darts" is NEVER suppressed regardless of what else triggers
> - Use the "gather facts, pick winner" pattern: collect every event the dart triggered, then select one moment announcement based on the precedence chain
> - **The game screen's takeout handler must call `announceRemoveDarts` UNCONDITIONALLY** (not inside a precedence `else` block — the call is independent of the moment-announcement winner)
>
> **Mandatory conventions (all 6 existing games follow these — do NOT diverge):**
>
> - **Sound file naming:** `GameName-SoundName.mp3` (PascalCase game name, PascalCase sound name, hyphen separator). Example: `ClockworkQuest-GearClick.mp3`, `LunarLander-ThrusterBurn.mp3`. Do NOT use snake_case filenames.
> - **Sound effects config `_basePath`:** `'games/[game_name_snake]/sounds/'` — NO `assets/` prefix. The Flutter asset system prepends `assets/` automatically.
> - **Sound trim times:** Every `SoundEffectConfig` MUST have an `endSeconds` value from the spec's Asset Checklist. Do NOT leave `endSeconds: null` — untrimmed audio makes the game feel sluggish.
> - **Announcement helper `dispose()`:** Every helper class MUST have a `void dispose() { _queueService.dispose(); }` method. The game screen calls `_audioQueue?.dispose()` in its `dispose()`.
> - **Game screen audio wiring checklist:**
>   1. `_audioQueue` field typed as the game's `AnnouncementHelper?`
>   2. Initialized in `_initializeGame()` via `GameAnnouncementQueueService` + `loadSettings()`
>   3. `announceGameStart()` called after init
>   4. First turn announced with 2000ms delay
>   5. Per-dart moment announcements in `_handleDartThrow` (with precedence chain + `isAutoPlaying` guard)
>   6. Remove darts announcement at 1500ms delay when `shouldPromptTakeout`
>   7. Turn announcement in `_handleTakeoutFinished` at 500ms delay (with `isAutoPlaying` guard)
>   8. `_audioQueue?.dispose()` in `dispose()`
> - **Test file:** `[GAME_NAME_SNAKE]_game_with_announcements_test.dart` testing full game flow with announcements (~18 tests covering lifecycle, moments, milestones, precedence, auto-play suppression)
>
> **Files to create:**
> 1. `lib/services/[GAME_NAME_SNAKE]_sound_effects.dart` — every sound file from the Asset Checklist + Announcements section with correct start/end times
> 2. `lib/services/[GAME_NAME_SNAKE]_announcement_helper.dart` — every announcement event with correct priority levels and sound effect associations, implementing the stacking precedence rules above. MUST include `dispose()` method.
> 3. `test/mocks/mock_[GAME_NAME_SNAKE]_audio_queue_service.dart`
> 4. `test/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_announcement_test.dart`
>    - Every test from the spec's Announcements testing section
>    - A test verifying max 2 announcements fire on the worst-case dart
>    - A test verifying "Remove your darts" always plays (cannot be suppressed)
> 5. `test/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_game_with_announcements_test.dart`
>    - Integration tests verifying announcements fire correctly from game state changes via the provider
>    - Lifecycle tests (game start, turn change, remove darts)
>    - Per-dart moment tests (hit, miss, advance, milestone events)
>    - Precedence tests (higher-priority events suppress lower-priority)
>    - Auto-play suppression tests (no announcements fire during Play-to-Complete)
>
> **Files to modify:**
> - `lib/screens/games/[GAME_NAME_SNAKE]/[GAME_NAME_SNAKE]_game_screen.dart` — wire the announcement helper into dart processing; verify `announceRemoveDarts` is called unconditionally on takeout (this was a Phase 4 requirement; if not yet present, add it now)
>
> **Verification:**
> - Run `flutter test test/screens/games/[GAME_NAME_SNAKE]/`
> - Confirm 100% pass rate
>
> **Report back:**
> - File paths created and modified
> - The full text of the precedence selection method in the announcement helper
> - The exact line number in the game screen where `announceRemoveDarts` is called (and confirmation it is NOT inside an `else` block)
> - The test name(s) covering the worst-case stacking scenario
> - Test results (X/Y passing)
>
> **Hard rules — Do NOT:**
> - Commit to master/main. Do NOT push to remote.

After the sub-agent returns, read `lib/services/[GAME_NAME_SNAKE]_announcement_helper.dart` and the relevant section of `[GAME_NAME_SNAKE]_game_screen.dart` yourself and trace the precedence implementation against your Step 5A design.

### Adversarial Review AR-5: Announcement Stacking Analysis

> "I will now verify the implementation matches the precedence design. I will:
>
> (a) Re-state the worst-case dart scenario from Step 5A
> (b) List all events that this worst-case dart could trigger simultaneously
> (c) Trace through the announcement helper code (the actual Dart code, not memory) to verify the precedence chain correctly suppresses lower-priority events
> (d) Count how many announcements would actually fire for this worst case
> (e) Verify the count does not exceed 2 (1 moment + Remove Darts)
> (f) **Trace the game-screen takeout handler** — read the actual code and verify `announceRemoveDarts` is called UNCONDITIONALLY (not inside a precedence `else`, not gated by the moment-announcement winner). Cite the file and line.
> (f-b) **Verify victory announcement fires ONLY from `_handleGameWon()`** — grep the game screen for `announceVictory`, `announceWinner`, `announceMatchVictory`. Every hit must be inside `_handleGameWon()`. If any hit is inside `_handleDartThrow()`, `_fireDartAnnouncement()`, or `pickAndAnnounceMoment()`, the victory fanfare will play before "remove your darts" — FAIL.
> (f-c) **Verify winning dart still gets its per-dart announcement** — trace the announcement code path when `hasWinner == true` after `processDartThrow()`. The per-dart score/hit announcement (descent, gear activated, flag planted, score readout, etc.) must still fire. If the helper has `if (hasWinner) return;` at the top of the precedence chain, or the game screen wraps the call in `if (!provider.hasWinner)`, the winning dart will be silent — FAIL. The correct sequence is: per-dart announcement → remove darts → takeout → victory.
> (g) Verify there is a test that covers this worst-case scenario, and that the test asserts both the count limit and Remove-Darts presence
>
> Worst-case scenario: [describe]
> Events triggered: [list]
> Announcements that fire: [count] — [PASS if <=2 / FAIL if >2]
> 'Remove your darts' suppressed: [YES/NO — must be NO]
> Game-screen call site: [file:line] — [UNCONDITIONAL / GATED]
> Speed Play timer deferred: [YES/NO/N/A] — if the game has a per-turn timer, verify every `_startSpeedPlayTimer` call site uses `whenIdle()` to wait for the turn announcement to finish before starting the countdown. Must be YES for timer-equipped games."

Report AR-5 findings. Dispatch a corrective Sonnet sub-agent for any issues before proceeding.

---
