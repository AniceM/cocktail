extends Button

signal glass_selected(glass: GlassType)

@export var glass: GlassType:
	set(value):
		glass = value
		_update_display()

@onready var _glass_icon_front: TextureRect = %GlassIconFront
@onready var _glass_icon_back: TextureRect = %GlassIconBack
@onready var _glass_label: Label = %GlassLabel


func _ready() -> void:
	_update_display()
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	glass_selected.emit(glass)


func _update_display() -> void:
	if not is_node_ready():
		return
	if glass:
		_glass_icon_front.texture = glass.sprite_front
		_glass_icon_back.texture = glass.sprite_back
		_glass_label.text = glass.name
	else:
		_glass_icon_front.texture = null
		_glass_icon_back.texture = null
		_glass_label.text = ""
