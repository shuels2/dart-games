# SFX > 1s tuning worksheet

Edit the **Start**, **End**, and **FadeOut(ms)** columns in place. Leave
**Game**, **Clip**, and **File(s)** alone (those identify the code line).
Then save and send the file back; I'll diff against the original and
update each `SoundEffectConfig` literal.

## Conventions

- `End` of `—` means today's config has `endSeconds: null` (the clip
  plays to the file's natural end). Replace `—` with a number to set
  an explicit end.
- `FadeOut(ms)` is the new field — 0 = hard stop (no fade), >0 = linear
  fade over the last N ms of the clip. Today every clip is 0.
- `Effective(s)` = `End − Start` when End is a number, else `File(s) − Start`.
  Don't edit this column; I'll recompute it from your edited Start/End.
- `File(s)` is the audio file's actual duration on disk (second-precision —
  a value of "5" means anywhere from 5.0 to 5.9s in reality).

## Table A — clips currently ≥ 2s effective duration

The obvious tuning candidates.

| #  | Game            | Clip            | Start | End   | FadeOut(ms) | Effective(s)        | File(s) | Asset / Notes |
|----|-----------------|-----------------|-------|-------|-------------|---------------------|---------|---------------|
| 1  | target_tag      | gameStart       | 0.0   | 4.0   | 1500        | 8.0                 | 14      | TargetTag-Magical.mp3 |
| 2  | lunar_lander    | victoryFanfare  | 0.5   | 4.0   | 1500        | 7.5                 | 9       | LunarLander-VictoryFanfare.mp3 |
| 3  | monster_mash    | gameStart       | 1.75  | 4.0   | 1500        | 7.25                | 14      | MonsterMash-Organ.mp3 — *user's symptom* |
| 4  | pirates_grid    | waveCrash       | 0.0   | 4.0   | 1500        | 5.0                 | **85**  | File is 85s, only 5s used |
| 5  | monster_mash    | turnStart       | 3.0   | 5.5   | 1500        | 4.5                 | 28      | MonsterMash-MonsterScream.mp3 — *every turn* |
| 6  | gladiator_arena | turnBell        | 0.0   | 2.0   | 1000        | 4.0                 | 5       | GladiatorArena-TurnBell.mp3 |
| 7  | tiki_golf       | victoryFanfare  | 7.0   | 11.0  | 1500        | 4.0                 | **123** | File is 2:03, only 4s used |
| 8  | clockwork_quest | victoryFanfare  | 0.0   | 3.5   | 1500        | 3.5                 | 3       | ClockworkQuest-Fanfare.mp3 |
| 9  | reef_royale     | reefLock        | 11.0  | 14.25 | 0           | 3.25                | 16      | ReefRoyale-Lock.mp3 |
| 10 | reef_royale     | victoryFanfare  | 5.8   | 8.9   | 0           | 3.1                 | 9       | ReefRoyale-Fanfare.mp3 |
| 11 | carnival_derby  | removeDarts     | 0.0   | 3.0   | 0           | 3.0                 | 7       | TargetTag-Swipe.mp3 — *announce disabled* |
| 12 | target_tag      | removeDarts     | 0.0   | 3.0   | 0           | 3.0                 | 7       | TargetTag-Swipe.mp3 — *announce disabled* |
| 13 | monster_mash    | removeDarts     | 0.0   | 3.0   | 0           | 3.0                 | 7       | TargetTag-Swipe.mp3 — *announce disabled* |
| 14 | reef_royale     | currentWhoosh   | 0.0   | 3.0   | 1500        | 3.0                 | 5       | ReefRoyale-RushingWater.mp3 |
| 15 | lunar_lander    | driftSound      | 1.0   | 4.0   | 1500        | 3.0                 | 12      | LunarLander-DriftSound.mp3 |
| 16 | target_tag      | bullseye        | 0.0   | 3.0   | 1500        | 11 (file)           | 11      | TargetTag-Choir.mp3 (FULL FILE) |
| 17 | carnival_derby  | bullseye        | 0.0   | 3.0   | 1500        | 11 (file)           | 11      | TargetTag-Choir.mp3 (FULL FILE) — same asset |
| 18 | carnival_derby  | horseraceStart  | 0.0   | 4.0   | 1500        | 9 (file)            | 9       | CarnivalDerby-HorseRace-Start.mp3 (FULL FILE) |
| 19 | carnival_derby  | gameComplete    | 0.0   | —     | 0           | 5 (file)            | 5       | CarnivalDerby-Horse-Gallop.mp3 (FULL FILE) |
| 20 | target_tag      | eliminated      | 0.0   | —     | 1500        | 4 (file)            | 4       | TargetTag-Villain.mp3 (FULL FILE) |
| 21 | monster_mash    | elimination     | 0.0   | 3.0   | 1500        | 4 (file)            | 4       | TargetTag-Villain.mp3 (FULL FILE) — same asset |
| 22 | gladiator_arena | crowdCheer      | 0.0   | 3.0   | 1500        | 4 (file)            | 4       | GladiatorArena-CrowdCheer.mp3 (FULL FILE) |
| 23 | carnival_derby  | miss            | 0.0   | —     | 1500        | 3 (file)            | 3       | TargetTag-Teasing.mp3 (FULL FILE) |
| 24 | target_tag      | miss            | 0.0   | —     | 1500        | 3 (file)            | 3       | TargetTag-Teasing.mp3 (FULL FILE) — same |
| 25 | carnival_derby  | bust            | 0.0   | —     | 1500        | 3 (file)            | 3       | TargetTag-Ominous.mp3 (FULL FILE) |
| 26 | target_tag      | lowShields      | 0.0   | —     | 0           | 3 (file)            | 3       | TargetTag-Ominous.mp3 (FULL FILE) — same |
| 27 | monster_mash    | healthWarning   | 0.0   | —     | 1500        | 3 (file)            | 3       | TargetTag-Ominous.mp3 (FULL FILE) — same |
| 28 | target_tag      | turnStart       | 0.0   | —     | 1500        | 3 (file)            | 3       | TargetTag-Fanfare.mp3 (FULL FILE) |
| 29 | monster_mash    | buffActivation  | 0.0   | —     | 0           | 3 (file)            | 3       | TargetTag-Fanfare.mp3 (FULL FILE) — same |
| 30 | reef_royale     | coralBloom      | 0.0   | —     | 0           | 3 (file)            | 3       | ReefRoyale-Chime.mp3 (FULL FILE) |
| 31 | reef_royale     | pearlChime      | 0.0   | —     | 0           | 3 (file)            | 3       | ReefRoyale-ChimeScore.mp3 (FULL FILE) |
| 32 | lunar_lander    | crashLanding    | 0.0   | —     | 0           | 3 (file)            | 3       | LunarLander-CrashLanding.mp3 (FULL FILE) |
| 33 | gladiator_arena | trumpetFanfare  | 0.0   | —     | 0           | 3 (file)            | 3       | GladiatorArena-TrumpetFanfare.mp3 (FULL FILE) |
| 34 | target_tag      | tripleHit       | 0.0   | 2.0   | 0           | 2.0                 | 11      | TargetTag-Dream.mp3 |
| 35 | carnival_derby  | tripleHit       | 0.0   | 2.0   | 0           | 2.0                 | 11      | TargetTag-Dream.mp3 — same |
| 36 | monster_mash    | clutchHeal      | 0.0   | 2.0   | 0           | 2.0                 | 11      | TargetTag-Dream.mp3 — same |
| 37 | target_tag      | shieldGained    | 0.0   | 2.0   | 0           | 2.0                 | 8       | TargetTag-WindUp.mp3 |
| 38 | pirates_grid    | timerTick       | 0.0   | 2.0   | 0           | 2.0                 | 5       | PiratesGrid-TimerTick.mp3 |
| 39 | pirates_grid    | cannonBoom      | 0.0   | 2.0   | 0           | 2.0                 | 3       | PiratesGrid-CannonBoom.mp3 |
| 40 | gladiator_arena | timerTick       | 0.0   | 2.0   | 0           | 2.0                 | 5       | GladiatorArena-TimerTick.mp3 |
| 41 | monster_mash    | hatTrick        | 0.0   | 2.5   | 0           | 2.5                 | 3       | MonsterMash-MonsterRoar.mp3 |
| 42 | clockwork_quest | clockChime      | 0.0   | 2.5   | 0           | 2.5                 | 8       | ClockworkQuest-ClockChime.mp3 |
| 43 | lunar_lander    | thrusterBurn    | 0.5   | 3.0   | 0           | 2.5                 | 7       | LunarLander-ThrusterBurn.mp3 |
| 44 | monster_mash    | attack          | 0.0   | —     | 0           | 2 (file)            | 2       | MonsterMash-Growl.mp3 (FULL FILE) |
| 45 | pirates_grid    | shipBell        | 0.0   | —     | 0           | 2 (file)            | 2       | PiratesGrid-ShipBell.mp3 (FULL FILE) |
| 46 | tiki_golf       | clap            | 0.0   | —     | 0           | 2 (file)            | 2       | TikiGolf-Clap.mp3 (FULL FILE) |

## Table B — clips 1.0–1.9s effective duration

Shorter clips. Fade-out on a 1s clip is usually unnecessary — listed for completeness.

| #  | Game            | Clip           | Start | End  | FadeOut(ms) | Effective(s)        | File(s) | Asset / Notes |
|----|-----------------|----------------|-------|------|-------------|---------------------|---------|---------------|
| 47 | tiki_golf       | ballDrop       | 0.0   | 1.6  | 0           | 1.6                 | 8       | TikiGolf-BallDrop.mp3 |
| 48 | gladiator_arena | crowdGasp      | 0.0   | 1.5  | 0           | 1.5                 | 10      | GladiatorArena-CrowdGasp.mp3 |
| 49 | lunar_lander    | missionControl | 0.0   | 1.25 | 0           | 1.25                | 5       | LunarLander-MissionControl.mp3 |
| 50 | pirates_grid    | treasureFound  | 0.0   | 1.25 | 0           | 1.25                | 8       | PiratesGrid-TreasureFound.mp3 |
| 51 | clockwork_quest | gearSpin       | 0.0   | 1.2  | 0           | 1.2                 | 1       | ClockworkQuest-GearSpin.mp3 |
| 52 | reef_royale     | turnBell       | 0.0   | 1.0  | 0           | 1.0                 | 11      | ReefRoyale-Bell.mp3 |
| 53 | clockwork_quest | tickTock       | 0.0   | 1.0  | 0           | 1.0                 | 15      | ClockworkQuest-TickTock.mp3 |
| 54 | carnival_derby  | singleHit      | 3.5   | —    | 0           | ~1.5 (file − start) | 5       | TargetTag-Spring.mp3 (FULL FILE from 3.5s) |
| 55 | target_tag      | singleHit      | 3.5   | —    | 0           | ~1.5 (file − start) | 5       | TargetTag-Spring.mp3 (FULL FILE from 3.5s) — same |
| 56 | monster_mash    | dartHit        | 3.5   | —    | 0           | ~1.5 (file − start) | 5       | TargetTag-Spring.mp3 (FULL FILE from 3.5s) — same |
| 57 | carnival_derby  | outerBull      | 0.0   | —    | 0           | 1 (file)            | 1       | TargetTag-Whistle.mp3 (FULL FILE) |
| 58 | target_tag      | outerBull      | 0.0   | —    | 0           | 1 (file)            | 1       | TargetTag-Whistle.mp3 (FULL FILE) — same |
| 59 | monster_mash    | healing        | 0.0   | —    | 0           | 1 (file)            | 1       | TargetTag-Whistle.mp3 (FULL FILE) — same |
| 60 | target_tag      | taggedIn       | 0.0   | —    | 0           | 1 (file)            | 1       | TargetTag-Launch.mp3 (FULL FILE) |
| 61 | target_tag      | successfulTag  | 0.0   | —    | 0           | 1 (file)            | 1       | TargetTag-PianoRoll.mp3 (FULL FILE) |
| 62 | target_tag      | taggedOut      | 0.0   | —    | 0           | 1 (file)            | 1       | TargetTag-BananaSlip.mp3 (FULL FILE) |
| 63 | reef_royale     | splash         | 0.0   | —    | 0           | 1 (file)            | 1       | ReefRoyale-Splash.mp3 (FULL FILE) |
| 64 | lunar_lander    | warningAlarm   | 0.0   | —    | 0           | 1 (file)            | 1       | LunarLander-WarningAlarm.mp3 (FULL FILE) |
| 65 | gladiator_arena | shieldBlock    | 0.0   | —    | 0           | 1 (file)            | 1       | GladiatorArena-ShieldBlock.mp3 (FULL FILE) |
| 66 | gladiator_arena | missThud       | 0.0   | —    | 0           | 1 (file)            | 1       | GladiatorArena-MissThud.mp3 (FULL FILE) |
| 67 | tiki_golf       | ukulele        | 0.0   | —    | 0           | 1 (file)            | 1       | TikiGolf-Ukulele.mp3 (FULL FILE) |
| 68 | tiki_golf       | splash         | 0.0   | —    | 0           | 1 (file)            | 1       | TikiGolf-Splash.mp3 (FULL FILE) |
| 69 | tiki_golf       | tikiChime      | 0.0   | —    | 0           | 1 (file)            | 1       | TikiGolf-TikiChime.mp3 (FULL FILE) |
| 70 | tiki_golf       | mulligan       | 0.0   | —    | 0           | 1 (file)            | 1       | TikiGolf-Mulligan.mp3 (FULL FILE) |

## Sub-1s clips (omitted — no tuning needed)

These are already short. Fade-out on a sub-1s clip is overkill. Listed once for completeness so you can confirm you don't want to touch them:

- clockwork_quest: `turnBell` (0.8s), `steamHiss` (0.6s), `gearClick` (0.4s)
- reef_royale: `doubleBubble` (0.65s), `bubblePop` (0.25s)
- tiki_golf: `putt` (0.2s)
- carnival_derby: `doubleHit` (0.75s)
- target_tag: `doubleHit` (0.75s)
- FULL FILE clips whose file is <1s: lunar_lander `radioBeep` / `touchdown`, pirates_grid `flagPlant` / `swordClash`, gladiator_arena `swordClash`
