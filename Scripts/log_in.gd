extends Control

var LinkToIcon = "https://avatar-ssl.xboxlive.com/avatar/ComputerTrac/avatarpic-l.png"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$BG/Accounts/AccountList/Recover.grab_focus()
	_refresh_carousel()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_account_Recover_pressed() -> void:
	$Select.play()
	ScreenManager.last_screen = "log-in"
	ScreenManager.curr_screen = "RecoverAcc"
	await $Select.finished
	get_tree().change_scene_to_file("res://scenes/recover.tscn")

func _input(event: InputEvent) -> void:
	if event:
		if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			var focussfxplaying = $Focus.playing
			if focussfxplaying == false:
				$Focus.play()

func _refresh_carousel() -> void:
	# Add real/custom profiles
	for i in AccountManager.profiles.size():
		var profile = AccountManager.profiles[i]
		var tile = $BG/Accounts/AccountList/Template.duplicate()
		tile.visible = true
		tile.name = "Profile_" + str(i)
		
		if profile.face_texture.get_size() < Vector2(512.0, 512.0):
			tile.get_node("SmallIconHelper").show()
			tile.get_node("SmallIconHelper/SmallGamerIcon").texture = profile.face_texture
		else:
			tile.icon = profile.face_texture
		tile.get_node("Gamertag").text = profile.gamertag
		
		# Optional GS for Xbox One style
		#tile.get_node("GS").text = str(profile.gamerscore) + " G" if not profile.is_custom else ""
		
		tile.pressed.connect(func():
			AccountManager.select_profile(i)
			$Select.play()
			await $Select.finished
			get_tree().change_scene_to_file("res://scenes/welcome.tscn")
		)
		
		$BG/Accounts/AccountList.add_child(tile)


func _on_createAcc_pressed() -> void:
	$Select.play()
	ScreenManager.last_screen = "log-in"
	ScreenManager.curr_screen = "CreateAcc"
	await $Select.finished
	get_tree().change_scene_to_file("res://scenes/create_profile.tscn")
