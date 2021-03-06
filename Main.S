	INCLUDE "dos/dos.i"
	INCLUDE "dos/dos_lib.i"
	INCLUDE "exec/exec.i"
	INCLUDE "exec/exec_lib.i"
	INCLUDE "graphics/gfx.i"
	INCLUDE "graphics/graphics_lib.i"
	INCLUDE "intuition/intuition.i"
	INCLUDE "intuition/intuition_lib.i"
	INCLUDE "reqtools.i"
	INCLUDE "reqtools_lib.i"

	INCLUDE "globals.i"
	INCLUDE "Project.i"
	INCLUDE "TileEditor.i"
	INCLUDE "TileEditor_intf.i"
	INCLUDE "TilesetBrowser.i"
	INCLUDE "TilesetBrowser_intf.i"

	jmp Start

	SECTION MainVars,BSS
ScrP:				ds.l 1
ProjWinP:			ds.l 1
SignalMask:			ds.l 1
FirstTileEditor:	ds.l 1
TilesetBrowser:		ds.l TILESETBROWSER_SIZEOF
BorderTop:			ds.w 1
BorderLeft:			ds.b 1
BorderRight:		ds.b 1
BorderBottom:		ds.b 1
QuitFlag:			ds.b 1
ProjectFilename:	ds.b 108

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
.initDos:
	lea.l DosName,a1
	bsr.s InitLib
	tst.l d0
	beq.s .closeReq
	move.l d0,DosBase
; libraries loaded, start program
	bsr.w Main
.closeDos:
	move.l DosBase,a1
	move.l 4.w,a6
	jsr _LVOCloseLibrary(a6)
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
* returns Z if cancelled, otherwise NZ and path in ProjectFilename
SelectProject:
	movem.l d2/a2-a4,-(sp)
.allocReq:
	move.l #RT_FILEREQ,d0
	move.l #0,a0
	move.l ReqBase,a6
	jsr _LVOrtAllocRequestA(a6)
	tst.l d0
	beq.s .done
	move.l d0,a4
.callReq:
	move.l #0,a0
	move.l a4,a1
	lea.l ProjectFilename,a2
	clr.b (a2)
	lea.l SelectProjectTxt,a3
	move.l ReqBase,a6
	jsr _LVOrtFileRequestA(a6)
	move.l d0,d2
.freeReq:
	move.l a4,a1
	move.l ReqBase,a6
	jsr _LVOrtFreeRequest(a6)
.retCode:
	tst.l d2
.done:
	movem.l (sp)+,d2/a2-a4
	rts
****
* Returns Z if the header is OK, otherwise NZ
ValidateHeader:
	movem.l d2-d3,-(sp)
	subq.l #4,sp
	move.l d0,d1
	move.l sp,d2
	move.l #4,d3
	move.l DosBase,a6
	jsr _LVORead(a6)
	cmp.l #4,d0
	bne.s .done
	cmp.l #'FRAC',(sp)
.done:
	; we use ADDA specifically to avoid setting flags
	adda.l #4,sp
	movem.l (sp)+,d2-d3
	rts
****
* Attempts to load the project in ProjectFilename
* returns Z on failure and NZ on success
LoadProject:
	movem.l d2-d4,-(sp)
	move.l #ProjectFilename,d1
	move.l #MODE_OLDFILE,d2
	move.l DosBase,a6
	jsr _LVOOpen(a6)
	tst.l d0
	beq.s .done
	move.l d0,d4				; d4 = file
	bsr.w ValidateHeader
	bne.s .closeFileOnFailure
	move.l d4,d1				; d1 = file
	move.l #Project,d2
	move.l #PROJECT_SIZEOF,d3
	move.l DosBase,a6
	jsr _LVORead(a6)
.closeFile:
	move.l d4,d1				; d1 = file
	move.l DosBase,a6
	jsr _LVOClose(a6)
	bra.s .done
.closeFileOnFailure:
	move.l d4,d1				; d1 = ile
	move.l DosBase,a6
	jsr _LVOClose(a6)
	ori.b #$04,ccr				; set zero!
.done:
	movem.l (sp)+,d2-d4
	rts
****
* Writes the currently loaded project to disk
SaveProject:
	movem.l d2-d4,-(sp)
.openFile:
	move.l #ProjectFilename,d1
	move.l #MODE_NEWFILE,d2
	move.l DosBase,a6
	jsr _LVOOpen(a6)
	tst.l d0
	beq.s .done
	move.l d0,d4			; d4 = File
.writeHeader:
	move.l d4,d1			; d1 = File
	subq.l #4,sp
	move.l #'FRAC',(sp)
	move.l sp,d2
	moveq.l #4,d3			; d3 = write 4 bytes
	move.l DosBase,a6
	jsr _LVOWrite(a6)
	addq.l #4,sp
.writeProject:
	move.l d4,d1			; d1 = File
	move.l #Project,d2
	move.l #PROJECT_SIZEOF,d3
	move.l DosBase,a6
	jsr _LVOWrite(a6)
.closeFile:
	move.l d4,d1
	move.l DosBase,a6
	jsr _LVOClose(a6)
.done:
	movem.l (sp)+,d2-d4
	rts
****
* Writes just one tileset to disk
* d0 - number of the tileset to save
SaveTileset:
	movem.l d2-d4,-(sp)
	move.w d0,-(sp)
.openFile:
	move.l #ProjectFilename,d1
	move.l #MODE_OLDFILE,d2
	move.l DosBase,a6
	jsr _LVOOpen(a6)
	tst.l d0
	beq.w .done
	move.l d0,d4								; d4 = File
.seekToCnt:
	move.l d4,d1								; d1 = File
	move.l #4,d2								; skip header
	move.l #OFFSET_BEGINNING,d3
	move.l DosBase,a6
	jsr _LVOSeek(a6)
.writeCount:
	move.l d4,d1								; d1 = File
	move.l #Project+Project_TilesetCnt,d2		; d2 = ptr to Count
	move.l #2,d3								; d3 = two bytes
	move.l DosBase,a6
	jsr _LVOWrite(a6)
.seekToName:
	move.l d4,d1								; d1 = File
	move.w (sp),d2								; d2 = tileset to write
	and.l #$0000FFFF,d2							; cast to long
	lsl.l #4,d2									; get offset
	move.l #OFFSET_CURRENT,d3
	move.l DosBase,a6
	jsr _LVOSeek(a6)
.writeName:
	move.l d4,d1								; d1 = File
	move.w (sp),d2								; d0 = tileset to write
	lsl.l #4,d2									; get offset
	lea.l Project+Project_TilesetNames,a0
	lea.l (a0,d2),a0							; a0 = address of name
	move.l a0,d2								; d2 = address of name
	move.l #16,d3								; 16 bytes
	move.l DosBase,a6
	jsr _LVOWrite(a6)
.seekToTiles:
	move.l d4,d1								; d1 = file
	move.w (sp),d2								; d2 = tileset to write
	and.l #$0000FFFF,d2							; cast to long
	lsl.l #8,d2									; get offset
	lsl.l #4,d2
	add.l #(4+Project_TilesetImgs),d2			; get offset into file
	move.l #OFFSET_BEGINNING,d3
	move.l DosBase,a6
	jsr _LVOSeek(a6)
.writeTiles:
	move.l d4,d1								; d1 = File
	move.w (sp),d2								; d0 = tileset to write
	lsl.l #8,d2									; get offset
	lsl.l #4,d2
	lea.l Project+Project_TilesetImgs,a0
	lea.l (a0,d2),a0							; a0 = address of name
	move.l a0,d2								; d2 = address of name
	move.l #4096,d3								; 4096 bytes
	move.l DosBase,a6
	jsr _LVOWrite(a6)
.seekToPassableInfo:
	move.l d4,d1								; d1 = file
	move.w (sp),d2								; d2 = tileset to write
	and.l #$0000FFFF,d2							; cast to long
	lsl.l #6,d2									; get offset
	add.l #(4+Project_TilesetPassable),d2		; get offset into file
	move.l #OFFSET_BEGINNING,d3
	move.l DosBase,a6
	jsr _LVOSeek(a6)
.writePassableInfo:
	move.l d4,d1								; d1 = File
	move.w (sp),d2								; d0 = tileset to write
	lsl.l #6,d2									; get offset
	lea.l Project+Project_TilesetPassable,a0
	lea.l (a0,d2),a0							; a0 = address of name
	move.l a0,d2								; d2 = address of name
	move.l #64,d3								; 64 bytes
	move.l DosBase,a6
	jsr _LVOWrite(a6)
.closeFile:
	move.l d4,d1
	move.l DosBase,a6
	jsr _LVOClose(a6)
.done:
	addq.l #2,sp							; pop off stored d0
	movem.l (sp)+,d2-d4
	rts
****
* Reverts a Tileset from Disk
* d0 - number of the tileset to save
RevertTileset:
	movem.l d2-d4,-(sp)
	move.w d0,-(sp)
.openFile:
	move.l #ProjectFilename,d1
	move.l #MODE_OLDFILE,d2
	move.l DosBase,a6
	jsr _LVOOpen(a6)
	tst.l d0
	beq.w .done
	move.l d0,d4								; d4 = File
.seekToCnt:
	move.l d4,d1								; d1 = File
	move.l #4,d2								; skip header
	move.l #OFFSET_BEGINNING,d3
	move.l DosBase,a6
	jsr _LVOSeek(a6)
.readCount:
	move.l d4,d1								; d1 = File
	move.l #Project+Project_TilesetCnt,d2		; d2 = ptr to Count
	move.l #2,d3								; d3 = two bytes
	move.l DosBase,a6
	jsr _LVORead(a6)
.seekToName:
	move.l d4,d1								; d1 = File
	move.w (sp),d2								; d2 = tileset to write
	and.l #$0000FFFF,d2							; cast to long
	lsl.l #4,d2									; get offset
	move.l #OFFSET_CURRENT,d3
	move.l DosBase,a6
	jsr _LVOSeek(a6)
.readName:
	move.l d4,d1								; d1 = File
	move.w (sp),d2								; d0 = tileset to write
	lsl.l #4,d2									; get offset
	lea.l Project+Project_TilesetNames,a0
	lea.l (a0,d2),a0							; a0 = address of name
	move.l a0,d2								; d2 = address of name
	move.l #16,d3								; 16 bytes
	move.l DosBase,a6
	jsr _LVORead(a6)
.seekToTiles:
	move.l d4,d1								; d1 = file
	move.w (sp),d2								; d2 = tileset to write
	and.l #$0000FFFF,d2							; cast to long
	lsl.l #8,d2									; get offset
	lsl.l #4,d2
	add.l #(4+Project_TilesetImgs),d2			; get offset into file
	move.l #OFFSET_BEGINNING,d3
	move.l DosBase,a6
	jsr _LVOSeek(a6)
.readTiles:
	move.l d4,d1								; d1 = File
	move.w (sp),d2								; d0 = tileset to write
	lsl.l #8,d2									; get offset
	lsl.l #4,d2
	lea.l Project+Project_TilesetImgs,a0
	lea.l (a0,d2),a0							; a0 = address of name
	move.l a0,d2								; d2 = address of name
	move.l #4096,d3								; 4096 bytes
	move.l DosBase,a6
	jsr _LVORead(a6)
.seekToPassableInfo:
	move.l d4,d1								; d1 = file
	move.w (sp),d2								; d2 = tileset to write
	and.l #$0000FFFF,d2							; cast to long
	lsl.l #6,d2									; get offset
	add.l #(4+Project_TilesetPassable),d2		; get offset into file
	move.l #OFFSET_BEGINNING,d3
	move.l DosBase,a6
	jsr _LVOSeek(a6)
.readPassableInfo:
	move.l d4,d1								; d1 = File
	move.w (sp),d2								; d0 = tileset to write
	lsl.l #6,d2									; get offset
	lea.l Project+Project_TilesetPassable,a0
	lea.l (a0,d2),a0							; a0 = address of name
	move.l a0,d2								; d2 = address of name
	move.l #64,d3								; 64 bytes
	move.l DosBase,a6
	jsr _LVORead(a6)
.closeFile:
	move.l d4,d1
	move.l DosBase,a6
	jsr _LVOClose(a6)
.done:
	addq.l #2,sp							; pop off stored d0
	movem.l (sp)+,d2-d4
	rts
****
* Creates a dummy project in ProjectFilename
CreateProject:
	lea.l Project,a0
	move.w #((PROJECT_SIZEOF/2)-1),d0		; d0 = number of words to clear
.loop:
	clr.w (a0)+
	dbra d0,.loop
	bra.w SaveProject
****
* assumes that libs have been loaded
Main:
	bsr.w SelectProject
	beq.w .done						; if there was an error, quit
	bsr.w LoadProject
	bne.s .initGlobals
	bsr.s CreateProject				; if we couldn't open it, create it
	beq.w .done
.initGlobals:
	clr.l FirstTileEditor
.openScreen:
	move.l IntuiBase,a6
	lea.l ScrDef,a0
	jsr _LVOOpenScreen(a6)
	tst.l d0						; success?
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
	bsr.w CloseTileEditors
	bsr.w CloseTilesetBrowserIfOpen
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
.done:
	rts
****
SetupScr:
	bsr.s InitBorderInfo
	bsr.s InitPal
	bsr.w InsScrP2WinDefs
	bsr.w AddBor2NewWins
; TODO: put me in a function
	lea.l TileEditorTemplate,a0
	lea.l TileEditor_NumGG(a0),a1
	lea.l TileEditor_NameGG(a0),a0
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
	lea.l TileNewWin,a0
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
	move.l (sp),d0				; d0=Signals
	bsr.s ChkForTileEditorMsgs
	move.l (sp)+,d0				; d0=Signals
	bsr.s ChkForBrowserMsgs
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
ChkForBrowserMsgs:
	move.l TilesetBrowser+TilesetBrowser_Window,a0
	bsr.s ChkForWinMsgs
	beq.s .done
	bsr.s HandleBrowserMsgs
.done:
	rts
****
* d0 - bitmask of signals that occurred
ChkForTileEditorMsgs:
	movem.l d2/a2,-(sp)
	move.l d0,d2							; d2 = sig set
	move.l FirstTileEditor,a2
	bra.s .test
.loop:
	move.l TileEditor_Window(a2),a0
	move.l d2,d0
	bsr.s ChkForWinMsgs
	beq.s .next
	move.l a2,a0
	bsr.w HandleTileEditorMsgs
.next:
	move.l TileEditor_Next(a2),a2
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
HandleBrowserMsgs:
	move.l a2,-(sp)
	move.l TilesetBrowser+TilesetBrowser_Window,a2
	move.l wd_UserPort(a2),a2
.loop:
	move.l a2,a0
	bsr.s GetAckMsg
	tst.l d0
	beq.s .done
	move.l d0,a0						; a0=Msg
.dispatch
	move.l im_Class(a0),d0
	cmp.l #IDCMP_CLOSEWINDOW,d0
	beq.s .closeWindow
	cmp.l #IDCMP_GADGETUP,d0
	beq.s .onGadgetUp
	cmp.l #IDCMP_GADGETDOWN,d0
	beq.s .onGadgetDown
	bra.s .loop
.closeWindow:
	move.l TilesetBrowser+TilesetBrowser_Window,a0
	bsr.w RemWinFromSigMask
	lea.l TilesetBrowser,a0
	jsr CloseTilesetBrowser
	bra.s .loop
.onGadgetUp:
	move.l im_IAddress(a0),a1			; a1 = gadget clicked
	lea.l TilesetBrowser,a0
	jsr TilesetBrowserGadgetUp
	bra.s .loop
.onGadgetDown:
	move.l im_IAddress(a0),a1
	lea.l TilesetBrowser,a0
	jsr TilesetBrowserGadgetDown
	bra.s .loop
.done:
	move.l (sp)+,a2
	rts
****
* a0 - contains ptr to tile editor
HandleTileEditorMsgs:
	movem.l d2/a2-a3,-(sp)
	move.l a0,a3						; a3=TileEditor
	move.l TileEditor_Window(a0),a0
	move.l wd_UserPort(a0),a2
.loop:
	move.l a2,a0						; a0=UserPort
	bsr.w GetAckMsg
	tst.l d0
	beq.w .done
	move.l d0,a0						; a0=Msg
.dispatch:
	move.l im_Class(a0),d0
	cmp.l #IDCMP_CLOSEWINDOW,d0
	beq.s .closeWindow
	cmp.l #IDCMP_GADGETUP,d0
	beq.w .onGadgetUp
	cmp.l #IDCMP_GADGETDOWN,d0
	beq.w .onGadgetDown
	cmp.l #IDCMP_MOUSEBUTTONS,d0
	beq.w .onMouseButtons
	cmp.l #IDCMP_MOUSEMOVE,d0
	beq.w .onMouseMove
	bra.s .loop
.closeWindow:
	move.l a3,a0						; a0 = tile editor
	tst.b TileEditor_Unsaved(a0)
	beq.s .doClose
	bsr.w ShowTileEditorUnsavedReq
	tst.l d0							; did they click cancel?
	beq.s .loop
	subq.l #1,d0						; did they click save?
	beq.s .save
.revert:
	move.w TileEditor_Num(a3),d0
	bsr.w RevertTileset
	lea.l TilesetBrowser,a0
	tst.l TilesetBrowser_Window(a0)
	beq.s .doClose
	jsr UpdateBrowserListGadgets
	bra.s .doClose
.save:
	move.w TileEditor_Num(a3),d0
	bsr.w SaveTileset
.doClose:
	move.l a3,a0						; a0 = tile editor
	bsr.w RemoveTileEditor
	move.l TileEditor_Window(a3),a0
	bsr.w RemWinFromSigMask
	move.l a3,a0						; a0 = tile editor once more
	jsr CloseTileEditor
	bra.w .loop
.onGadgetUp:
	move.l im_IAddress(a0),a1			; a1 = gadget clicked
	move.l a1,-(sp)
	move.l a3,a0						; a0 = tile editor
	jsr TileEditorGadgetUp
; quick and easy hack
	move.l (sp)+,a0						; a0 = gadget clicked
	cmp.w #$800,gg_GadgetID(a0)			; was this the name?
	bne.w .loop
	lea.l TilesetBrowser,a0
	tst.l TilesetBrowser_Window(a0)
	beq.w .loop
	jsr UpdateBrowserListGadgets
	bra.w .loop
.onGadgetDown:
	move.l im_IAddress(a0),a1
	move.l a3,a0
	jsr TileEditorGadgetDown
	bra.w .loop
.onMouseButtons:
	move.w im_MouseX(a0),d0
	move.w im_MouseY(a0),d1
	move.w im_Code(a0),d2
	move.l a3,a0
	jsr TileEditorMouseButtons
	bra.w .loop
.onMouseMove:
	move.w im_MouseX(a0),d0
	move.w im_MouseY(a0),d1
	move.l a3,a0
	jsr TileEditorMouseMove
	bra.w .loop
.done:
	movem.l (sp)+,d2/a2-a3
	rts
****
* a0 - tile editor to be removed
ShowTileEditorUnsavedReq:
	movem.l a2-a4,-(sp)
	lea.l UnsavedTags,a1
	move.l TileEditor_Window(a0),4(a1)		; write into Window tag
	move.l a1,a0							; a0 = taglist
	lea.l UnsavedBody,a1
	lea.l UnsavedGadgets,a2
	move.l #0,a3							; no args
	move.l #0,a4							; no args
	move.l ReqBase,a6
	jsr _LVOrtEZRequestA(a6)
	movem.l (sp)+,a2-a4
	rts
****
* a0 - tile editor to be removed
RemoveTileEditor:
.prev:
	tst.l TileEditor_Prev(a0)
	beq.s .noPrev
	move.l TileEditor_Prev(a0),a1
	move.l TileEditor_Next(a0),TileEditor_Next(a1)	; prev.next=dead.next
	bra.s .next
.noPrev:
	move.l TileEditor_Next(a0),FirstTileEditor			; first = dead.next
.next:
	tst.l TileEditor_Next(a0)
	beq.s .done
	move.l TileEditor_Next(a0),a1
	move.l TileEditor_Prev(a0),TileEditor_Prev(a1)	; next.prev=dead.prev
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
	bsr.w CheckForUnsaved
	beq.s .new								; no unsaved
	bsr.w ShowQuitUnsavedReq
	tst.l d0
	beq.s .done								; clicked cancel
	cmp.l #1,d0
	bne.s .new								; clicked don't save
	bsr.w SaveProject
	bsr.s MarkAllSaved
.new:
	bsr.w SelectProject
	beq.s .done
	bsr.w CloseTileEditors
	bsr.w CloseTilesetBrowserIfOpen
	bsr.w CreateProject						; init a new project
.done:
	rts
****
OpenItemHandler:
	bsr.w CheckForUnsaved
	beq.s .doOpen							; no unsaved
	bsr.s ShowQuitUnsavedReq
	tst.l d0
	beq.s .done								; clicked cancel
	cmp.l #1,d0
	bne.s .doOpen							; clicked don't save
	bsr.w SaveProject
.doOpen:
	bsr.w SelectProject
	beq.s .done
	bsr.w LoadProject
; TODO: handle failure case!
	bsr.w CloseTileEditors
	bsr.w CloseTilesetBrowserIfOpen
.done:
	rts
****
SaveItemHandler:
	bsr.w SaveProject
	bra.s MarkAllSaved
****
SaveAsItemHandler:
	bsr.w SelectProject
	beq.s .done
	bsr.w SaveProject
	bra.s MarkAllSaved
.done:
	rts
****
MarkAllSaved:
	move.l a2,-(sp)
	move.l FirstTileEditor,a2
	bra.s .next
.loop:
	move.l a2,a0
	jsr SetTileEditorSaved
	move.l TileEditor_Next(a2),a2
.next:
	cmp.l #0,a2
	bne.s .loop
	move.l (sp)+,a2
	rts
****
ShowQuitUnsavedReq:
	movem.l a2-a4,-(sp)
	lea.l UnsavedTags,a0
	move.l ProjWinP,4(a0)
	lea.l QuitUnsavedBody,a1
	lea.l QuitUnsavedGadgets,a2
	move.l #0,a3							; no args
	move.l #0,a4							; no args
	move.l ReqBase,a6
	jsr _LVOrtEZRequestA(a6)
	movem.l (sp)+,a2-a4
	rts
****
QuitItemHandler:
	bsr.s CheckForUnsaved
	beq.s .quit								; no unsaved
	bsr.s ShowQuitUnsavedReq
	tst.l d0
	beq.s .done								; clicked cancel
	cmp.l #1,d0
	bne.s .quit								; clicked don't save
	bsr.w SaveProject
.quit:
	move.b #1,QuitFlag
.done:
	rts
****
CheckForUnsaved:
	move.l FirstTileEditor,a0
	bra.s .next
.loop:
	tst.b TileEditor_Unsaved(a0)
	bne.s .done
	move.l TileEditor_Next(a0),a0
.next:
	cmp.l #0,a0
	bne.s .loop
.done:
	rts
****	
* d0 - tileset to spawn for
SpawnTilesetEditor:
	jsr NewTileEditor
	tst.l d0
	beq.s .done
.install:
	move.l d0,a0								; a0 = new
	move.l FirstTileEditor,TileEditor_Next(a0)
	tst.l FirstTileEditor						; was there an oldfirst?
	beq.s .noPrev
	move.l FirstTileEditor,a1
	move.l a0,TileEditor_Prev(a1)				; oldfirst.prev = new
.noPrev:
	move.l a0,FirstTileEditor					; first = new
	move.l TileEditor_Window(a0),a0
	bsr.w AddWinToSigMask
.done:
	rts

 XDEF SpawnTilesetEditor
****
NewTilesetItemHandler:
	move.w Project+Project_TilesetCnt,d0
	bsr.s SpawnTilesetEditor
; TODO: add a test to make sure this succeeded before doing this
	addq.w #1,Project+Project_TilesetCnt
.refreshBrowser:
	lea.l TilesetBrowser,a0
	tst.l TilesetBrowser_Window(a0)
	beq.s .done
	jsr UpdateBrowserListGadgets
.done:
	rts
****
OpenTilesetItemHandler:
	tst.l TilesetBrowser+TilesetBrowser_Window
	bne.s .activate
	lea.l TilesetBrowser,a0
	jsr NewTilesetBrowser
	move.l TilesetBrowser+TilesetBrowser_Window,a0
	bra.w AddWinToSigMask
.activate:
	move.l TilesetBrowser+TilesetBrowser_Window,a0
	move.l IntuiBase,a6
	jsr _LVOWindowToFront(a6)
	move.l TilesetBrowser+TilesetBrowser_Window,a0
	move.l IntuiBase,a6
	jmp _LVOActivateWindow(a6)
****
CloseTileEditors:
	move.l a2,-(sp)
	move.l FirstTileEditor,a2
	bra.s .test
.loop:
	move.l TileEditor_Window(a2),a0
	bsr.w RemWinFromSigMask
	move.l a2,a0						; a0 = tile editor once more
; NOTE: this has to be done before the call to CloseTileEditor, which
; frees the memory
	move.l TileEditor_Next(a2),a2
	jsr CloseTileEditor
.test:
	cmp.l #0,a2
	bne.s .loop
	clr.l FirstTileEditor
	move.l (sp)+,a2
	rts
****************
CloseTilesetBrowserIfOpen:
	move.l TilesetBrowser+TilesetBrowser_Window,d0
	beq.s .done
	move.l d0,a0
	bsr.w RemWinFromSigMask
	lea.l TilesetBrowser,a0
	jmp CloseTilesetBrowser
.done:
	rts

	SECTION MyData,DATA
******** Unsaved Tileset Requester
UnsavedBody:
	dc.b 'There are unsaved changes to',10,'this tileset.',0

QuitUnsavedBody:
	dc.b 'There are unsaved changes to',10,'one or more tilesets.',0

UnsavedGadgets:
	dc.b 'Save|Revert|Cancel',0

QuitUnsavedGadgets:
	dc.b "Save All|Don't Save|Cancel",0

UnsavedTitle:
	dc.b 'Save before closing?',0

	EVEN
UnsavedTags:
	dc.l RT_Window, 0
	dc.l RT_LockWindow,1
	dc.l RTEZ_ReqTitle,UnsavedTitle
	dc.l TAG_DONE

IntuiName:
	dc.b "intuition.library",0

GfxName:
	dc.b "graphics.library",0

ReqName:
	dc.b "reqtools.library",0

DosName:
	dc.b "dos.library",0
	
SelectProjectTxt:
	dc.b "Select Project to Create or Load",0

	EVEN
Palette:
	dc.w 0,0,0				; black
	dc.w 5,5,5
	dc.w 10,10,10
	dc.w 15,15,15			; white

Title:
	dc.b "FracIDE Tile Editor",0

SCR_WIDTH	=320
SCR_HEIGHT	=256

	EVEN
ScrDef:
	dc.w 0,0					; left,top
	dc.w SCR_WIDTH,SCR_HEIGHT	; width/height
	dc.w 2						; bits per pixel
	dc.b 0,3					; default pens
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

**** Tilesets Menu Text

TilesetsStr:
	dc.b "Tilesets",0

NewTilesetStr:
	dc.b "New Tileset...",0

OpenTilesetStr:
	dc.b "Open Tileset...",0

	EVEN
NewTilesetTxt:
	dc.b 0,0			; pens
	dc.b 0				; draw mode (JAM1)
	dc.b 0				; padding
	dc.w 0,0			; left, top
	dc.l 0				; default font
	dc.l NewTilesetStr
	dc.l 0				; next

OpenTilesetTxt:
	dc.b 0,0
	dc.b 0
	dc.b 0
	dc.w 0,0
	dc.l 0
	dc.l OpenTilesetStr
	dc.l 0

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

OpenStr:
	dc.b "Open...",0
	
	EVEN
OpenTxt:
	dc.b 0,0
	dc.b 0
	dc.b 0
	dc.w 0,0
	dc.l 0
	dc.l OpenStr
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
	dc.l OpenMenuItem
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
OpenMenuItem:
	dc.l SaveMenuItem
	dc.w 0,12
	dc.w 120,10			; width, height
	dc.w ITEMTEXT!COMMSEQ!ITEMENABLED!HIGHCOMP
	dc.l 0
	dc.l OpenTxt
	dc.l 0
	dc.b 'O'
	dc.b 0
	dc.l 0
	dc.w 0

	EVEN
SaveMenuItem:
	dc.l SaveAsMenuItem
	dc.w 0,24
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
	dc.w 0,36
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
	dc.w 0,48			; left, top
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

**** Tilesets MenuItems

NewTilesetMenuItem:
	dc.l OpenTilesetMenuItem	; next item
	dc.w 0,0					; left, top
	dc.w 130,10					; width
	dc.w ITEMTEXT!ITEMENABLED!HIGHCOMP
	dc.l 0						; mutual exclusion
	dc.l NewTilesetTxt
	dc.l 0						; no different highlighted text
	dc.b 0						; no shortcut
	dc.b 0						; padding
	dc.l 0						; no subitems
	dc.w 0						; next select

OpenTilesetMenuItem:
	dc.l 0						; next item
	dc.w 0,12					; left,top
	dc.w 130,10					; width,height
	dc.w ITEMTEXT!ITEMENABLED!HIGHCOMP
	dc.l 0						; mutual exclusion
	dc.l OpenTilesetTxt
	dc.l 0
	dc.b 0
	dc.b 0
	dc.l 0
	dc.w 0
	

******** Menus

; TODO: dynamically compute the sizes/positions of things

TilesetsMenu:
	dc.l 0						; next menu
	dc.w 82,0					; left/top
	dc.w 70						; width
	dc.w 10						; height
	dc.w MENUENABLED			; flags
	dc.l TilesetsStr			; text
	dc.l NewTilesetMenuItem		; first item
	dc.w 0,0,0,0

ProjMenu:
	dc.l TilesetsMenu		; next menu
	dc.w 2,0				; left, top
	dc.w 60					; width
	dc.w 30					; height
	dc.w MENUENABLED		; flags
	dc.l ProjStr			; text
	dc.l NewMenuItem		; first item
	dc.w 0,0,0,0			; for internal use only

******** Menu Handler Tables

MenuHandlers:
	dc.l ProjMenuHandlers,TilesetsMenuHandlers

ProjMenuHandlers:
	dc.l NewItemHandler,OpenItemHandler,SaveItemHandler
	dc.l SaveAsItemHandler,QuitItemHandler

TilesetsMenuHandlers:
	dc.l NewTilesetItemHandler,OpenTilesetItemHandler

******** NewWindow info

AllNewWins:
	dc.l TileNewWin,ProjNewWin,BrowserNewWin
NUM_OF_NEWWINS	=3
