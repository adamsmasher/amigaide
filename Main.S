	INCDIR Frac:FracIDE/
	INCLUDE Exec.i
	INCLUDE Graphics.i
	INCLUDE Intuition.i

	SECTION Globals,BSS
ScrP:		ds.l 1
ProjWinP:	ds.l 1
PalWinP:	ds.l 1
SprWinP:	ds.l 1
IntuiBase:	ds.l 1
GfxBase:	ds.l 1
FgClr:		ds.b 1
BgClr:		ds.b 1
	EVEN
BorderTop:	ds.w 1
BorderLeft:	ds.b 1
BorderRight:	ds.b 1
BorderBottom:	ds.b 1

****************

	SECTION Text,CODE
* in the Start routine we initialize our libraries
* then jump into Main
Start:
.initIntui:
	lea.l IntuiName,a1
	bsr.s InitLib
	tst.l d0		; success?
	beq.s .done		; just exit if we failed
	move.l d0,IntuiBase
.initGfx:
	lea.l GfxName,a1
	bsr.s InitLib
	tst.l d0		; success?
	beq.s .closeIntui
	move.l d0,GfxBase
; libraries loaded, start program
	bsr.s Main
.closeGfx:
	move.l GfxBase,a1	; a1=lib-to-close=gfx
	move.l 4.w,a6		; a6=exec base addr
	jsr _CloseLibrary(a6)
.closeIntui:
	move.l a6,a1		; a1=lib-to-close=intuition
	move.l 4.w,a6		; a6=exec base addr
.done:	rts
****
* a1 - pointer to library name
* returns library base address or NULL in d0
InitLib:
	move.l 4.w,a6		; a6=exec base addr
	moveq #33,d0		; d0=version#
	jsr _LoadLibrary(a6)	; d0=lib
	rts
****
* assumes that Intuition and the Gfx lib have been loaded
Main:
.openScreen:
	move.l IntuiBase,a6
	lea.l ScrDef,a0
	jsr _OpenScreen(a6)
	tst.l d0		; success?
	beq.s .done
	move.l d0,ScrP
; now that the screen is opened, set it up and install it into the win cfs
	bsr.s SetupScr
.openProjWin:
	move.l IntuiBase,a6
	lea.l ProjWinDef,a0
	jsr _OpenWindow(a6)
	tst.l d0
	beq.s .closeScreen
	move.l d0,ProjWinP
.attachProjMenu:
	bsr.w InitMenus
	move.l ProjWinP,a0
	lea.l ProjMenu,a1
	move.l IntuiBase,a6
	jsr _SetMenuStrip(a6)	
	tst.l d0
	beq.s .closeProjWin
.activateProjWin:
	move.l ProjWinP,a0
	move.l IntuiBase,a6
	jsr _ActivateWindow(a6)
; jump into the main loop
	bsr.w MainLoop
.detachMenu:
	move.l ProjWinP,a0
	move.l IntuiBase,a6
	jsr _ClearMenuStrip(a6)
.closeProjWin:
	move.l IntuiBase,a6
	move.l ProjWinP,a0
	jsr _CloseWindow(a6)
.closeScreen:	
	move.l ScrP,a0
	jsr _CloseScreen(a6)
.done:	rts
****
SetupScr:
	bsr.s InitBorderInfo
	bsr.s InitPal
	bsr.s InsScrP2WinDefs
	bsr.w AddBor2NewWins
	rts
****
InitBorderInfo:
	move.l ScrP,a0
	move.b Screen_WBorL(a0),BorderLeft
	move.b Screen_WBorR(a0),BorderRight
	move.b Screen_WBorBot(a0),BorderBottom
	moveq #0,d0
	move.b Screen_WBorTop(a0),d0
	move.l Screen_Font(a0),a0
	add.w TextAttr_YSize(a0),d0
	addq #1,d0
	move.w d0,BorderTop
	rts
****
InitPal:
	movem.l d2-d4/a2-a3,-(sp)
.getViewport:
	move.l ScrP,a0
	lea.l Screen_Viewport(a0),a2
.init:
	lea.l Palette,a3
	move.l GfxBase,a6
	moveq #4-1,d4
.loop:	move.l a2,a0		; a0=Viewport
	move.w d4,d0		; d0=palette #
	movem.w (a3)+,d1-d3	; d1-d3=entries
	jsr _SetRGB4(a6)
	dbra d4,.loop
	movem.l (sp)+,d2-d4/a2-a3
	rts
****
InsScrP2WinDefs:
	move.l ScrP,d0
	lea.l AllNewWins,a0
	moveq #NUM_OF_NEWWINS-1,d1
.loop:	move.l (a0)+,a1
	move.l d0,NewWindow_Screen(a1)
	dbra d1,.loop
	rts
****
AddBor2NewWins:
	lea.l SprNewWin,a0
	bsr.s AddBor2NewWin
	rts
****
* a0 - ptr to NewWindow struct
AddBor2NewWin:
	move.w NewWindow_Width(a0),d0
	move.w NewWindow_Height(a0),d1
	add.b BorderLeft,d0
	add.b BorderRight,d0
	add.w BorderTop,d1
	add.b BorderBottom,d1
	move.w d0,NewWindow_Width(a0)
	move.w d0,NewWindow_MinWidth(a0)
	move.w d0,NewWindow_MaxWidth(a0)
	move.w d1,NewWindow_Height(a0)
	move.w d1,NewWindow_MinHeight(a0)
	move.w d1,NewWindow_MaxHeight(a0)
	rts
****
InitMenus:
	rts
****
RedrawPalWin:
	bsr.s DrawSwatches
	bsr.s DrawFgMark
	bsr.s DrawBgMark
	rts
****
DrawSwatches:
	movem.l d2-d4/a2,-(sp)
	move.l GfxBase,a6
.getRastPort:
	move.l PalWinP,a2
	move.l Window_RastPort(a2),a1
.loopInit:
	moveq #0,d0			; d0=xmin
	add.b BorderLeft,d0
	moveq #16*3,d1			; d1=ymin
	add.w BorderTop,d1
	moveq #47,d2			; d2=xmax
	add.b d0,d2
	moveq #(16*3)+15,d3		; d3=ymax
	add.w BorderTop,d3
	moveq #4-1,d4			; four colours
.loop:
.setPen:
	movem.l d0-d1/a1,-(sp)
	move.l d4,d0			; d0=pen colour
	jsr _SetAPen(a6)
	movem.l (sp)+,d0-d1/a1
.drawRect:
	movem.l d0-d1/a1,-(sp)
	jsr _RectFill(a6)
	movem.l (sp)+,d0-d1/a1
.next:
	sub.l #16,d1			; ymin-=16
	sub.l #16,d3			; ymax-=16
	dbra d4,.loop
	movem.l (sp)+,d2-d4/a2
	rts
****
DrawFgMark:
	lea.l FgClr,a0
	lea.l FgMarkStr,a1
	jsr DrawMark
	rts
****
DrawBgMark:
	lea.l BgClr,a0
	lea.l BgMarkStr,a1
	jsr DrawMark
	rts
****
; a0 - pointer to color
; a1 - pointer to text
DrawMark:
.fillInTxt:
	move.b (a0),d0			; d0=color
	move.b d0,MarkBPen
	moveq #3,d1
	sub.b d0,d1
	move.b d1,MarkFPen
	move.l a1,MarkStr
.params:
	moveq #0,d0			; d0=left
	move.b (a0),d1			; d1=color
	and.l #$FF,d1
	lsl #4,d1			; d1=top
	add.l #$0B,d1			; adjust for window title
	move.l PalWinP,a0
	move.l Window_RastPort(a0),a0	; a0=rastport
	lea.l MarkTxt,a1
.draw:
	move.l IntuiBase,a6
	jsr _PrintIText(a6)
	rts
****
MainLoop:
	movem.l d2/a2,-(sp)
	move.l 4.w,a6			; a6=Exec
.getUserPort:
	move.l ProjWinP,a0
	move.l Window_UserPort(a0),a2	; a2=UserPort
.getSigMask:
	move.b MsgPort_SigBit(a2),d1
	moveq #1,d2
	lsl.l d1,d2			; d2=SigMask
.eventLoop:
	move.l d2,d0			; d0=SigMask
	jsr _Wait(a6)
	move.l a2,a0			; a0=UserPort
	bsr.s MsgLoop
	beq.s .eventLoop
.done:
	movem.l (sp)+,d2/a2
	rts
****
; a0 - pointer to UserPort
; returns NZ if user clicked close
MsgLoop:
	movem.l d2/a2-a3,-(sp)
	move.l a0,a3			; a3=UserPort
	moveq #0,d2			; d2=close clicked?
.loop:
	move.l a3,a0			; a0=UserPort
	move.l 4.w,a6			; a6=ExecBase
	jsr _GetMsg(a6)			; d0=Msg
	tst.l d0			; no messages left?
	beq.s .done
	move.l d0,a2			; a2=Msg
	move.l a2,a1			; a1=Msg
	jsr _ReplyMsg(a6)
.dispatch:
	move.l IntuiMessage_Class(a2),d0
	cmp.l #MENUPICK,d0
	beq.s .menuPick
	bra.s .loop
.menuPick:
	; TODO: fix this constant, obviously
	cmp.w #$F800,IntuiMessage_Code(a2)
	bne.s .loop
.closeWindow:
	moveq #1,d2			; d2=close clicked!
	bra.s .loop
;.clicked:
;	move.w IntuiMessage_MouseY(a2),d0
;	sub.w BorderTop,d0
;	lsr.w #4,d0			; d0=palette entry
;	move.w IntuiMessage_Code(a2),d1
;	cmp.w #SELECTDOWN,d1
;	beq.s .setFg
;	cmp.w #MENUDOWN,d1
;	bne.s .loop
;	move.b d0,BgClr
;	bra.s .doneClrSet
;.setFg:
;	move.b d0,FgClr
;.doneClrSet:
;	bsr.w RedrawPalWin
;	bra.s .loop
.done:
	tst.l d2
	movem.l (sp)+,d2/a2-a3
	rts
****************

	SECTION MyData,DATA

IntuiName:
	dc.b "intuition.library",0

GfxName:
	dc.b "graphics.library",0

	EVEN
Palette:
	dc.w 0,0,0			; black
	dc.w 5,5,5
	dc.w 10,10,10
	dc.w 15,15,15			; white

Title:
	dc.b "FracIDE",0

	EVEN
ScrDef:
	dc.w 0,0			; left,top
	dc.w 640,256,2			; width/height/depth
	dc.b 0,1			; default pens
	dc.w HIRES
	dc.w SHOWTITLE
	dc.l 0				; default font
	dc.l Title
	dc.l 0				; no custom gadgets
	dc.l 0				; no custom widgets

NewSpriteStr:
	dc.b "New Sprite...",0

	EVEN
NewSpriteTxt:
	dc.b 3,0			; pens
	dc.b 0				; default draw mode
	dc.b 0				; padding
	dc.w 2,2			; left, top
	dc.l 0				; default font
	dc.l NewSpriteStr
	dc.l 0				; next

**** Project Window

ProjStr:
	dc.b "Project",0
PROJSTR_LEN=7

; TODO: get these from the screen
PROJ_WIDTH	=300
PROJ_HEIGHT	=200

	EVEN
ProjWinDef:
	dc.w 0,0			; top, left
	dc.w PROJ_WIDTH,PROJ_HEIGHT	; width/height
	dc.b -1,-1			; default pens
	dc.l MENUPICK			; messages to listen for
	dc.l BORDERLESS!BACKDROP
	dc.l 0				; no gadgets
	dc.l 0				; default checkmark
	dc.l ProjStr
	dc.l 0				; write screen ptr here
	dc.l 0				; no bitmap
	dc.w PROJ_WIDTH,PROJ_HEIGHT	; min width/height
	dc.w PROJ_WIDTH,PROJ_HEIGHT	; max width/height
	dc.w CUSTOMSCREEN

**** Proj Menu

ExitStr:
	dc.b "Exit",0

	EVEN
ExitTxt:
	dc.b 0,0			; pens
	dc.b 0				; draw mode?
	dc.b 0				; padding
	dc.w 0,0			; left,	top
	dc.l 0				; default font
	dc.l ExitStr
	dc.l 0				; next

	EVEN
ExitMenuItem:
	dc.l 0				; next item
	dc.w 0,0			; left, top
ExitMenuItemWidth:
	dc.w 80				; TODO: dynamic?
	dc.w 10				; height
	dc.w ITEMTEXT!COMMSEQ!ITEMENABLED!HIGHCOMP
	dc.l 0				; mutual exclusion
	dc.l ExitTxt
	dc.l 0				; different highlighted text
	dc.b "Q"			; shortcut
	dc.b 0				; packing
	dc.l 0				; sub-item
	dc.w 0				; "next select"

ProjMenu:
	; TODO: point to sprite menu
	dc.l 0				; next menu
	dc.w 2,0			; left, top
ProjMenuWidth:
	dc.w 80				; TOOD: dynamic?
	dc.w 10				; height
	dc.w MENUENABLED		; flags
	dc.l ProjStr
	dc.l ExitMenuItem
	dc.w 0,0,0,0			; for internal use only

******** Sprite window

SPR_WIDTH	=100
SPR_HEIGHT	=100

SprTitle:
	dc.b "Sprite",0

**** NewWindow
	EVEN
SprNewWin:
	dc.w 20,20			; left,top
	dc.w SPR_WIDTH,SPR_HEIGHT	; width, height
	dc.b -1,-1			; default pens
	dc.l MOUSEBUTTONS!CLOSEWINDOW
	dc.l WINDOWCLOSE!WINDOWDEPTH!WINDOWDRAG!RMBTRAP
; TODO: in the future this will have lots of gadgets
	dc.l 0				; no gadgets
	dc.l 0				; default checkmark image
	dc.l SprTitle
	dc.l 0				; write screen ptr here
	dc.l 0				; no bitmap
	dc.w SPR_WIDTH,SPR_HEIGHT	; min width/height
	dc.w SPR_WIDTH,SPR_HEIGHT	; max width/height
	dc.w CUSTOMSCREEN		; type

******** NewWindow info

AllNewWins:
	dc.l SprNewWin,ProjWinDef
NUM_OF_NEWWINS	=2

******** Mark Data

FgMarkStr:
	dc.b "1",0

BgMarkStr:
	dc.b "2",0

	EVEN
MarkTxt:
MarkFPen:
	dc.b 0				; front (fill in)
MarkBPen:
	dc.b 0				; back (fill in)
	dc.b 0				; drawing mode????
	dc.b 0				; padding
	dc.w $0004			; left
	dc.w 0				; top
	dc.l 0				; font (default)
MarkStr:
	dc.l 0				; pointer to str (fill in)
	dc.l 0				; nothing next
