extends Node

const GITHUB_REPO = "NexilFromNullFrame/XLaunch" 
const API_URL = "https://api.github.com/repos/" + GITHUB_REPO + "/releases/latest"

var latest_version: String = "0.0.0"  # fallback
var current_version: String = "0.0.8"  # hardcode current version

signal update_available(new_version: String, download_url: String)
signal no_update()
signal check_failed()

func _ready() -> void:
	if OS.has_feature("standalone"):
		check_for_update()

func check_for_update() -> void:
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_github_response)
	
	var error = http.request(API_URL, ["User-Agent: XLauncher"], HTTPClient.METHOD_GET)
	if error != OK:
		check_failed.emit()
		print("GitHub check failed: ", error)

func _on_github_response(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		check_failed.emit()
		print("GitHub API error: ", response_code)
		return
	
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null or not json is Dictionary:
		check_failed.emit()
		return
	
	var tag_name = json.get("tag_name", "0.0.0")
	latest_version = tag_name.lstrip("v")  # remove 'v' prefix if present
	
	if latest_version != current_version:
		var assets = json.get("assets", [])
		var download_url = ""
		for asset in assets:
			if asset.get("name", "").ends_with(".zip") or asset.get("name", "").ends_with(".exe"):
				download_url = asset.get("browser_download_url", "")
				break
		
		update_available.emit(latest_version, download_url)
	else:
		no_update.emit()
