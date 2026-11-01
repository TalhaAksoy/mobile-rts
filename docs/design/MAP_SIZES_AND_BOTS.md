# Map sizes and more bots

The map size and the number of opponents are picked on the new-game screen, under the map:

- **Harita Boyutu:** Küçük / Orta / Büyük.
- **Rakip Krallıklar:** a − / + counter limited by the size, then one civ picker per opponent with its team colour.
  Rakip 1 starts on Bizanslılar, the others on Rastgele.

The choice is remembered in `user://settings.cfg` (section `game`, keys `map_size` and `bot_count`).

| Size | Cells | Opponents |
|---|---|---|
| Küçük | 32 × 60 | 1 |
| Orta | 48 × 76 | 1–3 |
| Büyük | 64 × 96 | 1–5 |

"Orta'da 2 bot daha" was read as **two more than Küçük**, so Orta allows 3. The limits are
`MapGenerator3D.MAP_SIZE_MAX_BOTS`, so changing one number changes the limit.

Küçük with one bot is the original map. The player and the bot have the same cells as before (16,48 and 16,10),
and every earlier test still runs on it.

## Layout (`MapGenerator3D._start_cells`)

- **Player:** bottom centre.
- **One bot:** top centre.
- **More bots:** spread evenly on an ellipse round the map. Measured gaps:

  | Setup | Closest bases |
  |---|---|
  | Orta, 3 bots | 30 cells |
  | Büyük, 5 bots | 27 cells |

**Every base:**

- the area around it is levelled and dried, including River Crossing fords;
- it gets the usual gold, stone, berry and wood cluster, and resources stay out of the base keep-out radius.

**Map types scale with the size:**

- Forest Valley opens a valley from every base through the map centre. With one bot this is exactly the old middle
  column.
- River Crossing has a ford every 8 columns.
- With more than one bot, the ground roads run from every base to the map centre.

## Bots

**Setup:**

- Every bot has its own `EnemyAI3D` (`GameController3D.bot_ais`; `[0]` is the scene's `enemy_ai`, team 1), its own
  resources, age and techs.
- Its civ is either the one picked on the screen or a random civ nobody else plays.
- **Rakip 1 → Rastgele** never picks the player's civ.

**Fighting:**

- Every team is hostile to every other team, so bots fight each other too.
- An attack wave goes to the nearest enemy Town Center from the bot's base. In a 1v1 that is the player's Town Center,
  as before.

**Winning:**

- A bot that loses its last Town Center is out: its AI stops, and its remaining units still fight.
- The last bot out means **victory**. Losing the player's Town Center is still defeat.

## Team colours

`FactionArtManager.TEAM_COLORS` / `team_color(team)`:

| Team | Colour |
|---|---|
| 0 (player) | blue |
| 1 | red |
| 2 | yellow |
| 3 | green |
| 4 | purple |
| 5 | teal |

These colours appear on:

- the 3D team trim on buildings and units;
- the minimap;
- the occlusion tint;
- the swatches on the new-game screen.

**Known limit:** in **2D sprite** style the sheets exist only in the first two colours, so every bot uses the red
sheet. Telling bots apart in 2D needs sheets rendered in the other four colours: `render_sprites.py` and
`units/render_unit_sprites.py` with more `TEAM_COLORS`.

## Saving

A save keeps:

- the map size and bot count;
- every team's civ, resources, age and techs;
- every bot's state: clock, waves, next wave, and whether it is out.

Older saves load as Küçük with one bot.

## Performance

The figures below were measured on the desktop only, not on a phone, and say nothing about mobile frame rate:

| Size | Bots | Draw calls (60 s in, at the player's base) | Nodes |
|---|---|---|---|
| Küçük | 1 | 294 | 2,400 |
| Orta | 3 | 351 | 4,000 |
| Büyük | 5 | 357 | 5,900 |

All three ran at the 60 FPS cap. The large map has about three times the cells: fog, trees and pathfinding scale with
it, so Büyük with five bots should be checked on a real device before it is recommended for low-end phones.

## Tests

`test_multi_bot.gd` checks:

- the new-game screen: limits, stepper, civ pickers, remembered choice;
- the layout on every size and several map types;
- the bot limits and team colours;
- elimination and victory;
- save/load;
- five bots playing for 150 game seconds on the large map.
