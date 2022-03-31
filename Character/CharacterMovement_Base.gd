extends CharacterBody3D
class_name CharacterMovement



#####################################
#Refrences
@onready var anim_ref = $AnimationTree
@onready var mesh_ref = $Armature
@onready var skeleton_ref = $Armature/Skeleton3D
@onready var collision_shape_ref = $CollisionShape3D
@onready var bonker = $CollisionShape3D/HeadBonker
@onready var camera_root = $CameraRoot
#####################################



#####################################
#Movement Settings
@export var AI := false

@export var is_flying := false
@export var gravity := 9.8

@export var tilt := true

@export var ragdoll := false :
	get: return ragdoll
	set(Newragdoll):
		ragdoll = Newragdoll
		if ragdoll == true:
			if skeleton_ref:
				skeleton_ref.physical_bones_start_simulation()
		else:
			if skeleton_ref:
				skeleton_ref.physical_bones_stop_simulation()


@export var jump_magnitude := 5.0
@export var roll_magnitude := 17.0

var default_height := 2.0
var crouch_height := 1.0

@export var crouch_switch_speed := 5.0 


#Movement Values Settings
#you could play with the values to achieve different movement settings
var deacceleration := 10.0
var acceleration_reducer := 3.0
var movement_data = {
	normal = {
		looking_direction = {
			standing = {
				walk_speed = 1.75,
				run_speed = 3.75,
				sprint_speed = 6.5,
				
				walk_acceleration = 20.0/acceleration_reducer,
				run_acceleration = 20.0/acceleration_reducer,
				sprint_acceleration = 7.5/acceleration_reducer,
				
				idle_rotation_rate = 0.5,
				walk_rotation_rate = 4.0,
				run_rotation_rate = 5.0,
				sprint_rotation_rate = 20.0,
			},

			crouching = {
				walk_speed = 1.5,
				run_speed = 2,
				sprint_speed = 3,
				
				walk_acceleration = 25.0/acceleration_reducer,
				run_acceleration = 25.0/acceleration_reducer,
				sprint_acceleration = 5.0/acceleration_reducer,
				
				idle_rotation_rate = 0.5,
				walk_rotation_rate = 4.0,
				run_rotation_rate = 5.0,
				sprint_rotation_rate = 20.0,
			}
		},
		
		
		
		
		
		velocity_direction = {
			standing = {
				walk_speed = 1.75,
				run_speed = 3.75,
				sprint_speed = 6.5,
				
				#Nomral Acceleration
				walk_acceleration = 20.0/acceleration_reducer,
				run_acceleration = 20.0/acceleration_reducer, 
				sprint_acceleration = 7.5/acceleration_reducer,
				
				#Responsive Rotation
				idle_rotation_rate = 5.0,
				walk_rotation_rate = 8.0,
				run_rotation_rate = 12.0, 
				sprint_rotation_rate = 20.0,
			},

			crouching = {
				walk_speed = 1.5,
				run_speed = 2,
				sprint_speed = 3,
				
				#Responsive Acceleration
				walk_acceleration = 25.0/acceleration_reducer,
				run_acceleration = 25.0/acceleration_reducer,
				sprint_acceleration = 5.0/acceleration_reducer,
				
				#Nomral Rotation
				idle_rotation_rate = 0.5,
				walk_rotation_rate = 4.0,
				run_rotation_rate = 5.0,
				sprint_rotation_rate = 20.0,
			}
		},
		
		
		
		
		
		
		aiming = {
			standing = {
				walk_speed = 1.65,
				run_speed = 3.75,
				sprint_speed = 6.5,
				
				walk_acceleration = 20.0/acceleration_reducer,
				run_acceleration = 20.0/acceleration_reducer,
				sprint_acceleration = 7.5/acceleration_reducer,
				
				idle_rotation_rate = 0.5,
				walk_rotation_rate = 4.0,
				run_rotation_rate = 5.0,
				sprint_rotation_rate = 20.0,
			},

			crouching = {
				walk_speed = 1.5,
				run_speed = 2,
				sprint_speed = 3,
				
				walk_acceleration = 25.0/acceleration_reducer,
				run_acceleration = 25.0/acceleration_reducer,
				sprint_acceleration = 5.0/acceleration_reducer,
				
				idle_rotation_rate = 0.5,
				walk_rotation_rate = 4.0,
				run_rotation_rate = 5.0,
				sprint_rotation_rate = 20.0,
			}
		}
	}
}
#####################################














#####################################
#for logic #it is better not to change it if you don't want to break the system / only change it if you want to redesign the system
var ActualAcceleration :Vector3
var InputAcceleration :Vector3

var vertical_velocity :Vector3 

var InputVelocity :Vector3

var tiltVector : Vector3

var IsMoving := false
var InputIsMoving := false

var head_bonked := false




var AimRate_H :float


var current_movement_data = {
	walk_speed = 1.75,
	run_speed = 3.75,
	sprint_speed = 6.5,

	walk_acceleration = 20.0,
	run_acceleration = 20.0,
	sprint_acceleration = 7.5,

	idle_rotation_rate = 0.5,
	walk_rotation_rate = 4.0,
	run_rotation_rate = 5.0,
	sprint_rotation_rate = 20.0,
}
#####################################



#status
var movement_state = Global.movement_state.grounded
var movement_action = Global.movement_action.none
@export var rotation_mode = Global.rotation_mode :
	get: return rotation_mode
	set(Newrotation_mode):
		rotation_mode = Newrotation_mode
		UpdateCharacterMovement()
		
@export var gait = Global.gait :
	get: return gait
	set(Newgait):
		gait = Newgait
		UpdateCharacterMovement()
@export var stance = Global.stance
@export var overlay_state = Global.overlay_state

func UpdateCharacterMovement():
	match rotation_mode:
		Global.rotation_mode.velocity_direction:
			if skeleton_ref:
				skeleton_ref.modification_stack.enabled = false
			tilt = false
			match stance:
				Global.stance.standing:
					current_movement_data = movement_data.normal.velocity_direction.standing
				Global.stance.crouching:
					current_movement_data = movement_data.normal.velocity_direction.crouching
					
					
		Global.rotation_mode.looking_direction:
			if skeleton_ref:
				skeleton_ref.modification_stack.enabled = false #Change to true when Godot fixes the bug.
			tilt = true
			match stance:
				Global.stance.standing:
					current_movement_data = movement_data.normal.looking_direction.standing
				Global.stance.crouching:
					current_movement_data = movement_data.normal.looking_direction.crouching
					
					
		Global.rotation_mode.aiming:
			match stance:
				Global.stance.standing:
					current_movement_data = movement_data.normal.aiming.standing
				Global.stance.crouching:
					current_movement_data = movement_data.normal.aiming.crouching
#####################################

var PrevAimRate_H :float
var RotationDifference
func _physics_process(delta):
	head_bonked = bonker.is_colliding()
	#
	AimRate_H = abs(($CameraRoot.HObject.rotation.y - PrevAimRate_H) / delta)
	PrevAimRate_H = $CameraRoot.HObject.rotation.y
	#
	#Debug()
	match movement_state:
		Global.movement_state.none:
			pass
		Global.movement_state.grounded:
			#------------------ Rotate Character Mesh ------------------#
			match movement_action:
				Global.movement_action.none:
					match rotation_mode:
							Global.rotation_mode.velocity_direction: 
								if (IsMoving and InputIsMoving) or (get_real_velocity() * Vector3(1.0,0.0,1.0)).length() > 0.5:
									stop_rotating_in_place() #Moving so stop the rotate in place
									smooth_character_rotation(velocity,calc_grounded_rotation_rate(),delta)
							Global.rotation_mode.looking_direction:
								if (IsMoving and InputIsMoving) or (get_real_velocity() * Vector3(1.0,0.0,1.0)).length() > 0.5:
									stop_rotating_in_place() #Moving so stop the rotate in place
									smooth_character_rotation(-$CameraRoot.HObject.transform.basis.z if gait != Global.gait.sprinting else velocity,calc_grounded_rotation_rate(),delta)
								else:
									if InputIsMoving == false:
										var CameraAngle = rad2deg($CameraRoot.HObject.rotation.y) +180
										var MeshAngle = rad2deg(mesh_ref.rotation.y)
										if abs(CameraAngle - MeshAngle) > 90.0:
											if IsRotating == false:
												rotate_in_place(CameraAngle,MeshAngle)
							Global.rotation_mode.aiming:
								if gait == Global.gait.sprinting: # character can't sprint while aiming
									gait = Global.gait.running
								if (IsMoving and InputIsMoving) or (get_real_velocity() * Vector3(1.0,0.0,1.0)).length() > 0.5:
									stop_rotating_in_place() #Moving so stop the rotate in place
									smooth_character_rotation(-$CameraRoot.HObject.transform.basis.z,calc_grounded_rotation_rate(),delta)
								else:
									if InputIsMoving == false:
										var CameraAngle = rad2deg($CameraRoot.HObject.rotation.y) +180
										var MeshAngle = rad2deg(mesh_ref.rotation.y)
										if abs(CameraAngle - MeshAngle) > 90.0:
											if IsRotating == false:
												rotate_in_place(CameraAngle,MeshAngle)
				Global.movement_action.rolling:
					if InputIsMoving == true:
						smooth_character_rotation(InputAcceleration ,2.0,delta)
						
		
		Global.movement_state.in_air:
			#------------------ Rotate Character Mesh In Air ------------------#
			stop_rotating_in_place()
			match rotation_mode:
					Global.rotation_mode.velocity_direction: 
						smooth_character_rotation(velocity if (get_real_velocity() * Vector3(1.0,0.0,1.0)).length() > 1.0 else  -$CameraRoot.HObject.transform.basis.z,5.0,delta)
					Global.rotation_mode.looking_direction:
						smooth_character_rotation(velocity if (get_real_velocity() * Vector3(1.0,0.0,1.0)).length() > 1.0 else  -$CameraRoot.HObject.transform.basis.z,5.0,delta)
					Global.rotation_mode.aiming:
						smooth_character_rotation(-$CameraRoot.HObject.transform.basis.z ,15.0,delta)
			#------------------ Mantle Check ------------------#
			if InputIsMoving == true:
				mantle_check()
		Global.movement_state.mantling:
			pass
		Global.movement_state.ragdoll:
			pass
	

	#------------------ Crouch ------------------#
	if stance == Global.stance.crouching:
		bonker.transform.origin.y -= crouch_switch_speed * delta
		collision_shape_ref.shape.height -= crouch_switch_speed * delta /2
	elif stance == Global.stance.standing and not head_bonked:
		bonker.transform.origin.y += crouch_switch_speed * delta 
		collision_shape_ref.shape.height += crouch_switch_speed * delta /2
		
	bonker.transform.origin.y = clamp(bonker.transform.origin.y,0.5,1.0)
	collision_shape_ref.shape.height = clamp(collision_shape_ref.shape.height,crouch_height,default_height)
	

	#------------------ Gravity ------------------#
	if is_flying == false:
		velocity.y =  lerp(velocity.y,vertical_velocity.y - get_floor_normal().y,delta * gravity)
		move_and_slide()
		
	if is_on_floor() and is_flying == false:
		movement_state = Global.movement_state.grounded 
		vertical_velocity = -get_floor_normal() * 10
	else:
		movement_state = Global.movement_state.in_air
		vertical_velocity += Vector3.DOWN * gravity * delta
#		if vertical_velocity < -20:
#			roll()
	if is_on_ceiling():
		vertical_velocity.y = 0




func smooth_character_rotation(Target:Vector3,nodelerpspeed,delta):
	mesh_ref.rotation.y = lerp_angle(mesh_ref.rotation.y, atan2(Target.x,Target.z) , delta * nodelerpspeed)
	

func calc_grounded_rotation_rate():
	
	if InputIsMoving == true:
		match gait:
			Global.gait.walking:
				return lerp(current_movement_data.idle_rotation_rate,current_movement_data.walk_rotation_rate, Global.map_range_clamped((get_real_velocity() * Vector3(1.0,0.0,1.0)).length(),0.0,current_movement_data.walk_speed,0.0,1.0)) * clamp(AimRate_H,1.0,3.0)
			Global.gait.running:
				return lerp(current_movement_data.walk_rotation_rate,current_movement_data.run_rotation_rate, Global.map_range_clamped((get_real_velocity() * Vector3(1.0,0.0,1.0)).length(),current_movement_data.walk_speed,current_movement_data.run_speed,1.0,2.0)) * clamp(AimRate_H,1.0,3.0)
			Global.gait.sprinting:
				return lerp(current_movement_data.run_rotation_rate,current_movement_data.sprint_rotation_rate,  Global.map_range_clamped((get_real_velocity() * Vector3(1.0,0.0,1.0)).length(),current_movement_data.run_speed,current_movement_data.sprint_speed,2.0,3.0)) * clamp(AimRate_H,1.0,2.5)
	else:
		return current_movement_data.idle_rotation_rate * clamp(AimRate_H,1.0,3.0)

var IsRotating = false :
	set(New):
		IsRotating = New
		if IsRotating:
			anim_ref.set("parameters/Turn/blend_amount" , 1)
		else:
			anim_ref.set("parameters/Turn/blend_amount" , 0)
	get: return IsRotating
func rotate_in_place(CameraAngle,MeshAngle):
	if abs(CameraAngle - MeshAngle) > 90:
		IsRotating = true
		var RotatingTween := create_tween()
		var NewRotation = mesh_ref.rotation.y + deg2rad(90 if CameraAngle - MeshAngle > 0 else -90)
		anim_ref.set("parameters/RightOrLeft/blend_amount" ,0 if CameraAngle - MeshAngle > 0 else 1)
		if IsRotating:
			RotatingTween.tween_property(mesh_ref,"rotation",Vector3(mesh_ref.rotation.x,NewRotation,mesh_ref.rotation.z),1.0667).set_ease(Tween.EASE_IN_OUT)
		RotatingTween.tween_callback(stop_rotating_in_place)
func stop_rotating_in_place():
	IsRotating = false

func ik_look_at(position: Vector3):
	if $LookAtObject:
		$LookAtObject.position = position


var PrevVelocity :Vector3
func add_movement_input(direction: Vector3, Speed: float , Acceleration: float):
	if is_flying == false:
		velocity.x = lerp(velocity.x, direction.x * Speed, Acceleration * get_physics_process_delta_time())
		velocity.z = lerp(velocity.z, direction.z * Speed, Acceleration * get_physics_process_delta_time())
	else:
		set_velocity(get_velocity().lerp(direction * Speed, Acceleration * get_physics_process_delta_time()))
		move_and_slide()
	InputVelocity = Speed * direction
	InputIsMoving = Speed > 0.0
	InputAcceleration = Acceleration * direction
	#
	ActualAcceleration = (velocity - PrevVelocity) / (Acceleration * get_physics_process_delta_time())
	PrevVelocity = velocity
	#
	
	#tiltCharacterMesh
#	if tilt == true:
#
#		tiltVector = (ActualAcceleration * direction).cross(Vector3.UP)
#		print(direction)
#		#mesh_ref.rotation.x = lerp(mesh_ref.rotation.x,tiltVector.x/5,Acceleration * get_physics_process_delta_time())
#		mesh_ref.rotation.z = lerp(mesh_ref.rotation.z,tiltVector.z/5,Acceleration * get_physics_process_delta_time())
	#



func mantle_check():
	pass

func jump():
	vertical_velocity = Vector3.UP * jump_magnitude



