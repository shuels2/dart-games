# Dart Games Documentation Structure

## Overview

This document describes the organization of the Dart Games documentation system. The documentation is split across multiple topic-based files to improve maintainability, navigation, and scalability.

## Directory Structure

```
dart_games/
├── CLAUDE.md                          # Main overview + navigation index (keep small)
└── docs/
    ├── DOCUMENTATION_STRUCTURE.md     # This file - explains the organization
    ├── architecture/
    │   ├── container-app.md          # App structure, project layout
    │   ├── shared-systems.md         # DartboardProvider, PlayerProvider, etc.
    │   └── design-system.md          # Core app colors, typography, theming
    │
    ├── development/
    │   ├── adding-games.md           # Complete guide for new games
    │   ├── game-integration.md       # Required integrations (announcer, stats, etc.)
    │   ├── asset-organization.md     # Asset folder structure
    │   ├── announcement-system.md    # GameAnnouncementQueueService guide
    │   ├── dartboard-emulator.md     # Dartboard emulator component integration
    │   ├── add-player-dialog.md      # Add Player dialog component
    │   ├── edit-score-dialog.md      # Edit Score dialog component
    │   └── widget-keys.md            # Widget key requirements for testing
    │
    ├── testing/
    │   ├── test-overview.md          # Test suite overview, counts, requirements
    │   ├── non-ui-tests.md           # Unit/provider/service tests
    │   ├── ui-automation.md          # Integration test guide (chromedriver, etc.)
    │   ├── continuous-animations.md  # pumpAndSettle() rules
    │   └── test-maintenance.md       # Updating tests when features change
    │
    ├── deployment/
    │   ├── build-process.md          # Mandatory testing, build steps
    │   └── git-workflow.md           # Push permissions, branching
    │
    ├── critical-rules/
    │   ├── dartboard-protection.md   # Dartboard emulator code protection
    │   ├── test-failures.md          # Handling test failures (never auto-update)
    │   └── cross-platform.md         # Web/tablet compatibility
    │
    └── games/
        ├── _GAME_TEMPLATE/           # Template for new games (copy this)
        │   ├── README.md             # Game overview and navigation
        │   ├── game-rules.md         # How the game works, win conditions
        │   ├── design-system.md      # Colors, fonts, styling, theme
        │   ├── components.md         # Component configs (dialogs, emulator)
        │   ├── announcements.md      # Announcement helper, sound effects
        │   ├── testing.md            # Game-specific test notes
        │   ├── assets.md             # Asset inventory and descriptions
        │   └── implementation-notes.md # Quirks, gotchas, technical details
        │
        ├── carnival-derby/
        │   ├── README.md             # "Carnival Derby is a dart-based horse racing game..."
        │   ├── game-rules.md         # Race mechanics, Normal vs Perfect Finish mode
        │   ├── design-system.md      # Yellow/amber carnival theme, Montserrat/Bangers fonts
        │   ├── components.md         # DartboardSectionConfig.carnivalDerby(), dialog configs
        │   ├── announcements.md      # CarnivalDerbyAnnouncementHelper, gallop sound effects
        │   ├── testing.md            # 24 UI tests, 26 user management tests, test patterns
        │   ├── assets.md             # 3 icons, 1 image, 2 sounds (with descriptions)
        │   └── implementation-notes.md # Exact score mode bust behavior, inner/outer singles
        │
        └── target-tag/
            ├── README.md             # "Target Tag is a shield-based elimination game..."
            ├── game-rules.md         # Shields, tagged-in, elimination, team mode, hero bonus
            ├── design-system.md      # Pink/green neon theme, Fredoka font, tech aesthetic
            ├── components.md         # DartboardSectionConfig.targetTag(), dialog configs
            ├── announcements.md      # TargetTagAnnouncementHelper, 15 sound effects
            ├── testing.md            # 53 UI tests, 46 non-UI tests, dart color validation
            ├── assets.md             # 11 icons (team icons 01-10), 15 sounds
            └── implementation-notes.md # Dart indicators (D1/D2/D3), color validation, turn flow
```

## Documentation Purpose by Category

### Architecture Documentation
Documents the foundational structure of the Dart Games container app, including how the app is organized, what shared systems exist, and the core design system.

**Files:**
- `container-app.md` - Project structure, how games integrate with container
- `shared-systems.md` - Global providers and services (PlayerProvider, DartboardProvider, etc.)
- `design-system.md` - Core app design language, colors, typography for non-game screens

### Development Documentation
Step-by-step guides and reference documentation for developers building new games or features.

**Files:**
- `adding-games.md` - Complete walkthrough for creating a new game
- `game-integration.md` - Required integrations (user management, announcer, victory music, etc.)
- `asset-organization.md` - Where to put game assets and how to structure them
- `announcement-system.md` - How to use GameAnnouncementQueueService
- `dartboard-emulator.md` - Integrating the shared dartboard emulator component
- `add-player-dialog.md` - Using the shared Add Player dialog component
- `edit-score-dialog.md` - Using the shared Edit Score dialog component
- `widget-keys.md` - Widget key naming conventions and requirements

### Testing Documentation
Everything related to testing, from running tests to writing new ones to handling failures.

**Files:**
- `test-overview.md` - High-level overview of the 349-test suite
- `non-ui-tests.md` - Details on the 272 non-UI tests (models, providers, services, widgets)
- `ui-automation.md` - Running the 77 UI automation tests with chromedriver
- `continuous-animations.md` - Critical rules for testing screens with animations
- `test-maintenance.md` - How to update tests when features change

### Deployment Documentation
Build process, git workflow, and deployment requirements.

**Files:**
- `build-process.md` - Mandatory testing before builds, build commands
- `git-workflow.md` - Push permissions, branching strategy

### Critical Rules Documentation
Rules that must NEVER be violated, organized by topic.

**Files:**
- `dartboard-protection.md` - Dartboard emulator code is protected, requires permission
- `test-failures.md` - Never auto-update tests to make them pass without user approval
- `cross-platform.md` - All features must work on web and tablet

### Game-Level Documentation

Each game has its own subdirectory with 8 standard files:

#### README.md (Game Overview)
- Brief description of the game
- Quick facts (players, duration, complexity)
- Links to other game docs
- File locations (screens, providers, models, services, assets, tests)
- Key features

#### game-rules.md (Game Mechanics)
- How to play
- Win conditions
- Scoring system
- Game modes (solo, team, variants)
- Turn flow
- Special mechanics
- Edge cases and special rules

#### design-system.md (Visual Design)
- Color palette (with hex codes)
- Typography (fonts, weights, sizes)
- Theme philosophy
- Screen-by-screen styling notes
- Button styles
- Animation styles
- Responsive design notes

#### components.md (Component Configurations)
- Dartboard emulator configs (DartboardSectionConfig, DartboardFABConfig)
- Dialog configs (AddPlayerDialogConfig, EditScoreDialogConfig)
- Custom widgets unique to this game
- Component integration examples

#### announcements.md (Audio System)
- Announcement helper class documentation
- All announcement methods and when they trigger
- Sound effects inventory (file names, timing, priority)
- Voice script examples
- Audio integration patterns

#### testing.md (Game-Specific Testing)
- Test file inventory (UI automation + non-UI)
- Key test scenarios covered
- Test patterns specific to this game
- Known test quirks or setup requirements
- Visual validation tests
- Widget keys used in this game

#### assets.md (Asset Inventory)
- Complete asset list organized by type (icons, images, sounds)
- Asset file paths
- Asset descriptions and usage
- Asset creation notes (sources, licenses)
- Future asset needs

#### implementation-notes.md (Technical Details)
- Code architecture specific to this game
- Provider/state management patterns
- Complex algorithms (scoring calculations, etc.)
- Gotchas and quirks
- Performance considerations
- Future enhancement ideas
- Known issues or limitations

## Adding a New Game

When adding a new game to Dart Games:

1. **Copy the template:**
   ```bash
   cp -r docs/games/_GAME_TEMPLATE docs/games/your-game-name
   ```

2. **Fill out all 8 template files** with your game's specific information

3. **Add link to main CLAUDE.md** in the Games section

4. **Follow the template structure** to ensure consistency across all games

## Benefits of This Structure

### Maintainability
- Each file focuses on one topic
- Easier to update specific sections
- Changes don't require scrolling through massive file

### Navigation
- Clear organization by topic
- Easy to find specific information
- Links create clear relationships

### Scalability
- Easy to add new games without bloating main file
- New development guides can be added as separate files
- Test documentation can grow independently

### Claude Code Compatibility
- Claude Code can reference specific documentation files
- Smaller files load faster
- Clear file names help Claude find relevant docs

### Collaboration
- Multiple developers can edit different docs without conflicts
- Game-specific docs can be maintained by game owners
- Clear ownership of documentation sections

### Template-Based Consistency
- `_GAME_TEMPLATE/` provides structure for new games
- Ensures all games document the same aspects
- Makes it clear what needs to be documented

## Main CLAUDE.md Role

The main CLAUDE.md file should be a **concise overview and navigation hub** (~200-300 lines):

1. Brief project summary (2-3 paragraphs)
2. Quick links to detailed docs (organized by topic)
3. Critical rules summary (with links to full details)
4. Quick reference commands (test commands, build commands)
5. Current test counts (just the numbers, link to details)
6. Table of contents with links to all docs/ files

## Migration Notes

Original CLAUDE.md contained ~2800 lines of content covering:
- Architecture details
- Development guides
- Testing procedures
- Critical rules
- Game-specific information
- Component integration guides

This has been reorganized into ~30+ focused files for better maintainability and navigation.
