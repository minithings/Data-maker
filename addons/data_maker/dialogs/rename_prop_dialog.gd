@tool
extends Window
class_name RenamePropDialog

signal rename_confirmed(old_name: String, new_name: String, group_files: Array)

var _old_label: Label
var _new_edit: LineEdit
var _old_name: String
var _group_files: Array

func _ready() -> void:
	hide()
	title = "Rename Property"
	size = Vector2(400, 220)
	wrap_controls = true
	close_requested.connect(func(): hide())

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	add_child(vbox)

	var row = HBoxContainer.new()
	var lbl = Label.new(); lbl.text = "Old name:"
	row.add_child(lbl)
	_old_label = Label.new()
	row.add_child(_old_label)
	vbox.add_child(row)

	_new_edit = LineEdit.new()
	_new_edit.placeholder_text = "New Property Name"
	vbox.add_child(_new_edit)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var footer = HBoxContainer.new()
	var cancel = Button.new(); cancel.text = "Cancel"
	cancel.pressed.connect(func(): hide())
	footer.add_child(cancel)
	var confirm = Button.new(); confirm.text = "Rename All"
	confirm.pressed.connect(_on_confirm)
	footer.add_child(confirm)
	vbox.add_child(footer)

func open_for(prop: String, group_files: Array) -> void:
	_old_name = prop
	_group_files = group_files
	_old_label.text = prop
	_new_edit.text = prop
	popup_centered()

func _on_confirm() -> void:
	var new_name = _new_edit.text.strip_edges()
	if new_name == "" or new_name == _old_name:
		return
	rename_confirmed.emit(_old_name, new_name, _group_files)
	hide()
