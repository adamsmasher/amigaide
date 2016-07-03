 INCLUDE "graphics/gfx.i"
 INCLUDE "graphics/graphics_lib.i"
 INCLUDE "graphics/rastport.i"
 INCLUDE "intuition/intuition.i"
 INCLUDE "intuition/intuition_lib.i"
 
 INCLUDE "TilesetBrowser.i"
 
 INCLUDE "globals.i"
 INCLUDE "Main_intf.i"
 INCLUDE "Project.i"

 SECTION TilesetBrowser,CODE
****
* a0 - ptr to where to initialize new tileset browser
NewTilesetBrowser:
	move.l a0,-(sp)
	clr.w d0
	bsr.s InitTilesetGadgets
	lea.l BrowserNewWin,a0
	move.l IntuiBase,a6
	jsr _LVOOpenWindow(a6)
	move.l (sp)+,a0							; a0 = tileset browser
	move.l d0,TilesetBrowser_Window(a0)
	move.w #-1,TilesetBrowser_Selected(a0)
	clr.w TilesetBrowser_FirstShown(a0)
	rts
	
 XDEF NewTilesetBrowser
****************
* d0 - first tileset displayed
InitTilesetGadgets:
	bsr.s InitEnabledGadgets
; a0 = first empty
; d0 = num disabled (-1)
	tst.w d0
	beq.s .done
	bsr.s InitDisabledGadgets
.done:
	rts
*****************
* d0 - first tileset displayed
* returns in a0 the first empty gadget
* returns in d0 the number disabled
InitEnabledGadgets:
	move.l a2,-(sp)
	lea.l TilesetListGadgets,a0
	lea.l TilesetListTexts,a1
; a2 = tileset name base
	lea.l Project+Project_TilesetNames,a2
	move.w d0,d1							; d1 = first tileset displayed
	lsl.w #4,d1								; d1 = byte offset
	lea.l (a2,d1),a2						; a2 = first name displayed	
; set d1 to be the number of tilesets (total) after the last currently
; initialized tileset (of the ones we're going to display)
	move.w Project+Project_TilesetCnt,d1
	sub.b d0,d1
	moveq.w #8-1,d0							; d0 - # of gadgets left
	bra.s .test
.loop:
	and.w #(~(GFLG_DISABLED!GFLG_SELECTED)),gg_Flags(a0)
	move.l a2,it_IText(a1)
	move.l a1,gg_GadgetText(a0)
.next:
	move.l gg_NextGadget(a0),a0
	lea.l it_SIZEOF(a1),a1					; a1 = next text
	lea.l 16(a2),a2							; a2 = next title
	subq.b #1,d1
.test:
	tst.b d1								; zero left total?
	dble d0,.loop
	movem.l (sp)+,a2
	rts
****************
* a0 - first disabled gadget
* d0 - number to disable
InitDisabledGadgets:
.loop:
	move.l #NoTilesetText,gg_GadgetText(a0)
	or.w #GFLG_DISABLED,gg_Flags(a0)
	and.w #(~GFLG_SELECTED),gg_Flags(a0)
	move.l gg_NextGadget(a0),a0
	dbra d0,.loop
	rts
****************
* a0 - TilesetBrowser
DeselectSelectedGadget:
	move.w TilesetBrowser_Selected(a0),d0
	cmp.w #-1,d0
	beq.s .done
	mulu.w #gg_SIZEOF,d0
	lea.l TilesetListGadgets,a0
	lea.l (a0,d0),a0
	and.w #(~GFLG_SELECTED),gg_Flags(a0)
.done:
	rts
****************
* a0 - ptr to Tileset Browser
CloseTilesetBrowser:
	move.l a0,-(sp)
	move.l TilesetBrowser_Window(a0),a0
	move.l IntuiBase,a6
	jsr _LVOCloseWindow(a6)
	move.l (sp),a0
	bsr.s DeselectSelectedGadget
	move.l (sp)+,a0
	clr.l TilesetBrowser_Window(a0)
	move.w #-1,TilesetBrowser_Selected(a0)
	rts
 XDEF CloseTilesetBrowser
****************
* a0 - ptr to TilesetBrowser
UpdateListGadgets:
	move.l a0,-(sp)
	bsr.s RemoveAllListGadgets
	move.l (sp),a0
	bsr.s ClearListArea
	move.l (sp),a0
	move.w TilesetBrowser_FirstShown(a0),d0
	bsr.w InitTilesetGadgets
	move.l (sp),a0
	bsr.s AddAllListGadgets
	move.l (sp)+,a0
	bsr.w RefreshAllListGadgets
	rts
****************
* a1 - rport
InitRPortClear:
	move.l a1,-(sp)
	moveq.b #0,d0							; d0 = white
	move.l GfxBase,a6
	jsr _LVOSetAPen(a6)
	move.l (sp)+,a1							; a1 = rport
	move.b #RP_JAM1,d0
	move.l GfxBase,a6
	jmp _LVOSetDrMd(a6)
****************
* a0 - ptr to TilesetBrowser
ClearListArea:
	movem.l d2-d3,-(sp)
	move.l TilesetBrowser_Window(a0),a0
	move.l wd_RPort(a0),-(sp)
	move.l (sp),a1							; a1 = rport
	bsr.s InitRPortClear
	move.l (sp)+,a1							; a1 = rport
	move.w #8,d0							; d0 = left
	move.w #142,d2							; d2 = right
	move.w #16,d1							; d1 = top
; TODO: fixme
	move.w #100,d3							; d3 = bottom
	move.l GfxBase,a6
	jsr _LVORectFill(a6)
	movem.l (sp)+,d2-d3
	rts
****************
* a0 - ptr to TilesetBrowser
RemoveAllListGadgets:
	move.l TilesetBrowser_Window(a0),a0
	lea.l TilesetListGadgets,a1
	move.w #8,d0
	move.l IntuiBase,a6
	jmp _LVORemoveGList(a6)
****************
* a0 - ptr to TilesetBrowser
AddAllListGadgets:
	move.l a2,-(sp)
	move.l TilesetBrowser_Window(a0),a0
	lea.l TilesetListGadgets,a1
	move.l #0,a2							; no requester
	move.w #-1,d0							; d0 = end of list
	move.w #8,d1							; d1 = eight gadgets
	move.l IntuiBase,a6
	jsr _LVOAddGList(a6)
	move.l (sp)+,a2
	rts
****************
* a0 - ptr to TilesetBrowser
RefreshAllListGadgets:
	move.l a2,-(sp)
	move.l TilesetBrowser_Window(a0),a1
	lea.l TilesetListGadgets,a0
	move.l #0,a2							; no requester
	move.w #8,d0							; eight gadgets
	move.l IntuiBase,a6
	jsr _LVORefreshGList(a6)
	move.l (sp)+,a2
	rts
****************
* d0 - new scroll value
* a0 - ptr to TilesetBrowser
UpdateScroll:
	move.w d0,-(sp)
	move.l a0,-(sp)
	move.w TilesetBrowser_FirstShown(a0),-(sp)
	bsr.w UpdateFirstShown
	move.w (sp)+,d0								; d0 = old first shown
	cmp.w TilesetBrowser_FirstShown(a0),d0
	beq.s .updateScrollGadget					; don't redraw if no change
	move.l (sp),a0
	bsr.w UpdateListGadgets
.updateScrollGadget:
	move.l (sp)+,a0
	move.w (sp)+,d0
	bra.s UpdateScrollGadget
****************
* d0 - new pot value
* a0 - TilesetBrowser
UpdateFirstShown:
; divide by 4096
	lsr.w #8,d0
	lsr.w #4,d0
	move.w d0,TilesetBrowser_FirstShown(a0)
	rts
****************
* a0 - ptr to TilesetBrowser
ScrollUp:
	lea.l ScrollInfo,a1
	move.w pi_VertPot(a1),d0
	cmp.w #4096,d0
	bcs.s .zero
	sub.w #4096,d0
	bra.s .doScroll
.zero:
	clr.w d0
.doScroll:
	bra.w UpdateScroll
****************
* a0 - ptr to TilesetBrowser
* d0 - new pot value
UpdateScrollGadget:
	movem.l d2-d4/a2,-(sp)
	move.w d0,d2						; d2 = new pot value
	move.l TilesetBrowser_Window(a0),a1
	lea.l ScrollBarGadget,a0
	move.l #0,a2						; a2 = No requester
	move.w #AUTOKNOB!FREEVERT,d0		; d0 = flags
	clr.w d1							; d1 = horizontal pot
	move.w #MAXBODY,d3					; d3 = horizbody
	move.w #4096,d4						; d4 = vertbody
	move.l IntuiBase,a6
	jsr _LVOModifyProp(a6)
	movem.l (sp)+,d2-d4/a2
	rts
****************
* a0 - ptr to TilesetBrowser
ScrollDown:
	lea.l ScrollInfo,a1
	move.w pi_VertPot(a1),d0
	cmp.w #(65536-4096),d0
	bcc.s .max
	add.w #4096,d0
	bra.s .doScroll
.max:
	move.w #$FFFF,d0
.doScroll:
	bra.w UpdateScroll
****************
* a0 - ptr to Tileset Browser
OpenTileset:
	move.w TilesetBrowser_Selected(a0),d0
	cmp #-1,d0
	beq .done
	jsr SpawnTilesetEditor
.done:
	rts
****************
* a0 - ptr to Tileset Browser
* a1 - gadget clicked
TilesetBrowserGadgetUp:
.dispatch:
	move.w gg_GadgetID(a1),d0
	cmp.w #SCROLL_UP_ID,d0
	beq.s .scrollUp
	cmp.w #SCROLL_DOWN_ID,d0
	beq.s .scrollDown
	cmp.w #OPEN_TILESET_ID,d0
	beq.s .openTileset
	cmp.w #SCROLL_BAR_ID,d0
	beq.s .updateScroll
	bra.s .done
.scrollUp:
	bsr.w ScrollUp
	bra.s .done
.scrollDown:
	bsr.s ScrollDown
	bra.s .done
.openTileset:
	bsr.s OpenTileset
	bra.s .done
.updateScroll:
	lea.l ScrollInfo,a1
	move.w pi_VertPot(a1),d0
	bsr.w UpdateScroll
.done:
	rts
 XDEF TilesetBrowserGadgetUp
****************
* a0 - ptr to TilesetBrowser
* d0 - newly selected gadget
* returns new selected in a0, old selected in a1
GetGadgetsToUpdate:
	move.l a2,-(sp)
	move.w TilesetBrowser_Selected(a0),d1
	lea.l TilesetListGadgets,a2
	mulu.w #gg_SIZEOF,d0					; d0 = gg_SIZEOF * selected
	lea.l (a2,d0),a0						; newly selected gadget
	cmp.w #-1,d1
	beq.s .noOld
	mulu.w #gg_SIZEOF,d1
	lea.l (a2,d1),a1						; old selected gadget
	bra.s .done
.noOld:
	move.l #0,a1
.done:
	move.l (sp)+,a2
	rts
****************
* a0 - ptr to Tileset Browser
* a1 - ptr to newly selected gadget
* a2 - ptr to old selected gadget
RemoveUpdatedListGadgets:
	move.l TilesetBrowser_Window(a0),-(sp)
	move.l (sp),a0							; a0 = window
	move.l IntuiBase,a6
	jsr _LVORemoveGadget(a6)
	move.l (sp)+,a0							; a0 = window
	move.l a2,a1							; a1 = old selected gadget
; don't do anything if the old gadget = NULL
	beq.s .done
	move.l IntuiBase,a6
	jmp _LVORemoveGadget(a6)
.done:
	rts
****************
* a0 - ptr to Tileset Browser
* a1 - newly selected gadget
* a2 - old selected gadget
RefreshUpdatedTilesetGadgets:
	move.l a2,-(sp)
	move.l TilesetBrowser_Window(a0),-(sp)
	move.l a1,a0							; a0 = new gadget
	move.l (sp),a1							; a1 = window
	move.l #0,a2							; a2 = no requester
	moveq.w #1,d0							; only refresh one gadget
	move.l IntuiBase,a6
	jsr _LVORefreshGList(a6)
	move.l (sp)+,a1							; a1 = window
	move.l (sp)+,a0							; a0 = old gadget
	beq.s .done
	move.l #0,a2							; a2 = no requester
	moveq.w #1,d0
	move.l IntuiBase,a6
	jmp _LVORefreshGList(a6)
.done:
	rts
****************
* a0 - newly selected gadget
* a1 - old selected gadget
UpdateSelectedGadgetFlags:
	or.w #GFLG_SELECTED,gg_Flags(a0)
	cmp #0,a1
	beq.s .done
	and.w #(~GFLG_SELECTED),gg_Flags(a1)
.done:
	rts
****************
* a1 - rport
* d1 - number of entry to clear
ClearListRect:
	movem.l d2-d3,-(sp)
	move.w #8,d0							; d0 = left
	move.w #142,d2							; d2 = right
	mulu.w #12,d1							; d1 = top (minus border)
	add.w #16,d1							; d1 = top
	move.w d1,d3							; d3 = top
	add.w #12,d3							; d3 = bottom
	move.l GfxBase,a6
	jsr _LVORectFill(a6)
	movem.l (sp)+,d2-d3
	rts
****************
* a0 - ptr to TilesetBrowser
* d0 - newly selected gadget
ClearTilesetListRect:
	move.w d0,-(sp)							; save new selection
	move.l a0,-(sp)							; save browser
	move.l TilesetBrowser_Window(a0),a0
	move.l wd_RPort(a0),-(sp)				; save rastport
	move.l (sp),a1							; a1 = rport
	bsr.w InitRPortClear
.drawNew:
	move.l (sp),a1							; a1 = rport
	move.w 8(sp),d1
	bsr.s ClearListRect
.drawOld:
	move.l (sp)+,a1							; a1 = rport
	move.l (sp)+,a0							; a0 = browser
	move.w TilesetBrowser_Selected(a0),d1
	cmp.w #-1,d1
	beq.s .done
	bsr.s ClearListRect
.done:
	addq.l #2,sp
	rts
****************
* a0 - ptr to TilesetBrowser
* a1 - newly selected gadget
* a2 - old selected gadget
AddUpdatedTilesetGadgets:
	move.l TilesetBrowser_Window(a0),-(sp)
.addNewGadget:
	move.l (sp),a0							; a0 = window
	move.w gg_GadgetID(a1),d0				; insert here
	move.l IntuiBase,a6
	jsr _LVOAddGadget(a6)
.addOldGadget:
	move.l (sp)+,a0							; a0 = window
	move.l a2,a1							; a1 = old gadget
	beq.s .done
	move.w gg_GadgetID(a1),d0				; insert here
	move.l IntuiBase,a6
	jmp _LVOAddGadget(a6)
.done:
	rts
****************
* a0 - ptr to Tileset Browser
* a1 - gadget clicked
TilesetBrowserGadgetDown:
	move.l a2,-(sp)
	move.w gg_GadgetID(a1),d0				; d0 = gadget clicked
	move.w d0,d1							; d1 = tileset clicked 
	add.w TilesetBrowser_FirstShown(a0),d1	; ...
; don't update if there's no change
; TODO: can probably set this up here and save pushing d2 onto the stack
	cmp.w TilesetBrowser_Selected(a0),d1
	beq.s .done
	move.w d0,-(sp)
	move.l a0,-(sp)							; store tilesetbrowser
	move.w d0,-(sp)							; store new gadget
	bsr.w GetGadgetsToUpdate
	movem.l a0-a1,-(sp)						; store gadgets to update
	movem.l (sp),a1-a2						; shift them up
	move.l 10(sp),a0						; a0 = tileset browser
	bsr.w RemoveUpdatedListGadgets
	movem.l (sp),a0-a1						; a0,a1 = new/old gadgets
	bsr.w UpdateSelectedGadgetFlags
	move.l 10(sp),a0						; a0 = tileset browser
	move.w 8(sp),d0							; d0 = newly selected gadget
	bsr.w ClearTilesetListRect
	move.l 10(sp),a0						; a0 = tileset browser
	movem.l (sp),a1-a2						; a1,a2 = new/old gadgets
	bsr.s AddUpdatedTilesetGadgets
	move.l 10(sp),a0						; a0 = tileset browser
	movem.l (sp)+,a1-a2						; a1,a2 = new/old gadgets
	bsr.w RefreshUpdatedTilesetGadgets
.update:
	move.w (sp)+,d0							; d0 = new selected
	move.l (sp)+,a0							; a0 = tilesetbrowser
	move.w (sp)+,d1
	move.w d1,TilesetBrowser_Selected(a0)
.done:
	move.l (sp)+,a2
	rts
 XDEF TilesetBrowserGadgetDown

 SECTION TilesetBrowserData,DATA
BrowserTitle:
    dc.b "Tileset Browser",0

SCROLL_UP_ID	=8
SCROLL_DOWN_ID	=9
OPEN_TILESET_ID	=10
SCROLL_BAR_ID	=11

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

TilesetListGadgets:
.entry1:
	dc.l *+gg_SIZEOF								; next
	dc.w 8,16										; left, top
	dc.w 135,12										; width, height
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
	dc.w 135,12										; width, height
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
	dc.w 135,12										; width, height
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
	dc.w 135,12										; width, height
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
	dc.w 135,12										; width, height
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
	dc.w 135,12										; width, height
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
	dc.w 135,12										; width, height
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
	dc.l ScrollUpGadget								; next
	dc.w 8,100										; left, top
	dc.w 135,12										; width, height
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
	dc.l OpenTilesetGadget			; next
	dc.w 143,27						; left,top
	dc.w 11,73						; width,height
	dc.w 0							; flags
	dc.w GACT_RELVERIFY				; activation
	dc.w GTYP_PROPGADGET			; type
	dc.l ScrollBarBorder			; border
	dc.l 0							; highlight border
	dc.l 0							; text
	dc.l 0							; deprecated
	dc.l ScrollInfo
	dc.w SCROLL_BAR_ID
	dc.l 0

OpenTilesetGadget:
	dc.l 0											; next
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

NoTilesetText:
	dc.b 2,0
	dc.b 0
	dc.b 0
	dc.w 0,1
	dc.l 0
	dc.l NoTilesetStr
	dc.l 0

NoTilesetStr:
	dc.b '<no tileset>',0
