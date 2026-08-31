PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

.PHONY: install uninstall check test

install:
	install -d "$(DESTDIR)$(BINDIR)"
	install -m 755 sc.sh "$(DESTDIR)$(BINDIR)/sc"

uninstall:
	rm -f "$(DESTDIR)$(BINDIR)/sc"

check:
	zsh -n sc.sh tests/test.sh
	zsh tests/test.sh

test: check
