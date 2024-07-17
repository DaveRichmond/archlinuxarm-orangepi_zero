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

UBOOT_VERSION = 2024.07
UBOOT_TARBALL = u-boot-v$(UBOOT_VERSION).tar.gz
UBOOT_DIR = u-boot-$(UBOOT_VERSION)

TF_DIR = trusted-firmware-a
TF_GIT = https://git.trustedfirmware.org/TF-A/$(TF_DIR).git
TF_PLAT = sun50i_h6
TF_BIN = $(shell pwd)/$(TF_DIR)/build/$(TF_PLAT)/release/bl31.bin

SCP_DIR=crust
SCP_GIT=git clone https://github.com/crust-firmware/$(SCP_DIR).git
SCP_BIN=$(shell pwd)/$(SCP_DIR)/build/scp/scp.bin

MOUNT_POINT = mnt

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

$(UBOOT_BIN): $(UBOOT_DIR) $(TF_BIN) $(SCP_BIN)
	cd $< && $(MAKE) orangepi_lite2_defconfig && $(MAKE) SCP=$(SCP_BIN) BL31=$(TF_BIN) CROSS_COMPILE=$(CROSS_COMPILE) PYTHON=$(PYTHON)
	cp $</$@ .

# Note: non-deterministic output as the image header contains a timestamp and a
# checksum including this timestamp (2x32-bit at offset 4)
$(UBOOT_SCRIPT): boot.txt
	mkimage -A arm -O linux -T script -C none -n "U-Boot boot script" -d $< $@
boot.txt:
	$(WGET) https://raw.githubusercontent.com/archlinuxarm/PKGBUILDs/master/alarm/uboot-sunxi/$@

#$(WORKING_KERNEL):
#	$(WGET) http://mirror.archlinuxarm.org/armv7h/core/$@

define part1
/dev/$(shell basename $(shell $(FIND) /sys/block/$(shell basename $(1))/ -maxdepth 2 -name "partition" -printf "%h"))
endef

install: $(ALL) fdisk.cmd
ifeq ($(BLOCK_DEVICE),/dev/null)
	@echo You must set BLOCK_DEVICE option
else
	sudo dd if=/dev/zero of=$(BLOCK_DEVICE) bs=1M count=8
	sudo fdisk $(BLOCK_DEVICE) < fdisk.cmd
	sync
	sudo mkfs.ext4 $(call part1,$(BLOCK_DEVICE))
	mkdir -p $(MOUNT_POINT)
	sudo umount $(MOUNT_POINT) || true
	sudo mount $(call part1,$(BLOCK_DEVICE)) $(MOUNT_POINT)
	sudo bsdtar -xpf $(ARCH_TARBALL) -C $(MOUNT_POINT)
	sudo cp $(UBOOT_SCRIPT) $(MOUNT_POINT)/boot
	#sudo cp $(WORKING_KERNEL) $(MOUNT_POINT)/root
	sync
	sudo umount $(MOUNT_POINT) || true
	rmdir $(MOUNT_POINT) || true
	sudo dd if=$(UBOOT_BIN) of=$(BLOCK_DEVICE) bs=1024 seek=8
endif

serial:
	$(MINITERM) --raw --eol=lf $(SERIAL_DEVICE) 115200

clean:
	$(RM) $(ALL)
	$(RM) boot.txt
	$(RM) -r $(UBOOT_DIR)

.PHONY: all serial clean install
