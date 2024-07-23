#!/bin/bash

set -e

DEBUG_MODE=false
WORKDIR=$PWD
PROCNUM=$(expr $(nproc) - 1)
INITRDFS=cpio
BUSYBOX=$WORKDIR/busybox

run() {
    if $DEBUG_MODE; then
        printf "[DEBUG] "
        printf "$PWD "
        echo "$@"
    fi
    $@
}

DISTRO=$(./getdistroname)

case $DISTRO in
    "debian")
        OVMF=/usr/share/ovmf/OVMF.fd
        ;;
    "arch")
        OVMF=/usr/share/ovmf/x64/OVMF.fd
        ;;
    *)
        OVMF=/usr/share/ovmf/OVMF.fd
        ;;
esac

source config.sh

download_kernel() {
    run wget https://cdn.kernel.org/pub/linux/kernel/v$KERNEL_VERSION_MASK/linux-$KERNEL_VERSION.tar.xz
    run tar xf linux-$KERNEL_VERSION.tar.xz
    run mv linux-$KERNEL_VERSION kernel
    run rm linux-$KERNEL_VERSION.tar.xz
}

build_kernel() {
    if [ ! -d kernel ]; then
        download_kernel
    fi
    run cd kernel
    run make -j$PROCNUM # --silent
    run cd ..
    run cp kernel/arch/x86/boot/bzImage vmlinuz
}

collect_initramfs() {
    if [ -d /tmp/lds/initrd ]; then
        rm -rf /tmp/lds/initrd
    fi
    run mkdir -p /tmp/lds/initrd/bin
    run cp -rf initrd/* /tmp/lds/initrd
    run cd /tmp/lds/initrd/bin
    cp $BUSYBOX .
    for link in $(./busybox --list); do
        run ln -s busybox $link
    done
    run cd $WORKDIR
}

build_initramfs_squashfs() {
    collect_initramfs
    cd /tmp/lds
    run mksquashfs initrd $INITRAMFS -no-strip -all-root -no-hardlinks -no-recovery
    run cd $WORKDIR
}

build_initramfs_cpio() {
    collect_initramfs
    cd /tmp/lds/initrd
    find . | cpio -o -H newc > $INITRAMFS
    run cd $WORKDIR
}

build_initramfs() {
    case $INITRDFS in
        "cpio")
            build_initramfs_cpio
            ;;
        "squashfs")
            build_initramfs_squashfs
            ;;
        *)
            echo "Unknown FS type: $INITRDFS. defaulting to cpio"
            build_initramfs_cpio
            ;;
    esac
}

build_grub() {
    if [ -d disk ]; then run rm -rf disk; fi
    run mkdir -p disk/boot/grub
    run cp $GRUB_CONFIG disk/boot/grub/grub.cfg
    run cp vmlinuz disk/boot/bzImage
    run cp $INITRAMFS disk/boot/initrd
    run grub-mkrescue disk -o disk.iso
    run rm -rf disk
}

test_grub() {
    run qemu-system-x86_64 -enable-kvm -m 8G \
		-vga virtio -drive file=disk.iso,if=virtio,format=raw \
		-smp 12 -cpu host -enable-kvm -rtc base=localtime \
		-bios $OVMF -no-reboot -serial stdio \
		2> /dev/null
}

config_kernel() {
    local 
    run cd kernel
    case $KERNEL_CONFIG in
        "gtk")
            run make gconfig
            ;;
        "ncurses")
            run make menuconfig
            ;;
        *)
            echo "Invalid \$KERNEL_CONFIG, defaulting to \`ncurses\`"
            run make menuconfig
            ;;
    esac
    run cd $WORKDIR
}

if [ $# -eq 0 ]; then
    echo "Command not provided"
    exit 1
fi

case $1 in
    "download-kernel")
        download_kernel
        ;;
    "build-kernel")
        build_kernel
        ;;
    "build-initramfs")
        build_initramfs
        ;;
    "build-grub")
        build_grub
        ;;
    "test")
        test_grub
        ;;
    "kconfig")
        config_kernel
        ;;
    *)
        echo "Unknown command"
        exit 1
        ;;
esac
