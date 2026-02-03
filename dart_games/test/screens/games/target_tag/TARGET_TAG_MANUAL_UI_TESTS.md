# Target Tag - Manual UI Tests

**Purpose:** Manual testing procedures for UI components that are not automated.

**When to use:** Before releases or when making changes to the Target Tag menu screen and Add Player dialog.

---

## Test Suite: Add Player Dialog (3 Manual Tests)

### Prerequisites
- Launch Dart Games app in Chrome: `flutter run -d chrome`
- Navigate to Target Tag menu screen from home screen

---

### Test 1: Add Player with Name Only

**Objective:** Verify that a player can be added with just a name (no photo)

**Steps:**
1. Click "Add New Player" button on Target Tag menu
2. Verify dialog opens with:
   - Title: "Add New Player"
   - Empty name field with label "Player Name"
   - Placeholder avatar icon (gray circle with person icon)
   - "CAMERA" button
   - "GALLERY" button
   - "Cancel" button
   - "Add Player" button
3. Enter player name: `Test Player`
4. Click "Add Player" button

**Expected Results:**
- ✅ Dialog closes
- ✅ Player "Test Player" appears in available players section
- ✅ Player "Test Player" is automatically selected (checkmark visible)
- ✅ Player has no photo displayed (shows default avatar)
- ✅ Player is saved to global player list (persists if you navigate away and back)

**Pass/Fail:** ___________

**Notes:** ___________________________________________________________

---

### Test 2: Add Player with Name and Photo

**Objective:** Verify that a player can be added with both name and photo

**Steps:**
1. Click "Add New Player" button on Target Tag menu
2. Verify dialog opens with empty fields
3. Enter player name: `Photo Player`
4. Click "GALLERY" button
5. Select a test photo from file picker
6. Verify photo preview appears in dialog (circular avatar with selected image)
7. Click "Add Player" button

**Expected Results:**
- ✅ Dialog closes
- ✅ Player "Photo Player" appears in available players section
- ✅ Player "Photo Player" is automatically selected (checkmark visible)
- ✅ Player's selected photo is displayed as avatar
- ✅ Player with photo is saved to global player list
- ✅ Photo persists if you navigate away and back

**Alternative - Camera Test:**
- Instead of step 4-5, click "CAMERA" button
- Follow browser camera permission prompts
- Take a photo or select from camera roll
- Verify photo preview appears
- Continue with remaining steps

**Pass/Fail:** ___________

**Notes:** ___________________________________________________________

---

### Test 3: Add Player Validation - Empty Name

**Objective:** Verify that empty names are rejected with clear error messaging

**Part A: Empty Name Error**

**Steps:**
1. Click "Add New Player" button on Target Tag menu
2. Verify dialog opens with empty name field
3. Leave name field empty (do not enter any text)
4. Click "Add Player" button

**Expected Results:**
- ✅ Error message appears: "Please enter a name"
- ✅ Error message is displayed below/within the name field (red text)
- ✅ Dialog remains open (does NOT close)
- ✅ No player is added to the player list
- ✅ Player count unchanged

**Part B: Whitespace Only Name Error**

**Steps:**
5. In the same dialog, enter only spaces: `   ` (three spaces)
6. Click "Add Player" button

**Expected Results:**
- ✅ Error message appears: "Please enter a name"
- ✅ Dialog remains open
- ✅ No player is added

**Part C: Error Clears on Valid Input**

**Steps:**
7. Enter a valid name: `Valid Player`
8. Observe the error message behavior
9. Click "Add Player" button

**Expected Results:**
- ✅ Error message disappears when typing begins
- ✅ Dialog closes after clicking "Add Player"
- ✅ Player "Valid Player" is added successfully
- ✅ Player "Valid Player" is automatically selected
- ✅ Player appears in available players section

**Pass/Fail:** ___________

**Notes:** ___________________________________________________________

---

### Test 4 (Bonus): Cancel Button Behavior

**Objective:** Verify that Cancel button discards changes without saving

**Steps:**
1. Click "Add New Player" button
2. Enter player name: `Cancelled Player`
3. Optionally select a photo
4. Click "Cancel" button

**Expected Results:**
- ✅ Dialog closes
- ✅ Player "Cancelled Player" is NOT added to player list
- ✅ No changes to player count
- ✅ No changes to selected players

**Pass/Fail:** ___________

**Notes:** ___________________________________________________________

---

## Test Execution Record

**Test Date:** ___________
**Tester:** ___________
**App Version/Commit:** ___________
**Platform:** Web (Chrome) / iOS / Android

**Overall Result:** PASS / FAIL

**Issues Found:**
-
-
-

**Additional Comments:**




---

## Why These Tests Are Manual

These tests are kept manual because:
1. **Web-specific dependencies** - The Target Tag menu uses web-specific services (`dart:html`, `dart:js_util`) that complicate automated widget testing
2. **Platform-specific image picking** - Camera and gallery access requires platform-specific mocks
3. **Simple validation logic** - The dialog's validation is straightforward (empty name check)
4. **Low regression risk** - The underlying functionality (player creation, selection, persistence) is fully covered by 30 automated PlayerProvider tests
5. **Fast manual execution** - These 3 tests take ~2 minutes to execute manually vs. the complexity of setting up cross-platform widget test infrastructure

**Automated Coverage:** The core functionality tested by these manual tests is covered by automated tests:
- `test/providers/player_provider_test.dart` - Player CRUD operations, validation, persistence
- `test/screens/games/target_tag/target_tag_user_management_test.dart` - Player stats integration

**When to Run:** Before major releases, after UI changes to Target Tag menu, or when modifying the Add Player dialog component.
