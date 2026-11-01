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
| villagers | 10 | 14 | 20 |
| army size (soldiers in training counted) | 8 | 14 | 40 |

Waves get 3 s shorter each time, down to 70 % of the interval. When the army is too small at wave time, the bot
checks again 15 s later. Soldiers that stay home still fight anything that comes near them.

## Measured against a passive player

Highland, the map where the old bot was harshest. Same seed for every row; headless at 8× speed, game time:

| | first soldier at the base | most at the base at once | largest army | Town Center |
|---|---|---|---|---|
| before (fixed setting) | 105 s | 17 | – | lost before 4 min |
| Kolay | 491 s | 5 | 9 | lost at 581 s (≈ 90 s after the first wave) |
| Orta | 311 s | 9 | 14 | standing at 330 s (end of run) |
| Zor | 189 s | 23 | 27 | lost at 218 s |

Covered by `scripts/tests/test_ai_difficulty.gd`. It uses fixed time and size limits taken from the on-screen
hints, not the profile values, so a profile edit that makes a level harsher fails the test.

## Known limit

On some seeds of the dense Forest Valley map, the bot builds no army at all. This is a pre-existing economy issue:
"bot military spending is uneven" in FINAL_GAMEPLAY_VALIDATION.md §7. Difficulty does not change it.
