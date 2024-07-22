#!/bin/bash

set -e

source config.sh

WORKDIR=$PWD
PROCNUM=$(expr $(nproc) - 1)
ALL_INITRAMFS_FILES=$(find initrd)

download_kernel() {
    wget https://cdn.kernel.org/pub/kernel/kernel/v6.x/kernel-$KERNEL_VERSION.tar.xz
    tar xf kernel-$KERNEL_VERSION.tar.xz
    mv kernel-$KERNEL_VERSION kernel
    rm kernel-$KERNEL_VERSION.tar.xz
}

build_kernel() {
    if [ ! -d kernel ]; then
        download_kernel
    fi
    cd kernel
    make -j$PROCNUM --silent
    cd ..
    cp kernel/arch/x86/boot/bzImage vmlinuz
}

build_initramfs() {
    mkdir -p /tmp/lds/initrd
    cp -r initrd /tmp/lds/initrd
    cd /tmp/lds/initrd/bin
    for link in $($WORKDIR/busybox --list); do
        cp -f /bin/$link $link > /dev/null 2>&1
    done
    cd /tmp/lds
    mksquashfs initrd $INITRAMFS -no-compression -noappend
    cd $WORKDIR
}

build_grub() {
    if [ -d disk ]; then rm -rf disk; fi
    mkdir -p disk/boot/grub
    mkdir -p disk/lhex
    cp $GRUB_CONFIG disk/boot/grub/
    cp vmlinuz disk/lhex/vmlinuz
    cp $INITRAMFS disk/lhex/initramfs.img
    # printf "" > disk/boot/2024-07-00-00-00-00-00.uuid
    grub-mkrescue disk -o disk.iso
    rm -rf disk
}

test_grub() {
    qemu-system-x86_64 -enable-kvm -vga virtio -m 8G \
		-vga virtio -drive file=disk.iso,if=virtio,format=raw \
		-smp 12 -cpu host -enable-kvm -rtc base=localtime \
		-bios /usr/share/ovmf/x64/OVMF.fd -no-reboot -serial stdio \
		2> /dev/null
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
    *)
        echo "Unknown command"
        exit 1
        ;;
esac
