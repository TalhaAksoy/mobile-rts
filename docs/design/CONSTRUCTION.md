# Placing and building

## Cancelling placement

Picking a building from the İnşaat menu enters placement mode. A bar above the bottom bar then shows
"<Bina>: yerleştirmek için haritaya dokun" with an **✖ İPTAL** button.

Placement can be left without spending anything in three ways:

- tapping İPTAL;
- pressing Escape;
- pressing the Android Back button. The first press leaves placement, and only the next one opens the pause menu
  (`PauseMenu.back_handler`).

Before this change there was no way out: after a wrong pick, the player had to place the building somewhere.

## Red or green ghost

The placement ghost is coloured by the same rules that decide whether a tap places the building
(`GameController3D.placement_block_reason`):

| Rule | Reason shown when it fails |
|---|---|
| Every cell is free: no tree, mine, building or water | "Burada ağaç ya da kaynak var" / "Burası dolu" |
| The ground is level | "Zemin çok eğimli" |
| A villager can walk up to the site | "Köylüler buraya ulaşamaz" |

The ghost is **green** where the building can go and **red** where it can't. On red, the placement bar shows the reason
in red, and tapping there places nothing and spends nothing; placement stays on.

**Reachability.** The check uses the selected villagers or, if none is selected, the nearest villager. It requires a
path that ends within building reach of the walls: next to them, or 1.3 cells out (see below). Before this, a building
could be placed in a pocket walled in by trees; its builders walked to it, gave up, and the site stayed at 0 %.

The check runs only when the ghost moves to another cell or another building is picked.

## Building crews (`GameController3D.MAX_BUILDERS = 5`)

Every builder adds its own build speed, so five villagers build a House in about 2.4 s instead of 12 s.

**Assigning builders.** At most five villagers work on one site, and the nearest ones go first. This applies:

- when a building is placed with villagers selected;
- when a site is tapped with villagers selected.

The others keep their orders, and a notice says the site is full.

**A selected unfinished building shows:**

- **İnşaatçı: n/5**, updated live.
- **+ Köylü Ekle** sends the nearest idle villager. If none is idle, it sends the nearest villager that is not
  already building something. When the crew is full, nobody is sent.
- **✖ İnşaatı İptal Et (iade: …)** removes the site and frees its builders and its ground. It refunds the cost of the
  part not built yet:
  - an untouched site gives everything back;
  - a Kışla at 50 % gives back 75 of its 150 wood.

## Fixed: builders giving up one cell short

A builder used to give up when its path ended one cell short of the site, and the site stayed at 0 %. This happened
when the cells right next to the site were taken, for example by the Town Center or by other builders. In a test with
7 villagers placing a House next to the Town Center, only 1 of the 5 sent builders kept working.

Now a builder whose path cannot get closer builds from where it stands, as long as it is within 1.3 cells of the
walls. Further away, the site really is out of reach, and the builder still gives up.

## Tests

`scripts/tests/test_construction_controls.gd` checks:

- the placement bar and İPTAL;
- the red ghost and its reason over a tree, the green ghost on a free spot, "Köylüler buraya ulaşamaz" for a spot
  walled in, and that tapping a red spot places nothing;
- the Back key order;
- 7 selected villagers giving exactly 5 builders;
- the site panel and + Köylü Ekle;
- the build speed: five builders next to their site build 5× as fast as one (41.7 %/s against 8.3 %/s on a House);
- the refunds;
- that cancelling frees the builders and the ground.
