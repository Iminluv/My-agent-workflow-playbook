.PHONY: help install install-copy verify test status scaffold-project

help:
	@echo "Antigravity Multi-Agent Workflow Management (Agent-test)"
	@echo ""
	@echo "Available commands:"
	@echo "  make install            - Symlink rules, agents, hooks, and scripts to ~/.gemini/config/plugins/ag-kit/"
	@echo "  make install-copy       - Static copy rules, agents, hooks, and scripts to Antigravity directory"
	@echo "  make verify             - Verify integrity of repository and installed rules, agents, hooks, and scripts"
	@echo "  make test               - Verify repository integrity and run Node.js test suite (tests/*.mjs)"
	@echo "  make scaffold-project   - Bootstrap .agents/ (knowledge & workflows) to TARGET=<dir>"
	@echo "  make status             - Check git working directory status"
	@echo ""

install:
	@chmod +x scripts/install.sh scripts/verify.sh scripts/scaffold.sh scripts/verify-deliverable.sh
	@./scripts/install.sh

install-copy:
	@chmod +x scripts/install.sh scripts/verify.sh scripts/scaffold.sh scripts/verify-deliverable.sh
	@./scripts/install.sh --copy

verify:
	@chmod +x scripts/verify.sh
	@./scripts/verify.sh

test:
	@chmod +x scripts/verify.sh scripts/verify-deliverable.sh
	@./scripts/verify.sh --repo
	@set -- tests/*.mjs; \
	if [ -e "$$1" ]; then \
		node --test "$$@"; \
	else \
		echo "No tests/*.mjs files found; skipping node --test."; \
	fi

scaffold-project:
	@chmod +x scripts/scaffold.sh
	@./scripts/scaffold.sh $(TARGET)

status:
	@git status -s
