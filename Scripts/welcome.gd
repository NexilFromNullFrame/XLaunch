extends Control

@onready var gamer_icon: TextureRect = $GamerIcon

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$LogIn.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	for i in AccountManager.profiles.size():
		var gamerpic = AccountManager.current_profile.face_texture
		if gamerpic.get_size() < Vector2(1080.0, 1080.0):
			$GamerIcon/SmallIconHelper.visible = true
			$GamerIcon/SmallIconHelper/SmallGamerIcon.texture = gamerpic
		else:
			gamer_icon.texture = gamerpic
		self.get_node("WelcomeUser/GamerTag").text = AccountManager.current_profile.display_name


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	$AnimationPlayer.play("WelcomeOut")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://scenes/home_screen.tscn")
