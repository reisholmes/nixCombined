# Makefile
# Convenience commands for NixOS/nix-darwin/home-manager operations

# Variables (can be overridden)
HOSTNAME := $(shell hostname -s)
USER := $(shell whoami)
SYSTEM := $(shell uname -s)
FLAKE := .#$(HOSTNAME)
EXPERIMENTAL := --extra-experimental-features "nix-command flakes"

.PHONY: help darwin home nixos update gc check \
	install-nix install-nix-darwin bootstrap-darwin bootstrap-home \
	darwin-rebuild nixos-rebuild home-manager-switch nix-gc flake-update flake-check

help:
	@echo "Common Commands:"
	@echo "  make darwin    - Rebuild Darwin (macOS) configuration"
	@echo "  make home      - Rebuild Home Manager configuration"
	@echo "  make nixos     - Rebuild NixOS configuration"
	@echo "  make update    - Update all flake inputs"
	@echo "  make gc        - Run garbage collection"
	@echo "  make check     - Validate flake configuration"
	@echo ""
	@echo "Bootstrap Commands (new machines):"
	@echo "  make bootstrap-darwin - Install nix-darwin and switch"
	@echo "  make bootstrap-home   - Install home-manager and switch"
	@echo ""
	@echo "Legacy Commands (compatibility):"
	@echo "  make darwin-rebuild      - Same as 'make darwin'"
	@echo "  make home-manager-switch - Same as 'make home'"
	@echo "  make nixos-rebuild       - Same as 'make nixos'"
	@echo "  make nix-gc              - Same as 'make gc'"
	@echo "  make flake-update        - Same as 'make update'"
	@echo "  make flake-check         - Same as 'make check'"
	@echo ""
	@echo "Current Environment:"
	@echo "  Hostname: $(HOSTNAME)"
	@echo "  User:     $(USER)"
	@echo "  System:   $(SYSTEM)"
	@echo "  Flake:    $(FLAKE)"

# Modern short commands
darwin:
	@echo "Rebuilding Darwin configuration for $(HOSTNAME)..."
	darwin-rebuild switch --flake $(FLAKE)
	@echo ""
	@echo "Showing package differences..."
	@nvd diff $$(ls -d1v /nix/var/nix/profiles/system-*-link 2>/dev/null | tail -2 | head -1) $$(ls -d1v /nix/var/nix/profiles/system-*-link 2>/dev/null | tail -1) 2>/dev/null || echo "Note: nvd not available or insufficient generations for comparison"

home:
	@echo "Rebuilding Home Manager configuration for $(USER)@$(HOSTNAME)..."
	home-manager switch --flake .#$(USER)@$(HOSTNAME) --impure -b backup
	@echo ""
	@echo "Showing package differences..."
	@nvd diff $$(home-manager generations | head -2 | tail -1 | awk '{print $$7}') $$(home-manager generations | head -1 | awk '{print $$7}') 2>/dev/null || echo "Note: nvd not available or insufficient generations for comparison"

nixos:
	@echo "Rebuilding NixOS configuration for $(HOSTNAME)..."
	sudo nixos-rebuild switch --flake $(FLAKE)
	@echo ""
	@echo "Showing package differences..."
	@nvd diff /nix/var/nix/profiles/system-{$$(ls -v /nix/var/nix/profiles/ | grep 'system-.*-link' | tail -2 | head -1 | sed 's/system-\(.*\)-link/\1/'),$($(ls -v /nix/var/nix/profiles/ | grep 'system-.*-link' | tail -1 | sed 's/system-\(.*\)-link/\1/'))}-link 2>/dev/null || echo "Note: nvd not available or insufficient generations for comparison"

update:
	@echo "Updating flake inputs..."
	nix flake update
	@echo ""
	@echo "✓ Flake inputs updated!"
	@echo ""
	@echo "Review changes with: git diff flake.lock"
	@echo ""
	@echo "Rebuild your system to apply updates:"
	@if [ "$(SYSTEM)" = "Darwin" ]; then \
		echo "  make darwin"; \
	else \
		echo "  make home    (for home-manager)"; \
		echo "  make nixos   (for NixOS system)"; \
	fi

gc:
	@echo "Running garbage collection..."
	nix-collect-garbage -d
	@echo ""
	@echo "✓ Garbage collection complete!"
	@if [ "$(SYSTEM)" = "Darwin" ]; then \
		echo ""; \
		echo "Rebuilding Darwin after GC..."; \
		darwin-rebuild switch --flake $(FLAKE); \
	else \
		echo ""; \
		echo "Tip: Run 'make home' or 'make nixos' to rebuild if needed."; \
	fi

check:
	@echo "Validating flake configuration..."
	nix flake check
	@echo ""
	@echo "✓ Flake validation passed!"

# Bootstrap commands
install-nix:
	@echo "Installing Nix package manager..."
	curl -L https://nixos.org/nix/install | sh -s -- --daemon
	@echo ""
	@echo "✓ Nix installation complete!"
	@echo ""
	@echo "You may need to restart your shell or source the Nix profile:"
	@echo "  . /etc/profile"

install-nix-darwin:
	@echo "Installing nix-darwin..."
	nix run nix-darwin $(EXPERIMENTAL) -- switch --flake $(FLAKE)
	@echo ""
	@echo "✓ nix-darwin installation complete!"

bootstrap-darwin: install-nix install-nix-darwin
	@echo ""
	@echo "✓ macOS bootstrap complete!"
	@echo "Use 'make darwin' for future rebuilds."

bootstrap-home:
	@echo "Bootstrapping home-manager for $(USER)@$(HOSTNAME)..."
	nix-shell -p home-manager --run "home-manager switch --flake .#$(USER)@$(HOSTNAME) --impure -b backup"
	@echo ""
	@echo "✓ home-manager bootstrap complete!"
	@echo "Use 'make home' for future rebuilds."

# Legacy command aliases (for backwards compatibility)
darwin-rebuild: darwin
nixos-rebuild: nixos
home-manager-switch: home
nix-gc: gc
flake-update: update
flake-check: check
