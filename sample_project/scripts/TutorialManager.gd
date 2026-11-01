class_name TutorialManager
extends Node

signal tutorial_completed

enum Step {
	CAMERA_MOVE,
	SELECT_VILLAGER,
	GATHER_WOOD,
	GATHER_GOLD,
	GATHER_STONE,
	BUILD_HOUSE,
	TRAIN_SOLDIER,
	ADVANCE_AGE,
	COMPLETED
}

var current_step: Step = Step.CAMERA_MOVE
var game: GameController3D = null
var initial_cam_pos: Vector3 = Vector3.ZERO
var step_timer: float = 0.0

const TUTORIAL_TEXTS = {
	Step.CAMERA_MOVE: "Adım 1/8: Haritayı Keşfet!\nParmağını veya fareni sürükleyerek kuşbakışı diorama haritasında gezin.",
	Step.SELECT_VILLAGER: "Adım 2/8: İşçini Seç!\nÜzerine dokunarak bir köy işçisini seç. (Aynı türdeki tüm birimleri seçmek için çift tıkla)",
	Step.GATHER_WOOD: "Adım 3/8: Odun Topla!\nİşçi seçiliyken yakındaki bir ağaca dokun. Odun toplayıp ana üsse taşıyacak.",
	Step.GATHER_GOLD: "Adım 4/8: Altın Kaz!\nParıldayan altın madeni cevherine dokunarak altın rezervi topla.",
	Step.GATHER_STONE: "Adım 5/8: Taş Çıkar!\nGri renkli granit taş ocağına dokunarak taş rezervi çıkar.",
	Step.BUILD_HOUSE: "Adım 6/8: Ev İnşa Et!\nSol alttaki [İNŞAAT] menüsünü aç, [EV] seç ve yeşil alana yerleştir.",
	Step.TRAIN_SOLDIER: "Adım 7/8: Asker Eğit!\nKışla veya Ana Üs seçip bir askeri birlik (Kılıçlı/Mızrakçı/Okçu) yetiştir.",
	Step.ADVANCE_AGE: "Adım 8/8: Hisar Çağı'na Yüksel!\nAna Üs'ten [Hisar Çağı] araştırmasını başlat, Demirci'de silahlarını güçlendir ve düşmanı fethet!",
	Step.COMPLETED: "Tebrikler! Temel RTS mekaniklerini başarıyla tamamladın. Şimdi sefere hazırsın!"
}

func start_tutorial(game_ctrl: GameController3D) -> void:
	game = game_ctrl
	current_step = Step.CAMERA_MOVE
	dismissed = false
	if is_instance_valid(game.ui_manager) and game.ui_manager.has_signal("objective_dismissed") \
			and not game.ui_manager.objective_dismissed.is_connected(_on_objective_dismissed):
		game.ui_manager.objective_dismissed.connect(_on_objective_dismissed)
	initial_cam_pos = game.camera.global_position
	_show_current_step()

func _show_current_step() -> void:
	if game == null or not is_instance_valid(game.ui_manager) or dismissed:
		return
	var text: String = TUTORIAL_TEXTS.get(current_step, "")
	if current_step == Step.COMPLETED:
		game.ui_manager.hide_objective()
		game.ui_manager.notify_banner(text, Color(0.35, 0.75, 0.35))
		return
	# "Adım 3/8: Odun Topla!\n<what to do>" -> card: "GÖREV 3/8", "Odun Topla", what to do
	var lines := text.split("\n", false, 1)
	var head := lines[0]
	var step_txt := ""
	var title := head
	if head.contains(":"):
		step_txt = head.get_slice(":", 0).replace("Adım", "Görev").strip_edges()
		title = head.substr(head.find(":") + 1).strip_edges()
	title = title.trim_suffix("!")
	game.ui_manager.show_objective(step_txt, title, lines[1].strip_edges() if lines.size() > 1 else "")

## The player closed the objective card: no more tutorial cards this match.
var dismissed := false

func _on_objective_dismissed() -> void:
	dismissed = true

## Hides the tutorial for the rest of the match (the objective card's ×, tests).
func stop_tutorial() -> void:
	dismissed = true
	if game != null and is_instance_valid(game.ui_manager):
		game.ui_manager.hide_objective()

func check_progress() -> void:
	if game == null or not game.is_game_active:
		return

	match current_step:
		Step.CAMERA_MOVE:
			if game.camera.global_position.distance_to(initial_cam_pos) > 6.0:
				_advance_step(Step.SELECT_VILLAGER)

		Step.SELECT_VILLAGER:
			for u in game.selected_units:
				if is_instance_valid(u) and u.unit_type == Unit3D.UnitType.VILLAGER:
					_advance_step(Step.GATHER_WOOD)
					break

		Step.GATHER_WOOD:
			for u in game.units:
				if is_instance_valid(u) and u.team == 0 and u.state == Unit3D.State.GATHERING and u.resource_type == "wood":
					_advance_step(Step.GATHER_GOLD)
					break

		Step.GATHER_GOLD:
			for u in game.units:
				if is_instance_valid(u) and u.team == 0 and u.state == Unit3D.State.GATHERING and u.resource_type == "gold":
					_advance_step(Step.GATHER_STONE)
					break

		Step.GATHER_STONE:
			for u in game.units:
				if is_instance_valid(u) and u.team == 0 and u.state == Unit3D.State.GATHERING and u.resource_type == "stone":
					_advance_step(Step.BUILD_HOUSE)
					break

		Step.BUILD_HOUSE:
			var houses = 0
			for b in game.buildings:
				if is_instance_valid(b) and b.team == 0 and b.building_type == Building3D.BuildingType.HOUSE:
					houses += 1
			if houses > 0:
				_advance_step(Step.TRAIN_SOLDIER)

		Step.TRAIN_SOLDIER:
			if game.trained_count > 0:
				_advance_step(Step.ADVANCE_AGE)

		Step.ADVANCE_AGE:
			if game.team_age.get(0, 1) >= 2:
				_advance_step(Step.COMPLETED)
				tutorial_completed.emit()

func _advance_step(next_step: Step) -> void:
	current_step = next_step
	SoundManager.play_sound("horn")
	_show_current_step()
