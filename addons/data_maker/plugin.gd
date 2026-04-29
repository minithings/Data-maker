@tool
extends EditorPlugin

const _MainPanel    = preload("res://addons/data_maker/ui/main_panel.gd")

var _panel: Control

const CONFIG_PATH = "user://data_maker.cfg"

func _enter_tree() -> void:
	_panel = _MainPanel.new()
	_panel.name = "DataMakerPanel"
	add_control_to_bottom_panel(_panel, "Data Maker")

	var cfg = ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		var p = cfg.get_value("editor", "last_project_path", "")
		if p != "" and DirAccess.dir_exists_absolute(p):
			_panel.restore_project(p)

func _exit_tree() -> void:
	if is_instance_valid(_panel):
		var cfg = ConfigFile.new()
		cfg.set_value("editor", "last_project_path", _panel.get_project_root())
		cfg.save(CONFIG_PATH)
		_panel.free_dialogs()
		remove_control_from_bottom_panel(_panel)
		_panel.queue_free()
		_panel = null

func _shortcut_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.ctrl_pressed and event.keycode == KEY_S:
			if is_instance_valid(_panel):
				_panel.save_dirty_files()
			get_viewport().set_input_as_handled()
