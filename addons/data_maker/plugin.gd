@tool
extends EditorPlugin

const MainPanel = preload("res://addons/data_maker/ui/main_panel.gd")

var main_panel: Control
const CONFIG_PATH = "user://data_maker.cfg"

func _enter_tree() -> void:
	main_panel = MainPanel.new()
	main_panel.name = "DataMaker"
	add_control_to_bottom_panel(main_panel, "Data Maker")

	var config = ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		var last_path = config.get_value("editor", "last_project_path", "")
		if last_path != "" and DirAccess.dir_exists_absolute(last_path):
			main_panel.restore_project(last_path)

func _exit_tree() -> void:
	if main_panel:
		var config = ConfigFile.new()
		config.set_value("editor", "last_project_path", main_panel.get_project_root())
		config.save(CONFIG_PATH)
		remove_control_from_bottom_panel(main_panel)
		main_panel.queue_free()

func _shortcut_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.ctrl_pressed and event.keycode == KEY_S:
			if main_panel:
				main_panel.save_dirty_files()
			get_viewport().set_input_as_handled()
