extends Node2D

export var timeout = 10.0 # timeout in seconds
export var viewport_scale = 1.0

var timed_objects = []
var exts

class TimedObject:
	var timer = null
	var object = null
	var indicator = null
	var parent = null
	var indicator_texture = null
	
	func _init(timeout, obj, parent):
		print("new timed object created")
		self.object = weakref(obj)
		self.parent = parent
		self.indicator_texture = load("res://assets/img/arrowwhite.png")
		self.timer = Timer.new()
		self.timer.set_wait_time(timeout)
		self.timer.set_one_shot(true)
		self.timer.connect("timeout", self, "_timeout")
		parent.add_child(self.timer)
		self.timer.start()
		if (obj.is_in_group("ships")):
			self.indicator = Node2D.new()
			var indicatorsprite = Sprite.new()
			indicatorsprite.set_texture(self.indicator_texture)
			indicatorsprite.set_z(4)
			indicatorsprite.show()
			parent.add_child(self.indicator)
			self.indicator.add_child(indicatorsprite)
			var indicatorlabel = Label.new()
			indicatorlabel.set_theme(load("res://assets/themes/noshadow.xml"))
			indicatorlabel.set_text(str(int(self.timer.get_time_left())))
			indicatorlabel.set_align(Label.ALIGN_CENTER)
			indicatorlabel.set_valign(Label.ALIGN_CENTER)
			indicatorlabel.set_pos(Vector2(-32, -32))
			indicatorlabel.set_size(Vector2(64,64))
			var indicatorlabelcontainer = Node2D.new()
			indicatorlabelcontainer.set_pos(Vector2(-40,0))
			indicatorlabelcontainer.add_child(indicatorlabel)
			self.indicator.add_child(indicatorlabelcontainer)
			

	func _timeout():
		# Be sure that object has not been deleted
		if self.object.get_ref() == null:
			clear()
			return
		if self.object.get_ref().is_in_group("ships"):
			if not self.object.get_ref().is_dummy:
				self.object.get_ref().die("exp_one")
			self.clear()
			print("is dead")
		elif self.object.get_ref().is_in_group("asteroids"):
			self.object.get_ref().scale = 0.1
			self.object.get_ref()._die()
		clear()
		
	func get_object():
		return self.object.get_ref()
	
	func update(width, height):
		if self.object.get_ref() == null:
			clear()
			return
		var indicator_pos = Vector2(0.0,0.0)
		if self.indicator != null:
			var obj_pos = self.object.get_ref().get_pos()
			indicator_pos = obj_pos
			if obj_pos.x > width*2 - 16:
				indicator_pos.x = width*2 - 16
			elif obj_pos.x < 16:
				indicator_pos.x = 16
			if obj_pos.y > height*2 - 16:
				indicator_pos.y = height*2 - 16
			elif obj_pos.y < 16:
				indicator_pos.y = 16
			self.indicator.set_pos(indicator_pos)
			self.indicator.set_rot(indicator_pos.angle_to_point(obj_pos) + PI/2)
			self.indicator.get_child(1).set_rot(-(indicator_pos.angle_to_point(obj_pos) + PI/2))
			var timeleft = int(self.timer.get_time_left())
			if timeleft < 10:
				timeleft = "0" + str(timeleft)
			else:
				timeleft = str(timeleft)
			self.indicator.get_child(1).get_child(0).set_text(timeleft)
	
	func clear():
		self.timer.queue_free()
		if indicator != null:
			self.indicator.queue_free()
		self.parent.timed_objects.remove(self.parent.timed_objects.find(self))

func _ready():
	# Initialization here
	exts = (get_tree().get_root().get_rect().end * viewport_scale)/2
	get_node("ScreenExtents").get_shape(0).set_extents(exts)
	get_node("ScreenExtents").set_pos(exts)
	set_process(true)

func _process(delta):
	for obj in timed_objects:
		obj.update(exts.x, exts.y)
	pass
		
func _on_ScreenExtents_body_enter( body ):
	if (body.is_in_group("ships") or body.is_in_group("asteroids")):
		for timed_obj in timed_objects:
			if timed_obj.get_object() == body:
				timed_obj.clear()

func _on_ScreenExtents_body_exit( body ):
	if (body.is_in_group("ships") and !body.isdying) or body.is_in_group("asteroids"):
		var obj = TimedObject.new(timeout, body, self)
		timed_objects.append(obj)
