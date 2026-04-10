extends Node2D

@onready var hot_valve: Node2D = $HotValve
@onready var cold_valve: Node2D = $ColdValve

@onready var hot_sprite: Sprite2D = $HotValve/Sprite2D
@onready var cold_sprite: Sprite2D = $ColdValve/Sprite2D

@onready var hot_area: Area2D = $HotValve/Area2D
@onready var cold_area: Area2D = $ColdValve/Area2D

@onready var shower_system: ShowerSystem = $ShowerSystem
@onready var water_audio: AudioStreamPlayer = $AudioStreamPlayer

@onready var ui_root: Control = get_node_or_null("CanvasLayer/UIRoot") as Control
@onready var steam_overlay: ColorRect = get_node_or_null("CanvasLayer/UIRoot/SteamOverlay") as ColorRect
@onready var bubble_label: Label = get_node_or_null("CanvasLayer/UIRoot/SteamOverlay/BubbleLabel") as Label

@onready var debug_panel: Control = get_node_or_null("CanvasLayer/UIRoot/DebugPanel") as Control
@onready var selected_label: Label = get_node_or_null("CanvasLayer/UIRoot/DebugPanel/SelectedLabel") as Label
@onready var temp_label: Label = get_node_or_null("CanvasLayer/UIRoot/DebugPanel/TempLabel") as Label
@onready var flow_label: Label = get_node_or_null("CanvasLayer/UIRoot/DebugPanel/FlowLabel") as Label
@onready var hint_label: Label = get_node_or_null("CanvasLayer/UIRoot/DebugPanel/HintLabel") as Label
@onready var progress_bar: ProgressBar = get_node_or_null("CanvasLayer/UIRoot/DebugPanel/ProgressBar") as ProgressBar

var selected_valve: String = "hot"
var finished: bool = false
var bubble_change_timer: float = 0.0

# 阀门旋转范围。方向不对就把两边数值对调
const HOT_MIN_ROT: float = -95.0
const HOT_MAX_ROT: float = 35.0
const COLD_MIN_ROT: float = 95.0
const COLD_MAX_ROT: float = -35.0

func _ready() -> void:
	_check_required_nodes()
	_setup_ui_layout()
	_setup_ui_mouse_behavior()

	hot_area.input_pickable = true
	cold_area.input_pickable = true

	hot_area.input_event.connect(_on_hot_area_input_event)
	cold_area.input_event.connect(_on_cold_area_input_event)

	shower_system.output_changed.connect(_on_output_changed)
	shower_system.shower_ready.connect(_on_shower_ready)

	selected_label.text = "当前选择：热阀门"
	temp_label.text = "水温：20.0°C"
	flow_label.text = "水量：0.00"
	hint_label.text = "点击左右阀门选择，再按 ← / → 调节"
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0

	steam_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	bubble_label.text = "点左边或右边阀门"

	_update_selected_visual()
	_update_valve_rotation()

	if water_audio.stream != null and not water_audio.playing:
		water_audio.play()

func _check_required_nodes() -> void:
	assert(hot_area != null, "没找到 HotValve/Area2D")
	assert(cold_area != null, "没找到 ColdValve/Area2D")
	assert(shower_system != null, "没找到 ShowerSystem")
	assert(ui_root != null, "没找到 CanvasLayer/UIRoot")
	assert(steam_overlay != null, "没找到 CanvasLayer/UIRoot/SteamOverlay")
	assert(bubble_label != null, "没找到 CanvasLayer/UIRoot/SteamOverlay/BubbleLabel")
	assert(debug_panel != null, "没找到 CanvasLayer/UIRoot/DebugPanel")
	assert(selected_label != null, "没找到 CanvasLayer/UIRoot/DebugPanel/SelectedLabel")
	assert(temp_label != null, "没找到 CanvasLayer/UIRoot/DebugPanel/TempLabel")
	assert(flow_label != null, "没找到 CanvasLayer/UIRoot/DebugPanel/FlowLabel")
	assert(hint_label != null, "没找到 CanvasLayer/UIRoot/DebugPanel/HintLabel")
	assert(progress_bar != null, "没找到 CanvasLayer/UIRoot/DebugPanel/ProgressBar")

func _setup_ui_layout() -> void:
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.offset_left = 0.0
	ui_root.offset_top = 0.0
	ui_root.offset_right = 0.0
	ui_root.offset_bottom = 0.0

	steam_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	steam_overlay.offset_left = 0.0
	steam_overlay.offset_top = 0.0
	steam_overlay.offset_right = 0.0
	steam_overlay.offset_bottom = 0.0

	# 漫画气泡文字：中上位置
	bubble_label.position = Vector2(430.0, 90.0)
	bubble_label.size = Vector2(420.0, 70.0)
	bubble_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# 左上角调试面板
	debug_panel.position = Vector2(20.0, 20.0)
	debug_panel.size = Vector2(300.0, 210.0)

	selected_label.position = Vector2(16.0, 16.0)
	selected_label.size = Vector2(260.0, 24.0)

	temp_label.position = Vector2(16.0, 46.0)
	temp_label.size = Vector2(260.0, 24.0)

	flow_label.position = Vector2(16.0, 76.0)
	flow_label.size = Vector2(260.0, 24.0)

	hint_label.position = Vector2(16.0, 106.0)
	hint_label.size = Vector2(260.0, 40.0)

	progress_bar.position = Vector2(16.0, 160.0)
	progress_bar.size = Vector2(260.0, 22.0)

func _setup_ui_mouse_behavior() -> void:
	# UI 不准挡鼠标，不然点不到阀门
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	steam_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	debug_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selected_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	temp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if finished:
		return

	var dir: float = Input.get_axis("ui_left", "ui_right")

	if absf(dir) > 0.01:
		if selected_valve == "hot":
			shower_system.hot_valve_open += dir * delta * 0.6
			shower_system.hot_valve_open = clampf(shower_system.hot_valve_open, 0.0, 1.0)
		else:
			shower_system.cold_valve_open += dir * delta * 0.6
			shower_system.cold_valve_open = clampf(shower_system.cold_valve_open, 0.0, 1.0)

	_update_valve_rotation()

	bubble_change_timer -= delta

func _on_hot_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			selected_valve = "hot"
			selected_label.text = "当前选择：热阀门"
			bubble_label.text = "正在调热水"
			_update_selected_visual()

func _on_cold_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			selected_valve = "cold"
			selected_label.text = "当前选择：冷阀门"
			bubble_label.text = "正在调冷水"
			_update_selected_visual()

func _on_output_changed(temp: float, flow: float, progress: float) -> void:
	temp_label.text = "水温：%.1f°C" % temp
	flow_label.text = "水量：%.2f" % flow
	progress_bar.value = progress * 100.0

	_update_bubble_text(temp, flow)
	_update_steam(temp, flow)
	_update_water_audio(flow)

func _update_bubble_text(temp: float, flow: float) -> void:
	if bubble_change_timer > 0.0:
		return

	bubble_label.text = get_feedback_text(temp, flow)
	bubble_change_timer = 0.15

func get_feedback_text(temp: float, flow: float) -> String:
	if flow < 0.05:
		return "还没出水……"

	if temp > 43.0:
		return "水太烫了"
	if temp < 34.0:
		return "水太凉了"

	if flow < 0.45:
		return "水有点小"
	if flow > 1.00:
		return "水太大了"

	if temp >= 38.0 and temp <= 41.0 and flow >= 0.65 and flow <= 0.95:
		return "差不多了……"

	return "再调一下……"

func _update_steam(temp: float, flow: float) -> void:
	var target_alpha: float = 0.0

	if temp > 40.0 and flow > 0.3:
		target_alpha = clampf((temp - 40.0) / 12.0, 0.0, 0.35) * clampf(flow, 0.0, 1.0)

	var c: Color = steam_overlay.color
	c.a = lerpf(c.a, target_alpha, 0.08)
	steam_overlay.color = c

func _update_water_audio(flow: float) -> void:
	if water_audio.stream == null:
		return

	if flow <= 0.02:
		water_audio.volume_db = -40.0
	else:
		var flow01: float = clampf(flow, 0.0, 1.0)
		water_audio.volume_db = lerpf(-24.0, -6.0, flow01)
		water_audio.pitch_scale = lerpf(0.9, 1.05, flow01)

func _update_selected_visual() -> void:
	if selected_valve == "hot":
		hot_sprite.scale = Vector2(1.08, 1.08)
		cold_sprite.scale = Vector2(1.0, 1.0)
		hot_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		cold_sprite.modulate = Color(0.85, 0.85, 0.85, 1.0)
	else:
		cold_sprite.scale = Vector2(1.08, 1.08)
		hot_sprite.scale = Vector2(1.0, 1.0)
		cold_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		hot_sprite.modulate = Color(0.85, 0.85, 0.85, 1.0)

func _update_valve_rotation() -> void:
	hot_valve.rotation_degrees = lerpf(HOT_MIN_ROT, HOT_MAX_ROT, shower_system.hot_valve_open)
	cold_valve.rotation_degrees = lerpf(COLD_MIN_ROT, COLD_MAX_ROT, shower_system.cold_valve_open)

func _on_shower_ready() -> void:
	finished = true
	bubble_label.text = "好了，就这个水温。"
	hint_label.text = "已调节完成。"
