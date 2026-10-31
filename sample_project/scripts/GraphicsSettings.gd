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
const SCALE_MIN := 50
const SCALE_MAX := 100
const SCALE_STEP := 5

## preset -> values (render scale in %, msaa sample count, shadow level, fps cap)
const PRESETS := {
	Preset.LOW: {"scale": 60, "msaa": 0, "shadows": Shadows.OFF, "fps": 30},
	Preset.MEDIUM: {"scale": 75, "msaa": 0, "shadows": Shadows.LOW, "fps": 60},
	Preset.HIGH: {"scale": 100, "msaa": 2, "shadows": Shadows.HIGH, "fps": 60},
}
## directional shadow atlas size and max distance per shadow level
const SHADOW_ATLAS := {Shadows.LOW: 1024, Shadows.HIGH: 4096}
const SHADOW_DISTANCE := {Shadows.LOW: 50.0, Shadows.HIGH: 75.0}

static var preset: int = Preset.HIGH
static var values: Dictionary = PRESETS[Preset.HIGH].duplicate()
static var _loaded := false


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
	return v


static func load_settings() -> void:
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK or not cfg.has_section(SECTION):
		set_preset(default_preset())
		return
	var p: int = int(cfg.get_value(SECTION, "preset", default_preset()))
	if PRESETS.has(p):
		set_preset(p)
	else:
		set_preset(default_preset())
		for k in ["scale", "msaa", "shadows", "fps"]:
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
		match int(values["msaa"]):
			2: viewport.msaa_3d = Viewport.MSAA_2X
			4: viewport.msaa_3d = Viewport.MSAA_4X
			_: viewport.msaa_3d = Viewport.MSAA_DISABLED
	var sh: int = values["shadows"]
	if light != null:
		light.shadow_enabled = sh != Shadows.OFF
		if sh != Shadows.OFF:
			light.directional_shadow_max_distance = SHADOW_DISTANCE[sh]
	if sh != Shadows.OFF:
		RenderingServer.directional_shadow_atlas_set_size(SHADOW_ATLAS[sh], true)
	Engine.max_fps = values["fps"]


static func describe() -> String:
	return "%s: çözünürlük %%%d, MSAA %s, gölge %s, %d FPS" % [PRESET_NAMES[preset], values["scale"],
		MSAA_NAMES[MSAA_OPTIONS.find(values["msaa"])], SHADOW_NAMES[values["shadows"]], values["fps"]]
