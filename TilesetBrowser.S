 INCLUDE "graphics/gfx.i"
 INCLUDE "graphics/graphics_lib.i"
 INCLUDE "graphics/rastport.i"
 INCLUDE "intuition/intuition.i"
 INCLUDE "intuition/intuition_lib.i"
 
 INCLUDE "TilesetBrowser.i"
 
 INCLUDE "globals.i"
 INCLUDE "Project.i"

 SECTION TilesetBrowser,CODE
****
* a0 - ptr to where to initialize new tileset browser
NewTilesetBrowser:
	move.l a0,-(sp)
	lea.l BrowserNewWin,a0
	move.l IntuiBase,a6
	jsr _LVOOpenWindow(a6)
	move.l (sp)+,a0							; a0 = tileset browser
	move.l d0,TilesetBrowser_Window(a0)
	move.w #-1,TilesetBrowser_Selected(a0)
	rts
	
 XDEF NewTilesetBrowser
****************
* a0 - ptr to Tileset Browser
CloseTilesetBrowser:
	move.l a0,-(sp)
	move.l TilesetBrowser_Window(a0),a0
	move.l IntuiBase,a6
	jsr _LVOCloseWindow(a6)
	move.l (sp)+,a0
	clr.l TilesetBrowser_Window(a0)
	move.w #-1,TilesetBrowser_Selected(a0)
	rts
 XDEF CloseTilesetBrowser
****************
* a1 - ptr to window
ScrollUp:
	movem.l d2-d4/a2,-(sp)
	lea.l ScrollInfo,a0
	move.w pi_VertPot(a0),d2
	cmp.w #4096,d2
	bcs.s .zero
	sub.w #4096,d2
	bra.s .doScroll
.zero:
	clr.w d2
.doScroll:
	lea.l ScrollBarGadget,a0
	move.l #0,a2						; a2 = No requester
	move.w #AUTOKNOB!FREEVERT,d0		; d0 = flags
	clr.w d1							; d1 = horizontal pot
	move.w #MAXBODY,d3					; d3 = horizbody
	move.w #4096,d4						; d4 = vertbody
	move.l IntuiBase,a6
	jsr _LVOModifyProp(a6)
.done:
	movem.l (sp)+,d2-d4/a2
	rts
****************
* a1 - ptr to window
ScrollDown:
	movem.l d2-d4/a2,-(sp)
	lea.l ScrollInfo,a0
	move.w pi_VertPot(a0),d2
	cmp.w #(65536-4096),d2
	bcc.s .max
	add.w #4096,d2
	bra.s .doScroll
.max:
	move.w #$FFFF,d2
.doScroll:
	lea.l ScrollBarGadget,a0
	move.l #0,a2						; a2 = No requester
	move.w #AUTOKNOB!FREEVERT,d0		; d0 = flags
	clr.w d1							; d1 = horizontal pot
	move.w #MAXBODY,d3					; d3 = horizbody
	move.w #4096,d4						; d4 = vertbody
	move.l IntuiBase,a6
	jsr _LVOModifyProp(a6)
.done:
	movem.l (sp)+,d2-d4/a2
	rts
****************
* a0 - ptr to Tileset Browser
* a1 - gadget clicked
TilesetBrowserGadgetUp:
	; TODO: no
	move.l TilesetBrowser_Window(a0),a0
.dispatch
	move.w gg_GadgetID(a1),d0
	cmp.w #SCROLL_UP_ID,d0
	beq.s .scrollUp
	cmp.w #SCROLL_DOWN_ID,d0
	beq.s .scrollDown
	bra.s .done
.scrollUp:
	move.l a0,a1
	jsr ScrollUp
	bra.s .done
.scrollDown:
	move.l a0,a1
	jsr ScrollDown
.done:
	rts
 XDEF TilesetBrowserGadgetUp
****************
* a0 - ptr to Tileset Browser
RemoveAllTilesetGadgets:
	lea.l TilesetListGadgets,a1
	moveq.l #8,d0
	move.l IntuiBase,a6
	jmp _LVORemoveGList(a6)
****************
* a1 - ptr to Tileset Browser
RefreshAllTilesetGadgets:
	lea.l TilesetListGadgets,a0
	move.l #0,a2					; no requester
	moveq.l #8,d0
	move.l IntuiBase,a6
	jmp _LVORefreshGList(a6)
****************
* d0 - tileset widget to select
SelectTileset:
	lea.l TilesetListGadgets,a0
	moveq.w #8-1,d1
.loop:
	cmp.w gg_GadgetID(a0),d0
	beq.s .select
.unselect:
	and.w #(~GFLG_SELECTED),gg_Flags(a0)
	bra .loopEnd
.select:
	or.w #GFLG_SELECTED,gg_Flags(a0)
.loopEnd:
	add.l #gg_SIZEOF,a0
	dbra d1,.loop
	rts
****************
* a1 - ptr to TilesetBrowser
ClearTilesetListRect:
	movem.l d2-d3,-(sp)
	move.l wd_RPort(a1),-(sp)
	move.l (sp),a1					; a1 = rport
	moveq.b #0,d0
	move.l GfxBase,a6
	jsr _LVOSetAPen(a6)
	move.l (sp),a1
	move.b #RP_JAM1,d0
	move.l GfxBase,a6
	jsr _LVOSetDrMd(a6)
	move.l (sp)+,a1					; a1 = rport
	move.w #8,d0
	move.w #16,d1
	move.w #142,d2
	move.w #110,d3
	move.l GfxBase,a6
	jsr _LVORectFill(a6)
	movem.l (sp)+,d2-d3
	rts
****************
* a0 - ptr to TilesetBrowser
AddAllTilesetGadgets:
	lea.l TilesetListGadgets,a1
	moveq.w #0,d0						; add gadgets to the front
	moveq.l #8,d1						; 8 total gadgets
	move.l #0,a2						; no requester
	move.l IntuiBase,a6
	jsr _LVOAddGList(a6)
	rts
****************
* a0 - ptr to Tileset Browser
* a1 - gadget clicked
TilesetBrowserGadgetDown:
	; TODO: no
	move.l TilesetBrowser_Window(a0),a0
; TODO: optimize - only redraw relevant widgets
; TODO: optimize - don't redraw if you're clicking on the already selected
	move.l a0,-(sp)
	move.w gg_GadgetID(a1),-(sp)
	bsr.w RemoveAllTilesetGadgets
	move.w (sp)+,d0						; d0 = gadget selected
	bsr.w SelectTileset
	move.l (sp),a1						; a1 = tileset browser
	bsr.s ClearTilesetListRect
	move.l (sp),a0						; a0 = tileset browser
	bsr.s AddAllTilesetGadgets
	move.l (sp)+,a1						; a1 = tileset browser
	bsr.w RefreshAllTilesetGadgets
	rts
 XDEF TilesetBrowserGadgetDown

 SECTION TilesetBrowserData,DATA
BrowserTitle:
    dc.b "Tileset Browser",0

SCROLL_UP_ID	=8
SCROLL_DOWN_ID	=9
OPEN_TILESET_ID	=10

BROWSER_WIDTH	=160
BROWSER_HEIGHT	=192

OPEN_TILESET_BUTTON_WIDTH	=145
OPEN_TILESET_BUTTON_HEIGHT	=16

	EVEN 
BrowserNewWin:
	dc.w 20,20										; left,top
	dc.w BROWSER_WIDTH,BROWSER_HEIGHT				; width, height
	dc.b -1,-1										; default pens
	dc.l CLOSEWINDOW!GADGETUP!GADGETDOWN
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

OpenTilesetStr:
	dc.b 'Open Tileset',0

	EVEN
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

OpenTilesetText:
	dc.b 3,0
	dc.b 0
	dc.b 0
	dc.w 25,4
	dc.l 0
	dc.l OpenTilesetStr
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

OpenTilesetBorderPoints:
	dc.w 0,0
	dc.w OPEN_TILESET_BUTTON_WIDTH+1,0
	dc.w OPEN_TILESET_BUTTON_WIDTH+1,OPEN_TILESET_BUTTON_HEIGHT+1
	dc.w 0,OPEN_TILESET_BUTTON_HEIGHT+1
	dc.w 0,0

OpenTilesetBorder:
	dc.w -1,-1
	dc.b 1,0
	dc.b 0
	dc.b 5
	dc.l OpenTilesetBorderPoints
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
	dc.w SCROLL_UP_ID
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
	dc.w SCROLL_DOWN_ID
	dc.l 0

ScrollInfo:
	dc.w AUTOKNOB!FREEVERT
	dc.w 0,0						; HPot, VPot
	dc.w MAXBODY,4096				; HBody,VBody
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
	dc.l 0							; next
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
	dc.w 134,12										; width, height
	dc.w 0											; flags
	dc.w GACT_IMMEDIATE
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
	dc.w 134,12										; width, height
	dc.w 0											; flags
	dc.w GACT_IMMEDIATE
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
	dc.w 134,12										; width, height
	dc.w 0											; flags
	dc.w GACT_IMMEDIATE
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
	dc.w 134,12										; width, height
	dc.w 0											; flags
	dc.w GACT_IMMEDIATE
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
	dc.w 134,12										; width, height
	dc.w 0											; flags
	dc.w GACT_IMMEDIATE
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
	dc.w 134,12										; width, height
	dc.w 0											; flags
	dc.w GACT_IMMEDIATE
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
	dc.w 134,12										; width, height
	dc.w 0											; flags
	dc.w GACT_IMMEDIATE
	dc.w GTYP_BOOLGADGET
	dc.l TilesetListBorder
	dc.l 0											; highlight gfx
	dc.l TilesetListTexts+it_SIZEOF*6
	dc.l 0											; deprecated
	dc.l 0											; no special info
	dc.w 6											; ID
	dc.l 0											; extra data
.entry8:
	dc.l OpenTilesetGadget							; next
	dc.w 8,100										; left, top
	dc.w 134,11										; width, height
	dc.w 0											; flags
	dc.w GACT_IMMEDIATE
	dc.w GTYP_BOOLGADGET
	dc.l TilesetListBottomBorder
	dc.l 0
	dc.l TilesetListTexts+it_SIZEOF*7
	dc.l 0
	dc.l 0
	dc.w 7
	dc.l 0

OpenTilesetGadget:
	dc.l ScrollUpGadget								; next
	dc.w 8,116										; left,top
	dc.w OPEN_TILESET_BUTTON_WIDTH,OPEN_TILESET_BUTTON_HEIGHT
	dc.w GFLG_GADGHCOMP
	dc.w GACT_RELVERIFY
	dc.w GTYP_BOOLGADGET
	dc.l OpenTilesetBorder
	dc.l 0
	dc.l OpenTilesetText
	dc.l 0
	dc.l 0
	dc.w OPEN_TILESET_ID
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
