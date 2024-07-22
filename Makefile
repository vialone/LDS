.DEFAULT_GOAL = all

all: livecd test

vmlinuz:
	./make.sh build-kernel

initramfs: vmlinuz
	./make.sh build-initramfs

livecd: initramfs
	./make.sh build-grub

test:
	./make.sh test
