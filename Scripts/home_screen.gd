## Home Screen Controller
## Displays the main dashboard after login.
## Shows current user profile (gamerpic, name, gamerscore), handles restricted access,
## and manages navigation to other screens (games list, settings, profile).
class_name Home_Menu extends Control

@onready var current_userIcon: Button = $BG/CurrentUser ## Defines User's Icon

const NO_RECENTS = preload("uid://bg3scnjahoks7") ## Defines An Available Theme Override for the "[b]Recents[/b]" Tile

## Current gamerpic texture (defaults to sign-in icon if no Account Detected)
var gamerpic = ScreenManager.SIGN_IN

## Current display name (defaults to "Sign in" if no Account Detected)
var DisplayName = """Sign
in"""

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if AccountManager.current_profile != null:
		gamerpic = AccountManager.current_profile.face_texture
		DisplayName = AccountManager.current_profile.display_name
		$BG/Profile/GamerScore.text = str(AccountManager.current_profile.gamerscore)
	else:
		pass
	$BG/LastApp.grab_focus()

## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	$BG/CurrentUser.icon = gamerpic
	$BG/Profile/GamerPic.texture = gamerpic
	$BG/Profile/DispName.text = DisplayName
	$BG/Profile/GamerScore.text = str(AccountManager.current_profile.gamerscore)
	
	if AccountManager.current_profile != null:
		ScreenManager.is_restricted = false
	else:
		ScreenManager.is_restricted = true
	
	# Update last app tile based on previous screen
	if ScreenManager.last_screen == "Game List":
		$BG/LastApp.remove_theme_stylebox_override("normal")
		$BG/LastApp/RecentAppIcon.texture = ScreenManager.ALLAPPS
		$BG/LastApp/RecentName/Name.text = "My games & apps"
	elif ScreenManager.last_screen == "Settings":
		$BG/LastApp.remove_theme_stylebox_override("normal")
		$BG/LastApp/RecentAppIcon.texture = ScreenManager.SETTINGS
		$BG/LastApp/RecentName/Name.text = "Settings"
	elif ScreenManager.last_screen == "Store":
		if ScreenManager.PreferredStore == "EGS":
			$BG/LastApp.remove_theme_stylebox_override("normal")
			$BG/LastApp/RecentAppIcon.texture = ScreenManager.EGS_LOGO
			$BG/LastApp/RecentName/Name.text = "Epic Games Store"
		elif ScreenManager.PreferredStore == "Steam":
			$BG/LastApp.remove_theme_stylebox_override("normal")
			$BG/LastApp/RecentAppIcon.texture = ScreenManager.STEAM_LOGO
			$BG/LastApp/RecentName/Name.text = "Steam"
		elif ScreenManager.PreferredStore == "Native":
			$BG/LastApp.remove_theme_stylebox_override("normal")
			$BG/LastApp/RecentAppIcon.texture = ScreenManager.MS_STORE_LIGHT
			$BG/LastApp/RecentName/Name.text = "Microsoft Store"
	else:
		$BG/LastApp.add_theme_stylebox_override("normal", NO_RECENTS)

## Handles input events (back button, tab navigation, focus sounds).
func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		var focussfxplaying = $Focus.playing
		if focussfxplaying == false:
			$Focus.play()
	
	if event.is_action_pressed("TabLeft"):
		if $BG/FastBar/TabBar.current_tab == 0:
			return
		$BG/FastBar/TabBar.current_tab -= 1
		$PageL.play()
	elif event.is_action_pressed("TabRight"):
		if $BG/FastBar/TabBar.current_tab == 2:
			return
		$BG/FastBar/TabBar.current_tab += 1
		$PageR.play()

## Called when the fast bar tab changes.
func _on_Fastbar_bar_tab_changed(tab: int) -> void:
	if tab < 1:
		$PageL.play()
	elif tab > 1:
		$PageR.play()

## Shows recent app name on focus.
func _on_last_app_Tile_focus_entered() -> void:
	$BG/LastApp/RecentName.visible = true

## Hides recent app name on focus exit.
func _on_last_app_Tile_focus_exited() -> void:
	$BG/LastApp/RecentName.visible = false

## Navigates to My Games & Apps screen if not restricted.
func _on_my_games_pressed() -> void:
	if ScreenManager.is_restricted == true:
		return printerr("Not Available Without Account!")
	$BG/MyGames/Select.play()
	await $BG/MyGames/Select.finished
	ScreenManager.last_screen = "Home Screen"
	ScreenManager.curr_screen = "Game List"
	get_tree().change_scene_to_file("res://scenes/gameslist.tscn")

## Navigates to the last opened screen (games list or settings).
func _on_last_app_pressed() -> void:
	if ScreenManager.last_screen == "Game List":
		$BG/LastApp/Select.play()
		await $BG/LastApp/Select.finished
		get_tree().change_scene_to_file("res://scenes/gameslist.tscn")
	elif ScreenManager.last_screen == "Settings":
		$BG/LastApp/Select.play()
		await $BG/LastApp/Select.finished
		get_tree().change_scene_to_file("res://scenes/settings.tscn")
	elif ScreenManager.last_screen == "Store":
		$BG/LastApp/Select.play()
		if ScreenManager.PreferredStore == "Native":
			OS.shell_open("ms-windows-store://home")
		elif ScreenManager.PreferredStore == "Steam":
			OS.shell_open("steam://open/main")
		elif ScreenManager.PreferredStore == "EGS":
			OS.shell_open("com.epicgames.launcher://store")
		else:
			pass
		ScreenManager.last_screen = "Store"

## Navigates to settings if not restricted.
func _on_settingsTile_pressed() -> void:
	if ScreenManager.is_restricted == true:
		return printerr("Not Available Without Account!")
	$BG/Settings/Select.play()
	await $BG/Settings/Select.finished
	ScreenManager.last_screen = "Home Screen"
	ScreenManager.curr_screen = "Settings"
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

## Navigates to login screen.
func _on_current_user_pressed() -> void:
	$BG/CurrentUser/MenuMinimize.play()
	$BG/CurrentUser/Select.play()
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/log_in.tscn")

## Extracts gamerscore from HTML (used in recovery).
func _extract_gamerscore(html: String) -> int:
	var gs := 0
	# Try 1: <span>Gamerscore</span>4,685
	var r1 := RegEx.new()
	r1.compile('<span>Gamerscore</span>\\s*([\\d,]+)')
	var m1 := r1.search(html)
	if m1: return m1.get_string(1).replace(",", "").to_int()
	
	# Try 2: profile-detail-item version
	var r2 := RegEx.new()
	r2.compile('profile-detail-item[^>]*>\\s*<span>Gamerscore</span>\\s*([\\d,]+)')
	var m2 := r2.search(html)
	if m2: return m2.get_string(1).replace(",", "").to_int()
	
	# Try 3: Sum per-game
	var r3 := RegEx.new()
	r3.compile("Gamerscore\\s*([\\d,]+)")
	for m in r3.search_all(html):
		gs += m.get_string(1).replace(",", "").to_int()
	
	print("GamerScore Ready!")
	AccountManager.current_profile.gamerscore = gs
	$BG/Profile/GamerScore.text = gs
	return gs

## Navigates to profile screen if not restricted.
func _on_profileTILE_pressed() -> void:
	if ScreenManager.is_restricted == false:
		$BG/Profile/Select.play()
		ScreenManager.last_screen = "Home Screen"
		ScreenManager.curr_screen = "Profile"
		await $BG/Profile/Select.finished
		get_tree().change_scene_to_file("res://scenes/profile.tscn")


func _on_store_pressed() -> void:
	$BG/LastApp/Select.play()
	if ScreenManager.PreferredStore == "Native":
		OS.shell_open("ms-windows-store://home")
	elif ScreenManager.PreferredStore == "Steam":
		OS.shell_open("steam://open/main")
	elif ScreenManager.PreferredStore == "EGS":
		OS.shell_open("com.epicgames.launcher://store")
	else:
		pass
	ScreenManager.last_screen = "Store"
