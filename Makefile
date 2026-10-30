# ==============================================================================
# NOT: Repoyu klonlayan kişi kendi bilgisayarındaki Godot 4 çalıştırılabilir (binary)
# dosyasının yolunu aşağıdaki GODOT_BIN değişkenine yazmalıdır veya komut satırından
# parametre olarak geçmelidir.
#
# Varsayılan Örnek Yollar:
#   macOS (Standart):  /Applications/Godot.app/Contents/MacOS/Godot
#   Linux / PATH:      godot
#   Windows:           C:/Godot/Godot_v4.x.exe
#
# Parametre ile çalıştırma örneği:
#   make run GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
# ==============================================================================
GODOT_BIN ?= godot
PROJECT_PATH ?= sample_project

.PHONY: run test test-commands test-phase1 test-art help

run:
	$(GODOT_BIN) --path $(PROJECT_PATH)

test:
	$(GODOT_BIN) --headless --path $(PROJECT_PATH) --script res://scripts/tests/test_selection_and_commands.gd
	$(GODOT_BIN) --headless --path $(PROJECT_PATH) --script res://scripts/tests/test_phase1_validation.gd
	$(GODOT_BIN) --headless --path $(PROJECT_PATH) --script res://scripts/tests/test_gather_deposit.gd
	$(GODOT_BIN) --headless --path $(PROJECT_PATH) --script res://scripts/tests/test_full_rts_suite.gd

test-commands:
	$(GODOT_BIN) --headless --path $(PROJECT_PATH) --script res://scripts/tests/test_selection_and_commands.gd

test-phase1:
	$(GODOT_BIN) --headless --path $(PROJECT_PATH) --script res://scripts/tests/test_phase1_validation.gd

test-art:
	$(GODOT_BIN) --headless --path $(PROJECT_PATH) --script res://scripts/tests/test_building_art_integration.gd

help:
	@echo "Pocket Empires 3D Makefile"
	@echo "  make run           - Oyunu başlatır (Örn: make run GODOT_BIN=...)"
	@echo "  make test          - Tüm otomatik testleri headless olarak çalıştırır"
	@echo "  make test-commands - Birim seçimi ve komut testlerini çalıştırır"
	@echo "  make test-phase1   - Phase 1 doğrulama testlerini çalıştırır"
	@echo "  make test-art      - Bina görsel entegrasyon testlerini çalıştırır"
