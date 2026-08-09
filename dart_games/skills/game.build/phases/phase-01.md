<!-- game.build Phase 1 — carved from SKILL.md (WS07 §7.1).
     SKILL.md holds the index and the cross-cutting rules; this file
     holds this phase only. Read it when you reach the phase. -->

## Phase 1: Asset Setup

**Goal:** Verify all game assets are in place (with correct naming convention), update pubspec.yaml, ensure the dev branch exists.

**Model:** **Tier 3** (Sonnet) for verification + pubspec changes; **Tier 0** (orchestrator) for AR-1. See Model Strategy at top for tier reference.

### Delegate to Sonnet sub-agent

**Sub-agent prompt template:**

> You are completing Phase 1 (Asset Setup) for the **[GAME_NAME_DISPLAY]** game build in the Dart Games Flutter project.
>
> **Read first:**
> - Spec file: `[SPEC_PATH]` — focus on the "Asset Checklist" section (Section [N]) and "Development Workflow" (Section [M]) per the section map below. The Asset Checklist MUST have BOTH a "Source File" column (where the user dropped the raw asset, typically under `C:\Users\steve\Downloads\<GameName>\...`) AND a "File Path" column (canonical target path under `assets/games/[GAME_NAME_SNAKE]/...` with the project's `[GameName]-[Element].ext` PascalCase convention). The skill auto-copies + renames from Source → File Path; the user does NOT pre-stage assets in the project tree.
> - Section map (from Phase 0): [PASTE SECTION MAP TABLE]
> - `docs/development/asset-organization.md` — pay attention to the filename convention `[GameName]-[Element]-[Variant].ext` (PascalCase, hyphens between game name and element, prefixed with game name).
>
> **Tasks (in order):**
> 1. Run `git branch --show-current`. If not on `[BRANCH_NAME]`:
>    - If the branch exists: `git checkout [BRANCH_NAME]`
>    - Otherwise: `git checkout -b [BRANCH_NAME]`
> 2. Create the asset folder structure under `assets/games/[GAME_NAME_SNAKE]/` (use `mkdir -p`). Include every subdirectory the spec's Asset Checklist references (typically `icons/`, `images/`, `characters/`, `sounds/`) — create them ALL up front, even if some asset types are absent.
> 3. **Auto-copy + rename every asset** from the spec's Asset Checklist Source File column → File Path column. For each row:
>    - If the **target File Path already exists**, skip (idempotent re-run safety) — log "SKIP (already in place): <target>".
>    - Else if the **Source File exists**, copy with renaming via `cp "<source>" "<target>"`. Create any missing intermediate directories. Log "COPY: <source> → <target>".
>    - Else (both missing) — STOP immediately, do NOT proceed. Report the missing asset(s) to the orchestrator: list every row where neither source nor target exists. The user must place the source files at the spec's listed Source paths before re-running.
>    - The renaming is mechanical and unconditional — the spec's File Path column IS the canonical target. Do NOT prompt the user before renaming; the spec's File Path column is the authority.
> 4. **Verify the home-screen card icon is now at the expected target path** (typically `assets/games/[GAME_NAME_SNAKE]/icons/[GameName]-Icon.png` per the spec's Asset Checklist + `docs/development/adding-games.md`). This will be referenced by the home_screen.dart card in Phase 4.
> 5. For every asset listed in the spec's Asset Checklist, build a verification table AFTER the copy pass:
>    | Asset (spec) | Source path | Target path | Filename convention OK? | PRESENT (post-copy)? |
>    Filename convention: `[GameName]-[Element]-[Variant].ext`, PascalCase, hyphens between game name and element, no spaces, prefixed with the game name. Every row's "PRESENT (post-copy)?" column MUST be YES; if any is NO, dispatch the copy logic again or stop and surface to the orchestrator.
> 6. Read `pubspec.yaml`. If the game's asset directories are not listed under `flutter.assets`, add them in alphabetical order with the existing games.
> 7. Run `flutter pub get` and confirm exit code 0.
> 8. **Write the asset path manifest** at `temp_wireframes/[GAME_NAME_SNAKE]/asset_paths.md`. This is consumed by Phase 2 (wireframes) and Phase 3 (model `assetPath` getter). Format:
>    ```
>    # Lunar Lander asset paths (canonical post-rename — use these EXACTLY)
>
>    ## Icon / Background
>    - icon: `assets/games/[GAME_NAME_SNAKE]/icons/[GameName]-Icon.png`
>    - background: `assets/games/[GAME_NAME_SNAKE]/images/[GameName]-Background.png`
>
>    ## Characters (enum_value → path)
>    - spaceDog → `assets/games/[GAME_NAME_SNAKE]/characters/SpaceDog.png`
>    - moonCat  → `assets/games/[GAME_NAME_SNAKE]/characters/MoonCat.png`
>    - ...
>
>    ## Sounds (constant → path → start/end times)
>    - thrusterBurn → `assets/games/[GAME_NAME_SNAKE]/sounds/[GameName]-ThrusterBurn.mp3` → 0.5s–3.0s
>    - ...
>    ```
>    Phase 3 sub-agent reads this file to populate the model's `assetPath` getter using the renamed paths, NOT the spec's original (potentially pre-rename) names.
>
> **Report back:**
> - The copy-pass log from step 3 (each row: COPY / SKIP / FAIL)
> - The verification table from step 5 (paths, naming, present-post-copy)
> - Confirmation the home-screen icon is at the expected target path
> - The diff applied to `pubspec.yaml` (or "no changes needed")
> - The output of `flutter pub get`
> - Confirmation that `temp_wireframes/[GAME_NAME_SNAKE]/asset_paths.md` was written
> - The active git branch
>
> **Hard rules — Do NOT:**
> - Commit to master/main. Do NOT push to remote. All work stays on `[BRANCH_NAME]`.
> - Modify any files outside `pubspec.yaml` and the new `assets/games/[GAME_NAME_SNAKE]/` tree (the asset copies and the directories required for them are the ONLY allowed creations).
> - Create any placeholder asset files (only copy real source files from the spec's Source paths)
> - Overwrite an asset that already exists at the target path (skip — see step 3 idempotency rule)
> - Skip `flutter pub get`
> - Proceed if any source AND target are both missing — STOP and surface to the orchestrator instead

After the sub-agent returns, run `git status` and read the modified `pubspec.yaml` yourself to confirm.

### Adversarial Review AR-1: Asset Verification

> "I will now verify the sub-agent's work against the spec's Asset Checklist section. For every asset listed in the spec, I will re-read the file system and pubspec.yaml to confirm:
> (a) The file exists at the correct path with the correct filename
> (b) The filename follows the `[GameName]-[Element]-[Variant].ext` convention
> (c) The pubspec.yaml includes the asset directory
> (d) The home-screen card icon is present at its expected path
> (e) No assets are in the wrong subdirectory (e.g., character images in sounds/)
> (f) No spec assets were overlooked
> (g) The asset path manifest at `temp_wireframes/[GAME_NAME_SNAKE]/asset_paths.md` was written and lists every asset with its CANONICAL POST-RENAME path. Read the manifest and verify every listed path resolves to a real file (`if [ -f "$path" ]`). This manifest is the source of truth for Phases 2 (wireframes) and 3 (model `assetPath`) — a path mismatch here cascades into the model and screens, causing silent runtime image-load failures.
> (h) **Background image suitability check.** Read `[GameName]-Background.png` (and any per-screen background) using the Read tool. Evaluate it against the spec's Style section: is the image a TEXTURE (parchment, gradient, low-detail wash) suitable as a backdrop for UI overlays, OR a fully ILLUSTRATED SCENE (characters, dense detail, high-contrast features) that will visually compete with foreground elements? Past failure: Pirate's Grid shipped with a fully illustrated pirate scene as `PiratesGrid-Background.png`; UI elements (settings boxes, player tiles, dart indicators) were buried against the busy art and had to be polished with a 65% Ocean Navy overlay after the build. If the image looks too detailed for an overlay backdrop, surface this to the user IMMEDIATELY ('the user-provided background is illustrated rather than textured — recommend either (a) replace with a low-detail texture, OR (b) plan to add a translucent color overlay (e.g., `Container(color: navy.withOpacity(0.65))`) on top of the bg in every screen so UI is readable'). The Stage A wireframe sub-agent in Phase 2 needs this decision baked in, not discovered later.
>
> I will list every discrepancy found."

Report AR-1 findings. If discrepancies exist, dispatch a corrective Sonnet sub-agent with the specific gaps before proceeding.

---
