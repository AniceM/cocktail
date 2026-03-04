extends Control

signal glass_selected(glass: GlassType)

const GlassButtonScene = preload("uid://cxc30n76bxc7g") # glass_button.tscn
const BUTTON_ANIM_DURATION := 0.2

# 2 Display options:
# 1. A scrollable grid of buttons
# @onready var _grid_container: GridContainer = %GridContainer
@onready var _scroll_container: ScrollContainer = %ScrollContainer
# 2. A carousel of buttons
@onready var _carousel_control: Control = %CarouselControl

# Current display
var _menu_control: Control
# Animation
var _stagger_tween: Tween


func _ready() -> void:
	_menu_control = _carousel_control
	_populate_glasses()


func _populate_glasses() -> void:
	# Clear existing buttons
	for child in _menu_control.get_children():
		child.queue_free()

	# Add a button for each unlocked glass, except "The Relay"
	for glass in PlayerProgression.get_glasses():
		# TODO: Have a special spot for "The Relay"?
		if glass.name == "The Relay":
			continue
		var button = GlassButtonScene.instantiate()
		button.glass = glass
		button.glass_selected.connect(_on_glass_button_selected)
		_menu_control.add_child(button)


func _on_glass_button_selected(glass: GlassType) -> void:
	glass_selected.emit(glass)


func get_selected_glass() -> GlassType:
	var carousel: CarouselContainer = _carousel_control.get_parent()
	var selected := carousel.get_selected_child()
	if selected and "glass" in selected:
		return selected.glass
	return null


func set_disabled(disabled: bool = true) -> void:
	for child in _menu_control.get_children():
		if child is Button:
			child.disabled = disabled


func animate_buttons_in() -> void:
	if _menu_control != _scroll_container:
		return
	if _stagger_tween:
		_stagger_tween.kill()
	_stagger_tween = create_tween()
	_stagger_tween.set_parallel(true)

	var buttons := _menu_control.get_children()
	for i in buttons.size():
		var button: Control = buttons[i]
		button.scale = Vector2.ZERO
		button.modulate.a = 0.0
		var delay := i * (BUTTON_ANIM_DURATION * 0.5)
		_stagger_tween.tween_property(button, "scale", Vector2.ONE, BUTTON_ANIM_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(delay)
		_stagger_tween.tween_property(button, "modulate:a", 1.0, BUTTON_ANIM_DURATION).set_ease(Tween.EASE_OUT).set_delay(delay)


func reset_scroll() -> void:
	if _menu_control == _scroll_container:
		_scroll_container.scroll_vertical = 0
		_scroll_container.scroll_horizontal = 0
