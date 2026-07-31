extends Control

## =============================================================================
## XLaunch - Setup Wizard Controller
## =============================================================================
## Responsibilities:
## 1. Manages multi-step initial setup UI (Language, Internet Check, GitHub Updates, Accounts).
## 2. Handles cross-platform device detection (PC, Mobile, Tablet, Handheld).
## 3. Dynamically updates UI input hints based on active input method (Keyboard, Touch, Xbox, PS, Deck).
## 4. Handles GitHub release API checks and executable replacement updates.
## =============================================================================

# State Machine: Tracks active setup wizard page
enum Section { SECTION_0, SECTION_1, SECTION_2, SECTION_3, SECTION_4 }
var current_section: Section = Section.SECTION_0

## Download & System State
var updating: bool = false
var current_http: HTTPRequest = null
var Has_Internet: bool = false
var device_type: String = ""
var Language: String = ""

## -----------------------------------------------------------------------------
## Input & Device Asset Preloads
## -----------------------------------------------------------------------------
const KEYBOARD_ENTER = preload("uid://dlnvep7xtk413")
const KEYBOARD_ESCAPE = preload("uid://cm1vnp1c8f3w8")
const PLAYSTATION_T = preload("uid://cahmju8ljwhy7")
const PLAYSTATION_C = preload("uid://bysnw5gchrdq5")
const PLAYSTATION_S = preload("uid://dburtqh8dixqx")
const PLAYSTATION_X = preload("uid://d201iaqyioi2u")
const STEAM_DECK_A = preload("uid://cx1r3e4w27apr")
const STEAM_DECK_B = preload("uid://bxufleq1o3735")
const TOUCH = preload("uid://brr1fmd8gqyqy")
const XBOX_A = preload("uid://bqt1nd1ha1d0d")
const XBOX_B = preload("uid://b3p0iqh1edsww")

## Device Graphic Preloads
const PC_SET_UP = preload("uid://w2ureak6vany")
const PHONE_SETUP = preload("uid://dt0p82ixq5ob5")
const LAPTOP_SET_UP = preload("uid://dnxluotkqm3ox")
const TABLET_SET_UP = preload("uid://dkqc0fgk6hs6q")


## -----------------------------------------------------------------------------
## Initialization
## -----------------------------------------------------------------------------
func _ready() -> void:
	ScreenManager.curr_screen = "Set-Up"
	Language = ScreenManager.Language
	device_type = detect_device_type()
	
	## NOTE: Listen for gamepad hotplugging to switch input glyphs dynamically
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	
	## Assign initial device graphic assets across all wizard sections
	var dev_tex = _get_device_texture(device_type)
	$Section1/Device.texture = dev_tex
	$Section2/Device.texture = dev_tex
	$Section3/Device.texture = dev_tex
	
	if device_type in ["phone", "tablet"] and Input.get_connected_joypads().size() < 1:
		$Section0/Mobile.visible = true
		$Section0/Mobile/Hint.visible = true
		$Section0/Mobile/button.visible = true
		
	_set_section(Section.SECTION_0)
	
	## Intro Animations
	$AnimationPlayer.play("StartSection0")
	await $AnimationPlayer.animation_finished
	$AnimationPlayer.play("Section0HintFade-In")
	
	$Section1/LanguageSelector/Eng.grab_focus()
	
	## Pre-flight non-blocking internet ping
	$HTTPRequest.request("https://example.com")


## -----------------------------------------------------------------------------
## Frame Update Routine
## NOTE: Limited strictly to active download progress calculation to save CPU cycles.
## -----------------------------------------------------------------------------
func _process(_delta: float) -> void:
	if updating and is_instance_valid(current_http):
		var downloaded = current_http.get_downloaded_bytes()
		var total = current_http.get_body_size()
		
		if total > 0:
			var percent = (downloaded / float(total)) * 100.0
			$Section3/DownloadMode/ProgressBar.value = percent
			$Section3/DownloadMode/Progress.text = "%.0f%%" % percent
			var remaining_mb = (total - downloaded) / (1024.0 * 1024.0)
			$Section3/DownloadMode/Remaining.text = "%.1f MB remaining" % remaining_mb
		else:
			$Section3/DownloadMode/Remaining.text = "Downloading..."


## =============================================================================
## State & UI Visibility Controllers
## =============================================================================

## Switches the visible wizard step and enforces UI node isolation.
func _set_section(new_section: Section) -> void:
	current_section = new_section
	
	$Section0.visible = (current_section == Section.SECTION_0)
	$Section1.visible = (current_section == Section.SECTION_1)
	$Section2.visible = (current_section == Section.SECTION_2)
	$Section3.visible = (current_section == Section.SECTION_3)
	$Section4.visible = (current_section == Section.SECTION_4)
	
	## Ensure Section 1 modulate is restored if animations dimmed it
	if current_section == Section.SECTION_1:
		$Section1.modulate = Color.WHITE

	$Section2/Device/CanvasLayer.visible = (current_section == Section.SECTION_2)
	$"setup-progress".visible = (current_section != Section.SECTION_0)
	
	_update_input_glyphs()

## Selects correct button prompts (A/B/Enter/Touch) depending on connected hardware.
func _update_input_glyphs() -> void:
	var has_joypad := Input.get_connected_joypads().size() > 0
	
	## Welcome Screen Input Hint Toggle
	if current_section == Section.SECTION_0:
		$Section0/Controller.visible = has_joypad
		$Section0/Keyboard.visible = not has_joypad and not (device_type in ["phone", "tablet"])
		return

	## Wizard Button Prompts
	if has_joypad:
		var joy_name = str(Input.get_joy_name(0))
		if "Xbox" in joy_name or "XInput" in joy_name:
			$Section1/InputGlyphA.texture = XBOX_A
			$Section2/InputGlyphA.texture = XBOX_A
			$Section2/InputGlyphB.texture = XBOX_B
		elif "PS4" in joy_name or "PS5" in joy_name:
			$Section1/InputGlyphA.texture = PLAYSTATION_X
			$Section2/InputGlyphA.texture = PLAYSTATION_X
			$Section2/InputGlyphB.texture = PLAYSTATION_C
		else:
			$Section1/InputGlyphA.texture = STEAM_DECK_A
			$Section2/InputGlyphA.texture = STEAM_DECK_A
			$Section2/InputGlyphB.texture = STEAM_DECK_B
	else:
		if device_type in ["phone", "tablet"]:
			$Section1/InputGlyphA.texture = TOUCH
		else:
			$Section1/InputGlyphA.texture = KEYBOARD_ENTER
			$Section2/InputGlyphB.texture = KEYBOARD_ESCAPE

func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_update_input_glyphs()

## Centralized section 0 exit helper
func _advance_from_section0() -> void:
	if current_section != Section.SECTION_0:
		return
	$Select.play()
	_set_section(Section.SECTION_1)
	$Section1/LanguageSelector/Eng.grab_focus()


## =============================================================================
## Input Event Handling
## =============================================================================

func _input(event: InputEvent) -> void:
	## Section 0: Allow ui_accept or direct screen tap
	if current_section == Section.SECTION_0:
		if event.is_action_pressed("ui_accept") or \
		   (event is InputEventScreenTouch and event.pressed) or \
		   (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
			get_viewport().set_input_as_handled()
			_advance_from_section0()
			return

	## NOTE: Standard GUI Buttons (Eng, Arabic, Update, Skip) automatically handle 
	## ui_accept when focused! Handling ui_accept manually here causes double-triggering.

	## Cancel / Back Action
	if event.is_action_pressed("Back"):
		if current_section == Section.SECTION_2:
			get_viewport().set_input_as_handled()
			$Back.play()
			_set_section(Section.SECTION_1)
			$"setup-progress".current_tab = 0
			$"setup-progress".set_tab_disabled(1, true)
			$"setup-progress/CurrentSec".text = "Language" if Language == "English" else "اللغة"
			
		elif current_section == Section.SECTION_3 and not updating:
			get_viewport().set_input_as_handled()
			$Back.play()
			_set_section(Section.SECTION_2)
			$"setup-progress".current_tab = 1
			$"setup-progress".set_tab_disabled(2, true)
			$"setup-progress/CurrentSec".text = "Internet" if Language == "English" else "الإنترنت"

	## Section 0: Allow ui_accept or direct screen tap
	if current_section == Section.SECTION_0:
		if event.is_action_pressed("ui_accept") or \
		   (event is InputEventScreenTouch and event.pressed) or \
		   (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
			get_viewport().set_input_as_handled()
			_advance_from_section0()
			$"setup-progress/CurrentSec".text = "Language" if Language == "English" else "اللغة"
			
		elif current_section == Section.SECTION_3 and not updating:
			$Back.play()
			_set_section(Section.SECTION_2)
			$"setup-progress".current_tab = 1
			$"setup-progress".set_tab_disabled(2, true)
			$"setup-progress/CurrentSec".text = "Internet" if Language == "English" else "الإنترنت"


## =============================================================================
## Section 1 & 2: Language & Internet Verification
## =============================================================================

func _on_engLang_pressed() -> void:
	Language = "English"
	$Select.play()
	start_section_2()

func _on_arabicLang_pressed() -> void:
	Language = "Arabic"
	$Select.play()
	start_section_2()

func start_section_2() -> void:
	_set_section(Section.SECTION_2)
	$"setup-progress".current_tab = 1
	$"setup-progress".set_tab_disabled(0, false)
	$"setup-progress".set_tab_disabled(1, false)
	$Section2/Options/skip.grab_focus()
	$"setup-progress/CurrentSec".text = "Internet" if Language == "English" else "الإنترنت"
	
	## Re-check internet access when Section 2 starts
	$HTTPRequest.cancel_request()
	$HTTPRequest.request("https://example.com")

## HTTP Signal Callback: Evaluates connectivity result
func wifi_check_complete(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	Has_Internet = (result == HTTPRequest.RESULT_SUCCESS and response_code == 200)
	
	if Has_Internet:
		$Section2/Device/CanvasLayer/Checkmark.text = "✓"
		$Section2/Device/CanvasLayer/Greenifier.color = Color(0.084, 0.5, 0.056, 1.0)
		$Section2/Title.text = "You're Connected" if Language == "English" else "تم الاتصال"
		$Section2/Subtitle.text = "Now We'll Check for Any Updates (optional)" if Language == "English" else "الآن سنتحقق من تحديثات (اختياري)"
		$Section2/Options/update.text = "Check For Updates" if Language == "English" else "تحقق للتحديثات"
		$Section2/Options/skip.text = "Skip Update" if Language == "English" else "تخطى التحديث"
		$Section2/Options/update.show()
	else:
		$Section2/Device/CanvasLayer/Checkmark.text = "❌"
		$Section2/Device/CanvasLayer/Greenifier.color = Color(1.0, 0.0, 0.0, 1.0)
		$Section2/Title.text = "No Internet" if Language == "English" else "لا يوجد إنترنت"
		$Section2/Subtitle.text = "No problem — updates are optional." if Language == "English" else "لا مشكلة ,التحديثات اختيارية."
		$Section2/Options/update.hide()
		$Section4/Options/Recover.hide()


## =============================================================================
## Section 3: GitHub Updates & Automated Updater
## =============================================================================

func start_Section_3() -> void:
	_set_section(Section.SECTION_3)
	$"setup-progress".current_tab = 2
	$"setup-progress".set_tab_disabled(2, false)
	$Section3/Options/skip.grab_focus()
	
	if device_type != "desktop_pc":
		$Section3/Device/Loading.show()
		$AnimationPlayer.play("updatecheck")
	else:
		$Section3/Device/Loading.hide()
	
	$"setup-progress/CurrentSec".text = "Updates" if Language == "English" else "التحديثات"
	$Section3/Title.text = "We're checking for Updates" if Language == "English" else "سنتحقق من التحديثات"
	
	## Query GitHub Releases API
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_github_release_check)
	http.request("https://api.github.com/repos/NexilFromNullFrame/XLaunch/releases", ["User-Agent: XLaunch"], HTTPClient.METHOD_GET)

## Evaluates GitHub Releases API JSON payload
func _on_github_release_check(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_show_update_fallback("Couldn't check for updates" if Language == "English" else "تعذر التحقق من التحديثات")
		return
	
	var json = JSON.parse_string(body.get_string_from_utf8())
	if not json is Array or json.is_empty():
		_show_update_fallback("No releases found" if Language == "English" else "لم يتم العثور على إصدارات")
		return
	
	var latest = json[0]
	var tag_name = latest.get("name", "0.0.0").lstrip("v")
	var current_version = "0.0.8"
	
	if tag_name != current_version:
		$Section3/Title.text = "Update available: " + tag_name if Language == "English" else "تحديث متوفر: " + tag_name
		$Section3/Options/updatenow.show()
	else:
		$Section3/Title.text = "You're up to date!" if Language == "English" else "أنت محدث!"
		$Section3/Options/skip.text = "Continue" if Language == "English" else "إكمال"
		
	$Section3/Options.show()
	$Section3/Device/Loading.hide()

func _show_update_fallback(msg: String) -> void:
	$Section3/Title.text = msg
	$Section3/Options/skip.text = "Continue" if Language == "English" else "إكمال"
	$Section3/Options.show()
	$Section3/Device/Loading.hide()

## Initiates binary download to temporary user directory
func download_update(url: String, temp_path: String) -> void:
	var http = $Section3/Updater
	http.cancel_request()
	http.download_file = temp_path
	http.request_completed.connect(_on_download_complete)
	
	if http.request(url) != OK:
		updating = false
		$Section3/Subtitle.text = "Download failed" if Language == "English" else "فشل التنزيل"
		return
	
	current_http = http
	updating = true
	$Section3/Options.hide()
	$Section3/DownloadMode.show()
	$Section3/Title.text = "Downloading Update..." if Language == "English" else "جاري تنزيل التحديث..."

func _on_download_complete(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	updating = false
	$Section3/DownloadMode.hide()
	
	if result == OK and response_code == 200:
		replace_and_restart()
	else:
		$Section3/Title.text = "Download failed" if Language == "English" else "فشل التنزيل"
		$Section3/Subtitle.text = "Check your connection and try again" if Language == "English" else "تحقق من الاتصال وحاول مرة أخرى"
		$Section3/Options.show()
	
	if is_instance_valid(current_http):
		current_http.queue_free()
		current_http = null

## Generates external Windows batch script to swap binary files on application exit
func replace_and_restart() -> void:
	var current_exe = OS.get_executable_path()
	var new_exe = ProjectSettings.globalize_path("user://updates/new_version.exe")
	var bat_path = "user://update.bat"
	var bat_content = "@echo off\ntimeout /t 2 /nobreak >nul\ndel \"%1\"\ncopy \"%2\" \"%1\"\nstart \"\" \"%1\"\ndel \"%0\"\n"
	
	var file = FileAccess.open(bat_path, FileAccess.WRITE)
	file.store_string(bat_content)
	file.close()
	
	OS.execute("cmd.exe", PackedStringArray(["/C", bat_path, current_exe, new_exe]))
	get_tree().quit()

## Flags initial boot as finished and transitions to login
func finish_setup() -> void:
	FirstBoot.config.set_value("setup", "completed", true)
	FirstBoot.config.save(FirstBoot.config_path)
	get_tree().change_scene_to_file("res://scenes/log_in.tscn")


## =============================================================================
## Platform Detection & Device Utilities
## =============================================================================

## Evaluates platform flags, DPI, and screen aspect ratio to categorize host device.
func detect_device_type() -> String:
	if OS.has_feature("web"): return "web_browser"
	
	var screen_size = DisplayServer.screen_get_size()
	var aspect = float(screen_size.x) / screen_size.y
	
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		return "tablet" if aspect > 1.6 else "phone"
		
	if OS.get_name() in ["Windows", "macOS", "Linux", "FreeBSD"]:
		var dpi = DisplayServer.screen_get_dpi()
		if (screen_size.x <= 2560 and screen_size.y <= 1600) and dpi >= 110:
			return "laptop"
		return "desktop_pc"
		
	return "unknown_desktop"

func _get_device_texture(type: String) -> Texture2D:
	match type:
		"laptop": return LAPTOP_SET_UP
		"phone": return PHONE_SETUP
		"tablet": return TABLET_SET_UP
		_: return PC_SET_UP


## =============================================================================
## UI Focus & Button Event Callbacks
## =============================================================================

## Generic focus styling helper for Metro UI buttons
func _set_button_focused(btn: Button, focused: bool) -> void:
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER if focused else HORIZONTAL_ALIGNMENT_LEFT
	if btn.has_node("FocusMarker"):
		btn.get_node("FocusMarker").visible = focused
	if focused:
		$Focus.play()

# Button Focus Listeners
func _on_engLang_focus_entered() -> void:
	_set_button_focused($Section1/LanguageSelector/Eng, true)
	$Section1/Title.text = "Hi"
	$Section1/InputGlyphA/Hint.text = "Select"
	$"setup-progress/CurrentSec".text = "Language"

func _on_engLang_focus_exited() -> void: _set_button_focused($Section1/LanguageSelector/Eng, false)

func _on_arabicLang_focus_entered() -> void:
	_set_button_focused($Section1/LanguageSelector/Arabic, true)
	$Section1/Title.text = "مرحبا"
	$Section1/InputGlyphA/Hint.text = "إدخال"
	$"setup-progress/CurrentSec".text = "اللغة"

func _on_arabicLang_focus_exited() -> void: _set_button_focused($Section1/LanguageSelector/Arabic, false)

func _on_skipupdates_focus_entered() -> void: _set_button_focused($Section2/Options/skip, true)
func _on_skipupdates_focus_exited() -> void: _set_button_focused($Section2/Options/skip, false)

func _on_update_focus_entered() -> void: _set_button_focused($Section2/Options/update, true)
func _on_update_focus_exited() -> void: _set_button_focused($Section2/Options/update, false)

func _on_updatenow_focus_entered() -> void: _set_button_focused($Section3/Options/updatenow, true)
func _on_updatenow_focus_exited() -> void: _set_button_focused($Section3/Options/updatenow, false)

func _on_skip_focus_entered() -> void: _set_button_focused($Section3/Options/skip, true)
func _on_skip_focus_exited() -> void: _set_button_focused($Section3/Options/skip, false)

# Button Action Listeners
func _on_update_pressed() -> void:
	$Select.play()
	start_Section_3()

func _on_updatenow_pressed() -> void:
	$Select.play()
	download_update("https://api.github.com/repos/NexilFromNullFrame/XLaunch/releases", "user://updates")

func _on_skipupdates_pressed() -> void:
	$Select.play()
	_set_section(Section.SECTION_4)
	$"setup-progress".current_tab = 3
	$"setup-progress".set_tab_disabled(3, false)
	$"setup-progress/CurrentSec".text = "Accounts"
	$Section4/Options/Recover.grab_focus()

# Mobile Button Direct Callback
func _on_mobilestart_pressed() -> void:
	_advance_from_section0()


func _on_recoveraccount_pressed() -> void:
	$Select.play()
	$Guide.show()
	ScreenManager.is_restricted = true
	$Guide/Recover.show()


func _on_create_new_account_pressed() -> void:
	$Select.play()
	$Guide.show()
	ScreenManager.is_restricted = true
	$Guide/CreateProfile.show()


func _on_skip_update_check_pressed() -> void:
	$Select.play()
	_set_section(Section.SECTION_4)
	$"setup-progress".current_tab = 3
	$"setup-progress".set_tab_disabled(3, false)
	$"setup-progress".set_tab_disabled(2, false)
	$"setup-progress/CurrentSec".text = "Accounts"
	$"Section4/Options/Create New".grab_focus()
