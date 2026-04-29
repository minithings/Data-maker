class_name EnemyData extends CustomResource

@export var code: String = ""
@export var name: String = "Unknown Enemy"
@export var max_health: int = 100
@export var attack: int = 10
@export var defense: int = 0
@export var speed: float = 50.0
@export var exp_reward: int = 10
@export var loot_table: Array[LootData]
@export var attack_speed: float = 1.0

## Validate dữ liệu sau khi resource được load.
## Gọi thủ công sau khi load resource hoặc trong editor tool script.
func validate() -> void:
	if max_health <= 0:
		push_error("EnemyData [%s]: max_health phải > 0, hiện tại: %s" % [code, max_health])
		max_health = 1
	if attack < 0:
		push_error("EnemyData [%s]: attack không được âm, hiện tại: %s" % [code, attack])
		attack = 0
	if defense < 0:
		push_error("EnemyData [%s]: defense không được âm, hiện tại: %s" % [code, defense])
		defense = 0
	if speed < 0.0:
		push_error("EnemyData [%s]: speed không được âm, hiện tại: %s" % [code, speed])
		speed = 0.0
	if attack_speed <= 0.0:
		push_error("EnemyData [%s]: attack_speed phải > 0, hiện tại: %s" % [code, attack_speed])
		attack_speed = 0.1
	if exp_reward < 0:
		push_error("EnemyData [%s]: exp_reward không được âm, hiện tại: %s" % [code, exp_reward])
		exp_reward = 0
