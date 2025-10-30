@tool
extends Node3D

@export_tool_button("Reset", "Callable") var reset_action = reset
@export var gravity: float = 10.0
@export var velocity: Vector3
@export var collision_damping: float = 0.5
var bounds_size: Vector3

@export var radius: float = 0.5:
	set(value):
		radius = value
		update_mesh()

@export var color: Color = Color.WHITE:
	set(value):
		color = value
		update_material()

var mesh_instance: MeshInstance3D

func _ready() -> void:
	if get_parent() and get_parent().has_method("get"):
		bounds_size = get_parent().bounds_size
	else:
		bounds_size = Vector3(8, 6, 8)

	position = Vector3.ZERO
	create_sphere_mesh()

func reset():
	velocity = Vector3.ZERO
	position = Vector3.ZERO

func _process(delta: float) -> void:
	velocity += Vector3.DOWN * gravity * delta
	position += velocity * delta
	resolve_collisions()

func create_sphere_mesh():
	if mesh_instance:
		mesh_instance.queue_free()

	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)

	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2
	mesh_instance.mesh = sphere_mesh

	update_material()

func update_mesh():
	if mesh_instance and mesh_instance.mesh is SphereMesh:
		mesh_instance.mesh.radius = radius
		mesh_instance.mesh.height = radius * 2

func update_material():
	if mesh_instance:
		var material = StandardMaterial3D.new()
		material.albedo_color = color
		mesh_instance.material_override = material

func resolve_collisions():
	var half_bounds_size = bounds_size / 2 - Vector3.ONE * radius

	# X axis collision
	if abs(position.x) > half_bounds_size.x:
		position.x = half_bounds_size.x * sign(position.x)
		velocity.x *= -1 * collision_damping

	# Y axis collision
	if abs(position.y) > half_bounds_size.y:
		position.y = half_bounds_size.y * sign(position.y)
		velocity.y *= -1 * collision_damping

	# Z axis collision
	if abs(position.z) > half_bounds_size.z:
		position.z = half_bounds_size.z * sign(position.z)
		velocity.z *= -1 * collision_damping
