class_name Log
extends RefCounted

static var enabled: bool = OS.is_debug_build()

const _SCOPE_COLOR := "#4FC3F7"
const _TIME_COLOR := "#8A8F98"
const _MESSAGE_COLOR := "#E6E6E6"


static func msg(from: Object, message: Variant) -> void:
	if not enabled:
		return

	var scope := _get_scope(from)
	var time_prefix := "[color=%s]%s[/color] " % [_TIME_COLOR, Time.get_time_string_from_system()]

	print_rich("%s[color=%s][%s][/color] [color=%s]%s[/color]" % [
		time_prefix,
		_SCOPE_COLOR,
		scope,
		_MESSAGE_COLOR,
		_escape_bbcode(str(message)),
	])


static func _get_scope(from: Object) -> String:
	if from == null:
		return "unknown"

	var script = from.get_script()
	if script and script.resource_path is String and not script.resource_path.is_empty():
		return script.resource_path.get_file().get_basename()

	return from.get_class()


static func _escape_bbcode(text: String) -> String:
	var placeholder := "\u001ALB\u001A"
	return text.replace("[", placeholder).replace("]", "[rb]").replace(placeholder, "[lb]")
