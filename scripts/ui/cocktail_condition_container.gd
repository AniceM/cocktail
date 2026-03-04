extends MarginContainer

@export var cocktail_condition: CocktailCondition:
	set(value):
		cocktail_condition = value
		if is_node_ready():
			_update_display()

@onready var _check_mark: ColorRect = %CheckMark
@onready var _description: Label = %Description
@onready var _flavor_badge: TextureRect = %FlavorBadge

var _color_tween: Tween


func _ready() -> void:
	_update_display()

	GameSession.current_cocktail_changed.connect(_on_cocktail_changed)
	GameSession.current_cocktail_updated.connect(_on_cocktail_updated)


func _get_single_flavor() -> Flavor:
	if cocktail_condition is FlavorCondition:
		var fc := cocktail_condition as FlavorCondition
		if fc.min_flavors.size() == 1 and fc.max_flavors.is_empty():
			return fc.min_flavors.keys()[0]
		if fc.max_flavors.size() == 1 and fc.min_flavors.is_empty():
			return fc.max_flavors.keys()[0]
	return null


func _on_cocktail_changed(_cocktail: Cocktail) -> void:
	_update_display()


func _on_cocktail_updated(_cocktail: Cocktail) -> void:
	_update_display()


func _update_display() -> void:
	# Setup icon based on condition type
	var flavor := _get_single_flavor()
	if flavor:
		_flavor_badge.texture = flavor.icon
		_flavor_badge.visible = true
		_check_mark.visible = false
	else:
		_flavor_badge.visible = false
		_check_mark.visible = true

	# Determine target color
	var target_color: Color = Color.GRAY
	if cocktail_condition:
		_description.text = cocktail_condition.description

		if GameSession.current_cocktail and cocktail_condition.is_met(GameSession.current_cocktail):
			target_color = Color.GREEN
	else:
		_description.text = ""

	# Animate the active icon (flavor badge or check mark)
	if _flavor_badge.visible:
		_animate_icon_color(_flavor_badge, target_color)
	else:
		_animate_icon_color(_check_mark, target_color)


func _animate_icon_color(icon_node: Control, target_color: Color) -> void:
	var current_color: Color = icon_node.modulate

	if current_color != target_color:
		if _color_tween:
			_color_tween.kill()
		_color_tween = create_tween()
		_color_tween.tween_property(icon_node, "modulate", target_color, 0.25)
