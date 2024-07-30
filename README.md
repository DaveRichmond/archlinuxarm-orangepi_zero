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
- https://github.com/pengutronix/genimage/


Preparing the files
===================

Run `make` (specifying jobs with `-jX` is supported and recommended).

This will provide:

- the ArchLinuxARM aarch64 default rootfs (`ArchLinuxARM-aarch64-latest.tar.gz`)
- an u-boot image compiled for the OrangePi Zero (`u-boot-sunxi-with-spl.bin`)


Installing the distribution
===========================

Run `make install`. At the end, the sdcard image will be shown that can be flashed to 
a card with dd, or balena etcher, or your favourite imaging program

This is running commands similar to [any other AllWinner ArchLinuxARM
installation][alarm-allwinner].

[alarm-allwinner]: https://archlinuxarm.org/platforms/armv7/allwinner/.


Ethernet
========

With the out of the box alarm image, a usb ethernet adapter will be required. Wifi is not 
yet working, but might after a `pacman -Syu`.


Goodies
=======

If you have a serial cable and `miniterm.py` installed (`python-pyserial`),
`make serial` will open a session with the appropriate settings.


TODO
====

- upstream to ArchLinuxARM
