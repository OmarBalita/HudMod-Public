#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
##  This program is free software: you can redistribute it and/or modify   ##
##  it under the terms of the GNU General Public License as published by   ##
##  the Free Software Foundation, either version 3 of the License, or      ##
##  (at your option) any later version.                                    ##
##                                                                         ##
##  This program is distributed in the hope that it will be useful,        ##
##  but WITHOUT ANY WARRANTY; without even the implied warranty of         ##
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the           ##
##  GNU General Public License for more details.                           ##
##                                                                         ##
##  You should have received a copy of the GNU General Public License      ##
##  along with this program. If not, see <https://www.gnu.org/licenses/>.  ##
#############################################################################
class_name GeometryHelper extends Object

static func find_closest_two_points(polygon_a: PackedVector2Array, polygon_b: PackedVector2Array) -> Vector2i:
	var result: Vector2i
	var min_dist: float = INF
	
	for ia: int in polygon_a.size():
		var pa: Vector2 = polygon_a[ia]
		for ib: int in polygon_b.size():
			var pb: Vector2 = polygon_b[ib]
			var dist: float = pa.distance_to(pb)
			if dist < min_dist:
				result = Vector2i(ia, ib)
				min_dist = dist
	
	return result
