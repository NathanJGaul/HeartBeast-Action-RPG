extends KinematicBody2D

const EnemyDeathEffect = preload("res://Effects/EnemyDeathEffect.tscn")

export var ACCELERATION = 300
export var MAX_SPEED = 50
export var FRICTION = 200
export var WANDER_TARGET_RANGE = 4

enum {
	IDLE,
	WANDER,
	CHASE
}

var velocity = Vector2.ZERO

var knockback = Vector2.ZERO

var state = CHASE

onready var stats = $Stats
onready var playerDetectionZone = $PlayerDetectionZone
onready var sprite = $AnimatedSprite
onready var hurtbox = $Hurtbox
onready var softCollision = $SoftCollision
onready var wanderController = $WanderController

func _ready():
	sprite.play("Fly")
	state = pick_random_state([IDLE, WANDER])

func _physics_process(delta):
	knockback = knockback.move_toward(Vector2.ZERO, FRICTION * delta)
	knockback = move_and_slide(knockback)
	
	match state:
		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			seek_player()
			
			if wanderController.get_time_left() == 0:
				state = pick_random_state([IDLE, WANDER])
				wanderController.start_wander_timer(rand_range(1, 3))
		
		WANDER:
			seek_player()
			
			if wanderController.get_time_left() == 0:
				state = pick_random_state([IDLE, WANDER])
				wanderController.start_wander_timer(rand_range(1, 3))
				
			accelerate_towards_point(global_position.direction_to(wanderController.target_position), delta)
			
			if global_position.distance_to(wanderController.target_position) <= WANDER_TARGET_RANGE:
				state = pick_random_state([IDLE, WANDER])
				wanderController.start_wander_timer(rand_range(1, 3))
			
		CHASE:
			var player = playerDetectionZone.player
			if player != null:
				accelerate_towards_point(global_position.direction_to(player.global_position), delta)
				
			else:
				state = IDLE
	
	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector() * delta * 800
		
	velocity = move_and_slide(velocity)
			
func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE

func pick_random_state(sate_list):
	sate_list.shuffle()
	return sate_list.pop_front()
	
func accelerate_towards_point(point, delta):
	velocity = velocity.move_toward(point * MAX_SPEED, ACCELERATION * delta)
	sprite.flip_h = velocity.x < 0

func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	knockback = area.knockback_vector * 150
	hurtbox.start_invincibility(0.5)
	hurtbox.create_hit_effect()

func _on_Stats_no_health():
	queue_free()
	var enemyDeathEffect = EnemyDeathEffect.instance()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position
