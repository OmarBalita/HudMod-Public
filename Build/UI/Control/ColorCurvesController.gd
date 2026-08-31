class_name ColorCurvesController extends MarginContainer

const HUE_CURVES_FOR_EXPORT: Array[StringName] = [&"hue_vs_hue", &"hue_vs_sat", &"hue_vs_lum"]
const LUM_CURVES_FOR_EXPORT: Array[StringName] = [&"lum_vs_sat"]
const SAT_CURVES_FOR_EXPORT: Array[StringName] = [&"sat_vs_sat", &"sat_vs_lum"]
const CURVES_FOR_EXPORT: Array[StringName] = HUE_CURVES_FOR_EXPORT + LUM_CURVES_FOR_EXPORT + SAT_CURVES_FOR_EXPORT

@export var color_curves: CompColorCurves

@onready var body: MarginContainer
@onready var bg_texture_rect: TextureRect
@onready var curve_controller: CurveController

var curr_curve_key: StringName
var curr_curve_profile: CurveProfile

func get_color_curves() -> CompColorCurves: return color_curves
func set_color_curves(new_val: CompColorCurves) -> void: color_curves = new_val

func _ready() -> void:
	
	var box_cont: BoxContainer = IS.create_box_container(8, true)
	
	#region curve_buttons
	var btns_scroll_cont: ScrollContainer = IS.create_scroll_container(3, 0)
	var btns_cont: BoxContainer = IS.create_box_container(8)
	
	IS.expand(btns_scroll_cont, true)
	
	var button_group:= ButtonGroup.new()
	
	for curve_key: StringName in CURVES_FOR_EXPORT:
		var str_curve_key: String = String(curve_key).capitalize()
		
		var curve_btn: Button = IS.create_button(str_curve_key, null, str_curve_key, false, true)
		curve_btn.button_group = button_group
		curve_btn.toggle_mode = true
		
		curve_btn.pressed.connect(_on_curve_btn_pressed.bind(curve_key))
		
		btns_cont.add_child(curve_btn)
	#endregion
	
	#region body
	body = IS.create_margin_container(0, 0)
	IS.expand(body, true, true)
	#endregion
	
	btns_scroll_cont.add_child(btns_cont)
	box_cont.add_child(btns_scroll_cont)
	box_cont.add_child(body)
	add_child(box_cont)
	
	open_curve_profile(CURVES_FOR_EXPORT[0])
	(btns_cont.get_child(0) as Button).button_pressed = true


func open_curve_profile(curve_key: StringName) -> void:
	if curve_key == curr_curve_key: return
	
	var curve_profile: CurveProfile = color_curves.get_prop(curve_key)
	
	if bg_texture_rect: bg_texture_rect.queue_free()
	if curve_controller: curve_controller.queue_free()
	bg_texture_rect = IS.create_texture_rect(null, {})
	curve_controller = curve_profile._create_curve_controller()
	
	if HUE_CURVES_FOR_EXPORT.has(curve_key):
		bg_texture_rect.texture = preload("res://Asset/rainbow_map_bar.png")
		bg_texture_rect.modulate.v = .4
	else:
		bg_texture_rect.texture = preload("res://Asset/luminance_map_bar.png")
		bg_texture_rect.modulate.v = .8
	
	body.add_child(bg_texture_rect)
	body.add_child(curve_controller)
	
	IS.set_base_panel_settings(curve_controller, IS.style_box_empty)
	
	IS.expand(bg_texture_rect, true, true)
	IS.expand(curve_controller, true, true)
	
	curr_curve_key = curve_key
	curr_curve_profile = curve_profile


func _on_curve_btn_pressed(curve_key: StringName) -> void:
	open_curve_profile(curve_key)












