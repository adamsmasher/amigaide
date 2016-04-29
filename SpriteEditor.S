	INCLUDE "exec/exec.i"
	INCLUDE "exec/exec_lib.i"
	INCLUDE "intuition/intuition.i"
	INCLUDE "intuition/intuition_lib.i"

	INCLUDE "globals.i"

	INCLUDE "SpriteEditor.i"

	SECTION SpriteEditor,CODE
****************
* returns in d0 address of new sprite editor, or NULL on failure
NewSpriteEditor:
	move.l a2,-(sp)
.allocEditor:
	moveq.l #SPRITEEDITOR_SIZEOF,d0		; allocate this many bytes
	move.l #MEMF_CLEAR,d1				; best available local, clear it
	move.l 4.w,a6
	jsr _LVOAllocMem(a6)
	tst.l d0							; success?
	beq.s .done							; fail otherwise
	move.l d0,a2						; a2 = SpriteEditor ptr
.openWindow:
	move.l IntuiBase,a6
	lea.l SprNewWin,a0
	jsr _LVOOpenWindow(a6)
	tst.l d0							; success?
	beq.s .freeEditor					; fail if not
	move.l d0,SpriteEditor_Window(a2)
	move.l a2,d0						; return in d0
	bra.s .done
.freeEditor:
	move.l a2,a1
	moveq.l #SPRITEEDITOR_SIZEOF,d0
	move.l 4.w,a6
	jsr _LVOFreeMem(a6)
	moveq.l #0,d0						; return NULL
.done:
	move.l (sp)+,a2
	rts

	XDEF NewSpriteEditor
****************
* a0 - ptr to SpriteEditor
CloseSpriteEditor:
.closeWindow:
	move.l a0,-(sp)
	move.l SpriteEditor_Window(a0),a0
	move.l IntuiBase,a6
	jsr _LVOCloseWindow(a6)
.freeEditor:
	move.l (sp)+,a1
	moveq.l #SPRITEEDITOR_SIZEOF,d0
	move.l 4.w,a6
	jmp _LVOFreeMem(a6)

	XDEF CloseSpriteEditor

	SECTION MyData,DATA
******** Sprite window

SPR_WIDTH	=128
SPR_HEIGHT	=144

SprTitle:
	dc.b "Sprite",0

**** Gadgets

** SprName

SPRNAME_WIDTH   =72
SPRNAME_HEIGHT  =10

	EVEN
SprNameBorderPts:
	dc.w 0,0
	dc.w SPRNAME_WIDTH+3,0
	dc.w SPRNAME_WIDTH+3,SPRNAME_HEIGHT+3
	dc.w 0,SPRNAME_HEIGHT+3
	dc.w 0,0

	EVEN
SprNameBorder:
	dc.w -2,-2
	dc.b 1,0
	dc.b 0
	dc.b 5
	dc.l SprNameBorderPts
	dc.l 0

SprNameBuf:
	dcb.b 16,0

SprNameInfo:
	dc.l SprNameBuf
	dc.l 0				; no undo buffer
	dc.w 0				; buffer pos
	dc.w 16				; max chars + NULL
	dc.w 0				; disp pos
	dc.w 0				; undo pos
	dc.w 0				; numchars
	dc.w 0				; dispcount
	dc.w 0,0			; cleft, ctop
	dc.l 0				; unused
	dc.l 0				; long int
	dc.l 0				; default key map

SprNameGadget:
	dc.l 0								; next gadget
	dc.w 40,4							; left, top
	dc.w SPRNAME_WIDTH,SPRNAME_HEIGHT
	dc.w GADGHCOMP
    dc.w 0								; flags
	dc.w GTYP_STRGADGET
	dc.l SprNameBorder
	dc.l 0								; no selected render
	dc.l 0								; no text
	dc.l 0								; no mutual exclude
	dc.l SprNameInfo
	dc.w 0								; no ID
	dc.l 0								; no special user data
	
	XDEF SprNameGadget

** SprNum

SPRNUM_WIDTH	=24
SPRNUM_HEIGHT	=10

	EVEN
SprNumBorderPts:
	dc.w 0,0
	dc.w SPRNUM_WIDTH+3,0
	dc.w SPRNUM_WIDTH+3,SPRNUM_HEIGHT+3
	dc.w 0,SPRNUM_HEIGHT+3
	dc.w 0,0

SprNumBorder:
	dc.w -2,-2			; left, top
	dc.b 1,0			; pens
	dc.b 0				; JAM1
	dc.b 5				; 5 points
	dc.l SprNumBorderPts
	dc.l 0				; no next

SprNumBuf:
	dc.b '0',0,0,0

; TODO: you'll need to clone this per sprite window
SprNumInfo:
	dc.l SprNumBuf
	dc.l 0				; no undo buffer
	dc.w 0				; buffer pos
	dc.w 4				; max chars + NULL
	dc.w 0				; disp pos
	dc.w 0				; undo pos
	dc.w 1				; numchars
	dc.w 1				; dispcount
	dc.w 0,0			; cleft, ctop
	dc.l 0				; unused
	dc.l 0				; long int
	dc.l 0				; default key map

SprNumGadget:
	dc.l SprNameGadget					; next gadget
	dc.w 5,4							; left, top
	dc.w SPRNUM_WIDTH,SPRNUM_HEIGHT
	dc.w GADGHCOMP
    dc.w GACT_STRINGRIGHT!GACT_LONGINT
	dc.w GTYP_STRGADGET
	dc.l SprNumBorder	
	dc.l 0								; no selected render
	dc.l 0								; no text
	dc.l 0								; no mutual exclude
	dc.l SprNumInfo
	dc.w 0								; no ID
	dc.l 0								; no special user data

	XDEF SprNumGadget

**** NewWindow
	EVEN
SprNewWin:
	dc.w 20,20										; left,top
	dc.w SPR_WIDTH,SPR_HEIGHT						; width, height
	dc.b -1,-1										; default pens
	dc.l MOUSEBUTTONS!CLOSEWINDOW
	dc.l WINDOWCLOSE!WINDOWDEPTH!WINDOWDRAG!RMBTRAP
	dc.l SprNumGadget
	dc.l 0											; default checkmark image
	dc.l SprTitle
	dc.l 0											; write screen ptr here
	dc.l 0											; no bitmap
	dc.w SPR_WIDTH,SPR_HEIGHT						; min width/height
	dc.w SPR_WIDTH,SPR_HEIGHT						; max width/height
	dc.w CUSTOMSCREEN								; type

	XDEF SprNewWin
