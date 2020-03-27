tool
extends Spatial

export(float) var force = 15
export(float) var hit_height = 0

var CANNON_BALL = preload("res://plugins/minigames/forest_run/Forest Arena/CannonBall.tscn")

func _process(_delta):
	if Engine.editor_hint:
		$ImmediateGeometry.clear()
		$ImmediateGeometry.begin(Mesh.PRIMITIVE_LINE_STRIP)
		$ImmediateGeometry.set_color(Color.red)
		var velocity = $Position3D.translation.normalized() * force
		var i = 0
		while true:
			var pos = ($"Scene Root6".transform * $"Scene Root6/ForestCannonBall".transform).origin + (i * 0.1) * (velocity + i * 0.05 * Vector3(0, -9.81, 0))
			$ImmediateGeometry.add_vertex(pos)
			if pos.y < hit_height - self.global_transform.origin.y:
				break
			i = i + 1
		$ImmediateGeometry.end()

func fire():
	$AnimationPlayer.queue("throw")
	yield($AnimationPlayer, "animation_finished")
	
	var transform = $"Scene Root6/ForestCannonBall".global_transform
	var ball = CANNON_BALL.instance()
	add_child(ball)
	ball.set_as_toplevel(true)
	ball.velocity = ($Position3D.global_transform.origin - self.global_transform.origin).normalized() * force
	ball.transform = transform
	ball.hit_height = hit_height
