#
# Copyright (C) 2022 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

DTBTOOL := $(HOST_OUT_EXECUTABLES)/dtbToolAmlogic$(HOST_EXECUTABLE_SUFFIX)
DTBTMP := $(PRODUCT_OUT)/tmp_dt
DTBDIR := $(PRODUCT_OUT)/obj/KERNEL_OBJ/arch/arm64/boot/dts/amlogic
DTCDIR := $(PRODUCT_OUT)/obj/KERNEL_OBJ/scripts/dtc/
TARGET_FLASH_DTB_PARTITION ?= true
INSTALLED_DTBIMAGE_PARTITION_TARGET := $(PRODUCT_OUT)/dtb.PARTITION
ifeq ($(TARGET_KERNEL_VERSION),5.4)
DTB_PARTITION_NAME := dt
else
DTB_PARTITION_NAME := dtb
endif

define aml-compress-dtb
	if [ -n "$(shell find $(1) -size +200k)" ]; then \
		echo "$(1) > 200k will be gziped"; \
		mv $(1) $(1).orig; \
		$(MINIGZIP) -c $(1).orig > $(1); \
	fi;
endef

$(INSTALLED_DTBIMAGE_TARGET): $(INSTALLED_KERNEL_TARGET) $(DTBTOOL) | $(ACP) $(MINIGZIP)
ifeq ($(words $(TARGET_DTB_NAME)),1)
	$(hide) $(ACP) $(DTBDIR)/$(TARGET_DTB_NAME).dtb $@
else
	$(hide) mkdir -p $(DTBTMP)
	$(foreach aDts, $(TARGET_DTB_NAME), \
		$(ACP) $(DTBDIR)/$(strip $(aDts)).dtb $(DTBTMP)/$(strip $(aDts)).dtb; \
	)
	$(hide) $(DTBTOOL) -o $@ -p $(DTCDIR) $(DTBTMP)
	$(hide) rm -rf $(DTBTMP)
endif
	$(hide) $(call aml-compress-dtb, @)

$(INSTALLED_DTBIMAGE_PARTITION_TARGET): $(INSTALLED_DTBIMAGE_TARGET) $(AVBTOOL)
	$(hide) $(ACP) $(INSTALLED_DTBIMAGE_TARGET) $@
	$(hide) $(AVBTOOL) add_hash_footer \
		--image $@ \
		--partition_size $(BOARD_DTBIMAGE_PARTITION_SIZE) \
		--partition_name $(DTB_PARTITION_NAME)

ifeq ($(TARGET_FLASH_DTB_PARTITION),true)
INSTALLED_RADIOIMAGE_TARGET += $(INSTALLED_DTBIMAGE_TARGET)
endif
