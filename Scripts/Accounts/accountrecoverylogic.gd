## Handles Gamertag profile recovery, Gamerscore parsing, and picture fetching for the Xbox launcher.
##
## Scrapes Gamerscore and Gamerpic directly from xboxgamertag.com by default.
## Integrates a toggle ([member avatar_or_gp]) to fallback to legacy 3D Xbox Live Avatars.
## Supports HTTP retries, User-Agent rotation, WebP/PNG/JPEG decoding, and custom image uploads.
extends Control

## Default URL endpoint template for full-body Xbox Live avatars.
var LinkAvatarFullBody: String = "https://avatar-ssl.xboxlive.com/avatar/Gamertag/avatar-body.png"
## Default URL endpoint template for Xbox Live avatar face icons.
var LinkAvatarIcon: String = "https://avatar-ssl.xboxlive.com/avatar/Gamertag/avatarpic-l.png"

## Input field for entering the target Gamertag.
@onready var gamerinput: LineEdit = $Gamerinput
## Label displaying the parsed Gamerscore value.
@onready var gamerscore_label: Label = $GamerScoreLabel
## Display container for the loaded Gamerpic or Avatar texture.
@onready var gamerpic: TextureRect = $Gamerpic
## Header title label for status messages and feedback.
@onready var Title: Label = $BG/Label
## Button to finalize profile creation.
@onready var create_account_Button: Button = $CreateAccount
## Button to trigger file dialog for uploading custom icons.
@onready var pick_icon_button: Button = $PickIconButton
## Toggle button determining whether to scrape Gamerpic (default) or fetch 3D Avatar.
@onready var avatar_or_gp: BaseButton = $Avatarorgp

## Holds custom user-uploaded texture if web fetching fails or is overridden.
var icon_tex: Texture2D = null
## Internal HTTP worker node for network operations.
var http: HTTPRequest = HTTPRequest.new()
## The active Gamertag being queried.
var current_gamertag: String = ""
## The extracted Gamerscore integer value.
var current_gamerscore: int = 0


func _ready() -> void:
	add_child(http)
	if not gamerinput:
		printerr("No Gamertag LineEdit!!")
	
	# Connect custom icon picker
	pick_icon_button.pressed.connect(_on_pick_icon_pressed)


## Initiates HTML scraping for the active [member current_gamertag] from xboxgamertag.com.
## Handles network retries, User-Agent rotation, and branches image fetching based on [member avatar_or_gp].
func fetch_fresh_data() -> void:
	var url: String = "https://xboxgamertag.com/search/" + current_gamertag
	
	# Rotate User-Agents to avoid scraper blocking
	var user_agents: Array[String] = [
		"XboxLive/2.0",
		"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
		"Mozilla/5.0 (Xbox; Xbox One) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
	]
	var ua: String = user_agents[randi() % user_agents.size()]
	
	var headers := PackedStringArray([
		"User-Agent: " + ua,
		"Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
		"Accept-Language: en-US,en;q=0.5",
		"Referer: https://xboxgamertag.com/"
	])
	
	var attempts: int = 0
	var max_attempts: int = 3
	var success: bool = false
	
	http.timeout = 10.0  # Prevent hanging requests
	
	while attempts < max_attempts and not success:
		var error: Error = http.request(url, headers)
		if error != OK:
			print("Request setup failed: ", error)
			attempts += 1
			await get_tree().create_timer(2.0).timeout
			continue
		
		var response: Array = await http.request_completed
		var response_code: int = response[1]
		var body: PackedByteArray = response[3]
		
		if response_code == 200:
			success = true
			var html: String = body.get_string_from_utf8()
			
			# 1. Parse Gamerscore
			var gs: int = _extract_gamerscore(html)
			gamerscore_label.text = str(gs)
			current_gamerscore = gs
			
			# 2. Determine Image Source based on the Avatarorgp toggle
			# Default: False / Unpressed = Scrape Gamerpic
			# Pressed = Legacy 3D Xbox Live Avatar
			if avatar_or_gp and avatar_or_gp.button_pressed:
				print("Toggle set to Avatar — fetching Xbox Live 3D Avatar...")
				load_avatar_face("xl")
			else:
				print("Toggle set to Gamerpic (Default) — scraping web Gamerpic...")
				var pic_url: String = _extract_gamerpic_url(html)
				if not pic_url.is_empty():
					_download_gamerpic(pic_url)
				else:
					_enable_custom_upload()
			
			print("Loaded Profile! GS: ", gs)
		else:
			print("Retry ", attempts + 1, "/", max_attempts, " — Code: ", response_code)
			attempts += 1
			await get_tree().create_timer(2.0).timeout
	
	if not success:
		gamerscore_label.text = "Error (Max retries reached)"
		Title.text = "Not Found!"


## Scrapes and returns the Gamerscore integer value from profile HTML [param html].
func _extract_gamerscore(html: String) -> int:
	var gs: int = 0
	
	var r1 := RegEx.new()
	r1.compile('<span>Gamerscore</span>\\s*([\\d,]+)')
	var m1 := r1.search(html)
	if m1: return m1.get_string(1).replace(",", "").to_int()
	
	var r2 := RegEx.new()
	r2.compile('profile-detail-item[^>]*>\\s*<span>Gamerscore</span>\\s*([\\d,]+)')
	var m2 := r2.search(html)
	if m2: return m2.get_string(1).replace(",", "").to_int()
	
	var r3 := RegEx.new()
	r3.compile("Gamerscore\\s*([\\d,]+)")
	for m in r3.search_all(html):
		gs += m.get_string(1).replace(",", "").to_int()
	
	print("GamerScore Ready!")
	current_gamerscore = gs
	return gs


## Extracts the Gamerpic ID from HTML and constructs a direct 1080p Microsoft CDN link
func _extract_gamerpic_url(html: String) -> String:
	# Matches the exact URL string inside image?url= up to the next '&' or '"'
	var regex := RegEx.new()
	regex.compile("images-eds-ssl\\.xboxlive\\.com/image\\?url=([^&\"\\s]+)")
	var match := regex.search(html)
	
	if match:
		# Group 1 contains the clean raw gamerpic ID
		var image_id: String = match.get_string(1).uri_decode()
		
		# Construct clean direct 1080p URL with Microsoft parameters
		var clean_url: String = "https://images-eds-ssl.xboxlive.com/image?url=%s&format=png&w=1080&h=1080" % image_id
		
		print("Extracted Gamerpic ID: ", image_id)
		print("Direct High-Res CDN URL: ", clean_url)
		return clean_url
		
	print("Failed to locate Gamerpic ID in HTML")
	return ""


## Downloads image payload from [param url] and applies it to [member gamerpic].
func _download_gamerpic(url: String) -> void:
	var img_http := HTTPRequest.new()
	add_child(img_http)
	
	img_http.request_completed.connect(func(_r: int, code: int, _h: PackedStringArray, body: PackedByteArray):
		if code == 200 and body.size() > 0:
			var img := Image.new()
			# Try WebP (weserv.nl proxy default), then PNG, then JPEG
			var err: Error = img.load_webp_from_buffer(body)
			if err != OK: err = img.load_png_from_buffer(body)
			if err != OK: err = img.load_jpg_from_buffer(body)
				
			if err == OK:
				var tex := ImageTexture.create_from_image(img)
				gamerpic.texture = tex
				gamerpic.show()
				create_account_Button.show()
				create_account_Button.text = "Yes, i am " + current_gamertag
			else:
				print("Failed to decode Gamerpic image buffer: ", err)
				_enable_custom_upload()
		else:
			_enable_custom_upload()
			
		img_http.queue_free()
	)
	
	img_http.request(url)


## Requests legacy 3D Xbox Live avatar headshot from Microsoft servers.
## Falls back to size "l" if size [param size] fails[span_3](start_span)[span_3](end_span).
func load_avatar_face(size: String = "xl") -> void:
	var gt: String = current_gamertag.to_lower()
	var url: String = "https://avatar-ssl.xboxlive.com/avatar/%s/avatarpic-%s.png" % [gt, size]
	var headers := PackedStringArray(["User-Agent: XboxLive/2.0"])
	http.request_completed.connect(_on_face_done.bind(size), CONNECT_ONE_SHOT)
	http.request(url, headers)


## Callback executed when Microsoft avatar download completes.
func _on_face_done(_r: int, code: int, _h: PackedStringArray, body: PackedByteArray, size: String) -> void:
	var tex: Texture2D = null
	
	if code == 200 and body.size() > 1000:
		var img := Image.new()
		var err: Error = img.load_png_from_buffer(body)
		if err == OK:
			tex = ImageTexture.create_from_image(img)
			print("Avatar loaded as PNG (", body.size(), " bytes)")
		else:
			err = img.load_jpg_from_buffer(body)
			if err == OK:
				tex = ImageTexture.create_from_image(img)
				print("Avatar loaded as JPEG (", body.size(), " bytes)")
			else:
				print("Failed to parse avatar image — error: ", err)
	
	if tex == null and size == "xl":
		print("XL failed — trying L size")
		load_avatar_face("l")
		return
	
	gamerpic.texture = tex
	
	if tex != null and tex.get_size() >= Vector2(32.0, 32.0):
		create_account_Button.show()
		create_account_Button.text = "Yes, i am " + current_gamertag
	else:
		_enable_custom_upload()


## Switches UI state to allow user to pick a local custom profile image[span_4](start_span)[span_4](end_span).
func _enable_custom_upload() -> void:
	pick_icon_button.disabled = false
	gamerpic.hide()
	$RecoveryGuide.show()
	Title.text = "No picture found for " + current_gamertag
	pick_icon_button.icon = icon_tex


## Opens native or Godot FileDialog to select a custom local image[span_5](start_span)[span_5](end_span).
func _on_pick_icon_pressed() -> void:
	var dialog := FileDialog.new()
	dialog.title = "Choose Custom Gamerpic"
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters = ["*.png,*.jpg ; Images"]
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	
	if OS.get_name() == "Android":
		dialog.use_native_dialog = true
	
	dialog.file_selected.connect(func(path: String):
		var img := Image.new()
		var err: Error = img.load(path)
		if err == OK:
			icon_tex = ImageTexture.create_from_image(img)
			pick_icon_button.icon = icon_tex
			gamerpic.texture = icon_tex
			gamerpic.show()
			print("Custom icon loaded: ", path)
			create_account_Button.show()
			create_account_Button.text = "Yes, i am " + current_gamertag
		else:
			print("Failed to load custom icon: ", err)
	)
	
	add_child(dialog)
	dialog.popup_centered(Vector2(800, 600))


## Saves created account profile data to AccountManager and transitions scenes[span_6](start_span)[span_6](end_span).
func _on_create_account_pressed() -> void:
	var GTag: String = gamerinput.text.strip_edges()
	var gs: int = current_gamerscore
	var gp: Texture2D = gamerpic.texture if gamerpic.texture else pick_icon_button.icon
	
	if GTag.is_empty() or gp == null:
		return
	
	$Select.play()
	var new_index: int = AccountManager.profiles.size()
	AccountManager.add_profile(GTag, GTag, gs, false, [], gp, null)
	AccountManager.select_profile(new_index)
	ScreenManager.is_restricted = false
	await $Select.finished
	if ScreenManager.curr_screen != "Set-Up":
		get_tree().change_scene_to_file("res://scenes/log_in.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/log_in.tscn")


## Handles input navigation (e.g., Back action)[span_7](start_span)[span_7](end_span).
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Back") and ScreenManager.is_restricted != true:
		if ScreenManager.curr_screen != "Set-Up":
			ScreenManager.last_screen = "CreateAcc"
			ScreenManager.curr_screen = "log-in"
			$Back.play()
			await $Back.finished
			get_tree().change_scene_to_file("res://scenes/log_in.tscn")


## LineEdit signal callback for when Gamertag search input is submitted[span_8](start_span)[span_8](end_span).
func _on_GamerTag_Recieved_LineEdit(new_text: String) -> void:
	current_gamertag = new_text
	print("Looking For " + current_gamertag)
	fetch_fresh_data()
