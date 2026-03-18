class_name NPCData extends CustomResource

@export_group("Thông tin chung")
@export var npc_code: String = "villager"
@export var movement_speed: float = 100.0
@export var max_inventory_slots: int = 10

@export_group("Model Appearance")
@export var model: ModelData