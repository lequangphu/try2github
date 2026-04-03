.PHONY: install uninstall test clean

INSTALL_DIR := $(HOME)/.local/share/try2github
BIN_DIR := $(HOME)/.local/bin
SHELL := $(shell echo $$SHELL | xargs basename)

install:
	@echo "Installing try2github..."
	@mkdir -p $(INSTALL_DIR)
	@cp -r lib shell templates $(INSTALL_DIR)/
	@mkdir -p $(BIN_DIR)
	@echo '#!/bin/bash' > $(BIN_DIR)/try
	@echo 'export TRY2GITHUB_ROOT="$(INSTALL_DIR)"' >> $(BIN_DIR)/try
	@echo 'source "$(INSTALL_DIR)/lib/try2github.sh"' >> $(BIN_DIR)/try
	@echo 'TRY2GITHUB_AUTO_CD=1 try2github_try "$$@"' >> $(BIN_DIR)/try
	@chmod +x $(BIN_DIR)/try
	@echo '#!/bin/bash' > $(BIN_DIR)/promote
	@echo 'export TRY2GITHUB_ROOT="$(INSTALL_DIR)"' >> $(BIN_DIR)/promote
	@echo 'source "$(INSTALL_DIR)/lib/try2github.sh"' >> $(BIN_DIR)/promote
	@echo 'TRY2GITHUB_AUTO_CD=1 try2github_promote "$$@"' >> $(BIN_DIR)/promote
	@chmod +x $(BIN_DIR)/promote
	@echo '#!/bin/bash' > $(BIN_DIR)/repo
	@echo 'export TRY2GITHUB_ROOT="$(INSTALL_DIR)"' >> $(BIN_DIR)/repo
	@echo 'source "$(INSTALL_DIR)/lib/try2github.sh"' >> $(BIN_DIR)/repo
	@echo 'if [ $$# -eq 0 ]; then try2github_repo ls; else TRY2GITHUB_AUTO_CD=1 try2github_repo "$$@"; fi' >> $(BIN_DIR)/repo
	@chmod +x $(BIN_DIR)/repo
	@echo "Installed to $(INSTALL_DIR)"
	@echo "Binaries in $(BIN_DIR)"
	@echo "Add to your shell RC: source $(INSTALL_DIR)/shell/try2github.$(SHELL)"

uninstall:
	@rm -rf $(INSTALL_DIR)
	@rm -f $(BIN_DIR)/try $(BIN_DIR)/promote $(BIN_DIR)/repo $(BIN_DIR)/tries
	@echo "Uninstalled try2github"

test:
	@echo "Running tests..."
	@bash test/test.sh

clean:
	@rm -f lib/*.bak shell/*.bak
	@echo "Cleaned backup files"
