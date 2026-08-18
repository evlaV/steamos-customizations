include ../common.mk

UPOWER_CONFIG_SRC := $(wildcard conf.d/*)
UPOWER_CONFIG_DSTDIR := $(DESTDIR)$(sysconfdir)/UPower/UPower.conf.d/

all:

install: all
	install -d $(UPOWER_CONFIG_DSTDIR)
	install -m 0644 $(UPOWER_CONFIG_SRC) $(UPOWER_CONFIG_DSTDIR)
