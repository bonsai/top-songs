extends Control
class_name DotMatrix

signal text_changed(new_text: String)

enum FontMode { AUTO, FONT_5X7, PIXELIX_3X5, JSON_16X16 }

var display_text := "":
	set(v):
		if v != display_text:
			display_text = v
			_columns = _render_text_to_columns(v)
			_scroll_pos = 0.0
			text_changed.emit(v)
			queue_redraw()

var color := Color.GREEN:
	set(v):
		color = v
		queue_redraw()
var dot_size := 3
var glow := 2
var speed := 3
var font_mode := FontMode.AUTO

var json_font_loaded := false

var _columns: Array[PackedByteArray] = []
var _scroll_pos := 0.0
var _num_view_cols := 20
var _step := 20.0
var _pad := 24.0
var _dot_r := 6.0
var _nr := 21
var _hue := 0.0

var _font_5x7: Dictionary = {}
var _font_pixelix: Dictionary = {}
var _font_json: Dictionary = {}
var _font_json_w := 16
var _font_json_h := 16

var _digits := [
	[" ### ","#   #","#  ##","# # #","##  #","#   #"," ### "],
	["  #  "," ##  ","  #  ","  #  ","  #  ","  #  "," ### "],
	[" ### ","#   #","    #","  ## "," #   ","#    ","#####"],
	[" ### ","#   #","    #","  ## ","    #","#   #"," ### "],
	["   # ","  ## "," # # ","#  # ","#####","   # ","   # "],
	["#####","#    ","#### ","    #","#   #","#   #"," ### "],
	["  ## "," #   ","#    ","#### ","#   #","#   #"," ### "],
	["#####","#   #","   # ","  #  ","  #  ","  #  ","  #  "],
	[" ### ","#   #","#   #"," ### ","#   #","#   #"," ### "],
	[" ### ","#   #","#   #"," ####","    #","   # "," ### "],
]

func _ready() -> void:
	custom_minimum_size = Vector2(200, 100)
	_load_builtin_fonts()
	_load_json_font()

func _load_builtin_fonts() -> void:
	# ASCII uppercase
	var ascii := {
		"A": [" ### ","#   #","#   #","#####","#   #","#   #","#   #"],
		"B": ["#### ","#   #","#   #","#### ","#   #","#   #","#### "],
		"C": [" ### ","#   #","#    ","#    ","#    ","#   #"," ### "],
		"D": ["#### ","#   #","#   #","#   #","#   #","#   #","#### "],
		"E": ["#####","#    ","#    ","#### ","#    ","#    ","#####"],
		"F": ["#####","#    ","#    ","#### ","#    ","#    ","#    "],
		"G": [" ### ","#   #","#    ","# ###","#   #","#   #"," ### "],
		"H": ["#   #","#   #","#   #","#####","#   #","#   #","#   #"],
		"I": ["#####","  #  ","  #  ","  #  ","  #  ","  #  ","#####"],
		"J": ["#####","    #","    #","    #","#   #","#   #"," ### "],
		"K": ["#   #","#  # ","# #  ","##   ","# #  ","#  # ","#   #"],
		"L": ["#    ","#    ","#    ","#    ","#    ","#    ","#####"],
		"M": ["#   #","## ##","# # #","#   #","#   #","#   #","#   #"],
		"N": ["#   #","##  #","# # #","#  ##","#   #","#   #","#   #"],
		"O": [" ### ","#   #","#   #","#   #","#   #","#   #"," ### "],
		"P": ["#### ","#   #","#   #","#### ","#    ","#    ","#    "],
		"Q": [" ### ","#   #","#   #","#   #","# # #","#  # "," ## #"],
		"R": ["#### ","#   #","#   #","#### ","# #  ","#  # ","#   #"],
		"S": [" ### ","#   #","#    "," ### ","    #","#   #"," ### "],
		"T": ["#####","  #  ","  #  ","  #  ","  #  ","  #  ","  #  "],
		"U": ["#   #","#   #","#   #","#   #","#   #","#   #"," ### "],
		"V": ["#   #","#   #","#   #","#   #"," # # "," # # ","  #  "],
		"W": ["#   #","#   #","#   #","#   #","# # #","## ##"," ### "],
		"X": ["#   #","#   #"," # # ","  #  "," # # ","#   #","#   #"],
		"Y": ["#   #","#   #"," # # ","  #  ","  #  ","  #  ","  #  "],
		"Z": ["#####","    #","   # ","  #  "," #   ","#    ","#####"],
	}
	for ch in ascii.keys():
		_font_5x7[ch] = ascii[ch]
	var space := ["     ","     ","     ","     ","     ","     ","     "]
	_font_5x7[" "] = space

func _load_json_font() -> void:
	var file := FileAccess.open("res://data/kanji-sample.json", FileAccess.READ)
	if not file:
		push_warning("JSON font not found at res://data/kanji-sample.json")
		return
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("JSON font parse error: ", json.get_error_message())
		return
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY or not data.has("glyphs"):
		push_error("Invalid JSON font format")
		return
	var glyphs: Dictionary = data["glyphs"]
	for ch in glyphs.keys():
		var hex_rows: Array = glyphs[ch]
		var dot_rows: PackedStringArray = []
		for hex_row in hex_rows:
			var s := ""
			for c in hex_row:
				s += "#" if c == "1" else " "
			dot_rows.append(s)
		_font_json[ch] = dot_rows
	json_font_loaded = true
	print("JSON font loaded: ", _font_json.size(), " glyphs")

func _has_cjk(text: String) -> bool:
	for i in text.length():
		var unicode := text.unicode_at(i)
		if (unicode >= 0x3000 and unicode <= 0x9FFF) or (unicode >= 0xF900 and unicode <= 0xFAFF):
			return true
	return false

func _render_text_to_columns(text: String) -> Array[PackedByteArray]:
	if text.is_empty():
		return []
	var f := dot_size
	_step = 14 + (f - 1) * 6
	_dot_r = 4 + (f - 1) * 2.0
	var rows_of_bools: Array[PackedByteArray] = []
	match font_mode:
		FontMode.JSON_16X16:
			rows_of_bools = _render_json(text, f)
		FontMode.FONT_5X7:
			rows_of_bools = _render_5x7(text, f)
		FontMode.PIXELIX_3X5:
			rows_of_bools = _render_pixelix(text, f)
		FontMode.AUTO:
			if _has_cjk(text) and json_font_loaded:
				rows_of_bools = _render_json(text, f)
			else:
				rows_of_bools = _render_5x7(text, f)
	_nr = rows_of_bools.size()
	if _nr == 0:
		return []
	var num_cols := 0
	for row in rows_of_bools:
		num_cols = max(num_cols, row.size())
	var columns: Array[PackedByteArray] = []
	for col_idx in range(num_cols):
		var col := PackedByteArray()
		for row_idx in range(_nr):
			var val := 1 if col_idx < rows_of_bools[row_idx].size() and rows_of_bools[row_idx][col_idx] > 0 else 0
			col.append(val)
		columns.append(col)
	return columns

func _render_5x7(text: String, scale: int) -> Array[PackedByteArray]:
	var h := 7 * scale
	var rows: Array[PackedByteArray] = []
	for i in range(h):
		rows.append(PackedByteArray())
	for i in text.length():
		var ch := text[i]
		var pattern: PackedStringArray = _font_5x7.get(ch, _font_5x7.get(ch.to_upper(), _font_5x7.get(ch.to_lower(), _font_5x7.get(" ", []))))
		if pattern.is_empty():
			pattern = _font_5x7[" "]
		for r in range(h):
			var src_idx := floor(float(r) / scale)
			var src := pattern[src_idx] if src_idx < pattern.size() else "     "
			for c in range(5 * scale):
				var src_c := floor(float(c) / scale)
				rows[r].append(1 if (src[src_c] if src_c < src.length() else " ") != " " else 0)
	return rows

func _render_pixelix(text: String, scale: int) -> Array[PackedByteArray]:
	var h := 5 * scale
	var rows: Array[PackedByteArray] = []
	for i in range(h):
		rows.append(PackedByteArray())
	for i in text.length():
		var ch := text[i]
		var pattern: Array = _font_pixelix.get(ch, [])
		if pattern.is_empty():
			for r in range(h):
				for c in range(3 * scale):
					rows[r].append(0)
			continue
		for r in range(h):
			var src_idx := floor(float(r) / scale)
			var src: String = pattern[min(src_idx, pattern.size() - 1)] if not pattern.is_empty() else "   "
			for c in range(3 * scale):
				var src_c := floor(float(c) / scale)
				rows[r].append(1 if src_c < src.length() and src[src_c] == "#" else 0)
	return rows

func _render_json(text: String, scale: int) -> Array[PackedByteArray]:
	var h := _font_json_h * scale
	var w := _font_json_w * scale
	var rows: Array[PackedByteArray] = []
	for i in range(h):
		rows.append(PackedByteArray())
	for i in text.length():
		var ch := text[i]
		var pattern: Array = _font_json.get(ch, [])
		if pattern.is_empty():
			for r in range(h):
				for c in range(w):
					rows[r].append(0)
			continue
		for r in range(h):
			var src_idx := floor(float(r) / scale)
			var src: String = pattern[src_idx] if src_idx < pattern.size() else ""
			for c in range(w):
				var src_c := floor(float(c) / scale)
				rows[r].append(1 if src_c < src.length() and src[src_c] == "#" else 0)
	return rows

func _get_speed_val() -> float:
	var speeds := [0.25, 0.5, 1.0, 1.5, 2.5]
	return speeds[clamp(speed - 1, 0, 4)]

func _get_glow_radius() -> float:
	var glows := [0.0, 4.0, 8.0 + 4.0 * dot_size, 16.0 + 8.0 * dot_size]
	return glows[clamp(glow, 0, 3)]

func _draw() -> void:
	var size := get_size()
	if _columns.is_empty():
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(10, size.y / 2), "LED BOARD", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.DIM_GRAY)
		return
	var gap := _num_view_cols
	var total := _columns.size() + gap
	_scroll_pos = fmod(_scroll_pos + _get_speed_val(), float(total))
	var base := floor(_scroll_pos)
	var actual_color := color
	if actual_color == Color.WHITE:
		_hue = fmod(_hue + 2.0, 360.0)
		actual_color = Color.from_hsv(_hue / 360.0, 1.0, 1.0)
	var cw := size.x
	var ch := size.y
	var start_x := (cw - _num_view_cols * _step) / 2.0 + _dot_r
	var start_y := (ch - _nr * _step) / 2.0 + _dot_r
	for ci in range(_num_view_cols):
		var idx := int(base) + ci
		var col_data := _columns[idx] if idx < _columns.size() else PackedByteArray()
		var x := start_x + ci * _step
		for ri in range(_nr):
			var on := col_data[ri] > 0 if ri < col_data.size() else false
			var y := start_y + ri * _step
			if on:
				var blur := _get_glow_radius()
				if blur > 0.0:
					draw_circle(Vector2(x, y), _dot_r + blur * 0.5, Color(actual_color.r, actual_color.g, actual_color.b, 0.15))
				draw_circle(Vector2(x, y), _dot_r, actual_color)
				draw_circle(Vector2(x - 1, y - 1), _dot_r * 0.35, Color(1, 1, 1, 0.35))
			else:
				draw_circle(Vector2(x, y), _dot_r, Color(0.15, 0.15, 0.15, 0.85))

func _process(delta: float) -> void:
	if not _columns.is_empty():
		queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_recalc_layout()

func _recalc_layout() -> void:
	var size := get_size()
	var f := dot_size
	_step = 14 + (f - 1) * 6 + 4
	_pad = 16 + (f - 1) * 8
	_num_view_cols = max(4, int((size.x - _pad * 2) / _step))
	_dot_r = 4 + (f - 1) * 2.0

func connect_to_api(url: String) -> void:
	var timer := Timer.new()
	timer.wait_time = 3.0
	timer.timeout.connect(_fetch_message.bind(url))
	add_child(timer)
	timer.start()

func _fetch_message(url: String) -> void:
	if url.is_empty():
		return
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_message_fetched.bind(http, url))
	http.request(url)

func _on_message_fetched(result: int, code: int, headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest, url: String) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var json := JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.data
			if typeof(data) == TYPE_DICTIONARY and data.has("message"):
				var msg: String = data["message"]
				if not msg.is_empty():
					display_text = msg
	http.queue_free()
