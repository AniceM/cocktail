extends Control

signal glass_selected(glass: GlassType)

const GlassButtonScene = preload("uid://cxc30n76bxc7g") # glass_button.tscn
const BUTTON_ANIM_DURATION := 0.2

@onready var _grid_container: GridContainer = %GridContainer
@onready var _scroll_container: ScrollContainer = %ScrollContainer

var _stagger_tween: Tween


func _ready() -> void:
	_populate_glasses()


func _populate_glasses() -> void:
	# Clear existing buttons
	for child in _grid_container.get_children():
		child.queue_free()

	# Add a button for each unlocked glass, except "The Relay"
	for glass in PlayerProgression.get_glasses():
		# TODO: Have a special spot for "The Relay"?
		if glass.name == "The Relay":
			continue
		var button = GlassButtonScene.instantiate()
		button.glass = glass
		button.glass_selected.connect(_on_glass_button_selected)
		_grid_container.add_child(button)


func _on_glass_button_selected(glass: GlassType) -> void:
	glass_selected.emit(glass)


func set_disabled(disabled: bool = true) -> void:
	for child in _grid_container.get_children():
		if child is Button:
			child.disabled = disabled


func animate_buttons_in() -> void:
	if _stagger_tween:
		_stagger_tween.kill()
	_stagger_tween = create_tween()
	_stagger_tween.set_parallel(true)

	var buttons := _grid_container.get_children()
	for i in buttons.size():
		var button: Control = buttons[i]
		button.scale = Vector2.ZERO
		button.modulate.a = 0.0
		var delay := i * (BUTTON_ANIM_DURATION * 0.5)
		_stagger_tween.tween_property(button, "scale", Vector2.ONE, BUTTON_ANIM_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_delay(delay)
		_stagger_tween.tween_property(button, "modulate:a", 1.0, BUTTON_ANIM_DURATION).set_ease(Tween.EASE_OUT).set_delay(delay)


func reset_scroll() -> void:
	_scroll_container.scroll_vertical = 0
	_scroll_container.scroll_horizontal = 0
