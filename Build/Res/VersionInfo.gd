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
class_name VersionInfo extends Resource

@export_group("External Links")
@export var website_link: String
@export var itch_link: String
@export var discord_link: String
@export var support_link: String = "https://www.patreon.com/10610068/join"

@export_group("About")
@export_multiline() var copyright_text: String
@export_subgroup("Q & A")
@export_multiline() var questions_and_answers: String
@export_subgroup("Authors")
@export var project_founder: StringName
@export var lead_developer: StringName
@export var developers: Array[String]
@export_subgroup("License")
@export_multiline() var license: String
@export_subgroup("Third-party Licenses")
@export_multiline() var thirdparty_licenses: String

@export_group("Version")
@export var version_name: StringName = "1.0.0.alpha"
@export var version_banner: Texture2D = preload("res://Asset/Images/banner-mid.jpg")
@export var banner_owner: StringName = "Erik Karits"
@export var banner_owner_link: String = "https://www.pexels.com/@erik-karits-2093459/"
