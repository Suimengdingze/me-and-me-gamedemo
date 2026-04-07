extends CharacterBody2D

@export var speed := 2500.0
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta):
	var dir := Input.get_axis("ui_left", "ui_right")

	velocity.x = dir * speed

	if dir == 0:
		anim.play("idle")
	else:
		anim.play("run")

		if dir > 0:
			anim.flip_h = true
		elif dir < 0:
			anim.flip_h = false

	move_and_slide()
