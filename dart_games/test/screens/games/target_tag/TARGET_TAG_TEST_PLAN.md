# Target Tag Game - Detailed Test Plan for Automation

**Instructions:** Review each test and mark as either `APPROVED: Yes` or `APPROVED: No` with optional comments.

---

## Solo Mode Tests

### Test 1: Solo Mode - Basic Shield Building
**APPROVED:** Yes

**Comments:**

**Purpose:** Validate solo mode setup, basic dart scoring, and shield accumulation

**Setup:**
- Mode: Solo
- Players: 2
- Hero bonus: OFF
- Max Shields: 5
- Player 1: "Alice" - Target: 14
- Player 2: "Bob" - Target: 20

**Detailed Steps:**

| Step | Action | Expected Shields | Expected Announcements (in order) |
|------|--------|-----------------|-----------------------------------|
| 1 | Start game | Alice: 0, Bob: 0 | "Welcome to Target Tag! Fill those shields!" |
| 2 | Alice throws Single 14 | Alice: 1, Bob: 0 | "Alice, your turn", "Single 14", "1 shields" |
| 3 | Alice throws Double 14 | Alice: 3, Bob: 0 | "Double 14", "3 shields" |
| 4 | Alice throws Triple 14 | Alice: 5, Bob: 0 | "Triple 14", "JACKPOT! Alice is TAGGED IN!", "Remove your darts" (5 shields because you cannot go above max shields of 5) |
| 5 | Bob throws Single 20 | Alice: 5, Bob: 1 | "Bob, your turn", "Single 20", "1 shields" |
| 6 | Bob throws Double 20 | Alice: 5, Bob: 3 | "Double 20", "3 shields" |
| 7 | Bob throws Triple 20 | Alice: 5, Bob: 5 | "Triple 20", "JACKPOT! Bob is TAGGED IN!", "Remove your darts" (5 shields because you cannot go above max shields of 5) |
| 8 | Alice throws Single 14 | Alice: 5, Bob: 5 | "Alice, your turn", "Single 14" (5 shields because you cannot go above the max shields setting of 5) |

**Final Expected State:**
- Alice: 5 shields, TAGGED-IN
- Bob: 5 shields, TAGGED-IN
- Current turn: Alice (dart 2 of turn)
- No eliminations

---

### Test 2: Solo Mode - Reaching Tagged-In Status
**APPROVED:** Yes

**Comments:**

**Purpose:** Validate tagged-in status announcement and behavior

**Setup:**
- Mode: Solo
- Players: 2
- Hero bonus: OFF
- Max Shields: 5
- Player 1: "Alice" - Target: 14
- Player 2: "Bob" - Target: 20

**Detailed Steps:**

| Step | Action | Expected Shields | Expected Announcements (in order) |
|------|--------|-----------------|-----------------------------------|
| 1 | Start game | Alice: 0, Bob: 0 | "Welcome to Target Tag! Fill those shields!" |
| 2 | Alice throws Single 14 | Alice: 1, Bob: 0 | "Alice, your turn", "Single 14", "1 shields" |
| 3 | Alice throws Triple 14 | Alice: 4, Bob: 0 | "Triple 14", "4 shields" |
| 4 | Alice throws Single 14 | Alice: 5, Bob: 0 | "Single 14", "JACKPOT! Alice is TAGGED IN!", "Remove your darts" |
| 5 | Bob throws Single 20 | Alice: 5, Bob: 1 | "Bob, your turn", "Single 20", "1 shields" |
| 6 | Bob throws Double 20 | Alice: 5, Bob: 3 | "Double 20", "3 shields" |
| 7 | Bob throws Single 20 | Alice: 5, Bob: 4 | "Single 20", "4 shields", "Remove your darts" |

**Final Expected State:**
- Alice: 5 shields, TAGGED-IN
- Bob: 4 shields, NOT tagged-in
- Current turn: Alice
- No eliminations

---

### Test 3: Solo Mode - Successful Tag on Opponent
**APPROVED:** Yes

**Comments:**

**Purpose:** Validate hitting opponent target reduces their shields correctly

**Setup:**
- Mode: Solo
- Players: 2
- Hero bonus: OFF
- Max Shields: 5
- Player 1: "Alice" - Target: 14, Starting shields: 5 (tagged-in)
- Player 2: "Bob" - Target: 20, Starting shields: 3

**Detailed Steps:**

| Step | Action | Expected Shields | Expected Announcements (in order) |
|------|--------|-----------------|-----------------------------------|
| 1 | Game state initialized | Alice: 5, Bob: 3 | (none - starting mid-game) |
| 2 | Alice throws Single 20 | Alice: 5, Bob: 2 | "Alice, your turn", "Single 20", "Tag! Got 'em!" |
| 3 | Alice throws Double 20 | Alice: 5, Bob: 0 | "Double 20", "Tag! Got 'em!", "Bob is Tagged Out! Better luck next time!", "Remove your darts" |
| 4 | Game ends | Alice: 5, Bob: 0 (eliminated) | "GAME OVER! Alice is the Target Tag Champion!" |

**Final Expected State:**
- Alice: 5 shields, TAGGED-IN, Winner
- Bob: 0 shields, ELIMINATED
- Game Over: true
- Winner: Alice

---

### Test 4: Solo Mode - Low Shields Warning
**APPROVED:** Yes

**Comments:**

**Purpose:** Validate low shields warning when opponent drops to exactly 1 shield

**Setup:**
- Mode: Solo
- Players: 2
- Hero bonus: OFF
- Max Shields: 5
- Player 1: "Alice" - Target: 14, Starting shields: 5 (tagged-in)
- Player 2: "Bob" - Target: 20, Starting shields: 2

**Detailed Steps:**

| Step | Action | Expected Shields | Expected Announcements (in order) |
|------|--------|-----------------|-----------------------------------|
| 1 | Game state initialized | Alice: 5, Bob: 2 | (none - starting mid-game) |
| 2 | Alice throws Single 20 | Alice: 5, Bob: 1 | "Alice, your turn", "Single 20", "Tag! Got 'em!", "Warning! Bob's shield is almost gone!" |
| 3 | Alice throws Miss | Alice: 5, Bob: 1 | "Miss" |
| 4 | Alice throws Miss | Alice: 5, Bob: 1 | "Miss", "Remove your darts" |

**Final Expected State:**
- Alice: 5 shields, TAGGED-IN
- Bob: 1 shield, NOT tagged-in
- Current turn: Bob
- No eliminations

---

### Test 5: Solo Mode - Losing Tagged-In Status
**APPROVED:** Yes

**Comments:**

**Purpose:** Validate losing tagged-in status when shields drop below max

**Setup:**
- Mode: Solo
- Players: 3
- Hero bonus: OFF
- Max Shields: 5
- Player 1: "Alice" - Target: 14, Starting shields: 5 (tagged-in)
- Player 2: "Bob" - Target: 20, Starting shields: 5 (tagged-in)
- Player 3: "Carol" - Target: 17, Starting shields: 3

**Detailed Steps:**

| Step | Action | Expected Shields | Expected Announcements (in order) |
|------|--------|-----------------|-----------------------------------|
| 1 | Game state initialized | Alice: 5, Bob: 5, Carol: 3 | (none - starting mid-game) |
| 2 | Bob throws Single 14 | Alice: 4, Bob: 5, Carol: 3 | "Bob, your turn", "Single 14", "Tag! Got 'em!", "Shield compromised! Alice is back on the hunt." |
| 3 | Bob throws Double 17 | Alice: 4, Bob: 5, Carol: 1 | "Double 17", "Tag! Got 'em!", "Warning! Carol's shield is almost gone!" |
| 4 | Bob throws Miss | Alice: 4, Bob: 5, Carol: 1 | "Miss", "Remove your darts" |

**Final Expected State:**
- Alice: 4 shields, NOT tagged-in
- Bob: 5 shields, TAGGED-IN
- Carol: 1 shield, NOT tagged-in
- Current turn: Carol
- No eliminations

---

### Test 6: Solo Mode - Multiple Low Shield Warnings
**APPROVED:** Yes

**Comments:**

**Purpose:** Validate multiple warning announcements when multiple opponents drop to 1 shield

**Setup:**
- Mode: Solo
- Players: 3
- Hero bonus: OFF
- Max Shields: 5
- Player 1: "Alice" - Target: 14, Starting shields: 5 (tagged-in)
- Player 2: "Bob" - Target: 20, Starting shields: 2
- Player 3: "Carol" - Target: 17, Starting shields: 2

**Detailed Steps:**

| Step | Action | Expected Shields | Expected Announcements (in order) |
|------|--------|-----------------|-----------------------------------|
| 1 | Game state initialized | Alice: 5, Bob: 2, Carol: 2 | (none - starting mid-game) |
| 2 | Alice throws Single 20 | Alice: 5, Bob: 1, Carol: 2 | "Alice, your turn", "Single 20", "Tag! Got 'em!", "Warning! Bob's shield is almost gone!" |
| 3 | Alice throws Single 17 | Alice: 5, Bob: 1, Carol: 1 | "Single 17", "Tag! Got 'em!", "Warning! Carol's shield is almost gone!" |
| 4 | Alice throws Miss | Alice: 5, Bob: 1, Carol: 1 | "Miss", "Remove your darts" |

**Final Expected State:**
- Alice: 5 shields, TAGGED-IN
- Bob: 1 shield, NOT tagged-in
- Carol: 1 shield, NOT tagged-in
- Current turn: Bob
- No eliminations

---

### Test 7: Solo Mode - Miss Handling
**APPROVED:** Yes

**Comments:**

**Purpose:** Validate miss announcements and no shield changes

**Setup:**
- Mode: Solo
- Players: 2
- Hero bonus: OFF
- Max Shields: 5
- Player 1: "Alice" - Target: 14
- Player 2: "Bob" - Target: 20

**Detailed Steps:**

| Step | Action | Expected Shields | Expected Announcements (in order) |
|------|--------|-----------------|-----------------------------------|
| 1 | Start game | Alice: 0, Bob: 0 | "Welcome to Target Tag! Fill those shields!" |
| 2 | Alice throws Miss | Alice: 0, Bob: 0 | "Alice, your turn", "Miss" |
| 3 | Alice throws Miss | Alice: 0, Bob: 0 | "Miss" |
| 4 | Alice throws Miss | Alice: 0, Bob: 0 | "Miss", "Remove your darts" |
| 5 | Bob throws Miss | Alice: 0, Bob: 0 | "Bob, your turn", "Miss" |
| 6 | Bob throws Miss | Alice: 0, Bob: 0 | "Miss" |
| 7 | Bob throws Miss | Alice: 0, Bob: 0 | "Miss", "Remove your darts" |

**Final Expected State:**
- Alice: 0 shields, NOT tagged-in
- Bob: 0 shields, NOT tagged-in
- Current turn: Alice
- No eliminations

---

### Test 8: Solo Mode - Victory Condition
**APPROVED:** Yes

**Comments:**

**Purpose:** Validate game ends when only one player remains

**Setup:**
- Mode: Solo
- Players: 2
- Hero bonus: OFF
- Max Shields: 5
- Player 1: "Alice" - Target: 14, Starting shields: 5 (tagged-in)
- Player 2: "Bob" - Target: 20, Starting shields: 1

**Detailed Steps:**

| Step | Action | Expected Shields | Expected Announcements (in order) |
|------|--------|-----------------|-----------------------------------|
| 1 | Game state initialized | Alice: 5, Bob: 1 | (none - starting mid-game) |
| 2 | Alice throws Single 20 | Alice: 5, Bob: 0 | "Alice, your turn", "Single 20", "Tag! Got 'em!", "Bob is Tagged Out! Better luck next time!", "Remove your darts", "GAME OVER! Alice is the Target Tag Champion!" |

**Final Expected State:**
- Alice: 5 shields, TAGGED-IN, Winner
- Bob: 0 shields, ELIMINATED
- Game Over: true
- Winner: Alice

---

## Team Mode Tests

### Test 9: Team Mode Random - Basic Team Setup
**APPROVED:** Yes

**Comments:** Users on the same team have the same target and the same hero bonus because they are on the same team.

**Purpose:** Validate random team assignment and team shield accumulation

**Setup:**
- Mode: Team
- Players: 4
- Teams: 2 (assigned randomly)
- Hero bonus: OFF
- Max Shields: 5
- For automation: Pre-assign teams
  - Team 1: "Alice" (Target: 14), "Bob" (Target: 14)
  - Team 2: "Carol" (Target: 17), "Dave" (Target: 17)

**Detailed Steps:**

| Step | Action | Expected Individual Shields | Expected Team Shields | Expected Announcements (in order) |
|------|--------|----------------------------|----------------------|-----------------------------------|
| 1 | Start game | All: 0 | Team 1: 0, Team 2: 0 | "Welcome to Target Tag! Fill those shields!" |
| 2 | Alice throws Single 14 | Alice: 1, Bob: 1 | Team 1: 1, Team 2: 0 | "Alice, your turn", "Single 14", "1 shields" |
| 3 | Alice throws Double 14 | Alice: 3, Bob: 3 | Team 1: 3, Team 2: 0 | "Double 14", "3 shields" |
| 4 | Alice throws Single 14 | Alice: 4, Bob: 4 | Team 1: 4, Team 2: 0 | "Single 14", "4 shields", "Remove your darts" |
| 5 | Carol throws Single 17 | Carol: 1, Dave: 1 | Team 1: 4, Team 2: 1 | "Carol, your turn", "Single 17", "1 shields" |
| 6 | Carol throws Single 17 | Carol: 2, Dave: 2 | Team 1: 4, Team 2: 2 | "Single 17", "2 shields" |
| 7 | Carol throws Single 17 | Carol: 3, Dave: 3 | Team 1: 4, Team 2: 3 | "Single 17", "3 shields", "Remove your darts" |
| 8 | Bob throws Single 14 | Alice: 5, Bob: 5 | Team 1: 5, Team 2: 3 | "Bob, your turn", "Single 14", "JACKPOT! Alice and Bob are TAGGED IN!" |
| 9 | Bob throws Miss | Alice: 5, Bob: 5 | Team 1: 5, Team 2: 3 | "Miss" |
| 10 | Bob throws Miss | Alice: 5, Bob: 5 | Team 1: 5, Team 2: 3 | "Miss", "Remove your darts" |

**Final Expected State:**
- Team 1: 5 shields total (Alice: 5, Bob: 5), TAGGED-IN
- Team 2: 3 shields total (Carol: 3, Dave: 3), NOT tagged-in
- Current turn: Dave
- No eliminations

---

### Test 10: Team Mode Manual - Manual Team Assignment
**APPROVED:** Yes

**Comments:** Teams have a max number of players of 2. Users on the same team have the same target and the same hero bonus because they are on the same team.

**Purpose:** Validate manual team selection

**Setup:**
- Mode: Team
- Players: 6
- Teams: 3 (manually assigned)
- Hero bonus: OFF
- Max Shields: 5
- Team 1: "Alice" (Target: 14), "Bob" (Target: 14)
- Team 2: "Carol" (Target: 17), "Dave" (Target: 17)
- Team 3: "Eve" (Target: 18), "Frank" (Target: 18)

**Detailed Steps:**

| Step | Action | Expected Individual Shields | Expected Team Shields | Expected Announcements (in order) |
|------|--------|----------------------------|----------------------|-----------------------------------|
| 1 | Start game | All: 0 | Team 1: 0, Team 2: 0, Team 3: 0 | "Welcome to Target Tag! Fill those shields!" |
| 2 | Alice throws Single 14 | Alice: 1, Bob: 1 | Team 1: 1, Team 2: 0, Team 3: 0 | "Alice, your turn", "Single 14", "1 shields" |
| 3 | Alice throws Single 14 | Alice: 2, Bob: 2 | Team 1: 2, Team 2: 0, Team 3: 0 | "Single 14", "2 shields" |
| 4 | Alice throws Miss | Alice: 2, Bob: 2 | Team 1: 2, Team 2: 0, Team 3: 0 | "Miss", "Remove your darts" |
| 5 | Carol throws Single 17 | Carol: 1, Dave: 1 | Team 1: 2, Team 2: 1, Team 3: 0 | "Carol, your turn", "Single 17", "1 shields" |
| 6 | Carol throws Single 17 | Carol: 2, Dave: 2 | Team 1: 2, Team 2: 2, Team 3: 0 | "Single 17", "2 shields" |
| 7 | Carol throws Miss | Carol: 2, Dave: 2 | Team 1: 2, Team 2: 2, Team 3: 0 | "Miss", "Remove your darts" |
| 8 | Eve throws Triple 18 | Eve: 3, Frank: 3 | Team 1: 2, Team 2: 2, Team 3: 3 | "Eve, your turn", "Triple 18", "3 shields" |
| 9 | Eve throws Double 18 | Eve: 5, Frank: 5 | Team 1: 2, Team 2: 2, Team 3: 5 | "Double 18", "JACKPOT! Eve and Frank are TAGGED IN!" |
| 10 | Eve throws Miss | Eve: 5, Frank: 5 | Team 1: 2, Team 2: 2, Team 3: 5 | "Miss", "Remove your darts" |

**Final Expected State:**
- Team 1: 2 shields total (Alice: 2, Bob: 2), NOT tagged-in
- Team 2: 2 shields total (Carol: 2, Dave: 2), NOT tagged-in
- Team 3: 5 shields total (Eve: 5, Frank: 5), TAGGED-IN
- Current turn: Bob
- No eliminations

---

### Test 11: Team Mode - Team Reaching Tagged-In
**APPROVED:** Yes

**Comments:** Team members share same target. Both members' shields increase together.

**Purpose:** Validate team tagged-in status

**Setup:**
- Mode: Team
- Players: 4
- Teams: 2
- Hero bonus: OFF
- Max Shields: 5
- Team 1: "Alice" (Target: 14), "Bob" (Target: 14)
- Team 2: "Carol" (Target: 17), "Dave" (Target: 17)

**Detailed Steps:**

| Step | Action | Expected Individual Shields | Expected Team Shields | Expected Announcements (in order) |
|------|--------|----------------------------|----------------------|-----------------------------------|
| 1 | Start game | All: 0 | Team 1: 0, Team 2: 0 | "Welcome to Target Tag! Fill those shields!" |
| 2 | Alice throws Triple 14 | Alice: 3, Bob: 3 | Team 1: 3, Team 2: 0 | "Alice, your turn", "Triple 14", "3 shields" |
| 3 | Alice throws Miss | Alice: 3, Bob: 3 | Team 1: 3, Team 2: 0 | "Miss" |
| 4 | Alice throws Miss | Alice: 3, Bob: 3 | Team 1: 3, Team 2: 0 | "Miss", "Remove your darts" |
| 5 | Carol throws Single 17 | Carol: 1, Dave: 1 | Team 1: 3, Team 2: 1 | "Carol, your turn", "Single 17", "1 shields" |
| 6 | Carol throws Miss | Carol: 1, Dave: 1 | Team 1: 3, Team 2: 1 | "Miss" |
| 7 | Carol throws Miss | Carol: 1, Dave: 1 | Team 1: 3, Team 2: 1 | "Miss", "Remove your darts" |
| 8 | Bob throws Double 14 | Alice: 5, Bob: 5 | Team 1: 5, Team 2: 1 | "Bob, your turn", "Double 14", "JACKPOT! Alice and Bob are TAGGED IN!" |
| 9 | Bob throws Miss | Alice: 5, Bob: 5 | Team 1: 5, Team 2: 1 | "Miss" |
| 10 | Bob throws Miss | Alice: 5, Bob: 5 | Team 1: 5, Team 2: 1 | "Miss", "Remove your darts" |

**Final Expected State:**
- Team 1: 5 shields total (Alice: 5, Bob: 5), TAGGED-IN
- Team 2: 1 shield total (Carol: 1, Dave: 1), NOT tagged-in
- Current turn: Dave
- No eliminations

---

### Test 12: Team Mode - Team Member Attacking Opponent
**APPROVED:** Yes

**Comments:** Team members share same target. When team is attacked, both members lose shields.

**Purpose:** Validate team members can attack when team is tagged-in

**Setup:**
- Mode: Team
- Players: 4
- Teams: 2
- Hero bonus: OFF
- Max Shields: 5
- Team 1: "Alice" (Target: 14), "Bob" (Target: 14), Starting shields: 5 (tagged-in) [Alice: 5, Bob: 5]
- Team 2: "Carol" (Target: 17), "Dave" (Target: 17), Starting shields: 3 [Carol: 3, Dave: 3]

**Detailed Steps:**

| Step | Action | Expected Individual Shields | Expected Team Shields | Expected Announcements (in order) |
|------|--------|----------------------------|----------------------|-----------------------------------|
| 1 | Game state initialized | Alice: 5, Bob: 5, Carol: 3, Dave: 3 | Team 1: 5, Team 2: 3 | (none - starting mid-game) |
| 2 | Alice throws Single 17 | Alice: 5, Bob: 5, Carol: 2, Dave: 2 | Team 1: 5, Team 2: 2 | "Alice, your turn", "Single 17", "Tag! Got 'em!" |
| 3 | Alice throws Single 17 | Alice: 5, Bob: 5, Carol: 1, Dave: 1 | Team 1: 5, Team 2: 1 | "Single 17", "Tag! Got 'em!", "Warning! Carol and Dave's shields are almost gone!" |
| 4 | Alice throws Miss | - | Team 1: 5, Team 2: 1 | "Miss", "Remove your darts" |
| 5 | Carol throws Single 14 | Alice: 5, Bob: 5, Carol: 1, Dave: 1 | Team 1: 5, Team 2: 1 | "Carol, your turn", "Single 14" (can't attack, not tagged-in) |
| 6 | Carol throws Miss | - | Team 1: 5, Team 2: 1 | "Miss" |
| 7 | Carol throws Miss | - | Team 1: 5, Team 2: 1 | "Miss", "Remove your darts" |
| 8 | Bob throws Single 17 | Alice: 5, Bob: 5, Carol: 0, Dave: 0 | Team 1: 5, Team 2: 0 | "Bob, your turn", "Single 17", "Tag! Got 'em!", "Carol and Dave are Tagged Out! Better luck next time!", "Remove your darts", "GAME OVER! Alice and Bob are the Target Tag Champions!" |

**Final Expected State:**
- Team 1: 5 shields total (Alice: 5, Bob: 5), TAGGED-IN, Winner
- Team 2: 0 shields total (Carol: 0 ELIMINATED, Dave: 0 ELIMINATED), ELIMINATED
- Game Over: true
- Winner: Team 1

---

### Test 13: Team Mode - Team Losing Tagged-In Status
**APPROVED:** Yes

**Comments:** Both team members lose shields when team is attacked. Team loses tagged-in when shields drop below max.

**Purpose:** Validate team loses tagged-in when total shields drop below max

**Setup:**
- Mode: Team
- Players: 4
- Teams: 2
- Hero bonus: OFF
- Max Shields: 5
- Team 1: "Alice" (Target: 14), "Bob" (Target: 14), Starting shields: 5 (tagged-in) [Alice: 5, Bob: 5]
- Team 2: "Carol" (Target: 17), "Dave" (Target: 17), Starting shields: 5 (tagged-in) [Carol: 5, Dave: 5]

**Detailed Steps:**

| Step | Action | Expected Individual Shields | Expected Team Shields | Expected Announcements (in order) |
|------|--------|----------------------------|----------------------|-----------------------------------|
| 1 | Game state initialized | Alice: 5, Bob: 5, Carol: 5, Dave: 5 | Team 1: 5, Team 2: 5 | (none - starting mid-game) |
| 2 | Alice throws Double 17 | Alice: 5, Bob: 5, Carol: 3, Dave: 3 | Team 1: 5, Team 2: 3 | "Alice, your turn", "Double 17", "Tag! Got 'em!", "Shield compromised! Carol and Dave are back on the hunt." |
| 3 | Alice throws Miss | - | Team 1: 5, Team 2: 3 | "Miss" |
| 4 | Alice throws Miss | - | Team 1: 5, Team 2: 3 | "Miss", "Remove your darts" |

**Final Expected State:**
- Team 1: 5 shields total (Alice: 5, Bob: 5), TAGGED-IN
- Team 2: 3 shields total (Carol: 3, Dave: 3), NOT tagged-in
- Current turn: Carol
- No eliminations

---

### Test 14: Team Mode - Team Elimination
**APPROVED:** Yes

**Comments:** When a team's shields reach 0, all members are eliminated.

**Purpose:** Validate team elimination when all members eliminated

**Setup:**
- Mode: Team
- Players: 4
- Teams: 2
- Hero bonus: OFF
- Max Shields: 5
- Team 1: "Alice" (Target: 14), "Bob" (Target: 14), Starting shields: 5 (tagged-in) [Alice: 5, Bob: 5]
- Team 2: "Carol" (Target: 17), "Dave" (Target: 17), Starting shields: 2 [Carol: 2, Dave: 2]

**Detailed Steps:**

| Step | Action | Expected Individual Shields | Expected Team Shields | Expected Announcements (in order) |
|------|--------|----------------------------|----------------------|-----------------------------------|
| 1 | Game state initialized | Alice: 5, Bob: 5, Carol: 2, Dave: 2 | Team 1: 5, Team 2: 2 | (none - starting mid-game) |
| 2 | Alice throws Double 17 | Alice: 5, Bob: 5, Carol: 0, Dave: 0 | Team 1: 5, Team 2: 0 | "Alice, your turn", "Double 17", "Tag! Got 'em!", "Carol and Dave are Tagged Out! Better luck next time!", "Remove your darts", "GAME OVER! Alice and Bob are the Target Tag Champions!" |

**Final Expected State:**
- Team 1: 5 shields total (Alice: 5, Bob: 5), TAGGED-IN, Winner
- Team 2: 0 shields total (Carol: 0 ELIMINATED, Dave: 0 ELIMINATED), ELIMINATED
- Game Over: true
- Winner: Team 1

---

## Hero Bonus Tests

### Test 15: Solo Mode - Hero Bonus Enabled
**APPROVED:** Yes

**Comments:** Hero bonus automatically fills shields to max when hit (not tagged-in).

**Purpose:** Validate hero bonus fills shields to max

**Setup:**
- Mode: Solo
- Players: 2
- Hero bonus: ON
- Max Shields: 5
- Player 1: "Alice" - Target: 14, Hero Bonus: D7 (Double 7)
- Player 2: "Bob" - Target: 20, Hero Bonus: T13 (Triple 13)

**Detailed Steps:**

| Step | Action | Expected Shields | Expected Announcements (in order) |
|------|--------|-----------------|-----------------------------------|
| 1 | Start game | Alice: 0, Bob: 0 | "Welcome to Target Tag! Fill those shields!" |
| 2 | Alice throws Single 14 | Alice: 1, Bob: 0 | "Alice, your turn", "Single 14", "1 shields" |
| 3 | Alice throws Double 7 | Alice: 5, Bob: 0 | "Double 7", "JACKPOT! Alice is TAGGED IN!", "Bob is Tagged Out! Better luck next time!", "Remove your darts", "GAME OVER! Alice is the Target Tag Champion!" (hero bonus hit, already at max - no shield announcement, Bob loses 1→ eliminated) |

**Final Expected State:**
- Alice: 5 shields, TAGGED-IN, Winner
- Bob: 0 shields, ELIMINATED
- Game Over: true
- Winner: Alice

---

### Test 16: Solo Mode - Hero Bonus Attack While Tagged-In
**APPROVED:** Yes

**Comments:** Hitting hero bonus while tagged-in reduces all opponents' shields by 1.

**Purpose:** Validate hitting hero bonus while tagged-in reduces all opponents' shields by 1

**Setup:**
- Mode: Solo
- Players: 3
- Hero bonus: ON
- Max Shields: 5
- Player 1: "Alice" - Target: 14, Hero Bonus: D7 (Double 7), Starting shields: 5 (tagged-in)
- Player 2: "Bob" - Target: 20, Hero Bonus: T13 (Triple 13), Starting shields: 3
- Player 3: "Carol" - Target: 17, Hero Bonus: D18 (Double 18), Starting shields: 4

**Detailed Steps:**

| Step | Action | Expected Shields | Expected Announcements (in order) |
|------|--------|-----------------|-----------------------------------|
| 1 | Game state initialized | Alice: 5, Bob: 3, Carol: 4 | (none - starting mid-game) |
| 2 | Alice throws Double 7 | Alice: 5, Bob: 2, Carol: 3 | "Alice, your turn", "Double 7", "Tag! Got 'em!" (hero bonus hit, already at max, both opponents lose 1) |
| 3 | Alice throws Double 7 | Alice: 5, Bob: 1, Carol: 2 | "Double 7", "Tag! Got 'em!", "Warning! Bob's shield is almost gone!" (hero bonus hit again, both opponents lose 1) |
| 4 | Alice throws Miss | Alice: 5, Bob: 1, Carol: 2 | "Miss", "Remove your darts" |

**Final Expected State:**
- Alice: 5 shields, TAGGED-IN
- Bob: 1 shield, NOT tagged-in
- Carol: 2 shields, NOT tagged-in
- Current turn: Bob
- No eliminations

---

### Test 17: Team Mode - Hero Bonus Attack
**APPROVED:** Yes

**Comments:** Hero bonus in team mode. When tagged-in team hits hero bonus, each opposing team loses 1 shield.

**Purpose:** Validate hero bonus in team mode reduces all opponent teams by 1

**Setup:**
- Mode: Team
- Players: 6
- Teams: 3
- Hero bonus: ON
- Max Shields: 5
- Team 1: "Alice" (Target: 14), "Bob" (Target: 14), Hero Bonus: T7 (Triple 7), Starting shields: 5 (tagged-in) [Alice: 5, Bob: 5]
- Team 2: "Carol" (Target: 17), "Dave" (Target: 17), Hero Bonus: D19 (Double 19), Starting shields: 3 [Carol: 3, Dave: 3]
- Team 3: "Eve" (Target: 18), "Frank" (Target: 18), Hero Bonus: D16 (Double 16), Starting shields: 4 [Eve: 4, Frank: 4]

**Detailed Steps:**

| Step | Action | Expected Individual Shields | Expected Team Shields | Expected Announcements (in order) |
|------|--------|----------------------------|----------------------|-----------------------------------|
| 1 | Game state initialized | Alice: 5, Bob: 5, Carol: 3, Dave: 3, Eve: 4, Frank: 4 | T1: 5, T2: 3, T3: 4 | (none - starting mid-game) |
| 2 | Alice throws Triple 7 | Alice: 5, Bob: 5, Carol: 2, Dave: 2, Eve: 3, Frank: 3 | T1: 5, T2: 2, T3: 3 | "Alice, your turn", "Triple 7", "Tag! Got 'em!" (hero bonus hit, already at max, each opposing team loses 1) |
| 3 | Alice throws Triple 7 | Alice: 5, Bob: 5, Carol: 1, Dave: 1, Eve: 2, Frank: 2 | T1: 5, T2: 1, T3: 2 | "Triple 7", "Tag! Got 'em!", "Warning! Carol and Dave's shields are almost gone!" (hero bonus hit again, each opposing team loses 1) |
| 4 | Alice throws Miss | - | - | "Miss", "Remove your darts" |

**Final Expected State:**
- Team 1: 5 shields total (Alice: 5, Bob: 5), TAGGED-IN
- Team 2: 1 shield total (Carol: 1, Dave: 1), NOT tagged-in
- Team 3: 2 shields total (Eve: 2, Frank: 2), NOT tagged-in
- Current turn: Carol
- No eliminations

---

## Turn Management Tests

### Test 18: Skip Player Turn
**APPROVED:** Yes

**Comments:**

**Purpose:** Validate skipping a player's turn works correctly

**Setup:**
- Mode: Solo
- Players: 3
- Hero bonus: OFF
- Max Shields: 5
- Player 1: "Alice" - Target: 14
- Player 2: "Bob" - Target: 20
- Player 3: "Carol" - Target: 17

**Detailed Steps:**

| Step | Action | Expected Shields | Expected Announcements (in order) |
|------|--------|-----------------|-----------------------------------|
| 1 | Start game | Alice: 0, Bob: 0, Carol: 0 | "Welcome to Target Tag! Fill those shields!" |
| 2 | Skip Alice's turn | Alice: 0, Bob: 0, Carol: 0 | (no announcements) |
| 3 | Bob throws Single 20 | Alice: 0, Bob: 1, Carol: 0 | "Bob, your turn", "Single 20", "1 shields" |
| 4 | Bob throws Miss | Alice: 0, Bob: 1, Carol: 0 | "Miss" |
| 5 | Bob throws Miss | Alice: 0, Bob: 1, Carol: 0 | "Miss", "Remove your darts" |
| 6 | Carol throws Single 17 | Alice: 0, Bob: 1, Carol: 1 | "Carol, your turn", "Single 17", "1 shields" |
| 7 | Carol throws Miss | Alice: 0, Bob: 1, Carol: 1 | "Miss" |
| 8 | Carol throws Miss | Alice: 0, Bob: 1, Carol: 1 | "Miss", "Remove your darts" |
| 9 | Alice throws Single 14 | Alice: 1, Bob: 1, Carol: 1 | "Alice, your turn", "Single 14", "1 shields" |

**Final Expected State:**
- Alice: 1 shield, NOT tagged-in
- Bob: 1 shield, NOT tagged-in
- Carol: 1 shield, NOT tagged-in
- Current turn: Alice (dart 2 of turn)
- No eliminations

---

### Test 19: Skip Multiple Turns in Sequence
**APPROVED:** Yes

**Comments:**

**Purpose:** Validate skipping multiple consecutive turns

**Setup:**
- Mode: Solo
- Players: 4
- Hero bonus: OFF
- Max Shields: 5
- Player 1: "Alice" - Target: 14
- Player 2: "Bob" - Target: 20
- Player 3: "Carol" - Target: 17
- Player 4: "Dave" - Target: 19

**Detailed Steps:**

| Step | Action | Expected Shields | Expected Announcements (in order) |
|------|--------|-----------------|-----------------------------------|
| 1 | Start game | All: 0 | "Welcome to Target Tag! Fill those shields!" |
| 2 | Skip Alice's turn | All: 0 | (no announcements) |
| 3 | Skip Bob's turn | All: 0 | (no announcements) |
| 4 | Carol throws Triple 17 | Carol: 3 | "Carol, your turn", "Triple 17", "3 shields" |
| 5 | Carol throws Miss | Carol: 3 | "Miss" |
| 6 | Carol throws Miss | Carol: 3 | "Miss", "Remove your darts" |
| 7 | Skip Dave's turn | All same | (no announcements) |
| 8 | Alice throws Double 14 | Alice: 2 | "Alice, your turn", "Double 14", "2 shields" |

**Final Expected State:**
- Alice: 2 shields, NOT tagged-in
- Bob: 0 shields, NOT tagged-in
- Carol: 3 shields, NOT tagged-in
- Dave: 0 shields, NOT tagged-in
- Current turn: Alice (dart 2 of turn)
- No eliminations

---

## Edit Score Tests

### Test 20: Edit Score - Add Shields
**APPROVED:** Yes

**Comments:** Max shields applies during edit score.

**Purpose:** Validate manually adding shields through edit score

**Setup:**
- Mode: Solo
- Players: 2
- Hero bonus: OFF
- Max Shields: 5
- Player 1: "Alice" - Target: 14, Starting shields: 2
- Player 2: "Bob" - Target: 20, Starting shields: 0

**Detailed Steps:**

| Step | Action | Expected Shields | Expected Announcements (in order) |
|------|--------|-----------------|-----------------------------------|
| 1 | Game state initialized | Alice: 2, Bob: 0 | (none - starting mid-game) |
| 2 | Edit Alice's score: Add Single 14 | Alice: 3, Bob: 0 | "Single 14", "3 shields" |
| 3 | Edit Alice's score: Add Double 14 | Alice: 5, Bob: 0 | "Double 14", "JACKPOT! Alice is TAGGED IN!" |
| 4 | Edit Alice's score: Add Triple 14 | Alice: 5, Bob: 0 | "Triple 14" (capped at max - no shield announcement) |

**Final Expected State:**
- Alice: 5 shields, TAGGED-IN
- Bob: 0 shields, NOT tagged-in
- Turn state: unchanged
- No eliminations

---

### Test 21: Edit Score - Add Opponent Attacks
**APPROVED:** Yes

**Comments:** This test only works if you are editing the 3 different dart throws for Alice on her turn. If you are repeatedly editing the same dart throw, then it would revert score changes for the other players. Make sure to have simulated 3 dart throws for Alice before you initiate step 2 of this test and that you are editing different dart throws for steps 2 and 3.

**Purpose:** Validate editing to add opponent attacks

**Setup:**
- Mode: Solo
- Players: 3
- Hero bonus: OFF
- Max Shields: 5
- Player 1: "Alice" - Target: 14, Starting shields: 5 (tagged-in)
- Player 2: "Bob" - Target: 20, Starting shields: 4
- Player 3: "Carol" - Target: 17, Starting shields: 3

**Detailed Steps:**

| Step | Action | Expected Shields | Expected Announcements (in order) |
|------|--------|-----------------|-----------------------------------|
| 1 | Game state initialized | Alice: 5, Bob: 4, Carol: 3 | (none - starting mid-game) |
| 2 | Edit Alice's score: Add Single 20 | Alice: 5, Bob: 3, Carol: 3 | "Single 20", "Tag! Got 'em!" |
| 3 | Edit Alice's score: Add Double 17 | Alice: 5, Bob: 3, Carol: 1 | "Double 17", "Tag! Got 'em!", "Warning! Carol's shield is almost gone!" |

**Final Expected State:**
- Alice: 5 shields, TAGGED-IN
- Bob: 3 shields, NOT tagged-in
- Carol: 1 shield, NOT tagged-in
- Turn state: unchanged
- No eliminations

---

### Test 22: Edit Score - Trigger Multiple Announcement Types
**APPROVED:** Yes

**Comments:** This test only works if you are editing the 3 different dart throws for Bob on his turn. If you are repeatedly editing the same dart throw, then it would revert score changes for the other players. Make sure to have simulated 3 dart throws for Bob before you initiate step 2 of this test and that you are editing different dart throws for steps 2, 3 and 4.

**Purpose:** Validate complex edit with multiple announcement types

**Setup:**
- Mode: Solo
- Players: 3
- Hero bonus: OFF
- Max Shields: 5
- Player 1: "Alice" - Target: 14, Starting shields: 4
- Player 2: "Bob" - Target: 20, Starting shields: 5 (tagged-in)
- Player 3: "Carol" - Target: 17, Starting shields: 2

**Detailed Steps:**

| Step | Action | Expected Shields | Expected Announcements (in order) |
|------|--------|-----------------|-----------------------------------|
| 1 | Game state initialized | Alice: 4, Bob: 5, Carol: 2 | (none - starting mid-game) |
| 2 | Edit Bob's score: Add Single 17 | Alice: 4, Bob: 5, Carol: 1 | "Single 17", "Tag! Got 'em!", "Warning! Carol's shield is almost gone!" |
| 3 | Edit Bob's score: Add Single 14 | Alice: 3, Bob: 5, Carol: 1 | "Single 14", "Tag! Got 'em!" |
| 4 | Edit Bob's score: Add Single 17 | Alice: 3, Bob: 5, Carol: 0 | "Single 17", "Tag! Got 'em!", "Carol is Tagged Out! Better luck next time!" |

**Final Expected State:**
- Alice: 3 shields, NOT tagged-in
- Bob: 5 shields, TAGGED-IN
- Carol: 0 shields, ELIMINATED
- Turn state: unchanged
- Carol eliminated

---

### Test 23: Edit Score - Remove Shields (Undo)
**APPROVED:** Yes

**Comments:** Update this test with what you observe from the announcements when you edit this score.

**Purpose:** Validate removing incorrectly entered darts

**Setup:**
- Mode: Solo
- Players: 2
- Hero bonus: OFF
- Max Shields: 5
- Player 1: "Alice" - Target: 14, Starting shields: 5 (from: Single 14, Triple 14, Single 14)
- Player 2: "Bob" - Target: 20, Starting shields: 0

**Detailed Steps:**

| Step | Action | Expected Shields | Expected Announcements (in order) |
|------|--------|-----------------|-----------------------------------|
| 1 | Game state initialized | Alice: 5, Bob: 0 | (none - starting mid-game) |
| 2 | Edit Alice's score: Remove Single 14 | Alice: 4, Bob: 0 | (announcements may replay or none) |
| 3 | Edit Alice's score: Remove Triple 14 | Alice: 1, Bob: 0 | (announcements may replay or none) |

**Final Expected State:**
- Alice: 1 shield, NOT tagged-in (lost tagged-in status)
- Bob: 0 shields, NOT tagged-in
- Turn state: unchanged
- No eliminations

**Note:** Need to clarify if announcements replay when recalculating from edit, or if edit is silent.

---

### Test 24: Edit Score - Team Mode Shield Adjustment
**APPROVED:** Yes

**Comments:** Team members share shields. Both members affected by edit. This test only works if you are editing the 3 different dart throws for Alice on her turn. If you are repeatedly editing the same dart throw, then it would revert score changes for the other players. Make sure to have simulated 3 dart throws for Alice before you initiate step 2 of this test and that you are editing different dart throws for steps 2 and 3.

**Purpose:** Validate edit score affects team shields correctly

**Setup:**
- Mode: Team
- Players: 4
- Teams: 2
- Hero bonus: OFF
- Max Shields: 5
- Team 1: "Alice" (Target: 14), "Bob" (Target: 14), Starting shields: 4 [Alice: 4, Bob: 4]
- Team 2: "Carol" (Target: 17), "Dave" (Target: 17), Starting shields: 3 [Carol: 3, Dave: 3]

**Detailed Steps:**

| Step | Action | Expected Individual Shields | Expected Team Shields | Expected Announcements (in order) |
|------|--------|----------------------------|----------------------|-----------------------------------|
| 1 | Game state initialized | Alice: 4, Bob: 4, Carol: 3, Dave: 3 | Team 1: 4, Team 2: 3 | (none - starting mid-game) |
| 2 | Edit Alice's score: Add Single 14 | Alice: 5, Bob: 5 | Team 1: 5, Team 2: 3 | "Single 14", "JACKPOT! Alice and Bob are TAGGED IN!" |
| 3 | Edit Alice's score: Add Single 14 | Alice: 5, Bob: 5 | Team 1: 5, Team 2: 3 | "Single 14" (capped at max - no shield announcement) |

**Final Expected State:**
- Team 1: 5 shields total (Alice: 5, Bob: 5), TAGGED-IN
- Team 2: 3 shields total (Carol: 3, Dave: 3), NOT tagged-in
- Turn state: unchanged
- No eliminations

---

## Edge Case Tests

### Test 25: Multiple Players Tagged-In Simultaneously
**APPROVED:** Yes

**Comments:**

**Purpose:** Validate behavior when multiple players are tagged-in

**Setup:**
- Mode: Solo
- Players: 4
- Hero bonus: OFF
- Max Shields: 5
- Player 1: "Alice" - Target: 14, Starting shields: 5 (tagged-in)
- Player 2: "Bob" - Target: 20, Starting shields: 5 (tagged-in)
- Player 3: "Carol" - Target: 17, Starting shields: 3
- Player 4: "Dave" - Target: 19, Starting shields: 4

**Detailed Steps:**

| Step | Action | Expected Shields | Expected Announcements (in order) |
|------|--------|-----------------|-----------------------------------|
| 1 | Game state initialized | Alice: 5, Bob: 5, Carol: 3, Dave: 4 | (none - starting mid-game) |
| 2 | Alice throws Single 20 | Alice: 5, Bob: 4, Carol: 3, Dave: 4 | "Alice, your turn", "Single 20", "Tag! Got 'em!", "Shield compromised! Bob is back on the hunt." |
| 3 | Alice throws Single 17 | Alice: 5, Bob: 4, Carol: 2, Dave: 4 | "Single 17", "Tag! Got 'em!" |
| 4 | Alice throws Miss | - | "Miss", "Remove your darts" |
| 5 | Bob throws Single 14 | Alice: 4, Bob: 4, Carol: 2, Dave: 4 | "Bob, your turn", "Single 14" (Bob is NOT tagged-in anymore, can't attack) |
| 6 | Bob throws Miss | - | "Miss" |
| 7 | Bob throws Miss | - | "Miss", "Remove your darts" |

**Final Expected State:**
- Alice: 5 shields, TAGGED-IN
- Bob: 4 shields, NOT tagged-in
- Carol: 2 shields, NOT tagged-in
- Dave: 4 shields, NOT tagged-in
- Current turn: Carol
- No eliminations

---

### Test 26: Simultaneous Eliminations (Team Mode with Hero Bonus)
**APPROVED:** Yes

**Comments:** Hero bonus reduces opponent team by 1 shield. Multiple hero bonus hits can eliminate.

**Purpose:** Validate eliminating opponent team with multiple hero bonus hits

**Setup:**
- Mode: Team
- Players: 4
- Teams: 2
- Hero bonus: ON
- Max Shields: 5
- Team 1: "Alice" (Target: 14), "Bob" (Target: 14), Hero Bonus: T7 (Triple 7), Starting shields: 5 (tagged-in) [Alice: 5, Bob: 5]
- Team 2: "Carol" (Target: 17), "Dave" (Target: 17), Hero Bonus: D18 (Double 18), Starting shields: 1 [Carol: 1, Dave: 1]

**Detailed Steps:**

| Step | Action | Expected Individual Shields | Expected Team Shields | Expected Announcements (in order) |
|------|--------|----------------------------|----------------------|-----------------------------------|
| 1 | Game state initialized | Alice: 5, Bob: 5, Carol: 1, Dave: 1 | Team 1: 5, Team 2: 1 | (none - starting mid-game) |
| 2 | Alice throws Triple 7 | Alice: 5, Bob: 5, Carol: 0, Dave: 0 | Team 1: 5, Team 2: 0 | "Alice, your turn", "Triple 7", "Tag! Got 'em!", "Carol and Dave are Tagged Out! Better luck next time!", "Remove your darts", "GAME OVER! Alice and Bob are the Target Tag Champions!" (hero bonus hit, already at max - no shield announcement, team 2 loses 1→both eliminated) |

**Final Expected State:**
- Team 1: 5 shields total (Alice: 5, Bob: 5), TAGGED-IN, Winner
- Team 2: 0 shields total (Carol: 0 ELIMINATED, Dave: 0 ELIMINATED), ELIMINATED
- Game Over: true
- Winner: Team 1

---

### Test 27: Regaining Tagged-In Status
**APPROVED:** Yes

**Comments:**

**Purpose:** Validate player can regain tagged-in after losing it

**Setup:**
- Mode: Solo
- Players: 2
- Hero bonus: OFF
- Max Shields: 5
- Player 1: "Alice" - Target: 14, Starting shields: 5 (tagged-in)
- Player 2: "Bob" - Target: 20, Starting shields: 5 (tagged-in)

**Detailed Steps:**

| Step | Action | Expected Shields | Expected Announcements (in order) |
|------|--------|-----------------|-----------------------------------|
| 1 | Game state initialized | Alice: 5, Bob: 5 | (none - starting mid-game) |
| 2 | Bob throws Single 14 | Alice: 4, Bob: 5 | "Bob, your turn", "Single 14", "Tag! Got 'em!", "Shield compromised! Alice is back on the hunt." |
| 3 | Bob throws Miss | Alice: 4, Bob: 5 | "Miss" |
| 4 | Bob throws Miss | Alice: 4, Bob: 5 | "Miss", "Remove your darts" |
| 5 | Alice throws Single 14 | Alice: 5, Bob: 5 | "Alice, your turn", "Single 14", "JACKPOT! Alice is TAGGED IN!" |
| 6 | Alice throws Miss | Alice: 5, Bob: 5 | "Miss" |
| 7 | Alice throws Miss | Alice: 5, Bob: 5 | "Miss", "Remove your darts" |

**Final Expected State:**
- Alice: 5 shields, TAGGED-IN
- Bob: 5 shields, TAGGED-IN
- Current turn: Bob
- No eliminations

---

### Test 28: All Bullseye Round (Hero Bonus ON)
**APPROVED:** Yes

**Comments:** Hero bonus fills shields to max on first hit AND attacks all opponents when becoming tagged-in. Since Bob starts at 0 shields, he is eliminated immediately.

**Purpose:** Validate rapid shield building with hero bonus and immediate elimination

**Setup:**
- Mode: Solo
- Players: 2
- Hero bonus: ON
- Max Shields: 5
- Player 1: "Alice" - Target: 14, Hero Bonus: T13 (Triple 13)
- Player 2: "Bob" - Target: 20, Hero Bonus: D7 (Double 7)

**Detailed Steps:**

| Step | Action | Expected Shields | Expected Announcements (in order) |
|------|--------|-----------------|-----------------------------------|
| 1 | Start game | Alice: 0, Bob: 0 | "Welcome to Target Tag! Fill those shields!" |
| 2 | Alice throws Triple 13 | Alice: 5, Bob: 0 (eliminated) | "Alice, your turn", "Triple 13", "JACKPOT! Alice is TAGGED IN!", "Bob is Tagged Out! Better luck next time!", "Remove your darts", "GAME OVER! Alice is the Target Tag Champion!" (hero bonus fills shields to max, becomes tagged-in, attacks Bob reducing him by 1, eliminating him immediately and winning the game) |

**Final Expected State:**
- Alice: 5 shields, TAGGED-IN, Winner
- Bob: 0 shields, ELIMINATED
- Game Over: true
- Winner: Alice

---

### Test 29: Ten Player Solo Game
**APPROVED:** Yes

**Comments:** Maximum 10 players allowed.

**Purpose:** Validate maximum player count in solo mode

**Setup:**
- Mode: Solo
- Players: 10
- Hero bonus: OFF
- Max Shields: 5
- Player 1: "Alice" - Target: 14
- Player 2: "Bob" - Target: 20
- Player 3: "Carol" - Target: 17
- Player 4: "Dave" - Target: 19
- Player 5: "Eve" - Target: 18
- Player 6: "Frank" - Target: 16
- Player 7: "Grace" - Target: 15
- Player 8: "Hank" - Target: 13
- Player 9: "Ivy" - Target: 12
- Player 10: "Jack" - Target: 11

**Detailed Steps:**

| Step | Action | Expected Shields | Expected Announcements (in order) |
|------|--------|-----------------|-----------------------------------|
| 1 | Start game | All: 0 | "Welcome to Target Tag! Fill those shields!" |
| 2 | Alice throws Single 14 | Alice: 1, others: 0 | "Alice, your turn", "Single 14", "1 shields" |
| 3 | Alice throws Miss | Alice: 1 | "Miss" |
| 4 | Alice throws Miss | Alice: 1 | "Miss", "Remove your darts" |
| 5 | Bob throws Single 20 | Bob: 1, others same | "Bob, your turn", "Single 20", "1 shields" |
| 6 | Bob throws Miss | Bob: 1 | "Miss" |
| 7 | Bob throws Miss | Bob: 1 | "Miss", "Remove your darts" |
| ... | (Continue for all players) | Each +1 shield | (Similar pattern) |
| 30 | Jack throws Single 11 | Jack: 1 | "Jack, your turn", "Single 11", "1 shields" |
| 31 | Jack throws Miss | Jack: 1 | "Miss" |
| 32 | Jack throws Miss | Jack: 1 | "Miss", "Remove your darts" |
| 33 | Turn cycles back to Alice | - | "Alice, your turn" |

**Final Expected State:**
- All players: 1 shield each, NOT tagged-in
- Current turn: Alice (new round)
- No eliminations
- Turn order cycles correctly

---

### Test 30: Five Teams with Two Members Each
**APPROVED:** Yes

**Comments:** Maximum 10 players, max 2 per team. Team members share same target.

**Purpose:** Validate maximum teams with 2 members each

**Setup:**
- Mode: Team
- Players: 10
- Teams: 5
- Hero bonus: OFF
- Max Shields: 5
- Team 1: "Alice" (Target: 14), "Bob" (Target: 14)
- Team 2: "Carol" (Target: 17), "Dave" (Target: 17)
- Team 3: "Eve" (Target: 18), "Frank" (Target: 18)
- Team 4: "Grace" (Target: 15), "Hank" (Target: 15)
- Team 5: "Ivy" (Target: 12), "Jack" (Target: 12)

**Detailed Steps:**

| Step | Action | Expected Individual Shields | Expected Team Shields | Expected Announcements (in order) |
|------|--------|----------------------------|----------------------|-----------------------------------|
| 1 | Start game | All: 0 | All teams: 0 | "Welcome to Target Tag! Fill those shields!" |
| 2 | Alice throws Single 14 | Alice: 1, Bob: 1 | Team 1: 1, others: 0 | "Alice, your turn", "Single 14", "1 shields" |
| 3 | Alice throws Miss | - | Same | "Miss" |
| 4 | Alice throws Miss | - | Same | "Miss", "Remove your darts" |
| 5 | Carol throws Single 17 | Carol: 1, Dave: 1 | Team 2: 1, others same | "Carol, your turn", "Single 17", "1 shields" |
| 6 | Carol throws Miss | - | Same | "Miss" |
| 7 | Carol throws Miss | - | Same | "Miss", "Remove your darts" |
| ... | (Continue for all teams) | Each team +1 | (Similar pattern) |
| 28 | Jack throws Single 12 | Ivy: 1, Jack: 1 | Team 5: 1 | "Jack, your turn", "Single 12", "1 shields" |
| 29 | Jack throws Miss | - | Same | "Miss" |
| 30 | Jack throws Miss | - | Same | "Miss", "Remove your darts" |
| 31 | Turn cycles to Alice | - | - | "Alice, your turn" |

**Final Expected State:**
- All teams: 1 shield each (all members: 1 shield each), NOT tagged-in
- Current turn: Alice (new round)
- No eliminations
- Turn order: Alice → Carol → Eve → Grace → Ivy → Bob → Dave → Frank → Hank → Jack → (cycles)

---

### Test 31: Solo Mode - Multiple Hero Bonus Attacks in Succession
**APPROVED:** Yes

**Comments:** Testing multiple consecutive hero bonus hits while tagged-in reduces all opponents by 1 each time.

**Purpose:** Validate multiple hero bonus attacks in a row correctly reduce all opponents' shields

**Setup:**
- Mode: Solo
- Players: 4
- Hero bonus: ON
- Max Shields: 5
- Player 1: "Alice" - Target: 14, Hero Bonus: T13 (Triple 13), Starting shields: 5 (tagged-in)
- Player 2: "Bob" - Target: 20, Hero Bonus: D7 (Double 7), Starting shields: 4
- Player 3: "Carol" - Target: 17, Hero Bonus: D19 (Double 19), Starting shields: 3
- Player 4: "Dave" - Target: 19, Hero Bonus: T16 (Triple 16), Starting shields: 2

**Detailed Steps:**

| Step | Action | Expected Shields | Expected Announcements (in order) |
|------|--------|-----------------|-----------------------------------|
| 1 | Game state initialized | Alice: 5, Bob: 4, Carol: 3, Dave: 2 | (none - starting mid-game) |
| 2 | Alice throws Triple 13 | Alice: 5, Bob: 3, Carol: 2, Dave: 1 | "Alice, your turn", "Triple 13", "Tag! Got 'em!", "Warning! Dave's shields are almost gone!" (hero bonus hit while tagged-in, all opponents lose 1) |
| 3 | Alice throws Triple 13 | Alice: 5, Bob: 2, Carol: 1, Dave: 0 | "Triple 13", "Tag! Got 'em!", "Dave is Tagged Out! Better luck next time!", "Warning! Carol's shields are almost gone!" (hero bonus hit again, all opponents lose 1, Dave eliminated) |
| 4 | Alice throws Triple 13 | Alice: 5, Bob: 1, Carol: 0 | "Triple 13", "Tag! Got 'em!", "Carol is Tagged Out! Better luck next time!", "Warning! Bob's shields are almost gone!", "Remove your darts" (hero bonus hit again, remaining opponents lose 1, Carol eliminated) |

**Final Expected State:**
- Alice: 5 shields, TAGGED-IN
- Bob: 1 shield, NOT tagged-in
- Carol: 0 shields, ELIMINATED
- Dave: 0 shields, ELIMINATED
- Current turn: Bob
- Game continues (Bob still alive)

---

### Test 32: Team Mode - Multiple Hero Bonus Attacks in Succession
**APPROVED:** Yes

**Comments:** Testing multiple consecutive hero bonus hits while tagged-in reduces all opponent teams by 1 each time.

**Purpose:** Validate multiple team hero bonus attacks in a row correctly reduce all opponent teams' shields

**Setup:**
- Mode: Team
- Players: 8
- Teams: 4
- Hero bonus: ON
- Max Shields: 5
- Team 1: "Alice" (Target: 14), "Bob" (Target: 14), Hero Bonus: T13 (Triple 13), Starting shields: 5 (tagged-in) [Alice: 5, Bob: 5]
- Team 2: "Carol" (Target: 17), "Dave" (Target: 17), Hero Bonus: D19 (Double 19), Starting shields: 4 [Carol: 4, Dave: 4]
- Team 3: "Eve" (Target: 18), "Frank" (Target: 18), Hero Bonus: D16 (Double 16), Starting shields: 3 [Eve: 3, Frank: 3]
- Team 4: "Grace" (Target: 15), "Hank" (Target: 15), Hero Bonus: T12 (Triple 12), Starting shields: 2 [Grace: 2, Hank: 2]

**Detailed Steps:**

| Step | Action | Expected Individual Shields | Expected Team Shields | Expected Announcements (in order) |
|------|--------|----------------------------|----------------------|-----------------------------------|
| 1 | Game state initialized | Alice: 5, Bob: 5, Carol: 4, Dave: 4, Eve: 3, Frank: 3, Grace: 2, Hank: 2 | T1: 5, T2: 4, T3: 3, T4: 2 | (none - starting mid-game) |
| 2 | Alice throws Triple 13 | Alice: 5, Bob: 5, Carol: 3, Dave: 3, Eve: 2, Frank: 2, Grace: 1, Hank: 1 | T1: 5, T2: 3, T3: 2, T4: 1 | "Alice, your turn", "Triple 13", "Tag! Got 'em!", "Warning! Grace and Hank's shields are almost gone!" (hero bonus hit while tagged-in, all opponent teams lose 1) |
| 3 | Alice throws Triple 13 | Alice: 5, Bob: 5, Carol: 2, Dave: 2, Eve: 1, Frank: 1, Grace: 0, Hank: 0 | T1: 5, T2: 2, T3: 1, T4: 0 | "Triple 13", "Tag! Got 'em!", "Grace and Hank are Tagged Out! Better luck next time!", "Warning! Eve and Frank's shields are almost gone!" (hero bonus hit again, all opponent teams lose 1, Team 4 eliminated) |
| 4 | Alice throws Triple 13 | Alice: 5, Bob: 5, Carol: 1, Dave: 1, Eve: 0, Frank: 0 | T1: 5, T2: 1, T3: 0 | "Triple 13", "Tag! Got 'em!", "Eve and Frank are Tagged Out! Better luck next time!", "Warning! Carol and Dave's shields are almost gone!", "Remove your darts" (hero bonus hit again, remaining opponent teams lose 1, Team 3 eliminated) |

**Final Expected State:**
- Team 1: 5 shields total (Alice: 5, Bob: 5), TAGGED-IN
- Team 2: 1 shield total (Carol: 1, Dave: 1), NOT tagged-in
- Team 3: 0 shields total (Eve: 0 ELIMINATED, Frank: 0 ELIMINATED), ELIMINATED
- Team 4: 0 shields total (Grace: 0 ELIMINATED, Hank: 0 ELIMINATED), ELIMINATED
- Current turn: Carol
- Game continues (Team 2 still alive)

---

## Summary
- **Total Tests: 32**
- **Solo Mode: 8 tests**
- **Team Mode: 6 tests**
- **Hero Bonus: 5 tests** (includes Tests 15, 16, 17, 31, 32)
- **Turn Management: 2 tests**
- **Edit Score: 5 tests**
- **Edge Cases: 6 tests**

---

## Automation Notes

**For automated testing, each test should:**

1. **Mock game setup** with exact player names, targets, starting shields, and max shields value
2. **Simulate dart throws** by calling `processDartThrow()` with specific sector strings (e.g., "Single 14", "Miss")
3. **Assert shield values** after each dart using provider getters
4. **Assert announcements** were queued in correct order using audio queue inspection
5. **Assert game state** (tagged-in status, eliminations, game over, winner)

**Key assertions needed:**
- `expect(provider.getShields(playerId), equals(expectedValue))`
- `expect(provider.isTaggedIn(playerId), equals(expectedBool))`
- `expect(provider.isEliminated(playerId), equals(expectedBool))`
- `expect(audioQueue.getQueuedAnnouncements(), containsInOrder([...]))`
- `expect(game.isGameOver, equals(expectedBool))`
- `expect(game.winner, equals(expectedPlayer/Team))`
