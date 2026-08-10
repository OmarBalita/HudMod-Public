class_name DiscordManager extends Node

static var _enabled: bool = ClassDB.class_exists(&"DiscordRPC")

func _ready():
	ProjectServer2.project_opened.connect(_on_project_server2_project_opened)
	if not _enabled:
		return
	
	DiscordRPC.set_app_id(1533525933808423082) # Application ID
	DiscordRPC.set_state("Develops." if OS.is_debug_build() else "Editing.")
	DiscordRPC.set_large_image("hudmod9")
	DiscordRPC.set_large_image_text("HudMod Hoopoes!")
	
	DiscordRPC.set_start_timestamp(int(Time.get_unix_time_from_system())) # "02:46 elapsed"
	# DiscordRPC.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00:00 remaining"
	
	DiscordRPC.refresh() # Always refresh after changing the values!

func  _process(_delta) -> void:
	if _enabled:
		DiscordRPC.run_callbacks()

func _on_project_server2_project_opened(project_res: ProjectRes) -> void:
	if not _enabled:
		return
	DiscordRPC.set_details(project_res.project_name)
	DiscordRPC.refresh()

