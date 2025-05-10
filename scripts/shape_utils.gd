extends Object

class_name ShapeUtils

static func get_normal_at_(point: Vector2, body: PhysicsBody2D, shape_origin: Vector2) -> Vector2:
	for i in body.get_shape_owners():
		for j in range(body.shape_owner_get_shape_count(i)):
			var shape = body.shape_owner_get_shape(i, j)
			if shape is RectangleShape2D:
				print("RectangleShape2D normals not implemented")
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
