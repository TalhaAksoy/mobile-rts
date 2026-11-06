# Pixel-art 2D sprites (Aseprite)

The "2D Sprite" visual style (Ayarlar > Görünüm, and the LOW preset) looks like a classic 2D RTS / RPG: the
camera is orthographic and looks straight down, so the ground is a flat map, while units, buildings and trees are
drawn in a 3/4 "oblique" view (front face plus roof / top) and lie flat on the ground. Painter's order: the
further south, the more in front (`ObliqueSort.gd`, `FactionArtManager.oblique_sort_y`). The 3D style keeps its 45
degree perspective camera (`MobileCamera3D`, gated on `FactionArtManager.top_down()`).

Every image is generated procedurally by Lua scripts that run inside Aseprite: units, buildings, trees / bushes /
mines for every biome, farm fields, civ upgrade kits, and the UI art made from them (unit portraits, building
icons, gallery posters).

| Output | Path |
| --- | --- |
| Game sheets (team 0 blue, team 1 red) | `sample_project/assets/sprites_px/{units,buildings}/<civ>/<id>_t0.png` / `_t1.png` |
| Environment, fields, upgrade kits | `sample_project/assets/sprites_px/{environment,fields,upgrade_kits}/...` |
| Layered sources (animation tags) | `art_source/aseprite/src/...` |
| UI portraits / icons / posters | `sample_project/art/units/<civ>/<role>/*.png`, `art/buildings/<civ>/*.png`, `art/concept_sheets/<civ>.png` |
| Manifest fragments | `build/px_meta/...` (ignored), merged by `update_manifest.py`; gallery-only buildings in `build/ui_only/` |

## Run

Through the Aseprite MCP server (`run_lua`, batch backend):

```lua
_G.GEN_ARGS = { root = "/path/to/mobile-rts", civs = {"franks"}, kinds = {"units", "buildings"} }
return dofile(GEN_ARGS.root .. "/art_source/aseprite/run.lua")
```

Or from a shell: `make sprites-px`. Kinds: `units, buildings, environment, fields, upgrade_kits, ui` (default: all;
`ui` reads the unit and building sheets). Then `python3 art_source/aseprite/update_manifest.py` and a Godot import
(`godot --headless --path sample_project --import`).

## Conventions

- 32 px/m (a man is ~56 px tall). Heights in the 3/4 drawings use 22.6 px/m; ground depth of fields and kit walls
  uses 32 px/m so they line up with their footprint seen from above. Buildings are taller in the image than their
  footprint is deep, so the front face and roof cover the footprint like in any 2D game. The 2D style renders at
  100% resolution (GraphicsSettings) so the pixel art is never blurred by a reduced 3D scale.
- Every civ is researched in `docs/art/culture/<civ>.md` (palette, architecture per building type, dress and
  armour per unit role, emblems, mistakes to avoid). `civs/<civ>.lua` encodes it: unit styles per role and the
  `_buildings` vocabulary (wall / roof materials, roof form, domes, arches, windows, props, emblem), and
  `landmarks/<civ>.lua` adds the civ's bespoke layouts (e.g. Ottoman külliye, Teutonic Ordensburg, Japanese buke
  yakata, Mongol ordo ger-cart, Norse great hall). Other building types use the generic layouts in `buildings.lua`
  built from that vocabulary.
- Manifest entries carry `"view": "oblique"`: `FactionArtManager.make_sprite_node` lays the sprite flat
  (image-up = north) with the anchor (front centre of the footprint, feet of a unit or tree) `plane_z` metres in
  front of the node origin. `Unit3D` keeps unit sheets flat and unrotated, mirrored when walking right.
- Unit sheets: 8 columns x 6 rows, one animation per row: idle 4, walk 8, attack 6, gather 6, build 4, death 6.
  Units face front-left. Dithered ground shadows are a separate, non-outlined layer; outlines are selective
  (a dark version of the neighbouring colour).
- Team colour is drawn with a 5-tone magenta placeholder ramp (`TEAM_H .. TEAM_DD` in `palette.lua`) and swapped
  per team on export: coats / tabards / kaftans, shields, caparisons, sashimono, roof ridges, banners and flags.
  Where a civ's iconic dress has a fixed colour (the Teutonic Order's white) the team colour moves to crest / sash.

## Age looks

Every soldier and building has three looks, one per age (Köy / Hisar / İmparatorluk), all derived in `ages.lua`:

- **Age II** is the base design (`civs/<civ>.lua`, landmarks) and keeps the plain file names (`swordsman_t0.png`).
- **Age I** (`*_a1_t*.png`): village-age kit (no metal armour, caps / hoods / turbans, plain shields, unarmoured
  horses) and the civ's vernacular materials (mud brick, wattle and daub, rammed earth, thatch, turf) on the generic
  layouts; watch towers become a timber lookout. The castle has no Age I look (it needs Age II). Mongol gers stay.
- **Age III** (`*_a3_t*.png`): the civ's heaviest historical kit (helmet + plume / crest, plate, lamellar or scale,
  capes, barded horses, gilded trim) and the landmarks with a paved yard, two standards and civ props.

Generic rules come first, then per-civ / per-role overrides for authenticity. `run.lua` builds ages 1, 2, 3 (or
`ages = {1, 3}`); metas land in `build/px_meta/<kind>/<civ>/<id>@a<N>.json` and `update_manifest.py` stores them
under the entry's `"ages"` key. In the game `FactionArtManager.for_age` picks the look from the owner's age
(`GameController3D.team_age`) and `Building3D.set_age_look` / `Unit3D.set_age_look` swap it on age-up.
The 3D units have the same three looks (`art_source/blender/units/unitstyle.py`, `build_units.py --ages=1,3`);
3D buildings swap materials for Age I and get standards in Age III at runtime.

## Files

- `arch.lua` architecture kit in metres: wall materials (ashlar, banded, brick with glazed diaper, ablaq, brick_banded,
  plaster, adobe, planks, stave, logs, felt, rammed earth), roofs (hip, gable, gable_front, stepped, curved, shed),
  round towers, domes and drums, minarets, doors, windows, banners, flags, tuğ, ground pads
- `props.lua` yard props (cypress, şadırvan, carpets, copper pot, barrels, logs, ore, headframe, targets, nişan taşı,
  horses, palms, stone lanterns, guardian lions, bamboo, rune stones, windmill sails, water wheels ...)
- `landmarks/<civ>.lua` civ-specific landmark layouts; `civs/<civ>.lua` civ styles
- `px.lua` drawing helpers (canvas with per-pixel layer ownership, lines, polygons, outline, rotation, JSON)
- `palette.lua` named colours and team ramps
- `char.lua` character kit (heads, headgear, torso, arms, weapons, shields, horse / camel)
- `units.lua` animation poses, sheet + `.aseprite` export
- `buildings.lua` one layout per building type, driven by the civ's building style
- `civs.lua` loads `civs/*.lua`
- `env.lua` trees, bushes and mines per biome, farm fields, civ upgrade kits (back + front halves)
- `ui.lua` portraits (pose_01 idle, pose_02 walk, action_reference attack, rear_reference mirrored walk), icons, posters
- `ages.lua` Age I / III transforms for units and buildings (see above)
- `physique.lua` the people per civ: stature (pixel rows added / removed at shin and waist, `units.lua`), torso width, a range of skin tones and hair colours spread over the roles, hair / beard customs. Mirrors `art_source/blender/units/unitstyle.py` PHYSIQUE; see the "People" note in `docs/art/culture/<civ>.md`
- `run.lua` entry point, `update_manifest.py` manifest merge
