extends Node

# Preload all secret type resources
var LIE: SecretType = preload("uid://c1l7qrmfd3fph")
var DEFLECTION: SecretType = preload("uid://dvxri18pfnhjn")
var OMISSION: SecretType = preload("uid://krf3glt47uou")
var ECHO: SecretType = preload("uid://bfnthbt57g12i")
var TRIGGER: SecretType = preload("uid://bj350oxh1wbxo")
var EMOTION: SecretType = preload("uid://cwa0mwjnm0nxd")
var ANOMALY: SecretType = preload("uid://crkjsyw58hdb5")
var CONTRADICTION: SecretType = preload("uid://drkqd7ykkmffy")
var FORESHADOW: SecretType = preload("uid://dm1h2eg2mgpkl")
var FRAGMENT: SecretType = preload("uid://8joi8sgrm6qd")

func get_all_secret_types() -> Array[SecretType]:
	return [LIE, DEFLECTION, OMISSION, ECHO, TRIGGER, EMOTION, ANOMALY, CONTRADICTION, FORESHADOW, FRAGMENT]

func get_secret_type_by_name(type_name: String) -> SecretType:
	for secret_type in get_all_secret_types():
		if secret_type.name == type_name:
			return secret_type
	return null
