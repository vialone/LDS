#!/bin/bash

set -e

DEBUG_MODE=false
WORKDIR=$PWD
PROCNUM=$(expr $(nproc) - 1)

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

build_initramfs() {
    run mkdir -p /tmp/lds/initrd/bin
    run cp -rf initrd/* /tmp/lds/initrd
    run cd /tmp/lds/initrd/bin
    set +e
    for link in $($WORKDIR/busybox --list); do
        run cp -f /bin/$link $link
    done
    set -e
    run cd /tmp/lds
    run mksquashfs initrd $INITRAMFS -no-strip -all-root -no-hardlinks -no-recovery
    run cd $WORKDIR
}

build_grub() {
    if [ -d disk ]; then run rm -rf disk; fi
    run mkdir -p disk/boot/grub
    run mkdir -p disk/lhex
    run cp $GRUB_CONFIG disk/boot/grub/
    run cp vmlinuz disk/lhex/vmlinuz
    run cp $INITRAMFS disk/lhex/initramfs.img
    # printf "" > disk/boot/2024-07-00-00-00-00-00.uuid
    run grub-mkrescue disk -o disk.iso
    run rm -rf disk
}

test_grub() {
    run qemu-system-x86_64 -enable-kvm -vga virtio -m 8G \
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
