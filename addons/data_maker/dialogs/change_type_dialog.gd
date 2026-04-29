@tool
extends Window
class_name ChangeTypeDialog

signal type_change_confirmed(prop: String, new_type: String, group_files: Array)

var _prop_label: Label
var _type_opt: OptionButton
var _prop: String
var _group_files: Array

func _ready() -> void:
	hide()
	title = "Change Column Type"
	size = Vector2(400, 220)
	wrap_controls = true
	close_requested.connect(func(): hide())

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	add_child(vbox)

	var row = HBoxContainer.new()
	var lbl = Label.new(); lbl.text = "Column:"
	row.add_child(lbl)
	_prop_label = Label.new()
	row.add_child(_prop_label)
	vbox.add_child(row)

	_type_opt = OptionButton.new()
	_type_opt.add_item("String")
	_type_opt.add_item("Number")
	_type_opt.add_item("Boolean")
	vbox.add_child(_type_opt)

	var note = Label.new()
	note.text = "Values will be converted automatically."
	note.add_theme_font_size_override("font_size", 10)
	vbox.add_child(note)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var footer = HBoxContainer.new()
	var cancel = Button.new(); cancel.text = "Cancel"
	cancel.pressed.connect(func(): hide())
	footer.add_child(cancel)
	var confirm = Button.new(); confirm.text = "Convert All"
	confirm.pressed.connect(_on_confirm)
	footer.add_child(confirm)
	vbox.add_child(footer)

func open_for(prop: String, group_files: Array, store) -> void:
	_prop = prop
	_group_files = group_files
	_prop_label.text = prop
	var current_type = store.get_original_type(group_files[0]["id"], prop)
	match current_type:
		"number": _type_opt.select(1)
		"boolean": _type_opt.select(2)
		_: _type_opt.select(0)
	popup_centered()

func _on_confirm() -> void:
	var types = ["string", "number", "boolean"]
	type_change_confirmed.emit(_prop, types[_type_opt.selected], _group_files)
	hide()
