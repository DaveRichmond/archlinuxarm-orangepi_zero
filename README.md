This repository can be used to create an ArchLinuxARM image for the OrangePi
Zero board.


Dependencies
============

- `make`
- `bsdtar` (`libarchive`)
- `python`
- `uboot-tools`
- `sudo`
- `fdisk`

Ubuntu will probably need (didn't take full notes, and just felt my way through each time make failed)
- `python-dev-is-python3`
- `libssl-dev`
- `flex`
- `bison`
- `gcc-arm-none-eabi`


Preparing the files
===================

Run `make` (specifying jobs with `-jX` is supported and recommended).

This will provide:

- the ArchLinuxARM armv7 default rootfs (`ArchLinuxARM-armv7-latest.tar.gz`)
- an u-boot image compiled for the OrangePi Zero (`u-boot-sunxi-with-spl.bin`)
- a boot script (`boot.scr`) to be copied in `/boot`


Installing the distribution
===========================

Run `make install BLOCK_DEVICE=/dev/mmcblk0` with the appropriate value for
`BLOCK_DEVICE`.

This is running commands similar to [any other AllWinner ArchLinuxARM
installation][alarm-allwinner].

[alarm-allwinner]: https://archlinuxarm.org/platforms/armv7/allwinner/.


Ethernet
========

In order to get ethernet working, you will need to downgrade to the 4.13-rc7
since the network support has been [reverted in 54f70f52e3][sunxi-revert]. You
can install the package with `pacman -U
/root/linux-armv7-rc-4.13.rc7-1-armv7h.pkg.tar.xz` using the [serial
interface][opiz-serial].

[sunxi-revert]: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=54f70f52e3b3a26164220d98a712a274bd28502f
[opiz-serial]: http://linux-sunxi.org/Xunlong_Orange_Pi_Zero#Locating_the_UART


Goodies
=======

If you have a serial cable and `miniterm.py` installed (`python-pyserial`),
`make serial` will open a session with the appropriate settings.


TODO
====

- upstream to ArchLinuxARM
