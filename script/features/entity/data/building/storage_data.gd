class_name StorageBuildingData extends BuildingData

@export_group("Cấu hình Kho chứa & Dịch vụ")
@export var is_storage: bool = true
@export var is_currency_storage: bool = false
@export var storage_priority: int = 0
@export var storage_capacity: int = 20
@export var default_accepted_types: Array[String] = []
@export var default_accepted_items: Array[String] = []
