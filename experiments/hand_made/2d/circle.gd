@tool
extends Node2D

@export_tool_button("Reset", "Callable") var reset_action = reset
@export var gravity: float = 10.0
@export var velocity: Vector2
@export var collision_damping: float = 0.5
var bounds_size: Vector2

@export var radius: float = 20.0:
    set(value):
        radius = value
        queue_redraw()

@export var color: Color = Color.WHITE:
    set(value):
        color = value
        queue_redraw()

func reset():
    velocity = Vector2.ZERO
    position = Vector2.ZERO  # Start at center top

func _ready() -> void:
    bounds_size = get_parent().bounds_size
    position = Vector2.ZERO  # Start at center top

func _process(delta: float) -> void:
    velocity += Vector2.DOWN * gravity * delta
    position += velocity * delta
    resolve_collisions()
    queue_redraw()

func _draw():
    # draw the circle
    draw_circle(Vector2.ZERO, radius, color)

func resolve_collisions():
    var half_bounds_size = bounds_size / 2 - Vector2.ONE * radius
    if abs(position.x) > half_bounds_size.x:
        print(position.x)
        position.x = half_bounds_size.x * sign(position.x)
        velocity.x *= -1 * collision_damping
        print(position.x)
    elif abs(position.y) > half_bounds_size.y:
        position.y = half_bounds_size.y * sign(position.y)
        velocity.y *= -1 * collision_damping
