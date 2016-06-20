 INCLUDE "intuition/intuition.i"
 INCLUDE "intuition/intuition_lib.i"
 
 INCLUDE "globals.i"

 SECTION TilesetBrowser,CODE
NewTilesetBrowser:
	lea.l BrowserNewWin,a0
	move.l IntuiBase,a6
	jsr _LVOOpenWindow(a6)
	rts
 XDEF NewTilesetBrowser

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
	dc.l 0											; first gadget
	dc.l 0											; default checkmark image
	dc.l BrowserTitle								; title
	dc.l 0											; PATCH screen ptr
	dc.l 0											; no bitmap
	dc.w BROWSER_WIDTH,BROWSER_HEIGHT				; min width/height
	dc.w BROWSER_WIDTH,BROWSER_HEIGHT				; max width/height
	dc.w CUSTOMSCREEN								; type
 XDEF BrowserNewWin