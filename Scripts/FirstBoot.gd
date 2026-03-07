# Autoload singleton: FirstBoot.gd
extends Node

const CURRENT_VERSION = "0.0.8" 

var config = ConfigFile.new()
var config_path = "user://first_boot.cfg"

func _ready() -> void:
	var err = config.load(config_path)
	if err != OK:
		# File doesn't exist -> first ever run
		run_first_boot_setup()
		return
	
	var last_version = config.get_value("version", "last_run", "0.0.0")
	if last_version != CURRENT_VERSION:
		# New version detected
		run_first_boot_setup(last_version)
	else:
		print("Already ran setup for v", CURRENT_VERSION)

func run_first_boot_setup(previous_version: String = "0.0.0") -> void:
	print("First boot / version upgrade detected (from ", previous_version, " → ", CURRENT_VERSION, ")")
	
	# Optional: migrate data from previous_version if needed
	if previous_version.begins_with("1.0"):
		migrate_from_v1_0()
	
	# Show setup screen
	get_tree().change_scene_to_file("res://scenes/Set_Up.tscn")
	
	# Save that we ran this version
	config.set_value("version", "last_run", CURRENT_VERSION)
	config.save(config_path)

func migrate_from_v1_0() -> void:
	# Example: clear old incompatible data
	print("Migrating from v1.0 → clearing old games list format")
	AccountManager.current_profile.installed_games.clear()
	AccountManager.save_current_profile()
	
	# Or copy old data to new structure if you want to preserve it
