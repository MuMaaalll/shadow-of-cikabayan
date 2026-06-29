extends Node
## ==========================================================================
## save_system.gd — HTTP Sync & Local Fallback Save System (Autoload)
## Shadow of Cikabayan | Godot 4.6
##
## Handles periodic auto-save and manual save/load of game state.
##
## ┌─────────────────────────────────────────────────────────────────┐
## │  SYNC FLOW                                                      │
## │                                                                  │
## │  Player moves → Timer (30s) → collect PlayerStats.to_dict()     │
## │       ↓                                                          │
## │  POST /api/game/save-state  ─── success ──► done                │
## │       │                                                          │
## │       └── fail (offline) ──► save to user://save_data.json      │
## │                                                                  │
## │  Game starts → GET /api/game/load-state → PlayerStats.from_dict │
## │       │                                                          │
## │       └── fail ──► load from user://save_data.json              │
## └─────────────────────────────────────────────────────────────────┘
##
## Register as Autoload in Project Settings:
##   SaveSystem = "res://src/core/save_system.gd"
## ==========================================================================

# ── Signals ────────────────────────────────────────────────────────────────

signal save_completed(success: bool)
signal load_completed(success: bool)

# ── Configuration ──────────────────────────────────────────────────────────

## Base URL of the Next.js API server. Change for production.
@export var api_base_url: String = "http://localhost:3000"

## Auto-save interval in seconds.
@export var auto_save_interval: float = 30.0

## Maximum retry attempts for HTTP requests.
@export var max_retries: int = 3

## Local save file path (fallback when offline).
const LOCAL_SAVE_PATH: String = "user://save_data.json"

# ── Node References ───────────────────────────────────────────────────────

var _http_save: HTTPRequest
var _http_load: HTTPRequest
var _auto_save_timer: Timer
var _retry_count: int = 0
var _is_saving: bool = false
var _is_loading: bool = false

# ── Lifecycle ──────────────────────────────────────────────────────────────

func _ready() -> void:
	# Create HTTPRequest nodes for save and load (separate to avoid conflicts)
	_http_save = HTTPRequest.new()
	_http_save.name = "HTTPSave"
	_http_save.request_completed.connect(_on_save_request_completed)
	add_child(_http_save)

	_http_load = HTTPRequest.new()
	_http_load.name = "HTTPLoad"
	_http_load.request_completed.connect(_on_load_request_completed)
	add_child(_http_load)

	# Create auto-save timer
	_auto_save_timer = Timer.new()
	_auto_save_timer.name = "AutoSaveTimer"
	_auto_save_timer.wait_time = auto_save_interval
	_auto_save_timer.autostart = true
	_auto_save_timer.timeout.connect(_on_auto_save_timeout)
	add_child(_auto_save_timer)

	print("[SaveSystem] Initialized. Auto-save every %.0fs." % auto_save_interval)

# ── Public API ─────────────────────────────────────────────────────────────

## Trigger a manual save (e.g., on map transition or interact with save point).
func save_game() -> void:
	if _is_saving:
		print("[SaveSystem] Save already in progress, skipping.")
		return
	_save_to_server()


## Trigger a manual load (e.g., on game start after auth).
func load_game() -> void:
	if _is_loading:
		print("[SaveSystem] Load already in progress, skipping.")
		return
	_load_from_server()


## Start the auto-save timer (called after player logs in).
func start_auto_save() -> void:
	_auto_save_timer.start()
	print("[SaveSystem] Auto-save started.")


## Stop the auto-save timer (e.g., during combat or cutscenes).
func stop_auto_save() -> void:
	_auto_save_timer.stop()
	print("[SaveSystem] Auto-save paused.")

# ── Auto-Save Timer ──────────────────────────────────────────────────────

func _on_auto_save_timeout() -> void:
	print("[SaveSystem] Auto-save triggered.")
	save_game()

# ── HTTP Save (POST) ─────────────────────────────────────────────────────
##
## Sends player state to the Next.js API:
##   POST {api_base_url}/api/game/save-state
##
## Request body (JSON):
## {
##   "session_token": "...",
##   "map_id": "kebun_cikabayan",
##   "x": 570.0,
##   "y": 321.0,
##   "direction": "down",
##   "hp": 100,
##   "sanity": 100,
##   "inventory": [ { "item_id": "reflective_mirror", "quantity": 2 } ],
##   "game_flags": { "boss_defeated_kuyang": true }
## }
##
## Response (JSON):
## { "success": true, "saved_at": "2026-06-29T06:55:00Z" }

func _save_to_server() -> void:
	_is_saving = true
	_retry_count = 0

	var stats = get_node_or_null("/root/PlayerStats")
	if not stats:
		push_warning("[SaveSystem] PlayerStats not found. Falling back to local save.")
		_save_locally()
		return

	var payload: Dictionary = stats.to_dict()
	var json_body: String = JSON.stringify(payload)

	var headers: PackedStringArray = PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer %s" % stats.session_token,
	])

	var url: String = api_base_url + "/api/game/save-state"
	print("[SaveSystem] POST %s" % url)

	var error := _http_save.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		push_warning("[SaveSystem] HTTP request failed to start (error: %d). Saving locally." % error)
		_save_locally()


func _on_save_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var response_text := body.get_string_from_utf8()
		var json := JSON.new()
		var parse_result := json.parse(response_text)

		if parse_result == OK:
			var data: Dictionary = json.data
			if data.get("success", false):
				print("[SaveSystem] ✓ Save successful at %s" % data.get("saved_at", "unknown"))
				_is_saving = false
				save_completed.emit(true)
				# Also save locally as backup
				_save_locally()
				return

	# Retry with exponential backoff
	_retry_count += 1
	if _retry_count < max_retries:
		var delay := pow(2, _retry_count)  # 2s, 4s, 8s
		print("[SaveSystem] Save failed (attempt %d/%d). Retrying in %.0fs..." % [_retry_count, max_retries, delay])
		await get_tree().create_timer(delay).timeout
		_is_saving = false
		_save_to_server()
	else:
		push_warning("[SaveSystem] Save failed after %d attempts. Saving locally." % max_retries)
		_save_locally()
		_is_saving = false
		save_completed.emit(false)

# ── HTTP Load (GET) ──────────────────────────────────────────────────────
##
## Loads player state from the Next.js API:
##   GET {api_base_url}/api/game/load-state
##
## Headers:
##   Authorization: Bearer {session_token}
##
## Response (JSON):
## {
##   "success": true,
##   "data": {
##     "map_id": "kebun_cikabayan",
##     "x": 570.0,
##     "y": 321.0,
##     "direction": "down",
##     ...
##   }
## }

func _load_from_server() -> void:
	_is_loading = true

	var stats = get_node_or_null("/root/PlayerStats")
	if not stats or stats.session_token.is_empty():
		push_warning("[SaveSystem] No session token. Loading from local save.")
		_load_locally()
		return

	var headers: PackedStringArray = PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer %s" % stats.session_token,
	])

	var url: String = api_base_url + "/api/game/load-state"
	print("[SaveSystem] GET %s" % url)

	var error := _http_load.request(url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		push_warning("[SaveSystem] HTTP load request failed (error: %d). Loading locally." % error)
		_load_locally()


func _on_load_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var response_text := body.get_string_from_utf8()
		var json := JSON.new()
		var parse_result := json.parse(response_text)

		if parse_result == OK:
			var response: Dictionary = json.data
			if response.get("success", false):
				var data: Dictionary = response.get("data", {})
				var stats = get_node_or_null("/root/PlayerStats")
				if stats:
					stats.from_dict(data)
					print("[SaveSystem] ✓ Game state loaded from server.")
					_is_loading = false
					load_completed.emit(true)
					return

	push_warning("[SaveSystem] Server load failed. Loading from local save.")
	_load_locally()
	_is_loading = false
	load_completed.emit(false)

# ── Local Save/Load Fallback ─────────────────────────────────────────────

## Saves player state to a local JSON file as offline fallback.
func _save_locally() -> void:
	var stats = get_node_or_null("/root/PlayerStats")
	if not stats:
		push_error("[SaveSystem] Cannot save locally — PlayerStats not found.")
		return

	var file := FileAccess.open(LOCAL_SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_str := JSON.stringify(stats.to_dict(), "\t")
		file.store_string(json_str)
		file.close()
		print("[SaveSystem] ✓ Local save written to %s" % LOCAL_SAVE_PATH)
	else:
		push_error("[SaveSystem] Failed to open %s for writing." % LOCAL_SAVE_PATH)


## Loads player state from a local JSON file.
func _load_locally() -> void:
	if not FileAccess.file_exists(LOCAL_SAVE_PATH):
		print("[SaveSystem] No local save found at %s. Using defaults." % LOCAL_SAVE_PATH)
		_is_loading = false
		load_completed.emit(false)
		return

	var file := FileAccess.open(LOCAL_SAVE_PATH, FileAccess.READ)
	if file:
		var content := file.get_as_text()
		file.close()

		var json := JSON.new()
		var parse_result := json.parse(content)

		if parse_result == OK:
			var data: Dictionary = json.data
			var stats = get_node_or_null("/root/PlayerStats")
			if stats:
				stats.from_dict(data)
				print("[SaveSystem] ✓ Game state loaded from local save.")
				_is_loading = false
				load_completed.emit(true)
				return

	push_error("[SaveSystem] Failed to parse local save file.")
	_is_loading = false
	load_completed.emit(false)
