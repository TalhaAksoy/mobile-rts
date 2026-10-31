# Linux Compatibility Audit — Pocket Empires 3D

Date: 2026-10-31 · Scope: Phase 0 (baseline) + Phase 1 (Linux recovery)

## 1. Environment (measured, not assumed)

| Item | Value |
|---|---|
| OS | CachyOS Linux, kernel 7.3.0-4-cachyos |
| Godot | `/usr/bin/godot` → 4.7.2.stable.arch_linux |
| Blender | `/usr/bin/blender` → 5.2.3 LTS (glTF exporter present; Draco available, MeshOptimizer lib missing — not needed) |
| GPU in use | Intel Raptor Lake-S iGPU via Mesa 26.2.5, OpenGL 4.6 Core, Godot **Compatibility** renderer |
| Second GPU | NVIDIA `10de:28e0` present but GLX fails (`failed to load driver: nvidia-drm`, `glx: failed to create dri3 screen`). Godot silently falls back to the Intel iGPU. Harmless for development; every FPS number in this repo was measured on the iGPU. |
| Project root | `sample_project/` (`project.godot`, `config/features=4.7`) |
| Main scene | `res://scenes/Main3D.tscn` (`GameController3D.gd`) |
| Renderer | `gl_compatibility` for desktop and mobile; MSAA 3D 2x |
| Display | 540×960 portrait, `canvas_items` stretch, `expand` aspect, handheld orientation = portrait |
| Export presets | **None** (`export_presets.cfg` absent) → Android/iOS export cannot be validated yet |
| Addons / native libs | None |
| Godot MCP | `godot-mcp` 0.1.1 (repo folder, built locally, registered in user-local Claude config). 14 tools; verified: `get_godot_version`, `list_projects`, `get_project_info`, `run_project`, `get_debug_output`, `stop_project`. **No screenshot tool**, so screenshots come from `scripts/tools/capture_gameplay.gd`, run against the real Main3D scene. |
| Blender MCP | addon 1.8 / protocol 15. Asset libraries and AI generators all off. `execute_blender_code` and `look` verified. |

## 2. MCP verification (non-destructive)

* **Blender:** created a temp scene (body cube plus a "door" box on −Y), saved `verify.blend`, exported `verify.glb` (3.8 KB) to the session scratchpad.
* **Godot:** copied the GLB into a temp `res://_tmp_verify/` folder, ran `--import`, instantiated it and read the transforms. The door at Blender `(0,-1.1,0.5)` lands at Godot `(0,0.5,1.1)`. So **Blender −Y = Godot +Z = gameplay front** (the camera looks toward −Z, and rally points sit at +Z). Scale is 1:1. Temp folder and import cache removed afterwards.
* **Side effect to note:** the first Blender verification call used `read_homefile`, which replaced the scene open in the user's Blender at the time. That scene was the unsaved default startup scene (Cube/Light/Camera), so no user work was lost.
* `run_project` (Godot MCP) launched Main3D in a window. Output had **0 script errors**, only GDScript warnings (unused variables, constant names shadowing `class_name`s, integer division).

## 3. Filesystem / path audit

| Check | Result |
|---|---|
| `/Users/…`, `/Applications/…`, `C:/` in `.gd/.tscn/.json/.cfg/.md` | none |
| Literal `res://` references (36 unique) resolve with exact case | all resolve |
| Dynamic building/unit art paths (manifest `path` fields, 130 building sprites) | all load (see test below) |
| `.uid` sidecars | one per script, regenerated cleanly on import |
| Symlinks | none |
| `.blend` imports (need Blender on every machine) | none in project. New pipeline ships `.glb` only (see BLENDER_PIPELINE.md) |
| macOS-only artifacts | `oyna.command` hardcodes `/Users/<name>/Downloads/Godot.app/...`. Kept as is (macOS convenience launcher, preserves macOS portability). On Linux use `make run` (GODOT_BIN defaults to `godot` on PATH). |
| Large archives in project | `PocketEmpires_*.zip` (≈54 MB) + `morris-roman.zip`. Godot doesn't import them, but they would end up in an export. **Recommend excluding them from export presets** once presets exist. |

**Conclusion: no Linux blockers found.** A clean `.godot/` cache rebuild (`godot --headless --import`, 3.4 s) finished with no errors.

## 4. Runtime error audit

### `get_closest_dropoff()` (previously "Expected 2 argument(s)")
* `GameController3D.get_closest_dropoff(from_pos, team, res_type := "")` now takes 2 or 3 args and routes to `get_closest_dropoff_for_resource` when a type is given.
* Callers: `Unit3D._find_valid_dropoff()` uses `has_method`/`call` with the resource type, falling back to 2 args. Tests `test_gather_deposit.gd` (2-arg and 3-arg) and `test_phase1_validation.gd` (wood/gold/food camp routing) pass.
* **Status: the error no longer occurs.** Over 10×300 s bot simulations: 0 `SCRIPT ERROR` lines.

### Bugs found and fixed in this pass

| # | Bug | Root cause | Fix | Regression test |
|---|---|---|---|---|
| L1 | Tapping a second villager while one is selected sometimes failed to switch selection. It issued a gather order instead. Map-dependent: only when a tree, mine or bush was within 48 px on screen. | `_handle_3d_click()` checked "resource interaction" before "friendly unit tap", even though `_get_entity_at_position()` had already resolved a friendly unit (units are meant to have absolute priority). | Friendly-unit branch now runs before the resource branch. An imprecise tap next to the *single already-selected* unit still falls through, so a nearby tree is gathered or the ground gets a move order, as before. | `scripts/tests/test_unit_tap_priority.gd` (fails 3/6 on the old code, passes 6/6 on the new). `test_single_unit_selection.gd` passes 6/6 runs. |
| L2 | `test_single_unit_selection.gd` hung until timeout on failure. | `assert()` halts the function before `quit()`. | Replaced with a non-halting `_expect()` that prints and `quit(1)`s. | — |
| L4 | **Melee units could never damage buildings.** A swordsman ordered to attack an enemy Town Center stood next to it indefinitely (distance stayed 4.0 m, 0 damage in 10 s). | `_process_attack_target()` compared `attack_range` (≈2 m) to the distance to the building's *center*. The footprint edge of a 2×2 building is ≥1.8 m from center and pathing stops at the nearest free cell, so a 3×3 TC was never in range. | New `Unit3D._distance_to_attack_target()` measures to the footprint rectangle edge for `Building3D` targets. Unit-vs-unit is unchanged. | `scripts/tests/test_combat.gd` (new): spear-vs-cavalry counter hit (18.0 = 8·2.5 − 2 armor), duel resolution, archer projectile kill, swordsman damages TC. Before the fix the TC case failed (3240→3240). |
| L5 | **Resource nodes spawned inside Town Center footprints**: 7 of 12 sampled maps (player and enemy bases). This hijacked taps on the TC (a cargo villager tapping its TC went gathering instead of depositing), blocked TC cells and showed gold crystals under the TC. | Random gold/stone/food clusters (`_find_random_empty_spot` + flood-fill `_spawn_resource_cluster`) had no keep-out around start positions (trees did: 4 cells). | `MapGenerator3D._is_in_base_keepout()` (radius 4 cells) applied to random spots and cluster growth. Base clusters (placed ≥5 cells out) are unaffected. | `scripts/tests/test_map_base_keepout.gd` (new): 30 seeded maps, both map types. PASS 30/30. With the fix disabled: FAIL 29/30. |
| L6 | **Bot food starvation deadlock**: bot frozen at pop 7, 6 villagers "gathering food" at 32 food, 0 wood (reproducible with seeds 12 and 20, and on the original code too). | A boxed-in berry bush: A* falls back to the nearest free cell 2+ cells away. The villager arrives, is still out of range, recomputes the same finished path and stands still forever. | `Unit3D._process_gathering`: if the path is exhausted while still out of range → `map_gen.mark_resource_unreachable()` and retarget. `find_nearest_resource_node` and `EnemyAI3D._send_to_resource` skip marked nodes. Marks reset on any walkability change. | `scripts/tools/bot_stall_probe.gd` (seeded): original code 1/20 stalls, before fix 2/20, after fix **0/130** (Chinese ×40 + 9 civs ×10). The 300 s bot test passes. |
| L9 | **Bot construction sites stuck at 0% for the rest of the match** (5/24 seeded games). The builder stood still forever, and `_is_building_in_progress()` then blocked that building type. | (a) Builders had the same exhausted-path loop as L6. (b) The bot validated site reachability from the *blocked* TC centre, whose path escapes into whatever sealed pocket the site is in. (c) Nobody re-tasked a builderless site. | Builder gives up when it can't get closer. `_find_build_spot` validates reachability from the **worker's** cell. Bot re-tasks builderless sites (idle villager first, otherwise borrows one). Watchdog cancels and refunds sites with no progress for 60 s of game time. | `bot_stall_probe.gd`: in final code every "unfinished site at 300 s" occurs in a game that already ended (bot destroyed the passive test player's TC: 21/24 games). 0 stalls in 48 seeded games (Chinese, Ottoman). |
| L10 | Units standing where a new building was placed were trapped inside its blocked footprint, so every path for them came back empty. | `place_building()` registered the footprint without moving units out. | `GameController3D._eject_units_from_footprint()` moves them to the nearest walkable cell outside. | covered by the bot probe (stuck builder at a blocked cell no longer occurs) and the full suite |
| L7 | A cargo villager tapping its own building could be redirected to a nearby resource. | Fuzzy 48 px resource search ran before the ally-building branch. | `_find_resource_at_click(..., precise_only)`: when the tap resolved to a friendly building, only exact-cell / collider-ray resource hits may override it. | `test_selection_and_commands.gd` step 6 (10/10 runs) |
| L8 | Seven older tests hung until the runner timeout on any failed check, hiding all later results. Two used fixed ground points that randomly landed on resources. | `assert()` halts the function before `quit()`. Map-dependent tap positions. | Non-halting `_expect()` in all 8 asserting test files (102 asserts converted in this pass, plus test_single_unit_selection earlier). `test_selection_and_commands` searches for ground the click handler itself reports as empty. | 10/10 consecutive runs |
| L3 | `test_building_art_import.gd` reported 130 failures. | Test was stale. It asserted the v1 pack (384×384, 14 types incl. farm/market/wall), but the v2 atlas-exact manifest declares variable `size_px` and 13 types. Art was fine. | Test now reads the manifest and checks every entry's declared size. | itself: 130/130 PASS |

## 5. Test baseline after Phase 1

Command pattern: `godot --headless --path sample_project --script res://scripts/tests/<name>.gd`

| Test | Result |
|---|---|
| test_selection_and_commands | PASS |
| test_phase1_validation | 27/27 PASS |
| test_gather_deposit | PASS |
| test_full_rts_suite | PASS |
| test_building_art_integration | 34/34 PASS |
| test_building_art_import | 130/130 PASS (after L3) |
| test_gallery_and_roster | PASS |
| test_art_pack_integration | PASS |
| test_selection_and_tc | PASS |
| test_single_unit_selection | PASS ×6 (after L1/L2) |
| test_zoom_and_bottom_bar | PASS |
| test_unit_tap_priority (new) | 6/6 PASS ×3 |
| test_combat (new) | 8/8 PASS |
| test_bot_300s_simulations | 10/10 "SUCCESS", 0 script errors (before and after L4) |

| test_map_base_keepout (new) | 30/30 maps PASS |
| test_building_models (new) | 190 checks PASS (13 buildings) |

Full suite runner: `./run_tests.sh [log_dir]` (repo root). Final run: **16/16 test files exit 0, 0 `SCRIPT ERROR`**.

## 6. Known issues recorded (not blockers, not yet fixed)

* **Bot sims now often end early:** since L4 (melee damages buildings) the bot's army destroys the *passive* test player's Town Center before 300 s in most seeded games. The 300 s test still passes (it checks economy health), but "pop at 300 s" is no longer comparable with pre-L4 runs.
* **Bot military spending is uneven.** Baseline run: the Mongol bot ended at 300 s with 0 military units and 844 gold / 600 food unspent. After L4 the Frankish bot ended with 0 military and 1100 food unspent. Results vary between runs (bot sims are not fully seeded). The test only checks that the economy didn't stall, so it reports SUCCESS anyway.
* **Post-processing (corrected):** `Main3D.tscn` listed near/far DOF keys on the `Environment` resource. Godot 4 has no DOF properties there (DOF lives on `CameraAttributes`), so **DOF never ran**. The keys were removed in the environment pass. Glow (bloom 0.16) is active.
* **Visuals:** buildings, trees and units are all camera-facing sprites (`Sprite3D`, `BILLBOARD_FIXED_Y`). The Town Center sprite covers only about ⅓ of its 5.4 m footprint (baseline screenshots in `docs/audits/evidence/baseline/`).
* GDScript warnings (≈20) are cosmetic and were left alone to keep the diff focused.
* No export presets, so the Android/iOS build is **not validated**.

## 7. Phase 1 acceptance

| Requirement | Evidence | Status |
|---|---|---|
| Project imports | `--import` exit 0, no errors | PASS |
| Main scene launches | Godot MCP `run_project`, 0 script errors | PASS |
| Main menu works / civ selection | `test_gallery_and_roster`, `test_full_rts_suite` | PASS (automated) |
| Match starts | all gameplay tests call `start_match()` on the real Main3D | PASS |
| Villagers gather + deposit | `test_gather_deposit`, `test_phase1_validation` | PASS |
| Units produced / queue / cancel | `test_phase1_validation` | PASS |
| Buildings constructed | `test_phase1_validation` (Lumber Camp placement + build) | PASS |
| Basic combat | `test_combat` (new; the older `test_full_rts_suite` only *spawns* units and never fights) | PASS after fix L4 |
| No recurring script errors | 10×300 s sims: 0 | PASS |
