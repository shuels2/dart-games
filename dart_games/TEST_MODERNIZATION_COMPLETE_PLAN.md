# Test Modernization - Complete Implementation Plan

**Version:** 2.0
**Date:** 2026-02-13
**Combines:** Technical implementation details + Agent team coordination
**Purpose:** Single comprehensive reference for test modernization project

---

## Quick Navigation

### Part 1: Project Overview
- [Executive Summary](#executive-summary)
- [Problem Analysis](#problem-analysis)
- [ROI Analysis](#roi-analysis)
- [Solution Overview](#solution-overview)
- [Team Structure](#team-structure)

### Part 2: Implementation Details - Test Modernization
- [Phase 1: Widget Keys Foundation](#phase-1-widget-keys-foundation)
- [Phase 2: Shared Test Components](#phase-2-shared-test-components)
- [Phase 3: Test Migration](#phase-3-test-migration)
- [Phase 4: Cleanup & Documentation](#phase-4-cleanup--documentation)

### Part 3: Project Management
- [Agent Roles & Responsibilities](#agent-roles--responsibilities)
- [Communication Protocol](#communication-protocol)
- [Quality Gates & Checkpoints](#quality-gates--checkpoints)
- [Risk Management](#risk-management)

### Part 4: Game Feature Enhancements
- [Phase 5: maxDartsPerTurn Property](#phase-5-maxdartsperturn-property)
- [Phase 6: Turn Management System](#phase-6-turn-management-system-with-_incrementturniffirst)
- [Phase 7: Global Skip Turn Component](#phase-7-global-skip-turn-component)

---

# PART 1: PROJECT OVERVIEW

## Executive Summary

### The Problem

The Dart Games test suite (302 tests total: 226 non-UI + 76 UI) suffers from:
- **~4,147 lines of duplicated test code** across 6 UI test files and 2 non-UI helper files
- **~28% test reliability** due to fragile text/type/index-based element finding
- **341 text-based finds** that break when UI text changes
- **85 index-based accesses** that break when UI is reordered
- **0 widget keys** for stable element identification

### The Solution

Implement two complementary improvements:

1. **Widget Keys** - Add 300+ widget keys to all interactive UI elements
   - Improves test reliability from ~28% to ~100%
   - Stable element identification that doesn't break with UI changes

2. **Shared Test Components** - Create 10 reusable test helper components
   - Eliminates ~4,147 lines of duplicate code
   - Single source of truth for common test operations
   - Reduces maintenance time by 83%

### Expected Outcomes

**Quantitative:**
- All 332 tests passing (256 non-UI + 76 UI)
- Test reliability: 28% → 100%
- Code reduction: -4,147 lines (~52% of UI test code)
- Maintenance time: 60 hours/year → 10 hours/year (-83%)
- Test execution time: Similar or faster

**Qualitative:**
- Tests don't break when UI text changes
- Tests don't break when UI is reordered
- Tests don't break when widget types change
- Easier to write new tests (use shared components)
- Easier to add new games (follow established patterns)
- Single source of truth for test operations

### Implementation Summary

**Effort:** 66-90 agent-hours total
**Timeline:** 5-7 weeks part-time OR 2-3 weeks full-time
**Files Modified:** ~315 files (300+ widgets + 6 tests + 1 keys file + helpers + docs)
**Critical Path:** Phase 1 (widget keys) must complete before Phase 3 (migration)

---

## Problem Analysis

### Duplication Analysis

#### 1. Sector Parsing Duplication

**Location:** Non-UI test helpers
**Files Affected:** 2
**Lines Duplicated:** 60 lines (30 lines × 2 implementations)

**Duplicate implementations:**
- `test/helpers/carnival_derby_test_helper.dart` (lines 118-149)
- `test/helpers/target_tag_test_helper.dart` (lines 321-352)

**Key Differences:**
```dart
// Carnival Derby returns: {'score': 50, 'multiplier': 'bullseye'}
// Target Tag returns: {'number': 50, 'multiplier': 'single'}
```

Both parse: S20, D20, T20, Bull, 25, 50, Miss, Outer Bull

---

#### 2. UI Helper Function Duplication

**Location:** Integration test files
**Files Affected:** 6
**Lines Duplicated:** ~2,887 lines total

**Breakdown by function:**

| Function | Files | Lines Each | Total | Purpose |
|----------|-------|------------|-------|---------|
| `navigateToTargetTagMenu()` | 5 | 18 | 90 | Navigate from home to Target Tag |
| `navigateToCarnivalDerbyMenu()` | 1 | 20 | 20 | Navigate from home to Carnival Derby |
| `addPlayer(name)` | 6 | 28 | 168 | Add player via dialog |
| `startGame()` | 6 | 18 | 108 | Click start button |
| `throwDart(number, multiplier)` | 4 | 20 | 80 | Simulate dart throw |
| `throwBullseye()` | 4 | 20 | 80 | Throw bullseye |
| `throwOuterBull()` | 2 | 20 | 40 | Throw outer bull |
| `throwMiss()` | 3 | 20 | 60 | Throw miss |
| `clickDartsRemoved()` | 5 | 11 | 55 | Click darts removed |
| `skipTurn()` | 2 | 18 | 36 | Skip turn |
| `enableHeroBonus()` | 2 | 35 | 70 | Toggle hero bonus |
| `enableTeamMode()` | 3 | 36 | 108 | Toggle team mode |
| `enableManualTeamAssignment()` | 2 | 100 | 200 | Manual team assignment |
| `setTargetScore(score)` | 1 | 28 | 28 | Set target score |
| `setShieldMax(value)` | 1 | 25 | 25 | Set shield max |
| `togglePerfectFinish()` | 1 | 12 | 12 | Toggle perfect finish |
| `openEditScore()` | 2 | 16 | 32 | Open edit score dialog |
| `updateScore()` | 2 | 12 | 24 | Submit edit score |
| `cancelEditScore()` | 2 | 12 | 24 | Cancel edit score |

**Total UI helper duplication:** ~1,260 lines

---

#### 3. Element Finding Duplication

**Location:** All UI test files
**Total Occurrences:** 341 text-based finds + 130 type-based finds + 85 index accesses = 556 fragile finds

**Common patterns:**

| Pattern | Count | Problem | Example |
|---------|-------|---------|---------|
| Text-based finding | 341 | Breaks on text changes | `find.text('Play Again')` |
| Type + index | 85 | Breaks on reordering | `find.byType(ElevatedButton).at(2)` |
| Type-based finding | 130 | Breaks on widget type changes | `find.byType(Slider)` |
| Descendant finding | 95 | Complex and fragile | `find.descendant(of: dialog, matching: text)` |

**Lines of duplicate finding code:** ~400 lines

---

#### 4. Provider Access Duplication

**Location:** All UI test files needing game state
**Lines Duplicated:** ~150 lines

**Repeated pattern (~30 occurrences):**
```dart
final context = tester.element(find.byType(MaterialApp));
final provider = Provider.of<GameProvider>(context, listen: false);
final value = provider.getSomeValue();
```

---

#### 5. Pump Sequence Duplication

**Location:** All UI test files (due to continuous animations)
**Occurrences:** 50+ times
**Lines Duplicated:** ~250 lines

**Repeated pattern:**
```dart
await tester.pump();
await tester.pump(const Duration(seconds: 1));
await tester.pump();
await tester.pump(const Duration(seconds: 5));
await tester.pump();
await tester.pump();
await tester.pump();
```

Required because `pumpAndSettle()` hangs on continuous animations (pulse effects).

---

### Total Duplication Summary

| Category | Files | Lines Duplicated |
|----------|-------|------------------|
| Sector parsing | 2 | 60 |
| UI helpers | 6 | 1,260 |
| Element finding | 6 | 400 |
| Provider access | 6 | 150 |
| Pump sequences | 6 | 250 |
| Edit score helpers | 6 | 780 |
| Results screen helpers | 6 | 420 |
| Player management | 6 | 540 |
| **TOTAL** | - | **~4,147 lines** |

---

## ROI Analysis

### Current State Fragility

**Test Fragility Metrics:**
- **341 text-based finds** - Break when text changes ("Play Again" → "Play Again!")
- **85 index-based accesses** - Break when UI is reordered
- **130 type-based finds** - Break when widget types change
- **0 widget keys** - No stable element identification

**Estimated Reliability:**
- Text changes: ~60% chance test breaks
- UI reordering: ~80% chance test breaks
- Widget refactoring: ~50% chance test breaks
- **Overall: ~28% reliability** when UI changes

### Proposed State with Widget Keys

**Test Reliability Metrics:**
- **300+ widget keys** - Stable identification
- **0 text-based finds** for interactive elements
- **0 index-based accesses** for buttons/tiles
- **Key-based finding** - Immune to text/order/type changes

**Estimated Reliability:**
- Text changes: No impact (keys unchanged)
- UI reordering: No impact (keys unchanged)
- Widget refactoring: No impact (keys unchanged)
- **Overall: ~100% reliability** when UI changes

### Maintenance Time Impact

**Current Maintenance (per year):**
- Text changes: 12 changes × 2 hours = 24 hours
- UI reordering: 6 reorders × 3 hours = 18 hours
- Widget refactoring: 4 refactors × 2 hours = 8 hours
- New game tests: 1 game × 10 hours = 10 hours
- **Total: ~60 hours/year**

**Future Maintenance with Keys + Shared Components:**
- Text changes: No test updates needed = 0 hours
- UI reordering: No test updates needed = 0 hours
- Widget refactoring: Minimal updates = 2 hours
- New game tests: Use shared components = 2 hours (80% faster)
- Shared component updates: 6 hours
- **Total: ~10 hours/year**

**Savings: 50 hours/year (83% reduction)**

### Implementation Investment

**Upfront Cost:**
- Phase 1 (Widget Keys): 26-34 hours
- Phase 2 (Shared Components): 11-17 hours
- Phase 3 (Migration): 16-22 hours
- Phase 4 (Documentation): 4.5-6.5 hours
- Quality Assurance (ongoing): 12-15 hours
- **Total: 69.5-94.5 agent-hours**

**Payback Period:**
- Investment: ~82 hours (average)
- Annual savings: 50 hours
- **Payback: 1.6 years (19 months)**

After 19 months, the modernization pays for itself and continues saving 50 hours/year.

### 5-Year ROI

**Total Investment:** 82 hours
**Total Savings:** 250 hours (50 hours × 5 years)
**Net Benefit:** 168 hours saved
**ROI:** 205% (2.05x return)

### Non-Quantifiable Benefits

1. **Confidence** - Tests won't randomly break
2. **Velocity** - New tests written 50% faster
3. **Onboarding** - New developers use shared components
4. **Quality** - Bugs found faster (tests more reliable)
5. **Maintenance** - Single source of truth for test operations

---

## Solution Overview

### Approach: Four-Phase Modernization

**Phase 1: Widget Keys** (Foundation)
- Add unique `Key` to all interactive UI elements
- Create centralized key definition file (`lib/constants/test_keys.dart`)
- Organize keys by screen/component
- No breaking changes to app functionality

**Phase 2: Shared Components** (Leverage Keys)
- Create reusable test helper components
- Use widget keys for reliable element finding
- Replace all text/type/index finding with key-based finding
- Eliminate duplication

**Phase 3: Migration** (Apply Components)
- Migrate 6 UI test files to use new infrastructure
- Replace duplicated code with shared component calls
- Maintain 100% test coverage (no reduction)

**Phase 4: Cleanup** (Finalize)
- Remove obsolete helper code
- Update documentation
- Verify all tests pass

### Component Architecture

**10 Shared Components:**

1. **SectorParser** - Parse dart notation (S20, D20, T20, etc.)
2. **PumpSequences** - Handle animations consistently
3. **ElementFinders** - Find UI elements using keys
4. **ProviderHelpers** - Access game state
5. **SettingsHelpers** - Configure game settings
6. **UITestHelpers** - High-level navigation
7. **EditScoreHelpers** - Edit score dialog operations
8. **ResultsHelpers** - Results screen operations
9. **PlayerTestUtils** - Player management
10. **GameUIConfig** - Game-specific configuration abstraction

### Widget Key Organization

**Centralized File:** `lib/constants/test_keys.dart`

**Key Classes:**
- `HomeKeys` - Home screen (game cards)
- `CarnivalDerbyMenuKeys` - Carnival Derby menu
- `TargetTagMenuKeys` - Target Tag menu
- `CarnivalDerbyGameKeys` - Carnival Derby game (60+ dart buttons)
- `TargetTagGameKeys` - Target Tag game (60+ dart buttons)
- `ResultsKeys` - Results screens (both games)
- `EditScoreDialogKeys` - Edit score dialog (both games)
- `AddPlayerDialogKeys` - Add player dialog
- `DartboardEmulatorKeys` - Dartboard emulator components

**Key Naming Convention:**
`Key('{screen}_{game}_{element}_{descriptor}')`

Examples:
- `Key('menu_cd_start_button')` - Carnival Derby start button
- `Key('game_tt_dart_double_20_button')` - Target Tag double 20 button
- `Key('dialog_edit_update_button')` - Edit score update button

---

## Team Structure

### Agent Team Composition

| Agent | Role | Primary Phases | Effort | Key Deliverables |
|-------|------|----------------|--------|------------------|
| 1 | Widget Keys Architect | Phase 1 | 26-34h | 300+ widget keys |
| 2 | Test Component Engineer | Phase 2 | 11-17h | 10 shared components |
| 3 | Test Migration Specialist | Phase 3 | 16-22h | 6 migrated test files |
| 4 | Quality Assurance Validator | All phases | 12-15h | Quality verification |
| 5 | Documentation Specialist | Phase 4 | 4.5-6.5h | Complete documentation |

**Total:** 69.5-94.5 agent-hours across 5 specialized roles

### Critical Path & Dependencies

```
Phase 1 (Keys) → Must complete before Phase 3 (Migration)
Phase 2 (Components) → Can run parallel with Phase 1D-1F

Critical Path:
Phase 1A-1C → Phase 1D-1F → Phase 3 → Phase 4
                ↓ (parallel)
              Phase 2
```

---

# PART 2: IMPLEMENTATION DETAILS

# PHASE 1: Widget Keys Foundation

## Overview

**Goal:** Add widget keys to all interactive UI elements for stable test identification.

**Duration:** 26-34 hours total
**Timeline:** 1-2 weeks part-time, 4-5 days full-time
**Agent:** Agent 1 (Widget Keys Architect)
**QA Support:** Agent 4 validates after each sub-phase
**Critical Success Factor:** Run tests after EVERY step - never proceed if tests fail

---

## Phase 1A: Key Naming Guide & Standards

**Goal:** Establish naming conventions and create documentation before adding any keys.

**Duration:** 2-3 hours
**Agent:** Agent 1 (primary), Agent 5 (reviews naming guide)

### Step 1A.1: Create Key Naming Guide

**Create file:** `docs/WIDGET_KEY_GUIDE.md`

**Content:**
```markdown
# Widget Key Naming Guide

## Naming Convention

Format: `{screen}_{widget_purpose}_{widget_type}`

### Screen Prefixes
- `home_` - Home screen (game selection)
- `menu_cd_` - Carnival Derby menu screen
- `menu_tt_` - Target Tag menu screen
- `game_cd_` - Carnival Derby game screen
- `game_tt_` - Target Tag game screen
- `results_cd_` - Carnival Derby results screen
- `results_tt_` - Target Tag results screen
- `dialog_edit_` - Edit score dialog
- `dialog_add_player_` - Add player dialog
- `dialog_team_` - Team assignment dialog
- `options_` - Options/settings screen
- `dartboard_` - Dartboard emulator components

### Widget Type Suffixes
- `_button` - All button types (ElevatedButton, TextButton, IconButton)
- `_switch` - Switch widgets
- `_slider` - Slider widgets
- `_field` - TextField widgets
- `_tile` - ListTile, player tiles
- `_card` - Card widgets
- `_fab` - FloatingActionButton

### Examples
- `home_carnival_derby_card` - Carnival Derby game card on home
- `menu_tt_add_player_button` - Add Player button on Target Tag menu
- `menu_cd_target_score_slider` - Target Score slider on Carnival Derby menu
- `menu_tt_team_mode_switch` - Team Mode switch on Target Tag menu
- `game_cd_dart_single_20_button` - Single 20 dart button in Carnival Derby
- `game_tt_skip_turn_button` - Skip Turn button in Target Tag
- `results_tt_play_again_button` - Play Again button on Target Tag results
- `dialog_edit_update_button` - Update button in edit score dialog

## Key Assignment Rules

### MUST Have Keys
- ✅ All interactive buttons
- ✅ All input controls (Switch, Slider, TextField, Checkbox)
- ✅ All navigation elements
- ✅ All dialog action buttons
- ✅ Dart throw buttons (all 60+)
- ✅ Player tiles/cards
- ✅ Settings controls

### Should Have Keys (If Tested)
- Game status displays
- Score displays
- Player name displays
- Turn indicators

### SKIP Keys (Never Tested)
- ❌ Pure layout widgets (Container, Padding, Column)
- ❌ Decorative images/icons
- ❌ Static text labels
- ❌ Background widgets

## Validation

Every new widget key must:
1. Follow naming convention
2. Be unique across entire app
3. Use const Key() constructor
4. Be documented in this guide
```

**Validation:**
```bash
# No validation needed - this is documentation
```

**Agent 4 Review:** Agent 5 (Documentation Specialist) reviews naming guide for clarity

---

### Step 1A.2: Add Key Constants File

**Create file:** `lib/constants/test_keys.dart`

**Content:**

```dart
import 'package:flutter/foundation.dart';

/// Widget keys for test automation
///
/// Naming convention: Key('{screen}_{game}_{element}_{descriptor}')
/// Example: Key('menu_cd_start_button')

// ============================================================================
// HOME SCREEN KEYS
// ============================================================================

class HomeKeys {
  // Game selection cards
  static const carnivalDerbyCard = Key('home_carnival_derby_card');
  static const targetTagCard = Key('home_target_tag_card');

  // Navigation
  static const optionsButton = Key('home_options_button');
}

// ============================================================================
// CARNIVAL DERBY KEYS
// ============================================================================

class CarnivalDerbyMenuKeys {
  // Player management
  static const addPlayerButton = Key('menu_cd_add_player_button');
  static playerTile(String playerId) => Key('menu_cd_player_tile_$playerId');
  static removePlayerButton(String playerId) => Key('menu_cd_remove_player_$playerId');

  // Settings
  static const targetScoreSlider = Key('menu_cd_target_score_slider');
  static const perfectFinishSwitch = Key('menu_cd_perfect_finish_switch');

  // Actions
  static const startButton = Key('menu_cd_start_button');
  static const backButton = Key('menu_cd_back_button');
}

class CarnivalDerbyGameKeys {
  // Game controls
  static const skipTurnButton = Key('game_cd_skip_turn_button');
  static const dartsRemovedButton = Key('game_cd_darts_removed_button');
  static const editScoreButton = Key('game_cd_edit_score_button');

  // Dart buttons - Singles
  static const dartSingle1 = Key('game_cd_dart_single_1_button');
  static const dartSingle2 = Key('game_cd_dart_single_2_button');
  static const dartSingle3 = Key('game_cd_dart_single_3_button');
  static const dartSingle4 = Key('game_cd_dart_single_4_button');
  static const dartSingle5 = Key('game_cd_dart_single_5_button');
  static const dartSingle6 = Key('game_cd_dart_single_6_button');
  static const dartSingle7 = Key('game_cd_dart_single_7_button');
  static const dartSingle8 = Key('game_cd_dart_single_8_button');
  static const dartSingle9 = Key('game_cd_dart_single_9_button');
  static const dartSingle10 = Key('game_cd_dart_single_10_button');
  static const dartSingle11 = Key('game_cd_dart_single_11_button');
  static const dartSingle12 = Key('game_cd_dart_single_12_button');
  static const dartSingle13 = Key('game_cd_dart_single_13_button');
  static const dartSingle14 = Key('game_cd_dart_single_14_button');
  static const dartSingle15 = Key('game_cd_dart_single_15_button');
  static const dartSingle16 = Key('game_cd_dart_single_16_button');
  static const dartSingle17 = Key('game_cd_dart_single_17_button');
  static const dartSingle18 = Key('game_cd_dart_single_18_button');
  static const dartSingle19 = Key('game_cd_dart_single_19_button');
  static const dartSingle20 = Key('game_cd_dart_single_20_button');

  // Dart buttons - Doubles
  static const dartDouble1 = Key('game_cd_dart_double_1_button');
  static const dartDouble2 = Key('game_cd_dart_double_2_button');
  static const dartDouble3 = Key('game_cd_dart_double_3_button');
  static const dartDouble4 = Key('game_cd_dart_double_4_button');
  static const dartDouble5 = Key('game_cd_dart_double_5_button');
  static const dartDouble6 = Key('game_cd_dart_double_6_button');
  static const dartDouble7 = Key('game_cd_dart_double_7_button');
  static const dartDouble8 = Key('game_cd_dart_double_8_button');
  static const dartDouble9 = Key('game_cd_dart_double_9_button');
  static const dartDouble10 = Key('game_cd_dart_double_10_button');
  static const dartDouble11 = Key('game_cd_dart_double_11_button');
  static const dartDouble12 = Key('game_cd_dart_double_12_button');
  static const dartDouble13 = Key('game_cd_dart_double_13_button');
  static const dartDouble14 = Key('game_cd_dart_double_14_button');
  static const dartDouble15 = Key('game_cd_dart_double_15_button');
  static const dartDouble16 = Key('game_cd_dart_double_16_button');
  static const dartDouble17 = Key('game_cd_dart_double_17_button');
  static const dartDouble18 = Key('game_cd_dart_double_18_button');
  static const dartDouble19 = Key('game_cd_dart_double_19_button');
  static const dartDouble20 = Key('game_cd_dart_double_20_button');

  // Dart buttons - Triples
  static const dartTriple1 = Key('game_cd_dart_triple_1_button');
  static const dartTriple2 = Key('game_cd_dart_triple_2_button');
  static const dartTriple3 = Key('game_cd_dart_triple_3_button');
  static const dartTriple4 = Key('game_cd_dart_triple_4_button');
  static const dartTriple5 = Key('game_cd_dart_triple_5_button');
  static const dartTriple6 = Key('game_cd_dart_triple_6_button');
  static const dartTriple7 = Key('game_cd_dart_triple_7_button');
  static const dartTriple8 = Key('game_cd_dart_triple_8_button');
  static const dartTriple9 = Key('game_cd_dart_triple_9_button');
  static const dartTriple10 = Key('game_cd_dart_triple_10_button');
  static const dartTriple11 = Key('game_cd_dart_triple_11_button');
  static const dartTriple12 = Key('game_cd_dart_triple_12_button');
  static const dartTriple13 = Key('game_cd_dart_triple_13_button');
  static const dartTriple14 = Key('game_cd_dart_triple_14_button');
  static const dartTriple15 = Key('game_cd_dart_triple_15_button');
  static const dartTriple16 = Key('game_cd_dart_triple_16_button');
  static const dartTriple17 = Key('game_cd_dart_triple_17_button');
  static const dartTriple18 = Key('game_cd_dart_triple_18_button');
  static const dartTriple19 = Key('game_cd_dart_triple_19_button');
  static const dartTriple20 = Key('game_cd_dart_triple_20_button');

  // Special dart buttons
  static const dartBullseye = Key('game_cd_dart_bullseye_button');
  static const dartOuterBull = Key('game_cd_dart_outer_bull_button');
  static const dartMiss = Key('game_cd_dart_miss_button');

  // Helper to get dart key programmatically
  static Key getDartKey(String multiplier, int number) {
    if (number == 50) return dartBullseye;
    if (number == 25) return dartOuterBull;

    final prefix = 'game_cd_dart_';
    final mult = multiplier.toLowerCase();
    return Key('${prefix}${mult}_${number}_button');
  }
}

class CarnivalDerbyResultsKeys {
  static const playAgainButton = Key('results_cd_play_again_button');
  static const changeSettingsButton = Key('results_cd_change_settings_button');
  static const selectDifferentGameButton = Key('results_cd_select_different_game_button');
}

// ============================================================================
// TARGET TAG KEYS
// ============================================================================

class TargetTagMenuKeys {
  // Player management
  static const addPlayerButton = Key('menu_tt_add_player_button');
  static playerTile(String playerId) => Key('menu_tt_player_tile_$playerId');
  static removePlayerButton(String playerId) => Key('menu_tt_remove_player_$playerId');

  // Settings
  static const shieldMaxSlider = Key('menu_tt_shield_max_slider');
  static const teamModeSwitch = Key('menu_tt_team_mode_switch');
  static const heroBonusSwitch = Key('menu_tt_hero_bonus_switch');
  static const manualTeamAssignmentSwitch = Key('menu_tt_manual_team_assignment_switch');

  // Actions
  static const startButton = Key('menu_tt_start_button');
  static const backButton = Key('menu_tt_back_button');
}

class TargetTagGameKeys {
  // Game controls
  static const skipTurnButton = Key('game_tt_skip_turn_button');
  static const dartsRemovedButton = Key('game_tt_darts_removed_button');
  static const editScoreButton = Key('game_tt_edit_score_button');

  // Dart buttons - Singles (same pattern as Carnival Derby)
  static const dartSingle1 = Key('game_tt_dart_single_1_button');
  static const dartSingle2 = Key('game_tt_dart_single_2_button');
  static const dartSingle3 = Key('game_tt_dart_single_3_button');
  static const dartSingle4 = Key('game_tt_dart_single_4_button');
  static const dartSingle5 = Key('game_tt_dart_single_5_button');
  static const dartSingle6 = Key('game_tt_dart_single_6_button');
  static const dartSingle7 = Key('game_tt_dart_single_7_button');
  static const dartSingle8 = Key('game_tt_dart_single_8_button');
  static const dartSingle9 = Key('game_tt_dart_single_9_button');
  static const dartSingle10 = Key('game_tt_dart_single_10_button');
  static const dartSingle11 = Key('game_tt_dart_single_11_button');
  static const dartSingle12 = Key('game_tt_dart_single_12_button');
  static const dartSingle13 = Key('game_tt_dart_single_13_button');
  static const dartSingle14 = Key('game_tt_dart_single_14_button');
  static const dartSingle15 = Key('game_tt_dart_single_15_button');
  static const dartSingle16 = Key('game_tt_dart_single_16_button');
  static const dartSingle17 = Key('game_tt_dart_single_17_button');
  static const dartSingle18 = Key('game_tt_dart_single_18_button');
  static const dartSingle19 = Key('game_tt_dart_single_19_button');
  static const dartSingle20 = Key('game_tt_dart_single_20_button');

  // Dart buttons - Doubles
  static const dartDouble1 = Key('game_tt_dart_double_1_button');
  static const dartDouble2 = Key('game_tt_dart_double_2_button');
  static const dartDouble3 = Key('game_tt_dart_double_3_button');
  static const dartDouble4 = Key('game_tt_dart_double_4_button');
  static const dartDouble5 = Key('game_tt_dart_double_5_button');
  static const dartDouble6 = Key('game_tt_dart_double_6_button');
  static const dartDouble7 = Key('game_tt_dart_double_7_button');
  static const dartDouble8 = Key('game_tt_dart_double_8_button');
  static const dartDouble9 = Key('game_tt_dart_double_9_button');
  static const dartDouble10 = Key('game_tt_dart_double_10_button');
  static const dartDouble11 = Key('game_tt_dart_double_11_button');
  static const dartDouble12 = Key('game_tt_dart_double_12_button');
  static const dartDouble13 = Key('game_tt_dart_double_13_button');
  static const dartDouble14 = Key('game_tt_dart_double_14_button');
  static const dartDouble15 = Key('game_tt_dart_double_15_button');
  static const dartDouble16 = Key('game_tt_dart_double_16_button');
  static const dartDouble17 = Key('game_tt_dart_double_17_button');
  static const dartDouble18 = Key('game_tt_dart_double_18_button');
  static const dartDouble19 = Key('game_tt_dart_double_19_button');
  static const dartDouble20 = Key('game_tt_dart_double_20_button');

  // Dart buttons - Triples
  static const dartTriple1 = Key('game_tt_dart_triple_1_button');
  static const dartTriple2 = Key('game_tt_dart_triple_2_button');
  static const dartTriple3 = Key('game_tt_dart_triple_3_button');
  static const dartTriple4 = Key('game_tt_dart_triple_4_button');
  static const dartTriple5 = Key('game_tt_dart_triple_5_button');
  static const dartTriple6 = Key('game_tt_dart_triple_6_button');
  static const dartTriple7 = Key('game_tt_dart_triple_7_button');
  static const dartTriple8 = Key('game_tt_dart_triple_8_button');
  static const dartTriple9 = Key('game_tt_dart_triple_9_button');
  static const dartTriple10 = Key('game_tt_dart_triple_10_button');
  static const dartTriple11 = Key('game_tt_dart_triple_11_button');
  static const dartTriple12 = Key('game_tt_dart_triple_12_button');
  static const dartTriple13 = Key('game_tt_dart_triple_13_button');
  static const dartTriple14 = Key('game_tt_dart_triple_14_button');
  static const dartTriple15 = Key('game_tt_dart_triple_15_button');
  static const dartTriple16 = Key('game_tt_dart_triple_16_button');
  static const dartTriple17 = Key('game_tt_dart_triple_17_button');
  static const dartTriple18 = Key('game_tt_dart_triple_18_button');
  static const dartTriple19 = Key('game_tt_dart_triple_19_button');
  static const dartTriple20 = Key('game_tt_dart_triple_20_button');

  // Special dart buttons
  static const dartBullseye = Key('game_tt_dart_bullseye_button');
  static const dartOuterBull = Key('game_tt_dart_outer_bull_button');
  static const dartMiss = Key('game_tt_dart_miss_button');

  // Helper to get dart key programmatically
  static Key getDartKey(String multiplier, int number) {
    if (number == 50) return dartBullseye;
    if (number == 25) return dartOuterBull;

    final prefix = 'game_tt_dart_';
    final mult = multiplier.toLowerCase();
    return Key('${prefix}${mult}_${number}_button');
  }
}

class TargetTagResultsKeys {
  static const playAgainButton = Key('results_tt_play_again_button');
  static const changeSettingsButton = Key('results_tt_change_settings_button');
  static const selectDifferentGameButton = Key('results_tt_select_different_game_button');
}

// ============================================================================
// DIALOG KEYS
// ============================================================================

class EditScoreDialogKeys {
  static const dialog = Key('dialog_edit_score');
  static const dart1Dropdown = Key('dialog_edit_dart1_dropdown');
  static const dart2Dropdown = Key('dialog_edit_dart2_dropdown');
  static const dart3Dropdown = Key('dialog_edit_dart3_dropdown');
  static const updateButton = Key('dialog_edit_update_button');
  static const cancelButton = Key('dialog_edit_cancel_button');
}

class AddPlayerDialogKeys {
  static const dialog = Key('dialog_add_player');
  static const nameField = Key('dialog_add_player_name_field');
  static const addButton = Key('dialog_add_player_add_button');
  static const cancelButton = Key('dialog_add_player_cancel_button');
  static const cameraButton = Key('dialog_add_player_camera_button');
  static const galleryButton = Key('dialog_add_player_gallery_button');
}

class TeamAssignmentDialogKeys {
  static const dialog = Key('dialog_team_assignment');
  static playerTeamDropdown(String playerId) => Key('dialog_team_player_${playerId}_dropdown');
  static const confirmButton = Key('dialog_team_confirm_button');
  static const cancelButton = Key('dialog_team_cancel_button');
}

// ============================================================================
// DARTBOARD EMULATOR KEYS
// ============================================================================

class DartboardEmulatorKeys {
  static const dartboard = Key('dartboard_emulator');
  static const removeButton = Key('dartboard_remove_button');
  static const showHideFab = Key('dartboard_show_hide_fab');
}
```

**Validation:**
```bash
cd dart_games
flutter analyze lib/constants/test_keys.dart
# Expected: No issues found
```

**Agent 4 Review:** Check for duplicate keys, verify naming convention followed

---

### Step 1A.3: Update CLAUDE.md with Key Guidelines

**File:** `CLAUDE.md`

**Location:** Add section after "Development Workflow" section

**Content to Add:**

```markdown
## Widget Keys for Testing

**ALL games MUST implement widget keys for testable elements.**

Widget keys enable reliable, maintainable UI testing by providing stable identifiers that don't break when text changes or UI is reordered.

### Why Widget Keys Are Required

**Problems with text/type/index-based finding:**
- ❌ Breaks when text changes (e.g., "Start Game" → "Begin Game")
- ❌ Breaks when UI is reordered (e.g., moving buttons)
- ❌ Breaks when widget types change (e.g., ElevatedButton → TextButton)
- ❌ Flaky tests that fail randomly based on timing
- ❌ Hard to maintain (magic indices, duplicated text)

**Benefits of key-based finding:**
- ✅ Stable across text changes
- ✅ Stable across UI refactoring
- ✅ Stable across widget type changes
- ✅ Clear intent (key name describes element)
- ✅ Easy to maintain (centralized in one file)

### What Needs Keys

Add `Key` to ALL interactive elements:
- ✅ Buttons (start, skip, edit, back, etc.)
- ✅ Player tiles (selectable, draggable)
- ✅ Menu cards (game selection)
- ✅ Input fields (text fields, dropdowns, sliders, switches)
- ✅ Dialogs (add player, edit score, settings)
- ✅ Dart score buttons (S20, D20, T20, Bull, Miss - all 60+)
- ✅ Navigation elements (tabs, drawers)
- ✅ Results screen elements (play again, change settings)

### Key Naming Convention

**Format:** `Key('screen_game_element_descriptor')`

**Components:**
- `screen` - Where the element appears (menu, game, results, dialog)
- `game` - Game abbreviation (cd = Carnival Derby, tt = Target Tag, etc.)
- `element` - Element type (button, tile, field, card)
- `descriptor` - Specific identifier (start, player, dart_single_20)

**Examples:**

```dart
// Menu screen keys
class YourGameMenuKeys {
  static const startButton = Key('menu_yg_start_button');
  static const addPlayerButton = Key('menu_yg_add_player_button');
  static playerTile(String playerId) => Key('menu_yg_player_tile_$playerId');
}

// Game screen keys
class YourGameGameKeys {
  static const dartSingle20 = Key('game_yg_dart_single_20_button');
  static const dartDouble20 = Key('game_yg_dart_double_20_button');
  static const skipTurnButton = Key('game_yg_skip_turn_button');
  static const dartsRemovedButton = Key('game_yg_darts_removed_button');
}

// Dialog keys
class YourGameDialogKeys {
  static const editScoreDialog = Key('dialog_yg_edit_score');
  static const confirmButton = Key('dialog_yg_confirm_button');
  static const cancelButton = Key('dialog_yg_cancel_button');
}
```

### Key Organization

**File:** `lib/constants/test_keys.dart`

Organize keys by screen/component:

```dart
// Home screen keys (shared across all games)
class HomeKeys {
  static const carnivalDerbyCard = Key('home_carnival_derby_card');
  static const targetTagCard = Key('home_target_tag_card');
}

// Your game keys (game-specific)
class YourGameMenuKeys { /* ... */ }
class YourGameGameKeys { /* ... */ }
class YourGameDialogKeys { /* ... */ }
class YourGameResultsKeys { /* ... */ }
```

### Implementation Example

**In your widget file:**

```dart
import 'package:dart_games/constants/test_keys.dart';

// Add keys to widgets
ElevatedButton(
  key: YourGameMenuKeys.startButton,  // ← Add key here
  onPressed: _startGame,
  child: Text('Start Game'),
)

// Dynamic keys (e.g., player tiles)
PlayerTile(
  key: YourGameMenuKeys.playerTile(player.id),  // ← Dynamic key
  player: player,
  onTap: () => _selectPlayer(player),
)
```

**In your tests:**

```dart
import 'package:dart_games/constants/test_keys.dart';

// Find elements by key (NOT by text or type)
final startButton = find.byKey(YourGameMenuKeys.startButton);
await tester.tap(startButton);

final aliceTile = find.byKey(YourGameMenuKeys.playerTile('alice-id'));
await tester.tap(aliceTile);

// NO MORE:
// ❌ find.text('Start Game')  // Breaks when text changes
// ❌ find.byType(ElevatedButton).at(2)  // Breaks when UI reorders
// ❌ find.widgetWithText(ElevatedButton, 'Start')  // Brittle and verbose
```

### Reference Implementations

See existing games for complete examples:
- Target Tag keys: `lib/constants/test_keys.dart` (TargetTagMenuKeys, TargetTagGameKeys, etc.)
- Carnival Derby keys: `lib/constants/test_keys.dart` (CarnivalDerbyMenuKeys, CarnivalDerbyGameKeys, etc.)
- Example tests using keys: `integration_test/target_tag_menu_and_mechanics_test.dart`
```

**Validation:**
```bash
cat CLAUDE.md | grep -A 20 "Widget Keys for Testing"
# Expected: Section is present and readable
```

**Agent 4 Review:** Agent 5 validates documentation accuracy

---

### Phase 1A Validation Checklist

**Before proceeding to Phase 1B:**

- [ ] `docs/WIDGET_KEY_GUIDE.md` created with complete guidelines
- [ ] `lib/constants/test_keys.dart` created with key constant classes
- [ ] `CLAUDE.md` updated with widget key section
- [ ] `flutter analyze lib/constants/test_keys.dart` passes
- [ ] Documentation reviewed by Agent 5
- [ ] Agent 4 QA approval

**Expected State:**
- Documentation complete
- No code changes yet
- No test changes yet
- Foundation ready for implementation

**Time Check:** Should take 2-3 hours. If taking longer, stop and reassess.

**Agent 4 Sign-Off Required:** Quality gate checkpoint

---

## Phase 1B: Home & Navigation Keys

**Goal:** Add keys to home screen and navigation elements.

**Duration:** 2-3 hours
**Agent:** Agent 1 (Widget Keys Architect)
**QA Support:** Agent 4 validates after completion

### Step 1B.1: Modify Home Screen

**File:** `lib/screens/home_screen.dart`

**Changes:**

1. **Add import at top of file:**
```dart
import 'package:dart_games/constants/test_keys.dart';
```

2. **Add keys to game selection cards:**

Find the Carnival Derby card (approximately line 80-120):
```dart
// BEFORE:
Card(
  elevation: 8,
  child: InkWell(
    onTap: () => _navigateToGame(context, '/carnivalDerby'),
    child: Column(
      // ...
    ),
  ),
)

// AFTER:
Card(
  key: HomeKeys.carnivalDerbyCard,  // ← ADD THIS
  elevation: 8,
  child: InkWell(
    onTap: () => _navigateToGame(context, '/carnivalDerby'),
    child: Column(
      // ...
    ),
  ),
)
```

Find the Target Tag card (approximately line 130-170):
```dart
// BEFORE:
Card(
  elevation: 8,
  child: InkWell(
    onTap: () => _navigateToGame(context, '/targetTag'),
    child: Column(
      // ...
    ),
  ),
)

// AFTER:
Card(
  key: HomeKeys.targetTagCard,  // ← ADD THIS
  elevation: 8,
  child: InkWell(
    onTap: () => _navigateToGame(context, '/targetTag'),
    child: Column(
      // ...
    ),
  ),
)
```

3. **Add key to options button (if present):**
```dart
// BEFORE:
IconButton(
  icon: Icon(Icons.settings),
  onPressed: () => Navigator.pushNamed(context, '/options'),
)

// AFTER:
IconButton(
  key: HomeKeys.optionsButton,  // ← ADD THIS
  icon: Icon(Icons.settings),
  onPressed: () => Navigator.pushNamed(context, '/options'),
)
```

**Validation:**
```bash
flutter analyze lib/screens/home_screen.dart
# Expected: No errors

flutter test
# Expected: All 226 tests still pass
```

**Agent 4 Review:** Verify keys added correctly, tests pass

---

### Phase 1B Validation Checklist

**Before proceeding to Phase 1C:**

- [ ] `lib/screens/home_screen.dart` modified with keys
- [ ] Import statement added
- [ ] All game cards keyed
- [ ] Navigation buttons keyed
- [ ] `flutter analyze` passes
- [ ] All 226 tests pass
- [ ] App runs without errors
- [ ] Agent 4 QA approval

**Expected State:**
- Home screen fully keyed
- No test failures
- No regressions

**Time Check:** Should take 2-3 hours total.

---

## Phase 1C: Game Menu Keys (Both Games)

**Goal:** Add keys to all menu screen widgets for both Carnival Derby and Target Tag.

**Duration:** 6-8 hours
**Agent:** Agent 1 (Widget Keys Architect)
**QA Support:** Agent 4 validates after completion

### Step 1C.1: Carnival Derby Menu Screen

**File:** `lib/screens/games/carnival_horse_race/horse_race_menu_screen.dart`

**Changes:**

1. **Add import:**
```dart
import 'package:dart_games/constants/test_keys.dart';
```

2. **Add Player button:**
```dart
// BEFORE:
ElevatedButton(
  onPressed: _handleAddPlayer,
  child: Text('Add Player'),
)

// AFTER:
ElevatedButton(
  key: CarnivalDerbyMenuKeys.addPlayerButton,  // ← ADD THIS
  onPressed: _handleAddPlayer,
  child: Text('Add Player'),
)
```

3. **Player tiles (ListView.builder):**
```dart
// BEFORE:
PlayerTile(
  player: player,
  onTap: () => playerProvider.selectPlayer(player, maxPlayers: 8),
  // ...
)

// AFTER:
PlayerTile(
  key: CarnivalDerbyMenuKeys.playerTile(player.id),  // ← ADD THIS
  player: player,
  onTap: () => playerProvider.selectPlayer(player, maxPlayers: 8),
  // ...
)
```

4. **Remove player buttons (if separate from tiles):**
```dart
// BEFORE:
IconButton(
  icon: Icon(Icons.close),
  onPressed: () => playerProvider.deselectPlayer(player),
)

// AFTER:
IconButton(
  key: CarnivalDerbyMenuKeys.removePlayerButton(player.id),  // ← ADD THIS
  icon: Icon(Icons.close),
  onPressed: () => playerProvider.deselectPlayer(player),
)
```

5. **Target Score slider:**
```dart
// BEFORE:
Slider(
  value: _targetScore.toDouble(),
  min: 50,
  max: 501,
  onChanged: (value) => setState(() => _targetScore = value.toInt()),
)

// AFTER:
Slider(
  key: CarnivalDerbyMenuKeys.targetScoreSlider,  // ← ADD THIS
  value: _targetScore.toDouble(),
  min: 50,
  max: 501,
  onChanged: (value) => setState(() => _targetScore = value.toInt()),
)
```

6. **Perfect Finish switch:**
```dart
// BEFORE:
Switch(
  value: _perfectFinishMode,
  onChanged: (value) => setState(() => _perfectFinishMode = value),
)

// AFTER:
Switch(
  key: CarnivalDerbyMenuKeys.perfectFinishSwitch,  // ← ADD THIS
  value: _perfectFinishMode,
  onChanged: (value) => setState(() => _perfectFinishMode = value),
)
```

7. **Start button:**
```dart
// BEFORE:
ElevatedButton(
  onPressed: _startGame,
  child: Text('Start Game'),
)

// AFTER:
ElevatedButton(
  key: CarnivalDerbyMenuKeys.startButton,  // ← ADD THIS
  onPressed: _startGame,
  child: Text('Start Game'),
)
```

8. **Back button:**
```dart
// BEFORE:
IconButton(
  icon: Icon(Icons.arrow_back),
  onPressed: () => Navigator.pop(context),
)

// AFTER:
IconButton(
  key: CarnivalDerbyMenuKeys.backButton,  // ← ADD THIS
  icon: Icon(Icons.arrow_back),
  onPressed: () => Navigator.pop(context),
)
```

**Validation:**
```bash
flutter analyze lib/screens/games/carnival_horse_race/horse_race_menu_screen.dart
# Expected: No errors

flutter test
# Expected: All 226 tests still pass
```

---

### Step 1C.2: Target Tag Menu Screen

**File:** `lib/screens/games/target_tag/target_tag_menu_screen.dart`

**Apply same pattern as Carnival Derby, using TargetTagMenuKeys:**

1. **Add import**
2. **Add Player button** → `TargetTagMenuKeys.addPlayerButton`
3. **Player tiles** → `TargetTagMenuKeys.playerTile(player.id)`
4. **Remove player buttons** → `TargetTagMenuKeys.removePlayerButton(player.id)`
5. **Shield Max slider** → `TargetTagMenuKeys.shieldMaxSlider`
6. **Team Mode switch** → `TargetTagMenuKeys.teamModeSwitch`
7. **Hero Bonus switch** → `TargetTagMenuKeys.heroBonusSwitch`
8. **Manual Team Assignment switch** → `TargetTagMenuKeys.manualTeamAssignmentSwitch`
9. **Start button** → `TargetTagMenuKeys.startButton`
10. **Back button** → `TargetTagMenuKeys.backButton`

**Validation:**
```bash
flutter analyze lib/screens/games/target_tag/target_tag_menu_screen.dart
# Expected: No errors

flutter test
# Expected: All 226 tests still pass
```

**Agent 4 Review:** Verify all menu widgets keyed, tests pass

---

### Phase 1C Validation Checklist

**Before proceeding to Phase 1D:**

- [ ] Carnival Derby menu screen fully keyed
- [ ] Target Tag menu screen fully keyed
- [ ] All player tiles have dynamic keys
- [ ] All settings controls keyed
- [ ] All action buttons keyed
- [ ] `flutter analyze` passes for both files
- [ ] All 226 tests pass
- [ ] App runs without errors
- [ ] Agent 4 QA approval

**Expected State:**
- Both menu screens fully keyed
- No test failures
- No regressions

**Time Check:** Should take 6-8 hours. This is a significant sub-phase.

---

## Phase 1D: Game Screen Keys (Both Games)

**Goal:** Add keys to all game screen widgets including ALL dart throw buttons.

**Duration:** 10-12 hours
**Agent:** Agent 1 (Widget Keys Architect)
**QA Support:** Agent 4 validates after completion

**CRITICAL:** This is the largest keying effort. Dart buttons alone are 60+ widgets per game. Take breaks.

### Step 1D.1: Carnival Derby Game Screen

**File:** `lib/screens/games/carnival_horse_race/horse_race_game_screen.dart`

**Changes:**

1. **Add import:**
```dart
import 'package:dart_games/constants/test_keys.dart';
```

2. **Game control buttons:**

```dart
// Skip Turn button
ElevatedButton(
  key: CarnivalDerbyGameKeys.skipTurnButton,
  onPressed: _skipTurn,
  child: Text('Skip Turn'),
)

// Darts Removed button
ElevatedButton(
  key: CarnivalDerbyGameKeys.dartsRemovedButton,
  onPressed: _handleDartsRemoved,
  child: Text('Darts Removed'),
)

// Edit Score button
ElevatedButton(
  key: CarnivalDerbyGameKeys.editScoreButton,
  onPressed: _openEditScore,
  child: Text('Edit Score'),
)
```

3. **Dart buttons - Singles (20 buttons):**

Find the dart button grid/layout. Add keys to each button:

```dart
// Single 1
DartButton(
  key: CarnivalDerbyGameKeys.dartSingle1,
  label: 'S1',
  onPressed: () => _throwDart(1, 'single'),
)

// Single 2
DartButton(
  key: CarnivalDerbyGameKeys.dartSingle2,
  label: 'S2',
  onPressed: () => _throwDart(2, 'single'),
)

// ... repeat for dartSingle3 through dartSingle20
```

4. **Dart buttons - Doubles (20 buttons):**

```dart
// Double 1
DartButton(
  key: CarnivalDerbyGameKeys.dartDouble1,
  label: 'D1',
  onPressed: () => _throwDart(1, 'double'),
)

// Double 2
DartButton(
  key: CarnivalDerbyGameKeys.dartDouble2,
  label: 'D2',
  onPressed: () => _throwDart(2, 'double'),
)

// ... repeat for dartDouble3 through dartDouble20
```

5. **Dart buttons - Triples (20 buttons):**

```dart
// Triple 1
DartButton(
  key: CarnivalDerbyGameKeys.dartTriple1,
  label: 'T1',
  onPressed: () => _throwDart(1, 'triple'),
)

// Triple 2
DartButton(
  key: CarnivalDerbyGameKeys.dartTriple2,
  label: 'T2',
  onPressed: () => _throwDart(2, 'triple'),
)

// ... repeat for dartTriple3 through dartTriple20
```

6. **Special dart buttons:**

```dart
// Bullseye
DartButton(
  key: CarnivalDerbyGameKeys.dartBullseye,
  label: 'Bull',
  onPressed: () => _throwDart(50, 'bullseye'),
)

// Outer Bull (25)
DartButton(
  key: CarnivalDerbyGameKeys.dartOuterBull,
  label: '25',
  onPressed: () => _throwDart(25, 'single'),
)

// Miss
DartButton(
  key: CarnivalDerbyGameKeys.dartMiss,
  label: 'Miss',
  onPressed: () => _throwDart(0, 'miss'),
)
```

**Validation:**
```bash
flutter analyze lib/screens/games/carnival_horse_race/horse_race_game_screen.dart
# Expected: No errors

flutter test
# Expected: All 226 tests still pass
```

**Agent 4 Review:** Verify ALL dart buttons keyed (63 total: 20 singles + 20 doubles + 20 triples + 3 specials)

---

### Step 1D.2: Target Tag Game Screen

**File:** `lib/screens/games/target_tag/target_tag_game_screen.dart`

**Apply same pattern as Carnival Derby, using TargetTagGameKeys:**

1. **Add import**
2. **Game control buttons:**
   - `TargetTagGameKeys.skipTurnButton`
   - `TargetTagGameKeys.dartsRemovedButton`
   - `TargetTagGameKeys.editScoreButton`
3. **All 60 dart buttons (singles, doubles, triples)**
4. **Special buttons (bullseye, outer bull, miss)**

**Validation:**
```bash
flutter analyze lib/screens/games/target_tag/target_tag_game_screen.dart
# Expected: No errors

flutter test
# Expected: All 226 tests still pass
```

**Agent 4 Review:** Verify ALL dart buttons keyed, tests pass

---

### Phase 1D Validation Checklist

**Before proceeding to Phase 1E:**

- [ ] Carnival Derby game screen fully keyed
  - [ ] 3 game control buttons keyed
  - [ ] 60 dart buttons keyed (singles, doubles, triples)
  - [ ] 3 special buttons keyed (bull, 25, miss)
- [ ] Target Tag game screen fully keyed (same counts)
- [ ] `flutter analyze` passes for both files
- [ ] All 226 tests pass
- [ ] App runs without errors
- [ ] Agent 4 QA approval

**Expected State:**
- Both game screens fully keyed (~126 dart buttons total)
- No test failures
- No regressions

**Time Check:** Should take 10-12 hours. This is the biggest sub-phase. Take breaks.

---

## Phase 1E: Results Screen Keys (Both Games)

**Goal:** Add keys to results screen widgets.

**Duration:** 2-3 hours
**Agent:** Agent 1 (Widget Keys Architect)
**QA Support:** Agent 4 validates after completion

### Step 1E.1: Carnival Derby Results Screen

**File:** `lib/screens/games/carnival_horse_race/horse_race_results_screen.dart`

**Changes:**

1. **Add import:**
```dart
import 'package:dart_games/constants/test_keys.dart';
```

2. **Play Again button:**
```dart
// BEFORE:
ElevatedButton(
  onPressed: _playAgain,
  child: Text('Play Again'),
)

// AFTER:
ElevatedButton(
  key: CarnivalDerbyResultsKeys.playAgainButton,  // ← ADD THIS
  onPressed: _playAgain,
  child: Text('Play Again'),
)
```

3. **Change Settings button:**
```dart
// BEFORE:
ElevatedButton(
  onPressed: _changeSettings,
  child: Text('Change Settings'),
)

// AFTER:
ElevatedButton(
  key: CarnivalDerbyResultsKeys.changeSettingsButton,  // ← ADD THIS
  onPressed: _changeSettings,
  child: Text('Change Settings'),
)
```

4. **Select Different Game button:**
```dart
// BEFORE:
ElevatedButton(
  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
  child: Text('Select Different Game'),
)

// AFTER:
ElevatedButton(
  key: CarnivalDerbyResultsKeys.selectDifferentGameButton,  // ← ADD THIS
  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
  child: Text('Select Different Game'),
)
```

**Validation:**
```bash
flutter analyze lib/screens/games/carnival_horse_race/horse_race_results_screen.dart
# Expected: No errors

flutter test
# Expected: All 226 tests still pass
```

---

### Step 1E.2: Target Tag Results Screen

**File:** `lib/screens/games/target_tag/target_tag_results_screen.dart`

**Apply same pattern using TargetTagResultsKeys:**

1. **Add import**
2. **Play Again button** → `TargetTagResultsKeys.playAgainButton`
3. **Change Settings button** → `TargetTagResultsKeys.changeSettingsButton`
4. **Select Different Game button** → `TargetTagResultsKeys.selectDifferentGameButton`

**Validation:**
```bash
flutter analyze lib/screens/games/target_tag/target_tag_results_screen.dart
# Expected: No errors

flutter test
# Expected: All 226 tests still pass
```

**Agent 4 Review:** Verify all results buttons keyed, tests pass

---

### Phase 1E Validation Checklist

**Before proceeding to Phase 1F:**

- [ ] Carnival Derby results screen fully keyed
- [ ] Target Tag results screen fully keyed
- [ ] All action buttons keyed
- [ ] `flutter analyze` passes for both files
- [ ] All 226 tests pass
- [ ] App runs without errors
- [ ] Agent 4 QA approval

**Expected State:**
- Both results screens fully keyed
- No test failures
- No regressions

**Time Check:** Should take 2-3 hours.

---

## Phase 1F: Dialog Keys (Edit Score, Add Player)

**Goal:** Add keys to all dialog widgets.

**Duration:** 4-5 hours
**Agent:** Agent 1 (Widget Keys Architect)
**QA Support:** Agent 4 validates after completion

### Step 1F.1: Edit Score Dialog (Both Games)

**Find:** Edit score dialog code (likely in game screen files or separate dialog file)

**Pattern applies to both Carnival Derby and Target Tag:**

```dart
// Import keys
import 'package:dart_games/constants/test_keys.dart';

// Dialog container
AlertDialog(
  key: EditScoreDialogKeys.dialog,  // ← ADD THIS
  title: Text('Edit Score'),
  content: Column(
    children: [
      // Dart 1 dropdown
      DropdownButton(
        key: EditScoreDialogKeys.dart1Dropdown,  // ← ADD THIS
        value: _dart1,
        items: dartOptions,
        onChanged: (value) => setState(() => _dart1 = value),
      ),

      // Dart 2 dropdown
      DropdownButton(
        key: EditScoreDialogKeys.dart2Dropdown,  // ← ADD THIS
        value: _dart2,
        items: dartOptions,
        onChanged: (value) => setState(() => _dart2 = value),
      ),

      // Dart 3 dropdown
      DropdownButton(
        key: EditScoreDialogKeys.dart3Dropdown,  // ← ADD THIS
        value: _dart3,
        items: dartOptions,
        onChanged: (value) => setState(() => _dart3 = value),
      ),
    ],
  ),
  actions: [
    // Cancel button
    TextButton(
      key: EditScoreDialogKeys.cancelButton,  // ← ADD THIS
      onPressed: () => Navigator.pop(context),
      child: Text('Cancel'),
    ),

    // Update button
    ElevatedButton(
      key: EditScoreDialogKeys.updateButton,  // ← ADD THIS
      onPressed: _updateScore,
      child: Text('Update'),
    ),
  ],
)
```

**Files to modify:**
- Carnival Derby edit score dialog (wherever it's defined)
- Target Tag edit score dialog (wherever it's defined)

**Validation:**
```bash
flutter test
# Expected: All 226 tests still pass
```

---

### Step 1F.2: Add Player Dialog

**Find:** Add player dialog code (likely in `lib/widgets/add_player/add_player_dialog.dart`)

**Changes:**

```dart
// Import keys
import 'package:dart_games/constants/test_keys.dart';

// Dialog container
AlertDialog(
  key: AddPlayerDialogKeys.dialog,  // ← ADD THIS
  title: Text('Add Player'),
  content: Column(
    children: [
      // Name field
      TextField(
        key: AddPlayerDialogKeys.nameField,  // ← ADD THIS
        decoration: InputDecoration(labelText: 'Name'),
        onChanged: (value) => setState(() => _name = value),
      ),

      // Camera button
      ElevatedButton(
        key: AddPlayerDialogKeys.cameraButton,  // ← ADD THIS
        onPressed: _pickImageFromCamera,
        child: Text('Camera'),
      ),

      // Gallery button
      ElevatedButton(
        key: AddPlayerDialogKeys.galleryButton,  // ← ADD THIS
        onPressed: _pickImageFromGallery,
        child: Text('Gallery'),
      ),
    ],
  ),
  actions: [
    // Cancel button
    TextButton(
      key: AddPlayerDialogKeys.cancelButton,  // ← ADD THIS
      onPressed: () => Navigator.pop(context),
      child: Text('Cancel'),
    ),

    // Add button
    ElevatedButton(
      key: AddPlayerDialogKeys.addButton,  // ← ADD THIS
      onPressed: _addPlayer,
      child: Text('Add'),
    ),
  ],
)
```

**Validation:**
```bash
flutter test
# Expected: All 226 tests still pass
```

---

### Step 1F.3: Team Assignment Dialog (Target Tag)

**Find:** Team assignment dialog code (likely in Target Tag menu screen)

**Changes:**

```dart
// Import keys
import 'package:dart_games/constants/test_keys.dart';

// Dialog container
AlertDialog(
  key: TeamAssignmentDialogKeys.dialog,  // ← ADD THIS
  title: Text('Assign Teams'),
  content: ListView.builder(
    itemCount: players.length,
    itemBuilder: (context, index) {
      final player = players[index];
      return DropdownButton(
        key: TeamAssignmentDialogKeys.playerTeamDropdown(player.id),  // ← ADD THIS (dynamic)
        value: _playerTeams[player.id],
        items: teamOptions,
        onChanged: (value) => setState(() => _playerTeams[player.id] = value),
      );
    },
  ),
  actions: [
    // Cancel button
    TextButton(
      key: TeamAssignmentDialogKeys.cancelButton,  // ← ADD THIS
      onPressed: () => Navigator.pop(context),
      child: Text('Cancel'),
    ),

    // Confirm button
    ElevatedButton(
      key: TeamAssignmentDialogKeys.confirmButton,  // ← ADD THIS
      onPressed: _confirmTeams,
      child: Text('Confirm'),
    ),
  ],
)
```

**Validation:**
```bash
flutter test
# Expected: All 226 tests still pass
```

**Agent 4 Review:** Verify all dialog widgets keyed, tests pass

---

### Phase 1F Validation Checklist

**Before proceeding to Phase 1 completion:**

- [ ] Edit score dialog keyed (both games)
- [ ] Add player dialog keyed
- [ ] Team assignment dialog keyed (Target Tag)
- [ ] All dialog inputs keyed
- [ ] All dialog buttons keyed
- [ ] `flutter analyze` passes
- [ ] All 226 tests pass
- [ ] App runs without errors
- [ ] Agent 4 QA approval

**Expected State:**
- All dialogs fully keyed
- No test failures
- No regressions

**Time Check:** Should take 4-5 hours.

---

## Phase 1 Complete - Final Validation

**Duration:** 1 hour for final verification
**Agent:** Agent 1 (Widget Keys Architect) + Agent 4 (QA Validator)

### Final Validation Checklist

**ALL sub-phases complete:**
- [x] Phase 1A: Key naming guide and standards
- [x] Phase 1B: Home & navigation keys
- [x] Phase 1C: Game menu keys (both games)
- [x] Phase 1D: Game screen keys (both games, 60+ dart buttons each)
- [x] Phase 1E: Results screen keys (both games)
- [x] Phase 1F: Dialog keys (edit score, add player, team assignment)

**Code Quality:**
- [ ] All ~300 widget keys added
- [ ] `lib/constants/test_keys.dart` complete and organized
- [ ] All screens/dialogs keyed
- [ ] No duplicate keys
- [ ] Naming convention followed consistently
- [ ] All imports added correctly

**Testing:**
- [ ] All 226 non-UI tests passing
- [ ] `flutter analyze` passes (0 errors)
- [ ] App runs without runtime errors
- [ ] No regressions in functionality

**Documentation:**
- [ ] `docs/WIDGET_KEY_GUIDE.md` complete
- [ ] `CLAUDE.md` updated with key requirements
- [ ] Agent 4 QA reports filed

**Verification Commands:**
```bash
# Static analysis
flutter analyze lib/constants/test_keys.dart
flutter analyze lib/screens/

# All tests
flutter test
# Expected: All 226 tests pass

# Manual smoke test
flutter run
# Navigate through app, verify:
# - Home screen loads
# - Both games accessible
# - Menus functional
# - Game screens work
# - Dialogs open/close
# - No crashes
```

**Expected Metrics:**
- Widget keys added: 300+
- Files modified: ~15
- Lines added: ~350 (key assignments + imports)
- Test pass rate: 100% (226/226)
- Analyze issues: 0

**Time Investment:** 26-34 hours (actual logged by Agent 1)

---

### Phase 1 Handoff Document

**Agent 1 Creates:**

```markdown
# Handoff: Phase 1 Complete - Widget Keys Foundation

**Completed By:** Agent 1 (Widget Keys Architect)
**Date:** [Date]
**Duration:** [Actual hours]

## Deliverables:
- [x] `docs/WIDGET_KEY_GUIDE.md` - Naming conventions and standards
- [x] `lib/constants/test_keys.dart` - 300+ widget key constants
- [x] Home screen fully keyed
- [x] Carnival Derby menu screen fully keyed
- [x] Target Tag menu screen fully keyed
- [x] Carnival Derby game screen fully keyed (63 dart buttons)
- [x] Target Tag game screen fully keyed (63 dart buttons)
- [x] Carnival Derby results screen fully keyed
- [x] Target Tag results screen fully keyed
- [x] Edit score dialogs keyed (both games)
- [x] Add player dialog keyed
- [x] Team assignment dialog keyed
- [x] CLAUDE.md updated

## Verification:
- [x] All tests pass: `flutter test` → 226/226 tests pass
- [x] No compilation errors: `flutter analyze` → 0 errors
- [x] App runs without regression
- [x] Manual testing completed (all screens accessible)

## Known Issues:
- None

## Notes for Phase 2 (Test Component Engineer):
- All widget keys are now available in `lib/constants/test_keys.dart`
- ElementFinders can now use keys instead of text/type/index finding
- Dynamic keys (player tiles, dart buttons) use factory methods
- All keys follow naming convention: `{screen}_{game}_{element}_{descriptor}`

**Sign-off:** Agent 1 - [Date]
```

**Agent 4 QA Review:**

```markdown
# QA Review: Phase 1 - Widget Keys Foundation

**Reviewed By:** Agent 4 (QA Validator)
**Date:** [Date]

## Verification Checklist:
- [x] All deliverables present
- [x] Tests pass: 226/226
- [x] Code quality acceptable (naming convention followed)
- [x] No regressions
- [x] Documentation complete

**Issues Found:** 0

**Key Count Verification:**
- HomeKeys: 3 keys
- CarnivalDerbyMenuKeys: 7 static + 2 dynamic functions = 9 total
- CarnivalDerbyGameKeys: 66 keys (3 controls + 63 darts)
- CarnivalDerbyResultsKeys: 3 keys
- TargetTagMenuKeys: 9 keys
- TargetTagGameKeys: 66 keys
- TargetTagResultsKeys: 3 keys
- EditScoreDialogKeys: 5 keys
- AddPlayerDialogKeys: 5 keys
- TeamAssignmentDialogKeys: 3 static + 1 dynamic = 4 keys
- **Total: ~170 static keys + dynamic functions**

**Status:** ☑ APPROVED

**Sign-off:** Agent 4 (QA Validator) - [Date]
```

**Agent 2 Acknowledges:**

```markdown
# Handoff Received: Phase 1 Complete

**Received By:** Agent 2 (Test Component Engineer)
**Date:** [Date]

## Confirmation:
- [x] Reviewed handoff document
- [x] Reviewed QA approval
- [x] Understand all widget keys available
- [x] Can proceed with Phase 2 (ElementFinders will use keys)

**Questions:**
- None

**Next Steps:**
- Begin Phase 2A: Create SectorParser and PumpSequences
- Then Phase 2B: Create ElementFinders (will use new widget keys)

**Sign-off:** Agent 2 (Test Component Engineer) - [Date]
```

---

### CHECKPOINT 1: Phase 1 Complete

**THIS IS A CRITICAL QUALITY GATE - DO NOT PROCEED UNTIL ALL CRITERIA MET**

✅ **Code Complete:**
- All 300+ widget keys added
- All imports correct
- No duplicate keys
- Naming convention followed

✅ **Quality Verified:**
- All 226 tests passing
- flutter analyze: 0 errors
- App runs without crashes
- No regressions

✅ **Documentation Complete:**
- Widget key guide created
- CLAUDE.md updated
- Handoff documents filed

✅ **Sign-Offs Complete:**
- Agent 1 signs off (Phase 1 complete)
- Agent 4 approves (QA passed)
- Agent 2 acknowledges (ready for Phase 2)

**IF ANY CRITERIA FAILS:**
1. Agent 4 documents failure
2. Agent 1 addresses issues
3. Re-validate
4. Do NOT proceed to Phase 2 until passed

**Ready for Phase 2:** ✅ YES / ☐ NO

---

# PHASE 2: Shared Test Components

## Overview

**Prerequisites:**
- Phase 1 complete (all widgets keyed)
- All 226 tests passing
- Checkpoint 1 passed

**Goal:** Create shared test components that use widget keys.

**Duration:** 11-17 hours
**Timeline:** 1-2 weeks part-time
**Agent:** Agent 2 (Test Component Engineer)
**QA Support:** Agent 4 validates after each sub-phase
**Critical Success Factor:** All components MUST use widget keys (no text/type/index finding)

---

## Phase 2A: Core Components (SectorParser, PumpSequences)

**Goal:** Create foundational shared components with no dependencies.

**Duration:** 2-3 hours
**Agent:** Agent 2 (Test Component Engineer)

### Step 2A.1: Create SectorParser Component

**Create file:** `test/shared/sector_parser.dart`

**Content:**

```dart
/// Shared sector parsing logic for dart notation
///
/// Parses dart sector strings like "S20", "D20", "T20", "Bull", "Miss"
/// Returns unified format: {'number': int, 'multiplier': String}
class SectorParser {
  /// Parse a sector string into number and multiplier
  ///
  /// Examples:
  /// - "S20" → {'number': 20, 'multiplier': 'single'}
  /// - "D20" → {'number': 20, 'multiplier': 'double'}
  /// - "T20" → {'number': 20, 'multiplier': 'triple'}
  /// - "Bull" → {'number': 50, 'multiplier': 'single'}
  /// - "25" → {'number': 25, 'multiplier': 'single'}
  /// - "Miss" → {'number': 0, 'multiplier': 'miss'}
  /// - "None" → null (treated as miss)
  static Map<String, dynamic>? parse(String sector) {
    // Handle bulls
    if (sector == 'Bull') {
      return {'number': 50, 'multiplier': 'single'};
    }
    if (sector == '25' || sector == 'Outer Bull') {
      return {'number': 25, 'multiplier': 'single'};
    }

    // Handle miss
    if (sector == 'Miss' || sector == 'None' || sector.isEmpty) {
      return {'number': 0, 'multiplier': 'miss'};
    }

    // Parse regular sectors (S20, D20, T20, etc.)
    final match = RegExp(r'^([SDTsdt])(\d+)$').firstMatch(sector);
    if (match == null) return null;

    final multiplierChar = match.group(1)!.toUpperCase();
    final number = int.parse(match.group(2)!);

    String multiplier;
    switch (multiplierChar) {
      case 'S':
        multiplier = 'single';
        break;
      case 'D':
        multiplier = 'double';
        break;
      case 'T':
        multiplier = 'triple';
        break;
      default:
        return null;
    }

    return {'number': number, 'multiplier': multiplier};
  }

  /// Get score value from sector string
  ///
  /// Examples:
  /// - "S20" → 20
  /// - "D20" → 40
  /// - "T20" → 60
  /// - "Bull" → 50
  /// - "Miss" → 0
  static int getScore(String sector) {
    final parsed = parse(sector);
    if (parsed == null) return 0;

    final number = parsed['number'] as int;
    final multiplier = parsed['multiplier'] as String;

    switch (multiplier) {
      case 'single':
      case 'miss':
        return number;
      case 'double':
        return number * 2;
      case 'triple':
        return number * 3;
      default:
        return 0;
    }
  }

  /// Convert to Carnival Derby format
  ///
  /// Carnival Derby uses: {'score': int, 'multiplier': String}
  /// Special handling for bullseye
  static Map<String, dynamic>? toCarnivalDerbyFormat(String sector) {
    final parsed = parse(sector);
    if (parsed == null) return null;

    final number = parsed['number'] as int;
    final multiplier = parsed['multiplier'] as String;

    // Special case: bullseye
    if (number == 50 && multiplier == 'single') {
      return {'score': 50, 'multiplier': 'bullseye'};
    }

    // Regular scoring
    return {'score': getScore(sector), 'multiplier': multiplier};
  }
}
```

---

### Step 2A.2: Create SectorParser Tests

**Create file:** `test/shared/sector_parser_test.dart`

**Content:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'sector_parser.dart';

void main() {
  group('SectorParser', () {
    group('parse()', () {
      test('parses singles correctly', () {
        expect(SectorParser.parse('S20'), {'number': 20, 'multiplier': 'single'});
        expect(SectorParser.parse('S1'), {'number': 1, 'multiplier': 'single'});
        expect(SectorParser.parse('s15'), {'number': 15, 'multiplier': 'single'});
      });

      test('parses doubles correctly', () {
        expect(SectorParser.parse('D20'), {'number': 20, 'multiplier': 'double'});
        expect(SectorParser.parse('d10'), {'number': 10, 'multiplier': 'double'});
      });

      test('parses triples correctly', () {
        expect(SectorParser.parse('T20'), {'number': 20, 'multiplier': 'triple'});
        expect(SectorParser.parse('t19'), {'number': 19, 'multiplier': 'triple'});
      });

      test('parses bullseye correctly', () {
        expect(SectorParser.parse('Bull'), {'number': 50, 'multiplier': 'single'});
      });

      test('parses outer bull correctly', () {
        expect(SectorParser.parse('25'), {'number': 25, 'multiplier': 'single'});
        expect(SectorParser.parse('Outer Bull'), {'number': 25, 'multiplier': 'single'});
      });

      test('parses miss correctly', () {
        expect(SectorParser.parse('Miss'), {'number': 0, 'multiplier': 'miss'});
        expect(SectorParser.parse('None'), {'number': 0, 'multiplier': 'miss'});
        expect(SectorParser.parse(''), {'number': 0, 'multiplier': 'miss'});
      });

      test('returns null for invalid input', () {
        expect(SectorParser.parse('X20'), null);
        expect(SectorParser.parse('20'), null);
        expect(SectorParser.parse('invalid'), null);
      });
    });

    group('getScore()', () {
      test('calculates single scores', () {
        expect(SectorParser.getScore('S20'), 20);
        expect(SectorParser.getScore('S1'), 1);
      });

      test('calculates double scores', () {
        expect(SectorParser.getScore('D20'), 40);
        expect(SectorParser.getScore('D10'), 20);
      });

      test('calculates triple scores', () {
        expect(SectorParser.getScore('T20'), 60);
        expect(SectorParser.getScore('T19'), 57);
      });

      test('handles special cases', () {
        expect(SectorParser.getScore('Bull'), 50);
        expect(SectorParser.getScore('25'), 25);
        expect(SectorParser.getScore('Miss'), 0);
      });
    });

    group('toCarnivalDerbyFormat()', () {
      test('converts regular sectors', () {
        expect(
          SectorParser.toCarnivalDerbyFormat('S20'),
          {'score': 20, 'multiplier': 'single'},
        );
        expect(
          SectorParser.toCarnivalDerbyFormat('D20'),
          {'score': 40, 'multiplier': 'double'},
        );
      });

      test('handles bullseye specially', () {
        expect(
          SectorParser.toCarnivalDerbyFormat('Bull'),
          {'score': 50, 'multiplier': 'bullseye'},
        );
      });

      test('returns null for invalid input', () {
        expect(SectorParser.toCarnivalDerbyFormat('invalid'), null);
      });
    });
  });
}
```

**Validation:**
```bash
flutter test test/shared/sector_parser_test.dart
# Expected: All 20 tests pass

flutter test
# Expected: All 246 tests pass (226 original + 20 new)
```

**Agent 4 Review:** Verify SectorParser tests pass, code quality good

---

### Step 2A.3: Create PumpSequences Component

**Create file:** `test/shared/pump_sequences.dart`

**Content:**

```dart
import 'package:flutter_test/flutter_test.dart';

/// Shared pump sequence patterns for UI tests
///
/// These handle continuous animations that prevent pumpAndSettle() from working.
/// Use these instead of raw pump() calls for consistency.
class PumpSequences {
  /// Standard navigation pump sequence
  ///
  /// Use after tapping a navigation element (button, card, etc.)
  ///
  /// Example:
  /// ```dart
  /// await tester.tap(find.byKey(HomeKeys.targetTagCard));
  /// await PumpSequences.navigation(tester);
  /// ```
  static Future<void> navigation(WidgetTester tester) async {
    await tester.pump(); // Process the tap
    await tester.pump(const Duration(seconds: 1)); // Let navigation complete
    await tester.pump(); // Process navigation
    await tester.pump(); // Build widget tree
  }

  /// Async data loading pump sequence
  ///
  /// Use after operations that load data from SharedPreferences or other async sources
  ///
  /// Example:
  /// ```dart
  /// // App loads players on startup
  /// app.main();
  /// await PumpSequences.asyncDataLoad(tester);
  /// ```
  static Future<void> asyncDataLoad(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5)); // Wait for async operation
    await tester.pump(); // Process data loaded
    await tester.pump(); // Rebuild widget tree
    await tester.pump(); // Layout widgets
    await tester.pump(); // Paint widgets
  }

  /// Dialog open pump sequence
  ///
  /// Use after tapping button that opens a dialog
  ///
  /// Example:
  /// ```dart
  /// await tester.tap(find.byKey(MenuKeys.addPlayerButton));
  /// await PumpSequences.dialogOpen(tester);
  /// ```
  static Future<void> dialogOpen(WidgetTester tester) async {
    await tester.pump(); // Process tap
    await tester.pump(const Duration(milliseconds: 500)); // Let dialog open
    await tester.pump(); // Build dialog
    await tester.pump(); // Layout dialog
    await tester.pump(); // Paint dialog
  }

  /// Dialog close pump sequence
  ///
  /// Use after tapping button that closes a dialog
  ///
  /// Example:
  /// ```dart
  /// await tester.tap(find.byKey(DialogKeys.cancelButton));
  /// await PumpSequences.dialogClose(tester);
  /// ```
  static Future<void> dialogClose(WidgetTester tester) async {
    await tester.pump(); // Process tap
    await tester.pump(const Duration(milliseconds: 500)); // Wait for dialog to close
    await tester.pump(); // Process dialog closing
  }

  /// Text entry pump sequence
  ///
  /// Use after entering text in a field
  ///
  /// Example:
  /// ```dart
  /// await tester.enterText(find.byKey(DialogKeys.nameField), 'Alice');
  /// await PumpSequences.textEntry(tester);
  /// ```
  static Future<void> textEntry(WidgetTester tester) async {
    await tester.pump(); // Process text entry
    await tester.pump(); // Update text field
  }

  /// Simple UI update pump sequence
  ///
  /// Use after state changes that trigger simple UI updates (no navigation/dialogs)
  ///
  /// Example:
  /// ```dart
  /// await tester.tap(find.byKey(MenuKeys.teamModeSwitch));
  /// await PumpSequences.simpleUpdate(tester);
  /// ```
  static Future<void> simpleUpdate(WidgetTester tester) async {
    await tester.pump(); // Process state change
    await tester.pump(); // Rebuild UI
  }

  /// Full screen rebuild pump sequence
  ///
  /// Use when waiting for complete screen re-render (e.g., after game over)
  ///
  /// Example:
  /// ```dart
  /// // After last dart thrown in game
  /// await PumpSequences.fullRebuild(tester);
  /// ```
  static Future<void> fullRebuild(tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }
}
```

**Validation:**
```bash
flutter analyze test/shared/pump_sequences.dart
# Expected: No errors

# No tests needed - these are helper methods used by other tests
```

**Agent 4 Review:** Verify PumpSequences code quality, documentation clear

---

### Phase 2A Validation Checklist

**Before proceeding to Phase 2B:**

- [ ] `test/shared/sector_parser.dart` created
- [ ] `test/shared/sector_parser_test.dart` created with 20 tests
- [ ] `test/shared/pump_sequences.dart` created
- [ ] All 246 tests passing (226 original + 20 new)
- [ ] `flutter analyze` passes
- [ ] Agent 4 QA approval

**Expected State:**
- 2 core components created
- 20 new tests passing
- All 246 tests passing total
- Ready for Phase 2B

**Time Check:** Should take 2-3 hours.

---

## Phase 2B: Element Finders (Uses Keys!)

**Goal:** Create element finding helpers that use widget keys.

**Duration:** 2-3 hours
**Agent:** Agent 2 (Test Component Engineer)

**CRITICAL:** All element finders MUST use widget keys from Phase 1. NO text/type/index finding.

### Step 2B.1: Create ElementFinders Component

**Create file:** `test/shared/element_finders.dart`

**Content:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/constants/test_keys.dart';

/// Shared element finding helpers using widget keys
///
/// ALL finding uses keys (never text/type/index) for reliability.
class ElementFinders {
  // ==========================================================================
  // HOME SCREEN FINDERS
  // ==========================================================================

  static Finder getCarnivalDerbyCard() {
    return find.byKey(HomeKeys.carnivalDerbyCard);
  }

  static Finder getTargetTagCard() {
    return find.byKey(HomeKeys.targetTagCard);
  }

  static Finder getOptionsButton() {
    return find.byKey(HomeKeys.optionsButton);
  }

  // ==========================================================================
  // CARNIVAL DERBY MENU FINDERS
  // ==========================================================================

  static Finder getCarnivalDerbyAddPlayerButton() {
    return find.byKey(CarnivalDerbyMenuKeys.addPlayerButton);
  }

  static Finder getCarnivalDerbyPlayerTile(String playerId) {
    return find.byKey(CarnivalDerbyMenuKeys.playerTile(playerId));
  }

  static Finder getCarnivalDerbyRemovePlayerButton(String playerId) {
    return find.byKey(CarnivalDerbyMenuKeys.removePlayerButton(playerId));
  }

  static Finder getCarnivalDerbyTargetScoreSlider() {
    return find.byKey(CarnivalDerbyMenuKeys.targetScoreSlider);
  }

  static Finder getCarnivalDerbyPerfectFinishSwitch() {
    return find.byKey(CarnivalDerbyMenuKeys.perfectFinishSwitch);
  }

  static Finder getCarnivalDerbyStartButton() {
    return find.byKey(CarnivalDerbyMenuKeys.startButton);
  }

  static Finder getCarnivalDerbyBackButton() {
    return find.byKey(CarnivalDerbyMenuKeys.backButton);
  }

  // ==========================================================================
  // CARNIVAL DERBY GAME FINDERS
  // ==========================================================================

  static Finder getCarnivalDerbySkipTurnButton() {
    return find.byKey(CarnivalDerbyGameKeys.skipTurnButton);
  }

  static Finder getCarnivalDerbyDartsRemovedButton() {
    return find.byKey(CarnivalDerbyGameKeys.dartsRemovedButton);
  }

  static Finder getCarnivalDerbyEditScoreButton() {
    return find.byKey(CarnivalDerbyGameKeys.editScoreButton);
  }

  static Finder getCarnivalDerbyDartButton(String multiplier, int number) {
    return find.byKey(CarnivalDerbyGameKeys.getDartKey(multiplier, number));
  }

  static Finder getCarnivalDerbyBullseyeButton() {
    return find.byKey(CarnivalDerbyGameKeys.dartBullseye);
  }

  static Finder getCarnivalDerbyOuterBullButton() {
    return find.byKey(CarnivalDerbyGameKeys.dartOuterBull);
  }

  static Finder getCarnivalDerbyMissButton() {
    return find.byKey(CarnivalDerbyGameKeys.dartMiss);
  }

  // ==========================================================================
  // CARNIVAL DERBY RESULTS FINDERS
  // ==========================================================================

  static Finder getCarnivalDerbyPlayAgainButton() {
    return find.byKey(CarnivalDerbyResultsKeys.playAgainButton);
  }

  static Finder getCarnivalDerbyChangeSettingsButton() {
    return find.byKey(CarnivalDerbyResultsKeys.changeSettingsButton);
  }

  static Finder getCarnivalDerbySelectDifferentGameButton() {
    return find.byKey(CarnivalDerbyResultsKeys.selectDifferentGameButton);
  }

  // ==========================================================================
  // TARGET TAG MENU FINDERS
  // ==========================================================================

  static Finder getTargetTagAddPlayerButton() {
    return find.byKey(TargetTagMenuKeys.addPlayerButton);
  }

  static Finder getTargetTagPlayerTile(String playerId) {
    return find.byKey(TargetTagMenuKeys.playerTile(playerId));
  }

  static Finder getTargetTagRemovePlayerButton(String playerId) {
    return find.byKey(TargetTagMenuKeys.removePlayerButton(playerId));
  }

  static Finder getTargetTagShieldMaxSlider() {
    return find.byKey(TargetTagMenuKeys.shieldMaxSlider);
  }

  static Finder getTargetTagTeamModeSwitch() {
    return find.byKey(TargetTagMenuKeys.teamModeSwitch);
  }

  static Finder getTargetTagHeroBonusSwitch() {
    return find.byKey(TargetTagMenuKeys.heroBonusSwitch);
  }

  static Finder getTargetTagManualTeamAssignmentSwitch() {
    return find.byKey(TargetTagMenuKeys.manualTeamAssignmentSwitch);
  }

  static Finder getTargetTagStartButton() {
    return find.byKey(TargetTagMenuKeys.startButton);
  }

  static Finder getTargetTagBackButton() {
    return find.byKey(TargetTagMenuKeys.backButton);
  }

  // ==========================================================================
  // TARGET TAG GAME FINDERS
  // ==========================================================================

  static Finder getTargetTagSkipTurnButton() {
    return find.byKey(TargetTagGameKeys.skipTurnButton);
  }

  static Finder getTargetTagDartsRemovedButton() {
    return find.byKey(TargetTagGameKeys.dartsRemovedButton);
  }

  static Finder getTargetTagEditScoreButton() {
    return find.byKey(TargetTagGameKeys.editScoreButton);
  }

  static Finder getTargetTagDartButton(String multiplier, int number) {
    return find.byKey(TargetTagGameKeys.getDartKey(multiplier, number));
  }

  static Finder getTargetTagBullseyeButton() {
    return find.byKey(TargetTagGameKeys.dartBullseye);
  }

  static Finder getTargetTagOuterBullButton() {
    return find.byKey(TargetTagGameKeys.dartOuterBull);
  }

  static Finder getTargetTagMissButton() {
    return find.byKey(TargetTagGameKeys.dartMiss);
  }

  // ==========================================================================
  // TARGET TAG RESULTS FINDERS
  // ==========================================================================

  static Finder getTargetTagPlayAgainButton() {
    return find.byKey(TargetTagResultsKeys.playAgainButton);
  }

  static Finder getTargetTagChangeSettingsButton() {
    return find.byKey(TargetTagResultsKeys.changeSettingsButton);
  }

  static Finder getTargetTagSelectDifferentGameButton() {
    return find.byKey(TargetTagResultsKeys.selectDifferentGameButton);
  }

  // ==========================================================================
  // DIALOG FINDERS
  // ==========================================================================

  static Finder getEditScoreDialog() {
    return find.byKey(EditScoreDialogKeys.dialog);
  }

  static Finder getEditScoreDart1Dropdown() {
    return find.byKey(EditScoreDialogKeys.dart1Dropdown);
  }

  static Finder getEditScoreDart2Dropdown() {
    return find.byKey(EditScoreDialogKeys.dart2Dropdown);
  }

  static Finder getEditScoreDart3Dropdown() {
    return find.byKey(EditScoreDialogKeys.dart3Dropdown);
  }

  static Finder getEditScoreUpdateButton() {
    return find.byKey(EditScoreDialogKeys.updateButton);
  }

  static Finder getEditScoreCancelButton() {
    return find.byKey(EditScoreDialogKeys.cancelButton);
  }

  static Finder getAddPlayerDialog() {
    return find.byKey(AddPlayerDialogKeys.dialog);
  }

  static Finder getAddPlayerNameField() {
    return find.byKey(AddPlayerDialogKeys.nameField);
  }

  static Finder getAddPlayerAddButton() {
    return find.byKey(AddPlayerDialogKeys.addButton);
  }

  static Finder getAddPlayerCancelButton() {
    return find.byKey(AddPlayerDialogKeys.cancelButton);
  }

  static Finder getAddPlayerCameraButton() {
    return find.byKey(AddPlayerDialogKeys.cameraButton);
  }

  static Finder getAddPlayerGalleryButton() {
    return find.byKey(AddPlayerDialogKeys.galleryButton);
  }

  static Finder getTeamAssignmentDialog() {
    return find.byKey(TeamAssignmentDialogKeys.dialog);
  }

  static Finder getTeamAssignmentPlayerDropdown(String playerId) {
    return find.byKey(TeamAssignmentDialogKeys.playerTeamDropdown(playerId));
  }

  static Finder getTeamAssignmentConfirmButton() {
    return find.byKey(TeamAssignmentDialogKeys.confirmButton);
  }

  static Finder getTeamAssignmentCancelButton() {
    return find.byKey(TeamAssignmentDialogKeys.cancelButton);
  }
}
```

**Validation:**
```bash
flutter analyze test/shared/element_finders.dart
# Expected: No errors

# No tests needed - these are helper methods used by other tests
```

**Agent 4 Review:**
- Verify ALL finders use keys (no find.text, find.byType, or .at(index))
- Verify code quality and documentation

---

### Phase 2B Validation Checklist

**Before proceeding to Phase 2C:**

- [ ] `test/shared/element_finders.dart` created
- [ ] All finder methods use widget keys
- [ ] NO text-based finding
- [ ] NO type-based finding
- [ ] NO index-based accesses
- [ ] `flutter analyze` passes
- [ ] Agent 4 QA approval

**Expected State:**
- ElementFinders component complete
- All finders key-based
- All 246 tests still passing
- Ready for Phase 2C

**Time Check:** Should take 2-3 hours.

---

## Phase 2C: Provider & Settings Helpers

**Goal:** Create provider access and settings control helpers.

**Duration:** 2-3 hours
**Agent:** Agent 2 (Test Component Engineer)
**QA Support:** Agent 4 validates after completion

### Step 2C.1: Create ProviderHelpers

**File:** `test/shared/provider_helpers.dart`

**Implementation:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dart_games/providers/horse_race_provider.dart';
import 'package:dart_games/providers/target_tag_provider.dart';
import 'package:dart_games/providers/player_provider.dart';
import 'package:dart_games/models/player.dart';

/// Helpers for accessing provider state in UI tests.
class ProviderHelpers {
  /// Get the MaterialApp context from tester
  static BuildContext getContext(WidgetTester tester) {
    return tester.element(find.byType(MaterialApp));
  }

  /// Get Carnival Derby provider
  static HorseRaceProvider getCarnivalDerbyProvider(WidgetTester tester) {
    final context = getContext(tester);
    return Provider.of<HorseRaceProvider>(context, listen: false);
  }

  /// Get Target Tag provider
  static TargetTagProvider getTargetTagProvider(WidgetTester tester) {
    final context = getContext(tester);
    return Provider.of<TargetTagProvider>(context, listen: false);
  }

  /// Get Player provider
  static PlayerProvider getPlayerProvider(WidgetTester tester) {
    final context = getContext(tester);
    return Provider.of<PlayerProvider>(context, listen: false);
  }

  // ===== CARNIVAL DERBY HELPERS =====

  /// Carnival Derby: Get current player score
  static int getCurrentPlayerScore(WidgetTester tester) {
    final provider = getCarnivalDerbyProvider(tester);
    final currentPlayerId = provider.getCurrentPlayerId();
    if (currentPlayerId == null) return 0;
    return provider.getPlayerScore(currentPlayerId);
  }

  /// Carnival Derby: Check if player busted
  static bool hasPlayerBusted(WidgetTester tester) {
    final provider = getCarnivalDerbyProvider(tester);
    return provider.currentPlayerBusted;
  }

  /// Carnival Derby: Check for winner
  static bool carnivalDerbyHasWinner(WidgetTester tester) {
    final provider = getCarnivalDerbyProvider(tester);
    return provider.hasWinner;
  }

  /// Carnival Derby: Get winner
  static Player? getCarnivalDerbyWinner(WidgetTester tester, List<Player> players) {
    final provider = getCarnivalDerbyProvider(tester);
    return provider.getWinner(players);
  }

  // ===== TARGET TAG HELPERS =====

  /// Target Tag: Get player shields
  static int getPlayerShields(WidgetTester tester, String playerId) {
    final provider = getTargetTagProvider(tester);
    return provider.getShields(playerId);
  }

  /// Target Tag: Check if player is tagged in
  static bool isPlayerTaggedIn(WidgetTester tester, String playerId) {
    final provider = getTargetTagProvider(tester);
    return provider.isTaggedIn(playerId);
  }

  /// Target Tag: Check if player is eliminated
  static bool isPlayerEliminated(WidgetTester tester, String playerId) {
    final provider = getTargetTagProvider(tester);
    return provider.isEliminated(playerId);
  }

  /// Target Tag: Check for winner
  static bool targetTagHasWinner(WidgetTester tester) {
    final provider = getTargetTagProvider(tester);
    return provider.hasWinner;
  }

  /// Target Tag: Get winners (returns list for team mode support)
  static List<Player> getTargetTagWinners(WidgetTester tester, List<Player> players) {
    final provider = getTargetTagProvider(tester);
    return provider.getWinners(players);
  }
}
```

**Validation:**
```bash
flutter analyze test/shared/provider_helpers.dart
# Expected: No errors
```

**Agent 4 Review:** Verify all provider access methods work, code quality good

---

### Step 2C.2: Create SettingsHelpers

**File:** `test/shared/settings_helpers.dart`

**Implementation:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'element_finders.dart';
import 'pump_sequences.dart';

/// Helpers for interacting with game settings controls.
class SettingsHelpers {
  /// Set slider value (Shield Max, Target Score)
  static Future<void> setSliderValue(
    WidgetTester tester,
    Finder sliderFinder,
    double value, {
    double min = 0,
    double max = 1,
  }) async {
    expect(sliderFinder, findsOneWidget);

    // Calculate position based on value range
    final normalizedValue = (value - min) / (max - min);

    // Drag slider to position (200 is approximate slider width)
    await tester.drag(sliderFinder, Offset(normalizedValue * 200, 0));
    await PumpSequences.simpleUpdate(tester);
  }

  /// Target Tag: Set Shield Max (1-10)
  static Future<void> setShieldMax(WidgetTester tester, int shieldMax) async {
    await setSliderValue(
      tester,
      ElementFinders.getTargetTagShieldMaxSlider(),
      shieldMax.toDouble(),
      min: 1,
      max: 10,
    );
  }

  /// Carnival Derby: Set Target Score (50-501)
  static Future<void> setTargetScore(WidgetTester tester, int targetScore) async {
    await setSliderValue(
      tester,
      ElementFinders.getCarnivalDerbyTargetScoreSlider(),
      targetScore.toDouble(),
      min: 50,
      max: 501,
    );
  }

  /// Toggle switch (generic)
  static Future<void> toggleSwitch(WidgetTester tester, Finder switchFinder) async {
    expect(switchFinder, findsOneWidget);
    await tester.tap(switchFinder);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Target Tag: Toggle Team Mode
  static Future<void> toggleTeamMode(WidgetTester tester) async {
    await toggleSwitch(tester, ElementFinders.getTargetTagTeamModeSwitch());
  }

  /// Target Tag: Toggle Manual Team Assignment
  static Future<void> toggleManualTeamAssignment(WidgetTester tester) async {
    await toggleSwitch(tester, ElementFinders.getTargetTagManualTeamAssignmentSwitch());
  }

  /// Target Tag: Toggle Hero Bonus
  static Future<void> toggleHeroBonus(WidgetTester tester) async {
    await toggleSwitch(tester, ElementFinders.getTargetTagHeroBonusSwitch());
  }

  /// Carnival Derby: Toggle Perfect Finish
  static Future<void> togglePerfectFinish(WidgetTester tester) async {
    await toggleSwitch(tester, ElementFinders.getCarnivalDerbyPerfectFinishSwitch());
  }
}
```

**Validation:**
```bash
flutter analyze test/shared/settings_helpers.dart
# Expected: No errors
```

**Agent 4 Review:** Verify settings helpers use widget keys, code quality good

---

### Phase 2C Validation Checklist

**Before proceeding to Phase 2D:**

- [ ] `test/shared/provider_helpers.dart` created
- [ ] `test/shared/settings_helpers.dart` created
- [ ] All helpers use widget keys via ElementFinders
- [ ] `flutter analyze` passes
- [ ] No compilation errors
- [ ] Agent 4 QA approval

**Expected State:**
- Provider and settings helpers ready
- All using widget keys
- All 246 tests still passing
- Ready for Phase 2D

**Time Check:** Should take 2-3 hours.

---

## Phase 2D: UI Interaction Helpers

**Goal:** Create high-level UI interaction helpers using keys.

**Duration:** 2-3 hours
**Agent:** Agent 2 (Test Component Engineer)

### Step 2D.1: Create GameUIConfig and UITestHelpers

**File:** `test/shared/ui_test_helpers.dart`

**Implementation:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_games/main.dart' as app;
import 'element_finders.dart';
import 'pump_sequences.dart';

/// Configuration for game-specific UI elements
class GameUIConfig {
  final String gameName;

  const GameUIConfig.targetTag() : gameName = 'Target Tag';
  const GameUIConfig.carnivalDerby() : gameName = 'Carnival Derby';
}

/// Shared UI test helper functions using widget keys
class UITestHelpers {
  /// Navigate from home screen to game menu
  static Future<void> navigateToGameMenu(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    // Set up emulator mode
    SharedPreferences.setMockInitialValues({'use_emulator': true});

    app.main();
    await tester.pumpAndSettle();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final gameCard = config.gameName == 'Target Tag'
        ? ElementFinders.getTargetTagCard()
        : ElementFinders.getCarnivalDerbyCard();

    expect(gameCard, findsOneWidget);
    await tester.tap(gameCard);

    await PumpSequences.navigation(tester);
  }

  /// Add a player via the add player dialog
  static Future<void> addPlayer(
    WidgetTester tester,
    String name,
    GameUIConfig config,
  ) async {
    final addButton = config.gameName == 'Target Tag'
        ? ElementFinders.getTargetTagAddPlayerButton()
        : ElementFinders.getCarnivalDerbyAddPlayerButton();

    await tester.ensureVisible(addButton.first);
    await tester.pump();

    await tester.tap(addButton.first);
    await PumpSequences.dialogOpen(tester);

    final nameField = ElementFinders.getAddPlayerNameField();
    await tester.enterText(nameField, name);
    await PumpSequences.textEntry(tester);

    final addPlayerButton = ElementFinders.getAddPlayerAddButton();
    await tester.tap(addPlayerButton.first);
    await PumpSequences.dialogClose(tester);
    await PumpSequences.asyncDataLoad(tester);
  }

  /// Start the game
  static Future<void> startGame(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final startButton = config.gameName == 'Target Tag'
        ? ElementFinders.getTargetTagStartButton()
        : ElementFinders.getCarnivalDerbyStartButton();

    await tester.ensureVisible(startButton);
    await tester.pump();

    await tester.tap(startButton);
    await PumpSequences.navigation(tester);
  }

  /// Throw a dart (number with multiplier)
  static Future<void> throwDart(
    WidgetTester tester,
    GameUIConfig config,
    int number,
    {String multiplier = 'single'}
  ) async {
    final dartButton = config.gameName == 'Target Tag'
        ? ElementFinders.getTargetTagDartButton(multiplier, number)
        : ElementFinders.getCarnivalDerbyDartButton(multiplier, number);

    await tester.tap(dartButton);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Throw bullseye
  static Future<void> throwBullseye(WidgetTester tester, GameUIConfig config) async {
    final bullButton = config.gameName == 'Target Tag'
        ? ElementFinders.getTargetTagBullseyeButton()
        : ElementFinders.getCarnivalDerbyBullseyeButton();

    await tester.tap(bullButton);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Throw outer bull
  static Future<void> throwOuterBull(WidgetTester tester, GameUIConfig config) async {
    final outerBullButton = config.gameName == 'Target Tag'
        ? ElementFinders.getTargetTagOuterBullButton()
        : ElementFinders.getCarnivalDerbyOuterBullButton();

    await tester.tap(outerBullButton);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Throw miss
  static Future<void> throwMiss(WidgetTester tester, GameUIConfig config) async {
    final missButton = config.gameName == 'Target Tag'
        ? ElementFinders.getTargetTagMissButton()
        : ElementFinders.getCarnivalDerbyMissButton();

    await tester.tap(missButton);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Click "Darts Removed" button
  static Future<void> clickDartsRemoved(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final removeButton = config.gameName == 'Target Tag'
        ? ElementFinders.getTargetTagDartsRemovedButton()
        : ElementFinders.getCarnivalDerbyDartsRemovedButton();

    await tester.tap(removeButton);
    await PumpSequences.simpleUpdate(tester);
  }

  /// Click "Skip Turn" button
  static Future<void> clickSkipTurn(
    WidgetTester tester,
    GameUIConfig config,
  ) async {
    final skipButton = config.gameName == 'Target Tag'
        ? ElementFinders.getTargetTagSkipTurnButton()
        : ElementFinders.getCarnivalDerbySkipTurnButton();

    await tester.tap(skipButton);
    await PumpSequences.simpleUpdate(tester);
  }
}
```

**Validation:**
```bash
flutter analyze test/shared/ui_test_helpers.dart
# Expected: No errors
```

**Agent 4 Review:** Verify all UI helpers use widget keys, code quality good

---

### Phase 2D Validation Checklist

**Before proceeding to Phase 2E:**

- [ ] `test/shared/ui_test_helpers.dart` created
- [ ] GameUIConfig class defined
- [ ] All UI helpers use ElementFinders (key-based)
- [ ] `flutter analyze` passes
- [ ] No compilation errors
- [ ] Agent 4 QA approval

**Expected State:**
- UI interaction helpers ready
- All using widget keys
- All 246 tests still passing
- Ready for Phase 2E

**Time Check:** Should take 2-3 hours.

---

## Phase 2E: Edit Score and Results Helpers

**Goal:** Create specialized helpers for edit score dialogs and results screens.

**Duration:** 2-3 hours
**Agent:** Agent 2 (Test Component Engineer)

### Step 2E.1: Create EditScoreHelpers

**File:** `test/shared/edit_score_helpers.dart`

**Implementation:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'element_finders.dart';
import 'pump_sequences.dart';
import 'ui_test_helpers.dart';

/// Helpers for interacting with edit score dialogs
class EditScoreHelpers {
  /// Open edit score dialog
  static Future<void> openEditScore(WidgetTester tester, GameUIConfig config) async {
    final editButton = config.gameName == 'Target Tag'
        ? ElementFinders.getTargetTagEditScoreButton()
        : ElementFinders.getCarnivalDerbyEditScoreButton();

    expect(editButton, findsOneWidget);
    await tester.tap(editButton);
    await PumpSequences.dialogOpen(tester);

    // Verify dialog opened
    expect(ElementFinders.getEditScoreUpdateButton(), findsOneWidget);
  }

  /// Update score (submit edit score dialog)
  static Future<void> updateScore(WidgetTester tester) async {
    final updateButton = ElementFinders.getEditScoreUpdateButton();
    await tester.tap(updateButton);
    await PumpSequences.dialogClose(tester);

    // Verify dialog closed
    expect(ElementFinders.getEditScoreUpdateButton(), findsNothing);
  }

  /// Cancel edit score
  static Future<void> cancelEditScore(WidgetTester tester) async {
    final cancelButton = ElementFinders.getEditScoreCancelButton();
    await tester.tap(cancelButton);
    await PumpSequences.dialogClose(tester);

    // Verify dialog closed
    expect(ElementFinders.getEditScoreUpdateButton(), findsNothing);
  }

  /// Target Tag: Add shields in edit score dialog
  static Future<void> addShields(WidgetTester tester, int count) async {
    // Implementation would use widget keys to find add shields button
    // This is a placeholder showing the pattern
    for (int i = 0; i < count; i++) {
      // await tester.tap(ElementFinders.getAddShieldButton());
      await PumpSequences.simpleUpdate(tester);
    }
  }

  /// Target Tag: Remove shields in edit score dialog
  static Future<void> removeShields(WidgetTester tester, int count) async {
    // Implementation would use widget keys to find remove shields button
    for (int i = 0; i < count; i++) {
      // await tester.tap(ElementFinders.getRemoveShieldButton());
      await PumpSequences.simpleUpdate(tester);
    }
  }
}
```

**Validation:**
```bash
flutter analyze test/shared/edit_score_helpers.dart
# Expected: No errors
```

**Agent 4 Review:** Verify edit score helpers use widget keys

---

### Step 2E.2: Create ResultsHelpers

**File:** `test/shared/results_helpers.dart`

**Implementation:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'element_finders.dart';
import 'pump_sequences.dart';
import 'ui_test_helpers.dart';

/// Helpers for interacting with results screens
class ResultsHelpers {
  /// Click Play Again button
  static Future<void> clickPlayAgain(WidgetTester tester, GameUIConfig config) async {
    final playAgainButton = config.gameName == 'Target Tag'
        ? ElementFinders.getTargetTagPlayAgainButton()
        : ElementFinders.getCarnivalDerbyPlayAgainButton();

    expect(playAgainButton, findsOneWidget);
    await tester.tap(playAgainButton);
    await PumpSequences.navigation(tester);
  }

  /// Click Change Settings button
  static Future<void> clickChangeSettings(WidgetTester tester, GameUIConfig config) async {
    final changeSettingsButton = config.gameName == 'Target Tag'
        ? ElementFinders.getTargetTagChangeSettingsButton()
        : ElementFinders.getCarnivalDerbyChangeSettingsButton();

    expect(changeSettingsButton, findsOneWidget);
    await tester.ensureVisible(changeSettingsButton);
    await tester.pump();
    await tester.tap(changeSettingsButton);
    await PumpSequences.navigation(tester);
  }

  /// Click Select Different Game button (return to home)
  static Future<void> clickSelectDifferentGame(WidgetTester tester, GameUIConfig config) async {
    final selectGameButton = config.gameName == 'Target Tag'
        ? ElementFinders.getTargetTagSelectDifferentGameButton()
        : ElementFinders.getCarnivalDerbySelectDifferentGameButton();

    expect(selectGameButton, findsOneWidget);
    await tester.tap(selectGameButton);
    await PumpSequences.navigation(tester);
  }

  /// Verify results screen displays winner
  static void verifyWinnerDisplayed(String winnerName) {
    expect(find.text('WINNER!'), findsOneWidget,
      reason: 'Results screen should show WINNER! text');
    expect(find.textContaining(winnerName), findsWidgets,
      reason: 'Results screen should show winner name: $winnerName');
  }

  /// Verify all results screen elements present
  static void verifyResultsScreenComplete(GameUIConfig config, String winnerName) {
    verifyWinnerDisplayed(winnerName);

    // Verify buttons present
    final playAgainButton = config.gameName == 'Target Tag'
        ? ElementFinders.getTargetTagPlayAgainButton()
        : ElementFinders.getCarnivalDerbyPlayAgainButton();
    expect(playAgainButton, findsOneWidget);

    final changeSettingsButton = config.gameName == 'Target Tag'
        ? ElementFinders.getTargetTagChangeSettingsButton()
        : ElementFinders.getCarnivalDerbyChangeSettingsButton();
    expect(changeSettingsButton, findsOneWidget);
  }
}
```

**Validation:**
```bash
flutter analyze test/shared/results_helpers.dart
# Expected: No errors
```

**Agent 4 Review:** Verify results helpers use widget keys

---

### Phase 2E Validation Checklist

**Before proceeding to Phase 2F:**

- [ ] `test/shared/edit_score_helpers.dart` created
- [ ] `test/shared/results_helpers.dart` created
- [ ] All helpers use ElementFinders (key-based)
- [ ] `flutter analyze` passes
- [ ] No compilation errors
- [ ] Agent 4 QA approval

**Expected State:**
- Edit score and results helpers ready
- All using widget keys
- All 246 tests still passing
- Ready for Phase 2F

**Time Check:** Should take 2-3 hours.

---

## Phase 2F: Player Test Utils

**Goal:** Create player management utilities for tests.

**Duration:** 1-2 hours
**Agent:** Agent 2 (Test Component Engineer)

### Step 2F.1: Create PlayerTestUtils

**File:** `test/shared/player_test_utils.dart`

**Implementation:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/models/player.dart';
import 'package:dart_games/providers/player_provider.dart';

/// Utilities for player management in tests
class PlayerTestUtils {
  /// Create multiple test players with sequential names
  static List<Player> createPlayers(int count, {String namePrefix = 'Player'}) {
    return List.generate(
      count,
      (i) => Player.create(name: '$namePrefix ${i + 1}'),
    );
  }

  /// Create and save multiple players to provider
  static Future<List<Player>> createAndSavePlayers(
    PlayerProvider provider,
    int count,
    {String namePrefix = 'Player'}
  ) async {
    final players = createPlayers(count, namePrefix: namePrefix);
    for (final player in players) {
      await provider.savePlayer(player);
    }
    return players;
  }

  /// Verify player has expected stats
  static void verifyPlayerStats(
    Player player, {
    required int gamesPlayed,
    required int gamesWon,
    int? historyLength,
    String? lastGameName,
    Duration? lastGameDuration,
  }) {
    expect(player.gamesPlayed, gamesPlayed,
      reason: '${player.name} should have played $gamesPlayed games');
    expect(player.gamesWon, gamesWon,
      reason: '${player.name} should have won $gamesWon games');

    if (historyLength != null) {
      expect(player.gameHistory.length, historyLength,
        reason: '${player.name} should have $historyLength history entries');
    }

    if (lastGameName != null && player.gameHistory.isNotEmpty) {
      expect(player.gameHistory.last.gameName, lastGameName,
        reason: '${player.name} last game should be $lastGameName');
    }

    if (lastGameDuration != null && player.gameHistory.isNotEmpty) {
      expect(player.gameHistory.last.duration, lastGameDuration,
        reason: '${player.name} last game duration mismatch');
    }
  }

  /// Find player by ID from provider
  static Player? getPlayerById(PlayerProvider provider, String playerId) {
    return provider.getPlayerById(playerId);
  }

  /// Reload players from storage and return specific player
  static Future<Player?> reloadAndGetPlayer(
    PlayerProvider provider,
    String playerId,
  ) async {
    await provider.loadPlayers();
    return getPlayerById(provider, playerId);
  }
}
```

**Create test file:** `test/shared/player_test_utils_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_games/providers/player_provider.dart';
import 'player_test_utils.dart';

void main() {
  group('PlayerTestUtils', () {
    test('creates multiple players with sequential names', () {
      final players = PlayerTestUtils.createPlayers(3);

      expect(players.length, 3);
      expect(players[0].name, 'Player 1');
      expect(players[1].name, 'Player 2');
      expect(players[2].name, 'Player 3');
    });

    test('creates players with custom prefix', () {
      final players = PlayerTestUtils.createPlayers(2, namePrefix: 'Test');

      expect(players.length, 2);
      expect(players[0].name, 'Test 1');
      expect(players[1].name, 'Test 2');
    });

    test('creates and saves players to provider', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = PlayerProvider();
      await provider.loadPlayers();

      final players = await PlayerTestUtils.createAndSavePlayers(provider, 2);

      expect(players.length, 2);
      expect(provider.allPlayers.length, 2);
      expect(provider.allPlayers[0].name, 'Player 1');
      expect(provider.allPlayers[1].name, 'Player 2');
    });

    test('verifies player stats - passes with correct stats', () {
      final player = Player.create(name: 'Test').copyWith(
        gamesPlayed: 5,
        gamesWon: 2,
      );

      expect(
        () => PlayerTestUtils.verifyPlayerStats(
          player,
          gamesPlayed: 5,
          gamesWon: 2,
        ),
        returnsNormally,
      );
    });

    test('verifies player stats - fails with incorrect stats', () {
      final player = Player.create(name: 'Test').copyWith(
        gamesPlayed: 5,
        gamesWon: 2,
      );

      expect(
        () => PlayerTestUtils.verifyPlayerStats(
          player,
          gamesPlayed: 10, // Wrong
          gamesWon: 2,
        ),
        throwsA(isA<TestFailure>()),
      );
    });

    test('finds player by ID from provider', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = PlayerProvider();
      await provider.loadPlayers();

      final players = await PlayerTestUtils.createAndSavePlayers(provider, 2);
      final foundPlayer = PlayerTestUtils.getPlayerById(provider, players[0].id);

      expect(foundPlayer, isNotNull);
      expect(foundPlayer!.id, players[0].id);
      expect(foundPlayer.name, 'Player 1');
    });

    test('reloads and gets player', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = PlayerProvider();
      await provider.loadPlayers();

      final players = await PlayerTestUtils.createAndSavePlayers(provider, 1);
      final playerId = players[0].id;

      // Simulate app restart
      final newProvider = PlayerProvider();
      final reloadedPlayer = await PlayerTestUtils.reloadAndGetPlayer(newProvider, playerId);

      expect(reloadedPlayer, isNotNull);
      expect(reloadedPlayer!.id, playerId);
      expect(reloadedPlayer.name, 'Player 1');
    });
  });
}
```

**Validation:**
```bash
# Run new tests
flutter test test/shared/player_test_utils_test.dart
# Expected: All ~10 new tests pass

# Run full test suite
flutter test
# Expected: All 256 tests pass (246 + 10 new)
```

**Agent 4 Review:** Verify PlayerTestUtils tests pass, code quality good

---

### Phase 2F Validation Checklist

**Before marking Phase 2 complete:**

- [ ] `test/shared/player_test_utils.dart` created
- [ ] `test/shared/player_test_utils_test.dart` created with 10 tests
- [ ] All 10 new tests passing
- [ ] All 256 tests passing total
- [ ] `flutter analyze` passes
- [ ] Agent 4 QA approval

**Expected State:**
- Player utilities complete with tests
- All 256 tests passing
- Ready for Phase 2 completion

**Time Check:** Should take 1-2 hours.

---

## Phase 2 Complete - Final Validation

**Duration:** 30 minutes for final verification
**Agent:** Agent 2 (Test Component Engineer) + Agent 4 (QA Validator)

### Final Validation Checklist

**ALL sub-phases complete:**
- [x] Phase 2A: SectorParser + PumpSequences (20 tests)
- [x] Phase 2B: ElementFinders
- [x] Phase 2C: ProviderHelpers + SettingsHelpers
- [x] Phase 2D: UITestHelpers + GameUIConfig
- [x] Phase 2E: EditScoreHelpers + ResultsHelpers
- [x] Phase 2F: PlayerTestUtils (10 tests)

**Code Quality:**
- [ ] All 10 shared component files created
- [ ] 30 new component tests passing
- [ ] All components use widget keys (no text/type/index)
- [ ] Component API clear and documented
- [ ] No circular dependencies

**Testing:**
- [ ] All 256 tests passing (226 original + 30 new)
- [ ] `flutter analyze` passes (0 errors)
- [ ] No regressions

**Verification Commands:**
```bash
# Test shared components
flutter test test/shared/
# Expected: All 30 tests pass

# Full test suite
flutter test
# Expected: All 256 tests pass

# Static analysis
flutter analyze test/shared/
# Expected: 0 errors
```

**Expected Metrics:**
- Shared components created: 10
- New tests added: 30
- Total tests: 256 (was 226)
- All components key-based: 100%

**Time Investment:** 11-17 hours (actual logged by Agent 2)

---

### Phase 2 Handoff Document

**Agent 2 Creates:**

```markdown
# Handoff: Phase 2 Complete - Shared Test Components

**Completed By:** Agent 2 (Test Component Engineer)
**Date:** [Date]
**Duration:** [Actual hours]

## Deliverables:
- [x] `test/shared/sector_parser.dart` + tests (20 tests)
- [x] `test/shared/pump_sequences.dart`
- [x] `test/shared/element_finders.dart`
- [x] `test/shared/provider_helpers.dart`
- [x] `test/shared/settings_helpers.dart`
- [x] `test/shared/ui_test_helpers.dart` + GameUIConfig
- [x] `test/shared/edit_score_helpers.dart`
- [x] `test/shared/results_helpers.dart`
- [x] `test/shared/player_test_utils.dart` + tests (10 tests)

## Verification:
- [x] All component tests pass: 30/30 tests pass
- [x] Full test suite passes: 256/256 tests pass
- [x] No compilation errors: `flutter analyze` → 0 errors
- [x] All components use widget keys (no text/type/index finding)

## Known Issues:
- None

## Notes for Phase 3 (Test Migration Specialist):
- All 10 shared components ready for use
- All components use ElementFinders (key-based) for finding widgets
- PumpSequences provides standard animation handling
- UITestHelpers has GameUIConfig for game-specific operations
- Start with smallest test file (target_tag_add_player_test.dart)

**Sign-off:** Agent 2 - [Date]
```

**Agent 4 QA Review:**

```markdown
# QA Review: Phase 2 - Shared Test Components

**Reviewed By:** Agent 4 (QA Validator)
**Date:** [Date]

## Verification Checklist:
- [x] All 10 deliverables present
- [x] Component tests pass: 30/30
- [x] Full tests pass: 256/256
- [x] Code quality acceptable (clean, documented)
- [x] All components use widget keys (verified - no find.text/find.byType.at())
- [x] No circular dependencies
- [x] No regressions

**Component Quality Check:**
- SectorParser: ✓ Good - handles all dart notation formats
- PumpSequences: ✓ Good - covers all animation patterns
- ElementFinders: ✓ Good - all key-based (0 text/type/index finds)
- ProviderHelpers: ✓ Good - clean provider access
- SettingsHelpers: ✓ Good - consistent slider/switch handling
- UITestHelpers: ✓ Good - high-level abstractions
- EditScoreHelpers: ✓ Good - dialog operations clean
- ResultsHelpers: ✓ Good - results navigation clear
- PlayerTestUtils: ✓ Good - useful utilities + tested

**Issues Found:** 0

**Status:** ☑ APPROVED

**Sign-off:** Agent 4 (QA Validator) - [Date]
```

**Agent 3 Acknowledges:**

```markdown
# Handoff Received: Phase 2 Complete

**Received By:** Agent 3 (Test Migration Specialist)
**Date:** [Date]

## Confirmation:
- [x] Reviewed handoff document
- [x] Reviewed QA approval
- [x] Understand all 10 shared components available
- [x] Ready to begin test migration

**Questions:**
- None

**Next Steps:**
- Begin Phase 3A: Develop migration strategy
- Then Phase 3B: Migrate target_tag_add_player_test.dart (smallest file)
- Validate tests pass before proceeding to next file

**Sign-off:** Agent 3 (Test Migration Specialist) - [Date]
```

---

### CHECKPOINT 2: Phase 2 Complete

**THIS IS A CRITICAL QUALITY GATE - DO NOT PROCEED UNTIL ALL CRITERIA MET**

✅ **Code Complete:**
- All 10 shared components created
- 30 new tests written and passing
- All components use widget keys

✅ **Quality Verified:**
- All 256 tests passing
- flutter analyze: 0 errors
- No circular dependencies
- No regressions

✅ **Documentation Complete:**
- Component APIs documented
- Handoff documents filed

✅ **Sign-Offs Complete:**
- Agent 2 signs off (Phase 2 complete)
- Agent 4 approves (QA passed)
- Agent 5 reviews (documentation quality)
- Agent 3 acknowledges (ready for Phase 3)

**IF ANY CRITERIA FAILS:**
1. Agent 4 documents failure
2. Agent 2 addresses issues
3. Re-validate
4. Do NOT proceed to Phase 3 until passed

**Ready for Phase 3:** ✅ YES / ☐ NO

---

# PHASE 3: Test Migration

## Overview

**Prerequisites:**
- Phase 1 complete (all widgets keyed)
- Phase 2 complete (all shared components created)
- All 256 tests passing
- Checkpoint 2 passed

**Goal:** Migrate all 6 UI test files to use shared components and widget keys.

**Duration:** 16-22 hours
**Timeline:** 2-3 weeks part-time
**Agent:** Agent 3 (Test Migration Specialist)
**QA Support:** Agent 4 validates after each file migration
**Critical Success Factor:** Migrate ONE file at a time, validate tests pass before next file

---

## Phase 3A: Migration Strategy

**Goal:** Establish migration patterns and approach.

**Duration:** 2-3 hours
**Agent:** Agent 3 (Test Migration Specialist)

### Migration Principles

**1. No Coverage Reduction Rule:**
- ALL existing test scenarios MUST be preserved
- ALL assertions MUST remain
- ALL edge cases MUST still be tested
- Can ADD new scenarios, cannot REMOVE any

**2. One File at a Time:**
- Migrate complete file before starting next
- Run tests after each migration
- Do NOT proceed if tests fail

**3. Standard Migration Pattern:**
```dart
// 1. Add imports
import '../test/shared/ui_test_helpers.dart';
import '../test/shared/element_finders.dart';
import '../test/shared/pump_sequences.dart';
import '../test/shared/provider_helpers.dart';
import '../test/shared/settings_helpers.dart';
import '../test/shared/edit_score_helpers.dart';
import '../test/shared/results_helpers.dart';

// 2. Add game config constant
const config = GameUIConfig.targetTag(); // or .carnivalDerby()

// 3. Delete ALL inline helper functions
// (navigateToMenu, addPlayer, throwDart, etc. - DELETE THEM ALL)

// 4. Replace inline code with shared helpers
// BEFORE:
final targetTagCard = find.text('Target Tag');
await tester.tap(targetTagCard);
await tester.pump();
await tester.pump(const Duration(seconds: 1));
// ... 10 more pump() calls

// AFTER:
await UITestHelpers.navigateToGameMenu(tester, config);

// 5. Replace element finding with ElementFinders
// BEFORE:
final startButton = find.text('START GAME');
await tester.tap(startButton);

// AFTER:
final startButton = ElementFinders.getTargetTagStartButton();
await tester.tap(startButton);

// 6. Replace pump sequences with PumpSequences
// BEFORE:
await tester.pump();
await tester.pump(const Duration(seconds: 1));
await tester.pump();
await tester.pump();

// AFTER:
await PumpSequences.navigation(tester);
```

### File Migration Order (Smallest to Largest)

1. **target_tag_add_player_test.dart** (6 tests, ~400 lines)
   - EASIEST - Good starting point
   - Expected reduction: ~150 lines (38%)

2. **target_tag_visual_validation_test.dart** (4 tests, ~750 lines)
   - Medium complexity
   - Expected reduction: ~200 lines (27%)

3. **target_tag_results_screen_test.dart** (6 tests, ~450 lines)
   - Medium complexity
   - Expected reduction: ~150 lines (33%)

4. **target_tag_gameplay_test.dart** (13 tests, ~2,000 lines)
   - Large file
   - Expected reduction: ~600 lines (30%)

5. **target_tag_menu_and_mechanics_test.dart** (23 tests, ~2,000 lines)
   - HARDEST - Most complex tests
   - Expected reduction: ~800 lines (40%)

6. **carnival_derby_ui_test.dart** (24 tests, ~1,500 lines)
   - Large file, different game
   - Expected reduction: ~600 lines (40%)

**Total Expected:** ~2,500 lines eliminated across all 6 files

---

### Migration Checklist Template

For each file, use this checklist:

```markdown
## File: [filename]

**Before Migration:**
- [ ] Read entire file, understand all test scenarios
- [ ] List all assertions to preserve
- [ ] Note any unique patterns not covered by shared components

**During Migration:**
- [ ] Add shared component imports
- [ ] Add GameUIConfig constant
- [ ] Delete inline helper functions
- [ ] Replace element finding with ElementFinders
- [ ] Replace navigation with UITestHelpers
- [ ] Replace pump sequences with PumpSequences
- [ ] Replace provider access with ProviderHelpers
- [ ] Verify all assertions preserved

**After Migration:**
- [ ] Run tests: `flutter drive ...` → All tests pass
- [ ] Compare scenarios: All original scenarios present
- [ ] Compare assertions: All original assertions present
- [ ] Agent 4 code review
- [ ] Agent 4 coverage verification
- [ ] Agent 4 QA approval

**Only proceed to next file after:**
- All tests passing ✓
- Agent 4 approval ✓
```

**Agent 4 Review:** Validate migration strategy, approve approach

---

### Phase 3A Validation Checklist

**Before proceeding to Phase 3B:**

- [ ] Migration principles documented
- [ ] Migration pattern established
- [ ] File order determined
- [ ] Migration checklist template created
- [ ] Agent 4 approves strategy

**Expected State:**
- Clear migration plan
- Ready to start with first file
- Agent 3 understands no-coverage-reduction rule

**Time Check:** Should take 2-3 hours.

---

## Phase 3B: File 1 - target_tag_add_player_test.dart

**Goal:** Migrate smallest test file as proof of concept.

**Duration:** 1-2 hours
**Agent:** Agent 3 (Test Migration Specialist)
**Tests:** 6 tests
**Expected Reduction:** ~150 lines (38%)

### Before Migration Example

**Original file structure (~400 lines):**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_games/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ~80 lines of inline helpers
  Future<void> navigateToTargetTagMenu(WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final targetTagCard = find.text('Target Tag');
    expect(targetTagCard, findsOneWidget);
    await tester.tap(targetTagCard);

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  Future<void> addPlayer(WidgetTester tester, String name) async {
    final addButton = find.text('NEW PLAYER');
    await tester.ensureVisible(addButton.first);
    await tester.pump();

    await tester.tap(addButton.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    final nameField = find.byType(TextField);
    await tester.enterText(nameField, name);
    await tester.pump();
    await tester.pump();

    final addPlayerButton = find.text('Add Player');
    await tester.tap(addPlayerButton.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  group('Target Tag - Add Player Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await prefs.setBool('use_emulator', true);
    });

    testWidgets('Test 1: Navigation and Initial Player Setup', (tester) async {
      await navigateToTargetTagMenu(tester);

      // Verify menu loaded
      expect(find.text('Target Tag'), findsWidgets);
      expect(find.text('START GAME'), findsOneWidget);
    });

    testWidgets('Test 2: Add Player with Name Only', (tester) async {
      await navigateToTargetTagMenu(tester);
      await addPlayer(tester, 'Alice');

      expect(find.text('Alice'), findsOneWidget);
    });

    // ... 4 more tests
  });
}
```

### After Migration

**Migrated file (~250 lines, -150 lines):**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ADD: Shared component imports
import '../test/shared/ui_test_helpers.dart';
import '../test/shared/element_finders.dart';
import '../test/shared/pump_sequences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ADD: Game config constant
  const config = GameUIConfig.targetTag();

  // DELETE: ALL inline helper functions removed

  group('Target Tag - Add Player Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await prefs.setBool('use_emulator', true);
    });

    testWidgets('Test 1: Navigation and Initial Player Setup', (tester) async {
      // BEFORE: await navigateToTargetTagMenu(tester);
      // AFTER:
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Verify menu loaded (PRESERVED assertions)
      expect(find.text('Target Tag'), findsWidgets);

      // BEFORE: find.text('START GAME')
      // AFTER:
      final startButton = ElementFinders.getTargetTagStartButton();
      expect(startButton, findsOneWidget);
    });

    testWidgets('Test 2: Add Player with Name Only', (tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // BEFORE: await addPlayer(tester, 'Alice');
      // AFTER:
      await UITestHelpers.addPlayer(tester, 'Alice', config);

      expect(find.text('Alice'), findsOneWidget); // PRESERVED assertion
    });

    testWidgets('Test 3: Add Player Photo UI Elements', (tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      // Open add player dialog
      final addButton = ElementFinders.getTargetTagAddPlayerButton();
      await tester.tap(addButton.first);
      await PumpSequences.dialogOpen(tester);

      // Verify dialog elements
      expect(ElementFinders.getAddPlayerNameField(), findsOneWidget);
      expect(ElementFinders.getAddPlayerCameraButton(), findsOneWidget);
      expect(ElementFinders.getAddPlayerGalleryButton(), findsOneWidget);
    });

    testWidgets('Test 4: Add Player Empty Name Validation', (tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      final addButton = ElementFinders.getTargetTagAddPlayerButton();
      await tester.tap(addButton.first);
      await PumpSequences.dialogOpen(tester);

      // Try to add without name
      final addPlayerButton = ElementFinders.getAddPlayerAddButton();
      await tester.tap(addPlayerButton.first);
      await PumpSequences.simpleUpdate(tester);

      // Dialog should still be open (validation failed)
      expect(ElementFinders.getAddPlayerDialog(), findsOneWidget);
    });

    testWidgets('Test 5: Add Player Whitespace-Only Name Validation', (tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      final addButton = ElementFinders.getTargetTagAddPlayerButton();
      await tester.tap(addButton.first);
      await PumpSequences.dialogOpen(tester);

      // Enter whitespace
      final nameField = ElementFinders.getAddPlayerNameField();
      await tester.enterText(nameField, '   ');
      await PumpSequences.textEntry(tester);

      // Try to add
      final addPlayerButton = ElementFinders.getAddPlayerAddButton();
      await tester.tap(addPlayerButton.first);
      await PumpSequences.simpleUpdate(tester);

      // Dialog should still be open
      expect(ElementFinders.getAddPlayerDialog(), findsOneWidget);
    });

    testWidgets('Test 6: Cancel Button Functionality', (tester) async {
      await UITestHelpers.navigateToGameMenu(tester, config);

      final addButton = ElementFinders.getTargetTagAddPlayerButton();
      await tester.tap(addButton.first);
      await PumpSequences.dialogOpen(tester);

      // Click cancel
      final cancelButton = ElementFinders.getAddPlayerCancelButton();
      await tester.tap(cancelButton);
      await PumpSequences.dialogClose(tester);

      // Dialog should be closed
      expect(ElementFinders.getAddPlayerDialog(), findsNothing);
    });
  });
}
```

**Validation:**
```bash
# Start chromedriver first
cd dart_games/chromedriver/chromedriver-win64
./chromedriver.exe --port=4444

# Run migrated test file
cd dart_games
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/target_tag_add_player_test.dart \
  -d chrome

# Expected: All 6 tests pass
```

**Agent 4 Review:**
- [ ] Verify all 6 tests pass
- [ ] Verify all inline helpers deleted
- [ ] Verify all element finding uses ElementFinders
- [ ] Verify all navigation uses UITestHelpers
- [ ] Verify all pump sequences use PumpSequences
- [ ] Verify no coverage reduction (all assertions preserved)

**Sign-off:** Agent 4 approval required before Phase 3C

---

### Phase 3B Validation Checklist

**Before proceeding to Phase 3C:**

- [ ] target_tag_add_player_test.dart migrated
- [ ] ~150 lines eliminated
- [ ] All 6 tests passing
- [ ] All inline helpers deleted
- [ ] All element finding uses keys
- [ ] All assertions preserved
- [ ] Agent 4 coverage verification complete
- [ ] Agent 4 QA approval

**Expected State:**
- First file migrated successfully
- Proof of concept complete
- Pattern validated
- Ready for next file

**Time Check:** Should take 1-2 hours.

---

## Phase 3C-3G: Remaining File Migrations

**Note:** Remaining files follow the same pattern as Phase 3B.

**Due to length constraints, I'll summarize the approach for each:**

### Phase 3C: target_tag_visual_validation_test.dart (4 tests)
- **Duration:** 1-2 hours
- **Expected reduction:** ~200 lines
- **Key changes:** Visual validation tests use ElementFinders for player tiles, badges, borders
- **Validation:** All 4 visual tests pass

### Phase 3D: target_tag_results_screen_test.dart (6 tests)
- **Duration:** 2-3 hours
- **Expected reduction:** ~150 lines
- **Key changes:** Use ResultsHelpers for Play Again, Change Settings buttons
- **Validation:** All 6 results tests pass

### Phase 3E: target_tag_gameplay_test.dart (13 tests)
- **Duration:** 3-4 hours
- **Expected reduction:** ~600 lines
- **Key changes:** Complex gameplay uses UITestHelpers.throwDart(), ProviderHelpers for state
- **Validation:** All 13 gameplay tests pass

### Phase 3F: target_tag_menu_and_mechanics_test.dart (23 tests)
- **Duration:** 4-5 hours
- **Expected reduction:** ~800 lines (LARGEST reduction)
- **Key changes:** Menu settings use SettingsHelpers, edit score uses EditScoreHelpers
- **Validation:** All 23 menu tests pass

### Phase 3G: carnival_derby_ui_test.dart (24 tests)
- **Duration:** 4-5 hours
- **Expected reduction:** ~600 lines
- **Key changes:** Same pattern, using GameUIConfig.carnivalDerby()
- **Validation:** All 24 Carnival Derby tests pass

---

## Phase 3 Complete - Final Validation

**Duration:** 1 hour for final verification
**Agent:** Agent 3 (Test Migration Specialist) + Agent 4 (QA Validator)

### Final Validation Checklist

**ALL sub-phases complete:**
- [x] Phase 3A: Migration strategy
- [x] Phase 3B: target_tag_add_player_test.dart (6 tests)
- [x] Phase 3C: target_tag_visual_validation_test.dart (4 tests)
- [x] Phase 3D: target_tag_results_screen_test.dart (6 tests)
- [x] Phase 3E: target_tag_gameplay_test.dart (13 tests)
- [x] Phase 3F: target_tag_menu_and_mechanics_test.dart (23 tests)
- [x] Phase 3G: carnival_derby_ui_test.dart (24 tests)

**Code Quality:**
- [ ] All 6 UI test files migrated
- [ ] All inline helpers removed
- [ ] All element finding uses ElementFinders
- [ ] All navigation uses UITestHelpers
- [ ] All pump sequences use PumpSequences
- [ ] ~2,500 lines eliminated

**Testing:**
- [ ] All 332 tests passing (256 non-UI + 76 UI)
- [ ] No flaky tests
- [ ] Zero coverage reduction verified

**Verification Commands:**
```bash
# Non-UI tests
flutter test
# Expected: All 256 tests pass

# UI tests (all 6 files - requires chromedriver)
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_add_player_test.dart -d chrome
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_visual_validation_test.dart -d chrome
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_results_screen_test.dart -d chrome
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_gameplay_test.dart -d chrome
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_menu_and_mechanics_test.dart -d chrome
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/carnival_derby_ui_test.dart -d chrome

# Expected: All 76 UI tests pass (6+4+6+13+23+24)
```

**Expected Metrics:**
- Files migrated: 6
- Lines eliminated: ~2,500
- Total tests: 332 (256 non-UI + 76 UI)
- Test pass rate: 100%
- Coverage reduction: 0%

**Time Investment:** 16-22 hours (actual logged by Agent 3)

---

### Phase 3 Handoff Document

**Agent 3 Creates:**

```markdown
# Handoff: Phase 3 Complete - Test Migration

**Completed By:** Agent 3 (Test Migration Specialist)
**Date:** [Date]
**Duration:** [Actual hours]

## Deliverables:
- [x] All 6 UI test files migrated to use shared components
- [x] target_tag_add_player_test.dart (-150 lines)
- [x] target_tag_visual_validation_test.dart (-200 lines)
- [x] target_tag_results_screen_test.dart (-150 lines)
- [x] target_tag_gameplay_test.dart (-600 lines)
- [x] target_tag_menu_and_mechanics_test.dart (-800 lines)
- [x] carnival_derby_ui_test.dart (-600 lines)
- [x] Total: ~2,500 lines eliminated

## Verification:
- [x] All non-UI tests pass: 256/256 tests pass
- [x] All UI tests pass: 76/76 tests pass (6+4+6+13+23+24)
- [x] Total: 332/332 tests pass (100% pass rate)
- [x] Zero coverage reduction verified
- [x] All inline helpers removed
- [x] All element finding uses keys

## Coverage Verification:
Each file was verified by Agent 4 to ensure:
- All original test scenarios preserved
- All original assertions preserved
- All edge cases still tested
- No reduction in test coverage

## Known Issues:
- None

## Notes for Phase 4 (Cleanup & Documentation):
- All test migrations complete
- All tests passing
- Ready for obsolete code cleanup
- Ready for documentation updates

**Sign-off:** Agent 3 - [Date]
```

**Agent 4 QA Review:**

```markdown
# QA Review: Phase 3 - Test Migration

**Reviewed By:** Agent 4 (QA Validator)
**Date:** [Date]

## Verification Checklist:
- [x] All 6 files migrated
- [x] Tests pass: 332/332 (100%)
- [x] Code reduction verified: ~2,500 lines eliminated
- [x] No inline helpers remaining
- [x] All element finding uses keys
- [x] Zero coverage reduction

**Coverage Verification (File-by-File):**
- target_tag_add_player_test.dart: ✓ All 6 scenarios preserved
- target_tag_visual_validation_test.dart: ✓ All 4 scenarios preserved
- target_tag_results_screen_test.dart: ✓ All 6 scenarios preserved
- target_tag_gameplay_test.dart: ✓ All 13 scenarios preserved
- target_tag_menu_and_mechanics_test.dart: ✓ All 23 scenarios preserved
- carnival_derby_ui_test.dart: ✓ All 24 scenarios preserved

**Issues Found:** 0

**Status:** ☑ APPROVED

**Sign-off:** Agent 4 (QA Validator) - [Date]
```

**Agent 5 Acknowledges:**

```markdown
# Handoff Received: Phase 3 Complete

**Received By:** Agent 5 (Documentation Specialist)
**Date:** [Date]

## Confirmation:
- [x] Reviewed handoff document
- [x] Reviewed QA approval
- [x] All test migrations complete
- [x] Ready to begin Phase 4 (documentation)

**Questions:**
- None

**Next Steps:**
- Phase 4A: Remove obsolete code
- Phase 4B: Update documentation (CLAUDE.md, README.md)
- Phase 4C: Create TEST_MODERNIZATION_SUMMARY.md
- Phase 4D: Final validation

**Sign-off:** Agent 5 (Documentation Specialist) - [Date]
```

---

### CHECKPOINT 3: Phase 3 Complete

**THIS IS A CRITICAL QUALITY GATE - DO NOT PROCEED UNTIL ALL CRITERIA MET**

✅ **Migration Complete:**
- All 6 UI test files migrated
- All inline helpers removed
- ~2,500 lines eliminated

✅ **Quality Verified:**
- All 332 tests passing (100%)
- Zero coverage reduction
- All element finding uses keys

✅ **Documentation Complete:**
- Handoff documents filed
- Coverage verification complete

✅ **Sign-Offs Complete:**
- Agent 3 signs off (Phase 3 complete)
- Agent 4 approves (QA passed, coverage verified)
- Agent 5 acknowledges (ready for Phase 4)

**IF ANY CRITERIA FAILS:**
1. Agent 4 documents failure
2. Agent 3 addresses issues
3. Re-validate
4. Do NOT proceed to Phase 4 until passed

**Ready for Phase 4:** ✅ YES / ☐ NO

---

# PHASE 4: Cleanup & Documentation

## Overview

**Prerequisites:**
- Phase 3 complete (all test files migrated)
- All 332 tests passing
- Checkpoint 3 passed

**Goal:** Finalize the modernization with cleanup and documentation.

**Duration:** 4.5-6.5 hours
**Timeline:** 1 week part-time
**Agent:** Agent 5 (Documentation Specialist), Agent 3 (cleanup)
**Critical Success Factor:** All documentation accurate and complete

---

## Phase 4A: Remove Obsolete Code

**Goal:** Clean up any remaining obsolete code.

**Duration:** 1 hour
**Agent:** Agent 3 (Test Migration Specialist)

### Verification Commands

**Search for obsolete patterns:**
```bash
cd dart_games

# Search for inline helper function definitions (should be 0)
grep -n "Future<void> navigate" integration_test/*.dart
grep -n "Future<void> addPlayer" integration_test/*.dart
grep -n "Future<void> throwDart" integration_test/*.dart
grep -n "Future<void> clickDarts" integration_test/*.dart

# Expected: No matches

# Search for commented-out code
grep -n "// BEFORE" integration_test/*.dart
grep -n "// OLD:" integration_test/*.dart

# Expected: No matches (or only in documentation comments)

# Search for text-based finding (should be minimal, only for display text verification)
grep -n "find.text" integration_test/*.dart | wc -l

# Expected: Very low count (only for assertions like expect(find.text('WINNER!'), findsOneWidget))

# Search for index-based access (should be 0)
grep -n ".at(" integration_test/*.dart

# Expected: No matches
```

**Manual Review:**
- Open each integration test file
- Scan for commented-out code blocks
- Remove any TODO comments left from migration
- Remove any debug print statements

**Validation:**
```bash
flutter test
# Expected: All 256 non-UI tests pass

flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_add_player_test.dart -d chrome
# Expected: Still passes (no regressions from cleanup)
```

**Agent 4 Review:** Verify no obsolete code remains

---

### Phase 4A Validation Checklist

**Before proceeding to Phase 4B:**

- [ ] No inline helper functions remain
- [ ] No commented-out old code
- [ ] No TODO comments from migration
- [ ] No debug print statements
- [ ] Minimal text-based finding (only for display text assertions)
- [ ] Zero index-based accesses
- [ ] All tests still passing
- [ ] Agent 4 approval

**Expected State:**
- Codebase clean
- All obsolete code removed
- All tests passing

**Time Check:** Should take 1 hour.

---

## Phase 4B: Update Documentation

**Goal:** Update all project documentation to reflect test modernization.

**Duration:** 2-3 hours
**Agent:** Agent 5 (Documentation Specialist)

### Step 4B.1: Update CLAUDE.md

**File:** `CLAUDE.md`

**Location:** Add new section after "Widget Keys for Testing" section (added in Phase 1A.3)

**Content to Add:**

```markdown
## Shared Test Components

**ALL tests MUST use shared test components to maintain consistency and reduce duplication.**

The test suite uses shared components located in `test/shared/`:

### Non-UI Test Components

**SectorParser** (`test/shared/sector_parser.dart`)
- Universal dart sector parsing
- Handles: S20, D20, T20, Bull, 25, Miss
- Returns unified format: `{'number': int, 'multiplier': String}`

**PlayerTestUtils** (`test/shared/player_test_utils.dart`)
- Player creation utilities
- Stats verification helpers
- Test data management

### UI Test Components

**ElementFinders** (`test/shared/element_finders.dart`)
- ALL element finding using widget keys
- No text/type/index-based finding
- Game-specific finders for both Target Tag and Carnival Derby

**UITestHelpers** (`test/shared/ui_test_helpers.dart`)
- High-level UI interactions
- Navigation, player management, dart throwing
- Uses GameUIConfig for game-specific operations

**PumpSequences** (`test/shared/pump_sequences.dart`)
- Standard animation handling patterns
- Replaces manual pump() sequences
- Handles continuous animations properly

**ProviderHelpers** (`test/shared/provider_helpers.dart`)
- Clean provider state access
- Game-specific provider methods

**SettingsHelpers** (`test/shared/settings_helpers.dart`)
- Settings control interactions
- Slider manipulation, switch toggling

**EditScoreHelpers** (`test/shared/edit_score_helpers.dart`)
- Edit score dialog operations
- Both Carnival Derby and Target Tag support

**ResultsHelpers** (`test/shared/results_helpers.dart`)
- Results screen navigation
- Play Again, Change Settings, Select Different Game

### Usage Example

```dart
import '../test/shared/ui_test_helpers.dart';
import '../test/shared/element_finders.dart';
import '../test/shared/pump_sequences.dart';

testWidgets('My test', (tester) async {
  const config = GameUIConfig.targetTag();

  // Navigate to game
  await UITestHelpers.navigateToGameMenu(tester, config);

  // Add players
  await UITestHelpers.addPlayer(tester, 'Alice', config);
  await UITestHelpers.addPlayer(tester, 'Bob', config);

  // Start game
  await UITestHelpers.startGame(tester, config);

  // Throw darts
  await UITestHelpers.throwDart(tester, config, 20, multiplier: 'double');
  await UITestHelpers.throwBullseye(tester, config);

  // Click darts removed
  await UITestHelpers.clickDartsRemoved(tester, config);

  // Verify using ElementFinders
  final startButton = ElementFinders.getTargetTagStartButton();
  expect(startButton, findsOneWidget);
}
```

### Benefits of Shared Components

- ✅ **Eliminated ~4,147 lines of duplicate code**
- ✅ **100% test reliability** (all element finding uses widget keys)
- ✅ **Single source of truth** for test operations
- ✅ **Easy to maintain** when UI changes
- ✅ **Easy to add new tests** (use existing helpers)
- ✅ **Easy to add new games** (follow established patterns)

### Adding New Games - Testing Requirements

When adding a new game, your tests MUST:

1. **Use shared test components**
   - Import from `test/shared/`
   - Create GameUIConfig for your game
   - Use UITestHelpers for all interactions

2. **Use widget keys for all element finding**
   - Add keys to `lib/constants/test_keys.dart`
   - Use ElementFinders methods
   - No text/type/index-based finding

3. **Follow established patterns**
   - See existing test files for examples
   - Use same structure and organization
   - Maintain consistency

**Reference Implementations:**
- Target Tag: `integration_test/target_tag_*.dart` (52 tests)
- Carnival Derby: `integration_test/carnival_derby_ui_test.dart` (24 tests)
```

**Also update test counts in CLAUDE.md:**

Find and update these sections:
- Line ~45: Update "Test suite (226 tests)" to "Test suite (256 non-UI tests + 76 UI tests = 332 total)"
- Line ~930: Update UI test count references
- Complete Test Suite section: Update breakdown with new numbers

**Validation:**
```bash
cat CLAUDE.md | grep -A 10 "Shared Test Components"
# Expected: Section present and readable
```

---

### Step 4B.2: Update README.md

**File:** `README.md`

**Location:** Update "Testing" section

**Find existing section and update:**

```markdown
## Testing

The project includes comprehensive test coverage:

- **Non-UI Tests:** 256 tests covering models, providers, services, game logic, and shared test components
- **UI Automation Tests:** 76 tests validating end-to-end user interactions

**Total:** 332 tests

All tests must pass before commits and deployments.

### Test Organization

**Non-UI Tests** (`test/` directory):
- Model Tests: 36 tests (GameHistoryEntry, Player, VictoryMusicFile)
- Provider Tests: 37 tests (PlayerProvider, game providers)
- Service Tests: 42 tests (AnnouncerSettings, VictoryMusic)
- Integration Tests: 83 tests (game logic with announcements)
  - Carnival Derby: 33 tests (game logic + user management)
  - Target Tag: 42 tests (game logic + user management)
- Widget Tests: 23 tests (InteractiveDartboard)
- **Shared Test Components:** 30 tests (SectorParser, PlayerTestUtils)

**UI Automation Tests** (`integration_test/` directory):
- Target Tag: 52 tests (menu, gameplay, visual validation, results, add player)
- Carnival Derby: 24 tests (complete game flow)

**Total:** 256 + 76 = 332 tests

### Test Modernization

The test suite has been modernized for reliability and maintainability:

**Key Improvements:**
- ✅ **Widget keys:** All interactive UI elements have unique keys for stable identification
- ✅ **Shared components:** 10 reusable test helpers eliminate ~4,147 lines of duplication
- ✅ **100% test reliability:** Tests don't break when UI text changes or elements are reordered
- ✅ **Key-based finding:** All element finding uses keys (no text/type/index-based finding)

**Benefits:**
- Easier to maintain tests when UI changes
- Easier to write new tests (use shared helpers)
- Easier to add new games (follow established patterns)
- Single source of truth for test operations

**See:** `test/shared/` for all shared test components

### Running Tests

**Non-UI tests:**
```bash
flutter test
# Expected: All 256 tests pass
```

**UI automation tests:**
```bash
# Terminal 1: Start chromedriver
cd dart_games/chromedriver/chromedriver-win64
./chromedriver.exe --port=4444

# Terminal 2: Run UI tests
cd dart_games
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_add_player_test.dart -d chrome
# (Repeat for all 6 UI test files)
# Expected: All 76 tests pass
```

**See:** `CLAUDE.md` for complete testing guidelines and requirements
```

**Validation:**
```bash
cat README.md | grep -A 20 "## Testing"
# Expected: Section present and accurate
```

---

### Step 4B.3: Create TEST_MODERNIZATION_SUMMARY.md

**Create file:** `TEST_MODERNIZATION_SUMMARY.md`

**Content:**

```markdown
# Test Modernization - Project Summary

**Date Completed:** [Date]
**Duration:** [Actual hours]
**Team:** 5 specialized agents

---

## Overview

This document summarizes the test modernization initiative that improved the Dart Games test suite's reliability, maintainability, and efficiency.

## The Problem

The test suite (302 tests total) suffered from:
- **~4,147 lines of duplicated code** across 6 UI test files
- **~28% test reliability** due to fragile text/type/index-based element finding
- **341 text-based finds** that broke when UI text changed
- **85 index-based accesses** that broke when UI was reordered
- **0 widget keys** for stable element identification

## The Solution

Implemented two complementary improvements:

### 1. Widget Keys (Phase 1)
- Added 300+ widget keys to all interactive UI elements
- Centralized in `lib/constants/test_keys.dart`
- Organized by screen/component
- Improves test reliability from ~28% to ~100%

### 2. Shared Test Components (Phase 2)
- Created 10 reusable test helper components
- Eliminates ~4,147 lines of duplicate code
- Single source of truth for common test operations
- Located in `test/shared/`

## Implementation Phases

### Phase 1: Widget Keys Foundation (26-34 hours)
- Created widget key naming guide
- Added 300+ keys across all screens
- Updated CLAUDE.md with requirements
- **Outcome:** All 226 tests still passing, 0 regressions

### Phase 2: Shared Test Components (11-17 hours)
- Created 10 shared component files
- Added 30 new component tests
- All components use widget keys
- **Outcome:** All 256 tests passing (226 + 30 new)

### Phase 3: Test Migration (16-22 hours)
- Migrated 6 UI test files
- Eliminated ~2,500 lines of duplicate code
- Zero coverage reduction
- **Outcome:** All 332 tests passing (256 non-UI + 76 UI)

### Phase 4: Cleanup & Documentation (4.5-6.5 hours)
- Removed obsolete code
- Updated CLAUDE.md and README.md
- Created this summary
- **Outcome:** Complete documentation, clean codebase

**Total Effort:** 58-80 agent-hours across 5 specialized agents

---

## Quantitative Results

### Code Reduction
- Total lines eliminated: ~4,147
- UI test files: -2,500 lines (-35%)
- Helper duplication: -1,260 lines (-100%)
- Element finding: -400 lines (-100%)
- Pump sequences: -250 lines (-100%)
- Edit score helpers: -780 lines (-100%)
- Results helpers: -420 lines (-100%)
- Player management: -540 lines (-100%)

### Test Reliability
- **Before:** ~28% reliable (broke with UI changes)
- **After:** ~100% reliable (immune to UI text/order changes)
- Text-based finds: 341 → 0 (-100%)
- Index-based finds: 85 → 0 (-100%)
- Key-based finds: 0 → 300+ (+100%)

### Test Coverage
- **Before:** 226 non-UI + 76 UI = 302 tests
- **After:** 256 non-UI + 76 UI = 332 tests
- **Added:** 30 new component tests
- **Removed:** 0 tests (zero coverage reduction)

### Maintenance Time Impact
- **Before:** ~60 hours/year
- **After:** ~10 hours/year
- **Savings:** 50 hours/year (83% reduction)

---

## Qualitative Results

### Benefits Achieved

**Test Reliability:**
- ✅ Tests don't break when UI text changes
- ✅ Tests don't break when UI is reordered
- ✅ Tests don't break when widget types change
- ✅ No flaky tests
- ✅ Stable across refactoring

**Maintainability:**
- ✅ Single source of truth for test operations
- ✅ Easy to update when UI changes
- ✅ Easy to fix bugs (one place to update)
- ✅ Clear, self-documenting code

**Developer Experience:**
- ✅ New tests written 50% faster
- ✅ New games follow established patterns
- ✅ Onboarding easier (use shared components)
- ✅ Test failures easier to debug

---

## Components Created

### Widget Keys
**File:** `lib/constants/test_keys.dart` (300+ keys)

**Key Classes:**
- HomeKeys (3 keys)
- CarnivalDerbyMenuKeys (9 keys)
- CarnivalDerbyGameKeys (66 keys - includes all dart buttons)
- CarnivalDerbyResultsKeys (3 keys)
- TargetTagMenuKeys (9 keys)
- TargetTagGameKeys (66 keys)
- TargetTagResultsKeys (3 keys)
- EditScoreDialogKeys (5 keys)
- AddPlayerDialogKeys (5 keys)
- TeamAssignmentDialogKeys (4 keys)

### Shared Test Components
**Location:** `test/shared/` (10 files)

1. **sector_parser.dart** - Universal dart notation parsing (20 tests)
2. **pump_sequences.dart** - Standard animation handling
3. **element_finders.dart** - Key-based element finding
4. **provider_helpers.dart** - Clean provider access
5. **settings_helpers.dart** - Settings control interactions
6. **ui_test_helpers.dart** - High-level UI helpers
7. **edit_score_helpers.dart** - Edit score dialog operations
8. **results_helpers.dart** - Results screen navigation
9. **player_test_utils.dart** - Player utilities (10 tests)
10. **GameUIConfig** - Game-specific configuration

---

## Before & After Examples

### Before: Inline Helper (80 lines)
```dart
// Duplicated in 5 files
Future<void> navigateToTargetTagMenu(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();
  await tester.pumpAndSettle(const Duration(seconds: 3));

  final targetTagCard = find.text('Target Tag'); // Fragile!
  expect(targetTagCard, findsOneWidget);
  await tester.tap(targetTagCard);

  // Manual pump sequence
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
  await tester.pump(const Duration(seconds: 5));
  await tester.pump();
  await tester.pump();
  await tester.pump();
}
```

### After: Shared Component (1 line)
```dart
await UITestHelpers.navigateToGameMenu(tester, GameUIConfig.targetTag());
```

### Before: Text-Based Finding (Fragile)
```dart
final startButton = find.text('START GAME');
await tester.tap(startButton);
```

### After: Key-Based Finding (Robust)
```dart
final startButton = ElementFinders.getTargetTagStartButton();
await tester.tap(startButton);
```

---

## ROI Analysis

### Investment
- Upfront: 58-80 agent-hours
- One-time cost: ~70 hours average

### Returns
- Annual savings: 50 hours/year
- Payback period: 1.4 years (17 months)
- 5-year ROI: 257% (2.57x return)

### Non-Quantifiable Benefits
- Increased confidence in test suite
- Faster development velocity
- Better onboarding experience
- Higher code quality

---

## Lessons Learned

### What Worked Well
1. **Phased approach** - Clear phases with validation gates
2. **Quality gates** - Agent 4 review prevented regressions
3. **One file at a time** - Prevented overwhelming scope
4. **Agent specialization** - Each agent focused on their expertise
5. **No coverage reduction rule** - Maintained test quality

### Challenges Overcome
1. **Large scope** - Managed via phases and checkpoints
2. **Continuous animations** - Solved with PumpSequences
3. **Element finding** - Solved with widget keys
4. **Code duplication** - Eliminated with shared components

### Future Improvements
1. **Widget keys from day 1** - Add keys when creating new widgets
2. **Shared components first** - Create helpers before writing tests
3. **Test templates** - Provide templates for new game tests

---

## Team & Effort Distribution

| Agent | Role | Effort | Key Deliverables |
|-------|------|--------|------------------|
| 1 | Widget Keys Architect | 26-34h | 300+ widget keys |
| 2 | Test Component Engineer | 11-17h | 10 shared components |
| 3 | Test Migration Specialist | 16-22h | 6 migrated test files |
| 4 | Quality Assurance Validator | 12-15h | Quality verification |
| 5 | Documentation Specialist | 4.5-6.5h | Complete documentation |

**Total:** 69.5-94.5 agent-hours

---

## Files Modified

**App Code:**
- `lib/constants/test_keys.dart` (NEW - 300+ keys)
- `lib/screens/home_screen.dart` (added keys)
- `lib/screens/games/carnival_horse_race/horse_race_menu_screen.dart` (added keys)
- `lib/screens/games/carnival_horse_race/horse_race_game_screen.dart` (added keys)
- `lib/screens/games/carnival_horse_race/horse_race_results_screen.dart` (added keys)
- `lib/screens/games/target_tag/target_tag_menu_screen.dart` (added keys)
- `lib/screens/games/target_tag/target_tag_game_screen.dart` (added keys)
- `lib/screens/games/target_tag/target_tag_results_screen.dart` (added keys)
- `lib/widgets/add_player/add_player_dialog.dart` (added keys)
- Various dialog files (added keys)

**Test Code:**
- `test/shared/` (NEW - 10 files, 30 tests)
- `integration_test/target_tag_add_player_test.dart` (migrated)
- `integration_test/target_tag_visual_validation_test.dart` (migrated)
- `integration_test/target_tag_results_screen_test.dart` (migrated)
- `integration_test/target_tag_gameplay_test.dart` (migrated)
- `integration_test/target_tag_menu_and_mechanics_test.dart` (migrated)
- `integration_test/carnival_derby_ui_test.dart` (migrated)

**Documentation:**
- `docs/WIDGET_KEY_GUIDE.md` (NEW)
- `CLAUDE.md` (updated)
- `README.md` (updated)
- `TEST_MODERNIZATION_SUMMARY.md` (THIS FILE)

**Total:** ~25 files modified/created

---

## References

**Documentation:**
- Widget Key Guide: `docs/WIDGET_KEY_GUIDE.md`
- Development Guidelines: `CLAUDE.md`
- Project README: `README.md`

**Implementation Details:**
- Master Plan: `TEST_MODERNIZATION_MASTER_PLAN.md`
- Agent Team Plan: `AGENT_TEAM_IMPLEMENTATION_PLAN.md`
- Complete Plan: `TEST_MODERNIZATION_COMPLETE_PLAN.md`

**Code:**
- Widget Keys: `lib/constants/test_keys.dart`
- Shared Components: `test/shared/`
- Test Examples: `integration_test/`

---

## Acknowledgments

**Team:**
- Agent 1: Widget Keys Architect
- Agent 2: Test Component Engineer
- Agent 3: Test Migration Specialist
- Agent 4: Quality Assurance Validator
- Agent 5: Documentation Specialist

**Success Factors:**
- Clear phases and milestones
- Quality gates and checkpoints
- Zero coverage reduction rule
- Agent specialization and collaboration

---

**Project Status:** ✅ COMPLETE

**Final Metrics:**
- 332 tests passing (100% pass rate)
- ~4,147 lines eliminated
- 100% test reliability
- All documentation complete
- Ready for production

---

**END OF TEST MODERNIZATION SUMMARY**
```

**Validation:**
```bash
cat TEST_MODERNIZATION_SUMMARY.md | head -50
# Expected: Summary file complete and readable
```

---

### Phase 4B Validation Checklist

**Before proceeding to Phase 4C:**

- [ ] CLAUDE.md updated with shared components section
- [ ] CLAUDE.md test counts updated
- [ ] README.md testing section updated
- [ ] TEST_MODERNIZATION_SUMMARY.md created
- [ ] All code examples in docs compile
- [ ] Documentation cross-referenced correctly
- [ ] Agent 4 documentation review
- [ ] Agent 5 approval

**Expected State:**
- All documentation complete and accurate
- Ready for final validation

**Time Check:** Should take 2-3 hours.

---

## Phase 4C: Final Test Run

**Goal:** Run complete test suite one final time.

**Duration:** 30-60 minutes (execution time)
**Agent:** All agents

### Validation Commands

**Non-UI tests:**
```bash
cd dart_games
flutter test

# Expected output:
# 00:XX +256: All tests passed!
```

**UI automation tests (all 6 files):**
```bash
# Terminal 1: Start chromedriver
cd dart_games/chromedriver/chromedriver-win64
./chromedriver.exe --port=4444

# Terminal 2: Run each test file
cd dart_games

# 1. Target Tag - Add Player (6 tests, ~2 min)
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_add_player_test.dart -d chrome

# 2. Target Tag - Visual Validation (4 tests, ~2 min)
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_visual_validation_test.dart -d chrome

# 3. Target Tag - Results Screen (6 tests, ~5 min)
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_results_screen_test.dart -d chrome

# 4. Target Tag - Gameplay (13 tests, ~10 min)
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_gameplay_test.dart -d chrome

# 5. Target Tag - Menu & Mechanics (23 tests, ~12 min)
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_menu_and_mechanics_test.dart -d chrome

# 6. Carnival Derby (24 tests, ~12 min)
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/carnival_derby_ui_test.dart -d chrome

# Expected total: 76 tests pass (~43 minutes)
```

**Static analysis:**
```bash
flutter analyze

# Expected: No issues found!
```

---

### Phase 4C Validation Checklist

**All tests passing:**
- [ ] Non-UI tests: 256/256 pass
- [ ] UI tests file 1: 6/6 pass
- [ ] UI tests file 2: 4/4 pass
- [ ] UI tests file 3: 6/6 pass
- [ ] UI tests file 4: 13/13 pass
- [ ] UI tests file 5: 23/23 pass
- [ ] UI tests file 6: 24/24 pass
- [ ] **Total: 332/332 tests pass (100%)**
- [ ] flutter analyze: 0 errors

**Expected State:**
- Complete test suite validated
- 100% pass rate confirmed
- Ready for final sign-off

**Time Check:** Should take 30-60 minutes execution time.

---

## Phase 4D: Performance Verification

**Goal:** Verify test execution time and app performance unchanged.

**Duration:** 30 minutes
**Agent:** Agent 4 (QA Validator)

### Performance Metrics

**Test Execution Time:**
```bash
# Non-UI tests (timed)
time flutter test

# Expected: Similar to baseline (~2 minutes)
# Acceptable: No more than 10% increase
```

**UI Test Execution Time:**
- Measured during Phase 4C
- Expected: ~43 minutes total (6 files)
- Acceptable: Similar to baseline

**App Performance:**
- Launch time: Unchanged (keys don't affect runtime)
- Memory usage: Unchanged
- Bundle size: +<1KB (keys compile to integers)

**Validation:**
```bash
# Build app
flutter build web --release

# Check bundle size
ls -lh build/web/main.dart.js

# Expected: Similar size to before modernization
# Keys add negligible overhead
```

---

### Phase 4D Validation Checklist

- [ ] Non-UI test time: Similar to baseline
- [ ] UI test time: Similar to baseline
- [ ] App launch time: Unchanged
- [ ] Memory usage: Unchanged
- [ ] Bundle size: +<1KB

**Expected State:**
- No performance degradation
- Test execution time acceptable
- Ready for final completion

**Time Check:** Should take 30 minutes.

---

## Phase 4 Complete - Project Complete!

**Duration:** 1 hour for final sign-offs
**All Agents Participate**

### Final Validation Checklist

**ALL sub-phases complete:**
- [x] Phase 4A: Obsolete code removed
- [x] Phase 4B: Documentation updated
- [x] Phase 4C: Final test run (332/332 pass)
- [x] Phase 4D: Performance verified

**Code Quality:**
- [ ] ~4,147 lines eliminated (verified)
- [ ] All obsolete code removed
- [ ] 0 text-based finds for interactive elements
- [ ] 0 index-based accesses
- [ ] flutter analyze: 0 errors, 0 warnings

**Test Quality:**
- [ ] 332 tests passing (100% pass rate)
- [ ] No flaky tests
- [ ] All tests use shared components
- [ ] Test execution time acceptable

**Documentation:**
- [ ] WIDGET_KEY_GUIDE.md complete
- [ ] TEST_MODERNIZATION_SUMMARY.md complete
- [ ] CLAUDE.md updated accurately
- [ ] README.md updated
- [ ] All code examples compile

**Performance:**
- [ ] App launch time unchanged
- [ ] App memory usage unchanged
- [ ] Test execution time similar

---

### Project Completion Sign-Off Form

**Phase 1 Complete:**
- Signed by: Agent 1 (Widget Keys Architect) - [Date]
- All widgets keyed: ☑ Yes
- All tests passing: ☑ Yes

**Phase 2 Complete:**
- Signed by: Agent 2 (Test Component Engineer) - [Date]
- All components created: ☑ Yes
- All tests passing: ☑ Yes

**Phase 3 Complete:**
- Signed by: Agent 3 (Test Migration Specialist) - [Date]
- All tests migrated: ☑ Yes
- All tests passing: ☑ Yes

**Phase 4 Complete:**
- Signed by: Agent 5 (Documentation Specialist) - [Date]
- Documentation complete: ☑ Yes
- All tests passing: ☑ Yes

**Quality Assurance:**
- Signed by: Agent 4 (QA Validator) - [Date]
- All quality gates passed: ☑ Yes
- Zero coverage reduction: ☑ Yes
- All success criteria met: ☑ Yes

**PROJECT COMPLETE:**
- Signed by: User - [Date]
- Team trained: ☐ Yes
- Ready for production: ☐ Yes
- Approved: ☐ Yes

---

### CHECKPOINT 4: Project Complete

**THIS IS THE FINAL QUALITY GATE**

✅ **All Phases Complete:**
- Phase 1: Widget Keys ✓
- Phase 2: Shared Components ✓
- Phase 3: Test Migration ✓
- Phase 4: Cleanup & Documentation ✓

✅ **All Success Criteria Met:**
- ~4,147 lines eliminated ✓
- 332 tests passing (100%) ✓
- 100% test reliability ✓
- Complete documentation ✓
- No performance degradation ✓

✅ **All Agents Sign Off:**
- Agent 1 ✓
- Agent 2 ✓
- Agent 3 ✓
- Agent 4 ✓
- Agent 5 ✓

**Project Status:** ✅ COMPLETE

---


---

# PART 3: PROJECT MANAGEMENT

This section defines how a team of 5 specialized agents will coordinate to implement the test modernization initiative.

**Key Points:**
- Agents work in coordinated phases with clear handoffs
- Each agent has defined responsibilities and deliverables
- Quality gates ensure no regressions or coverage reduction
- All technical implementation details are in Part 2
- This section focuses on team coordination and workflow

**Timeline:** 5-7 weeks with parallelization
**Agent-Hours:** 66-90 hours total
**Critical Success Factor:** 100% test pass rate maintained throughout

## Team Structure

### Agent Team Composition

| Agent | Role | Primary Phases | Effort | Key Deliverables |
|-------|------|----------------|--------|------------------|
| 1 | Widget Keys Architect | Phase 1 | 26-34h | 300+ widget keys |
| 2 | Test Component Engineer | Phase 2 | 11-17h | 10 shared components |
| 3 | Test Migration Specialist | Phase 3 | 16-22h | 6 migrated test files |
| 4 | Quality Assurance Validator | All phases | 12-15h | Quality verification |
| 5 | Documentation Specialist | Phase 4 | 4.5-6.5h | Complete documentation |

**Total:** 69.5-94.5 agent-hours across 5 specialized roles

---

## Agent Roles & Responsibilities

### Agent 1: Widget Keys Architect

**Primary Responsibility:** Implement Phase 1 of TEST_MODERNIZATION_MASTER_PLAN.md (Widget Keys Foundation)

**Specific Tasks:**
- **Phase 1A:** Create key naming guide and `test_keys.dart` file
  - Reference: Master plan lines 377-515
  - Duration: 2-3 hours
  - Deliverable: Documentation + key constants file

- **Phase 1B:** Add keys to home & navigation screens
  - Reference: Master plan lines 517-536
  - Duration: 2-3 hours
  - Deliverable: Home screen fully keyed

- **Phase 1C:** Add keys to both game menu screens
  - Reference: Master plan lines 538-565
  - Duration: 6-8 hours
  - Deliverable: Menu screens fully keyed

- **Phase 1D:** Add keys to both game screens (60+ dart buttons each)
  - Reference: Master plan lines 567-593
  - Duration: 10-12 hours
  - Deliverable: Game screens fully keyed

- **Phase 1E:** Add keys to both results screens
  - Reference: Master plan lines 595-614
  - Duration: 2-3 hours
  - Deliverable: Results screens fully keyed

- **Phase 1F:** Add keys to all dialogs
  - Reference: Master plan lines 616-634
  - Duration: 4-5 hours
  - Deliverable: Dialogs fully keyed

**Success Criteria:**
- All 300+ widgets keyed
- All 226 non-UI tests still passing after each sub-phase
- `flutter analyze` passes with 0 errors
- No runtime regressions

**Handoff to:** Test Component Engineer (can start Phase 2 after Phase 1C complete)

---

### Agent 2: Test Component Engineer

**Primary Responsibility:** Implement Phase 2 of TEST_MODERNIZATION_MASTER_PLAN.md (Shared Test Components)

**Specific Tasks:**
- **Phase 2A:** Create SectorParser and PumpSequences
  - Reference: Master plan lines 663-681
  - Duration: 2-3 hours
  - Deliverable: 2 components with 20 tests

- **Phase 2B:** Create ElementFinders (using widget keys from Phase 1)
  - Reference: Master plan lines 683-699
  - Duration: 2-3 hours
  - Deliverable: Element finding helpers

- **Phase 2C:** Create Provider and Settings helpers
  - Reference: Master plan lines 701-718
  - Duration: 2-3 hours
  - Deliverable: State access helpers

- **Phase 2D:** Create UI interaction helpers
  - Reference: Master plan lines 720-736
  - Duration: 2-3 hours
  - Deliverable: High-level UI helpers

- **Phase 2E:** Create EditScore and Results helpers
  - Reference: Master plan lines 738-755
  - Duration: 2-3 hours
  - Deliverable: Specialized dialog helpers

- **Phase 2F:** Create PlayerTestUtils
  - Reference: Master plan lines 757-775
  - Duration: 1-2 hours
  - Deliverable: Player utilities with 10 tests

**Success Criteria:**
- All 10 shared components created
- 30 new component tests passing
- All 256 tests passing (226 original + 30 new)
- All components use widget keys (no text/type/index finding)
- Component API documentation complete

**Prerequisites:** Phase 1C complete (enough keys for ElementFinders to work)

**Handoff to:** Test Migration Specialist (after Phase 1 fully complete)

---

### Agent 3: Test Migration Specialist

**Primary Responsibility:** Implement Phase 3 of TEST_MODERNIZATION_MASTER_PLAN.md (Test Migration)

**Specific Tasks:**
- **Phase 3A:** Develop migration strategy and patterns
  - Reference: Master plan lines 807-828
  - Duration: 2-3 hours
  - Deliverable: Migration guide with before/after examples

- **Phase 3B:** Migrate target_tag_add_player_test.dart (6 tests)
  - Reference: Master plan lines 830-844
  - Duration: 1-2 hours
  - Expected reduction: ~150 lines
  - Validation: All 6 tests pass

- **Phase 3C:** Migrate target_tag_visual_validation_test.dart (4 tests)
  - Reference: Master plan lines 846-853
  - Duration: 1-2 hours
  - Expected reduction: ~200 lines
  - Validation: All 4 tests pass

- **Phase 3D:** Migrate target_tag_results_screen_test.dart (6 tests)
  - Reference: Master plan lines 855-862
  - Duration: 2-3 hours
  - Expected reduction: ~150 lines
  - Validation: All 6 tests pass

- **Phase 3E:** Migrate target_tag_gameplay_test.dart (13 tests)
  - Reference: Master plan lines 864-871
  - Duration: 3-4 hours
  - Expected reduction: ~600 lines
  - Validation: All 13 tests pass

- **Phase 3F:** Migrate target_tag_menu_and_mechanics_test.dart (23 tests)
  - Reference: Master plan lines 873-882
  - Duration: 4-5 hours
  - Expected reduction: ~800 lines
  - Validation: All 23 tests pass
  - **Note:** Largest/most complex file

- **Phase 3G:** Migrate carnival_derby_ui_test.dart (24 tests)
  - Reference: Master plan lines 884-891
  - Duration: 4-5 hours
  - Expected reduction: ~600 lines
  - Validation: All 24 tests pass

**Success Criteria:**
- All 6 UI test files migrated
- All 76 UI tests passing
- Total 332 tests passing (256 non-UI + 76 UI)
- ~2,500 lines eliminated
- Zero coverage reduction (all original test scenarios preserved)
- All inline helper functions removed

**Critical Requirement:** Migrate ONE file at a time, validate tests pass before proceeding to next file

**Prerequisites:** Phase 1 AND Phase 2 both complete

**Handoff to:** Documentation Specialist (for Phase 4)

---

### Agent 4: Quality Assurance Validator

**Primary Responsibility:** Continuous quality validation across all phases

**Ongoing Tasks Throughout Project:**

**Phase 1 Reviews (after each sub-phase):**
- Verify widget key naming follows convention
- Check for duplicate keys
- Verify tests still pass (226/226)
- Spot-check app functionality
- Sign off before next sub-phase begins

**Phase 2 Reviews (after each component):**
- Review component code quality
- Verify components use widget keys (not text/type/index)
- Check component tests pass
- Verify integration with existing tests
- Sign off before next component

**Phase 3 Reviews (after each file migration):**
- Verify all tests in migrated file pass
- Check for coverage reduction (compare scenarios before/after)
- Verify all inline helpers removed
- Validate code reduction metrics
- Sign off before next migration

**Phase 4 Reviews:**
- Verify all obsolete code removed
- Review documentation accuracy
- Cross-reference code examples in docs
- Verify final test counts
- Final project sign-off

**Specific Deliverables:**
- Quality gate reports (1 per sub-phase)
- Coverage verification reports (Phase 3)
- Code review findings log
- Final quality sign-off document

**Quality Metrics to Track:**
- Test pass rate (must stay at 100%)
- Test count progression (226 → 256 → 332)
- Code reduction vs. target (~4,147 lines)
- Widget keys added vs. target (300+)
- No hardcoded text/type/index finds in new code

**Escalation Protocol:**
If quality gate fails:
1. Document issue with evidence
2. Block progression to next sub-phase
3. Work with responsible agent to resolve
4. Re-validate after fix
5. Escalate to user if unresolvable

**Effort Distribution:**
- Phase 1: 5-7 hours (reviews after each 1A-1F)
- Phase 2: 3-4 hours (reviews after each 2A-2F)
- Phase 3: 3-4 hours (reviews after each 3B-3G)
- Phase 4: 1-2 hours (final validation)

---

### Agent 5: Documentation Specialist

**Primary Responsibility:** Implement Phase 4B and create final documentation

**Specific Tasks:**

**Phase 4B: Update Documentation**
- Reference: Master plan lines 933-940
- Duration: 1-2 hours

1. **Update CLAUDE.md:**
   - Add "Widget Key Requirements" section
   - Add "Shared Test Components" section
   - Update test counts (226 → 256 → 332)
   - Update "Testing Requirements" section
   - Verify all code examples compile

2. **Update README.md:**
   - Add "Test Infrastructure" section
   - Update test count references
   - Add test reliability improvements note

3. **Create TEST_MODERNIZATION_SUMMARY.md:**
   - Comprehensive summary of work completed
   - Before/after metrics
   - Benefits achieved
   - Lessons learned
   - Migration patterns for future reference

**Supporting Tasks (Throughout Project):**
- Review widget key naming guide (Phase 1A)
- Review component API documentation (Phase 2)
- Collect metrics for final summary (Phase 3)

**Success Criteria:**
- All documentation accurate and complete
- All code examples compile and run
- Documentation cross-referenced correctly
- Team can use docs to maintain system

**Prerequisites:** Phase 3 complete (all migrations done)

**Effort:** 4.5-6.5 hours (concentrated in Phase 4)

---

## Implementation Workflow

### Overall Timeline (5-7 Weeks)

```
┌─────────────────────────────────────────────────────────────────────┐
│ WEEK 1: Phase 1A-1C (Widget Keys - Foundation)                      │
│ Agent 1: Key naming guide + Home keys + Menu keys (10-14 hours)    │
│ Agent 4: QA reviews (1-2 hours)                                     │
│ Agent 5: Review naming guide (30 min)                               │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ WEEK 2: Phase 1D-1F + Phase 2A-2C (Parallel Work)                  │
│ Agent 1: Game screen keys + Results keys + Dialog keys (16-20h)    │
│ Agent 2: SectorParser + ElementFinders + Helpers (6-9h) PARALLEL   │
│ Agent 4: QA reviews for both (2-3 hours)                            │
└─────────────────────────────────────────────────────────────────────┘
              ↓ Checkpoint 1: Phase 1 Complete ↓

┌─────────────────────────────────────────────────────────────────────┐
│ WEEK 3: Phase 2D-2F (Shared Components Complete)                    │
│ Agent 2: UI helpers + EditScore + PlayerUtils (5-8 hours)          │
│ Agent 4: QA reviews (1-2 hours)                                     │
└─────────────────────────────────────────────────────────────────────┘
              ↓ Checkpoint 2: Phase 2 Complete ↓

┌─────────────────────────────────────────────────────────────────────┐
│ WEEK 4: Phase 3A-3D (First 4 Test File Migrations)                 │
│ Agent 3: Strategy + 3 smaller files + 1 medium (8-11 hours)        │
│ Agent 4: QA reviews (1-2 hours)                                     │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ WEEK 5: Phase 3E-3G (Last 2 Large Test File Migrations)            │
│ Agent 3: 2 largest files (8-10 hours)                               │
│ Agent 4: QA reviews (1-2 hours)                                     │
└─────────────────────────────────────────────────────────────────────┘
              ↓ Checkpoint 3: Phase 3 Complete ↓

┌─────────────────────────────────────────────────────────────────────┐
│ WEEK 6-7: Phase 4 (Cleanup & Documentation)                         │
│ Agent 3: Remove obsolete code (1 hour)                              │
│ Agent 5: Update all documentation (2-3 hours)                       │
│ Agent 4: Final validation (1-2 hours)                               │
│ ALL: Final test runs and sign-offs (1-2 hours)                      │
└─────────────────────────────────────────────────────────────────────┘
              ↓ Checkpoint 4: Project Complete ↓
```

### Parallel Work Opportunities

**Week 2 Parallelization:**
- Agent 1 works on Phase 1D-1F (game/results/dialog keys)
- Agent 2 works on Phase 2A-2C (components) IN PARALLEL
- This saves ~6-9 hours of calendar time

**Prerequisite:** Phase 1C must complete before Phase 2B (ElementFinders need menu keys to reference)

---

### Critical Path

```
Phase 1A → 1B → 1C → [1D-1F || 2A-2C] → 2D-2F → 3A-3G → 4A-4D

Key:
→ Sequential (must wait)
|| Parallel (can run simultaneously)
```

**Cannot Start Until:**
- Phase 2B (ElementFinders): Needs Phase 1C keys
- Phase 3 (Migration): Needs Phase 1 AND Phase 2 complete
- Phase 4 (Docs): Needs Phase 3 complete

---

## Communication Protocol

### Daily Status Updates

Each agent posts to **AGENT_DAILY_STATUS.md**:

```markdown
## [Date] - [Agent Name]

### Completed Today:
- Phase X.Y: [Specific task]
- Lines of code: +X / -Y
- Tests: X passing

### In Progress:
- Phase X.Z: [Specific task] (50% complete)

### Blockers:
- [None] OR [Specific blocker with details]

### Next Up:
- Phase X.Z+1: [Next task]

### Questions/Issues:
- [None] OR [Specific questions]
```

**Update Frequency:** Once per work session (minimum daily if working)

**Review Protocol:** All agents review daily status before starting work

---

### Phase Handoff Protocol

When completing a phase/sub-phase:

**1. Completing Agent Creates Handoff Document:**

```markdown
# Handoff: Phase X Complete

**Completed By:** [Agent Name]
**Date:** [Date]
**Duration:** [Actual hours]

## Deliverables:
- [ ] File 1: [path/to/file.dart]
- [ ] File 2: [path/to/file.dart]
- [ ] Tests passing: X/X

## Verification:
- [ ] All tests pass: `flutter test` → X tests pass
- [ ] No compilation errors: `flutter analyze` → 0 errors
- [ ] App runs without regression

## Known Issues:
- [None] OR [List any concerns for next agent]

## Notes for Next Agent:
- [Any helpful context or gotchas]

**Sign-off:** [Agent Name] - [Date]
```

**2. QA Validator Reviews and Approves:**

```markdown
# QA Review: Phase X

**Reviewed By:** QA Validator
**Date:** [Date]

## Verification Checklist:
- [ ] All deliverables present
- [ ] Tests pass: [X/X]
- [ ] Code quality acceptable
- [ ] Follows conventions
- [ ] No regressions

**Issues Found:** [Count]
- [List any issues]

**Status:** ☐ APPROVED ☐ NEEDS REVISION

**Sign-off:** QA Validator - [Date]
```

**3. Next Agent Acknowledges:**

```markdown
# Handoff Received: Phase X

**Received By:** [Agent Name]
**Date:** [Date]

## Confirmation:
- [ ] Reviewed handoff document
- [ ] Reviewed QA approval
- [ ] Understand deliverables
- [ ] No blocking questions

**Questions:**
- [None] OR [List questions for previous agent]

**Sign-off:** [Agent Name] - [Date]
```

**No work begins on next phase until:**
1. Handoff document complete
2. QA approval granted
3. Next agent acknowledges

---

### Issue Escalation Protocol

**Level 1: Agent-to-Agent (Informal)**
- Quick questions or clarifications
- Post in AGENT_DAILY_STATUS.md
- Response expected within 1 work day

**Level 2: Agent-to-QA (Formal)**
- Quality issues or test failures
- Post detailed issue report
- QA investigates and provides guidance
- Resolution tracked

**Level 3: QA-to-User (Critical)**
- Blocking issues that prevent progress
- Quality gates that fail repeatedly
- Scope changes or clarifications needed
- QA Validator creates detailed report for user
- User provides decision/guidance

**Issue Report Template:**

```markdown
# Issue Report: [Title]

**Reported By:** [Agent Name]
**Date:** [Date]
**Phase:** [Phase X.Y]
**Severity:** ☐ Low ☐ Medium ☐ High ☐ Critical

## Problem Description:
[Clear description of the issue]

## Impact:
[How this affects timeline/quality]

## Steps to Reproduce:
1. [Step 1]
2. [Step 2]

## Expected vs. Actual:
**Expected:** [What should happen]
**Actual:** [What actually happened]

## Proposed Solutions:
1. [Solution A with pros/cons]
2. [Solution B with pros/cons]

## Timeline Impact:
[Estimate of delay if not resolved quickly]
```

---

## Quality Gates & Checkpoints

### Checkpoint 1: Phase 1 Complete (Widget Keys)

**When:** After Phase 1F, before any Phase 3 work

**Criteria:**
- [ ] All 300+ widget keys added
- [ ] `lib/constants/test_keys.dart` complete and organized
- [ ] All screens/dialogs keyed (home, menus, games, results, dialogs)
- [ ] All 226 non-UI tests passing
- [ ] `flutter analyze` passes (0 errors)
- [ ] App runs without runtime errors
- [ ] Documentation complete (`docs/WIDGET_KEY_GUIDE.md`)
- [ ] CLAUDE.md updated with key requirements

**Verification Commands:**
```bash
flutter analyze lib/constants/test_keys.dart
flutter test  # Expect: 226 tests pass
flutter run   # Manual: Navigate through app, verify no crashes
```

**Sign-off Required:**
- Widget Keys Architect (Phase 1 complete)
- QA Validator (Quality approved)

**If Failed:**
- Identify gaps (missing keys, failing tests, etc.)
- Agent 1 addresses gaps
- Re-validate
- Do NOT proceed to Phase 3 until passed

---

### Checkpoint 2: Phase 2 Complete (Shared Components)

**When:** After Phase 2F, before any Phase 3 work

**Criteria:**
- [ ] All 10 shared component files created
- [ ] 30 new component tests passing
- [ ] All 256 tests passing (226 original + 30 new)
- [ ] All components use widget keys (no text/type/index finding)
- [ ] Component API documentation complete
- [ ] No circular dependencies in components
- [ ] All components have unit tests

**Component Checklist:**
- [ ] `test/shared/sector_parser.dart` (with 20 tests)
- [ ] `test/shared/pump_sequences.dart`
- [ ] `test/shared/element_finders.dart`
- [ ] `test/shared/provider_helpers.dart`
- [ ] `test/shared/settings_helpers.dart`
- [ ] `test/shared/ui_test_helpers.dart`
- [ ] `test/shared/edit_score_helpers.dart`
- [ ] `test/shared/results_helpers.dart`
- [ ] `test/shared/player_test_utils.dart` (with 10 tests)
- [ ] `test/shared/game_ui_config.dart` (or inline in helpers)

**Verification Commands:**
```bash
flutter test test/shared/  # Expect: 30 tests pass
flutter test  # Expect: 256 tests pass
flutter analyze test/shared/
```

**Sign-off Required:**
- Test Component Engineer (Phase 2 complete)
- QA Validator (Quality approved)
- Documentation Specialist (API docs reviewed)

**If Failed:**
- Identify incomplete components
- Agent 2 completes missing work
- Re-validate
- Do NOT proceed to Phase 3 until passed

---

### Checkpoint 3: Phase 3 Complete (Test Migration)

**When:** After Phase 3G (all files migrated), before Phase 4

**Criteria:**
- [ ] All 6 UI test files migrated
- [ ] All inline helper functions removed
- [ ] All 332 tests passing (256 non-UI + 76 UI automation)
- [ ] ~2,500 lines eliminated from UI test files
- [ ] Zero coverage reduction verified
- [ ] All text/type/index finding replaced with key-based finding
- [ ] All shared components in use

**Test File Checklist:**
- [ ] `integration_test/target_tag_add_player_test.dart` (6 tests pass)
- [ ] `integration_test/target_tag_visual_validation_test.dart` (4 tests pass)
- [ ] `integration_test/target_tag_results_screen_test.dart` (6 tests pass)
- [ ] `integration_test/target_tag_gameplay_test.dart` (13 tests pass)
- [ ] `integration_test/target_tag_menu_and_mechanics_test.dart` (23 tests pass)
- [ ] `integration_test/carnival_derby_ui_test.dart` (24 tests pass)

**Verification Commands:**
```bash
# Non-UI tests
flutter test  # Expect: 256 tests pass

# UI tests (requires chromedriver running on port 4444)
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_add_player_test.dart -d chrome
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_visual_validation_test.dart -d chrome
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_results_screen_test.dart -d chrome
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_gameplay_test.dart -d chrome
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/target_tag_menu_and_mechanics_test.dart -d chrome
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/carnival_derby_ui_test.dart -d chrome

# Expect: All 76 UI tests pass
```

**Coverage Verification:**
- [ ] QA Validator confirms no test scenarios removed
- [ ] All previous assertions still present
- [ ] All edge cases still covered

**Sign-off Required:**
- Test Migration Specialist (Phase 3 complete)
- QA Validator (Coverage verified, quality approved)

**If Failed:**
- Identify failing tests or coverage gaps
- Agent 3 addresses issues
- Re-validate
- Do NOT proceed to Phase 4 until passed

---

### Checkpoint 4: Project Complete (Final Sign-off)

**When:** After Phase 4D (all cleanup and docs complete)

**Criteria:**

**Code Quality:**
- [ ] ~4,147 lines eliminated (verified)
- [ ] All obsolete code removed
- [ ] 0 text-based finds for interactive elements
- [ ] 0 index-based accesses for buttons/tiles
- [ ] `flutter analyze` passes (0 errors, 0 warnings)

**Test Quality:**
- [ ] 332 tests passing (256 non-UI + 76 UI)
- [ ] 100% pass rate
- [ ] No flaky tests
- [ ] All tests use shared components
- [ ] Test execution time similar to baseline

**Documentation:**
- [ ] `docs/WIDGET_KEY_GUIDE.md` complete
- [ ] `TEST_MODERNIZATION_SUMMARY.md` complete
- [ ] `CLAUDE.md` updated accurately
- [ ] `README.md` updated
- [ ] All code examples in docs compile
- [ ] Test counts accurate throughout docs

**Performance:**
- [ ] App launch time unchanged
- [ ] App memory usage unchanged
- [ ] Test execution time unchanged
- [ ] No user-facing regressions

**ROI Verification:**
- [ ] Total time invested: 53-73 hours (actual logged)
- [ ] Expected annual savings: 50 hours/year
- [ ] Payback period: 14-19 months
- [ ] All metrics documented

**Verification Commands:**
```bash
# All tests
flutter test  # Expect: 256 tests pass
# [All 6 UI test files]  # Expect: 76 tests pass

# Code quality
flutter analyze  # Expect: 0 issues

# Documentation
grep -r "226 tests" .  # Should find 0 (all updated to 256/332)
grep -r "302 tests" .  # Should find 0 (all updated to 332)
```

**Sign-off Required:**
- All 5 agents sign off
- User final approval

**If Failed:**
- Identify gaps in checklist
- Responsible agent addresses
- Re-validate
- Repeat until all criteria met

---

## Risk Management

### Risk 1: Widget Keys Break Existing Functionality

**Probability:** Low
**Impact:** Medium
**Phase:** Phase 1

**Mitigation:**
- Add keys incrementally (one screen at a time)
- Run `flutter test` after each Phase 1 sub-phase
- Manual testing after each screen (Agent 1 + Agent 4)
- Keys don't change app behavior (only add metadata)

**Detection:**
- Tests fail after adding keys
- App crashes at runtime
- UI renders incorrectly

**Response:**
1. Agent 4 identifies which keys caused issue
2. Agent 1 removes problematic keys
3. Investigate root cause (likely duplicate keys)
4. Fix and re-add keys
5. Re-validate tests pass

**Owner:** Agent 1 (Widget Keys Architect) with Agent 4 (QA) oversight

---

### Risk 2: Test Migration Reduces Coverage

**Probability:** Medium
**Impact:** High
**Phase:** Phase 3

**Mitigation:**
- Agent 3 follows strict "no reduction" rule
- Agent 4 manually reviews each migrated file
- Compare before/after test scenarios explicitly
- Maintain checklist of all assertions to preserve
- Migrate one file at a time, validate before next

**Detection:**
- Test count decreases
- Scenarios missing in migrated tests
- Assertions removed
- QA Validator catches during review

**Response:**
1. Agent 4 documents missing coverage
2. Agent 3 adds back missing scenarios
3. Re-run tests
4. Re-review with Agent 4
5. Do not proceed until coverage restored

**Owner:** Agent 3 (Test Migration Specialist) with Agent 4 (QA) enforcement

---

### Risk 3: Shared Components Don't Cover All Use Cases

**Probability:** Low
**Impact:** Medium
**Phase:** Phase 2-3

**Mitigation:**
- Agent 2 analyzes ALL existing test patterns before building
- Create components iteratively, test with real scenarios
- Agent 3 provides feedback on component gaps during migration
- Components designed for extensibility

**Detection:**
- Agent 3 finds scenarios components can't handle
- Need to write inline code instead of using component
- Components require frequent modifications

**Response:**
1. Agent 3 documents gap with example
2. Agent 2 extends component to cover gap
3. Agent 3 validates component now works
4. Update component documentation
5. Continue migration

**Owner:** Agent 2 (Test Component Engineer) with Agent 3 (Migration Specialist) feedback

---

### Risk 4: ChromeDriver/UI Tests Become Flaky

**Probability:** Medium
**Impact:** Medium
**Phase:** Phase 3

**Mitigation:**
- Use `PumpSequences` consistently for all animations
- Key-based finding more reliable than text-based
- Run each test multiple times to verify stability
- Agent 3 documents flaky patterns and solutions

**Detection:**
- Tests pass sometimes, fail sometimes
- Timeouts or element not found errors
- Tests fail in CI but pass locally

**Response:**
1. Agent 3 identifies flaky test
2. Add additional pump sequences or wait times
3. Verify element finding uses keys (not text)
4. Run test 5 times to confirm stability
5. Document pattern for future reference

**Owner:** Agent 3 (Test Migration Specialist)

---

### Risk 5: Timeline Overruns

**Probability:** Medium
**Impact:** Low
**Phase:** All phases

**Mitigation:**
- Build buffer into estimates (53-73 hour range)
- Parallelize Phase 1D-1F with Phase 2
- Break large phases into smaller sub-phases
- Track actual vs. estimated time daily
- QA Validator identifies delays early

**Detection:**
- Actual time exceeds estimated by >20%
- Phases taking multiple times longer than planned
- Agents report blockers or difficulty

**Response:**
1. Agent reports delay with reason
2. QA Validator assesses impact
3. Options:
   - Extend timeline (user approval)
   - Reduce scope (user approval)
   - Add resources (not practical with agent team)
4. Adjust plan and communicate new timeline

**Owner:** Agent 4 (QA Validator) tracks, User decides on response

---

### Risk 6: Agent Availability/Continuity

**Probability:** Low
**Impact:** High
**Phase:** All phases

**Mitigation:**
- Each agent maintains detailed daily status
- Handoff documents capture all context
- Master plan contains all technical details
- Work is organized into independent sub-phases
- Different agent can resume if needed

**Detection:**
- Agent becomes unavailable mid-phase
- Agent changes between phases

**Response:**
1. Review agent's daily status logs
2. Review handoff documents
3. New agent studies master plan relevant section
4. New agent asks questions of QA Validator
5. Resume work from last completed sub-phase

**Owner:** User (if agent replacement needed)

---

## Success Metrics

### Quantitative Metrics

**1. Test Count Progression:**
- Baseline: 226 non-UI tests
- After Phase 2: 256 tests (226 + 30 component tests)
- After Phase 3: 332 tests (256 + 76 UI)
- **Target:** All 332 tests passing

**2. Code Reduction:**
- Target: ~4,147 lines eliminated
- Measure: `git diff --stat` before/after migration
- Breakdown:
  - UI test files: -2,500 lines
  - Helper duplication: -1,260 lines
  - Element finding: -400 lines

**3. Widget Keys:**
- Target: 300+ keys added
- Measure: Count keys in `lib/constants/test_keys.dart`
- Verify: All interactive widgets keyed

**4. Test Reliability:**
- Text-based finds: 341 → 0 (-100%)
- Index-based finds: 85 → 0 (-100%)
- Key-based finds: 0 → 300+ (+100%)
- **Overall reliability: 28% → 100%**

**5. Test Execution Time:**
- Non-UI: Should remain <2 minutes
- UI: Should remain ~43 minutes
- Measure: Time full test suite runs
- **Target:** No more than 10% increase

**6. Shared Components:**
- Target: 10 components created
- Measure: Count files in `test/shared/`
- Verify: All components have tests

---

### Qualitative Metrics

**1. Code Quality:**
- Clean, maintainable code
- Follows naming conventions
- Well-documented
- QA Validator approval
- Zero `flutter analyze` errors

**2. Documentation Quality:**
- Clear and comprehensive
- Examples compile and run
- Easy to understand for future developers
- Cross-referenced correctly
- User approval

**3. Test Maintainability:**
- Easy to update when UI changes
- No hardcoded text or indices
- Clear test intent
- Self-documenting
- Team agreement on quality

**4. Team Readiness:**
- All agents trained on widget keys
- All agents trained on shared components
- Patterns documented for future use
- Onboarding guide for new developers

---

### Tracking & Reporting

**Daily Tracking:**
Each agent logs in `AGENT_DAILY_STATUS.md`:
- Hours worked
- Tasks completed
- Tests passing
- Issues encountered

**Weekly Summary:**
Agent 4 (QA Validator) creates weekly report:
```markdown
# Week X Summary

## Progress:
- Phase X.Y completed
- Phase X.Z in progress (75%)

## Metrics:
- Tests passing: X/Y
- Lines eliminated: X
- Widget keys added: X
- Components created: X

## Issues:
- X issues resolved
- Y issues open

## Next Week:
- Complete Phase X.Z
- Start Phase X.Z+1
```

**Final Report:**
Agent 5 (Documentation Specialist) creates in TEST_MODERNIZATION_SUMMARY.md:
- All metrics achieved
- Before/after comparisons
- Lessons learned
- Benefits realized
- Recommendations for future work

---

## Appendix

### File References

**Master Plan:** `TEST_MODERNIZATION_MASTER_PLAN.md`
- Contains ALL technical implementation details
- Phase-by-phase instructions
- Code examples and validation commands
- Complete technical reference

**Status Tracking:** `AGENT_DAILY_STATUS.md`
- Daily agent updates
- Real-time progress tracking

**Handoff Documents:** Created ad-hoc per phase
- `HANDOFF_PHASE_1.md`
- `HANDOFF_PHASE_2.md`
- `HANDOFF_PHASE_3.md`

**Final Summary:** `TEST_MODERNIZATION_SUMMARY.md`
- Created in Phase 4
- Complete project summary

---

### Agent Assignment Matrix

| Phase | Sub-Phase | Primary Agent | Support Agents | Duration |
|-------|-----------|---------------|----------------|----------|
| 1A | Key naming guide | Agent 1 | Agent 4, Agent 5 | 2-3h |
| 1B | Home keys | Agent 1 | Agent 4 | 2-3h |
| 1C | Menu keys | Agent 1 | Agent 4 | 6-8h |
| 1D | Game screen keys | Agent 1 | Agent 4 | 10-12h |
| 1E | Results keys | Agent 1 | Agent 4 | 2-3h |
| 1F | Dialog keys | Agent 1 | Agent 4 | 4-5h |
| 2A | Core components | Agent 2 | Agent 4 | 2-3h |
| 2B | Element finders | Agent 2 | Agent 4 | 2-3h |
| 2C | Helpers | Agent 2 | Agent 4 | 2-3h |
| 2D | UI helpers | Agent 2 | Agent 4 | 2-3h |
| 2E | Dialog helpers | Agent 2 | Agent 4 | 2-3h |
| 2F | Player utils | Agent 2 | Agent 4 | 1-2h |
| 3A | Migration strategy | Agent 3 | Agent 4 | 2-3h |
| 3B-3G | 6 file migrations | Agent 3 | Agent 4 | 14-20h |
| 4A | Cleanup | Agent 3 | Agent 4 | 1h |
| 4B | Documentation | Agent 5 | All | 2-3h |
| 4C | Final tests | Agent 4 | All | 30min |
| 4D | Performance | Agent 4 | - | 30min |

**Total Agent-Hours:** 69.5-94.5 hours across 5 agents

---

### Next Steps

**To Begin Implementation:**

1. **User approval of this agent team plan**
2. **Create AGENT_DAILY_STATUS.md** for tracking
3. **Assign Agent 1 to start Phase 1A**
4. **Agent 1 creates widget key naming guide**
5. **Follow master plan for technical details**

**Ready to start?** All technical details are in TEST_MODERNIZATION_MASTER_PLAN.md. This agent team plan provides the coordination framework.

---

# PART 4: GAME FEATURE ENHANCEMENTS

This section defines the game feature updates that should be implemented alongside test modernization to improve code quality, maintainability, and future-proofing.

**Why Include These Features:**
- **Synergy with test modernization**: Tests will validate these new features
- **Future-proofing**: Enables games with variable dart counts (1, 5, 10 darts/turn)
- **Code quality**: Eliminates duplication in turn counting logic
- **Bug prevention**: Centralized skip turn logic prevents future bugs
- **Better statistics**: Enhanced player metrics for all games

**Implementation Order:**
- These features should be implemented BEFORE or IN PARALLEL with test modernization
- Tests updated in Phase 3 will validate these new features
- Agent 2 (Test Component Engineer) can implement these while Agent 1 works on widget keys

---

## Overview of Game Feature Enhancements

### Current State

Both Target Tag and Carnival Derby games currently:
- Hardcode "3 darts per turn" throughout the code
- Duplicate turn increment logic in multiple locations
- Have inconsistent skip turn implementations (one adds misses, one records dart throws)
- Track basic statistics (games played/won, duration)

### Problems

1. **Hardcoded Dart Counts**
   - Every reference to dart counts uses literal "3"
   - Future games with different dart counts require extensive code changes
   - Skip turn helpers hardcode `3 - dartsThrown`
   - Dartboard emulator assumes 3 darts

2. **Duplicated Turn Counter Logic**
   - Target Tag: Turn increment duplicated in `processMiss()` and `processDartHit()`
   - Carnival Derby: Turn increment duplicated in 3 branches of `recordDartThrow()`
   - Risk: New dart processing paths might forget to increment turn counter
   - Hard to maintain: Changes require editing multiple locations

3. **Inconsistent Skip Turn Behavior**
   - Target Tag `skipTurn()` calls `processMiss()` → increments dart counters (WRONG)
   - Carnival Derby `skipTurn()` calls `recordDartThrow()` → increments dart counters (WRONG)
   - Skip turn should ONLY add visual "Skip" markers, not increment counters
   - Current implementation causes incorrect statistics

4. **Limited Statistics**
   - Only tracks games played/won and duration
   - No visibility into dart efficiency or turn counts
   - Cannot compare player performance across games

### Proposed Solution

**Phase 5: Add maxDartsPerTurn Property**
- Add `final int maxDartsPerTurn` property to both game models
- Default to 3 for current games
- Replace all hardcoded "3" references with `_currentGame!.maxDartsPerTurn`
- Add validation: prevent processing more than maxDartsPerTurn
- **Effort:** 1-2 hours
- **Files:** 2 game models, 2 providers

**Phase 6: Refactor Turn Counter Logic**
- Extract turn increment logic into `_incrementTurnIfFirst()` helper method
- Replace all duplicate turn increment code with single helper call
- DRY principle: Logic exists in exactly one place
- **Effort:** 1-2 hours
- **Files:** 2 game models

**Phase 7: Create Global Skip Turn Component**
- Create `lib/services/game_skip_turn_helper.dart` with `GameSkipTurnHelper` class
- Centralized skip turn validation and visual marker management
- Update both providers to use global helper
- Ensures skip turn does NOT increment dart or turn counters
- **Effort:** 2-3 hours
- **Files:** 1 new service, 2 providers

### Expected Outcomes

**After Phase 5-7 Implementation:**

✅ **Future-Proofing:**
- New games can specify any dart count (1, 5, 10, etc.) with single parameter
- No hardcoded "3" anywhere in game logic
- Dart count changes require editing only game model constructor

✅ **Code Quality:**
- ~15 locations updated to use `maxDartsPerTurn` property
- Turn increment logic exists in ONE place (DRY principle)
- Skip turn behavior centralized and consistent

✅ **Bug Prevention:**
- Skip turn helper prevents incrementing counters (current bug fixed)
- Dart overflow validation prevents processing too many darts
- Future games inherit correct patterns automatically

✅ **Enhanced Statistics:**
- Track dart throws and turns per player
- Calculate dart efficiency metrics
- Support player performance comparisons

---

## Phase 5: maxDartsPerTurn Property

**Goal:** Add configurable dart count property to game models, enabling future games to specify different dart counts per turn.

**Agent Assignment:** Agent 2 (Test Component Engineer) can implement this in parallel with Phase 2 work.

**Duration:** 1-2 hours

### Phase 5A: Update Target Tag Game Model

#### File: `lib/models/target_tag_game.dart`

**Add property** (line ~15):

```dart
class TargetTagGame {
  final String id;
  final List<String> playerIds;
  final int shields;
  final bool heroBonus;
  final DateTime startedAt;
  final int maxDartsPerTurn;  // NEW: Max darts allowed per turn

  TargetTagGame({
    required this.id,
    required this.playerIds,
    required this.shields,
    this.heroBonus = false,
    required this.startedAt,
    this.maxDartsPerTurn = 3,  // NEW: Default to standard 3 darts
    // ... rest of parameters
  });
}
```

**Update factory constructors** (`createSolo()` and `createTeam()`):

```dart
factory TargetTagGame.createSolo({
  required List<String> playerIds,
  required int shields,
  bool heroBonus = false,
}) {
  return TargetTagGame(
    id: const Uuid().v4(),
    playerIds: playerIds,
    shields: shields,
    heroBonus: heroBonus,
    startedAt: DateTime.now(),
    maxDartsPerTurn: 3,  // NEW: Explicit for Target Tag
    // ... rest of initialization
  );
}

factory TargetTagGame.createTeam({
  required Map<String, List<String>> teams,
  required int shields,
  bool heroBonus = false,
}) {
  return TargetTagGame(
    id: const Uuid().v4(),
    playerIds: teams.values.expand((x) => x).toList(),
    teams: teams,
    shields: shields,
    heroBonus: heroBonus,
    startedAt: DateTime.now(),
    maxDartsPerTurn: 3,  // NEW: Explicit for Target Tag
    // ... rest of initialization
  );
}
```

**Add getter method**:

```dart
int getMaxDartsPerTurn() => maxDartsPerTurn;
```

**Add dart limit validation** in `processMiss()` (line ~344):

```dart
void processMiss(String playerId) {
  if (state != GameState.playing && state != GameState.suddenDeath) return;
  if (playerId != playerIds[currentPlayerIndex]) return;

  // NEW: Prevent processing more darts than allowed per turn
  if (dartsThrown[playerId]! >= maxDartsPerTurn) return;

  // ... existing logic
}
```

**Add dart limit validation** in `processDartHit()` (line ~378):

```dart
void processDartHit(String playerId, int hitNumber, String multiplier) {
  if (state != GameState.playing && state != GameState.suddenDeath) return;
  if (playerId != playerIds[currentPlayerIndex]) return;

  // NEW: Prevent processing more darts than allowed per turn
  if (dartsThrown[playerId]! >= maxDartsPerTurn) return;

  // ... existing logic
}
```

**Why add validation?**
- Prevents bugs in games with different dart counts (e.g., 1 dart/turn, 5 darts/turn)
- Silently ignores extra darts (graceful degradation)
- Future-proofs for non-standard game modes

### Phase 5B: Update Carnival Derby Game Model

#### File: `lib/models/horse_race_game.dart`

Apply identical changes:

**Add property**:

```dart
class HorseRaceGame {
  final String id;
  final List<String> playerIds;
  final int targetScore;
  final bool exactScoreMode;
  final DateTime startedAt;
  final int maxDartsPerTurn;  // NEW: Max darts allowed per turn

  HorseRaceGame({
    required this.id,
    required this.playerIds,
    required this.targetScore,
    this.exactScoreMode = false,
    required this.startedAt,
    this.maxDartsPerTurn = 3,  // NEW: Default to standard 3 darts
    // ... rest of parameters
  });
}
```

**Update factory constructor**:

```dart
factory HorseRaceGame.create({
  required List<String> playerIds,
  required int targetScore,
  bool exactScoreMode = false,
}) {
  return HorseRaceGame(
    id: const Uuid().v4(),
    playerIds: playerIds,
    targetScore: targetScore,
    exactScoreMode: exactScoreMode,
    startedAt: DateTime.now(),
    maxDartsPerTurn: 3,  // NEW: Explicit for Carnival Derby
    // ... rest of initialization
  );
}
```

**Add getter method**:

```dart
int getMaxDartsPerTurn() => maxDartsPerTurn;
```

**Add dart limit validation** in `recordDartThrow()` (line ~87):

```dart
void recordDartThrow(String playerId, int score, {String? dartDisplay}) {
  if (state != GameState.playing) return;
  if (playerId != playerIds[currentPlayerIndex]) return;

  // NEW: Prevent processing more darts than allowed per turn
  if (dartsThrown[playerId]! >= maxDartsPerTurn) return;

  // ... existing logic
}
```

### Phase 5C: Update Target Tag Provider

#### File: `lib/providers/target_tag_provider.dart`

**Replace hardcoded "3" in skipTurn()** (line ~256):

```dart
void skipTurn() {
  if (_currentGame == null) return;

  final currentPlayerId = _currentGame!.getCurrentPlayerId();
  final dartsThrown = _currentGame!.getCurrentPlayerDartsThrown();

  // OLD: final remainingDarts = 3 - dartsThrown;
  // NEW: Use game property
  final remainingDarts = _currentGame!.maxDartsPerTurn - dartsThrown;

  for (int i = 0; i < remainingDarts; i++) {
    _currentGame!.currentTurnDarts[currentPlayerId]!.add('Skip');
  }

  _waitingForTakeout = true;
  notifyListeners();
}
```

### Phase 5D: Update Carnival Derby Provider

#### File: `lib/providers/horse_race_provider.dart`

**Replace hardcoded "3" in skipTurn()** (line ~91):

```dart
void skipTurn() {
  if (_currentGame == null) return;

  final currentPlayerId = _currentGame!.getCurrentPlayerId();
  final dartsThrown = _currentGame!.getCurrentPlayerDartsThrown();

  // OLD: final remainingDarts = 3 - dartsThrown;
  // NEW: Use game property
  final remainingDarts = _currentGame!.maxDartsPerTurn - dartsThrown;

  for (int i = 0; i < remainingDarts; i++) {
    _currentGame!.currentTurnDartScores[currentPlayerId]!.add('Skip');
  }

  _waitingForTakeout = true;
  notifyListeners();
}
```

### Phase 5 Validation

**Run all tests:**
```bash
flutter test
```

**Expected:** All 332 tests pass (100% pass rate)

**Checklist:**
- [ ] TargetTagGame has `maxDartsPerTurn` property
- [ ] HorseRaceGame has `maxDartsPerTurn` property
- [ ] Both factories set `maxDartsPerTurn: 3`
- [ ] Both game models have dart limit validation
- [ ] Both providers use `_currentGame!.maxDartsPerTurn`
- [ ] No hardcoded "3" references remain in skip turn methods
- [ ] All 332 tests passing
- [ ] No runtime errors in manual testing

**Handoff to:** Phase 6 (can proceed immediately after validation)

---

## Phase 6: Turn Management System with _incrementTurnIfFirst()

**Goal:** Eliminate duplication of turn increment logic by extracting it into a private helper method in each game model.

**Agent Assignment:** Agent 2 (Test Component Engineer)

**Duration:** 1-2 hours

### Background

**Current Issue:**

The turn increment logic `if (dartsThrown[playerId] == 1) { totalTurns[playerId]++; }` is duplicated:
- **Target Tag**: 2 locations (`processMiss()` and `processDartHit()`)
- **Carnival Derby**: 3 locations (bust branch, win branch, normal branch in `recordDartThrow()`)

This creates maintenance risk - future dart processing paths might forget the turn increment.

**Turn Counting Rules:**
- Turn counted when FIRST dart is thrown (not when turn ends)
- Handles edge cases correctly:
  - ✅ Player throws 1 dart then skips = 1 turn counted
  - ✅ Player skips entire turn (0 darts) = 0 turns counted
  - ✅ Player wins on 1st or 2nd dart = 1 turn counted

**Why increment on first dart (not in advanceToNextPlayer)?**
- Turn starts when first dart is thrown, not when turn ends
- Handles win on 1st/2nd dart correctly
- Handles skip after 1 dart correctly
- Skip entire turn (0 darts) = 0 turns counted ✓

### Phase 6A: Refactor Target Tag Game Model

#### File: `lib/models/target_tag_game.dart`

**Add private helper method** (after getter methods, around line 234):

```dart
// Increment turn counter if this is the first dart thrown
void _incrementTurnIfFirst(String playerId) {
  if (dartsThrown[playerId] == 1) {
    totalTurns[playerId] = (totalTurns[playerId] ?? 0) + 1;
  }
}
```

**Update `processMiss()` method** (line ~344):

```dart
void processMiss(String playerId) {
  if (state != GameState.playing && state != GameState.suddenDeath) return;
  if (playerId != playerIds[currentPlayerIndex]) return;
  if (dartsThrown[playerId]! >= maxDartsPerTurn) return;

  // ... existing tagged-in tracking and lists ...

  // Increment dart counters
  dartsThrown[playerId] = (dartsThrown[playerId] ?? 0) + 1;
  totalDartsThrown[playerId] = (totalDartsThrown[playerId] ?? 0) + 1;

  // OLD: Duplicated turn increment logic
  // if (dartsThrown[playerId] == 1) {
  //   totalTurns[playerId] = (totalTurns[playerId] ?? 0) + 1;
  // }

  // NEW: Single call, clear intent
  _incrementTurnIfFirst(playerId);
}
```

**Update `processDartHit()` method** (line ~378):

```dart
void processDartHit(String playerId, int hitNumber, String multiplier) {
  if (state != GameState.playing && state != GameState.suddenDeath) return;
  if (playerId != playerIds[currentPlayerIndex]) return;
  if (dartsThrown[playerId]! >= maxDartsPerTurn) return;

  // ... existing logic ...

  // Increment dart counters
  dartsThrown[playerId] = (dartsThrown[playerId] ?? 0) + 1;
  totalDartsThrown[playerId] = (totalDartsThrown[playerId] ?? 0) + 1;

  // OLD: Duplicated turn increment logic
  // if (dartsThrown[playerId] == 1) {
  //   totalTurns[playerId] = (totalTurns[playerId] ?? 0) + 1;
  // }

  // NEW: Single call, clear intent
  _incrementTurnIfFirst(playerId);

  // ... rest of logic ...
}
```

### Phase 6B: Refactor Carnival Derby Game Model

#### File: `lib/models/horse_race_game.dart`

**Add private helper method** (after getter methods, around line 234):

```dart
// Increment turn counter if this is the first dart thrown
void _incrementTurnIfFirst(String playerId) {
  if (dartsThrown[playerId] == 1) {
    totalTurns[playerId] = (totalTurns[playerId] ?? 0) + 1;
  }
}
```

**Update `recordDartThrow()` method** (3 call sites, line ~87):

```dart
void recordDartThrow(String playerId, int score, {String? dartDisplay}) {
  if (state != GameState.playing) return;
  if (playerId != playerIds[currentPlayerIndex]) return;
  if (dartsThrown[playerId]! >= maxDartsPerTurn) return;

  final currentScore = scores[playerId] ?? 0;
  final newScore = currentScore + score;

  // Store dart score display
  currentTurnDartScores[playerId] ??= [];
  currentTurnDartScores[playerId]!.add(dartDisplay ?? score.toString());

  // Handle exact score mode
  if (exactScoreMode) {
    if (newScore > targetScore) {
      // Player busted
      currentPlayerBusted = true;
      dartsThrown[playerId] = (dartsThrown[playerId] ?? 0) + 1;
      totalDartsThrown[playerId] = (totalDartsThrown[playerId] ?? 0) + 1;

      // OLD: Duplicated turn increment
      // if (dartsThrown[playerId] == 1) {
      //   totalTurns[playerId] = (totalTurns[playerId] ?? 0) + 1;
      // }

      // NEW: Use helper method (Call 1)
      _incrementTurnIfFirst(playerId);
      return;
    } else if (newScore == targetScore) {
      // Player won
      scores[playerId] = newScore;
      dartsThrown[playerId] = (dartsThrown[playerId] ?? 0) + 1;
      totalDartsThrown[playerId] = (totalDartsThrown[playerId] ?? 0) + 1;

      // OLD: Duplicated turn increment
      // if (dartsThrown[playerId] == 1) {
      //   totalTurns[playerId] = (totalTurns[playerId] ?? 0) + 1;
      // }

      // NEW: Use helper method (Call 2)
      _incrementTurnIfFirst(playerId);
      winnerId = playerId;
      state = GameState.finished;
      return;
    }
  }

  // Normal mode or exact mode without bust/win
  scores[playerId] = newScore;
  dartsThrown[playerId] = (dartsThrown[playerId] ?? 0) + 1;
  totalDartsThrown[playerId] = (totalDartsThrown[playerId] ?? 0) + 1;

  // OLD: Duplicated turn increment
  // if (dartsThrown[playerId] == 1) {
  //   totalTurns[playerId] = (totalTurns[playerId] ?? 0) + 1;
  // }

  // NEW: Use helper method (Call 3)
  _incrementTurnIfFirst(playerId);

  // Check if player has won (normal mode)
  if (!exactScoreMode && scores[playerId]! >= targetScore) {
    winnerId = playerId;
    state = GameState.finished;
  }
}
```

### Benefits of Phase 6 Refactoring

1. ✅ **DRY Principle** - Logic exists in exactly one place
2. ✅ **Clear Intent** - Method name `_incrementTurnIfFirst()` self-documents behavior
3. ✅ **Easier to Modify** - Future changes (e.g., tracking turn timestamps) only need one edit
4. ✅ **Same Behavior** - Still handles all edge cases (skip turn, wins on dart 1/2, etc.)
5. ✅ **No Breaking Changes** - Internal refactoring, same external behavior
6. ✅ **Future-Proof** - New dart processing paths automatically get correct turn counting by calling helper

### Phase 6 Validation

**Run all tests:**
```bash
flutter test
```

**Expected:** All 332 tests pass (100% pass rate)

**Test Impact:**
- No test changes required (internal refactoring only)
- Existing tests continue to validate correct behavior
- Statistics tracking tests verify turn counting still works correctly

**Checklist:**
- [ ] TargetTagGame has `_incrementTurnIfFirst()` method
- [ ] HorseRaceGame has `_incrementTurnIfFirst()` method
- [ ] Target Tag uses helper in 2 locations (processMiss, processDartHit)
- [ ] Carnival Derby uses helper in 3 locations (bust, win, normal branches)
- [ ] No duplicated turn increment logic remains
- [ ] All 332 tests passing
- [ ] Statistics tracking still works correctly

**Handoff to:** Phase 7 (can proceed immediately after validation)

---

## Phase 7: Global Skip Turn Component

**Goal:** Create a reusable skip turn **LOGIC** utility that ensures consistent behavior across all games (current and future).

**Agent Assignment:** Agent 2 (Test Component Engineer)

**Duration:** 2-3 hours

### Background

**Current Problem:**

Skip turn implementations are inconsistent and BUGGY:

**Target Tag** (`lib/providers/target_tag_provider.dart` line ~256):
```dart
void skipTurn() {
  final remainingDarts = 3 - dartsThrown;
  for (int i = 0; i < remainingDarts; i++) {
    _currentGame!.currentTurnDarts[currentPlayerId]!.add('Miss');
    _currentGame!.processMiss(currentPlayerId);  // ❌ PROBLEM: Increments counters
  }
  _waitingForTakeout = true;
}
```

**Carnival Derby** (`lib/providers/horse_race_provider.dart` line ~91):
```dart
void skipTurn() {
  final remainingDarts = 3 - dartsThrown;
  for (int i = 0; i < remainingDarts; i++) {
    _currentGame!.recordDartThrow(currentPlayerId, 0, dartDisplay: 'Miss');  // ❌ PROBLEM: Increments counters
  }
  _waitingForTakeout = true;
}
```

**Issues:**
1. Calls game dart processing methods (`processMiss()`, `recordDartThrow()`)
2. Increments dart throw counters (WRONG - skip should not count as throws)
3. Increments turn counters (WRONG - skip entire turn should not count as turn if 0 darts thrown)
4. Causes incorrect statistics
5. Inconsistent between games (one uses processMiss, one uses recordDartThrow)

**Correct Skip Turn Behavior:**
- ✅ Adds visual "Skip" markers for remaining darts
- ❌ Does NOT increment dart throw counters
- ❌ Does NOT increment turn counters (if 0 darts thrown)
- ❌ Does NOT call game-specific dart processing methods
- ✅ Turn still counted if player threw 1+ darts before skipping

**IMPORTANT:** This is a **LOGIC-ONLY** component. Each game keeps its own skip turn button with game-specific styling and positioning.

**What the helper provides:**
- ✅ Validation logic (can skip turn?)
- ✅ Counter management (add visual markers without incrementing counters)
- ✅ Consistent behavior rules

**What each game controls:**
- ✅ Button styling (colors, fonts, borders matching game theme)
- ✅ Button positioning (where it appears in the game UI)
- ✅ Button text/icon (can say "Skip Turn", "Skip", or use an icon)

### Phase 7A: Create Global Skip Turn Helper

#### File: `lib/services/game_skip_turn_helper.dart` (NEW)

Create a static helper class:

```dart
/// Helper class for consistent skip turn behavior across all games.
///
/// Skip turn behavior:
/// - Adds visual "Skip" markers for remaining darts
/// - Does NOT increment dart throw counters
/// - Does NOT increment turn counters
/// - Does NOT call game-specific dart processing methods
///
/// This ensures skip turn works identically across all current and future games.
class GameSkipTurnHelper {
  /// Handles skip turn for any game.
  ///
  /// Parameters:
  /// - currentDartCount: How many darts the player has thrown this turn
  /// - maxDartsPerTurn: Maximum darts per turn (usually 3)
  /// - addVisualMarker: Callback to add "Skip" marker to game state
  ///
  /// Returns:
  /// - Number of darts that were skipped (for logging/debugging)
  ///
  /// Example usage:
  /// ```dart
  /// GameSkipTurnHelper.skipRemainingDarts(
  ///   currentDartCount: dartsThrown,
  ///   maxDartsPerTurn: _currentGame!.maxDartsPerTurn,
  ///   addVisualMarker: (marker) {
  ///     _currentGame!.currentTurnDarts[currentPlayerId]!.add(marker);
  ///   },
  /// );
  /// ```
  static int skipRemainingDarts({
    required int currentDartCount,
    required int maxDartsPerTurn,
    required void Function(String marker) addVisualMarker,
  }) {
    if (currentDartCount >= maxDartsPerTurn) {
      return 0; // Already threw all darts
    }

    final remainingDarts = maxDartsPerTurn - currentDartCount;

    // Add visual "Skip" markers only (do NOT process as dart throws)
    for (int i = 0; i < remainingDarts; i++) {
      addVisualMarker('Skip');
    }

    return remainingDarts;
  }

  /// Validates skip turn conditions.
  ///
  /// Returns true if skip turn is allowed, false otherwise.
  ///
  /// Example usage:
  /// ```dart
  /// if (!GameSkipTurnHelper.canSkipTurn(
  ///   gameActive: isGameActive,
  ///   waitingForTakeout: _waitingForTakeout,
  ///   currentDartCount: dartsThrown,
  ///   maxDartsPerTurn: _currentGame!.maxDartsPerTurn,
  /// )) {
  ///   return; // Skip not allowed
  /// }
  /// ```
  static bool canSkipTurn({
    required bool gameActive,
    required bool waitingForTakeout,
    required int currentDartCount,
    required int maxDartsPerTurn,
  }) {
    if (!gameActive) return false;
    if (waitingForTakeout) return false;
    if (currentDartCount >= maxDartsPerTurn) return false;
    return true;
  }
}
```

### Phase 7B: Update Target Tag Provider

#### File: `lib/providers/target_tag_provider.dart` (line ~256)

**BEFORE (buggy - adds misses and increments counters):**
```dart
void skipTurn() {
  final remainingDarts = 3 - dartsThrown;
  for (int i = 0; i < remainingDarts; i++) {
    _currentGame!.currentTurnDarts[currentPlayerId]!.add('Miss');
    _currentGame!.processMiss(currentPlayerId);  // ❌ PROBLEM
  }
  _waitingForTakeout = true;
}
```

**AFTER (uses global helper - correct behavior):**
```dart
import 'package:dart_games/services/game_skip_turn_helper.dart';

void skipTurn() {
  if (_currentGame == null) return;

  final currentPlayerId = _currentGame!.getCurrentPlayerId();
  final dartsThrown = _currentGame!.getCurrentPlayerDartsThrown();

  // Validate using global helper
  if (!GameSkipTurnHelper.canSkipTurn(
    gameActive: isGameActive,
    waitingForTakeout: _waitingForTakeout,
    currentDartCount: dartsThrown,
    maxDartsPerTurn: _currentGame!.maxDartsPerTurn,
  )) {
    return;
  }

  // Execute skip using global helper
  GameSkipTurnHelper.skipRemainingDarts(
    currentDartCount: dartsThrown,
    maxDartsPerTurn: _currentGame!.maxDartsPerTurn,
    addVisualMarker: (marker) {
      _currentGame!.currentTurnDarts[currentPlayerId] ??= [];
      _currentGame!.currentTurnDarts[currentPlayerId]!.add(marker);
    },
  );

  _waitingForTakeout = true;
  notifyListeners();
}
```

### Phase 7C: Update Carnival Derby Provider

#### File: `lib/providers/horse_race_provider.dart` (line ~91)

**BEFORE (buggy - records dart throws and increments counters):**
```dart
void skipTurn() {
  final remainingDarts = 3 - dartsThrown;
  for (int i = 0; i < remainingDarts; i++) {
    _currentGame!.recordDartThrow(currentPlayerId, 0, dartDisplay: 'Miss');  // ❌ PROBLEM
  }
  _waitingForTakeout = true;
}
```

**AFTER (uses global helper - correct behavior):**
```dart
import 'package:dart_games/services/game_skip_turn_helper.dart';

void skipTurn() {
  if (_currentGame == null) return;

  final currentPlayerId = _currentGame!.getCurrentPlayerId();
  final dartsThrown = _currentGame!.getCurrentPlayerDartsThrown();

  // Validate using global helper
  if (!GameSkipTurnHelper.canSkipTurn(
    gameActive: isGameActive,
    waitingForTakeout: _waitingForTakeout,
    currentDartCount: dartsThrown,
    maxDartsPerTurn: _currentGame!.maxDartsPerTurn,
  )) {
    return;
  }

  // Execute skip using global helper
  GameSkipTurnHelper.skipRemainingDarts(
    currentDartCount: dartsThrown,
    maxDartsPerTurn: _currentGame!.maxDartsPerTurn,
    addVisualMarker: (marker) {
      _currentGame!.currentTurnDartScores[currentPlayerId] ??= [];
      _currentGame!.currentTurnDartScores[currentPlayerId]!.add(marker);
    },
  );

  _waitingForTakeout = true;
  notifyListeners();
}
```

### Benefits of Phase 7

1. ✅ **Bug Fix** - Skip turn no longer increments dart or turn counters
2. ✅ **Consistency** - All games use identical skip turn logic
3. ✅ **Centralized** - Bug fixes benefit all games automatically
4. ✅ **Future-Proof** - New games inherit correct skip turn behavior
5. ✅ **Clear Documentation** - Helper method documents correct behavior
6. ✅ **Uses maxDartsPerTurn** - Already integrated with Phase 5 changes

### Phase 7 Validation

**Run all tests:**
```bash
flutter test
```

**Expected:** All 332 tests pass (100% pass rate)

**Manual Testing:**

**Test Case 1: Skip after 1 dart**
1. Start game, throw 1 dart
2. Click "Skip Turn"
3. Verify: UI shows "Skip" markers (not "Miss")
4. Verify: Statistics show 1 dart thrown, 1 turn counted

**Test Case 2: Skip entire turn (0 darts)**
1. Start game, immediately click "Skip Turn"
2. Verify: UI shows 3 "Skip" markers
3. Verify: Statistics show 0 darts thrown, 0 turns counted

**Test Case 3: Skip after 2 darts**
1. Start game, throw 2 darts
2. Click "Skip Turn"
3. Verify: UI shows 1 "Skip" marker
4. Verify: Statistics show 2 darts thrown, 1 turn counted

**Checklist:**
- [ ] `game_skip_turn_helper.dart` created
- [ ] TargetTagProvider uses global helper
- [ ] CarnivalDerbyProvider uses global helper
- [ ] Both providers use `maxDartsPerTurn` (not hardcoded 3)
- [ ] Skip turn shows "Skip" markers (not "Miss")
- [ ] Skip turn does NOT increment dart counters
- [ ] Skip turn does NOT increment turn counter (if 0 darts thrown)
- [ ] All 332 tests passing
- [ ] Manual test cases pass

---


## Summary: Game Feature Enhancements

### Implementation Order

**Recommended Sequence:**
1. **Phase 5** (1-2 hours) - Add maxDartsPerTurn property
2. **Phase 6** (1-2 hours) - Refactor turn counter logic with helper method
3. **Phase 7** (2-3 hours) - Create global skip turn component

**Total Effort:** 4-7 hours

**Can Run in Parallel with Test Modernization:**
- Agent 2 can implement Phases 5-7 while Agent 1 works on widget keys (Phase 1)
- Phases 5-7 complete before test migration (Phase 3) begins
- Tests migrated in Phase 3 will validate these features

### Files Modified

**New Files Created (1):**
- `lib/services/game_skip_turn_helper.dart` - Global skip turn component

**Game Models Updated (2):**
- `lib/models/target_tag_game.dart` - maxDartsPerTurn, _incrementTurnIfFirst()
- `lib/models/horse_race_game.dart` - maxDartsPerTurn, _incrementTurnIfFirst()

**Providers Updated (2):**
- `lib/providers/target_tag_provider.dart` - Use maxDartsPerTurn, global skip turn helper
- `lib/providers/horse_race_provider.dart` - Use maxDartsPerTurn, global skip turn helper

**Total:** 1 new file, 4 files modified

### Success Criteria

After Phases 5-7 implementation:

✅ **Future-Proofing:**
- New games can specify any dart count (1, 5, 10, etc.) with single `maxDartsPerTurn` parameter
- No hardcoded "3" anywhere in game logic or skip turn methods
- Dart count changes require editing only game model constructor

✅ **Code Quality:**
- Turn increment logic exists in ONE place per game (DRY principle)
- Skip turn behavior centralized and consistent across all games
- Clear, self-documenting method names

✅ **Bug Prevention:**
- Skip turn helper prevents incrementing counters (current bug fixed)
- Dart overflow validation prevents processing too many darts
- Future games inherit correct patterns automatically

✅ **Testing:**
- All 332 tests pass after each phase
- New tests added in Phase 3 (test migration) validate these features
- Manual testing confirms skip turn shows "Skip" markers, not "Miss"

### Integration with Test Modernization Timeline

```
Week 1-2: Agent 1 - Phase 1 (Widget Keys)
          Agent 2 - Phases 5-7 (Game Features) ← Run in parallel

Week 3-4: Agent 2 - Phase 2 (Shared Components)

Week 5-6: Agent 3 - Phase 3 (Test Migration)
          ↳ Tests validate game features from Phases 5-7

Week 7: Agent 5 - Phase 4 (Documentation)
        ↳ Document game features in CLAUDE.md
```

**No Timeline Impact:** Game features complete before test migration begins, so no blocking dependencies.

---

## Documentation Updates for Game Features

These updates will be added to CLAUDE.md as part of **Phase 4B** (Documentation Updates).

### CLAUDE.md Updates

**Section: "Game Model Requirements"** (add after "Adding New Games" section):

```markdown
### Game Model Requirements

**ALL game models MUST implement these standard properties and methods:**

#### 1. Max Darts Per Turn Property

Every game model must have:

```dart
class YourGame {
  final int maxDartsPerTurn;  // Max darts allowed per turn

  YourGame({
    this.maxDartsPerTurn = 3,  // Default to standard 3 darts
    // ... other parameters
  });

  int getMaxDartsPerTurn() => maxDartsPerTurn;
}
```

**Future games can specify different counts:**
```dart
// Example: One-dart game
YourGame(maxDartsPerTurn: 1, ...)

// Example: Five-dart game
YourGame(maxDartsPerTurn: 5, ...)
```

#### 2. Turn Counter Helper Method

Every game model must have:

```dart
// Increment turn counter if this is the first dart thrown
void _incrementTurnIfFirst(String playerId) {
  if (dartsThrown[playerId] == 1) {
    totalTurns[playerId] = (totalTurns[playerId] ?? 0) + 1;
  }
}
```

**Usage in dart processing methods:**

```dart
void processDart(String playerId, /* ... */) {
  // Validate dart limit
  if (dartsThrown[playerId]! >= maxDartsPerTurn) return;

  // ... process dart ...

  // Increment counters
  dartsThrown[playerId] = (dartsThrown[playerId] ?? 0) + 1;
  totalDartsThrown[playerId] = (totalDartsThrown[playerId] ?? 0) + 1;
  _incrementTurnIfFirst(playerId);  // ← Use helper method
}
```

#### 3. Skip Turn Integration

**REQUIRED: Use global `GameSkipTurnHelper`:**

```dart
import 'package:dart_games/services/game_skip_turn_helper.dart';

void skipTurn() {
  if (_currentGame == null) return;

  final currentPlayerId = _currentGame!.getCurrentPlayerId();
  final dartsThrown = _currentGame!.getCurrentPlayerDartsThrown();

  // Validate
  if (!GameSkipTurnHelper.canSkipTurn(
    gameActive: isGameActive,
    waitingForTakeout: _waitingForTakeout,
    currentDartCount: dartsThrown,
    maxDartsPerTurn: _currentGame!.maxDartsPerTurn,
  )) {
    return;
  }

  // Execute skip
  GameSkipTurnHelper.skipRemainingDarts(
    currentDartCount: dartsThrown,
    maxDartsPerTurn: _currentGame!.maxDartsPerTurn,
    addVisualMarker: (marker) {
      _currentGame!.currentTurnDarts[currentPlayerId]!.add(marker);
    },
  );

  _waitingForTakeout = true;
  notifyListeners();
}
```
```

**Reference Implementations:**
- Target Tag: `lib/models/target_tag_game.dart`, `lib/providers/target_tag_provider.dart`
- Carnival Derby: `lib/models/horse_race_game.dart`, `lib/providers/horse_race_provider.dart`
- Skip Turn Helper: `lib/services/game_skip_turn_helper.dart`

---

## Validation Checklist - All Game Features

Before marking Phases 5-8 complete:

**Phase 5: maxDartsPerTurn Property**
- [ ] Both game models have `final int maxDartsPerTurn` property
- [ ] Both factories set `maxDartsPerTurn: 3`
- [ ] Both models have dart limit validation (`if (dartsThrown >= maxDartsPerTurn) return`)
- [ ] Both providers use `_currentGame!.maxDartsPerTurn` (not hardcoded 3)
- [ ] All 332 tests passing

**Phase 6: Turn Counter Helper**
- [ ] Both game models have `_incrementTurnIfFirst()` method
- [ ] Target Tag uses helper in 2 locations
- [ ] Carnival Derby uses helper in 3 locations
- [ ] No duplicated turn increment logic remains
- [ ] All 332 tests passing

**Phase 7: Global Skip Turn Component**
- [ ] `lib/services/game_skip_turn_helper.dart` created
- [ ] Both providers import and use `GameSkipTurnHelper`
- [ ] Skip turn uses `canSkipTurn()` validation
- [ ] Skip turn uses `skipRemainingDarts()` execution
- [ ] Skip turn shows "Skip" markers (not "Miss")
- [ ] Manual testing confirms correct behavior
- [ ] All 332 tests passing

**Integration with Test Modernization:**
- [ ] Agent 2 completes Phases 5-7 before Phase 3 (test migration)
- [ ] Tests migrated in Phase 3 validate game features
- [ ] Phase 4B documentation includes game features
- [ ] CLAUDE.md updated with game model requirements

**Final Sign-Off:**
- [ ] All game features implemented and tested
- [ ] All 332 tests passing
- [ ] Manual testing completed
- [ ] Documentation updated
- [ ] Ready for test modernization Phase 3

---

**END OF PART 4: GAME FEATURE ENHANCEMENTS**
