class_name LevelData extends Resource

@export var exp_per_level: Array[int] = [0, 100, 250, 500, 900, 1500]

func get_exp_for_level(level: int) -> int:
	if level < exp_per_level.size():
		return exp_per_level[level]
	return exp_per_level[-1] + (level - exp_per_level.size() + 1) * 1000
