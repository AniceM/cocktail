@tool
extends Node2D

@export var bounds_size: Vector2 = Vector2(800, 600)

func _process(_delta: float) -> void:
    queue_redraw()

func _draw():
    # draw the container bounds centered at origin (sides and bottom only)
    var half_size = bounds_size / 2
    # Left wall
    draw_line(Vector2(-half_size.x, -half_size.y), Vector2(-half_size.x, half_size.y), Color.DARK_GRAY, 2.0)
    # Right wall
    draw_line(Vector2(half_size.x, -half_size.y), Vector2(half_size.x, half_size.y), Color.DARK_GRAY, 2.0)
    # Bottom
    draw_line(Vector2(-half_size.x, half_size.y), Vector2(half_size.x, half_size.y), Color.DARK_GRAY, 2.0)