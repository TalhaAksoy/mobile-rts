# Gathering

Villagers gather one resource at a time, so the load on the villager panel counts up 1 by 1 ("Altın Kazıyor 3/5").

## Rules (`Unit3D.gd`)

- **Every swing takes exactly 1.** The time between swings (`GATHER_INTERVAL`):

  | Source | Seconds per swing |
  |---|---|
  | Wood | 0.4 |
  | Berries | 0.4 |
  | Gold | 0.5 |
  | Stone | 0.5 |
  | Field | 0.5 |

  Wood and berries keep their old lead over the other sources (5 versus 4 per swing before).
- **Bonuses make swings faster, never bigger.** Civ bonuses (`CivData *_gather_mult`) and gather techs divide the
  interval. For example, Sarazenler mine gold 30 % faster: one gold every 0.38 s.
- **A villager carries 5** (`max_carry`) before walking back. Techs still add to it:
  - Bıçkı Ocağı: +3, so 8;
  - the TC carry tech: +5.

## Working and unloading up close

Villagers stand right next to what they work on:

- **At the node:** they gather from at most 0.6 m from the node's cell (`GATHER_REACH`).
- **At the drop-off:** they unload at most 0.8 m from the building's wall (`DROPOFF_REACH`).

**Before,** a villager stopped once it was within 2.8 m of the node's centre or anywhere in a neighbouring cell. It
unloaded within 3.2 m of the building's edge. In practice that meant:

- gathering 1.6–2.8 m away from the node;
- unloading about 2 m from the wall;
- a shorter round trip, which made the economy faster.

**Now** the A* path ends in the neighbouring cell, and the villager walks the last metre straight in. If another unit
blocks it for 1.5 s (`APPROACH_TIMEOUT`), it works or unloads from where it stands, so it never gets stuck.

Going closer (0.35 m and 0.5 m) was tried. Crowds of bot villagers then pushed each other off their cells: in
`test_bot_no_sealed_villagers`, five ended up walled away from their Town Center. The economy also slowed, and the Zor
bot no longer took the Town Center before minute 5.

## Why

Before, a swing took 4–5 at once and a villager carried 15:

- the load filled in two or three swings;
- six farmers on six fields brought in about 900 food a minute.

**Measured gathering speed** (fresh villager, no bonus, not counting the walk):

| | Old | New |
|---|---|---|
| Wood | about 6 per second | 2.5 per second |
| Gold / stone | about 5 per second | 2 per second |

With 5 per trip, a villager also walks back three times as often.

## Bot

The bot gives villagers a job only when they are idle. With the slower economy, the food crew from the start kept
farming:

- food piled up past 1,000;
- wood stayed near 0;
- the bot built no barracks.

`EnemyAI3D` now moves one villager per think between food and wood:

- from food to wood when food is over 300 and wood under 150;
- the other way when wood is over 400 and food under 100.

After the change, every one of the ten 300-second bot simulations builds an army. The measured attack times per
difficulty are in `AI_DIFFICULTY.md`.

## Tests

`scripts/tests/test_gather_one_by_one.gd` checks:

- a villager carries 5;
- wood, gold, stone and berries count up 1 by 1 and one trip delivers 5;
- a civ bonus makes the swings faster but keeps 1 per swing;
- +3 carry gives a trip of 8;
- starting at the base, the villager works within 0.7 m of the node and unloads within 0.9 m of the wall.
  The old code fails this: 1.6–2.8 m at the node and 2 m at the wall.

`test_ai_difficulty.gd` now simulates the Zor match for 300 s instead of 240 s. Its check is still "Zor takes the
Town Center before minute 5"; the shorter run ended before that could be seen.
