# LDS
LDS - Linux Distro creation System

Clone, and in root directory create directory `inird`. it will be included into your system. binaries like `[`, `ls`, etc. will be copied from your host system during build.

configuration is stored in file `config.sh`.

To download kernel, run `make download-kernel`. It will download kernel version you specified in config.
Next, run `make config-kernel`. It will run gtk or ncurses kernel config, depends on your config.
Next, run `make build-kernel`. It will build kernel accordingly to your config.

`$WORKDIR/busybox` required to determine a list of binaries to copy from your host system. You can replace it
with sth executable to customize this list.

`grub.cfg` is config for grub. Be careful, config file's basename will be used in ISO image as-is!

Next, after you putting all needed files in your `initrd` folder, you need to create initramfs image.
To do that, run `make initramfs`.

After all, just run `make livecd` to create bootable ISO image.

also you can run `make test` to test your system in QEMU.
