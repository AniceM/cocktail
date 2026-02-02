extends Node2D
## Handles the jigger pour animation - entering, pouring stream, following surface, and exiting.
## All animations are added to a parent tween passed from GlassScene for unified control.

# Node references
@onready var jigger: Sprite2D = %Jigger
@onready var stream: ColorRect = %ColorRect

# Cached shader material
var _stream_material: ShaderMaterial

# Original transform (saved from editor position/rotation)
var _home_position: Vector2
var _pour_rotation: float

# Target pour_progress for start_pour() - stored separately because enter() resets the shader value to 0
var _target_pour_progress: float = 1.0

# Animation timing (seconds) - exposed so parent can query if needed
const ENTER_DURATION := 0.3
const POUR_EXTEND_DURATION := 0.2
const POUR_RETRACT_DURATION := 0.12
const EXIT_DURATION := 0.25

# Enter/exit animation offset
const ENTER_X_OFFSET := 300.0


func _ready() -> void:
	_stream_material = stream.material as ShaderMaterial

	# Save the editor-defined position and rotation as our "home" state
	_home_position = position
	_pour_rotation = rotation

	# Start hidden
	reset_to_hidden()


func configure_for_glass(jigger_y: float, stream_length: float) -> void:
	"""Configure jigger position and stream length for a specific glass.

	Called once per glass type in set_glass(), not per pour.

	Args:
		jigger_y: Local Y position for the jigger (relative to parent)
		stream_length: Length the stream needs to cover (in local units)
	"""
	_home_position.y = jigger_y
	stream.offset_bottom = stream_length
	reset_target()


func reset_to_hidden() -> void:
	"""Instantly reset to hidden state (for interruption cleanup)."""
	visible = false
	_set_pour_progress(0.0)


func reset_target() -> void:
	"""Reset target pour_progress to 1.0 (full stream) for an empty glass."""
	_target_pour_progress = 1.0


# ============================================================================
# Tween Building API - Each method adds tweeners to the parent tween
# ============================================================================

func add_enter(tween: Tween, color: Color) -> void:
	"""Add jigger enter animation to tween.

	Args:
		tween: Parent tween to add animations to
		color: Color of the liquid being poured
	"""
	# Set stream color
	_stream_material.set_shader_parameter("liquid_color", color)
	_stream_material.set_shader_parameter("highlight_color", color.lightened(0.3))

	# Start off-screen to the right, horizontal, transparent
	position = _home_position + Vector2(ENTER_X_OFFSET, 0)
	rotation = 0.0
	modulate.a = 0.0
	visible = true
	_set_pour_progress(0.0)

	# Add parallel enter animations
	tween.set_parallel(true)
	tween.tween_property(self , "position", _home_position, ENTER_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self , "rotation", _pour_rotation, ENTER_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self , "modulate:a", 1.0, ENTER_DURATION * 0.5)
	tween.set_parallel(false)


func add_start_pour(tween: Tween) -> void:
	"""Add pour stream extend animation to tween.

	Uses _target_pour_progress which is either 1.0 for an empty glass
	or the value set by a previous follow_surface.
	"""
	tween.tween_method(_set_pour_progress, 0.0, _target_pour_progress, POUR_EXTEND_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


func add_follow_surface(tween: Tween, target_surface_global_y: float, duration: float) -> void:
	"""Add pour_progress animation to follow the rising liquid surface.

	Args:
		tween: Parent tween to add animation to
		target_surface_global_y: Global Y position where the liquid surface will be
		duration: How long the animation should take (match fill animation)
	"""
	# Start from where add_start_pour left off
	var from_progress = _target_pour_progress

	# Calculate new target pour_progress from target surface position
	var stream_top_y = global_position.y
	var full_stream_length = stream.offset_bottom * global_scale.y
	var distance_to_surface = target_surface_global_y - stream_top_y
	if full_stream_length > 0.0:
		_target_pour_progress = clampf(distance_to_surface / full_stream_length, 0.0, 1.0)
	else:
		_target_pour_progress = 0.0

	tween.tween_method(_set_pour_progress, from_progress, _target_pour_progress, duration) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)


func add_stop_pour(tween: Tween) -> void:
	"""Add pour stream retract animation to tween."""
	tween.tween_method(_set_pour_progress, _target_pour_progress, 0.0, POUR_RETRACT_DURATION) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)


func add_exit(tween: Tween) -> void:
	"""Add jigger exit animation to tween."""
	var exit_position := _home_position + Vector2(ENTER_X_OFFSET, 0)

	tween.set_parallel(true)
	tween.tween_property(self , "position", exit_position, EXIT_DURATION) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self , "rotation", 0.0, EXIT_DURATION) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self , "modulate:a", 0.0, EXIT_DURATION)
	tween.set_parallel(false)

	# Hide when exit completes
	tween.tween_callback(func(): visible = false)


# ============================================================================
# Private Helpers
# ============================================================================

func _set_pour_progress(value: float) -> void:
	_stream_material.set_shader_parameter("pour_progress", value)
