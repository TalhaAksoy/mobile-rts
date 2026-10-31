# Blender ↔ Godot Integration Report

Date: 2026-10-31 · Engine: Godot 4.7.2 (gl_compatibility) · Blender 5.2.3 · Linux (CachyOS), Intel RPL-S iGPU

## 1. What was integrated

* 13 building models (all 10 civ Town Centers + Ottoman House / Barracks / Lumber Camp) and 4 environment props
  (pine, oak, gold mine, stone mine). Every one was built in Blender through MCP, exported to GLB, imported by Godot and
  shown in the real Main3D match.
* Shared material library: 38 `StandardMaterial3D` resources plus pinned lossless 64×64 textures.
* Manifest: `sample_project/data/art/building_model_manifest.json` (civ + building id → model, source, tris, status, enabled).

## 2. Code changes (gameplay untouched where not stated)

| File | Change |
|---|---|
| `scripts/FactionArtManager.gd` | manifest loader, `instantiate_building_model()`, `instantiate_environment_model()`, library material remap, team trim materials, `compute_visual_aabb()`, global toggle `use_3d_building_models`, one-time warnings for missing assets |
| `scripts/Building3D.gd` | model branch before the sprite branch, `v_height` from model AABB, timber scaffold + rising construction visual, `refresh_construction_state()` |
| `scripts/SaveManager.gd` | calls `refresh_construction_state()` after restoring `is_completed` / `construction_progress` |
| `scripts/MapGenerator3D.gd` | trees/mines use 3D models (sprite fallback), random yaw/scale, mine depletion shrink, grass albedo toned |
| `scripts/Unit3D.gd` | occlusion silhouette (team-coloured, no depth test) + sprite in OPAQUE_PREPASS at higher render priority. Also melee-vs-building range fix (see Linux audit L4) |
| `scenes/Main3D.tscn` | warmer/lower sun, cooler ambient, exposure + contrast/saturation adjustments. Dead `dof_blur_*` keys removed: they sat on `Environment`, where Godot 4 has no such properties, so the game never had DOF (correction to an earlier version of this report) |
| `scripts/HD2DGround.gd`, `scripts/HD2DScatter.gd`, `shaders/hd2d_*.gdshader` (new) | HD-2D environment pass: textured ground + A*-routed roads, ground scatter, water, vignette (see ART_DIRECTION_BIBLE §7) |
| `scripts/MapGenerator3D.gd` (gameplay) | base keep-out for resource spawning (L5), shared unreachable-resource marks (L6) |
| `scripts/EnemyAI3D.gd` (gameplay) | skips unreachable resources, worker-based site reachability, re-tasks builderless sites, 60 s stalled-site watchdog with refund (L6/L9) |
| `scripts/GameController3D.gd` (gameplay) | tap priority (L1/L7), units ejected from newly placed footprints (L10) |

## 3. Validation evidence

| Check | Method | Result |
|---|---|---|
| GLB imports | `godot --headless --import` | 17/17 import, 0 errors (after one stale-UID pass, see pipeline §5) |
| Transform / ground / footprint | `test_building_models.gd` | all 13 buildings: base y = 0.000, inside footprint ±0.05 m |
| Materials | same test | every surface mapped to `res://assets/3d/materials/*` (0 stray imported materials) |
| Team colour | same test | TEAM trim blue (team 0) and red (team 1) on every building |
| Collision | same test | footprint `BoxShape3D` unchanged (not derived from render geometry) |
| Construction states | same test | scale 0.15 → 0.575 at 50% → 1.0 on completion, scaffold hidden |
| Save/load unfinished model building | same test, real match | restored at 40% progress, scale 0.49 = expected |
| Selection / navigation / gather / combat with models present | full suite (`./run_tests.sh`) | see FINAL_GAMEPLAY_VALIDATION.md |
| In-game visuals | `capture_gameplay.gd` | `docs/audits/evidence/slice/` (all 10 civ TCs, Ottoman base, 3 zooms) |
| Reference fidelity | `compose_compare.sh` | `compare_{ottomans,japanese,mongols}_town_center.png` |

## 4. Performance: sprite baseline vs 3D models

Measured with `scripts/tools/perf_benchmark.gd` in a real, windowed match: Ottoman base of 13 buildings, N mixed units per
team walking (pathing + idle-scan AI live), 4 s samples. Hardware: **Intel i7-13650HX + integrated RPL-S GPU, 540×960
window**. This is a desktop iGPU, **not a phone**, so no mobile FPS is claimed. Raw data:
`docs/audits/evidence/perf/perf_ottomans_igpu.csv`.

| Units / team | Zoom | Sprites FPS | Models FPS | Sprites draw calls | Models draw calls | Models primitives |
|---|---|---|---|---|---|---|
| 0 | default | 137.6 | 131.5 | 439 | 589 | 94k |
| 0 | far | 135.8 | 129.1 | 567 | 695 | 108k |
| 20 | default | 110.1 | 112.0 | 747 | 861 | 108k |
| 50 | default | 91.8 | 93.5 | 1122 | 1235 | 128k |
| 80 | default | 75.4 | 80.8 | 1404 | 1565 | 149k |
| 80 | far | 88.7 | 90.1 | 1205 | 1402 | 164k |

Findings:
* 3D buildings and environment cost ~+110 to +190 draw calls and ~+5% frame time with no units. With units the difference
  is within run-to-run noise.
* **Units are the bottleneck in both modes:** about 7 draw calls per unit (sprite depth prepass + colour + shadow,
  silhouette, HP bar meshes during combat). For a mobile target, 1,400–1,600 draw calls is too many.
  Recommended next steps, in order: (1) disable shadow casting on unit sprites and use a blob shadow decal or 1 shared
  MultiMesh, (2) draw HP bars only for selected/damaged units in a single MultiMesh, (3) MultiMesh the trees,
  (4) LOD/merge for far zoom.

### Environment pass cost (same benchmark, `perf_ottomans_igpu_env_pass.csv`)

| Units / team | Zoom | FPS before env pass | FPS after | Draw calls before → after |
|---|---|---|---|---|
| 0 | default | 131.5 | 111.6 | 589 → 562 |
| 0 | far | 129.1 | 113.4 | 695 → 707 |
| 50 | default | 93.5 | 85.8 | 1235 → 1204 |
| 80 | default | 80.8 | 81.0 | 1565 → 1559 |

≈ +1.3 ms/frame on the iGPU, fill-rate (ground shader with 5 texture reads, scatter overdraw, water), not draw calls.
On a phone this is the cost to watch. A low-quality toggle (scatter off, ground texture count 4 → 2) is the obvious knob.

## 5. Known limitations

* Units, farms, castles and 117 other building cells still use the earlier art (ASSET_INVENTORY.md §3).
* Android/iOS export not validated: there are no export presets.
* Gallery-fidelity gaps listed in ART_DIRECTION_BIBLE.md §8.
