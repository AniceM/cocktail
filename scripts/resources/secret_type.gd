class_name SecretType
extends Resource

enum Category {
	SEMANTIC,
	NARRATIVE,
	EMOTIONAL,
	LOGICAL,
	TEMPORAL,
	META
}

@export var name: String = ""
@export var category: Category = Category.SEMANTIC
@export var icon: Texture2D
@export var color: Color = Color.WHITE
@export_multiline var intuitive_cue: String = ""
@export_multiline var gameplay_function: String = ""
@export var suspicion_cost: int = 1 # How much suspicion clicking this type costs