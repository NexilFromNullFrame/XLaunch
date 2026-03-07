# res://account_system/SaveSystem.gd
extends Node

const SAVE_PATH = "user://profiles.save"

func save_profiles(profiles: Array) -> void:
	var serializable = []
	for p in profiles:
		serializable.append({
			"gamertag": p.gamertag,
			"display_name": p.display_name,
			"gamerscore": p.gamerscore,
			"is_custom": p.is_custom,
			"installed_games": p.installed_games
		})
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(serializable)
		file.close()

func load_profiles() -> Array:
	if not FileAccess.file_exists(SAVE_PATH):
		return []
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = file.get_var()
	file.close()
	return data if typeof(data) == TYPE_ARRAY else []
