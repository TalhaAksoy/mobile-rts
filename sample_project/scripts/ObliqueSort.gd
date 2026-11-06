extends Node3D
## 2D sprite style (orthographic camera straight down, sprites drawn in a 3/4 "oblique" view lying flat):
## painter's order like a 2D game, the further south (larger z) the more in front. Height does not move anything
## on screen with an orthographic top-down camera, so it is used as the sort key (FactionArtManager.oblique_sort_y).
## Static props / buildings sort once when they enter the tree (deferred, after the caller has placed them);
## call apply() again if the node moves or is rescaled.

func _ready() -> void:
	call_deferred("apply")

## Ground sprites (meta "ground": fields) are flat on the earth: always under units, buildings and trees.
func apply() -> void:
	if is_inside_tree():
		if has_meta("ground"):
			global_position.y = FactionArtManager.OBLIQUE_SORT_BASE - 0.5
		else:
			global_position.y = FactionArtManager.oblique_sort_y(global_position.z)
