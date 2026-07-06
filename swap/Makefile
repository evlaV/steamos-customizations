include ../common.mk

SERVICES_IN := $(wildcard systemd/*.service.in) $(wildcard hibernation/*.service.in)
SERVICES := $(patsubst %.in,%,$(SERVICES_IN))
SWAPS_IN := $(wildcard systemd/*.swap.in)
SWAPS := $(patsubst %.in,%,$(SWAPS_IN))
HIBERNATE_SCRIPTS := $(wildcard hibernation/*.sh)
UNITS := $(SERVICES) $(SWAPS)
CLEANABLE := $(SERVICES)

all: $(SERVICES) $(SWAPS)

install: all
	install -d $(DESTDIR)$(systemdunitsdir)
	install -m 0644 $(UNITS) $(DESTDIR)$(systemdunitsdir)
	install -d $(DESTDIR)$(libexecdir)/steamos
	install -m 0755 $(HIBERNATE_SCRIPTS) $(DESTDIR)$(libexecdir)/steamos
	$(call enable-systemd-units,$(DESTDIR)$(systemdunitsdir),$(notdir $(UNITS)))
