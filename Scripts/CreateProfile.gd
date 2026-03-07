extends Control

@onready var name_input: LineEdit = $NameInput
@onready var gs_spin: SpinBox = $GSSpin
@onready var icon_button:  = $PickIconButton
@onready var create_button: Button = $CreateButton

var icon_tex: Texture2D = null

func _ready() -> void:
	$NameInput.grab_focus()
	icon_button.pressed.connect(_pick_icon)
	create_button.pressed.connect(_create)

func _pick_icon() -> void:
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters = ["*.png,*.jpg ; Images"]
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_selected.connect(func(path):
		var img = Image.new()
		img.load(path)
		icon_tex = ImageTexture.create_from_image(img)
	)
	add_child(dialog)
	dialog.popup_centered(Vector2(800, 600))

func _process(_delta: float) -> void:
	icon_button.icon = icon_tex

func _create() -> void:
	var GTag = name_input.text.strip_edges()
	var gs = gs_spin.value
	var gp = $PickIconButton.icon
	if GTag.is_empty():
		return
	if gp == null:
		return

	$Select.play()
	AccountManager.add_profile(GTag, GTag, gs, true, [], icon_tex, null)
	await $Select.finished
	if ScreenManager.last_screen == "log-in":
		get_tree().change_scene_to_file("res://scenes/log_in.tscn")

func _input(event: InputEvent) -> void:
	if event:
		if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			var focussfxplaying = $Focus.playing
			if focussfxplaying == false:
				$Focus.play()
		if event.is_action_pressed("Back"):
			if ScreenManager.last_screen == "log-in":
				ScreenManager.last_screen = "CreateAcc"
				ScreenManager.curr_screen = "log-in"
			$Back.play()
			await $Back.finished
			
			get_tree().change_scene_to_file("res://scenes/log_in.tscn")
