.DEFAULT_GOAL = all

all:
    echo "Command not specified. Exiting..."
    exit 1

config-kernel:
    ./make.sh kconfig

download-kernel:
    ./make.sh download-kernel

kernel:
	./make.sh build-kernel

initramfs:
	./make.sh build-initramfs

livecd:
	./make.sh build-grub

test:
	./make.sh test

