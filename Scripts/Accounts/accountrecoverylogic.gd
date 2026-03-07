## Handles gamertag recovery for the Xbox launcher.
##
## Fetches gamerscore and avatar from xboxgamertag.com.
## Supports retries, User-Agent rotation, PNG/JPEG fallback, and custom icon upload.
## Saves the profile with fetched or custom data when user confirms.
extends Control

var LinkAvatarFullBody = "https://avatar-ssl.xboxlive.com/avatar/Gamertag/avatar-body.png"
var LinkAvatarIcon = "https://avatar-ssl.xboxlive.com/avatar/Gamertag/avatarpic-l.png"

@onready var gamerinput: LineEdit = $Gamerinput
@onready var gamerscore_label: Label = $GamerScoreLabel
@onready var gamerpic: TextureRect = $Gamerpic
@onready var Title: Label = $BG/Label
@onready var create_account_Button: Button = $CreateAccount
@onready var pick_icon_button: Button = $PickIconButton

var icon_tex: Texture2D = null
var http: HTTPRequest = HTTPRequest.new()
var current_gamertag: String = ""
var current_gamerscore: int = 0

func _ready() -> void:
	add_child(http)
	if not gamerinput:
		printerr("No Gamertag LineEdit!!")
	
	# Connect custom icon button
	pick_icon_button.pressed.connect(_on_pick_icon_pressed)

# ── Recovery Logic ──
func fetch_fresh_data() -> void:
	var url = "https://xboxgamertag.com/search/" + current_gamertag
	
	# Rotate User-Agents to avoid blocks
	var user_agents = [
		"XboxLive/2.0",
		"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
		"Mozilla/5.0 (Xbox; Xbox One) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
	]
	var ua = user_agents[randi() % user_agents.size()]
	
	var headers := PackedStringArray([
		"User-Agent: " + ua,
		"Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
		"Accept-Language: en-US,en;q=0.5",
		"Referer: https://xboxgamertag.com/"
	])
	
	var attempts = 0
	var max_attempts = 3
	var success = false
	
	http.timeout = 10  # Prevent hanging forever
	
	while attempts < max_attempts and not success:
		var error = http.request(url, headers)
		if error != OK:
			print("Request setup failed: ", error)
			attempts += 1
			await get_tree().create_timer(2.0).timeout
			continue
		
		var response = await http.request_completed
		var response_code = response[1]
		var body = response[3]
		
		if response_code == 200:
			success = true
			var html = body.get_string_from_utf8()
			var gs = _extract_gamerscore(html)
			gamerscore_label.text = str(gs)
			current_gamerscore = gs
			load_avatar_face("xl")
			print("Loaded Profile! GS: ", gs)
		else:
			print("Retry ", attempts + 1, "/", max_attempts, " — Code: ", response_code)
			attempts += 1
			await get_tree().create_timer(2.0).timeout
	
	if not success:
		gamerscore_label.text = "Error (Max retries reached)"
		Title.text = "Not Found!"

# ── Gamerscore extraction ──
func _extract_gamerscore(html: String) -> int:
	var gs := 0
	
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

# ── Avatar loading with fallback ──
func load_avatar_face(size: String = "xl") -> void:
	var gt = current_gamertag.to_lower()
	var url = "https://avatar-ssl.xboxlive.com/avatar/%s/avatarpic-%s.png" % [gt, size]
	var headers = PackedStringArray(["User-Agent: XboxLive/2.0"])
	http.request_completed.connect(_on_face_done.bind(size), CONNECT_ONE_SHOT)
	http.request(url, headers)

func _on_face_done(_r: int, code: int, _h: PackedStringArray, body: PackedByteArray, size: String) -> void:
	var tex: Texture2D = null
	
	if code == 200 and body.size() > 1000:
		var img = Image.new()
		var err = img.load_png_from_buffer(body)
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

func _enable_custom_upload() -> void:
	$PickIconButton.disabled = false
	$Gamerpic.hide()
	$RecoveryGuide.show()
	Title.text = "No avatar found for " + current_gamertag
	$PickIconButton.icon = icon_tex

# ── Custom icon picker ──
func _on_pick_icon_pressed() -> void:
	var dialog = FileDialog.new()
	dialog.title = "Choose Custom Gamerpic"
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters = ["*.png,*.jpg ; Images"]
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	
	if OS.get_name() == "Android":
		dialog.use_native_dialog = true
	
	dialog.file_selected.connect(func(path: String):
		var img = Image.new()
		var err = img.load(path)
		if err == OK:
			icon_tex = ImageTexture.create_from_image(img)
			$PickIconButton.icon = icon_tex
			$Gamerpic.texture = icon_tex
			$Gamerpic.show()
			print("Custom icon loaded: ", path)
			$CreateAccount.show()
			$CreateAccount.text = "Yes, i Am " + current_gamertag
		else:
			print("Failed to load custom icon: ", err)
	)
	
	add_child(dialog)
	dialog.popup_centered(Vector2(800, 600))

# ── Create profile ──
func _on_create_account_pressed() -> void:
	var GTag = gamerinput.text.strip_edges()
	var gs = current_gamerscore
	var gp = $Gamerpic.texture if $Gamerpic.texture else $PickIconButton.icon
	
	if GTag.is_empty() or gp == null:
		return
	
	$Select.play()
	var new_index = AccountManager.profiles.size()
	AccountManager.add_profile(GTag, GTag, gs, false, [], gp, null)
	AccountManager.select_profile(new_index)
	await $Select.finished
	if ScreenManager.curr_screen != "Set-Up":
		get_tree().change_scene_to_file("res://scenes/log_in.tscn")
	else:
		pass

# ── Input handling ──
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Back"):
		if ScreenManager.curr_screen != "Set-Up":
			ScreenManager.last_screen = "CreateAcc"
			ScreenManager.curr_screen = "log-in"
			$Back.play()
			await $Back.finished
			get_tree().change_scene_to_file("res://scenes/log_in.tscn")

func _on_GamerTag_Recieved_LineEdit(new_text: String) -> void:
	current_gamertag = new_text
	print("Looking For " + current_gamertag)
	fetch_fresh_data()
