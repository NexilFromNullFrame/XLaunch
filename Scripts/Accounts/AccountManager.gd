## Manages user profiles for XLauncher.
## Handles profile creation, selection, removal, saving/loading, and texture management.
## Emits signals when the profile list or current profile changes.
class_name Account_Manager extends Node

signal profile_list_changed() ## Emits After A New Account Gets Added
signal current_profile_changed(profile: Dictionary) ## Emits Once User Logs-Out By Pressing their Face_Texture (User's Icon) on The Home Screen

## Array of all loaded profiles (each is a Dictionary)
var profiles: Array[Dictionary] = []

## The currently selected profile (Dictionary or empty {})
var current_profile: Dictionary = {}

func _ready() -> void:
	load_profiles()

## Adds or updates a profile.
## If the gamertag already exists, it updates the existing entry.
## Automatically selects the new/updated profile.
func add_profile(gamertag: String, display_name: String, gamerscore: int = 0, is_custom: bool = false, installed_games: Array[Dictionary] = [], face_texture: Texture2D = null, body_texture: Texture2D = null) -> void:
	var clean_gt = gamertag.to_lower()
	var existing_index = -1
	
	# Check if profile already exists
	for i in profiles.size():
		if profiles[i].gamertag == clean_gt:
			existing_index = i
			break
	
	var profile_data = {
		"gamertag": clean_gt,
		"display_name": display_name,
		"gamerscore": gamerscore,
		"is_custom": is_custom,
		"installed_games": installed_games,
		"face_texture": face_texture,
		"body_texture": body_texture,
	}
	
	if existing_index != -1:
		# Update existing profile
		profiles[existing_index] = profile_data
		print("Updated existing profile: ", clean_gt, " with GS: ", gamerscore)
	else:
		# Add new profile
		profiles.append(profile_data)
		existing_index = profiles.size() - 1
		print("Added new profile: ", clean_gt)
	
	# Save textures
	_save_texture(face_texture, clean_gt + "_face.png")
	_save_texture(body_texture, clean_gt + "_body.png")
	
	SaveSystem.save_profiles(profiles)
	profile_list_changed.emit()
	
	# Auto-select the updated/new profile
	select_profile(existing_index)

## Selects a profile by index and emits current_profile_changed.
func select_profile(index: int) -> void:
	if index < 0 or index >= profiles.size():
		return
	current_profile = profiles[index]
	current_profile_changed.emit(current_profile)

## Removes a profile by gamertag (case-insensitive).
## Deletes the profile from the list, removes saved texture files,
## saves changes, and updates the current profile if needed.
## Emits profile_list_changed() signal on success.


func remove_profile(gamertag: String) -> void: ## Takes in [b] GAMERTAG [/b] and Tries finding the Profile for Deletion
	var clean_gt = gamertag.to_lower()
	var found_index = -1
	
	# Find the profile index by gamertag
	for i in profiles.size():
		if profiles[i].gamertag == clean_gt:
			found_index = i
			break
	
	if found_index == -1:
		print("No profile found with gamertag: ", gamertag)
		return
	
	# Delete saved texture files
	var _profile = profiles[found_index]
	var face_path = "user://".path_join(clean_gt + "_face.png")
	var body_path = "user://".path_join(clean_gt + "_body.png")
	DirAccess.remove_absolute(face_path)
	DirAccess.remove_absolute(body_path)
	
	# Remove from list
	profiles.remove_at(found_index)
	
	# If this was the current profile, clear or fallback
	if current_profile.gamertag == clean_gt:
		if profiles.is_empty():
			current_profile = {}
		else:
			# Select the first remaining profile (or any logic you prefer)
			select_profile(0)
	
	# Save and notify
	SaveSystem.save_profiles(profiles)
	profile_list_changed.emit()
	
	print("Removed profile: ", clean_gt)

## Checks if a gamertag already exists (case-insensitive).
func has_profile(gamertag: String) -> bool:
	var clean_gt = gamertag.to_lower()
	for p in profiles:
		if p.gamertag == clean_gt:
			return true
	return false

## Loads all profiles from save file.
func load_profiles() -> void:
	var data = SaveSystem.load_profiles()
	profiles.clear()
	for d in data:
		var p = {
			"gamertag": d.gamertag,
			"display_name": d.display_name,
			"gamerscore": d.gamerscore,
			"is_custom": d.get("is_custom", false),
			"installed_games": d.get("installed_games", []),
			"face_texture": _load_texture(d.gamertag + "_face.png"),
			"body_texture": _load_texture(d.gamertag + "_body.png")
		}
		profiles.append(p)
	profile_list_changed.emit()

## Saves the current profile list (called when needed).
func save_current_profile() -> void:
	SaveSystem.save_profiles(profiles)
	print("Current profile saved with ", current_profile.installed_games.size(), " games")

## Saves a texture to user:// as PNG.
func _save_texture(tex: Texture2D, filename: String) -> void:
	if not tex:
		return
	var img = tex.get_image()
	img.save_png("user://".path_join(filename))

## Loads a texture from user:// PNG file.
func _load_texture(filename: String) -> Texture2D:
	var path = "user://".path_join(filename)
	if FileAccess.file_exists(path):
		var img = Image.load_from_file(path)
		if img:
			return ImageTexture.create_from_image(img)
	return null
