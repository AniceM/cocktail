@tool
extends Control
class_name CarouselContainer

## Arrange items in a circular arc. If false, items are laid out linearly.
@export var circular: bool = false
## Horizontal radius of the circular layout.
@export var radius: float = 200.0
## Vertical depth of the circular arc (perspective effect).
@export var depth: float = -100.0
## Spacing between items in linear mode.
@export var spacing: float = 20.0

## How much items fade based on distance from selection (0 = no fade, 1 = full fade).
@export_range(0.0, 1.0) var opacity_falloff: float = 0.35
## How much items shrink based on distance from selection.
@export_range(0.0, 1.0) var scale_falloff: float = 0.25
## Minimum scale for the farthest items.
@export_range(0.01, 0.99, 0.01) var scale_min: float = 0.1

## Interpolation speed for smooth transitions.
@export var smoothing_speed: float = 6.5
## Index of the currently selected item.
@export var selected_index: int = 0
## Automatically select whichever child item has focus.
@export var follow_focus: bool = true
## Container node holding the carousel items.
@export var items_container: Control = null


func _process(delta: float) -> void:
	if !items_container or items_container.get_child_count() == 0:
		return

	var child_count := items_container.get_child_count()

	# Auto-select the item that contains the focused Control (not just direct focus).
	if follow_focus:
		var focus_owner := get_viewport().gui_get_focus_owner()
		if focus_owner and items_container.is_ancestor_of(focus_owner):
			var focused_item := focus_owner
			while focused_item and focused_item.get_parent() != items_container:
				focused_item = focused_item.get_parent()
			if focused_item and focused_item is Control:
				selected_index = focused_item.get_index()

	selected_index = clampi(selected_index, 0, child_count - 1)
	var t := clampf(smoothing_speed * delta, 0.0, 1.0)

	for child: Control in items_container.get_children():
		var index := child.get_index()

		# Distance from selected (shared by both modes for falloff effects)
		var dist: float

		# Positioning
		if circular:
			var wrapped_offset := _wrap_offset(index - selected_index, child_count)
			dist = absf(wrapped_offset)

			# Distribute items evenly around a full circle
			var angle := (wrapped_offset / float(child_count)) * TAU
			var x := sin(angle) * radius
			var y := (1.0 - cos(angle)) * depth
			var target_pos := Vector2(x, y) - child.size / 2.0
			child.position = child.position.lerp(target_pos, t)
		else:
			dist = absf(float(index - selected_index))

			# No position lerp: scales lerp smoothly, positions follow each frame.
			# Container scroll lerp handles the overall sliding animation.
			var target_x := 0.0
			if index > 0:
				var prev: Control = items_container.get_child(index - 1)
				# Use current (lerping) scale so positions track actual visual edges
				var prev_visual_right := prev.position.x + prev.size.x * 0.5 * (1.0 + prev.scale.x)
				target_x = prev_visual_right + spacing - child.size.x * 0.5 * (1.0 - child.scale.x)
			child.position = Vector2(target_x, -child.size.y / 2.0)

		# Scaling
		child.pivot_offset = child.size / 2.0
		var target_scale := clampf(1.0 - scale_falloff * dist, scale_min, 1.0)
		child.scale = child.scale.lerp(Vector2.ONE * target_scale, t)

		# Opacity
		var target_opacity := clampf(1.0 - opacity_falloff * dist, 0.0, 1.0)
		child.modulate.a = lerpf(child.modulate.a, target_opacity, t)

		# Z-index
		if index == selected_index:
			child.z_index = 1
		else:
			child.z_index = - roundi(dist)

	# Scroll container to center selection
	if circular:
		items_container.position.x = lerpf(items_container.position.x, 0.0, t)
	else:
		# Simulate equilibrium position of selected child using the same chain formula
		var eq_x := 0.0
		for idx in range(1, selected_index + 1):
			var prev_c: Control = items_container.get_child(idx - 1)
			var prev_s := clampf(1.0 - scale_falloff * absf(float(idx - 1 - selected_index)), scale_min, 1.0)
			var cur_c: Control = items_container.get_child(idx)
			var cur_s := clampf(1.0 - scale_falloff * absf(float(idx - selected_index)), scale_min, 1.0)
			eq_x = eq_x + prev_c.size.x * 0.5 * (1.0 + prev_s) + spacing - cur_c.size.x * 0.5 * (1.0 - cur_s)
		var selected_child: Control = items_container.get_child(selected_index)
		var scroll_target := - (eq_x + selected_child.size.x / 2.0)
		items_container.position.x = lerpf(items_container.position.x, scroll_target, t)


## Wraps an offset to the range (-count/2, count/2] for shortest circular path.
func _wrap_offset(offset: int, count: int) -> float:
	var wrapped := fmod(float(offset) + count / 2.0, float(count))
	if wrapped < 0.0:
		wrapped += count
	return wrapped - count / 2.0


func select_previous() -> void:
	if !items_container:
		return
	var child_count := items_container.get_child_count()
	if child_count == 0:
		return

	if circular:
		selected_index = wrapi(selected_index - 1, 0, child_count)
	elif selected_index > 0:
		selected_index -= 1


func select_next() -> void:
	if !items_container:
		return
	var child_count := items_container.get_child_count()
	if child_count == 0:
		return

	if circular:
		selected_index = wrapi(selected_index + 1, 0, child_count)
	elif selected_index < child_count - 1:
		selected_index += 1


func get_selected_child() -> Control:
	if !items_container:
		return null
	var child_count := items_container.get_child_count()
	if child_count == 0:
		return null
	return items_container.get_child(clampi(selected_index, 0, child_count - 1))
