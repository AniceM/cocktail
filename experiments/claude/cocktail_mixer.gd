extends Node2D

## Main controller for the cocktail mixing system

@export var glass_path: NodePath
@export var bottle_paths: Array[NodePath] = []

var glass: LiquidContainer
var bottles: Array[LiquidContainer] = []

var is_pouring: bool = false
var pour_stream: PourStream

func _ready() -> void:
	# Resolve glass NodePath to actual LiquidContainer
	if glass_path:
		glass = get_node(glass_path) as LiquidContainer
		if glass:
			glass.is_bottle = false

	# Resolve NodePaths to actual LiquidContainer objects
	for path in bottle_paths:
		var bottle = get_node(path) as LiquidContainer
		if bottle:
			bottles.append(bottle)

	# Connect bottle click signals
	for bottle in bottles:
		if bottle:
			bottle.clicked.connect(_on_bottle_clicked)

	# Add demo liquids for testing
	_setup_demo_liquids()
	print("Cocktail Mixer ready! Click on bottles to pour into glass.")

func _setup_demo_liquids() -> void:
	# Add colored liquids to each bottle
	if bottles.size() > 0:
		bottles[0].add_liquid_layer(Color(0.8, 0.1, 0.1), 120.0)  # Red
	if bottles.size() > 1:
		bottles[1].add_liquid_layer(Color(1.0, 0.6, 0.1), 100.0)  # Orange
	if bottles.size() > 2:
		bottles[2].add_liquid_layer(Color(0.1, 0.4, 0.9), 90.0)   # Blue
	if bottles.size() > 3:
		bottles[3].add_liquid_layer(Color(0.95, 0.85, 0.2), 110.0) # Yellow

func _on_bottle_clicked(bottle: LiquidContainer) -> void:
	print("Bottle clicked!")

	if is_pouring:
		print("Already pouring, please wait...")
		return

	if bottle.liquid_layers.is_empty():
		print("Bottle is empty!")
		return

	if not glass.can_receive_liquid(bottle.pour_amount):
		print("Glass is full!")
		return

	print("Starting pour...")
	start_pour(bottle, glass)

func start_pour(from_container: LiquidContainer, to_container: LiquidContainer) -> void:
	is_pouring = true
	from_container.pour_started.emit(from_container, to_container)

	# Get the liquid to pour
	var layers_to_pour = from_container.remove_liquid_from_top(from_container.pour_amount)

	if layers_to_pour.is_empty():
		is_pouring = false
		return

	# Create visual pour stream
	if not pour_stream:
		pour_stream = PourStream.new()
		add_child(pour_stream)

	pour_stream.start_pour(from_container, to_container, layers_to_pour)
	await pour_stream.pour_complete

	# Add liquid to target container
	for layer in layers_to_pour:
		to_container.add_liquid_layer(layer.color, layer.amount)

	from_container.pour_finished.emit(from_container, to_container)
	is_pouring = false

# Visual representation of liquid pouring through the air
class PourStream extends Node2D:
	signal pour_complete

	var from_pos: Vector2
	var to_pos: Vector2
	var layers: Array[LiquidLayer]
	var pour_progress: float = 0.0
	var stream_width: float = 8.0
	var pour_duration: float = 1.0

	func start_pour(from: LiquidContainer, to: LiquidContainer, p_layers: Array[LiquidLayer]) -> void:
		from_pos = from.global_position + Vector2(0, -from.container_height / 2)
		to_pos = to.global_position + Vector2(0, -to.container_height / 2 + to.current_fill_height)
		layers = p_layers
		pour_progress = 0.0

		# Animate the pour
		var tween = create_tween()
		tween.tween_property(self, "pour_progress", 1.0, pour_duration)
		tween.finished.connect(_on_pour_finished)

		queue_redraw()

	func _process(_delta: float) -> void:
		if pour_progress > 0 and pour_progress < 1.0:
			queue_redraw()

	func _draw() -> void:
		if pour_progress <= 0 or pour_progress >= 1.0:
			return

		# Draw the liquid stream as a bezier curve
		var start = to_local(from_pos)
		var end = to_local(to_pos)

		# Control point for the curve (slight arc)
		var mid = (start + end) / 2
		mid.x += 20.0 # Slight arc to the right

		# Calculate color (blend of all layers)
		var blend_color = Color.BLACK
		var total_amount = 0.0
		for layer in layers:
			total_amount += layer.amount

		for layer in layers:
			var weight = layer.amount / total_amount
			blend_color += layer.color * weight

		# Draw the stream
		var points = 20
		var prev_point = start
		for i in range(1, points + 1):
			var t = float(i) / points * pour_progress
			var point = start.bezier_interpolate(mid, mid, end, t)

			draw_line(prev_point, point, blend_color, stream_width)
			prev_point = point

	func _on_pour_finished() -> void:
		pour_progress = 0.0
		queue_redraw()
		pour_complete.emit()
