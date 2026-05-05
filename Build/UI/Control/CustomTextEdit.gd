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
class_name CustomTextEdit extends TextEdit

func get_selection_from_index() -> int:
	return line_col_to_index(
		get_selection_from_line(),
		get_selection_from_column()
	)

func get_selection_to_index() -> int:
	return line_col_to_index(
		get_selection_to_line(),
		get_selection_to_column()
	)

func line_col_to_index(line: int, col: int) -> int:
	var index: int
	for line_index: int in line:
		index += get_line(line_index).length() + 1
	return index + col
