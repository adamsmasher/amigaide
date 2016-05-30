	INCLUDE "exec/exec.i"
	INCLUDE "exec/exec_lib.i"
	INCLUDE "graphics/gfx.i"
	INCLUDE "graphics/graphics_lib.i"
	INCLUDE "intuition/intuition.i"
	INCLUDE "intuition/intuition_lib.i"
	INCLUDE "reqtools.i"

	INCLUDE "globals.i"
	INCLUDE "SpriteEditor.i"
	INCLUDE "SpriteEditor_intf.i"

	jmp Start

	SECTION MainVars,BSS
ScrP:			ds.l 1
ProjWinP:		ds.l 1
SignalMask:		ds.l 1
FirstSprEditor:	ds.l 1
BorderTop:		ds.w 1
BorderLeft:		ds.b 1
BorderRight:	ds.b 1
BorderBottom:	ds.b 1
QuitFlag:		ds.b 1

****************

	SECTION Main,CODE
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
.initReq:
	; we can't just use InitLib, bc we need a higher version
	lea.l ReqName,a1
	move.l 4.w,a6
	moveq #REQTOOLSVERSION,d0
	jsr _LVOOpenLibrary(a6)
	tst.l d0
	beq.s .closeGfx
	move.l d0,ReqBase
; libraries loaded, start program
	bsr.s Main
.closeReq:
	move.l ReqBase,a1
	move.l 4.w,a6
	jsr _LVOCloseLibrary(a6)
.closeGfx:
	move.l GfxBase,a1	; a1=lib-to-close=gfx
	move.l 4.w,a6		; a6=exec base addr
	jsr _LVOCloseLibrary(a6)
.closeIntui:
	move.l a6,a1		; a1=lib-to-close=intuition
	move.l 4.w,a6		; a6=exec base addr
.done:	rts
****
* a1 - pointer to library name
* returns library base address or NULL in d0
InitLib:
	move.l 4.w,a6			; a6=exec base addr
	moveq #33,d0			; d0=version#
	jsr _LVOOpenLibrary(a6)	; d0=lib
	rts
****
* assumes that libs have been loaded
Main:


.initGlobals:
	clr.l FirstSprEditor
.openScreen:
	move.l IntuiBase,a6
	lea.l ScrDef,a0
	jsr _LVOOpenScreen(a6)
	tst.l d0		; success?
	beq.w .done
	move.l d0,ScrP
; now that the screen is opened, set it up and install it into the win cfs
	bsr.w SetupScr
.openProjWin:
	move.l IntuiBase,a6
	lea.l ProjNewWin,a0
	jsr _LVOOpenWindow(a6)
	tst.l d0
	beq.s .closeScreen
	move.l d0,ProjWinP
.attachProjMenu:
	bsr.w InitMenus
	move.l ProjWinP,a0
	lea.l ProjMenu,a1
	move.l IntuiBase,a6
	jsr _LVOSetMenuStrip(a6)
	tst.l d0
	beq.s .closeProjWin
.activateProjWin:
	move.l ProjWinP,a0
	move.l IntuiBase,a6
	jsr _LVOActivateWindow(a6)
.initSigMask:
	clr.l SignalMask
	move.l ProjWinP,a0
	bsr.w AddWinToSigMask
; jump into the main loop
	bsr.w MainLoop
	bsr.w CloseSpriteEditors
.detachMenu:
	move.l ProjWinP,a0
	move.l IntuiBase,a6
	jsr _LVOClearMenuStrip(a6)
.closeProjWin:
	move.l IntuiBase,a6
	move.l ProjWinP,a0
	jsr _LVOCloseWindow(a6)
.closeScreen:	
	move.l ScrP,a0
	jsr _LVOCloseScreen(a6)
.done:	rts
****
SetupScr:
	bsr.s InitBorderInfo
	bsr.s InitPal
	bsr.w InsScrP2WinDefs
	bsr.w AddBor2NewWins
; TODO: put me in a function
	lea.l SprEditorTemplate,a0
	lea.l SpriteEditor_NumGG(a0),a1
	lea.l SpriteEditor_NameGG(a0),a0
	move.w BorderTop,d0
	add.w d0,gg_TopEdge(a0)
	add.w d0,gg_TopEdge(a1)
	moveq.l #0,d0
	move.b BorderLeft,d0
	add.w d0,gg_LeftEdge(a0)
	add.w d0,gg_LeftEdge(a1)
	rts
****
InitBorderInfo:
	move.l ScrP,a0
	move.b sc_WBorLeft(a0),BorderLeft
	move.b sc_WBorRight(a0),BorderRight
	move.b sc_WBorBottom(a0),BorderBottom
	moveq #0,d0
	move.b sc_WBorTop(a0),d0
	move.l sc_Font(a0),a0
	add.w ta_YSize(a0),d0
	addq #1,d0
	move.w d0,BorderTop
	rts
****
InitPal:
	movem.l d2-d4/a2-a3,-(sp)
.getViewport:
	move.l ScrP,a0
	lea.l sc_ViewPort(a0),a2
.init:
	lea.l Palette,a3
	move.l GfxBase,a6
	moveq #4-1,d4
.loop:
	move.l a2,a0		; a0=Viewport
	move.w d4,d0		; d0=palette #
	movem.w (a3)+,d1-d3	; d1-d3=entries
	jsr _LVOSetRGB4(a6)
	dbra d4,.loop
	movem.l (sp)+,d2-d4/a2-a3
	rts
****
InsScrP2WinDefs:
	move.l ScrP,d0
	lea.l AllNewWins,a0
	moveq #NUM_OF_NEWWINS-1,d1
.loop:	move.l (a0)+,a1
	move.l d0,nw_Screen(a1)
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
	move.w nw_Width(a0),d0
	move.w nw_Height(a0),d1
	add.b BorderLeft,d0
	add.b BorderRight,d0
	add.w BorderTop,d1
	add.b BorderBottom,d1
	move.w d0,nw_Width(a0)
	move.w d0,nw_MinWidth(a0)
	move.w d0,nw_MaxWidth(a0)
	move.w d1,nw_Height(a0)
	move.w d1,nw_MinHeight(a0)
	move.w d1,nw_MaxHeight(a0)
	rts
****
* This is where we'll dynamically size the menus, should we ever get around
* to that
InitMenus:
	rts
****
* a0 - ptr to window to add to sig mask
AddWinToSigMask:
	move.l wd_UserPort(a0),a0
	move.b MP_SIGBIT(a0),d1
	moveq #1,d0
	lsl.l d1,d0
	or.l d0,SignalMask
	rts
****
* a0 - ptr to window to rem from sig mask
RemWinFromSigMask:
	move.l wd_UserPort(a0),a0
	move.b MP_SIGBIT(a0),d1
	moveq #1,d0
	lsl.l d1,d0
	not.l d0
	and.l d0,SignalMask
	rts
****
MainLoop:
	clr.b QuitFlag
.eventLoop:
	move.l SignalMask,d0
	move.l 4.w,a6
	jsr _LVOWait(a6)
	bsr.s MsgLoop
	tst.b QuitFlag
	beq.s .eventLoop
	rts
****
* d0 - bitmask of signals that occurred
MsgLoop:
	move.l d0,-(sp)
	bsr.s ChkForProjMsgs
	move.l (sp)+,d0				; d0=Signals
	bsr.s ChkForSprEditorMsgs
	rts
****
* a0 - window to check for
* d0 - bitmask of signals that occurred
* returns Z if not a match
ChkForWinMsgs:
	moveq #0,d1
	move.l wd_UserPort(a0),a0
	move.b MP_SIGBIT(a0),d1
	btst d1,d0
	rts
****
* d0 - bitmask of signals that occurred
ChkForProjMsgs:
	move.l ProjWinP,a0
	bsr.s ChkForWinMsgs
	beq.s .done
	bsr.s HandleProjMsgs
.done:
	rts
****
* d0 - bitmask of signals that occurred
ChkForSprEditorMsgs:
	movem.l d2/a2,-(sp)
	move.l d0,d2							; d2 = sig set
	move.l FirstSprEditor,a2
	bra.s .test
.loop:
	move.l SpriteEditor_Window(a2),a0
	move.l d2,d0
	bsr.s ChkForWinMsgs
	beq.s .next
	move.l a2,a0
	bsr.s HandleSprEditorMsgs
.next:
	move.l SpriteEditor_Next(a2),a2
.test:
	cmp.l #0,a2
	bne.s .loop
	movem.l (sp)+,d2/a2
	rts
****
* a0 - UserPort to check
GetAckMsg:
	move.l 4.w,a6
    jsr _LVOGetMsg(a6)
	tst.l d0
	beq.s .done
	move.l d0,-(sp)
	move.l d0,a1
	jsr _LVOReplyMsg(a6)
	move.l (sp)+,d0
.done:	rts
****
HandleProjMsgs:
	move.l a2,-(sp)
	move.l ProjWinP,a2
	move.l wd_UserPort(a2),a2
.loop:
	move.l a2,a0			; a0=UserPort
	bsr.s GetAckMsg
	tst.l d0
	beq.s .done
	move.l d0,a0			; a0=Msg
.dispatch:
	move.l im_Class(a0),d0
	cmp.l #MENUPICK,d0
	beq.s .menuPick
	bra.s .loop
.menuPick:
	move.w im_Code(a0),d0
	bsr.w HandleMenu
	bra.s .loop
.done:
	move.l (sp)+,a2
	rts
****
* a0 - contains ptr to sprite editor
HandleSprEditorMsgs:
	movem.l d2/a2-a3,-(sp)
	move.l a0,a3						; a3=SpriteEditor
	move.l SpriteEditor_Window(a0),a0
	move.l wd_UserPort(a0),a2
.loop:
	move.l a2,a0						; a0=UserPort
	bsr.s GetAckMsg
	tst.l d0
	beq.w .done
	move.l d0,a0						; a0=Msg
.dispatch:
	move.l im_Class(a0),d0
	cmp.l #IDCMP_CLOSEWINDOW,d0
	beq.s .closeWindow
	cmp.l #IDCMP_GADGETUP,d0
	beq.s .onGadgetUp
	cmp.l #IDCMP_GADGETDOWN,d0
	beq.s .onGadgetDown
	cmp.l #IDCMP_MOUSEBUTTONS,d0
	beq.s .onMouseButtons
	cmp.l #IDCMP_MOUSEMOVE,d0
	beq.s .onMouseMove
	bra.s .loop
.closeWindow:
	move.l a3,a0						; a0 = spr editor
	bsr.s RemoveSpriteEditor
	move.l SpriteEditor_Window(a3),a0	; a0 = spr editor window
	bsr.w RemWinFromSigMask
	move.l a3,a0						; a0 = spr editor once more
	jsr CloseSpriteEditor
	bra.s .loop
.onGadgetUp:
	move.l im_IAddress(a0),a1			; a1 = gadget clicked
	move.l a3,a0						; a0 = sprite editor
	jsr SpriteEditorGadgetUp
	bra.s .loop
.onGadgetDown:
	move.l im_IAddress(a0),a1
	move.l a3,a0
	jsr SpriteEditorGadgetDown
	bra.s .loop
.onMouseButtons:
	move.w im_MouseX(a0),d0
	move.w im_MouseY(a0),d1
	move.w im_Code(a0),d2
	move.l a3,a0
	jsr SpriteEditorMouseButtons
	bra.w .loop
.onMouseMove:
	move.w im_MouseX(a0),d0
	move.w im_MouseY(a0),d1
	move.l a3,a0
	jsr SpriteEditorMouseMove
	bra.w .loop
.done:
	movem.l (sp)+,d2/a2-a3
	rts
****
* a0 - sprite editor to be removed
RemoveSpriteEditor:
.prev:
	tst.l SpriteEditor_Prev(a0)
	beq.s .noPrev
	move.l SpriteEditor_Prev(a0),a1
	move.l SpriteEditor_Next(a0),SpriteEditor_Next(a1)	; prev.next=dead.next
	bra.s .next
.noPrev:
	move.l SpriteEditor_Next(a0),FirstSprEditor			; first = dead.next
.next:
	tst.l SpriteEditor_Next(a0)
	beq.s .done
	move.l SpriteEditor_Next(a0),a1
	move.l SpriteEditor_Prev(a0),SpriteEditor_Prev(a1)	; next.prev=dead.prev
.done:
	rts
****
* d0 - contains Menu Number
HandleMenu:
	cmp.l #MENUNULL,d0
	bne.s .validSelection
	rts
.validSelection:
	move.w d0,d1
	and.w #$001F,d1			; d1 = Menu
	lea.l MenuHandlers,a0
	lsl.w #2,d1				; get index in bytes
	move.l (a0,d1.w),a0		; a0 = Menu Handler Table
	and.w #$07E0,d0			; isolate Menu Item
	lsr.w #3,d0				; d0 = index in bytes
	move.l (a0,d0.w),a0		; a0 = handler
	jmp (a0)				; jump to routine
****
NewItemHandler:
	rts
****
SaveItemHandler:
	rts
****
SaveAsItemHandler:
	rts
****
QuitItemHandler:
	move.b #1,QuitFlag
	rts
****
NewSpriteItemHandler:
	jsr NewSpriteEditor
	tst.l d0
	beq.s .done
.install:
	move.l d0,a0								; a0 = new
	move.l FirstSprEditor,SpriteEditor_Next(a0)
	tst.l FirstSprEditor						; was there an oldfirst?
	beq.s .noPrev
	move.l FirstSprEditor,a1
	move.l a0,SpriteEditor_Prev(a1)				; oldfirst.prev = new
.noPrev:
	move.l a0,FirstSprEditor					; first = new
	move.l SpriteEditor_Window(a0),a0
	bsr.w AddWinToSigMask
.done:
	rts
****
CloseSpriteEditors:
	move.l d2,-(sp)
	move.l FirstSprEditor,d2
	bra.s .test
.loop:
	move.l d2,a0
	move.l SpriteEditor_Next(a0),d2
	bsr.w CloseSpriteEditor
.test:
	tst.l d2
	bne.s .loop
	move.l (sp)+,d2
	rts
****************

	SECTION MyData,DATA

IntuiName:
	dc.b "intuition.library",0

GfxName:
	dc.b "graphics.library",0

ReqName:
	dc.b "reqtools.library",0

	EVEN
Palette:
	dc.w 0,0,0				; black
	dc.w 5,5,5
	dc.w 10,10,10
	dc.w 15,15,15			; white

Title:
	dc.b "FracIDE",0

SCR_WIDTH	=320
SCR_HEIGHT	=256

	EVEN
ScrDef:
	dc.w 0,0					; left,top
	dc.w SCR_WIDTH,SCR_HEIGHT	; width/height
	dc.w 2						; bits per pixel
	dc.b 0,1					; default pens
	dc.w 0						; lo res view mode
	dc.w SHOWTITLE
	dc.l 0						; default font
	dc.l Title
	dc.l 0						; no custom gadgets
	dc.l 0						; no custom bitmap

**** Project Window

ProjStr:
	dc.b "Project",0

	EVEN
ProjNewWin:
	dc.w 0,0			; top, left
	dc.w SCR_WIDTH,SCR_HEIGHT	; width/height - get from screen
	dc.b -1,-1			; default pens
	dc.l MENUPICK			; messages to listen for
	dc.l BORDERLESS!BACKDROP
	dc.l 0				; no gadgets
	dc.l 0				; default checkmark
	dc.l ProjStr
	dc.l 0				; write screen ptr here
	dc.l 0				; no bitmap
	dc.w SCR_WIDTH,SCR_HEIGHT	; min width/height
	dc.w SCR_WIDTH,SCR_HEIGHT	; max width/height
	dc.w CUSTOMSCREEN

******** Menu Text

**** Sprites Menu Text

SpritesStr:
	dc.b "Sprites",0

NewSpriteStr:
	dc.b "New Sprite...",0

	EVEN
NewSpriteTxt:
	dc.b 0,0			; pens
	dc.b 0				; draw mode (JAM1)
	dc.b 0				; padding
	dc.w 0,0			; left, top
	dc.l 0				; default font
	dc.l NewSpriteStr
	dc.l 0				; next

**** Proj Menu Text

NewStr:
	dc.b "New",0
	
	EVEN
NewTxt:
	dc.b 0,0
	dc.b 0
	dc.b 0
	dc.w 0,0
	dc.l 0
	dc.l NewStr
	dc.l 0

SaveStr:
	dc.b "Save",0
	
	EVEN
SaveTxt:
	dc.b 0,0
	dc.b 0
	dc.b 0
	dc.w 0,0
	dc.l 0
	dc.l SaveStr
	dc.l 0

SaveAsStr:
	dc.b 'Save As...',0
	
	EVEN
SaveAsTxt:
	dc.b 0,0
	dc.b 0
	dc.b 0
	dc.w 0,0
	dc.l 0
	dc.l SaveAsStr
	dc.l 0

ExitStr:
	dc.b "Exit",0

	EVEN
ExitTxt:
	dc.b 0,0			; pens
	dc.b 0				; draw mode (JAM1)
	dc.b 0				; padding
	dc.w 0,0			; left,	top
	dc.l 0				; default font
	dc.l ExitStr
	dc.l 0				; next

******** MenuItems

**** Project MenuItems

	EVEN
NewMenuItem:
	dc.l SaveMenuItem
	dc.w 0,0
	dc.w 120,10
	dc.w ITEMTEXT!COMMSEQ!ITEMENABLED!HIGHCOMP
	dc.l 0
	dc.l NewTxt
	dc.l 0
	dc.b 'N'
	dc.b 0
	dc.l 0
	dc.w 0

	EVEN
SaveMenuItem:
	dc.l SaveAsMenuItem
	dc.w 0,12
	dc.w 120,10			; width, height
	dc.w ITEMTEXT!COMMSEQ!ITEMENABLED!HIGHCOMP
	dc.l 0
	dc.l SaveTxt
	dc.l 0
	dc.b 'S'
	dc.b 0
	dc.l 0
	dc.w 0
	
	EVEN
SaveAsMenuItem:
	dc.l ExitMenuItem
	dc.w 0,24
	dc.w 120,10
	dc.w ITEMTEXT!COMMSEQ!ITEMENABLED!HIGHCOMP
	dc.l 0
	dc.l SaveAsTxt
	dc.l 0
	dc.b 'A'
	dc.b 0
	dc.l 0
	dc.w 0
	
	EVEN
ExitMenuItem:
	dc.l 0				; next item
	dc.w 0,36			; left, top
	dc.w 120,10			; width, height
; flags
	dc.w ITEMTEXT!COMMSEQ!ITEMENABLED!HIGHCOMP
	dc.l 0				; mutual exclusion
	dc.l ExitTxt
	dc.l 0				; different highlighted text
	dc.b "Q"			; shortcut
	dc.b 0				; padding
	dc.l 0				; sub-item
	dc.w 0				; "next select"

**** Sprites MenuItems

NewSpriteMenuItem:
	dc.l 0				; next item
	dc.w 0,0			; left, top
	dc.w 100			; width
	dc.w 10				; height
	dc.w ITEMTEXT!ITEMENABLED!HIGHCOMP
	dc.l 0				; mutual exclusion
	dc.l NewSpriteTxt
	dc.l 0				; no different highlighted text
	dc.b 0				; no shortcut
	dc.b 0				; padding
	dc.l 0				; no subitems
	dc.w 0				; next select

******** Menus

; TODO: dynamically compute the sizes/positions of things

SpritesMenu:
	dc.l 0						; next menu
	dc.w 82,0					; left/top
	dc.w 60						; width
	dc.w 10						; height
	dc.w MENUENABLED			; flags
	dc.l SpritesStr				; text
	dc.l NewSpriteMenuItem		; first item
	dc.w 0,0,0,0

ProjMenu:
	dc.l SpritesMenu		; next menu
	dc.w 2,0				; left, top
	dc.w 60					; width
	dc.w 30					; height
	dc.w MENUENABLED		; flags
	dc.l ProjStr			; text
	dc.l NewMenuItem		; first item
	dc.w 0,0,0,0			; for internal use only

******** Menu Handler Tables

MenuHandlers:
	dc.l ProjMenuHandlers,SpritesMenuHandlers

ProjMenuHandlers:
	dc.l NewItemHandler,SaveItemHandler,SaveAsItemHandler
	dc.l QuitItemHandler

SpritesMenuHandlers:
	dc.l NewSpriteItemHandler

******** NewWindow info

AllNewWins:
	dc.l SprNewWin,ProjNewWin
NUM_OF_NEWWINS	=2
