@tool
extends Node3D

@export var bounds_size: Vector3 = Vector3(8, 6, 8)
@export var wall_thickness: float = 0.1

var mesh_instance: MeshInstance3D
var immediate_mesh: ImmediateMesh

func _ready() -> void:
	create_container_mesh()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		create_container_mesh()

func create_container_mesh():
	# Remove old mesh if it exists
	if mesh_instance:
		mesh_instance.queue_free()

	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)

	immediate_mesh = ImmediateMesh.new()
	mesh_instance.mesh = immediate_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color.DARK_GRAY
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.3
	mesh_instance.material_override = material

	var half_size = bounds_size / 2

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# Left wall (negative X)
	add_wall_quad(
		Vector3(-half_size.x, -half_size.y, -half_size.z),
		Vector3(-half_size.x, half_size.y, -half_size.z),
		Vector3(-half_size.x, half_size.y, half_size.z),
		Vector3(-half_size.x, -half_size.y, half_size.z)
	)

	# Right wall (positive X)
	add_wall_quad(
		Vector3(half_size.x, -half_size.y, half_size.z),
		Vector3(half_size.x, half_size.y, half_size.z),
		Vector3(half_size.x, half_size.y, -half_size.z),
		Vector3(half_size.x, -half_size.y, -half_size.z)
	)

	# Back wall (negative Z)
	add_wall_quad(
		Vector3(-half_size.x, -half_size.y, -half_size.z),
		Vector3(half_size.x, -half_size.y, -half_size.z),
		Vector3(half_size.x, half_size.y, -half_size.z),
		Vector3(-half_size.x, half_size.y, -half_size.z)
	)

	# Front wall (positive Z)
	add_wall_quad(
		Vector3(-half_size.x, -half_size.y, half_size.z),
		Vector3(-half_size.x, half_size.y, half_size.z),
		Vector3(half_size.x, half_size.y, half_size.z),
		Vector3(half_size.x, -half_size.y, half_size.z)
	)

	# Bottom (positive Y in Godot's coordinate system)
	add_wall_quad(
		Vector3(-half_size.x, half_size.y, -half_size.z),
		Vector3(half_size.x, half_size.y, -half_size.z),
		Vector3(half_size.x, half_size.y, half_size.z),
		Vector3(-half_size.x, half_size.y, half_size.z)
	)

	immediate_mesh.surface_end()

func add_wall_quad(p1: Vector3, p2: Vector3, p3: Vector3, p4: Vector3):
	# First triangle
	immediate_mesh.surface_add_vertex(p1)
	immediate_mesh.surface_add_vertex(p2)
	immediate_mesh.surface_add_vertex(p3)

	# Second triangle
	immediate_mesh.surface_add_vertex(p1)
	immediate_mesh.surface_add_vertex(p3)
	immediate_mesh.surface_add_vertex(p4)
