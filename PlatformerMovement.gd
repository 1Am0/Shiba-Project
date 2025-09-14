extends CharacterBody2D

# Movement settings
var speed = 200
var jump_velocity = -400
var gravity = 900
var bounce_velocity = -700

# Dash settings
var dash_speed = 600
var dash_duration = 0.2
var dash_cooldown = 0.5
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var is_dashing = false
var dash_direction = 0

# Jump settings
var max_jumps = 1   # Only reset to 1 when landing (1 ground jump + 1 air jump)
var jumps_left = max_jumps

# Extra jump feel
var coyote_time = 0.08
var jump_buffer_time = 0.08

# Internal timers
var coyote_timer = 0.0
var jump_buffer_timer = 0.0

# Reset position
var reset_position = Vector2(40, -10)

func _physics_process(delta):
	var velocity = self.velocity

	# Reset position with R key (using input action for robustness)
	if Input.is_action_just_pressed("Reset"):
		global_position = reset_position
		velocity = Vector2.ZERO
		self.velocity = velocity
		return

	# Dash cooldown handling
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer = max(dash_cooldown_timer - delta, 0.0)

	# Dashing logic
	if is_dashing:
		dash_timer -= delta
		if has_node("DashParticles"):
			$DashParticles.emitting = true

		velocity.x = dash_speed * dash_direction
		velocity.y = 0

		if dash_timer <= 0.0:
			is_dashing = false
			if has_node("DashParticles"):
				$DashParticles.emitting = false
			dash_cooldown_timer = dash_cooldown
	else:
		if has_node("DashParticles"):
			$DashParticles.emitting = false

		if Input.is_action_just_pressed("Dash") and dash_cooldown_timer <= 0.0:
			is_dashing = true
			dash_timer = dash_duration
			if has_node("DashParticles"):
				$DashParticles.emitting = true

			var input_direction = 0
			if Input.is_action_pressed("Left"):
				input_direction -= 1
			if Input.is_action_pressed("Right"):
				input_direction += 1
			dash_direction = input_direction if input_direction != 0 else (sign(velocity.x) if velocity.x != 0 else 1)

		# Apply gravity if not dashing (no jump cut gravity, always constant gravity!)
		if not is_on_floor_excluding_bouncy():
			velocity.y += gravity * delta

		# Update timers and reset jumps ONLY when landing
		if is_on_floor_excluding_bouncy():
			coyote_timer = coyote_time
			jumps_left = max_jumps  # reset only when truly on floor
		else:
			coyote_timer = max(coyote_timer - delta, 0.0)

		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)

		# Left / Right movement (uses input actions for robustness)
		var input_direction = 0
		if Input.is_action_pressed("Left"):
			input_direction -= 1
		if Input.is_action_pressed("Right"):
			input_direction += 1
		velocity.x = input_direction * speed

		# Register jump input (buffer)
		if Input.is_action_just_pressed("Jump"):
			jump_buffer_timer = jump_buffer_time

		# Jump logic:
		# Allow jump if coyote time (floor jump) OR if jumps_left > 0 (air jump)
		if jump_buffer_timer > 0.0 and (coyote_timer > 0.0 or (not is_on_floor_excluding_bouncy() and jumps_left > 0)):
			velocity.y = jump_velocity
			jump_buffer_timer = 0.0
			coyote_timer = 0.0
			if not is_on_floor_excluding_bouncy():
				jumps_left -= 1 # only decrement on air jump
			if has_node("JumpParticles"):
				$JumpParticles.emitting = true
			if has_node("Jump Audio"):
				$"Jump Audio".play()

	self.velocity = velocity
	move_and_slide()

	# Bounce check (always allowed, independent of ground logic)
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("Bouncy"):
			self.velocity.y = bounce_velocity

func is_on_floor_excluding_bouncy() -> bool:
	if not is_on_floor():
		return false
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision.get_collider().is_in_group("Bouncy"):
			return false
	return true
