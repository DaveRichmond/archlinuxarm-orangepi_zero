# User configuration
SERIAL_DEVICE = /dev/ttyUSB0
WGET = wget
MINITERM = miniterm.py
CROSS_COMPILE ?= aarch64-linux-gnu-
PYTHON ?= python
BLOCK_DEVICE ?= /dev/null
FIND ?= find

UBOOT_SCRIPT = boot.scr
UBOOT_BIN = u-boot-sunxi-with-spl.bin

ARCH_TARBALL = ArchLinuxARM-aarch64-latest.tar.gz

#WORKING_KERNEL = linux-armv7-6.9.8-2-armv7h.pkg.tar.xz

UBOOT_VERSION = 2024.01
UBOOT_TARBALL = u-boot-v$(UBOOT_VERSION).tar.gz
UBOOT_DIR = u-boot-$(UBOOT_VERSION)

TF_DIR = trusted-firmware-a
TF_GIT = https://git.trustedfirmware.org/TF-A/$(TF_DIR).git
TF_PLAT = sun50i_h6
TF_BIN = $(shell pwd)/$(TF_DIR)/build/$(TF_PLAT)/release/bl31.bin

SCP_DIR=crust
SCP_GIT=https://github.com/crust-firmware/$(SCP_DIR).git
SCP_BIN=$(shell pwd)/$(SCP_DIR)/build/scp/scp.bin
#SCP_BIN = /dev/null

INPUT_DIR ?= $(shell pwd)/input

ALL = $(ARCH_TARBALL) $(UBOOT_BIN) $(UBOOT_SCRIPT) $(WORKING_KERNEL)

all: $(ALL)

$(TF_DIR):
	git clone $(TF_GIT)

$(TF_BIN): $(TF_DIR)
	cd $< && make CROSS_COMPILE=$(CROSS_COMPILE) PLAT=$(TF_PLAT)

$(SCP_DIR):
	git clone $(SCP_GIT)

$(SCP_BIN): $(SCP_DIR)
	cd $< && make orangepi_3_defconfig && make CROSS_COMPILE=or1k-elf- scp

$(UBOOT_TARBALL):
	$(WGET) https://github.com/u-boot/u-boot/archive/v$(UBOOT_VERSION).tar.gz -O $@
$(UBOOT_DIR): $(UBOOT_TARBALL)
	tar xf $<

$(ARCH_TARBALL):
	$(WGET) http://archlinuxarm.org/os/$@

$(INPUT_DIR):
	mkdir -p $(INPUT_DIR)

$(UBOOT_BIN): $(UBOOT_DIR) $(TF_BIN) $(SCP_BIN) $(INPUT_DIR)
	cd $< && $(MAKE) orangepi_lite2_defconfig && $(MAKE) SCP=$(SCP_BIN) BL31=$(TF_BIN) CROSS_COMPILE=$(CROSS_COMPILE) PYTHON=$(PYTHON)
	cp $</$@ $(INPUT_DIR)

# Note: non-deterministic output as the image header contains a timestamp and a
# checksum including this timestamp (2x32-bit at offset 4)
$(UBOOT_SCRIPT): boot.txt
	mkimage -A arm -O linux -T script -C none -n "U-Boot boot script" -d $< $@

#$(WORKING_KERNEL):
#	$(WGET) http://mirror.archlinuxarm.org/armv7h/core/$@

BUILD_DIR ?= $(shell pwd)/root
GENIMAGE = $(HOME)/genimage/genimage
output/sdcard.img: $(ALL) genimage.cfg	
	mkdir -p $(BUILD_DIR)
	sudo bsdtar -xpf $(ARCH_TARBALL) -C $(BUILD_DIR)
	sudo cp $(UBOOT_SCRIPT) $(BUILD_DIR)/boot/
	sudo $(GENIMAGE) genimage.cfg
	sudo rm -Rf $(BUILD_DIR)

install: $(ALL) fdisk.cmd output/sdcard.img
	@echo Please flash output/sdcard.img to an sd card
serial:
	$(MINITERM) --raw --eol=lf $(SERIAL_DEVICE) 115200

clean:
	$(RM) $(ALL)
	sudo $(RM) -r output
	$(RM) -r $(UBOOT_DIR)

.PHONY: all serial clean install
