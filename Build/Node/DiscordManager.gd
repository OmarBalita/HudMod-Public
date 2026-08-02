class_name DiscordManager extends Node

func _ready():
	ProjectServer2.project_opened.connect(_on_project_server2_project_opened)

	DiscordRPC.app_id = 1533525933808423082 # Application ID
	DiscordRPC.state = "Editing."
	DiscordRPC.large_image = "hudmod9"
	DiscordRPC.large_image_text = "HudMod Hoopoes!"
	
	DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system()) # "02:46 elapsed"
	# DiscordRPC.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00:00 remaining"
	
	DiscordRPC.refresh() # Always refresh after changing the values!

func  _process(_delta) -> void:
	DiscordRPC.run_callbacks()

func _on_project_server2_project_opened(project_res: ProjectRes) -> void:
	DiscordRPC.details = project_res.project_name
	DiscordRPC.refresh()
