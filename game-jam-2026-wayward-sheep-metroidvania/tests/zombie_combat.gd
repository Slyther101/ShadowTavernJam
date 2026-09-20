extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var hero = scene.get_node("Hero")
	var zombie = scene.get_node("Zombie")
	scene.get_node("Shadow").set_physics_process(false)
	await create_timer(2.0).timeout
	check(zombie.is_on_floor(), "Zombie should land on the level geometry")
	check(absf(zombie.global_position.x - zombie.home_x) > 1.0, "Zombie should patrol the level")
	# Isolate combat from the level geometry and input while retaining animation playback.
	scene.set_process(false)
	hero.set_physics_process(false)
	scene.get_node("Shadow").set_physics_process(false)
	zombie.set_physics_process(false)
	hero.global_position = Vector2(0, -2000)
	zombie.global_position = Vector2(28, -2019)
	await physics_frame
	zombie._update_behavior(0.016)
	check(zombie.state == &"Attack", "Nearby hero should trigger an attack")
	await create_timer(0.65).timeout
	check(hero.health == 4, "Bite should damage hero once after its windup")
	hero.take_damage(1)
	check(hero.health == 4, "Invulnerability should block repeated damage")
	await create_timer(1.2).timeout
	check(zombie.state == &"Idle", "Attack should finish and return to idle")
	hero.direction = 1.0
	hero._start_action(&"Attack")
	await create_timer(0.35).timeout
	check(zombie.health == 2, "Hero swing should damage zombie once")
	await create_timer(0.6).timeout
	check(zombie.state == &"Idle", "Damage reaction should finish")
	hero.direction = -1.0
	hero._start_action(&"Attack 2")
	await create_timer(0.5).timeout
	check(zombie.health == 2, "Attacks facing away should miss")
	zombie.attack_cooldown = 0.0
	zombie._update_behavior(0.016)
	hero.global_position.x = -200
	await create_timer(0.65).timeout
	check(hero.health == 4, "Leaving bite range during windup should dodge damage")
	await create_timer(1.2).timeout
	zombie.take_damage(2, hero.global_position)
	await create_timer(0.8).timeout
	check(not is_instance_valid(zombie), "Defeated zombie should be removed")
	hero.hurt_cooldown = 0.0
	hero.is_controled = false
	hero.take_damage(10)
	check(hero.health == 0 and hero.action_name == &"Die", "Lethal damage should start hero death even while controlling the shadow")
	await create_timer(1.0).timeout
	check(not hero.hero_animation.is_playing(), "Hero death animation should finish so the controller can restart the scene")
	print("Zombie combat checks: ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
