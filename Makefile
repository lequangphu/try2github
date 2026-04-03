.PHONY: install uninstall test clean

INSTALL_DIR := $(HOME)/.local/share/try2github
SHELL := $(shell echo $$SHELL | xargs basename)

install:
	@echo "Installing try2github..."
	@echo "Prerequisite: gem install try-cli (tobi/try)"
	@mkdir -p $(INSTALL_DIR)
	@cp -r lib shell $(INSTALL_DIR)/
	@echo "Installed to $(INSTALL_DIR)"
	@echo ""
	@echo "Add to your shell RC:"
	@echo "  eval \"\$$(try init ~/src/tries)\"     # tobi/try"
	@echo "  source $(INSTALL_DIR)/shell/try2github.$(SHELL)  # try2github"

uninstall:
	@rm -rf $(INSTALL_DIR)
	@echo "Uninstalled try2github"

test:
	@echo "Running tests..."
	@bash test/test.sh

clean:
	@rm -f lib/*.bak shell/*.bak
	@echo "Cleaned backup files"
