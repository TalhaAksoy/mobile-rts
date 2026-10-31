# Final Gameplay Validation

Date: 2026-10-31 · Linux (CachyOS) · Godot 4.7.2 · Blender 5.2.3 · Intel i7-13650HX + Intel RPL-S iGPU

## 1. Release readiness: **NOT READY**

The Linux baseline is solid. Gameplay bugs found during the work are fixed with regression tests, and the 3D building
pipeline is proven end-to-end. The game is still **not a finished visual overhaul**: 117 building cells, all units, farms,
castles and the terrain still use the earlier art. Mobile builds/performance are **unmeasured** (no export presets, no
device), and unit draw-call cost is too high for a phone target.

## 2. Exact commands

```bash
# import / cache rebuild
godot --headless --path sample_project --import
# every automated test (prints one line per test file, exit 1 on any failure)
./run_tests.sh [log_dir]
# single test
godot --headless --path sample_project --script res://scripts/tests/<name>.gd
# real-game screenshots (needs a display)
godot --path sample_project --script res://scripts/tools/capture_gameplay.gd -- --out=<dir> --civ=<0-9> [--showcase=house,barracks,lumber_camp]
# rendering benchmark (needs a display)
godot --path sample_project --script res://scripts/tools/perf_benchmark.gd -- --out=<file.csv>
# seeded bot-economy probe
godot --headless --path sample_project --script res://scripts/tools/bot_stall_probe.gd -- --civ=<0-9> --seeds=<n> [--first=<seed>]
```

## 3. Automated results (final run)

| Test file | Covers | Result |
|---|---|---|
| test_selection_and_commands | select, ground move, gather wood/gold, empty-ground move, cargo drop-off at TC, attack, box select | PASS (10/10 consecutive runs) |
| test_single_unit_selection | tap/switch/toggle/isolate selection | PASS |
| test_unit_tap_priority (new) | friendly-unit tap vs. nearby-resource tap | PASS |
| test_selection_and_tc | TC selection, click interception | PASS |
| test_zoom_and_bottom_bar | camera zoom, HUD bottom bar | PASS |
| test_phase1_validation | pan/box-select, queue + cancel + refunds, resource pick, HUD resource panel, camp placement, drop-off routing | 27/27 PASS |
| test_gather_deposit | gather → deposit loop, 2/3-arg `get_closest_dropoff` | PASS |
| test_full_rts_suite | economy, production, counters, ages/techs, fog of war, save/load, AI think | PASS |
| test_combat (new) | spear-vs-cavalry counter (exact damage), duel resolution, archer projectiles, melee vs building | 8/8 PASS |
| test_building_models (new) | 13 models: ground contact, footprint, shared materials, team colours, collision, construction states, save/load of unfinished model building, fallbacks | 190 checks PASS |
| test_map_base_keepout (new) | no resources in TC keep-out, each base has gold/stone/food | 30/30 maps PASS |
| test_building_art_integration / _import, test_art_pack_integration, test_gallery_and_roster | sprite art, gallery, civ roster | PASS |
| test_bot_300s_simulations | 10 civs × 300 s bot economy | 10/10 no stall |

Totals: **16/16 test files exit 0, 0 `SCRIPT ERROR` lines.**

Seeded bot-economy probe (`bot_stall_probe.gd`, same maps per seed):
* original code: 1/20 stalls (Chinese). Before the fixes: 2/20 (seeds 12 and 20: pop frozen at 7, 0 wood).
* after the starvation fix (L6): 0/40 Chinese + 0/90 other civs. After the keep-out fix (L5): 0/120 (all 10 civs × 12 seeds).
* final code (L6+L9+L10): 0/48 (Chinese, Ottoman × 24). In 21/24 Chinese games the bot destroyed the passive player's TC before 300 s.

## 4. Gameplay bugs fixed in this work (details: LINUX_COMPATIBILITY_AUDIT.md §4)

L1 unit-vs-resource tap priority · L2/L8 hanging & map-dependent tests · L3 stale art test · **L4 melee units could not damage
buildings** · **L5 resources spawned inside Town Centers (7/12 maps)** · **L6 bot food-starvation deadlock** · L7 cargo
drop-off tap hijacked by fuzzy resource pick · **L9 bot construction sites stuck at 0% forever** · L10 units trapped inside
newly placed buildings.

**Save / load map (found while adding the smooth hills).** Loading regenerates the map from its seed, but:
- Mines, resource clusters, oasis palms, tree species and prop rotation used the global random generator, so gold
  and stone mines came back in different cells. They now use the map's own seeded generator, and every map type
  regenerates identically.
- The stone mine list was never cleared on regenerate. After a load, the old map's invisible stone mines stayed,
  blocking cells and still gatherable.
- Nothing that had been used up was saved. Cut trees, mined-out mines and eaten bushes came back full. Saves now
  store what is left of every node.

Covered by `test_save_load_map` (all 5 maps).

## 5. Spec §13 checklist

| Area | Item | Evidence | Status |
|---|---|---|---|
| Economy | 4 resource types gathered | test_full_rts_suite, test_selection_and_commands, bot sims | PASS |
| | amounts decrease / no duplication | test_gather_deposit, test_phase1_validation | PASS |
| | auto retarget after depletion, search radius | test_phase1_validation; L6 adds unreachable skip | PASS |
| | drop-off camps accept correct types | test_phase1_validation (wood→lumber, gold→mining, food→mill) | PASS |
| | resource panel shows real amounts | test_phase1_validation | PASS |
| Construction | placement, selected villagers auto-assigned to the blueprint, progress → completion, operational drop-off | test_phase1_validation ("Lumber Camp placed", "villagers assigned to construct", camp routing); test_building_models (progress/complete) | PASS |
| | building cost deducted exactly once | only unit-production deduction/refund is asserted (test_phase1_validation) | NOT EXECUTED |
| | invalid placement rejected | not separately re-tested in this pass | NOT EXECUTED |
| | buildings attacked & destroyed | damage: test_combat (TC takes damage); full destruction not run to 0 HP in a test | PARTIAL |
| Military | spawn, move, attack, counters, damage math | test_combat, test_full_rts_suite | PASS |
| | models match civ | units are still civ-specific **sprites** (no 3D units) | N/A (sprites) |
| | attack animations | sprite swing/bob only (pre-existing), no 3D animation set | NOT STARTED |
| | navigation respects footprints | footprints unchanged (A* cells registered by `place_building`) | PASS (unchanged code path) |
| Bots | gather, build, train villagers/soldiers, no starvation deadlock | bot sims 10/10; seeded probe 0 stalls after fixes (L6, L9, L10) | PASS |
| | appropriate targets / full matches to victory | not run to victory in this pass. **Uneven military spending observed** (e.g. Viking bot: 0 military, 3335 food unspent at 300 s) | PARTIAL / known issue |
| Save/load | building type & civ, queues, resources, unfinished buildings, no duplicates | test_full_rts_suite, test_building_models (unfinished model building) | PASS (production queue / villager task persistence not separately asserted) |
| Platform | loads on Linux | import + MCP run_project, 0 errors | PASS |
| | macOS portability preserved | no macOS paths added. `oyna.command` kept | PASS (not run on macOS) |
| | Android / iOS export | no export presets in repo | NOT EXECUTED |

## 6. Performance (measured, desktop iGPU only)

See BLENDER_GODOT_INTEGRATION_REPORT.md §4 and `docs/audits/evidence/perf/perf_ottomans_igpu.csv`.
80 units/team: 80.8 FPS (models) vs 75.4 (sprites) at 1,565 vs 1,404 draw calls. The main bottleneck is per-unit draw calls
(~7 each). **No mobile FPS is claimed**: no device was available.

## 7. Known remaining issues

1. Visual overhaul incomplete (ASSET_INVENTORY.md §3); units are sprites.
2. Unit draw calls too high for mobile; trees not instanced.
3. Bot military spending is uneven (pre-existing; not addressed).
4. (Resolved by the environment pass) The grass no longer reads as flat neon. Environment pass costs ≈1.3 ms/frame on the iGPU (integration report §4).
5. The tutorial hint label overflows the top HUD bar and minimap at 540×960 (pre-existing UI issue, visible in captures).
6. No export presets, so no Android/iOS validation.
7. ~20 GDScript warnings (unused variables, shadowed class names). Cosmetic.
8. (Fixed) Mine depletion size is now restored after loading a save, together with the remaining amount.
9. 3D trees/mines in explored-but-not-visible fog are not dimmed (the sprite path tinted them; the fog overlay still darkens the area).
10. Bot sims end early against the passive test player (consequence of L4), so 300 s population is not comparable with older runs.

## 8. MCP usage log

**Blender MCP** (`execute_blender_code`, `look`, `get_addon_status`, `get_scene_info`): addon status and scene inspection;
temp verification scene + GLB export; material library bake; 17 assets built, each iterated with `look` (≈25 look calls);
`build_all.py` batch builds with preview renders. Failures: one call used `read_homefile`, which replaced the open default
scene (no user data lost, see Linux audit §2). One script hit `active_object` missing after `read_homefile`. One review
script deleted its own mesh copies (`ReferenceError`). Each was fixed by changing the approach.

**Godot MCP** (`get_godot_version`, `list_projects`, `get_project_info`, `run_project`, `get_debug_output`, `stop_project`):
version/project inspection; launched the main scene and read its debug output (0 script errors). The server has no
screenshot or scene-instancing-at-runtime tool, so screenshots, tests and benchmarks ran through `godot` CLI scripts against
the same project (`capture_gameplay.gd`, `perf_benchmark.gd`, tests). Failures: none.
