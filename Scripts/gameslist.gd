## Manages the game list grid UI for the Xbox launcher.
##
## Displays a grid of installed/custom games/apps.
## Supports adding new entries with icon picker and file picker for launch path.
## Handles launching apps/executables via FileDialog on desktop and Android SAF fallback.
## Includes focus sound, name panel visibility, and back navigation.
class_name GameList extends Control

@onready var current_userIcon: TextureRect = $BG/CurrentUser
var gamerpic = AccountManager.current_profile.face_texture
@onready var tile_template: Button = $BG/ApplistGrid/GridContainer/Template
@onready var grid_container: GridContainer = $BG/ApplistGrid/GridContainer # ← your grid
var LastTile = "AddNew"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$BG/ApplistGrid/GridContainer/AddNew.grab_focus()
	refresh_games_ui() # Load games on start

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	$BG/CurrentUser.texture = gamerpic
	update_last_focused()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Back"):
		ScreenManager.last_screen = "Game List"
		ScreenManager.curr_screen = "Home Screen"
		$Back.play()
		await $Back.finished
		get_tree().change_scene_to_file("res://scenes/home_screen.tscn")
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		var focussfxplaying = $Focus.playing
		if focussfxplaying == false:
			$Focus.play()
	if event.is_action_pressed("Menu") and not $BG/ApplistGrid/GridContainer/AddNew.has_focus():
		if $Menu.visible == true:
			$MenuMinimize.play()
			$Menu.visible = false
		else:
			$Menu/SelectedItemName.text = LastTile
			$Menu.visible = true
			$MenuMaximize.play()

func _on_add_game_pressed() -> void:
	$Select.play()
	if $BG/ApplistGrid/GridContainer.get_child_count() -1 > 15:
		$BG/ApplistGrid/GridContainer.columns += 1
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters = ["*.png,*.jpg ; Images"]
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_selected.connect(_on_game_icon_picked)
	add_child(dialog)
	dialog.popup_centered(Vector2(800, 600))
	dialog.title = "Pick Game/App Icon"

## [b] After Loading Icon [/b]
func _on_game_icon_picked(path: String) -> void:
	var img = Image.new()
	img.load(path)
	var icon = ImageTexture.create_from_image(img)
	# Custom input dialog for name (controller-friendly)
	var name_dialog = _create_input_dialog("Game Name:", func(name):
		if name.is_empty(): return
		# Launch path dialog
		var launch_dialog = _create_input_dialog("Launch Path (optional):", func(launch):
			var new_game = {
				"name": name,
				"icon_path": path,
				"gs": 0,
				"launch_path": launch
			}
			AccountManager.current_profile.installed_games.append(new_game)
			AccountManager.save_current_profile()
			refresh_games_ui()
		)
		add_child(launch_dialog)
		launch_dialog.popup_centered()
	)
	add_child(name_dialog)
	name_dialog.popup_centered()

func refresh_games_ui() -> void:
	# Get games from current profile (safe default)
	var games = AccountManager.current_profile.get("installed_games", [])
	print("Loading ", games.size(), " games from profile: ", games) # Debug: see what's loaded
	for game in games:
		var new_tile = tile_template.duplicate()
		new_tile.visible = true
		new_tile.name = game.name
		# Fill tile — load icon from filesystem path
		var image = Image.load_from_file(game.icon_path)
		new_tile.icon = ImageTexture.create_from_image(image)
		var name_node = new_tile.get_node_or_null("NamePanel/Name") # adjust path if wrong
		if name_node:
			name_node.text = game.name
		# Click to launch (fixed for .exe/.lnk — use shell_open for all types)
		new_tile.pressed.connect(func():
			$Select.play()
			if game.launch_path != "":
				var launch_error = OS.shell_open(game.launch_path)
				if launch_error != OK:
					print("Failed to launch ", game.launch_path, " — error: ", launch_error)
			else:
				print("No launch path for ", game.name)
		)
		# Name bar show/hide on focus (your original connects)
		new_tile.focus_entered.connect(func():
			var name_panel = new_tile.get_node_or_null("NamePanel")
			if name_panel:
				name_panel.visible = true
		)
		new_tile.focus_exited.connect(func():
			var name_panel = new_tile.get_node_or_null("NamePanel")
			if name_panel:
				name_panel.visible = false
		)
		grid_container.add_child(new_tile)
	print("Refreshed ", games.size(), " games in UI")

# Custom controller-friendly input dialog
func _create_input_dialog(title: String, callback: Callable) -> AcceptDialog:
	var dialog = AcceptDialog.new()
	dialog.dialog_text = title
	dialog.ok_button_text = "OK"
	dialog.add_cancel_button("Cancel")
	dialog.size = Vector2i(300, 200)
	var input = LineEdit.new()
	input.placeholder_text = "Enter here..."
	input.grab_focus()
	dialog.add_child(input)
	dialog.confirmed.connect(func():
		callback.call(input.text.strip_edges())
		dialog.queue_free()
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	# Grab focus on show
	dialog.grab_focus()
	return dialog

func update_last_focused() -> void :
	LastTile = str(get_viewport().gui_get_focus_owner().name)


func _on_storetile_pressed() -> void:
	$Select.play()
	if ScreenManager.PreferredStore == "Native":
		OS.shell_open("ms-windows-store://home")
	elif ScreenManager.PreferredStore == "Steam":
		OS.shell_open("steam://open/main")
	elif ScreenManager.PreferredStore == "EGS":
		OS.shell_open("com.epicgames.launcher://store")
	else:
		pass
