@tool
extends Window
class_name CreateResourceDialog

signal resource_create_requested(name: String, ext: String, template_id: String, schema: Array)

var _name_edit: LineEdit
var _ext_tres: Button
var _ext_json: Button
var _clone_container: VBoxContainer
var _json_container: VBoxContainer
var _clone_search: LineEdit
var _clone_list: ItemList
var _schema_list: VBoxContainer
var _prop_name_edit: LineEdit
var _prop_type_opt: OptionButton
var _schema: Array = []  # [{name, type}]
var _store: DataStore
var _selected_template: String = ""

func _init(store: DataStore) -> void:
	_store = store

func _ready() -> void:
	title = "Create New Resource"
	size = Vector2(520, 520)
	wrap_controls = true
	close_requested.connect(func(): hide())

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	add_child(vbox)

	# File name
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Resource Filename"
	vbox.add_child(_name_edit)

	# Extension toggle
	var ext_row = HBoxContainer.new()
	_ext_tres = Button.new()
	_ext_tres.text = ".tres"
	_ext_tres.toggle_mode = true
	_ext_tres.button_pressed = true
	_ext_tres.pressed.connect(func(): _on_ext_changed(".tres"))
	ext_row.add_child(_ext_tres)
	_ext_json = Button.new()
	_ext_json.text = ".json"
	_ext_json.toggle_mode = true
	_ext_json.pressed.connect(func(): _on_ext_changed(".json"))
	ext_row.add_child(_ext_json)
	vbox.add_child(ext_row)

	# .tres clone area
	_clone_container = VBoxContainer.new()
	var clone_label = Label.new()
	clone_label.text = "Clone structure from:"
	_clone_container.add_child(clone_label)
	_clone_search = LineEdit.new()
	_clone_search.placeholder_text = "Search templates..."
	_clone_search.text_changed.connect(_on_clone_search)
	_clone_container.add_child(_clone_search)
	_clone_list = ItemList.new()
	_clone_list.custom_minimum_size.y = 120
	_clone_list.item_selected.connect(func(idx):
		_selected_template = _clone_list.get_item_metadata(idx)
	)
	_clone_container.add_child(_clone_list)
	vbox.add_child(_clone_container)

	# .json schema builder
	_json_container = VBoxContainer.new()
	_json_container.visible = false
	var schema_label = Label.new()
	schema_label.text = "Define Initial Object Schema:"
	_json_container.add_child(schema_label)

	var prop_row = HBoxContainer.new()
	_prop_name_edit = LineEdit.new()
	_prop_name_edit.placeholder_text = "Prop Name"
	_prop_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prop_row.add_child(_prop_name_edit)
	_prop_type_opt = OptionButton.new()
	_prop_type_opt.add_item("String")
	_prop_type_opt.add_item("Number")
	_prop_type_opt.add_item("Bool")
	prop_row.add_child(_prop_type_opt)
	var add_prop_btn = Button.new()
	add_prop_btn.text = "+"
	add_prop_btn.pressed.connect(_add_prop_to_schema)
	prop_row.add_child(add_prop_btn)
	_json_container.add_child(prop_row)

	_schema_list = VBoxContainer.new()
	_json_container.add_child(_schema_list)
	vbox.add_child(_json_container)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Footer
	var footer = HBoxContainer.new()
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(func(): hide())
	footer.add_child(cancel_btn)
	var create_btn = Button.new()
	create_btn.text = "Create"
	create_btn.pressed.connect(_on_create)
	footer.add_child(create_btn)
	vbox.add_child(footer)

func open() -> void:
	_name_edit.text = ""
	_schema = []
	_selected_template = ""
	_on_ext_changed(".tres")
	_refresh_clone_list("")
	popup_centered()

func _on_ext_changed(ext: String) -> void:
	_ext_tres.button_pressed = ext == ".tres"
	_ext_json.button_pressed = ext == ".json"
	_clone_container.visible = ext == ".tres"
	_json_container.visible = ext == ".json"

func _on_clone_search(q: String) -> void:
	_refresh_clone_list(q)

func _refresh_clone_list(q: String) -> void:
	_clone_list.clear()
	var query = q.to_lower()
	var count = 0
	for f in _store.all_files:
		if f["type"] != "tres":
			continue
		if query != "" and not f["name"].to_lower().contains(query) and not f["script_name"].to_lower().contains(query):
			continue
		_clone_list.add_item("%s  (%s)" % [f["name"], f["script_name"]])
		_clone_list.set_item_metadata(_clone_list.item_count - 1, f["id"])
		count += 1
		if count >= 8:
			break

func _add_prop_to_schema() -> void:
	var pname = _prop_name_edit.text.strip_edges()
	if pname == "":
		return
	var types = ["string", "number", "boolean"]
	_schema.append({"name": pname, "type": types[_prop_type_opt.selected]})
	_prop_name_edit.text = ""
	_refresh_schema_list()

func _refresh_schema_list() -> void:
	for c in _schema_list.get_children():
		c.queue_free()
	for i in _schema.size():
		var row = HBoxContainer.new()
		var lbl = Label.new()
		lbl.text = "%s  [%s]" % [_schema[i]["name"], _schema[i]["type"]]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var del_btn = Button.new()
		del_btn.text = "✕"
		var cap_i = i
		del_btn.pressed.connect(func(): _schema.remove_at(cap_i); _refresh_schema_list())
		row.add_child(del_btn)
		_schema_list.add_child(row)

func _on_create() -> void:
	var name = _name_edit.text.strip_edges()
	if name == "":
		return
	var ext = ".tres" if _ext_tres.button_pressed else ".json"
	resource_create_requested.emit(name, ext, _selected_template, _schema)
	hide()
