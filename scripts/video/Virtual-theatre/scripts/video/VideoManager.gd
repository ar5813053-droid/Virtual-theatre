extends Node
## Authoritative video playback for the cinema screen.
## Supports direct media file URLs (primarily .ogv / Ogg Theora via VideoStreamTheora).
## Webpage / YouTube / Instagram / DRM streams are NOT supported — shows clear errors.

signal state_changed(state: String)
signal time_changed(position_sec: float, duration_sec: float)
signal volume_changed(linear: float)
signal error_message(msg: String)
signal info_message(msg: String)
signal media_loaded(url: String)

enum State { IDLE, LOADING, PLAYING, PAUSED, ERROR }

var state: State = State.IDLE
var current_url: String = ""
var current_title: String = ""
var volume_linear: float = 1.0
var is_muted: bool = false
var _volume_before_mute: float = 1.0

## Hidden player that owns the stream; texture is sampled for the 3D screen.
var _player: VideoStreamPlayer
var _http: HTTPRequest
var _cache_path: String = ""
var _duration_guess: float = 0.0
var _seek_supported: bool = false


func _ready() -> void:
	_player = VideoStreamPlayer.new()
	_player.name = "CinemaVideoPlayer"
	_player.visible = false
	_player.volume_db = 0.0
	add_child(_player)
	_player.finished.connect(_on_finished)

	_http = HTTPRequest.new()
	_http.name = "VideoHTTP"
	_http.timeout = 60.0
	_http.use_threads = true
	add_child(_http)
	_http.request_completed.connect(_on_http_completed)

	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if state == State.PLAYING or state == State.PAUSED:
		var pos := 0.0
		if _player and _player.stream:
			pos = _player.stream_position
		time_changed.emit(pos, _duration_guess)


func get_video_texture() -> Texture2D:
	if _player:
		return _player.get_video_texture()
	return null


func is_playing() -> bool:
	return state == State.PLAYING


func get_stream_position() -> float:
	if _player:
		return _player.stream_position
	return 0.0


func get_duration() -> float:
	return _duration_guess


func play_url(url: String) -> void:
	url = url.strip_edges()
	if url.is_empty():
		_set_error("Please enter a video URL.")
		return

	if not (url.begins_with("http://") or url.begins_with("https://") or url.begins_with("user://") or url.begins_with("res://")):
		_set_error("URL must start with http://, https://, or be a local path.")
		return

	# Reject obvious webpage / streaming-site patterns
	var lower := url.to_lower()
	if _looks_like_webpage(lower):
		_set_error("This looks like a webpage, not a direct video file.\nYouTube, Instagram, and similar sites are not supported.\nUse a direct link ending in .ogv (Ogg Theora).")
		return

	var ext := _extension_of(url)
	if ext not in ["ogv", "ogg"]:
		# Godot stock builds decode Ogg Theora (.ogv). Other formats need modules.
		_set_error("Unsupported format '.%s'.\nGodot's built-in player supports Ogg Theora (.ogv).\nMP4/WebM/YouTube need extra modules or external tools — not included." % ext)
		return

	_stop_internal(false)
	current_url = url
	current_title = url.get_file()
	if current_title.is_empty():
		current_title = url
	_set_state(State.LOADING)
	info_message.emit("Loading video…")

	if url.begins_with("res://") or url.begins_with("user://"):
		_load_local(url)
	else:
		_download_then_play(url)


func _looks_like_webpage(lower: String) -> bool:
	var hosts := ["youtube.com", "youtu.be", "instagram.com", "facebook.com", "vimeo.com/video", "tiktok.com", "twitter.com", "x.com"]
	for h in hosts:
		if h in lower:
			return true
	# watch?v= style
	if "watch?v=" in lower or "/shorts/" in lower:
		return true
	# No media extension and ends without file-like path
	var ext := _extension_of(lower)
	if ext.is_empty() and ("/watch" in lower or lower.ends_with(".html") or lower.ends_with(".htm") or lower.ends_with("/")):
		return true
	return false


func _extension_of(url: String) -> String:
	var path := url
	var q := path.find("?")
	if q >= 0:
		path = path.substr(0, q)
	var hash_i := path.find("#")
	if hash_i >= 0:
		path = path.substr(0, hash_i)
	return path.get_extension().to_lower()


func _download_then_play(url: String) -> void:
	_cache_path = "user://cinema_cache_%d.ogv" % Time.get_ticks_msec()
	var err := _http.request(url)
	if err != OK:
		_set_error("Could not start download (error %d)." % err)


func _on_http_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if state != State.LOADING:
		return
	if result != HTTPRequest.RESULT_SUCCESS:
		_set_error("Network error while downloading (result %d)." % result)
		return
	if response_code < 200 or response_code >= 300:
		_set_error("Server returned HTTP %d." % response_code)
		return
	if body.is_empty():
		_set_error("Downloaded file is empty.")
		return
	# Basic size guard for low-end devices (200 MB)
	if body.size() > 200 * 1024 * 1024:
		_set_error("File too large (>200 MB) for in-app cache on mobile.")
		return

	var f := FileAccess.open(_cache_path, FileAccess.WRITE)
	if not f:
		_set_error("Could not write cache file.")
		return
	f.store_buffer(body)
	f.close()
	_load_local(_cache_path)


func _load_local(path: String) -> void:
	var stream := VideoStreamTheora.new()
	stream.file = path
	_player.stream = stream
	_player.volume_db = linear_to_db(maxf(volume_linear, 0.0001)) if not is_muted else -80.0
	# VideoStreamTheora does not always expose duration; leave 0 if unknown
	_duration_guess = 0.0
	_seek_supported = true  # stream_position can be set; quality varies by file
	_player.play()
	_set_state(State.PLAYING)
	media_loaded.emit(current_url)
	info_message.emit("Playing: %s" % current_title)


func toggle_play_pause() -> void:
	if state == State.PLAYING:
		_player.paused = true
		_set_state(State.PAUSED)
	elif state == State.PAUSED:
		_player.paused = false
		_set_state(State.PLAYING)
	elif state == State.IDLE or state == State.ERROR:
		info_message.emit("Load a video first.")


func play() -> void:
	if state == State.PAUSED:
		_player.paused = false
		_set_state(State.PLAYING)
	elif state == State.PLAYING:
		pass
	else:
		info_message.emit("Load a video first.")


func pause() -> void:
	if state == State.PLAYING:
		_player.paused = true
		_set_state(State.PAUSED)


func stop() -> void:
	_stop_internal(true)


func _stop_internal(clear_url: bool) -> void:
	if _player:
		_player.stop()
		_player.stream = null
	if not _cache_path.is_empty() and FileAccess.file_exists(_cache_path):
		DirAccess.remove_absolute(_cache_path)
	_cache_path = ""
	_duration_guess = 0.0
	if clear_url:
		current_url = ""
		current_title = ""
	_set_state(State.IDLE)


func seek_to(seconds: float) -> void:
	if not _player or not _player.stream:
		return
	if not _seek_supported:
		info_message.emit("Seeking not available for this stream.")
		return
	_player.stream_position = maxf(0.0, seconds)


func seek_relative(delta_sec: float) -> void:
	seek_to(get_stream_position() + delta_sec)


func restart() -> void:
	seek_to(0.0)
	if state == State.PAUSED or state == State.PLAYING:
		_player.paused = false
		_player.play()
		_set_state(State.PLAYING)


func set_volume_linear(v: float) -> void:
	volume_linear = clampf(v, 0.0, 1.0)
	if not is_muted and _player:
		_player.volume_db = linear_to_db(maxf(volume_linear, 0.0001))
	volume_changed.emit(volume_linear)


func toggle_mute() -> void:
	is_muted = not is_muted
	if is_muted:
		_volume_before_mute = volume_linear
		if _player:
			_player.volume_db = -80.0
	else:
		if _player:
			_player.volume_db = linear_to_db(maxf(volume_linear, 0.0001))
	volume_changed.emit(0.0 if is_muted else volume_linear)


func _on_finished() -> void:
	_set_state(State.PAUSED)
	info_message.emit("Playback finished.")


func _set_state(s: State) -> void:
	state = s
	var names := {
		State.IDLE: "idle",
		State.LOADING: "loading",
		State.PLAYING: "playing",
		State.PAUSED: "paused",
		State.ERROR: "error",
	}
	state_changed.emit(names.get(s, "unknown"))


func _set_error(msg: String) -> void:
	_set_state(State.ERROR)
	error_message.emit(msg)
