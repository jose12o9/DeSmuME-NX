/* main.c - this file is part of DeSmuME
*
* Copyright (C) 2006,2007 DeSmuME Team
* Copyright (C) 2007 Pascal Giard (evilynux)
* Copyright (C) 2009 Yoshihiro (DsonPSP)
* This file is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation; either version 2, or (at your option)
* any later version.
*
* This file is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; see the file COPYING.  If not, write to
* the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
* Boston, MA 02111-1307, USA.
*/
#include <stdio.h>


//DIRTY FIX FOR CONFLICTING TYPEDEFS
namespace libnx 
{
	#include <switch.h>
}

#include <malloc.h>

#include "../MMU.h"
#include "../NDSSystem.h"
#include "../debug.h"
#include "../render3D.h"
#include "../rasterize.h"
#include "../saves.h"
#include "../mic.h"
#include "../SPU.h"

#include "input.h"
#include "sound.h"
#include "menu.h"
#include "config.h"

volatile bool execute = FALSE;

static inline uint8_t convert5To8(uint8_t x)
{
	return ((x << 3) | (x >> 2));
}

static inline uint32_t ABGR1555toRGBA8(uint16_t color)
{
	uint32_t pixel = 0x00;
	uint8_t  *dst = (uint8_t*)&pixel; 

	dst[0] = convert5To8((color >> 0)   & 0x1F); //R
	dst[1] = convert5To8((color >> 5)   & 0x1F); //G
	dst[2] = convert5To8((color >> 10)  & 0x1F); //B
	dst[3] = 0xFF;//CONVERT_5_TO_8((color >> 11) & 0x1F); //A

    return pixel;
}

GPU3DInterface *core3DList[] = {
	&gpu3DNull,
	&gpu3DRasterize,
	NULL
};

SoundInterface_struct *SNDCoreList[] = {
  &SNDDummy,
  &SNDDummy,
  &SNDSwitch,
  NULL
};

const char * save_type_names[] = {
	"Autodetect",
	"EEPROM 4kbit",
	"EEPROM 64kbit",
	"EEPROM 512kbit",
	"FRAM 256kbit",
	"FLASH 2mbit",
	"FLASH 4mbit",
	NULL
};

int cycles;

static unsigned short keypad;

static void desmume_cycle()
{
    process_ctrls_events(&keypad);

    if(libnx::hidTouchCount())
    {
    	libnx::touchPosition touch;
		hidTouchRead(&touch, 0);

		if(touch.px > 401 && touch.px < 882 && touch.py > 360 && touch.py < 720)
		{

				NDS_setTouchPos((touch.px - 401) / 1.875,(touch.py - 360) / 1.875);
		}
	}

	else if(libnx::hidKeysUp(libnx::CONTROLLER_P1_AUTO) & libnx::KEY_TOUCH)
	{
		NDS_releaseTouch();
	}

	update_keypad(keypad);
	
    NDS_exec<false>();

    if(UserConfiguration.soundEnabled)
    	SPU_Emulate_user();
}

int main(int argc, char **argv)
{
	libnx::gfxInitDefault();
	libnx::consoleInit(NULL);

	char *rom_path = menu_FileBrowser();

	libnx::gfxConfigureResolution(684, 384);

	/* the firmware settings */
	struct NDS_fw_config_data fw_config;


	/* default the firmware settings, they may get changed later */
	NDS_FillDefaultFirmwareConfigData(&fw_config);

  	NDS_Init();

  	GPU->Change3DRendererByID(RENDERID_SOFTRASTERIZER);
  	SPU_ChangeSoundCore(SNDCORE_SWITCH, 735 * 4);

	CommonSettings.loadToMemory = true;

	if (NDS_LoadROM( rom_path, NULL, NULL) < 0) {
		printf("Error loading %s\n", rom_path);
	}

	execute = TRUE;
	u32 width, height;

	while(1) 
	{

		for (int i = 0; i < UserConfiguration.frameSkip; i++)
		{
			NDS_SkipNextFrame();
			desmume_cycle();
		}

		desmume_cycle();

		uint16_t * src = (uint16_t *)GPU->GetDisplayInfo().masterNativeBuffer;
		uint32_t *framebuffer = (uint32_t*)libnx::gfxGetFramebuffer(&width, &height);

		for(int x = 0; x < 256; x++){
    		for(int y = 0; y < (192 * 2); y++){
    			uint32_t offset = libnx::gfxGetFramebufferDisplayOffset(214 + x, y);
        		framebuffer[offset] = ABGR1555toRGBA8(src[( y * 256 ) + x]);
    		}
		}

		libnx::gfxFlushBuffers();
		libnx::gfxSwapBuffers();
    }

	return 0;
}