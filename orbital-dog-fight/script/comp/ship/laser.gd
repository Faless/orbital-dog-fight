
extends RigidBody2D

export var power = 10 setget set_power,get_power

func _ready():
	get_node("LifeTime").connect("timeout", self, "_die")
	get_node("LifeTime").start()
	connect("body_enter", self, "_on_body_enter")
	pass

func set_power(pw):
	power = pw

func get_power():
	return power

func _die():
	queue_free()

func _on_body_enter(body):
	if body.is_in_group("shootables"):
		body.hit(self)
	_die()

