@tool
extends Window
class_name AddPropDialog

signal property_confirmed(name: String, type: String, default_val: String, group_files: Array)

var _name_edit: LineEdit
var _type_opt: OptionButton
var _default_edit: LineEdit
var _group_files: Array

func _ready() -> void:
	title = "Configure New Column"
	size = Vector2(400, 260)
	wrap_controls = true
	close_requested.connect(func(): hide())

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	add_child(vbox)

	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Property Name"
	vbox.add_child(_name_edit)

	_type_opt = OptionButton.new()
	_type_opt.add_item("String")
	_type_opt.add_item("Number")
	_type_opt.add_item("Boolean")
	vbox.add_child(_type_opt)

	_default_edit = LineEdit.new()
	_default_edit.placeholder_text = "Default Value"
	vbox.add_child(_default_edit)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var footer = HBoxContainer.new()
	var cancel = Button.new(); cancel.text = "Cancel"
	cancel.pressed.connect(func(): hide())
	footer.add_child(cancel)
	var confirm = Button.new(); confirm.text = "Confirm"
	confirm.pressed.connect(_on_confirm)
	footer.add_child(confirm)
	vbox.add_child(footer)

func open_for(group_files: Array) -> void:
	_group_files = group_files
	_name_edit.text = ""
	_default_edit.text = ""
	_type_opt.select(0)
	popup_centered()

func _on_confirm() -> void:
	var name = _name_edit.text.strip_edges()
	if name == "":
		return
	var types = ["string", "number", "boolean"]
	property_confirmed.emit(name, types[_type_opt.selected], _default_edit.text, _group_files)
	hide()
