 INCLUDE "intuition/intuition.i"
 INCLUDE "intuition/intuition_lib.i"
 
 INCLUDE "globals.i"
 INCLUDE "Project.i"

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
	dc.l ScrollUpGadget								; first gadget
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
	dc.w 146,12

TilesetListBottomBorderPoints:
	dc.w 0,0
	dc.w 0,12
	dc.w 146,12
	dc.w 146,0

TilesetListBorderPoints1:
	dc.w 0,0
	dc.w 0,12

TilesetListBorderPoints2:
	dc.w 146,0
	dc.w 146,12

TilesetListTopBorder:
	dc.w -1,-1										; left, top
	dc.b 1,0										; pens
	dc.b 0											; jam1
	dc.b 4											; 4 points
	dc.l TilesetListTopBorderPoints
	dc.l 0											; no next border

TilesetListBorder:
	dc.w -1,-1										; left,top
	dc.b 1,0										; pens
	dc.b 0											; jam1
	dc.b 2											; 2 points
	dc.l TilesetListBorderPoints1
	dc.l TilesetListBorderP2						; next

TilesetListBorderP2:
	dc.w -1,-1										; left,top
	dc.b 1,0										; pens
	dc.b 0											; jam1
	dc.b 2											; 2 points
	dc.l TilesetListBorderPoints2
	dc.l 0											; next

TilesetListBottomBorder:
	dc.w -1,-1
	dc.b 1,0
	dc.b 0
	dc.b 4
	dc.l TilesetListBottomBorderPoints
	dc.l 0

ScrollUpStr:
	dc.b '^',0

ScrollDownStr:
	dc.b 'v',0

ScrollUpTxt:
	dc.b 3,0										; pens
	dc.b 0											; jam1
	dc.b 0											; padding
	dc.w 1,2										; left, top
	dc.l 0											; default font
	dc.l ScrollUpStr
	dc.l 0											; next

ScrollDownTxt:
	dc.b 3,0
	dc.b 0
	dc.b 0
	dc.w 0,1
	dc.l 0
	dc.l ScrollDownStr
	dc.l 0

ScrollButtonBorderPoints:
	dc.w 0,0
	dc.w 0,12
	dc.w 10,12
	dc.w 10,0
	dc.w 0,0

ScrollButtonBorder:
	dc.w -1,-1
	dc.b 1,0
	dc.b 0
	dc.b 5
	dc.l ScrollButtonBorderPoints
	dc.l 0

ScrollUpGadget:
	dc.l ScrollDownGadget
	dc.w 144,16					; left, top
	dc.w 10,12
	dc.w GFLG_GADGHCOMP
	dc.w GACT_RELVERIFY
	dc.w GTYP_BOOLGADGET
	dc.l ScrollButtonBorder
	dc.l 0
	dc.l ScrollUpTxt
	dc.l 0
	dc.l 0
	dc.w 8
	dc.l 0

ScrollDownGadget:
	dc.l ScrollBarGadget
	dc.w 144,100
	dc.w 10,12
	dc.w GFLG_GADGHCOMP
	dc.w GACT_RELVERIFY
	dc.w GTYP_BOOLGADGET
	dc.l ScrollButtonBorder
	dc.l 0
	dc.l ScrollDownTxt
	dc.l 0
	dc.l 0
	dc.w 9
	dc.l 0

ScrollInfo:
	dc.w AUTOKNOB!FREEVERT
	dc.w 0,0						; HPot, VPot
	dc.w MAXBODY,256				; HBody,VBody
	dc.w 0,0						; width,height
	dc.w 0,0						; HPosRes,VPosRes
	dc.w 0,0						; leftborder,topborder

ScrollBarBorderPoints:
	dc.w -1,-1
	dc.w 12,-1
	dc.w 12,15
	dc.w -1,15
	dc.w -1,-1

ScrollBarBorder:
	dc.l 0,0						; left,top
	dc.b 3,0						; front,back pen
	dc.b 0							; jam1
	dc.b 0							; number of points
	dc.l ScrollBarBorderPoints		; points
	dc.l 0							; next border

ScrollBarGadget:
	dc.l TilesetListGadgets			; next
	dc.w 143,27						; left,top
	dc.w 11,73						; width,height
	dc.w 0							; flags
	dc.w 0							; activation
	dc.w GTYP_PROPGADGET			; type
	dc.l ScrollBarBorder			; border
	dc.l 0							; highlight border
	dc.l 0							; text
	dc.l 0							; deprecated
	dc.l ScrollInfo
	dc.w 10
	dc.l 0
TilesetListGadgets:
.entry1:
	dc.l *+gg_SIZEOF								; next
	dc.w 8,16										; left, top
	dc.w 134,11										; width, height
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
.entry2:
	dc.l *+gg_SIZEOF								; next
	dc.w 8,28										; left, top
	dc.w 134,11										; width, height
	dc.w 0											; flags
	dc.w GACT_IMMEDIATE!GACT_TOGGLESELECT
	dc.w GTYP_BOOLGADGET
	dc.l TilesetListBorder
	dc.l 0
	dc.l TilesetListTexts+it_SIZEOF
	dc.l 0
	dc.l 0
	dc.w 1
	dc.l 0
.entry3:
	dc.l *+gg_SIZEOF								; next
	dc.w 8,40										; left, top
	dc.w 134,11										; width, height
	dc.w 0											; flags
	dc.w GACT_IMMEDIATE!GACT_TOGGLESELECT
	dc.w GTYP_BOOLGADGET
	dc.l TilesetListBorder
	dc.l 0											; highlight gfx
	dc.l TilesetListTexts+it_SIZEOF*2
	dc.l 0											; deprecated
	dc.l 0											; no special info
	dc.w 2											; ID
	dc.l 0											; extra data
.entry4:
	dc.l *+gg_SIZEOF								; next
	dc.w 8,52										; left, top
	dc.w 134,11										; width, height
	dc.w 0											; flags
	dc.w GACT_IMMEDIATE!GACT_TOGGLESELECT
	dc.w GTYP_BOOLGADGET
	dc.l TilesetListBorder
	dc.l 0
	dc.l TilesetListTexts+it_SIZEOF*3
	dc.l 0
	dc.l 0
	dc.w 3
	dc.l 0
.entry5:
	dc.l *+gg_SIZEOF								; next
	dc.w 8,64										; left, top
	dc.w 134,11										; width, height
	dc.w 0											; flags
	dc.w GACT_IMMEDIATE!GACT_TOGGLESELECT
	dc.w GTYP_BOOLGADGET
	dc.l TilesetListBorder
	dc.l 0											; highlight gfx
	dc.l TilesetListTexts+it_SIZEOF*4
	dc.l 0											; deprecated
	dc.l 0											; no special info
	dc.w 4											; ID
	dc.l 0											; extra data
.entry6:
	dc.l *+gg_SIZEOF								; next
	dc.w 8,76										; left, top
	dc.w 134,11										; width, height
	dc.w 0											; flags
	dc.w GACT_IMMEDIATE!GACT_TOGGLESELECT
	dc.w GTYP_BOOLGADGET
	dc.l TilesetListBorder
	dc.l 0
	dc.l TilesetListTexts+it_SIZEOF*5
	dc.l 0
	dc.l 0
	dc.w 5
	dc.l 0
.entry7:
	dc.l *+gg_SIZEOF								; next
	dc.w 8,88										; left, top
	dc.w 134,11										; width, height
	dc.w 0											; flags
	dc.w GACT_IMMEDIATE!GACT_TOGGLESELECT
	dc.w GTYP_BOOLGADGET
	dc.l TilesetListBorder
	dc.l 0											; highlight gfx
	dc.l TilesetListTexts+it_SIZEOF*6
	dc.l 0											; deprecated
	dc.l 0											; no special info
	dc.w 6											; ID
	dc.l 0											; extra data
.entry8:
	dc.l 0											; next
	dc.w 8,100										; left, top
	dc.w 134,11										; width, height
	dc.w 0											; flags
	dc.w GACT_IMMEDIATE!GACT_TOGGLESELECT
	dc.w GTYP_BOOLGADGET
	dc.l TilesetListBottomBorder
	dc.l 0
	dc.l TilesetListTexts+it_SIZEOF*7
	dc.l 0
	dc.l 0
	dc.w 7
	dc.l 0

TestStr:
	dc.b "Test",0

	EVEN
TilesetListTexts:
.text1:
	dc.b 3,0										; pens
	dc.b 0											; jam1
	dc.b 0											; padding
	dc.w 0,1										; left, top
	dc.l 0											; default font
	dc.l Project+Project_TilesetNames+16*0
	dc.l 0											; next
.text2:
	dc.b 3,0										; pens
	dc.b 0											; jam1
	dc.b 0											; padding
	dc.w 0,1										; left,top
	dc.l 0											; default font
	dc.l Project+Project_TilesetNames+16*1
	dc.l 0
.text3:
	dc.b 3,0										; pens
	dc.b 0											; jam1
	dc.b 0											; padding
	dc.w 0,1										; left, top
	dc.l 0											; default font
	dc.l Project+Project_TilesetNames+16*2
	dc.l 0											; next
.text4:
	dc.b 3,0										; pens
	dc.b 0											; jam1
	dc.b 0											; padding
	dc.w 0,1										; left,top
	dc.l 0											; default font
	dc.l Project+Project_TilesetNames+16*3
	dc.l 0
.text5:
	dc.b 3,0										; pens
	dc.b 0											; jam1
	dc.b 0											; padding
	dc.w 0,1										; left, top
	dc.l 0											; default font
	dc.l Project+Project_TilesetNames+16*4
	dc.l 0											; next
.text6:
	dc.b 3,0										; pens
	dc.b 0											; jam1
	dc.b 0											; padding
	dc.w 0,1										; left,top
	dc.l 0											; default font
	dc.l Project+Project_TilesetNames+16*5
	dc.l 0
.text7:
	dc.b 3,0										; pens
	dc.b 0											; jam1
	dc.b 0											; padding
	dc.w 0,1										; left, top
	dc.l 0											; default font
	dc.l Project+Project_TilesetNames+16*6
	dc.l 0											; next
.text8:
	dc.b 3,0										; pens
	dc.b 0											; jam1
	dc.b 0											; padding
	dc.w 0,1										; left,top
	dc.l 0											; default font
	dc.l Project+Project_TilesetNames+16*7
	dc.l 0
