extends Resource

class_name ProjectileData

@export_category("Basic Properties")
@export var name: String = "Projectile" ## Name of the projectile type
@export var speed: float = 500.0 ## Base movement speed
@export var damage: int = 1 ## Base damage dealt to targets
@export var lifetime: float = 5.0 ## How long the projectile exists before auto-destroying

@export_category("Visual")
@export var texture: Texture2D ## Sprite texture for the projectile
@export var scale: Vector2 = Vector2.ONE ## Scale of the projectile sprite
@export var modulate: Color = Color.WHITE ## Color tint of the projectile

@export_category("Effects")
@export var element: String = "" ## Element type (fire, ice, etc.)
@export var impact_effect: PackedScene ## Effect to spawn on impact
@export var trail_effect: PackedScene ## Effect to spawn while moving

@export_category("Audio")
@export var shoot_sound: AudioStream ## Sound played when projectile is created
@export var impact_sound: AudioStream ## Sound played when projectile hits something
@export var travel_sound: AudioStream ## Sound played while projectile is moving

@export_category("Behavior")
@export var use_gravity: bool = false ## Whether projectile is affected by gravity
@export var gravity_scale: float = 1.0 ## How strongly projectile is affected by gravity
@export var pierce_targets: bool = false ## Whether projectile continues after hitting
@export var homing: bool = false ## Whether projectile follows target
@export var homing_strength: float = 0.0 ## How strongly projectile follows target
@export var bounces: int = 0 ## Number of times projectile can bounce
@export var explodes: bool = false ## Whether projectile explodes on impact
@export var explosion_radius: float = 0.0 ## Radius of explosion if applicable
