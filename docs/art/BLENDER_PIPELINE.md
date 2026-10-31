# Blender → Godot Asset Pipeline

Verified with Blender 5.2.3 LTS + Godot 4.7.2 (Compatibility renderer) on Linux, driven through Blender MCP and Godot MCP.

## 1. Layout

```
art_source/
  blender/
    pe_kit.py            # material library (pixel-art pattern baker), geometry Builder, export/preview helpers
    parts.py             # shared architecture parts (minarets, round towers, spires, cypress, logs, shields ...)
    buildings/<civ>_<asset>.py      # one build script per building: build() + run(export)
    environment/<biome>_<asset>.py  # trees, mines, food props; VARIANTS = [(folder, biome)] re-skins per biome
    environment/env_parts.py        # frond / cactus pad / rotated block / foliage clump helpers
    build_all.py         # rebuild library + every building + previews (run inside Blender)
    build_environment.py # rebuild library + scatter atlas + every environment prop variant + previews
    update_manifest.py   # regenerate the Godot manifest from *.meta.json (run with system python)
    <civ>/<asset>.blend  # editable source (written by export_asset)
    <civ>/<asset>.meta.json
  textures/
    materials/PE_*.png   # baked 64x64 pattern textures (source of truth: pe_kit.RAMPS / PATTERNS)
    emblems/<civ>.png, banner_<civ>.png   # cropped from sample_project/art/flags
  tools/compose_compare.sh   # reference | Blender | Godot comparison sheet
sample_project/
  assets/3d/buildings/<civ>/<asset>.glb
  assets/3d/environment/{common,desert,steppe,autumn}/<asset>.glb
  assets/3d/materials/PE_*.tres + textures/PE_*.png(.import pinned)   # shared Godot material library
  data/art/building_model_manifest.json
docs/art/previews/<civ>_<asset>.png   # Blender preview renders (45° RTS angle)
```

`.blend` files live **outside** the Godot project, so opening the project never needs Blender (Godot would otherwise try to
import `.blend`). The game ships only `.glb`.

## 2. Conventions (verified, not assumed)

| Rule | Value | How it was verified |
|---|---|---|
| Units | 1 Blender unit = 1 m = 1 Godot unit | test cube exported/imported 1:1 |
| Up axis | Blender Z-up → glTF Y-up | door marker at Blender (0,−1.1,0.5) imported at Godot (0,0.5,1.1) |
| Front | **Blender −Y = Godot +Z** = towards camera / rally point | same test |
| Origin | ground centre of the gameplay footprint, base at z=0 | `test_building_models.gd` checks min y ≈ 0 |
| Footprint | grid × 2 m × 0.9 (+0.05 tolerance): TC/Barracks 5.4 m, House/camps 3.6 m, Castle 7.2 m | `test_building_models.gd` checks AABB |
| Texel density | 32 px/m (64 px texture = 2 m tile), nearest + mipmaps | visual check at 3 zooms |
| Materials | named `PE_*` / `TEAM_*`, exported **without images** | Godot remaps by name |
| Polycount | buildings 600–4000 tris, props 100–350 tris | meta.json / manifest |

## 3. Building an asset

1. Write `art_source/blender/buildings/<civ>_<asset>.py` using `Builder` + `parts`. Record in the docstring what was read from
   the gallery reference and every interpretation decision.
2. In Blender (MCP `execute_blender_code`):
   ```python
   import runpy
   runpy.run_path("<repo>/art_source/blender/build_all.py", init_globals={"ONLY": ["<civ>_<asset>"]}, run_name="__main__")
   ```
   This bakes/refreshes the material library, builds the mesh (one object, one surface per material), saves the
   `.blend`, exports the `.glb`, writes `.meta.json` and renders `docs/art/previews/<civ>_<asset>.png`.
3. Inspect it with MCP `look` (angles `[0,-1,1]` = RTS view, `[-0.7,-0.7,0.75]` = gallery-like 3/4). Iterate until the
   silhouette reads at RTS distance.
4. `python3 art_source/blender/update_manifest.py`, which adds/updates the entry (keeps `enabled`/`status`).
5. `godot --headless --path sample_project --import`, then `godot --headless --path sample_project --script res://scripts/tests/test_building_models.gd`
   (footprint, ground contact, library materials, team trim, construction states, save/load).
6. In-game capture: `godot --path sample_project --script res://scripts/tools/capture_gameplay.gd -- --out=<dir> --civ=<n> --showcase=<ids>`.
7. Comparison sheet: `art_source/tools/compose_compare.sh <civ> <asset> <capture.png>`.

### 3.1 Kit-built building types (civ kit)

Barracks, Archery Range, Stable, Blacksmith, Lumber Camp, Mining Camp, Watch Tower and Castle are built from a shared kit
instead of one hand-written script per civ (Ottoman Barracks and Lumber Camp stay hand-written):

* `civstyle.py`: one `STYLES[civ]` entry per civ (wall, plinth, roof form + material, windows, tower form, fence) plus
  `hall()`, `roof()`, `tower()`, `ger()`, `canopy()`, `curtain()` and props (fence, weapon rack, dummy, archery butt,
  horse, cart, anvil, hay, flagpole). Mongols get gers and felt awnings instead of halls; Vikings and Mongols get
  timber palisades instead of stone curtain walls.
* `bldtypes.py`: one layout per type (`build_barracks`, `build_archery_range`, ...), so a type reads the same for every
  civ while the civ shows in masonry, roof form, tower form and props.
* `buildings/<civ>_<asset>.py` are thin wrappers written by `python3 art_source/blender/gen_type_scripts.py <asset>
  <grid>` (it never overwrites an existing script). `build_all.py` reloads the kit modules on every run.

To change how a civ looks everywhere, edit its `STYLES` entry and rebuild with `ONLY` = that civ's scripts.

### 3.2 2D sprite set (Ayarlar > Görünüm: 2D Sprite)

The 2D look is rendered from the same models, so 2D and 3D always show the same design.

1. In Blender: `runpy.run_path("<repo>/art_source/blender/render_sprites.py")`. Optional globals:
   * `ONLY = ["britons_house", "env:common_tree_pine", "fields:field", ...]` restricts the set.
   * `EXPOSURE = -1.5` (stops) is the default. It was calibrated against in-game 3D captures (roofs and walls),
     because the sprites are unshaded in Godot but still tonemapped there.

   The script builds each model with its own build script and renders it:
   * with an orthographic camera at the game camera's 45° pitch,
   * at 4× supersampling, on a transparent background,
   * once per team colour when the model has `TEAM_*` surfaces.

   Upgrade kits are cut at the origin into a back half and a front half, so the back pieces stand behind the
   building sprite. Output: `build/sprites_raw/` (not committed) and `sample_project/data/art/sprite_manifest.json`.
2. Outside Blender, `python3 art_source/blender/finish_sprites.py`:
   * box-downsamples to 32 px/m, the same density as the 3D textures;
   * gives the alpha a hard edge;
   * writes `sample_project/assets/sprites/<section>/<key>[_t0|_t1].png`;
   * pins each `.import` as lossless, with no mipmaps and no VRAM compression from 3D detection, which would blur
     the pixels.
3. `godot --headless --path sample_project --import`, then `test_visual_style.gd`.

Placement (`FactionArtManager.make_sprite_node`):
* The sprite is a plane facing the camera (no billboard; the camera yaw is fixed).
* It stands at the model's front-most depth (`plane_z`) and is stretched vertically by 1/cos(45°), so the 45° camera
  sees it undistorted.
* `anchor` is the pixel of the ground point under the model origin.
* In 2D mode, buildings under construction show the sprite revealed from the ground up.
* Environment props are mirrored at random instead of rotated.

## 4. Godot side

* `FactionArtManager.instantiate_building_model(civ, type, team)` loads the GLB listed in the manifest and replaces every
  surface material by `res://assets/3d/materials/<name>.tres`. `TEAM_*` surfaces get a per-team duplicate with
  `TEAM_COLORS[team]`.
* `Building3D._build_3d_structure()` tries the model first, then falls back to the HD-2D sprite, then to the old procedural
  geometry. Gameplay (collision box, selection ring, HP bar, production, AI, save/load) is unchanged and independent of the visual.
* Construction: the model rises from 15% to 100% height inside a timber scaffold (`_update_construction_visual`).
  `refresh_construction_state()` re-applies this after `SaveManager.load_game`.
* Environment: `MapGenerator3D._add_env_model()` puts the tree/mine GLB under the resource node as `Visual`, with random
  yaw and scale. Mines scale 100%→55% as they deplete. Selection `Area3D` colliders are unchanged.
* Biomes: `CivData.MAP_CONFIGS[*].biome` (temperate / desert / steppe / autumn) selects `CivData.BIOME_PROPS`
  (tree species + weights, gold, stone and food prop ids and their Turkish UI names). Manifest keys are the bare id for the
  temperate set (`tree_pine`) and `<biome>/<asset>` for variants (`desert/tree_palm`). A missing or disabled biome model
  falls back to the temperate id, then to the sprite. Each biome has its own nature atlas
  (`PE_NatureAtlas`, `PE_NatureAtlas_{Desert,Steppe,Autumn}`: same quadrant layout, different ramps), so a prop script
  can be re-skinned per biome and every prop stays at 1 atlas draw call (+1 fruit surface on food props).
  `HD2DGround.BIOME_GROUND / BIOME_WATER / BIOME_CLIFF_TINT` and the biome rows of the scatter atlas (4×8 cells) dress
  the ground to match. `test_biome_props.gd` checks every map type end-to-end.
* Reversible: `FactionArtManager.use_3d_building_models = false`, or `"enabled": false` per manifest entry → sprite path.

## 5. Gotchas found while building the pipeline

* Openings placed *inside* a solid wall box are invisible. `arch_opening()` therefore puts the dark panel just in front of the
  wall, with a protruding frame and inward-facing reveals.
* Hip roofs with upturned corners need an 8-point underside. A flat corner-height underside pokes through the roof at mid-eave.
* Godot extracts embedded glTF images per model (duplicate textures, no sharing), which is why GLBs carry no images.
* Godot's default *Detect 3D* would VRAM-compress the 64×64 pixel textures the first time the editor sees them. `pe_kit`
  writes/patches their `.import` (`compress/mode=0`, `mipmaps/generate=true`, `detect_3d/compress_to=0`).
* Deleting extracted textures leaves stale UIDs for one import pass ("Unrecognized UID"). A second `--import` is clean.
* `bpy.ops.wm.read_homefile` replaces whatever scene is open in the user's Blender. Builds use `pe_kit.reset_scene()` on a
  dedicated file instead.
