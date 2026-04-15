Grub Integration
================

Holo uses grub as its stage 2 bootloader (the details of the entire
boot process are documented elsewhere - see the final section of this
file).

Here we will document how we use grub in Holo and where the configuration
and so forth for grub is driven from.

Components
---------------

Note that these scripts also do other things. We are concerned here only
with how they interact with grub:
   
 * misc/bin/steamos-finalize-install
   * different mode (obsolete?) if /boot is a mount point
   * grub/libexec/holo-grub-mkimage (as grub-mkimage)
   * grub/bin/update-grub
   
 * grub/systemd/holo-install-grub.service
   * If either grub.cfg or grubx64.efi are missing from /efi
     * grub/libexec/holo-grub-install (invoked as as /usr/bin/grub-install)
     * grub/bin/update-grub

 * grub/bin/update-grub
   * EXTERNAL DEPENDENCY /usr/share/grub/grub-mkconfig_lib
   * grub-mkconfig
     * write grub config to /efi/EFI/SteamOS/grub.cfg
     * This used to be conditional on whether /boot was ro or rw but
       the turned out to add complexity & fragility for no gain.

 * grub/libexec/holo-grub-mkearlyconfig
   * TODO - this may be obsolete, or at least simplifiable now
   * create a stub config for the default location to point to the real config

 * grub/libexec/holo-grub-install
   * EXTERNAL DEPENDENCY /usr/lib/grub-install
     * targets /efi
     * omits the nvram bootloader variable
     * uses holo-grub-mkimage as grub-mkimage

 * grub/libexec/holo-grub-mkimage
   * calls holo-grub-mkearlyconfig
     * TODO - is the above obsolete now the config is always on /efi?
   * EXTERNAL DEPENDENCY /usr/lib/grub-mkimage
   * writes grub image to /efi by default

