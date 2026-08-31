PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

.PHONY: install uninstall check test

install:
	install -d "$(DESTDIR)$(BINDIR)"
	install -m 755 scrcpy-desktop "$(DESTDIR)$(BINDIR)/scrcpy-desktop"
	@if [ -L "$(DESTDIR)$(BINDIR)/sc" ] && [ "$$(readlink "$(DESTDIR)$(BINDIR)/sc")" = scrcpy-desktop ]; then \
		:; \
	elif [ -e "$(DESTDIR)$(BINDIR)/sc" ] || [ -L "$(DESTDIR)$(BINDIR)/sc" ]; then \
		echo "warning: $(BINDIR)/sc already exists; shortcut not installed" >&2; \
	else \
		ln -s scrcpy-desktop "$(DESTDIR)$(BINDIR)/sc"; \
	fi

uninstall:
	@if [ -L "$(DESTDIR)$(BINDIR)/sc" ] && [ "$$(readlink "$(DESTDIR)$(BINDIR)/sc")" = scrcpy-desktop ]; then \
		rm -f "$(DESTDIR)$(BINDIR)/sc"; \
	fi
	rm -f "$(DESTDIR)$(BINDIR)/scrcpy-desktop"

check:
	zsh -n scrcpy-desktop tests/test.sh
	zsh tests/test.sh

test: check
