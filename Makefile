.PHONY: help install install-copy verify status scaffold-project

help:
	@echo "Antigravity Multi-Agent Workflow Management (Agent-test)"
	@echo ""
	@echo "Available commands:"
	@echo "  make install            - Symlink rules and agents to ~/.gemini/config/plugins/ag-kit/"
	@echo "  make install-copy       - Static copy rules and agents to Antigravity directory"
	@echo "  make verify             - Verify integrity of installed rules and agents"
	@echo "  make scaffold-project   - Bootstrap .agents/ (knowledge & workflows) to TARGET=<dir>"
	@echo "  make status             - Check git working directory status"
	@echo ""

install:
	@chmod +x scripts/install.sh scripts/verify.sh scripts/scaffold.sh
	@./scripts/install.sh

install-copy:
	@chmod +x scripts/install.sh scripts/verify.sh scripts/scaffold.sh
	@./scripts/install.sh --copy

verify:
	@chmod +x scripts/verify.sh
	@./scripts/verify.sh

scaffold-project:
	@chmod +x scripts/scaffold.sh
	@./scripts/scaffold.sh $(TARGET)

status:
	@git status -s
