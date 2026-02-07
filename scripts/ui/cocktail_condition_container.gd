extends MarginContainer

@export var cocktail_condition: CocktailCondition:
	set(value):
		cocktail_condition = value
		_update_display()

@onready var _check_mark: ColorRect = %CheckMark
@onready var _description: Label = %Description

var _color_tween: Tween


func _ready() -> void:
	# Initial display
	_update_display()

	# Listen to cocktail changes
	GameSession.current_cocktail_changed.connect(_on_cocktail_changed)
	GameSession.current_cocktail_updated.connect(_on_cocktail_updated)


func _on_cocktail_changed(_cocktail: Cocktail) -> void:
	_update_display()


func _on_cocktail_updated(_cocktail: Cocktail) -> void:
	_update_display()


func _update_display() -> void:
	if not is_node_ready():
		return

	# Determine target color
	var target_color: Color = Color.GRAY
	if cocktail_condition:
		_description.text = cocktail_condition.description

		# Check if condition is met
		if GameSession.current_cocktail and cocktail_condition.is_met(GameSession.current_cocktail):
			target_color = Color.GREEN
	else:
		_description.text = ""

	# Animate color if changed
	if _check_mark.color != target_color:
		if _color_tween:        
			_color_tween.kill()
		_color_tween = create_tween()
		_color_tween.tween_property(_check_mark, "color", target_color, 0.25)
