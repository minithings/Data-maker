class_name TransportJobPacket

enum Status { AVAILABLE, CLAIMED, IN_PROGRESS, DONE, CANCELLED }

## Loại công việc vận chuyển
enum JobType { SUPPLY, COLLECT, CLEANUP }

var job_id: int = 0
var job_type: JobType = JobType.SUPPLY
var status: Status = Status.AVAILABLE

## Node nguồn (kho/producer chứa item cần lấy)
var pickup_target: Node2D = null
## Node đích (kho/consumer cần nhận item)
var delivery_target: Node2D = null

var item_data: ItemData = null
var amount: int = 0
## Slot index trên consumer (dùng cho SUPPLY job có specific slot)
var target_slot: int = -1

## Độ ưu tiên: số càng cao càng được xử lý trước
var priority: int = 0

## Node yêu cầu job (để callback khi cần)
var requester: Node2D = null

## NPC đang giữ job này (được set khi CLAIMED)
var claimed_by: Object = null

## Thời điểm tạo (để tie-break và expire cũ)
var created_at: float = 0.0

## ID tự tăng
static var _next_id: int = 0

func _init(
		p_type: JobType,
		p_pickup: Node2D,
		p_delivery: Node2D,
		p_item_data: ItemData,
		p_amount: int,
		p_priority: int = 0,
		p_requester: Node2D = null,
		p_slot: int = -1
) -> void:
	_next_id += 1
	job_id = _next_id
	job_type = p_type
	pickup_target = p_pickup
	delivery_target = p_delivery
	item_data = p_item_data
	amount = p_amount
	priority = p_priority
	requester = p_requester
	target_slot = p_slot
	created_at = Time.get_ticks_msec() / 1000.0

func is_valid() -> bool:
	return (
		status != Status.CANCELLED
		and status != Status.DONE
		and is_instance_valid(pickup_target)
		and is_instance_valid(delivery_target)
		and item_data != null
		and amount > 0
	)

func claim(npc: Object) -> void:
	status = Status.CLAIMED
	claimed_by = npc

func start() -> void:
	status = Status.IN_PROGRESS

func complete() -> void:
	status = Status.DONE

func cancel() -> void:
	status = Status.CANCELLED
	claimed_by = null
