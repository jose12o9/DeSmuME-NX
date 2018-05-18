#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------

ifeq ($(strip $(DEVKITPRO)),)
$(error "Please set DEVKITPRO in your environment. export DEVKITPRO=<path to>/devkitpro")
endif

TOPDIR ?= $(CURDIR)
include $(DEVKITPRO)/libnx/switch_rules

#---------------------------------------------------------------------------------
# TARGET is the name of the output
# BUILD is the directory where object files & intermediate files will be placed
# SOURCES is a list of directories containing source code
# DATA is a list of directories containing data files
# INCLUDES is a list of directories containing header files
# EXEFS_SRC is the optional input directory containing data copied into exefs, if anything this normally should only contain "main.npdm".
# ROMFS is the directory containing data to be added to RomFS, relative to the Makefile (Optional)
#
# NO_ICON: if set to anything, do not use icon.
# NO_NACP: if set to anything, no .nacp file is generated.
# APP_TITLE is the name of the app stored in the .nacp file (Optional)
# APP_AUTHOR is the author of the app stored in the .nacp file (Optional)
# APP_VERSION is the version of the app stored in the .nacp file (Optional)
# APP_TITLEID is the titleID of the app stored in the .nacp file (Optional)
# ICON is the filename of the icon (.jpg), relative to the project folder.
#   If not set, it attempts to use one of the following (in this order):
#     - <Project name>.jpg
#     - icon.jpg
#     - <libnx folder>/default_icon.jpg
#---------------------------------------------------------------------------------
TARGET		:=	DeSmuME-NX
BUILD		:=	build
SOURCES		:=	src src/utils/decrypt src/addons src/utils src/utils/tinyxml src/utils/colorspacehandler src/filter src/metaspu src/switch src/libretro-common/file src/libretro-common/compat/ src/libretro-common/features/
DATA		:=	data
INCLUDES	:=	src src/libretro-common/include
EXEFS_SRC	:=	exefs_src

APP_TITLE   := DeSmuME-NX
APP_AUTHOR  := MasterFeizz
APP_VERSION := 0.0.1

#ROMFS	:=	romfs

#---------------------------------------------------------------------------------
# options for code generation
#---------------------------------------------------------------------------------
ARCH	:=	-march=armv8-a -mtune=cortex-a57 -mtp=soft -fPIE

CFLAGS	:=	-g -Wall -O2 -ffunction-sections \
			-ffast-math $(ARCH) $(DEFINES)

CFLAGS	+=	$(INCLUDE) -D__SWITCH__ -DHAVE_LIBZ 

CXXFLAGS	:= $(CFLAGS) -fno-rtti -std=gnu++11

ASFLAGS	:=	-g $(ARCH)
LDFLAGS	=	-specs=$(DEVKITPRO)/libnx/switch.specs -g $(ARCH) -Wl,-Map,$(notdir $*.map)

LIBS	:=  -lm -lz -lnx -lstdc++

#---------------------------------------------------------------------------------
# list of directories containing libraries, this must be the top level containing
# include and lib
#---------------------------------------------------------------------------------
PORTLIBS := $(DEVKITPRO)/portlibs/switch
LIBDIRS	:= $(PORTLIBS) $(LIBNX)


#---------------------------------------------------------------------------------
# no real need to edit anything past this point unless you need to add additional
# rules for different file extensions
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))
#---------------------------------------------------------------------------------

export OUTPUT	:=	$(CURDIR)/$(TARGET)
export TOPDIR	:=	$(CURDIR)

export VPATH	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
			$(foreach dir,$(DATA),$(CURDIR)/$(dir))

export DEPSDIR	:=	$(CURDIR)/$(BUILD)

SOURCES_CXX +=  armcpu.cpp \
				arm_instructions.cpp \
				bios.cpp \
				cp15.cpp \
				common.cpp \
				debug.cpp \
				driver.cpp \
				Database.cpp \
				emufile.cpp \
				encrypt.cpp \
				firmware.cpp \
				FIFO.cpp \
				GPU.cpp \
				mc.cpp \
				readwrite.cpp \
				wifi.cpp \
				path.cpp \
				MMU.cpp \
				NDSSystem.cpp \
				ROMReader.cpp \
				render3D.cpp \
				rasterize.cpp \
				rtc.cpp \
				saves.cpp \
				SPU.cpp \
				matrix.cpp \
				gfx3d.cpp \
				texcache.cpp \
				thumb_instructions.cpp \
				movie.cpp \
				mic.cpp \
				cheatSystem.cpp \
				slot1.cpp \
				slot2.cpp \
				version.cpp \
				addons/slot2_auto.cpp addons/slot2_mpcf.cpp addons/slot2_paddle.cpp addons/slot2_gbagame.cpp addons/slot2_none.cpp addons/slot2_rumblepak.cpp addons/slot2_guitarGrip.cpp addons/slot2_expMemory.cpp addons/slot2_piano.cpp addons/slot2_passme.cpp addons/slot1_none.cpp addons/slot1_r4.cpp addons/slot1_retail_nand.cpp addons/slot1_retail_auto.cpp addons/slot1_retail_mcrom.cpp addons/slot1comp_mc.cpp addons/slot1comp_rom.cpp addons/slot1comp_protocol.cpp \
				filter/deposterize.cpp \
				filter/xbrz.cpp \
				utils/advanscene.cpp \
				utils/datetime.cpp \
				utils/xstring.cpp \
				utils/vfat.cpp \
				utils/dlditool.cpp \
				utils/emufat.cpp \
				utils/guid.cpp \
				utils/colorspacehandler/colorspacehandler.cpp \
				utils/decrypt/decrypt.cpp \
				utils/decrypt/header.cpp \
				utils/decrypt/crc.cpp \
				utils/tinyxml/tinyxml.cpp \
				utils/tinyxml/tinystr.cpp \
				utils/tinyxml/tinyxmlerror.cpp \
				utils/tinyxml/tinyxmlparser.cpp \
				metaspu/metaspu.cpp \
				switch/task.cpp \
				switch/main.cpp \
				switch/input.cpp \
				switch/sound.cpp \
				switch/menu.cpp \
				switch/config.cpp

LIBRETRO_SOURCES += \
				libretro-common/compat/compat_strl.c \
				libretro-common/file/file_path.c \
				libretro-common/file/retro_dirent.c \
				libretro-common/file/retro_stat.c \
				libretro-common/features/features_cpu.c

CFILES		:= $(notdir $(LIBRETRO_SOURCES))
CPPFILES	:= $(notdir $(SOURCES_CXX))
SFILES		:=
BINFILES	:=	

#---------------------------------------------------------------------------------
# use CXX for linking C++ projects, CC for standard C
#---------------------------------------------------------------------------------
ifeq ($(strip $(CPPFILES)),)
#---------------------------------------------------------------------------------
	export LD	:=	$(CC)
#---------------------------------------------------------------------------------
else
#---------------------------------------------------------------------------------
	export LD	:=	$(CXX)
#---------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------

export OFILES	:=	$(CPPFILES:.cpp=.o) $(CFILES:.c=.o)

export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
			$(foreach dir,$(LIBDIRS),-I$(dir)/include) \
			-I$(CURDIR)/$(BUILD)

export LIBPATHS	:=	$(foreach dir,$(LIBDIRS),-L$(dir)/lib)

export BUILD_EXEFS_SRC := $(TOPDIR)/$(EXEFS_SRC)

ifeq ($(strip $(ICON)),)
	icons := $(wildcard *.jpg)
	ifneq (,$(findstring $(TARGET).jpg,$(icons)))
		export APP_ICON := $(TOPDIR)/$(TARGET).jpg
	else
		ifneq (,$(findstring icon.jpg,$(icons)))
			export APP_ICON := $(TOPDIR)/icon.jpg
		endif
	endif
else
	export APP_ICON := $(TOPDIR)/$(ICON)
endif

ifeq ($(strip $(NO_ICON)),)
	export NROFLAGS += --icon=$(APP_ICON)
endif

ifeq ($(strip $(NO_NACP)),)
	export NROFLAGS += --nacp=$(CURDIR)/$(TARGET).nacp
endif

ifneq ($(APP_TITLEID),)
	export NACPFLAGS += --titleid=$(APP_TITLEID)
endif

ifneq ($(ROMFS),)
	export NROFLAGS += --romfsdir=$(CURDIR)/$(ROMFS)
endif

.PHONY: $(BUILD) clean all

#---------------------------------------------------------------------------------
all: $(BUILD)

$(BUILD):
	@[ -d $@ ] || mkdir -p $@
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

#---------------------------------------------------------------------------------
clean:
	@echo clean ...
	@rm -fr $(BUILD) $(TARGET).pfs0 $(TARGET).nso $(TARGET).nro $(TARGET).nacp $(TARGET).elf


#---------------------------------------------------------------------------------
else
.PHONY:	all

DEPENDS	:=	$(OFILES:.o=.d)

#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------
all	:	$(OUTPUT).pfs0 $(OUTPUT).nro

$(OUTPUT).pfs0	:	$(OUTPUT).nso

$(OUTPUT).nso	:	$(OUTPUT).elf

ifeq ($(strip $(NO_NACP)),)
$(OUTPUT).nro	:	$(OUTPUT).elf $(OUTPUT).nacp
else
$(OUTPUT).nro	:	$(OUTPUT).elf
endif

$(OUTPUT).elf	:	$(OFILES)

#---------------------------------------------------------------------------------
# you need a rule like this for each extension you use as binary data
#---------------------------------------------------------------------------------
%.bin.o	:	%.bin
#---------------------------------------------------------------------------------
	@echo $(notdir $<)
	@$(bin2o)

-include $(DEPENDS)

#---------------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------------