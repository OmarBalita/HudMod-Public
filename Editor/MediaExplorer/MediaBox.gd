class_name MediaBox extends Container

var categories: Dictionary[String, Category]

var media_explorer: MediaExplorer

var body_container: BoxContainer

var options_container: BoxContainer
var scroll_container: ScrollContainer
var media_select_cont: MediaSelectContainer = _init_media_select_cont()
var media_categories_box: BoxContainer

var search_line: LineEdit

# Current filter and sort
var curr_filter: int
var curr_sort: int

func _init(_media_explorer: MediaExplorer) -> void:
	media_explorer = _media_explorer

func _ready() -> void:
	
	body_container = IS.create_box_container(10, true)
	options_container = IS.create_box_container(8)
	scroll_container = IS.create_scroll_container(1,1, {size_flags_vertical = Control.PRESET_FULL_RECT})
	var margin_container: MarginContainer = IS.create_margin_container(12, 12, 12, 12)
	
	media_categories_box = IS.create_box_container(12, true, {})
	media_categories_box.gui_input.connect(_on_media_categories_box_gui_input)
	
	IS.expand(margin_container, true, true)
	IS.expand(media_categories_box, true, true)
	body_container.clip_contents = false
	media_categories_box.clip_contents = false
	
	margin_container.add_child(media_select_cont)
	margin_container.add_child(media_categories_box)
	scroll_container.add_child(margin_container)
	body_container.add_child(options_container)
	body_container.add_child(scroll_container)
	
	add_child(body_container)
	
	_ready_options()

func _init_media_select_cont() -> MediaSelectContainer:
	return MediaSelectContainer.new(self)

func _on_media_categories_box_gui_input(event: InputEvent) -> void:
	
	if MediaExplorer.focused_cards:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			media_select_cont.deselect_all()
			EditorServer.properties._clear_controls()




func _ready_options() -> void:
	search_line = IS.create_line_edit("Search for Media", "", media_explorer.texture_search)
	search_line.text_changed.connect(on_search_line_text_changed)
	options_container.add_child(search_line)

func add_category(category_name: StringName, has_header: bool = true, accent_color: Color = Color.BLACK) -> Category:
	var category: Category = IS.create_category(has_header, category_name, accent_color, media_explorer.card_display_size)
	category.has_custom_color = false
	media_categories_box.add_child(category)
	categories[category_name] = category
	return category

func get_category(category_name: StringName) -> Category:
	return categories.get(category_name)

func remove_category(category_name: StringName) -> void:
	categories.get(category_name).queue_free()
	categories.erase(category_name)


func register_categories_content_to_select_container() -> void:
	
	var cats_keys: Array[String] = categories.keys()
	var cats_vals: Array[Category] = categories.values()
	
	for cat_idx: int in cats_keys.size():
		
		var cat_name: StringName = cats_keys[cat_idx]
		var cat: Category = cats_vals[cat_idx]
		
		var contents: Array[Node] = cat.get_contents()
		
		var port: Dictionary
		
		for idx: int in contents.size():
			port[idx] = contents[idx]
		
		media_select_cont.add_selectable_port(cat_idx, port)

func update_select_container() -> void:
	media_select_cont.clear_selectable_ports()
	register_categories_content_to_select_container()

func update_cards_selection() -> void:
	
	var cat_keys: Array[String] = categories.keys()
	
	for cat_idx: int in cat_keys.size():
		var cat_key: String = cat_keys[cat_idx]
		var cat: Category = categories[cat_key]
		var cards: Array[Node] = cat.get_contents()
		
		var port: Dictionary = media_select_cont.selected[cat_idx] if media_select_cont.selected.has(cat_idx) else {}
		
		for idx: int in cards.size():
			var card: MediaCard = cards[idx]
			card.update_selection(port.has(idx))


func filter_and_sort() -> void:
	
	var search_query: String = search_line.text.strip_edges().to_lower()
	var filter_func: Callable = _get_filter_func()
	var sort_func: Callable = _get_sort_func()
	
	for cat_name: StringName in categories:
		
		var category: Category = categories[cat_name]
		var cat_sorted_cards:= category.get_contents()
		cat_sorted_cards.sort_custom(sort_func)
		
		for index: int in cat_sorted_cards.size():
			var card: MediaCard = cat_sorted_cards[index]
			var is_finded: bool = StringHelper.fuzzy_search(search_query, card.display_name.to_lower())
			card.visible = filter_func.call(card) and (search_query.is_empty() or is_finded)
			category.move_content(card, index)

func on_search_line_text_changed(new_text: String) -> void:
	filter_and_sort()

func _get_filter_options() -> Array[Dictionary]:
	return []

func _get_filter_func() -> Callable:
	return func(card: MediaCard) -> bool: return true

func _get_sort_options() -> Array[Dictionary]:
	return [
		{text = "Name"},
		{text = "Type"},
		{text = "Latest to Earliest"},
		{text = "Earliest to Latest"},
	]

func _get_sort_func() -> Callable:
	match curr_sort:
		0:
			return func(a: MediaCard, b: MediaCard) -> bool:
				return a.display_name.to_lower() < b.display_name.to_lower()
		1:
			return func(a: MediaCard, b: MediaCard) -> bool:
				if a.created_card_type == b.created_card_type:
					return a.create_date > b.create_date
				return a.created_card_type < b.created_card_type
		2:
			return func(a: MediaCard, b: MediaCard) -> bool: return a.create_date > b.create_date
		3:
			return func(a: MediaCard, b: MediaCard) -> bool: return a.create_date < b.create_date
		_:
			return Callable()


class MediaSelectContainer extends SelectContainer:
	
	var media_box: MediaBox
	
	func _init(_media_box: MediaBox) -> void:
		media_box = _media_box
		
		IS.set_base_panel_settings(self, IS.style_transparent)
		
		control_enable_delete = false
		control_enable_past = false
	
	func _ready() -> void:
		super()
		shortcut_node.key = &"Explorer"
		shortcut_node.cond_func = func() -> bool:
			return media_box.scroll_container.get_global_rect().has_point(get_global_mouse_position())
		shortcut_node.load_shortcuts_from_settings()
	
	func emit_focused_changed(old_focused: Vector2i, new_focused: Vector2i) -> void:
		super(old_focused, new_focused)
		var cats: Array[Category] = media_box.categories.values()
		
		if has_selectable_val(old_focused.x, old_focused.y):
			
			var latest_clip: MediaCard = cats[old_focused.x].content_container.get_child(old_focused.y)
			if latest_clip: latest_clip.select_panel.modulate.a = .7
			EditorServer.properties._clear_controls()
		
		var new_clip: MediaCard = cats[new_focused.x].content_container.get_child(new_focused.y)
		if new_clip: new_clip.select_panel.modulate.a = 1.
		
		if new_clip is ImportBox.ImportCard and not new_clip.disabled:
			EditorServer.properties.update_media_properties(MediaServer.get_imported_file_info(new_clip.path_or_name, new_clip.type))
	
	func emit_selected_changed() -> void:
		super()
		media_box.update_cards_selection()



class MediaCard extends PanelContainer:
	
	static var add_texture: Texture2D = preload("res://Asset/Icons/plus.png")
	
	static var double_click_threshold: float = .3
	
	@onready var name_label: Label
	@onready var add_button: TextureButton
	@onready var thumbnail_texture_rect: TextureRect
	@onready var select_panel: SelectPanel = SelectPanel.new(self)
	
	@export var display_name: StringName = &"Media Card"
	@export var display_texture: Texture2D = IS.TEXTURE_X_MARK:
		set(val):
			if not val:
				val = IS.TEXTURE_X_MARK
			display_texture = val
	@export var disabled: bool
	
	var media_box: MediaBox
	
	var selection_port: int
	
	func _init(_media_box: MediaBox, port: int) -> void:
		media_box = _media_box
		selection_port = port
		IS.set_base_panel_settings(self, IS.style_panel)
	
	func _ready() -> void:
		
		add_child(select_panel)
		
		name_label = IS.create_label(display_name)
		add_button = IS.create_texture_button(add_texture)
		thumbnail_texture_rect = IS.create_texture_rect(display_texture, {})
		
		var margin_container: MarginContainer = IS.create_margin_container()
		var split_container: SplitContainer = IS.create_split_container(2, true)
		var split_container2: SplitContainer = IS.create_split_container()
		
		IS.add_children(split_container2, [add_button, name_label])
		IS.add_children(split_container, [thumbnail_texture_rect, split_container2])
		
		margin_container.add_child(split_container)
		
		add_child(margin_container)
		
		name_label.set_text_overrun_behavior(TextServer.OVERRUN_TRIM_ELLIPSIS)
		
		thumbnail_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumbnail_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		IS.expand(thumbnail_texture_rect, true, true)
		
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
		add_button.pressed.connect(_on_add_button_pressed)
	
	func _gui_input(event: InputEvent) -> void:
		
		if event is InputEventMouseButton:
			
			if event.is_pressed():
				
				if event.button_index == MOUSE_BUTTON_LEFT:
					var curr_time: float = Time.get_ticks_msec() / 1000.
					if curr_time - get_meta(&"latest_time", .0) < double_click_threshold:
						_activate()
					set_meta(&"latest_time", curr_time)
			
			else:
				
				match event.button_index:
					MOUSE_BUTTON_LEFT:
						_select(event.alt_pressed, not event.ctrl_pressed)
					MOUSE_BUTTON_RIGHT:
						_select(event.alt_pressed, not event.ctrl_pressed)
						popup_context_menu()
	
	func _select(delete: bool, preclear: bool) -> void:
		media_box.media_select_cont.manage_val(selection_port, get_index(), delete, preclear)
		media_box.media_select_cont.emit_selected_changed()
	
	func _activate() -> void:
		add_media_ress(0, PlaybackServer.position)
	
	func popup_context_menu() -> void:
		var options: Array[Dictionary] = _get_context_menu_options()
		
		var context_menu: PopupMenu = IS.create_popup_menu(options)
		
		context_menu.always_on_top = true
		var popup_pos:= Vector2i(get_global_mouse_position()) + get_window().position
		
		get_tree().get_current_scene().add_child(context_menu)
		context_menu.popup(Rect2i(popup_pos, Vector2i.ZERO))
		context_menu.id_pressed.connect(_on_context_menu_id_pressed)
		context_menu.popup_hide.connect(context_menu.queue_free)
	
	func _get_context_menu_options() -> Array[Dictionary]:
		return []
	
	
	func update_selection(selection: bool) -> void:
		select_panel.visible = selection
	
	func get_media_ress() -> Array[MediaClipRes]:
		return []
	
	func add_media_ress(layer_index: int, frame_in: int, auto_init: bool = true) -> void:
		
		if disabled:
			return
		
		var media_ress: Array[MediaClipRes] = get_media_ress()
		
		for clip_res: MediaClipRes in media_ress:
			if auto_init and clip_res is Display2DClipRes:
				clip_res.add_component(&"Display2D", CompCanvasItem.new(), true)
		
		ProjectServer2.opened_clip_res_path.back().add_clips(layer_index, frame_in, media_ress, EditorServer.time_line2.overlay_menu.focus_index)
	
	func _on_mouse_entered() -> void:
		MediaExplorer.focused_cards.append(self)
	
	func _on_mouse_exited() -> void:
		MediaExplorer.focused_cards.erase(self)
	
	func _on_add_button_pressed() -> void:
		add_media_ress(0, PlaybackServer.position)
	
	func _on_context_menu_id_pressed(id: int) -> void:
		pass
	
	
	class SelectPanel extends Panel:
		
		const STYLE_SELECTED: StyleBoxFlat = preload("uid://kkroptu2c0c1")
		
		@export var owner_as_media_card: MediaCard
		
		func _init(_owner_as_media_card: MediaCard) -> void:
			owner_as_media_card = _owner_as_media_card
			IS.set_base_panel_settings(self, STYLE_SELECTED)
			modulate.a = .7
			visible = false





