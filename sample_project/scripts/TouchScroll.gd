class_name TouchScroll
extends Node
## Finger scrolling for every ScrollContainer, started anywhere on it - also on a button or a card.
##
## Godot's ScrollContainer only drags when the touch starts on its own background: a press on a child
## button stays with the button, so a build menu full of cards could only be scrolled through the gaps
## between them or with the thin scroll bar. Here every control inside a ScrollContainer reports its
## (emulated) mouse input; once the finger has moved DEADZONE px along a scrolling axis the press is
## taken from the button (it will not fire on release) and the list follows the finger, with a short
## glide after letting go. A tap that does not move still presses the button as before.

const DEADZONE := 12.0          # px the finger has to travel before a press turns into a scroll
const GLIDE_DECAY := 5.0        # 1/s, how fast the glide after letting go slows down
const GLIDE_MIN := 30.0         # px/s, below this the glide stops

var _sc: ScrollContainer = null         # list being pressed / dragged
var _button: BaseButton = null          # button the press landed on (cancelled once it is a drag)
var _start := Vector2.ZERO
var _start_scroll := Vector2.ZERO
var _dragging := false
var _press_frame := -1
var _last_pos := Vector2.ZERO
var _last_ms := 0
var _vel := Vector2.ZERO
var _glide_sc: ScrollContainer = null
var _glide_pos := Vector2.ZERO

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	for c in get_tree().root.find_children("*", "Control", true, false):
		_hook(c)

func _on_node_added(n: Node) -> void:
	if n is Control:
		_hook(n)

## Children are added before or after their ScrollContainer is in the tree; a control is hooked when it
## (or the list above it) enters, so whole cards rebuilt at runtime are covered too.
func _hook(c: Control) -> void:
	if c is ScrollContainer:
		for d in c.find_children("*", "Control", true, false):
			_connect(d)
		return
	if _scroll_of(c) != null:
		_connect(c)

func _connect(c: Control) -> void:
	if c is ScrollBar or c.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return
	if not c.gui_input.is_connected(_on_child_input):
		c.gui_input.connect(_on_child_input.bind(c))

func _scroll_of(c: Node) -> ScrollContainer:
	var p := c.get_parent()
	while p != null:
		if p is ScrollContainer:
			return p
		if p is ScrollBar:
			return null
		p = p.get_parent()
	return null

## Axes the list really scrolls along: switched on AND its content is longer than the box (a vertical
## build menu has horizontal scrolling on "auto", but nothing to scroll there, so a sideways slip of the
## finger must stay a tap).
func _axes(sc: ScrollContainer) -> Vector2:
	var h := sc.get_h_scroll_bar()
	var v := sc.get_v_scroll_bar()
	var ax := 1.0 if sc.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED and h.max_value - h.page > 0.5 else 0.0
	var ay := 1.0 if sc.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED and v.max_value - v.page > 0.5 else 0.0
	return Vector2(ax, ay)

func _on_child_input(event: InputEvent, c: Control) -> void:
	# touch events reach the GUI too, next to the mouse events emulated from them: only the mouse ones count
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var sc := _scroll_of(c)
		if sc == null:
			return
		var pos := c.get_global_transform() * (event as InputEventMouse).position
		if event.pressed:
			if _press_frame == Engine.get_process_frames() and _sc == sc:
				return                          # the same press passed on to a parent control
			_press_frame = Engine.get_process_frames()
			_sc = sc
			_button = _button_of(c, sc)
			_start = pos
			_start_scroll = Vector2(sc.scroll_horizontal, sc.scroll_vertical)
			_dragging = false
			_glide_sc = null
			_vel = Vector2.ZERO
			_last_pos = _start
			_last_ms = Time.get_ticks_msec()
		elif _sc == sc:
			if _dragging:
				c.accept_event()
				if _vel.length() > GLIDE_MIN * 4.0:
					_glide_sc = sc
					_glide_pos = Vector2(sc.scroll_horizontal, sc.scroll_vertical)
			_sc = null
			_button = null
			_dragging = false
	elif event is InputEventMouseMotion and _sc != null and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		if _scroll_of(c) != _sc:
			return
		# the event's own position, local to the control, taken to the canvas (its global_position is
		# not always in the same space for emulated mouse events)
		var pos := c.get_global_transform() * (event as InputEventMouse).position
		var axes := _axes(_sc)
		var d: Vector2 = (pos - _start) * axes
		if not _dragging and d.length() >= DEADZONE:
			_dragging = true
			_cancel_press()
		if _dragging:
			_sc.scroll_horizontal = int(round(_start_scroll.x - d.x))
			_sc.scroll_vertical = int(round(_start_scroll.y - d.y))
			var now := Time.get_ticks_msec()
			var dt := maxf(0.001, (now - _last_ms) / 1000.0)
			var v: Vector2 = -(pos - _last_pos) * axes / dt
			_vel = _vel.lerp(v, 0.5) if dt < 0.1 else Vector2.ZERO
			_last_pos = pos
			_last_ms = now
			c.accept_event()

func _button_of(c: Node, sc: ScrollContainer) -> BaseButton:
	var n: Node = c
	while n != null and n != sc:
		if n is BaseButton:
			return n
		n = n.get_parent()
	return null

## The press becomes a scroll: the button forgets it (no "pressed" on release). Disabling a button
## clears its press attempt; it is enabled again at once, so it never shows greyed out.
func _cancel_press() -> void:
	if _button != null and is_instance_valid(_button) and not _button.disabled:
		_button.disabled = true
		_button.disabled = false

func _process(delta: float) -> void:
	if _glide_sc == null:
		return
	if not is_instance_valid(_glide_sc) or not _glide_sc.is_visible_in_tree() or _vel.length() < GLIDE_MIN:
		_glide_sc = null
		return
	_glide_pos += _vel * delta
	var before := Vector2(_glide_sc.scroll_horizontal, _glide_sc.scroll_vertical)
	_glide_sc.scroll_horizontal = int(round(_glide_pos.x))
	_glide_sc.scroll_vertical = int(round(_glide_pos.y))
	var after := Vector2(_glide_sc.scroll_horizontal, _glide_sc.scroll_vertical)
	if after == before and _vel.length() > 0.0 and (after - _glide_pos).length() > 1.0:
		_glide_sc = null                        # hit the end of the list
		return
	_vel *= exp(-GLIDE_DECAY * delta)
