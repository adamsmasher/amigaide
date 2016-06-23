 INCLUDE "intuition/intuition.i"
 INCLUDE "intuition/intuition_lib.i"
 
 INCLUDE "globals.i"

 SECTION TilesetBrowser,CODE
****
* returns in d0 pointer to the new Tileset Browser (window, for now TODO)
NewTilesetBrowser:
	lea.l BrowserNewWin,a0
	move.l IntuiBase,a6
	jmp _LVOOpenWindow(a6)
 XDEF NewTilesetBrowser
****************
* a0 - ptr to Tileset Browser (window, for now TODO)
CloseTilesetBrowser:
	move.l IntuiBase,a6
	jmp _LVOCloseWindow(a6)
 XDEF CloseTilesetBrowser

 SECTION TilesetBrowserData,DATA
BrowserTitle:
    dc.b "Tileset Browser",0

BROWSER_WIDTH	=160
BROWSER_HEIGHT	=192

	EVEN 
BrowserNewWin:
	dc.w 20,20										; left,top
	dc.w BROWSER_WIDTH,BROWSER_HEIGHT				; width, height
	dc.b -1,-1										; default pens
	dc.l CLOSEWINDOW!GADGETUP
	dc.l WINDOWCLOSE!WINDOWDEPTH!WINDOWDRAG
	dc.l TilesetListGadgets							; first gadget
	dc.l 0											; default checkmark image
	dc.l BrowserTitle								; title
	dc.l 0											; PATCH screen ptr
	dc.l 0											; no bitmap
	dc.w BROWSER_WIDTH,BROWSER_HEIGHT				; min width/height
	dc.w BROWSER_WIDTH,BROWSER_HEIGHT				; max width/height
	dc.w CUSTOMSCREEN								; type
 XDEF BrowserNewWin
 
TilesetListTopBorderPoints:
	dc.w 0,12
	dc.w 0,0
	dc.w 146,0
	dc.w 146,11
 
TilesetListTopBorder:
	dc.w -1,-1										; left, top
	dc.b 1,0										; pens
	dc.b 0											; jam1
	dc.b 4											; 4 points
	dc.l TilesetListTopBorderPoints
	dc.l 0											; no next border

TilesetListGadgets:
	dc.l 0
;	dc.l *+gg_SIZEOF								; next
	dc.w 8,16										; left, top
	dc.w 144,11										; width, height
	dc.w 0											; flags
	dc.w GACT_IMMEDIATE!GACT_TOGGLESELECT
	dc.w GTYP_BOOLGADGET
	dc.l TilesetListTopBorder
	dc.l 0											; highlight gfx
	dc.l TilesetListTexts
	dc.l 0											; deprecated
	dc.l 0											; no special info
	dc.w 0											; ID
	dc.l 0											; extra data

TestStr:
	dc.b "Test",0

	EVEN
TilesetListTexts:
	dc.b 3,0										; pens
	dc.b 0											; jam1
	dc.b 0											; padding
	dc.w 0,1										; left, top
	dc.l 0											; default font
	dc.l TestStr
	dc.l 0											; next
