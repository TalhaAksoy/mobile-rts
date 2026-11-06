class_name GraphicsSettings
extends RefCounted
## Graphics quality: presets (Low / Medium / High) plus individual options. Changing any single option by
## hand turns the preset into CUSTOM. Saved in user://settings.cfg (section "graphics"), applied to the
## root viewport (3D resolution scale, MSAA), the scene's DirectionalLight3D (shadows) and Engine.max_fps.
##
## Numbers behind the presets: docs/audits/MOBILE_PERFORMANCE.md (pixel cost dominated: 3D resolution
## and MSAA moved FPS most, shadows next).

enum Preset { LOW, MEDIUM, HIGH, CUSTOM }
enum Shadows { OFF, LOW, HIGH }

const PATH := "user://settings.cfg"
const SECTION := "graphics"

const PRESET_NAMES := ["Düşük", "Orta", "Yüksek", "Özel"]
const MSAA_OPTIONS := [0, 2, 4]                       # 0 = off, 2x, 4x
const MSAA_NAMES := ["Kapalı", "2x", "4x"]
const SHADOW_NAMES := ["Kapalı", "Düşük", "Yüksek"]
const FPS_OPTIONS := [30, 60]
const STYLE_NAMES := ["3D Model", "2D Sprite"]      # 2D = sprites rendered in Blender from the same models
const SCALE_MIN := 50
const SCALE_MAX := 100
const SCALE_STEP := 5

## preset -> values (render scale in %, msaa sample count, shadow level, fps cap, style 0 = 3D / 1 = 2D,
## effects 0 = none / 1 = vignette / 2 = vignette + glow)
## Glow is several full-screen blur passes: the most expensive effect on a phone GPU and nearly invisible in this
## art (2D: no visible change; 3D: sunlit grass a touch brighter), so only Yüksek keeps it. Measured on desktop,
## the empty 2D scene went 6.1 -> 3.3 ms per frame without glow; the vignette is another 0.4 ms.
const PRESETS := {
	Preset.LOW: {"scale": 60, "msaa": 0, "shadows": Shadows.OFF, "fps": 30, "style": 1, "effects": 0},
	Preset.MEDIUM: {"scale": 75, "msaa": 0, "shadows": Shadows.LOW, "fps": 60, "style": 0, "effects": 1},
	Preset.HIGH: {"scale": 100, "msaa": 2, "shadows": Shadows.HIGH, "fps": 60, "style": 0, "effects": 2},
}
## directional shadow atlas size and max distance per shadow level
const SHADOW_ATLAS := {Shadows.LOW: 1024, Shadows.HIGH: 4096}
const SHADOW_DISTANCE := {Shadows.LOW: 50.0, Shadows.HIGH: 75.0}

static var preset: int = Preset.HIGH
static var values: Dictionary = PRESETS[Preset.HIGH].duplicate()
static var _loaded := false
## Headless runs (tests, CI) use the defaults instead of the player's saved file, so a player who picked
## 2D sprites does not change what the 3D tests see. test_graphics_settings turns this on.
static var read_saved_when_headless := false


static func default_preset() -> int:
	return Preset.MEDIUM if OS.has_feature("mobile") else Preset.HIGH


## Selecting a preset copies its values.
static func set_preset(p: int) -> void:
	if not PRESETS.has(p):
		return
	preset = p
	values = PRESETS[p].duplicate()


## A manual change of one option: the preset becomes CUSTOM.
static func set_value(key: String, v) -> void:
	values[key] = _sanitize(key, v)
	preset = Preset.CUSTOM


static func _sanitize(key: String, v):
	match key:
		"scale":
			return clampi(int(round(float(v) / SCALE_STEP)) * SCALE_STEP, SCALE_MIN, SCALE_MAX)
		"msaa":
			return int(v) if int(v) in MSAA_OPTIONS else 0
		"shadows":
			return clampi(int(v), Shadows.OFF, Shadows.HIGH)
		"fps":
			return int(v) if int(v) in FPS_OPTIONS else 60
		"style":
			return clampi(int(v), 0, 1)
		"effects":
			return clampi(int(v), 0, 2)
	return v


static func load_settings() -> void:
	_loaded = true
	var cfg := ConfigFile.new()
	if DisplayServer.get_name() == "headless" and not read_saved_when_headless:
		set_preset(default_preset())
		return
	if cfg.load(PATH) != OK or not cfg.has_section(SECTION):
		set_preset(default_preset())
		return
	var p: int = int(cfg.get_value(SECTION, "preset", default_preset()))
	if PRESETS.has(p):
		set_preset(p)
	else:
		set_preset(default_preset())
		for k in ["scale", "msaa", "shadows", "fps", "style", "effects"]:
			values[k] = _sanitize(k, cfg.get_value(SECTION, k, values[k]))
		preset = Preset.CUSTOM


static func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(PATH)                       # keep other sections (audio, ...)
	cfg.set_value(SECTION, "preset", preset)
	for k in values.keys():
		cfg.set_value(SECTION, k, values[k])
	cfg.save(PATH)


static func ensure_loaded() -> void:
	if not _loaded:
		load_settings()


## Applies the current values. `light` may be null (no 3D scene yet).
static func apply(viewport: Viewport, light: DirectionalLight3D = null) -> void:
	ensure_loaded()
	if viewport != null:
		viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		viewport.scaling_3d_scale = values["scale"] / 100.0
		if int(values.get("style", 0)) == 1:
			# 2D style: pixel art must be rendered at full resolution (a reduced 3D scale blurs it and drops
			# pixel rows); flat sprites + one terrain mesh are cheap, the other LOW savings still apply
			viewport.scaling_3d_scale = 1.0
		match int(values["msaa"]):
			2: viewport.msaa_3d = Viewport.MSAA_2X
			4: viewport.msaa_3d = Viewport.MSAA_4X
			_: viewport.msaa_3d = Viewport.MSAA_DISABLED
	var sh: int = values["shadows"]
	if light != null:
		light.shadow_enabled = sh != Shadows.OFF
		if sh != Shadows.OFF:
			light.directional_shadow_max_distance = SHADOW_DISTANCE[sh]
			# every split draws the shadow casters again: 2 on Orta (no visible change at game zoom, ~10-15 % fewer
			# drawn triangles in a 60-a-side battle), 4 on Yüksek
			light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if sh == Shadows.LOW \
				else DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	if sh != Shadows.OFF:
		RenderingServer.directional_shadow_atlas_set_size(SHADOW_ATLAS[sh], true)
	Engine.max_fps = values["fps"]
	apply_effects(viewport)
	# Simulation rate follows the frame cap: at 30 fps (Düşük, the low-end preset) the game ticks 30 times a second, one
	# tick per frame, so the per-frame simulation cost halves and nothing judders; 60 fps presets keep 60 ticks.
	# At most 2 ticks per frame: on a slow phone a long frame used to run up to 8 catch-up ticks, which made the next
	# frame longer still (measured with scripts/tools/device_tiers.sh); now the game slows down a little instead.
	Engine.physics_ticks_per_second = 30 if int(values["fps"]) > 0 and int(values["fps"]) <= 30 else 60
	Engine.max_physics_steps_per_frame = 2
	# 3D models or Blender-rendered sprites: read when buildings / map props are created (next match)
	FactionArtManager.use_3d_building_models = int(values.get("style", 0)) == 0


static func describe() -> String:
	return "%s: %s, çözünürlük %%%d, MSAA %s, gölge %s, %d FPS" % [PRESET_NAMES[preset], STYLE_NAMES[values["style"]],
		values["scale"], MSAA_NAMES[MSAA_OPTIONS.find(values["msaa"])], SHADOW_NAMES[values["shadows"]], values["fps"]]


## Glow on the scene's WorldEnvironment and the HD-2D vignette layer, per the "effects" value.
static func apply_effects(viewport: Viewport) -> void:
	if viewport == null:
		return
	var fx := int(values.get("effects", 2))
	for we in viewport.find_children("*", "WorldEnvironment", true, false):
		var env: Environment = (we as WorldEnvironment).environment
		if env != null:
			env.glow_enabled = fx >= 2
	for v in viewport.find_children("HD2DVignette", "CanvasLayer", true, false):
		v.visible = fx >= 1
