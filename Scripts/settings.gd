extends Control

var UserIcon = AccountManager.current_profile.face_texture
var UserName = str(AccountManager.current_profile.display_name)
var Current_Screen = "Home"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.play("intro")

	$PersonalSettings/widetile.grab_focus()
	
	$PersonalSettings/widetile.icon = UserIcon
	$GamerTag.text = UserName

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Back"):
		if Current_Screen == "Home":
			ScreenManager.last_screen = "Settings"
			ScreenManager.curr_screen = "Home Screen"
			$Back.play()
			await $Back.finished
			get_tree().change_scene_to_file("res://scenes/home_screen.tscn")
			return
		elif Current_Screen == "Network Settings":
			$Back.play()
			Current_Screen = "Home"
			$Title.text = "Settings"
			$AnimationPlayer.play_backwards("Transition")
		elif Current_Screen == "Preferred Store":
			$Back.play()
			Current_Screen = "Home"
			$Title.text = "Settings"
			$AnimationPlayer.play_backwards("Transition")
			$PersonalSettings/widetile.grab_focus()
			$StoreApps.hide()
		else:
			$Back.play()
			Current_Screen = "Home"
			$Title.text = "Settings"
			$AnimationPlayer.play_backwards("Transition")
	
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		var focussfxplaying = $Focus.playing
		if focussfxplaying == false:
			$Focus.play()


func _on_Networktile_pressed() -> void:
	Current_Screen = "Network Settings"
	$Title.text = "Network Settings"
	$AnimationPlayer.play("Transition")
	$Select.play()


func _on_personal_info_pressed() -> void:
	$AnimationPlayer.play("TransitionOut")
	$Select.play()
	ScreenManager.last_screen = "Settings"
	ScreenManager.curr_screen = "Profile"
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://scenes/profile.tscn")


func _on_preferred_store_pressed() -> void:
	$AnimationPlayer.play("Transition")
	$Select.play()
	Current_Screen = "Preferred Store"
	await $AnimationPlayer.animation_finished
	$Title.text = "Choose Your Preferred Store"
	$StoreApps.show()
	$StoreApps/Native.grab_focus()


func _on_nativeStore_pressed() -> void:
	ScreenManager.PreferredStore = "Native"


func _on_steamStore_pressed() -> void:
	ScreenManager.PreferredStore = "Steam"


func _on_epicStore_pressed() -> void:
	ScreenManager.PreferredStore = "EGS"
