	INCDIR Frac:FracIDE/
	INCLUDE Exec.i
	INCLUDE Graphics.i
	INCLUDE Intuition.i

	SECTION Tramp,CODE
	jmp Start

	SECTION Globals,BSS
ScrP:		ds.l 1
ProjWinP:	ds.l 1
PalWinP:	ds.l 1
SprWinP:	ds.l 1
IntuiBase:	ds.l 1
GfxBase:	ds.l 1
BorderTop:	ds.w 1
BorderLeft:	ds.b 1
BorderRight:	ds.b 1
BorderBottom:	ds.b 1
QuitFlag:	ds.b 1

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
	lea.l ProjNewWin,a0
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
* This is where we'll dynamically size the menus, should we ever get around
* to that
InitMenus:
	rts
****
MainLoop:
	clr.b QuitFlag
.eventLoop:
	move.l ProjWinP,a0
	bsr.s WinWait
	move.l ProjWinP,a0
	move.l Window_UserPort(a0),a0	; a0=UserPort
	bsr.s MsgLoop
	tst.b QuitFlag
	beq.s .eventLoop
	rts
****
* a0 - ptr to window to wait for a signal from
WinWait:
	move.l Window_UserPort(a0),a0
	move.b MsgPort_SigBit(a0),d1
	moveq #1,d0
	lsl.l d1,d0
	move.l 4.w,a6
	jsr _Wait(a6)
	rts
****
; a0 - pointer to UserPort
MsgLoop:
	movem.l a2-a3,-(sp)
	move.l a0,a3			; a3=UserPort
.loop:	move.l a3,a0			; a0=UserPort
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
	move.w IntuiMessage_Code(a2),d0
	bsr.s HandleMenu
	bra.s .loop
.done:	movem.l (sp)+,a2-a3
	rts
****
* d0 - contains Menu Number
HandleMenu:
	move.w d0,d1
	and.w #$001F,d1			; d1 = Menu
	lea.l MenuHandlers,a0
	lsl.w #2,d1			; get index in bytes
	move.l (a0,d1.w),a0		; a0 = Menu Handler Table
	and.w #$07E0,d0			; isolate Menu Item
	lsr.w #3,d0			; d0 = index in bytes
	move.l (a0,d0.w),a0		; a0 = handler
	jmp (a0)			; jump to routine
****
QuitItemHandler:
	move.b #1,QuitFlag
	rts
****
NewSpriteItemHandler:
	movem.l a2-a3,-(sp)
	bsr.s AllocNewTask		; a0 = ptr to task
	move.l a0,a1			; a1 = ptr to task
	lea.l SpriteMain,a2		; a2 = code
	move.l #0,a3			; no special exit code
	move.l 4.w,a6
	jsr _AddTask(a6)
	movem.l (sp)+,a2-a3
	rts
****
* returns in a0 ptr to new Task
AllocNewTask:
	movem.l a2-a3,-(sp)
	lea.l TaskMemList,a0
	move.l 4.w,a6			; a6=Exec
	jsr _AllocEntry(a6)
	move.l d0,a2			; a2=memory list
	move.l MemList_ME(a2),a3	; a3=new Task
.initStack:
; d0 = ptr to stack
	move.l (MemList_ME+MEMENTRY_SIZE)(a2),d0
	move.l d0,Task_SPLower(a3)
	add.l #4096,d0			; d0 = top of stack
	move.l d0,Task_SPUpper(a3)
	move.l d0,Task_SPReg(a3)
.initNode:
	move.b #NT_TASK,Node_Type(a3)
	clr.b Node_Pri(a3)
	move.l #SpritesStr,Node_Name(a3)
.initList:
	lea.l Task_MemEntry(a3),a0
	bsr.s NewList
	move.l a2,a1			; a1=memory list
	move.l 4.w,a6
	jsr _AddHead(a6)
.done:	move.l a3,a0			; a0 = new Task
	movem.l (sp)+,a2-a3
	rts
****
* a0 - points to uninitialied List
* returns same, now initialized List in a0
NewList:
	move.l a0,List_Head(a0)
	addq.l #4,List_Head(a0)		; head now points to tail
	clr.l List_Tail(a0)
	move.l a0,List_TailPred(a0)	; tailpred points to head
	rts
****************

	SECTION MyData,DATA

TaskMemList:
	dcb.b NODE_SIZE,0		; no node info
	dc.w 2				; number of entries
; entry 1 - the task
	dc.l MEMF_PUBLIC!MEMF_CLEAR	; public memory, zeroed out
	dc.l TASK_SIZE
; entry 2 - the stack
	dc.l MEMF_CLEAR			; private memory, zeroed out
	dc.l 4096			; 4k stack

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

SCR_WIDTH	=640
SCR_HEIGHT	=256

	EVEN
ScrDef:
	dc.w 0,0			; left,top
	dc.w SCR_WIDTH,SCR_HEIGHT	; width/height
	dc.w 2				; bits per pixel
	dc.b 0,1			; default pens
	dc.w HIRES
	dc.w SHOWTITLE
	dc.l 0				; default font
	dc.l Title
	dc.l 0				; no custom gadgets
	dc.l 0				; no custom widgets

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
ExitMenuItem:
	dc.l 0				; next item
	dc.w 0,0			; left, top
	dc.w 80				; width
	dc.w 10				; height
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
	dc.l 0				; next menu
	dc.w 82,0			; left/top
	dc.w 80				; width
	dc.w 10				; height
	dc.w MENUENABLED		; flags
	dc.l SpritesStr			; text
	dc.l NewSpriteMenuItem		; first item
	dc.w 0,0,0,0

ProjMenu:
	dc.l SpritesMenu		; next menu
	dc.w 2,0			; left, top
	dc.w 80				; width
	dc.w 10				; height
	dc.w MENUENABLED		; flags
	dc.l ProjStr			; text
	dc.l ExitMenuItem		; first item
	dc.w 0,0,0,0			; for internal use only

******** Menu Handler Tables

MenuHandlers:
	dc.l ProjMenuHandlers,SpritesMenuHandlers

ProjMenuHandlers:
	dc.l QuitItemHandler

SpritesMenuHandlers:
	dc.l NewSpriteItemHandler

******** NewWindow info

AllNewWins:
	dc.l SprNewWin,ProjNewWin
NUM_OF_NEWWINS	=2

**** ASM-One doesn't like including the other modules at the top

	INCLUDE SpriteEditor.S
