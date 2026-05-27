extends Control

# LED Board メインコントローラー

@onready var dot_matrix = $DotMatrix
@onready var settings_panel: Control = $SettingsPanel
@onready var color_slider: HSlider = $SettingsPanel/Margin/VBox/ColorRow/HSlider
@onready var size_slider: HSlider = $SettingsPanel/Margin/VBox/SizeRow/HSlider
@onready var glow_slider: HSlider = $SettingsPanel/Margin/VBox/GlowRow/HSlider
@onready var speed_slider: HSlider = $SettingsPanel/Margin/VBox/SpeedRow/HSlider
@onready var status_label: Label = $SettingsPanel/Margin/VBox/StatusRow/StatusValue
@onready var message_input: LineEdit = $SettingsPanel/Margin/VBox/InputRow/LineEdit
@onready var toggle_btn: Button = $ToggleBtn
@onready var demo_timer: Timer = $DemoTimer

const DEMO_TEXT := "蔵前ドープネス"
const API_URL := "http://localhost:8080/api/message"
const COLORS := [
	Color("#ff0041"), Color("#ff2020"), Color("#ff4400"), Color("#ff6600"),
	Color("#ff8800"), Color("#ffaa00"), Color("#ffcc00"), Color("#ffdd00"),
	Color("#ffff41"), Color("#aaff00"), Color("#55ff00"), Color("#00ff41"),
	Color("#00ff88"), Color("#00ffcc"), Color("#00ffff"), Color("#41ffff"),
	Color("#0088ff"), Color("#0041ff"), Color("#4400ff"), Color("#8800ff"),
	Color("#aa00ff"), Color("#ff41ff"), Color("#ff00aa"), Color("#ff0066"),
	Color("#ff69b4"), Color("#a020f0"), Color("#ffffff"),
]
const RAINBOW_IDX := 27
var _color_idx := 11

var _settings_visible := true

func _ready() -> void:
	# フォント関連設定
	dot_matrix.font_mode = 0  # AUTO
	dot_matrix.dot_size = 3
	dot_matrix.glow = 2
	dot_matrix.speed = 3
	dot_matrix.color = COLORS[_color_idx]

	# 接続
	dot_matrix.connect_to_api(API_URL)

	# シグナル
	dot_matrix.text_changed.connect(_on_text_changed)

	# 設定パネル初期値
	color_slider.value = _color_idx
	size_slider.value = dot_matrix.dot_size
	glow_slider.value = dot_matrix.glow
	speed_slider.value = dot_matrix.speed

	# デモタイマー
	demo_timer.timeout.connect(_start_demo)
	demo_timer.start(15.0)

	# キーボード
	message_input.text_submitted.connect(_on_message_submitted)

	# トグル
	toggle_btn.pressed.connect(_toggle_settings)

func _on_text_changed(new_text: String) -> void:
	demo_timer.stop()
	status_label.text = new_text
	# 文字が来たらデモリセットタイマー再スタート
	demo_timer.start(30.0)

func _start_demo() -> void:
	dot_matrix.display_text = DEMO_TEXT
	status_label.text = "DEMO: " + DEMO_TEXT

func _on_message_submitted(text: String) -> void:
	if text.is_empty():
		return
	# APIにPOST
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_post_done.bind(http, text))
	http.request(API_URL, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.new().stringify({"text": text}))
	message_input.clear()

func _on_post_done(result: int, code: int, headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest, sent_text: String) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		dot_matrix.display_text = sent_text
		status_label.text = sent_text
	http.queue_free()

func _on_send_pressed() -> void:
	_on_message_submitted(message_input.text)

func _toggle_settings() -> void:
	_settings_visible = not _settings_visible
	settings_panel.visible = _settings_visible
	toggle_btn.text = "≫" if _settings_visible else "≪"

# ── 設定変更 ──
func _on_color_changed(value: float) -> void:
	_color_idx = int(value)
	if _color_idx >= COLORS.size():
		dot_matrix.color = Color.WHITE  # rainbow
	else:
		dot_matrix.color = COLORS[_color_idx]

func _on_size_changed(value: float) -> void:
	dot_matrix.dot_size = int(value)

func _on_glow_changed(value: float) -> void:
	dot_matrix.glow = int(value)

func _on_speed_changed(value: float) -> void:
	dot_matrix.speed = int(value)

func _on_font_mode_selected(index: int) -> void:
	dot_matrix.font_mode = index

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # Escape
		_toggle_settings()
	if event.is_action_pressed("ui_accept") and not message_input.has_focus():
		_start_demo()

func _exit_tree() -> void:
	pass
