extends PanelContainer

const COLOR_TWEEN_DURATION := 0.25
const DEFAULT_COLOR := Color(1.0, 1.0, 1.0, 0.7)

var current_color: Color = DEFAULT_COLOR
var _style: StyleBoxFlat
var _color_tween: Tween


func _ready() -> void:
	_style = get_theme_stylebox("panel").duplicate()
	add_theme_stylebox_override("panel", _style)


func set_slot_color(color: Color, animate: bool = true) -> void:
	current_color = color
	if not animate:
		_style.bg_color = color
		return
	if _color_tween:
		_color_tween.kill()
	_color_tween = create_tween()
	_color_tween.tween_property(_style, "bg_color", color, COLOR_TWEEN_DURATION)


func reset_slot(animate: bool = true) -> void:
	set_slot_color(DEFAULT_COLOR, animate)
