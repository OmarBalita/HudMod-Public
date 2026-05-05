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
extends Node

func describe(what: Object, description: Dictionary) -> void:
	for d: String in description:
		what.set(d, description.get(d))

func describe_node_deep(node: Node, description: Dictionary) -> void:
	describe(node, description)
	for child_node: Node in node.get_children():
		describe_node_deep(child_node, description)

func call_method_deep(node: Node, method_name: StringName, args: Array) -> void:
	node.call(method_name, args)
	for child_node: Node in node.get_children():
		call_method_deep(child_node, method_name, args)

func copy_properties(from: Object, to_objects: Array[Object], do_not_copy: Array[StringName]) -> void:
	for prop: Dictionary in from.get_property_list():
		var name = prop.name
		if name in do_not_copy:
			continue
		for to: Object in to_objects:
			to.set(name, from.get(name))
