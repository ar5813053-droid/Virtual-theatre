extends Control
## 2D media controls for the tablet — reliable on Android touch and desktop mouse.
## Controls the single VideoManager instance (cinema screen + audio).

signal close_requested
signal open_url_requested

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var status_label: Label = $Panel/VBox/StatusLabel
@onready var play_btn: Button = $Panel/VBox/Transport/PlayPause
@onready var back_btn: Button = $Panel/VBox/Transport/Rewind
@onready var fwd_btn: Button = $Panel/VBox/Transport/Forward
@onready var restart_btn: Button = $Panel/VBox/Transport/Restart
@onready var mute_btn: Button = $Panel/VBox/VolRow/Mute
@onready var vol_slider: HSlider = $Panel/VBox/VolRow/Volume
@onready var seek_slider: HSlider = $Panel/VBox/SeekSlider
@onready var time_label: Label = $Panel/VBox/TimeLabel
@onready var url_btn: Button = $Panel/VBox/Actions/OpenURL
@onready var close_btn: Button = $Panel/VBox/Actions/Close

var _vm: Node
var _updating_seek: bool = false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if play_btn:
		play_btn.pressed.connect(_on_play_pause)
	if back_btn:
		back_btn.pressed.connect(func(): _call_vm("seek_relative", [-10.0]))
	if fwd_btn:
		fwd_btn.pressed.connect(func(): _call_vm("seek_relative", [10.0]))
	if restart_btn:
		restart_btn.pressed.connect(func(): _call_vm("restart", []))
	if mute_btn:
		mute_btn.pressed.connect(func(): _call_vm("toggle_mute", []))
	if vol_slider:
		vol_slider.min_value = 0.0
		vol_slider.max_value = 1.0
		vol_slider.step = 0.05
		vol_slider.value_changed.connect(_on_volume)
	if seek_slider:
		seek_slider.min_value = 0.0
		seek_slider.max_value = 1.0
		seek_slider.step = 0.001
		seek_slider.drag_ended.connect(_on_seek_drag_ended)
	if url_btn:
		url_btn.pressed.connect(func(): open_url_requested.emit())
	if close_btn:
		close_btn.pressed.connect(func(): close_requested.emit())


func bind_video_manager(vm: Node) -> void:
	if _vm == vm:
		return
	_disconnect_vm()
	_vm = vm
	if not _vm:
		return
	if _vm.has_signal("state_changed"):
		_vm.state_changed.connect(_on_state)
	if _vm.has_signal("time_changed"):
		_vm.time_changed.connect(_on_time)
	if _vm.has_signal("volume_changed"):
		_vm.volume_changed.connect(_on_vol_signal)
	if _vm.has_signal("error_message"):
		_vm.error_message.connect(func(m): _set_status(m, true))
	if _vm.has_signal("info_message"):
		_vm.info_message.connect(func(m): _set_status(m, false))
	if _vm.has_signal("media_loaded"):
		_vm.media_loaded.connect(func(u): _set_title(u))
	refresh()


func _disconnect_vm() -> void:
	# Signals use CONNECT_ONE_SHOT style avoidance — just leave if freed
	_vm = null


func refresh() -> void:
	if not _vm:
		_set_title("No video")
		_set_status("Load a direct .ogv URL to play on the cinema screen.")
		return
	var url: String = str(_vm.get("current_url") if _vm.get("current_url") != null else "")
	var title: String = str(_vm.get("current_title") if _vm.get("current_title") != null else url)
	_set_title(title if not title.is_empty() else "No video loaded")
	var st = _vm.get("state")
	_on_state(_state_name(st))
	var vol = _vm.get("volume_linear")
	if vol != null and vol_slider:
		vol_slider.value = float(vol)


func _state_name(st) -> String:
	if st == null:
		return "idle"
	match int(st):
		0: return "idle"
		1: return "loading"
		2: return "playing"
		3: return "paused"
		4: return "error"
		_: return str(st)


func _on_state(s: String) -> void:
	if play_btn:
		play_btn.text = "Pause" if s == "playing" else "Play"
	if status_label and s in ["idle", "loading", "playing", "paused"]:
		_set_status(s.capitalize())


func _on_time(pos: float, dur: float) -> void:
	if time_label:
		time_label.text = "%s / %s" % [_fmt(pos), _fmt(dur) if dur > 0.0 else "--:--"]
	if seek_slider and not _updating_seek and dur > 0.0:
		_updating_seek = true
		seek_slider.max_value = dur
		seek_slider.value = pos
		_updating_seek = false
	elif seek_slider and dur <= 0.0:
		# Unknown duration — disable precise scrubbing visual
		seek_slider.max_value = 1.0
		seek_slider.value = 0.0


func _on_vol_signal(v: float) -> void:
	if vol_slider and absf(vol_slider.value - v) > 0.01:
		vol_slider.value = v


func _on_play_pause() -> void:
	_call_vm("toggle_play_pause", [])


func _on_volume(v: float) -> void:
	_call_vm("set_volume_linear", [v])


func _on_seek_drag_ended(changed: bool) -> void:
	if not changed or not seek_slider:
		return
	_call_vm("seek_to", [seek_slider.value])


func _call_vm(method: String, args: Array) -> void:
	if _vm and _vm.has_method(method):
		_vm.callv(method, args)


func _set_title(t: String) -> void:
	if title_label:
		title_label.text = t if t.length() < 48 else t.substr(0, 45) + "…"


func _set_status(t: String, is_err: bool = false) -> void:
	if status_label:
		status_label.text = t
		status_label.modulate = Color(1.0, 0.5, 0.45) if is_err else Color(0.8, 0.9, 0.85)


func _fmt(sec: float) -> String:
	var s := int(sec)
	var m := s / 60
	s = s % 60
	return "%d:%02d" % [m, s]
