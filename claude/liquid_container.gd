class_name LiquidContainer
extends Node2D

## A container (glass or bottle) that holds liquid layers and can pour/receive liquid

signal clicked(container: LiquidContainer)
signal pour_started(from: LiquidContainer, to: LiquidContainer)
signal pour_finished(from: LiquidContainer, to: LiquidContainer)

@export var container_width: float = 60.0
@export var container_height: float = 150.0
@export var max_capacity: float = 150.0 # Total height of liquid it can hold
@export var pour_amount: float = 30.0 # Fixed amount to pour
@export var is_bottle: bool = true # If false, it's a glass (receives liquid)

var liquid_layers: Array[LiquidLayer] = []
var current_fill_height: float = 0.0
var area: Area2D

func add_liquid_layer(color: Color, amount: float) -> void:
	if current_fill_height + amount > max_capacity:
		amount = max_capacity - current_fill_height

	if amount <= 0:
		return

	# Check if we can merge with the top layer
	if liquid_layers.size() > 0 and liquid_layers[-1].color == color:
		liquid_layers[-1].amount += amount
	else:
		liquid_layers.append(LiquidLayer.new(color, amount))

	current_fill_height += amount
	queue_redraw()

func remove_liquid_from_top(amount: float) -> Array[LiquidLayer]:
	var removed_layers: Array[LiquidLayer] = []
	var remaining_amount = amount

	while remaining_amount > 0 and liquid_layers.size() > 0:
		var top_layer = liquid_layers[-1]

		if top_layer.amount <= remaining_amount:
			# Remove entire layer
			removed_layers.push_front(top_layer)
			liquid_layers.pop_back()
			remaining_amount -= top_layer.amount
			current_fill_height -= top_layer.amount
		else:
			# Partially remove from layer
			var removed_layer = LiquidLayer.new(top_layer.color, remaining_amount)
			removed_layers.push_front(removed_layer)
			top_layer.amount -= remaining_amount
			current_fill_height -= remaining_amount
			remaining_amount = 0

	queue_redraw()
	return removed_layers

func can_receive_liquid(amount: float) -> bool:
	return current_fill_height + amount <= max_capacity

func _draw() -> void:
	# Draw container outline
	var rect = Rect2(-container_width / 2, -container_height / 2, container_width, container_height)

	if is_bottle:
		# Draw bottle shape (rectangle with neck)
		draw_rect(rect, Color.WHITE, false, 2.0)
		# Bottle neck
		var neck_width = container_width * 0.4
		var neck_height = 20.0
		draw_rect(Rect2(-neck_width / 2, -container_height / 2 - neck_height, neck_width, neck_height), Color.WHITE, false, 2.0)
	else:
		# Draw glass shape (tapered)
		var top_width = container_width
		var bottom_width = container_width * 0.7
		var points = PackedVector2Array([
			Vector2(-bottom_width / 2, container_height / 2),
			Vector2(bottom_width / 2, container_height / 2),
			Vector2(top_width / 2, -container_height / 2),
			Vector2(-top_width / 2, -container_height / 2)
		])
		draw_polyline(points + PackedVector2Array([points[0]]), Color.WHITE, 2.0)

	# Draw liquid layers from bottom to top
	var y_offset = container_height / 2 # Start from bottom

	for layer in liquid_layers:
		var layer_rect = Rect2(
			- container_width / 2 + 2,
			y_offset - layer.amount,
			container_width - 4,
			layer.amount
		)
		draw_rect(layer_rect, layer.color, true)
		y_offset -= layer.amount

func _ready() -> void:
	# Setup Area2D for click detection (Godot 4.5)
	area = Area2D.new()
	area.input_pickable = true # Enable input on Area2D
	add_child(area)

	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(container_width, container_height)
	collision_shape.shape = shape
	area.add_child(collision_shape)

	# Connect the input_event signal from Area2D
	area.input_event.connect(_on_area_input_event)
	queue_redraw()

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)
