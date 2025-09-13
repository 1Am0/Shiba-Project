extends CharacterBody2D

# Movement settings
var speed = 200
var jump_velocity = -400
var gravity = 900

func _physics_process(delta):
	var velocity = self.velocity  # CharacterBody2D has a built-in velocity
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Left / Right movement
	var input_direction = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	velocity.x = input_direction * speed
	
	# Jump
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_velocity
	
	# Move the character
	self.velocity = velocity
	move_and_slide()
