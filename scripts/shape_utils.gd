extends Object

class_name ShapeUtils

static func _is_between(x, min_value, max_value)-> bool:
	if x > min_value and x < max_value:
		return true
	else: return false

static func get_normal_at_(point: Vector2, body: PhysicsBody2D, shape_origin: Vector2) -> Vector2:
	var best_distance = INF
	var best_normal = Vector2.ZERO

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
				var normal = (point - owner.global_position).normalized()
				var dist = point.distance_to(owner.global_position) - shape.radius
				if dist < best_distance:
					best_distance = dist
					best_normal = normal
			elif shape is ConvexPolygonShape2D:
				shape_origin = owner.global_position
				for p in range(len(shape.points)):
					var p1 = shape.points[p] + shape_origin
					var p2 = shape.points[p - 1] + shape_origin
					var seg = p2 - p1
					var seg_length = seg.length()
					if seg_length == 0:
						continue
					var t = ((point - p1).dot(seg)) / (seg_length * seg_length)
					t = clamp(t, 0, 1)
					var projection = p1 + seg * t
					var dist = point.distance_squared_to(projection)
					if dist < best_distance:
						best_distance = dist
						best_normal = seg.orthogonal().normalized()
	# The normal may point inward or outward depending on winding; flip if needed
	if best_distance < 1000:
		return -best_normal
	return (point-shape_origin).normalized()
