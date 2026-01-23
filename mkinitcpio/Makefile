include ../common.mk

GEN_HOOKS_IN := initcpio/hooks/holo.in
HOOKS_IN := $(GEN_HOOKS_IN)
HOOKS := $(patsubst %.in,%,$(HOOKS_IN))
GEN_INSTS_IN := initcpio/install/holo.in
INSTS_IN := $(filter-out $(GEN_INSTS_IN),$(wildcard initcpio/install/*.in))
INSTS := $(patsubst %.in,%,$(INSTS_IN) $(GEN_INSTS_IN))
CONFS := $(wildcard mkinitcpio.conf.d/*)
CLEANABLE := $(GEN_HOOKS_IN) $(HOOKS) $(GEN_INSTS_IN) $(INSTS)

initcpio/hooks/holo.in: initcpio/hooks/holo.tmpl ../initrd/holo-etc-overlay.ash \
		../initrd/holo-factory-reset.ash ../initrd/holo-udev-rules.ash \
		../initrd/holo-var-lib-modules.ash ../initrd/holo-var.ash

	cat $< | ../initrd/inline-file.sh "@HOLO_ETC_OVERLAY@" ../initrd/holo-etc-overlay.ash | \
		../initrd/inline-file.sh "@HOLO_FACTORY_RESET@" ../initrd/holo-factory-reset.ash | \
		../initrd/inline-file.sh "@HOLO_UDEV_RULES@" ../initrd/holo-udev-rules.ash | \
		../initrd/inline-file.sh "@HOLO_VAR_LIB@" ../initrd/holo-var-lib-modules.ash | \
		../initrd/inline-file.sh "@HOLO_VAR@" ../initrd/holo-var.ash | \
		sed -e 's|@INFO@|msg|g;s|@WARN@|err|g;s|@WAIT_FOR_DEV@|poll_device|g' > $@

initcpio/install/holo.in: initcpio/install/holo.tmpl ../initrd/holo-files.bash
	../initrd/inline-file.sh "@HOLO_BINARIES@" $^ > $@

all: $(GEN_HOOKS_IN) $(HOOKS) $(GEN_INSTS_IN) $(INSTS)

install: all
	install -d $(DESTDIR)$(libdir)/initcpio/hooks
	install -m 0644 $(HOOKS) $(DESTDIR)$(libdir)/initcpio/hooks
	install -d $(DESTDIR)$(libdir)/initcpio/install
	install -m 0644 $(INSTS) $(DESTDIR)$(libdir)/initcpio/install
	install -d $(DESTDIR)$(sysconfdir)/mkinitcpio.conf.d
	install -m 0644 $(CONFS) $(DESTDIR)$(sysconfdir)/mkinitcpio.conf.d/
