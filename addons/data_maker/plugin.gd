@tool
extends EditorPlugin

const _MainPanel = preload("res://addons/data_maker/ui/main_panel.gd")

var _panel: Control

const CONFIG_PATH = "user://data_maker.cfg"

func _enter_tree() -> void:
	_panel = _MainPanel.new()
	_panel.name = "DataMakerPanel"
	get_editor_interface().get_editor_main_screen().add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.visible = false

	var cfg = ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		var p = cfg.get_value("editor", "last_project_path", "")
		if p != "" and DirAccess.dir_exists_absolute(p):
			_panel.call_deferred("restore_project", p)

func _exit_tree() -> void:
	if is_instance_valid(_panel):
		var cfg = ConfigFile.new()
		cfg.set_value("editor", "last_project_path", _panel.get_project_root())
		cfg.save(CONFIG_PATH)
		_panel.free_dialogs()
		_panel.queue_free()
		_panel = null

func _has_main_screen() -> bool:
	return true

func _make_visible(visible: bool) -> void:
	if is_instance_valid(_panel):
		_panel.visible = visible

func _get_plugin_name() -> String:
	return "Data Maker"

func _get_plugin_icon() -> Texture2D:
	return get_editor_interface().get_base_control().get_theme_icon("ResourcePreloader", "EditorIcons")

func _shortcut_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.ctrl_pressed and event.keycode == KEY_S:
			if is_instance_valid(_panel) and _panel.visible:
				_panel.save_dirty_files()
			get_viewport().set_input_as_handled()
