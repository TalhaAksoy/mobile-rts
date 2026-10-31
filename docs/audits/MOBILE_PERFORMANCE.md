# Mobile performance: benchmark tool and first results (Android emulator)

Date: 2026-10-31. **No physical phone has been measured yet.** All Android numbers below come from the Android Studio
emulator, which renders through the desktop GPU (Intel RPL-S iGPU, via the emulator's GLES translator). They show
that the game runs on Android/GLES3 and what the **relative** cost of each setting is in that environment. They are
not phone FPS, and phone GPUs (tile-based Adreno / Mali / PowerVR) behave differently. In particular, MSAA is usually
cheap on tile-based GPUs, and draw calls cost more CPU on low-end phones.

## Tool

* `sample_project/scripts/tools/Benchmark.gd` + `scenes/Benchmark.tscn`: a fixed scenario.
  * Setup: seed 5, Yeşil Vadi, Britons vs Japanese, one of every building type, a mill with 6 farmed fields, bot off.
  * Per phase: 4 s warm-up, then 15 s of measurement.
  * Output: one `PE_BENCH {json}` line per phase (logcat tag `godot`), plus `user://benchmark.json` and an on-screen table.
* The export preset **Android Benchmark** has the custom feature `benchmark`. With it,
  `application/run/main_scene.benchmark` makes the benchmark the main scene. The normal game is unchanged (preset
  **Android**).
* `tools/android_benchmark.sh [out_dir]` exports the preset, installs it on the attached device or emulator, runs it,
  prints the results and pulls `benchmark.json`. Desktop: `godot --path sample_project res://scenes/Benchmark.tscn`.
* Setup that was needed on this machine:
  * Godot 4.7.2 Android export templates in `~/.local/share/godot/export_templates/4.7.2.stable/`.
  * Godot editor setting `export/android/java_sdk_path` pointed at Android Studio's bundled JDK.
  * A debug keystore at the path the editor settings expect.
  * Project setting `rendering/textures/vram_compression/import_etc2_astc=true`, which Android export requires.

## Results: Android emulator (sdk_gphone64_x86_64, 1080×2400, OpenGL ES 3.0, vsync forced on)

The game renders 3D at the **full window resolution (1080×2400)** with **2× MSAA** and directional shadows.

| Phase | Run 1 FPS | Run 2 FPS | p50 / p99 ms (run 1) | Draw calls | Primitives |
|---|---|---|---|---|---|
| base, 3D buildings | 29.0 | 29.4 | 33.5 / 41.3 | 709 | 105k |
| base, far zoom | 28.8 | 32.0 | 34.7 / 43.5 | 761 | 117k |
| base, shadows off | 32.2 | 36.3 | 31.3 / 40.0 | 386 | 47k |
| base, **sprite** buildings (old art) | 29.1 | 36.2 | 34.7 / 42.9 | 489 | 32k |
| base, **3D at 50% resolution** | **51.8** | 42.4 | 19.2 / 22.2 | 709 | 105k |
| base, **MSAA off** | **41.4** | 41.5 | 24.1 / 33.1 | 709 | 105k |
| battle (60 units spawned), 3D buildings | 27.2 | 22.7 | 36.2 / 56.5 | 892 | 119k |

Run-to-run variation is large, up to about ±20% (the emulator shares the desktop). Only the big effects are reliable:

1. **Pixel cost dominates in the emulator.**
   * Halving the 3D resolution: about +45–80% FPS.
   * Turning MSAA off: about +40%.
   * Draw calls and primitives did not change in either case.
2. **3D buildings vs the old sprites: no measurable difference** (29.0 vs 29.1 in run 1; run 2 favours sprites, but
   within the noise). The 3D buildings add about 220 draw calls and 70k primitives here, but that is not where this
   emulator's time goes.
3. **Shadows** halve the draw calls (709 → 386) and cut primitives by 55%, for about +10–20% FPS.
4. **Memory**:
   * Video memory: about 165 MB at full resolution with MSAA, about 86–88 MB at 50% scale or without MSAA.
   * Static memory: about 92 MB.

Desktop reference (same tool, 540×960 window, vsync off): 146 FPS with 3D buildings, 157 with sprites, 190 without
shadows. This is only for comparison.

## Graphics settings (Ayarlar > Grafik Kalitesi)

`scripts/GraphicsSettings.gd` + the settings screen (`MenuRoot._build_graphics_settings`):

* **Presets:** Düşük / Orta / Yüksek, plus **Özel**. Özel is selected automatically as soon as the player changes any
  single option by hand. Tapping Özel keeps the current values.
* **Options:**
  * 3D resolution: 50–100% in 5% steps (`Viewport.scaling_3d_scale`, bilinear).
  * MSAA: off / 2x / 4x.
  * Shadows: off / low (1024 atlas, 50 m) / high (4096 atlas, 75 m).
  * Frame cap: 30 / 60 FPS.
* **Saving:** applied immediately, and on game start. Saved to `user://settings.cfg` when the settings screen is closed
  (volume and camera speed are saved there too now).
* **Default with no saved file:** Orta on phones (`OS.has_feature("mobile")`), Yüksek on desktop. Yüksek equals the look
  before the menu existed.

| Preset | Look | 3D resolution | MSAA | Shadows | FPS cap |
|---|---|---|---|---|---|
| Düşük | 2D sprites | 60% | off | off | 30 |
| Orta | 3D models | 75% | off | low | 60 |
| Yüksek | 3D models | 100% | 2x | high | 60 |

**Görünüm (look):**
* **3D Model:** the Blender models.
* **2D Sprite:** sprites rendered in Blender from the same models (BLENDER_PIPELINE §3.2).

It is read when a match is created. Changing it by hand makes the preset Custom, like every other option.

Emulator run 5 (the frame cap is lifted while measuring; Düşük now uses 2D sprites):

| Preset / phase | FPS | p50 / p99 ms | Draw calls | Primitives | Video memory |
|---|---|---|---|---|---|
| Düşük (2D) | 52.3 | 19.2 / 21.3 | 270 | 19k | 73 MB |
| Orta | 50.8 | 19.4 / 27.4 | 661 | 96k | 78 MB |
| Yüksek | 29.6 | 33.3 / 45.2 | 709 | 105k | 127 MB |
| High settings, 2D sprites | 36.5 | 27.3 / 37.5 | 283 | 29k | 127 MB |
| High settings, 3D models | 30.1 | 33.3 / 41.2 | 709 | 105k | 126 MB |

With equal settings, 2D sprites cut draw calls by 60% and primitives by 70% (about +20% FPS in the emulator).

Earlier runs measured "base_sprites" with the old hand-drawn sprites. Before the fix in run 5, the settings were
applied after the match had started, so the look option did not take effect in that phase.

Test: `scripts/tests/test_graphics_settings.gd`. It covers the presets, Custom on a manual change, applying the settings,
the menu controls, and save/load. It backs up and restores the user's settings file.

## Smooth hills: geometry cost (desktop measurement, not phone FPS)

The stepped terraces were replaced by one smooth ground mesh: a 65×121 vertex grid, about 15.4k triangles. The
per-cell water quads (73–95 per water map) became one water surface. Measured with `capture_gameplay.gd`, River
Crossing, seed 7, 3D style, desktop High preset:

| | draw calls | primitives |
|---|---|---|
| before (stepped terraces) | 385 | 72,249 |
| after (smooth hills) | 386 | 105,486 |

Draw calls do not change. Primitives rise by about 33k: the ground mesh is drawn in the colour pass and again in
the shadow pass. On the Low preset, shadows are off, so the shadow-pass copy is not drawn. This has not been
measured on the emulator or a phone yet, so no FPS claim is made here.

## Bugs found by running on Android (fixed)

* **Main menu background was empty in exported builds.** `MenuRoot.gd` read the raw `battle_bg.png` from disk, which
  is not packed into exports. It now loads the imported texture.
* **Buildings (and often units) could not be selected by tap or click.** This was pre-existing.
  * Cause: `project.godot` enables both touch→mouse and mouse→touch emulation, so every tap reached
    `GameController3D._unhandled_input` twice: the real event and an emulated copy. The first copy selected the
    building; the second, a "tap on the already selected building", deselected it again.
  * Fix: the handler now ignores emulated pointer events (`InputEvent.DEVICE_ID_EMULATION`).
  * Earlier tests called the click handler directly and missed this. `test_real_input_taps.gd` taps through
    `Input.parse_input_event` with emulation active:
    * every building type in 3D and 2D, with mouse and finger;
    * a second tap deselects;
    * the train button, villager select/move, and drag-to-pan.

    Without the fix it reports 0/11 buildings selectable.
  * Also confirmed on the emulator: tapping the Town Center opens its panel, and "İşçi Eğit" trains exactly one villager.
* **Zoom buttons showed missing-glyph boxes (FF0B / FF0D) on Android.** The full-width "＋/－" characters are not
  in the Android fonts. They are now ASCII `+` / `-`. The gallery's emoji (⚔ 🏛 📜) render fine on Android.

## Not done / next

* **Measure on a real phone.** USB or wireless debugging, then `tools/android_benchmark.sh`. A low-end and a mid-range
  device would bracket the target.
* Candidate optimisations, not applied, to decide after phone numbers:
  * a 3D resolution scale for mobile (e.g. 0.6–0.75), possibly as a setting;
  * MSAA off or FXAA on mobile;
  * shadow distance or resolution tuned for the RTS camera;
  * per-building material atlases (fewer draw calls) if the phone turns out to be CPU/draw-call bound.
* The APK is 109 MB, mostly the two architectures (arm64 + x86_64 for the emulator). A store build would be arm64 only.
