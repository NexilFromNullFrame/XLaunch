extends Control

## Controller/Touch Check
var JoypadName = str(Input.get_joy_name(0))

## Set-Up State-Check
var in_section0 : bool = true
var in_section1 : bool = false
var in_section2 : bool = false
var in_section3 : bool = false
var in_section4 : bool = false

var updating : bool = false
var current_http: HTTPRequest = null

## Internet Check
var Has_Internet : bool = false

## Language
var Language = ScreenManager.Language # Assuming ScreenManager has Language var

## Preloads for Textures
const KEYBOARD_SET_UP = preload("uid://r6vewgcl6k8h")
const KEYBOARD_ENTER = preload("uid://dlnvep7xtk413")
const KEYBOARD_ESCAPE = preload("uid://cm1vnp1c8f3w8")
const PLAYSTATION_T = preload("uid://cahmju8ljwhy7")
const PLAYSTATION_C = preload("uid://bysnw5gchrdq5")
const PLAYSTATION_S = preload("uid://dburtqh8dixqx")
const PLAYSTATION_X = preload("uid://d201iaqyioi2u")
const STEAM_DECK_A = preload("uid://cx1r3e4w27apr")
const STEAM_DECK_B = preload("uid://bxufleq1o3735")
const STEAM_DECK_X = preload("uid://d3m8dyxwow1vk")
const STEAM_DECK_Y = preload("uid://b6enlojyprip7")
const TOUCH = preload("uid://brr1fmd8gqyqy")
const XBOX_A = preload("uid://bqt1nd1ha1d0d")
const XBOX_B = preload("uid://b3p0iqh1edsww")
const XBOX_X = preload("uid://dt1bkiqc6k0jo")
const XBOX_Y = preload("uid://bx6beggtf3qhf")
const PC_SET_UP = preload("uid://w2ureak6vany")
const PHONE_SETUP = preload("uid://dt0p82ixq5ob5")
const LAPTOP_SET_UP = preload("uid://dnxluotkqm3ox")
const TABLET_SET_UP = preload("uid://dkqc0fgk6hs6q")

func _ready() -> void:
	ScreenManager.curr_screen = "Set-Up"
	var Device = detect_device_type()
	$HTTPRequest.request("https://example.com") # Internet check
	# Set initial device icon for Section 1
	if Device == "laptop":
		$Section1/Device.texture = LAPTOP_SET_UP
	elif Device == "desktop_pc":
		$Section1/Device.texture = PC_SET_UP
	elif Device == "phone":
		$Section1/Device.texture = PHONE_SETUP
	elif Device == "tablet":
		$Section1/Device.texture = TABLET_SET_UP
	# Force correct initial visibility
	$Section0.visible = true
	$Section1.visible = false
	$Section2.visible = false
	$"setup-progress".visible = false
	# Show controller or keyboard in Section 0 from the start
	if Input.get_connected_joypads().size() >= 1:
		$Section0/Controller.visible = true
		$Section0/Keyboard.visible = false
	else:
		$Section0/Controller.visible = false
		$Section0/Keyboard.visible = true
	# Start animations
	$AnimationPlayer.play("StartSection0")
	await $AnimationPlayer.animation_finished
	$AnimationPlayer.play("Section0HintFade-In")
	# Focus first language option (for Section 1 later)
	$Section1/LanguageSelector/Eng.grab_focus()

func _process(_delta: float) -> void:
	var Device = detect_device_type()
	# Section visibility - only one active at a time
	$Section0.visible = in_section0
	$Section1.visible = in_section1
	$Section2.visible = in_section2
	$Section2/Device/CanvasLayer.visible = in_section2
	# Controller / Keyboard visibility in Section 0
	if in_section0:
		if Input.get_connected_joypads().size() >= 1:
			$Section0/Controller.visible = true
			$Section0/Keyboard.visible = false
		else:
			$Section0/Controller.visible = false
			$Section0/Keyboard.visible = true
	# Device icon update (only when in Section 1)
	if in_section1 or in_section2:
		if Device == "laptop":
			$Section1/Device.texture = LAPTOP_SET_UP
			$Section2/Device.texture = LAPTOP_SET_UP
		elif Device == "desktop_pc":
			$Section1/Device.texture = PC_SET_UP
			$Section2/Device.texture = PC_SET_UP
		elif Device == "phone":
			$Section1/Device.texture = PHONE_SETUP
			$Section2/Device.texture = PHONE_SETUP
		elif Device == "tablet":
			$Section1/Device.texture = TABLET_SET_UP
			$Section2/Device.texture = TABLET_SET_UP
	# Progress bar visibility (hide in Section 0)
	$"setup-progress".visible = not in_section0
	# Glyphs for Section 1 & 2
	if Input.get_connected_joypads().size() >= 1:
		if JoypadName == "XInput Controller" or JoypadName == "Xbox Controller":
			$Section1/InputGlyphA.texture = XBOX_A
			$Section2/InputGlyphA.texture = XBOX_A
			$Section2/InputGlyphB.texture = XBOX_B
		elif JoypadName == "PS4 Controller" or JoypadName == "PS5 Controller":
			$Section1/InputGlyphA.texture = PLAYSTATION_X
			$Section2/InputGlyphA.texture = PLAYSTATION_X
			$Section2/InputGlyphB.texture = PLAYSTATION_C
		else:
			$Section1/InputGlyphA.texture = STEAM_DECK_A
			$Section2/InputGlyphA.texture = STEAM_DECK_A
			$Section2/InputGlyphB.texture = STEAM_DECK_B
	else:
		if Device == "tablet" or Device == "phone":
			$Section1/InputGlyphA.texture = TOUCH
		else:
			$Section1/InputGlyphA.texture = KEYBOARD_ENTER
			$Section2/InputGlyphB.texture = KEYBOARD_ESCAPE
	if updating and is_instance_valid(current_http):  # we'll store current_http
		var downloaded = current_http.get_downloaded_bytes()
		var total = current_http.get_body_size()
		
		if total > 0:
			var percent = (downloaded / float(total)) * 100
			$Section3/DownloadMode/ProgressBar.value = percent
			$Section3/DownloadMode/Progress.text = "%.0f%%" % percent
			
			var remaining_mb = (total - downloaded) / (1024.0 * 1024.0)
			$Section3/DownloadMode/Remaining.text = "%.1f MB remaining" % remaining_mb
		else:
			$Section3/DownloadMode/Remaining.text = "Downloading..."

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if in_section0:
			in_section0 = false
			in_section1 = true
			$Select.play()
			$Section1/LanguageSelector/Eng.grab_focus()
		elif in_section1:
			if $Section1/LanguageSelector/Eng.has_focus():
				_on_engLang_pressed()
			elif $Section1/LanguageSelector/Arabic.has_focus():
				_on_arabicLang_pressed()
		elif in_section2 and $Section2/Options/update.has_focus():
			_on_update_pressed()
	if event.is_action_pressed("Back"):
		if in_section2:
			in_section2 = false
			in_section1 = true
			$Back.play()
			$Section2.hide()
			$Section1.show()
			$"setup-progress".current_tab = 0
			$"setup-progress".set_tab_disabled(1, true)
			if Language == "English":
				$"setup-progress/CurrentSec".text = "Language"
			elif Language == "Arabic":
				$"setup-progress/CurrentSec".text = "اللغة"
		if in_section3 and updating == false:
			in_section3 = false
			in_section2 = true
			$Back.play()
			$Section3.hide()
			$Section2.show()
			$"setup-progress".current_tab = 1
			$"setup-progress".set_tab_disabled(2, true)
			if Language == "English":
				$"setup-progress/CurrentSec".text = "Internet"
			elif Language == "Arabic":
				$"setup-progress/CurrentSec".text = "الإنترنت"

func _on_engLang_pressed() -> void:
	in_section1 = false
	in_section2 = true
	Language = "English"
	$Select.play()
	start_section_2()

func _on_arabicLang_pressed() -> void:
	in_section1 = false
	in_section2 = true
	Language = "Arabic"
	$Select.play()
	start_section_2()

func start_section_2() -> void:
	$Section2.show()
	$"setup-progress".current_tab = 1
	$"setup-progress".set_tab_disabled(0, false)
	$"setup-progress".set_tab_disabled(1, false)
	$Section2/Options/skip.grab_focus()
	if Language == "English":
		$"setup-progress/CurrentSec".text = "Internet"
	elif Language == "Arabic":
		$"setup-progress/CurrentSec".text = "الإنترنت"
	# Start non-blocking internet check
	$HTTPRequest.cancel_request()
	$HTTPRequest.request("https://example.com")

func wifi_check_complete(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		print("user has internet access")
		Has_Internet = true
		$Section2/Device/CanvasLayer/Checkmark.text = "✔️"
		$Section2/Device/CanvasLayer/Greenifier.color = Color(0.084, 0.5, 0.056, 1.0)
		if Language == "English":
			$Section2/Title.text = "You're Connected"
			$Section2/Subtitle.text = "Now We'll Check for Any Updates (optional)"
			$Section2/Options/update.text = "Check For Updates"
			$Section2/Options/skip.text = "Skip Update"
		elif Language == "Arabic":
			$Section2/Title.text = "تم الاتصال"
			$Section2/Subtitle.text = "الآن سنتحقق من تحديثات (اختياري)"
			$Section2/Options/update.text = "تحقق للتحديثات"
			$Section2/Options/skip.text = "تخطى التحديث"
	else:
		print("user doesn't have internet Access")
		Has_Internet = false
		$Section2/Device/CanvasLayer/Checkmark.text = "❌"
		$Section2/Device/CanvasLayer/Greenifier.color = Color(1.0, 0.0, 0.0, 1.0)
		if Language == "English":
			$Section2/Title.text = "No Internet"
			$Section2/Subtitle.text = "No problem — updates are optional."
			$Section2/Options/update.hide()
		elif Language == "Arabic":
			$Section2/Title.text = "لا يوجد إنترنت"
			$Section2/Subtitle.text = "لا مشكلة ,التحديثات اختيارية."
			$Section2/Options/update.hide()

func start_Section_3() -> void:
	$Section2.hide()
	$Section3.show()
	$"setup-progress".current_tab = 2
	$"setup-progress".set_tab_disabled(2, false)
	
	var device = detect_device_type()
	if device == "desktop_pc":
		$Section3/Device.texture = PC_SET_UP
		$Section3/Device/Loading.hide()
	elif device == "phone":
		$Section3/Device.texture = PHONE_SETUP
		$Section3/Device/Loading.show()
		$AnimationPlayer.play("updatecheck")
	elif device == "tablet":
		$Section3/Device.texture = TABLET_SET_UP
		$Section3/Device/Loading.show()
		$AnimationPlayer.play("updatecheck")
	elif device == "laptop":
		$Section3/Device.texture = LAPTOP_SET_UP
		$Section3/Device/Loading.show()
		$AnimationPlayer.play("updatecheck")
	
	if Language == "English":
		$"setup-progress/CurrentSec".text = "Updates"
		$Section3/Title.text = "We're checking for Updates"
	elif Language == "Arabic":
		$"setup-progress/CurrentSec".text = "التحديثات"
		$Section3/Title.text = "سنتحقق من التحديثات"
	
	# ───────────────────────────────
	# GitHub release check integration
	# ───────────────────────────────
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_github_release_check)
	
	var url = "https://api.github.com/repos/NexilFromNullFrame/XLaunch/releases"
	var headers = ["User-Agent: XLaunch"]
	
	var err = http.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		print("GitHub check failed to start: ", err)
		$Section3/Subtitle.text = "Couldn't check for updates" if Language == "English" else "تعذر التحقق من التحديثات"
		$Section3/Options/skip.text = "Continue" if Language == "English" else "إكمال"
		$Section3/Options.show()
		$Section3/Device/Loading.hide()

func _on_github_release_check(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("GitHub API error: ", response_code)
		$Section3/Title.text = "Couldn't check for updates" if Language == "English" else "تعذر التحقق من التحديثات"
		$Section3/Options/skip.text = "Continue" if Language == "English" else "إكمال"
		$Section3/Options.show()
		$Section3/Device/Loading.hide()
		return
	
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null or not json is Array or json.is_empty():
		$Section3/Title.text = "No releases found" if Language == "English" else "لم يتم العثور على إصدارات"
		$Section3/Options/skip.text = "Continue" if Language == "English" else "إكمال"
		$Section3/Options.show()
		$Section3/Device/Loading.hide()
		return
	
	# Take the newest release (array is newest → oldest)
	var latest = json[0]
	var tag_name = latest.get("name", "0.0.0").lstrip("v")
	var current_version = "0.0.8"  # ← your current version
	
	if tag_name != current_version:
		$Section3/Title.text = "Update available: " + tag_name if Language == "English" else "تحديث متوفر: " + tag_name
		$Section3/Options/updatenow.show()
		$Section3/Options.show()
		# Optional: store download URL
		var assets = latest.get("assets", [])
		for asset in assets:
			if asset.get("name", "").ends_with(".zip") or asset.get("name", "").ends_with(".exe"):
				var url = asset.get("browser_download_url", "")
				print("Download URL: ", url)
				# You can show a button later
				break
	else:
		$Section3/Title.text = "You're up to date!" if Language == "English" else "أنت محدث!"
		$Section3/Options/skip.text = "Continue" if Language == "English" else "إكمال"
		$Section3/Options.show()
	
	$Section3/Device/Loading.hide()

func download_update(url: String, temp_path: String) -> void:
	var http = $Section3/Updater  # reuse existing node
	
	# Reset state
	http.cancel_request()  # stop any previous request
	http.download_file = temp_path
	http.request_completed.connect(_on_download_complete)
	
	var err = http.request(url)
	if err != OK:
		print("Download failed to start: ", err)
		updating = false
		$Section3/Subtitle.text = "Download failed" if Language == "English" else "فشل التنزيل"
		return
	
	current_http = http
	updating = true
	$Section3/Options.hide()
	$Section3/DownloadMode.show()
	$Section3/DownloadMode/ProgressBar.value = 0
	$Section3/DownloadMode/Progress.text = "0%"
	$Section3/DownloadMode/Remaining.text = "0 MB remaining"
	$Section3/Title.text = "Downloading Update..." if Language == "English" else "جاري تنزيل التحديث..."

var total_bytes: int = 0
@onready var downloaded_bytes = $Section3/Updater.get_downloaded_bytes()

@warning_ignore("shadowed_variable_base_class")
func _on_body_size_received(size: int) -> void:
	total_bytes = size
	if total_bytes > 0:
		$Section3/DownloadMode/Remaining.text = "%.1f MB total" % (total_bytes / 1024.0 / 1024.0)

func _on_download_chunk_received(chunk: PackedByteArray) -> void:
	downloaded_bytes += chunk.size()
	if total_bytes > 0:
		var percent = (downloaded_bytes / float(total_bytes)) * 100
		$Section3/DownloadMode/ProgressBar.value = percent
		$Section3/DownloadMode/Progress.text = "%.0f%%" % percent
		
		var remaining_mb = (total_bytes - downloaded_bytes) / 1024.0 / 1024.0
		$Section3/DownloadMode/Remaining.text = "%.1f MB remaining" % remaining_mb
	else:
		$Section3/DownloadMode/Remaining.text = "Downloading..."

func _on_download_progress(received: int, total: int) -> void:
	@warning_ignore("incompatible_ternary")
	var percent = (received / float(total)) * 100 if total > 0 else 0
	$Section3/DownloadMode/ProgressBar.value = percent  # update UI bar
	$Section3/DownloadMode/Progress.text = "%s%" %str($Section3/DownloadMode/ProgressBar.value)
	$Section3/DownloadMode/Remaining.text = "%s MB remaining" %str(total-received)
	print("Download progress: ", percent, "%")

func _on_download_complete(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	updating = false
	$Section3/DownloadMode.hide()
	
	if result == OK and response_code == 200:
		print("Download complete — now replacing")
		replace_and_restart()
	else:
		print("Download failed: ", response_code)
		$Section3/Title.text = "Download failed" if Language == "English" else "فشل التنزيل"
		$Section3/Subtitle.text = "Check your connection and try again" if Language == "English" else "تحقق من الاتصال وحاول مرة أخرى"
		$Section3/Options.show()
	
	# Clean up the HTTPRequest node
	if is_instance_valid(current_http):
		current_http.queue_free()
		current_http = null

func replace_and_restart() -> void:
	var current_exe = OS.get_executable_path()
	var new_exe = ProjectSettings.globalize_path("user://updates/new_version.exe")
	
	# Create a batch file to replace after quit
	var bat_path = "user://update.bat"
	var bat_content = """
@echo off
timeout /t 2 /nobreak >nul  # wait 2 seconds for app to quit
del "%1"  # delete old exe
copy "%2" "%1"  # copy new
start "" "%1"  # restart
del "%0"  # delete this bat
"""
	var file = FileAccess.open(bat_path, FileAccess.WRITE)
	file.store_string(bat_content)
	file.close()
	
	# Run the bat with args: current_exe, new_exe
	var args = PackedStringArray(["/C", bat_path, current_exe, new_exe])
	OS.execute("cmd.exe", args)  # non-blocking
	# Quit the app — bat takes over
	get_tree().quit()

func finish_setup() -> void:
	FirstBoot.config.set_value("setup", "completed", true)
	FirstBoot.config.save(FirstBoot.config_path)
	get_tree().change_scene_to_file("res://scenes/log_in.tscn")

# Device detection
func detect_device_type() -> String:
	var os_name = OS.get_name()
	var is_mobile = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")
	var is_web = OS.has_feature("web")
	var screen_size = DisplayServer.screen_get_size()
	var aspect = float(screen_size.x) / screen_size.y
	if is_web:
		return "web_browser"
	if is_mobile:
		if aspect > 1.6:
			return "tablet"
		return "phone"
	if os_name in ["Windows", "macOS", "Linux", "FreeBSD"]:
		var dpi = DisplayServer.screen_get_dpi()
		if (screen_size.x <= 2560 and screen_size.y <= 1600) and dpi >= 110:
			return "laptop"
		return "desktop_pc"
	if OS.has_feature("steam_deck") or OS.get_processor_name().to_lower().contains("ryzen") and screen_size.x == 1280 and screen_size.y == 800:
		return "handheld_pc"
	return "unknown_desktop"

# Language focus
func _on_engLang_focus_entered() -> void:
	$Section1/LanguageSelector/Eng.alignment = 1
	$Section1/LanguageSelector/Eng/FocusMarker.show()
	$Focus.play()
	$Section1/Title.text = "Hi"
	$Section1/InputGlyphA/Hint.text = "Select"
	$"setup-progress/CurrentSec".text = "Language"

func _on_engLang_focus_exited() -> void:
	$Section1/LanguageSelector/Eng.alignment = 0
	$Section1/LanguageSelector/Eng/FocusMarker.hide()

func _on_arabicLang_focus_entered() -> void:
	$Section1/LanguageSelector/Arabic.alignment = 1
	$Section1/LanguageSelector/Arabic/FocusMarker.show()
	$Focus.play()
	$Section1/Title.text = "مرحبا"
	$Section1/InputGlyphA/Hint.text = "إدخال"
	$"setup-progress/CurrentSec".text = "اللغة"

func _on_arabicLang_focus_exited() -> void:
	$Section1/LanguageSelector/Arabic.alignment = 0
	$Section1/LanguageSelector/Arabic/FocusMarker.hide()

func _on_skipupdates_focus_entered() -> void:
	$Section2/Options/skip.alignment = 1
	$Section2/Options/skip/FocusMarker.show()
	$Focus.play()

func _on_skipupdates_focus_exited() -> void:
	$Section2/Options/skip.alignment = 0
	$Section2/Options/skip/FocusMarker.hide()

func _on_update_focus_entered() -> void:
	$Section2/Options/update.alignment = 1
	$Section2/Options/update/FocusMarker.show()
	$Focus.play()

func _on_update_focus_exited() -> void:
	$Section2/Options/update.alignment = 0
	$Section2/Options/update/FocusMarker.hide()

func _on_update_pressed() -> void:
	in_section2 = false
	in_section3 = true
	$Select.play()
	start_Section_3()


func _on_updatenow_focus_entered() -> void:
	$Section3/Options/updatenow.alignment = 1
	$Section3/Options/updatenow/FocusMarker.show()
	$Focus.play()


func _on_updatenow_focus_exited() -> void:
	$Section3/Options/updatenow.alignment = 0
	$Section3/Options/updatenow/FocusMarker.hide()


func _on_skip_focus_entered() -> void:
	$Section3/Options/skip.alignment = 1
	$Section3/Options/skip/FocusMarker.show()
	$Focus.play()


func _on_skip_focus_exited() -> void:
	$Section3/Options/skip.alignment = 0
	$Section3/Options/skip/FocusMarker.hide()


func _on_updatenow_pressed() -> void:
	$Select.play()
	download_update("https://api.github.com/repos/NexilFromNullFrame/XLaunch/releases", "user://updates")
	$Section3/Options.hide()
	$Section3/DownloadMode.show()
