extends Object

class_name ShapeUtils

static func _is_between(x, min, max)-> bool:
	if x > min and x < max:
		return true
	else: return false

static func get_normal_at_(point: Vector2, body: PhysicsBody2D, shape_origin: Vector2) -> Vector2:
	for i in body.get_shape_owners():
		for j in range(body.shape_owner_get_shape_count(i)):
			var owner = body.shape_owner_get_owner(i)
			var shape = body.shape_owner_get_shape(i, j)
			if shape is RectangleShape2D:
				shape_origin = owner.global_position
				var angle = (point - shape_origin).angle()
				print(angle)
				var corners = [
					Vector2(- shape.size.x*0.5, - shape.size.y*0.5).angle(),
					Vector2(  shape.size.x*0.5, - shape.size.y*0.5).angle(),
					Vector2(  shape.size.x*0.5,   shape.size.y*0.5).angle(),
					Vector2(- shape.size.x*0.5,   shape.size.y*0.5).angle()
					]
				if _is_between(angle, corners[1], corners[2]):
					return Vector2.RIGHT
				if _is_between(angle, corners[0], corners[1]):
					return Vector2.UP
				if _is_between(angle, corners[2], corners[3]):
					return Vector2.DOWN
				if angle < corners[0] or angle > corners[3]:
					return Vector2.LEFT
				# Doesn't take into account rotation yet.
				return (point - shape_origin).normalized() # temporary
			elif shape is CircleShape2D:
				return (point - shape_origin).normalized()
			elif shape is ConvexPolygonShape2D:
				var best = -1
				var bestDistance = 9999999999.0
				for p in range(len(shape.points)):
					if p == 0: continue
					var midpoint : Vector2 = (shape.points[p] + shape.points[p-1]) * 0.5
					var d = (midpoint+shape_origin).distance_squared_to(point)
					if d < bestDistance:
						bestDistance = d
						best = p
				if best != -1:
					var tangent : Vector2 = (shape.points[best] - shape.points[best-1])
					tangent = tangent.normalized()
					return tangent.orthogonal().normalized()
			else:
				print(shape)
	return point-shape_origin.normalized()
