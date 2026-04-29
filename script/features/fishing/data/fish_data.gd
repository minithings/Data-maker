class_name FishData extends CustomResource

# ============ THÔNG TIN CƠ BẢN ============
@export_group("Thông tin cá")
@export var fish_code: String = "carp"
@export var name: String = "Cá Chép"
@export_multiline var description: String = "Loại cá phổ biến ở ao hồ."

@export_group("Hiển thị")
@export var icon: Texture2D
@export var fish_sprite: Texture2D

enum FishRarity {COMMON, UNCOMMON, RARE, EPIC, LEGENDARY}
@export_group("Phân loại")
@export var rarity: FishRarity = FishRarity.COMMON
@export var category: String = "freshwater"

@export_group("Cơ chế câu cá")
@export var base_catch_time: float = 8.0
@export var bite_window: float = 2.5
@export var difficulty: int = 1
@export var min_rod_level: int = 1
@export var escape_chance: float = 0.1

@export_subgroup("Mùa & Điều kiện")
@export var seasons: Array = []
@export var active_hours_start: int = 0
@export var active_hours_end: int = 23
@export var weather_bonus: Array[String] = []
@export var weather_penalty: Array[String] = []

@export_group("Thu hoạch")
@export var loot_table: Array[LootData]
@export var weight_min: float = 0.3
@export var weight_max: float = 5.0
@export var base_sell_price: int = 20

@export_group("Kinh nghiệm")
@export var exp_reward: int = 10
func can_catch_in_season(season: int) -> bool:
	if seasons.is_empty():
		return true
	return season in seasons

func can_catch_at_hour(hour: int) -> bool:
	if active_hours_start <= active_hours_end:
		return hour >= active_hours_start and hour <= active_hours_end
	# Xử lý trường hợp qua nửa đêm (ví dụ 22:00 - 04:00)
	return hour >= active_hours_start or hour <= active_hours_end

func get_weather_multiplier(weather: String) -> float:
	if weather in weather_bonus:
		return 1.5
	if weather in weather_penalty:
		return 0.4
	return 1.0

func get_rarity_name() -> String:
	return FishRarity.keys()[rarity]

func get_rarity_color() -> Color:
	match rarity:
		FishRarity.COMMON: return Color.WHITE
		FishRarity.UNCOMMON: return Color.GREEN
		FishRarity.RARE: return Color.CYAN
		FishRarity.EPIC: return Color(0.6, 0.2, 0.9)
		FishRarity.LEGENDARY: return Color.GOLD
	return Color.WHITE

func calculate_sell_price(weight: float, quality: int) -> int:
	var price := base_sell_price
	price += int(weight * 5.0)
	price = int(price * (1.0 + quality * 0.3))
	return price
