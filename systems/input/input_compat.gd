extends RefCounted

static func key_matches(event: InputEventKey, expected_key: int) -> bool:
	if event.keycode == expected_key or event.physical_keycode == expected_key:
		return true

	if expected_key >= KEY_A and expected_key <= KEY_Z:
		var uppercase_code: int = expected_key
		var lowercase_code: int = expected_key + 32
		return event.unicode == uppercase_code or event.unicode == lowercase_code

	return false
