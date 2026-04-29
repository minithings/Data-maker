@tool
extends VBoxContainer
class_name DataMakerSidebar

signal folder_selected(full_path: String)
signal new_resource_requested

var _tree: Tree
var _new_btn: Button
var _store: DataStore
var _validator: Validator

func _init(store: DataStore, validator: Validator) -> void:
	_store = store
	_validator = validator

func _ready() -> void:
	custom_minimum_size.x = 220
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	_new_btn = Button.new()
	_new_btn.text = "+ New Resource"
	_new_btn.visible = false
	_new_btn.pressed.connect(func(): new_resource_requested.emit())
	add_child(_new_btn)

	_tree = Tree.new()
	_tree.hide_root = true
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.item_selected.connect(_on_item_selected)
	add_child(_tree)

func refresh() -> void:
	_tree.clear()
	_new_btn.visible = _store.project_root != ""
	var root = _tree.create_item()

	for folder in _store.folders:
		var item = _tree.create_item(root)
		var label = folder["name"]
		var err_count = _validator.get_folder_error_count(folder["full_path"])
		if err_count > 0:
			label += "  (%d)" % err_count
		item.set_text(0, label)
		item.set_metadata(0, folder["full_path"])
		if folder["full_path"] == _store.active_folder:
			_tree.set_selected(item, 0)

func _on_item_selected() -> void:
	var sel = _tree.get_selected()
	if sel:
		var path = sel.get_metadata(0)
		folder_selected.emit(path)
