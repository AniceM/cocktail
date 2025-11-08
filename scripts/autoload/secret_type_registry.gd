extends Node

# Preload all secret type resources
var LIE: SecretType = preload("res://data/secret_types/lie.tres")
var DEFLECTION: SecretType = preload("res://data/secret_types/deflection.tres")
var OMISSION: SecretType = preload("res://data/secret_types/omission.tres")
var ECHO: SecretType = preload("res://data/secret_types/echo.tres")
var TRIGGER: SecretType = preload("res://data/secret_types/trigger.tres")
var EMOTION: SecretType = preload("res://data/secret_types/emotion.tres")
var ANOMALY: SecretType = preload("res://data/secret_types/anomaly.tres")
var CONTRADICTION: SecretType = preload("res://data/secret_types/contradiction.tres")
var FORESHADOW: SecretType = preload("res://data/secret_types/foreshadow.tres")
var FRAGMENT: SecretType = preload("res://data/secret_types/fragment.tres")

func get_all_secret_types() -> Array[SecretType]:
	return [LIE, DEFLECTION, OMISSION, ECHO, TRIGGER, EMOTION, ANOMALY, CONTRADICTION, FORESHADOW, FRAGMENT]

func get_secret_type_by_name(type_name: String) -> SecretType:
	for secret_type in get_all_secret_types():
		if secret_type.name == type_name:
			return secret_type
	return null
