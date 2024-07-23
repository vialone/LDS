KERNEL_VERSION_MASK=6.x
KERNEL_VERSION=6.9.10
KERNEL_CONFIG=ncurses # possible values: gtk, ncurses
INITRAMFS=$PWD/initramfs.img # it's better not to touch this parameter
GRUB_CONFIG=$WORKDIR/grub.cfg
# DEBUG_MODE=true # uncomment for additional logs
# INITRDFS=squashfs # uncomment to use SquashFS instead of CPIO
