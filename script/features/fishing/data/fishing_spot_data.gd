class_name FishingSpotData extends CustomResource

@export_group("Thông tin điểm câu")
@export var spot_code: String = "river_spot_01"
@export var display_name: String = "Khúc Sông Yên Tĩnh"
@export_multiline var description: String = "Một khúc sông bình yên, nước trong vắt."

@export_group("Cá có thể câu")
@export var fish_pool: Array[FishData]
@export var rare_bonus_multiplier: float = 1.0

@export_group("Giới hạn & Hồi phục")
@export var max_concurrent_fishers: int = 2
@export var max_fish_stock: int = 20
@export var restock_amount: int = 5
@export var restock_hours: float = 6.0

@export_group("Điều kiện mở khóa")
@export var required_seasons: Array[int] = []
@export var required_research: String = ""
@export var required_player_level: int = 1

@export_group("Vị trí")
@export var map_id: String = "camp"
@export var visual_tile: Vector2i = Vector2i.ZERO
func is_available_in_season(season: int) -> bool:
	if required_seasons.is_empty():
		return true
	return season in required_seasons

func get_random_fish(season: int, hour: int, weather: String) -> FishData:
	var eligible: Array[FishData] = []
	var weights: Array[float] = []

	for fish in fish_pool:
		if not fish.can_catch_in_season(season): continue
		if not fish.can_catch_at_hour(hour): continue
		var w = 1.0 / max(1, fish.difficulty) * fish.get_weather_multiplier(weather)
		# Cá hiếm hơn có weight thấp hơn nhưng được nhân bonus của spot
		match fish.rarity:
			FishData.FishRarity.UNCOMMON: w *= 0.5
			FishData.FishRarity.RARE: w *= 0.2 * rare_bonus_multiplier
			FishData.FishRarity.EPIC: w *= 0.05 * rare_bonus_multiplier
			FishData.FishRarity.LEGENDARY: w *= 0.01 * rare_bonus_multiplier
		eligible.append(fish)
		weights.append(w)

	if eligible.is_empty():
		return null

	# Weighted random pick
	var total := 0.0
	for wt in weights: total += wt
	var roll := randf() * total
	var cumulative := 0.0
	for i in eligible.size():
		cumulative += weights[i]
		if roll <= cumulative:
			return eligible[i]
	return eligible[-1]
