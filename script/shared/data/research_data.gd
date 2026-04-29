class_name ResearchData extends CustomResource

# ============ IDENTITY ============
@export var code: String = ""
@export var name: String = ""
@export var description: String = ""
@export var flavor_text: String = ""        # quote/lore ngắn hiển thị trong UI
@export var icon: Texture2D = null
@export var category: String = ""          # "farming" | "cooking" | "husbandry" | "industry" | "fishing" | "trade"
@export var tier: int = 1                  # 0..4, dùng để layout UI tree

# ============ UNLOCK CONDITIONS ============
# Tất cả prerequisites phải được unlock trước
@export var prerequisites: Array[String] = []
# Village level tối thiểu (0 = luôn mở được nếu prerequisites đủ)
@export var required_village_level: int = 0

# ============ COST ============
# Để 0 / rỗng nếu node này miễn phí
@export var gold_cost: int = 0
@export var item_costs: Dictionary = {}    # { "wood": 20, "stone": 5 }

# ============ TREE STRUCTURE ============
# Danh sách code con — dùng để build UI tree, không ảnh hưởng logic unlock
@export var children: Array[String] = []

# ============ UNLOCKS ============
@export var unlocks_buildings: Array[String] = []
@export var unlocks_recipes: Array[String] = []
@export var unlocks_skills: Array[String] = []
@export var unlocks_tools: Array[String] = []       # item codes: tool_axe_t1, fishing_rod_basic...
@export var unlocks_seeds: Array[String] = []       # item codes: seed_wheat, seed_grape...
@export var unlocks_knowledges: Array[String] = []  # journal/codex entries

# ============ PRODUCTION BUFFS ============
## Buff áp dụng ngay khi research được unlock, cộng dồn với skill effects.
## Key là tên modifier giống SkillEffectSystem: "crop_grow_speed", "double_yield_chance",
## "crop_yield_bonus", "npc_work_speed", "harvest_speed", "production_efficiency".
## Value là float — cộng thêm vào modifier tương ứng.
## Ví dụ: { "crop_grow_speed": 0.1 }  → cây lớn nhanh hơn 10%
@export var production_buffs: Dictionary = {}

# ============ LOGIC ============

## Kiểm tra có đủ điều kiện để research không (KHÔNG tính cost, chỉ tính prerequisites + level)
func can_research(unlocked_nodes: Dictionary, village_level: int) -> bool:
	if village_level < required_village_level:
		return false
	for pre in prerequisites:
		if not unlocked_nodes.get(pre, false):
			return false
	return true

## Trả về true nếu node này không tốn gì cả
func is_free() -> bool:
	return gold_cost == 0 and item_costs.is_empty()

## Tóm tắt cost dạng string để hiển thị UI
func get_cost_label() -> String:
	if is_free():
		return "Free"
	var parts: Array[String] = []
	if gold_cost > 0:
		parts.append("%d gold" % gold_cost)
	for item_code in item_costs:
		parts.append("%dx %s" % [item_costs[item_code], item_code])
	return ", ".join(parts)

## Tóm tắt những gì được mở khoá
func get_unlock_summary() -> Dictionary:
	return {
		"buildings":  unlocks_buildings.size(),
		"recipes":    unlocks_recipes.size(),
		"skills":     unlocks_skills.size(),
		"tools":      unlocks_tools.size(),
		"seeds":      unlocks_seeds.size(),
		"knowledge":  unlocks_knowledges.size(),
	}

## Tổng số thứ được mở khoá — dùng để hiển thị badge trên UI card
func get_total_unlocks() -> int:
	return (unlocks_buildings.size() + unlocks_recipes.size() + unlocks_skills.size()
		+ unlocks_tools.size() + unlocks_seeds.size() + unlocks_knowledges.size())
