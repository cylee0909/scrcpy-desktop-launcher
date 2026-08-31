PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
PROGRAM := scrcpy-desktop-launcher
ALIASES := sc scrcpy-desktop

.PHONY: install uninstall check test

install:
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
