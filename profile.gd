extends Control

@onready var g_tag: Label = $ProfileBG/GTag

var Gamerpic = AccountManager.current_profile.face_texture
var Gamertag = AccountManager.current_profile.gamertag
var Gamerscore = AccountManager.current_profile.gamerscore

var MightLeave : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	g_tag.text = Gamertag
	$ProfileBG/Gamerpic.texture = Gamerpic
	$ProfileBG/CanvasLayer/GScore.text = str(Gamerscore)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Back") and MightLeave == false:
		if ScreenManager.last_screen == "Settings":
			ScreenManager.last_screen = "Profile"
			ScreenManager.curr_screen = "Settings"
			$Back.play()
			await $Back.finished
			get_tree().change_scene_to_file("res://settings.tscn")
		elif ScreenManager.last_screen == "Home Screen":
			ScreenManager.last_screen = "Profile"
			ScreenManager.curr_screen = "Home Screen"
			$Back.play()
			await $Back.finished
			get_tree().change_scene_to_file("res://home_screen.tscn")
	
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		var focussfxplaying = $Focus.playing
		if focussfxplaying == false:
			$Focus.play()

### User Leaving Logic
func _on_profile_remove_pressed() -> void:
	MightLeave = true
	$Select.play()
	## Show Panel and Load-In Animation
	$ProfileRemove/WarningScreen.show()
	$AnimationPlayer.play("Warning-Loadin")


func _on_disagreeAccountDeletion_pressed() -> void:
	MightLeave = false
	$Back.play()
	$ProfileRemove/WarningScreen.hide()


func _on_agreeAccountDeletion_pressed() -> void:
	$Select.play()
	await $Select.finished
	var GTtoDelete = AccountManager.current_profile.gamertag
	AccountManager.remove_profile(GTtoDelete)
	get_tree().change_scene_to_file("res://log_in.tscn")
