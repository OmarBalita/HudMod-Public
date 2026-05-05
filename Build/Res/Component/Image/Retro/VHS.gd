#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompCRT extends PassShaderComponentRes

#@export var overlay: bool = false
@export var pixelate: bool = true

@export_range(0.0, 1.0) var scanlines_opacity: float = 0.4
@export_range(0.0, 0.5) var scanlines_width: float = 0.25
@export_range(0.0, 1.0) var grille_opacity: float = 0.3
@export var resolution: Vector2 = Vector2(640.0, 480.0)

@export var roll: bool = true
@export var roll_speed: float = 8.0
@export_range(0.0, 100.0) var roll_size: float = 15.0
@export_range(0.1, 5.0) var roll_variation: float = 1.8
@export_range(0.0, 0.2) var distort_intensity: float = 0.05

@export_range(0.0, 1.0) var noise_opacity: float = 0.4
@export var noise_speed: float = 5.0
@export_range(0.0, 1.0) var static_noise_intensity: float = 0.06

@export_range(-1.0, 1.0) var aberration: float = 0.03
@export var brightness: float = 1.4
@export var discolor: bool = true

@export_range(0.0, 5.0) var warp_amount: float = 1.0
@export var clip_warp: bool = false

@export var vignette_intensity: float = 0.4
@export_range(0.0, 1.0) var vignette_opacity: float = 0.5


func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		#&"overlay": export(bool_args(overlay)),
		&"pixelate": export(bool_args(pixelate)),
		
		&"Scanlines & Grille": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"scanlines_opacity": export(float_args(scanlines_opacity, 0.0, 1.0)),
		&"scanlines_width": export(float_args(scanlines_width, 0.0, 0.5)),
		&"grille_opacity": export(float_args(grille_opacity, 0.0, 1.0)),
		&"resolution": export(vec2_args(resolution)),
		&"_Scanlines & Grille": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		
		&"Rolling": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"roll": export(bool_args(roll)),
		&"roll_speed": export(float_args(roll_speed)),
		&"roll_size": export(float_args(roll_size, 0.0, 100.0)),
		&"roll_variation": export(float_args(roll_variation, 0.1, 5.0)),
		&"distort_intensity": export(float_args(distort_intensity, 0.0, 0.2)),
		&"_Rolling": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		
		&"Noise": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"noise_opacity": export(float_args(noise_opacity, 0.0, 1.0)),
		&"noise_speed": export(float_args(noise_speed)),
		&"static_noise_intensity": export(float_args(static_noise_intensity, 0.0, 1.0)),
		&"_Noise": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		
		&"Color & Image": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"aberration": export(float_args(aberration, -1.0, 1.0)),
		&"brightness": export(float_args(brightness)),
		&"discolor": export(bool_args(discolor)),
		&"_Color & Image": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		
		&"Warp": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"warp_amount": export(float_args(warp_amount, 0.0, 5.0)),
		&"clip_warp": export(bool_args(clip_warp)),
		&"_Warp": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		
		&"Vignette": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"vignette_intensity": export(float_args(vignette_intensity)),
		&"vignette_opacity": export(float_args(vignette_opacity, 0.0, 1.0)),
		&"_Vignette": export_method(ExportMethodType.METHOD_EXIT_CATEGORY)
	}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/VHS.gdshader")

func _process(frame: int) -> void:
	set_shader_props({
		&"time": float(frame),
		
		#&"overlay": overlay,
		&"pixelate": pixelate,
		
		&"scanlines_opacity": scanlines_opacity,
		&"scanlines_width": scanlines_width,
		&"grille_opacity": grille_opacity,
		&"resolution": resolution,
		
		&"roll": roll,
		&"roll_speed": roll_speed,
		&"roll_size": roll_size,
		&"roll_variation": roll_variation,
		&"distort_intensity": distort_intensity,
		
		&"noise_opacity": noise_opacity,
		&"noise_speed": noise_speed,
		&"static_noise_intensity": static_noise_intensity,
		
		&"aberration": aberration,
		&"brightness": brightness,
		&"discolor": discolor,
		
		&"warp_amount": warp_amount,
		&"clip_warp": clip_warp,
		
		&"vignette_intensity": vignette_intensity,
		&"vignette_opacity": vignette_opacity
	})
