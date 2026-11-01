# Enemy bot difficulty (Kolay / Orta / Zor)

Picked on the civ select screen ("Zorluk", under the enemy kingdom) before the match. The first launch selects
**Kolay** so that a new player gets time to learn. After that the last choice is remembered (`user://settings.cfg`,
section `game`, key `difficulty`). A saved game keeps its difficulty and the bot's clock, so loading does not give a
fresh grace period.

## Why

`EnemyAI3D` already had an unused difficulty enum: every match ran with one fixed setting.

- The first attack wave fired **40 s** into the match, with every soldier the bot had.
- Later waves came every 28–40 s.

Against a player who only moved a few villagers, on Highland, seed 901:

- the first enemy soldier reached the base at **105 s**;
- the Town Center fell before minute 4;
- the attack force was 17 soldiers.

## Profiles (`EnemyAI3D.PROFILES`)

| | Kolay | Orta | Zor |
|---|---|---|---|
| decisions every | 4 s | 2.5 s | 1.5 s |
| no attack before | 8 min | 5 min | 3 min |
| between waves | 150 s | 90 s | 55 s |
| wave waits for an army of | 4 | 5 | 5 |
| part of the army sent | 50 % | 60 % | 100 % |
| villagers | 10 | 14 | 26 |
| army size (soldiers in training counted) | 8 | 14 | 40 |

Waves get 3 s shorter each time, down to 70 % of the interval. When the army is too small at wave time, the bot
checks again 15 s later. Soldiers that stay home still fight anything that comes near them.

## Measured against a passive player

Highland, the map where the old bot was harshest. Same seed for every row; headless at 8× speed, game time:

| | first soldier at the base | most at the base at once | largest army | Town Center |
|---|---|---|---|---|
| before (fixed setting) | 105 s | 17 | – | lost before 4 min |
| Kolay | 491 s | 4 | 8 | standing at 600 s (end of run) |
| Orta | 311 s | 9 | 14 | standing at 330 s (end of run) |
| Zor | 189 s | 14 | 20 | lost at 281 s |

These rows are with one-at-a-time gathering and villagers walking right up to the node and the drop-off
(`GATHERING.md`). With the old 4–5 per swing and 15 per trip the waves were bigger: Kolay took the Town Center at
581 s, Zor at 218 s with 23 soldiers at the base.

**Zor villager cap.** Walking right up to the node slowed every economy. After that change the Zor bot took a passive
player's Town Center only at 299 s, against its "before minute 5" promise. Its villager cap went from 20 to 26 to fix
that: now 281 s.

Covered by `scripts/tests/test_ai_difficulty.gd`. It uses fixed time and size limits taken from the on-screen
hints, not the profile values, so a profile edit that makes a level harsher fails the test.

## Fixed: the bot sealing its own villagers (Forest Valley)

On some seeds of the dense Forest Valley map, the bot built no army at all. Seed 900: no soldiers in 8 minutes, with
2,600+ wood.

- **What happened.** At 39 s the bot placed a house across the mouth of a berry pocket, closed in by trees, a gold
  mine and bushes. 7–10 villagers were trapped there carrying food for the rest of the match.
- **Why the check missed it.** Site checks are "can the builder reach it" and "does it seal anything off". Both were
  measured from the worker's own cell. That worker stood inside the future house, so both checks passed.
- **Why no army followed.** Later builders were picked from the trapped villagers, so no site was ever reachable.
- **The fix.** Both checks now use a walkable cell next to the Town Center: the home area every villager must reach.
  The builder is the nearest villager that can actually walk to the site.
- **Result.** 12/12 Forest Valley seeds and 16/16 seeds on the other maps build an army.

Covered by `scripts/tests/test_bot_no_sealed_villagers.gd`. It runs three Forest Valley seeds, including 900, and
checks that the bot builds an army, that every villager can walk home, and that no villager carries food for a minute
or more.
