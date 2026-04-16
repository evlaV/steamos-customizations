include ../common.mk

BINARIES_IN := $(wildcard bin/*.in)
BINARIES := $(patsubst %.in,%,$(BINARIES_IN))
# This setuid wrapper exposes a limited subset of holo-bootconf's
# functionality to unprivileged callers: specifically the set-mode
# actions used to configure the well-known boot requests such as:
# reboot reboot-other update (for example). This allows things like
# steam and the plasma UI to request those update modes safely.
SUIDBINS := bin/holo-set-bootmode
COMPLETIONS := $(wildcard completions/*)
SERVICES_IN := $(wildcard systemd/*.service.in)
SERVICES := $(patsubst %.in,%,$(SERVICES_IN))
CLEANABLE := $(BINARIES) $(SERVICES) $(SUIDBINS)
BOOTMODES := $(patsubst %,steamos-%,halt poweroff reboot)
ALIAS     := $(sbindir)/holo-alias

all: $(BINARIES) $(SERVICES) $(SUIDBINS)

bin/holo-set-bootmode: bin/holo-set-bootmode.c
	$(CC) -Wall -Wextra $^ -DBINDIR=\"$(bindir)\" -o $@

aliases:
	@install -d $(DESTDIR)$(sbindir)
	@(for X in $(BOOTMODES); \
	  do ln -svf $(ALIAS) $(DESTDIR)$(sbindir)/$$X; done)
	@ln -svf $(ALIAS) $(DESTDIR)$(sbindir)/steamos-set-bootmode

install: all aliases
	install -d $(DESTDIR)$(sbindir)
	install -m 0755 $(BINARIES) $(DESTDIR)$(sbindir)
	for i in holo-halt holo-poweroff; do \
		ln -sfv holo-reboot $(DESTDIR)$(sbindir)/$$i; \
	done
	install -m 4755 $(SUIDBINS) $(DESTDIR)$(sbindir)
	install -d $(DESTDIR)$(completionsdir)
	install -m 0644 $(COMPLETIONS) $(DESTDIR)$(completionsdir)
	for i in holo-halt holo-poweroff; do \
		ln -sfv holo-reboot $(DESTDIR)$(completionsdir)/$$i; \
	done
	install -d $(DESTDIR)$(systemdunitsdir)
	install -m 644 $(SERVICES) $(DESTDIR)$(systemdunitsdir)
	$(call enable-systemd-units,$(DESTDIR)$(systemdunitsdir),$(notdir $(SERVICES)))
