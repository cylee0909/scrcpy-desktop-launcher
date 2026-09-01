PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
PROGRAM := scrcpy-desktop-launcher
ALIASES := sc scrcpy-desktop

.PHONY: install uninstall check test

install:
	@if ! command -v macism >/dev/null 2>&1; then \
		if [ "$$(uname -s)" != Darwin ]; then \
			echo "warning: macism is only available on macOS; skipping" >&2; \
		elif ! command -v brew >/dev/null 2>&1; then \
			echo "error: Homebrew is required to install macism" >&2; \
			exit 1; \
		else \
			echo "Installing macism for automatic macOS input-source switching..."; \
			brew install laishulu/homebrew/macism; \
		fi; \
	fi
	install -d "$(DESTDIR)$(BINDIR)"
	install -m 755 "$(PROGRAM)" "$(DESTDIR)$(BINDIR)/$(PROGRAM)"
	@for alias in $(ALIASES); do \
		path="$(DESTDIR)$(BINDIR)/$$alias"; \
		if [ -L "$$path" ] && [ "$$(readlink "$$path")" = "$(PROGRAM)" ]; then \
			:; \
		elif [ -e "$$path" ] || [ -L "$$path" ]; then \
			echo "warning: $(BINDIR)/$$alias already exists; shortcut not installed" >&2; \
		else \
			ln -s "$(PROGRAM)" "$$path"; \
		fi; \
	done

uninstall:
	@for alias in $(ALIASES); do \
		path="$(DESTDIR)$(BINDIR)/$$alias"; \
		if [ -L "$$path" ] && [ "$$(readlink "$$path")" = "$(PROGRAM)" ]; then \
			rm -f "$$path"; \
		fi; \
	done
	rm -f "$(DESTDIR)$(BINDIR)/$(PROGRAM)"

check:
	zsh -n "$(PROGRAM)" tests/test.sh
	zsh tests/test.sh

test: check
