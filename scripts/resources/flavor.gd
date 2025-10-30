class_name Flavor
extends Resource

@export var name: String = ""
@export var icon: Texture2D
@export var color: Color = Color.WHITE
@export_multiline var description: String = ""
@export var symbolic_meaning: String = ""

# Which secret types does this flavor boost?
@export var boosted_secret_types: Array[SecretType] = []