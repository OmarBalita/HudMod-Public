#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
@abstract class_name Text2DComponentRes extends ComponentRes

func has_method_type() -> bool: return false

func _process(frame: int) -> void:
	var lines_data: Array[Text2DClipRes.LineData] = owner.lines_data
	var global_idx: int
	
	for line_idx: int in lines_data.size():
		var line_data: Text2DClipRes.LineData = lines_data[line_idx]
		var glyphs: Array[Dictionary] = line_data.glyphs
		var chars: Array[CharFXTransform] = line_data.chars
		for idx: int in glyphs.size():
			var glyph: Dictionary = glyphs[idx]
			var char: CharFXTransform = chars[idx]
			_process_char_fx(line_idx, line_data, idx, global_idx, glyph, char)
			global_idx += 1

func _process_char_fx(line_idx: int, line_data: Text2DClipRes.LineData, idx: int, global_idx: int, glyph: Dictionary, char: CharFXTransform) -> void:
	pass

func clear_predraw() -> void:
	owner.clear_predraw()

func submit_line_predraw(from: Vector2, to: Vector2, color: Color = Color.WHITE, width: int = -1, antialized: bool = false) -> int:
	return owner.add_line_predraw(from, to, color, width, antialized)

func submit_rect_predraw(rect: Rect2, color: Color = Color.WHITE, filled: bool = true, width: int = -1, antialized: bool = false) -> int:
	return owner.add_rect_predraw(rect, color, filled, width, antialized)

func submit_circle_predraw(position: Vector2, radius: float, color: Color = Color.WHITE, width: int = -1, antialized: bool = false) -> int:
	return owner.add_circle_predraw(position, radius, color, width, antialized)

func submit_polyline_predraw(points: PackedVector2Array, color: Color = Color.WHITE, width: int = -1, antialized: bool = false) -> int:
	return owner.add_polyline_predraw(points, color, width, antialized)

func submit_polygon_predraw(points: PackedVector2Array, colors:= PackedColorArray(), uvs:= PackedVector2Array(), texture: Texture2D = null) -> int:
	return owner.add_polygon_predraw(points, colors, uvs, texture)

func remove_predraw(idx: int) -> void:
	owner.remove_predraw(idx)

func clear_postdraw() -> void:
	owner.clear_postdraw()

func submit_line_postdraw(from: Vector2, to: Vector2, color: Color = Color.WHITE, width: int = -1, antialized: bool = false) -> int:
	return owner.add_line_postdraw(from, to, color, width, antialized)

func submit_rect_postdraw(rect: Rect2, color: Color = Color.WHITE, filled: bool = true, width: int = -1, antialized: bool = false) -> int:
	return owner.add_rect_postdraw(rect, color, filled, width, antialized)

func submit_circle_postdraw(position: Vector2, radius: float, color: Color = Color.WHITE, width: int = -1, antialized: bool = false) -> int:
	return owner.add_circle_postdraw(position, radius, color, width, antialized)

func submit_polyline_postdraw(points: PackedVector2Array, color: Color = Color.WHITE, width: int = -1, antialized: bool = false) -> int:
	return owner.add_polyline_postdraw(points, color, width, antialized)

func submit_polygon_postdraw(points: PackedVector2Array, colors:= PackedColorArray(), uvs:= PackedVector2Array(), texture: Texture2D = null) -> int:
	return owner.add_polygon_postdraw(points, colors, uvs, texture)

func remove_postdraw(idx: int) -> void:
	owner.remove_postdraw(idx)




