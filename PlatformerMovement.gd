extends CharacterBody2D

# Movement settings
var speed = 200
var jump_velocity = -400
var gravity = 900
var bounce_velocity = -700  # stronger jump for bouncy surfaces

# Extra jump feel
var coyote_time = 0.08          # seconds you can still jump after leaving floor
var jump_buffer_time = 0.08     # seconds a jump input is remembered before landing

# Internal timers
var coyote_timer = 0.0
var jump_buffer_timer = 0.0

func _physics_process(delta):
	var velocity = self.velocity

	# Apply gravity
	if not is_on_floor_excluding_bouncy():
		velocity.y += gravity * delta

	# Update timers
	if is_on_floor_excluding_bouncy():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)

	jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)

	# Left / Right movement (A/D)
	var input_direction = 0
	if Input.is_key_pressed(KEY_A):
		input_direction -= 1
	if Input.is_key_pressed(KEY_D):
		input_direction += 1
	velocity.x = input_direction * speed

	# Register jump input (buffer)
	if Input.is_key_pressed(KEY_SPACE):
		jump_buffer_timer = jump_buffer_time

	# Jump if buffer + coyote overlap
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	# Move the character
	self.velocity = velocity
	move_and_slide()

	# Bounce check (always allowed, independent of ground logic)
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("Bouncy"):
			self.velocity.y = bounce_velocity


# --- Custom floor check that ignores Bouncy surfaces ---
func is_on_floor_excluding_bouncy() -> bool:
	if not is_on_floor():
		return false
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision.get_collider().is_in_group("Bouncy"):
			return false
	return true
