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
	movem.l a2-a3,-(sp)
.allocEditor:
	moveq.l #SPRITEEDITOR_SIZEOF,d0		; allocate this many bytes
	move.l #MEMF_CLEAR,d1				; best available local, clear it
	move.l 4.w,a6
	jsr _LVOAllocMem(a6)
	tst.l d0							; success?
	beq.w .done							; fail otherwise
	move.l d0,a3						; a3 = SpriteEditor ptr
.makeEditor:
	lea.l SprEditorTemplate,a0			; src
	move.l a3,a1						; dest=new editor
	moveq.l #SPRITEEDITOR_SIZEOF,d0		; size
	move.l 4.w,a6
	jsr _LVOCopyMem(a6)
.patchEditor:
	move.l a3,d0						; d0=spriteeditor base
	lea.l SpriteEditor_NumGG(a3),a0
	add.l d0,gg_NextGadget(a0)
	add.l d0,gg_SpecialInfo(a0)
	lea.l SpriteEditor_NumSI(a3),a0
	add.l d0,si_Buffer(a0)
	lea.l SpriteEditor_NameGG(a3),a0
	add.l d0,gg_NextGadget(a0)
	add.l d0,gg_SpecialInfo(a0)
	lea.l SpriteEditor_NameSI(a3),a0
	add.l d0,si_Buffer(a0)
.patchNewWin:
	lea.l SprNewWin,a0
	lea.l SpriteEditor_NumGG(a3),a1
	move.l a1,nw_FirstGadget(a0)
	lea.l SpriteEditor_Title(a3),a1
	move.l a1,nw_Title(a0)
.openWindow:
	move.l IntuiBase,a6
	jsr _LVOOpenWindow(a6)
	tst.l d0							; success?
	beq.s .freeEditor					; fail if not
	move.l d0,SpriteEditor_Window(a3)
.disableSpriteNum:
	lea.l SpriteEditor_NumGG(a3),a0
	move.l d0,a1						; a1=Window
	move.l #0,a2						; no requester
	move.l IntuiBase,a6
	jsr _LVOOffGadget(a6)
	move.l a3,d0						; return in d0
	bra.s .done
.freeEditor:
	move.l a3,a1						; a1=editor to free
	moveq.l #SPRITEEDITOR_SIZEOF,d0
	move.l 4.w,a6
	jsr _LVOFreeMem(a6)
	moveq.l #0,d0						; return NULL
.done:
	movem.l (sp)+,a2-a3
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
; TODO: deallocate the gadgets, the buffers...
.freeEditor:
	move.l (sp)+,a1
	moveq.l #SPRITEEDITOR_SIZEOF,d0
	move.l 4.w,a6
	jmp _LVOFreeMem(a6)

	XDEF CloseSpriteEditor

	SECTION MyData,DATA
******** Sprite window
**** Constansts

SPR_WIDTH	=128
SPR_HEIGHT	=144

SPRNAME_WIDTH   =88
SPRNAME_HEIGHT  =10

SPRNUM_WIDTH	=24
SPRNUM_HEIGHT	=10

**** NewWindow
* when a new sprite editor is created, this struct is updated to refer
* to the correct data
	EVEN
SprNewWin:
	dc.w 20,20										; left,top
	dc.w SPR_WIDTH,SPR_HEIGHT						; width, height
	dc.b -1,-1										; default pens
	dc.l MOUSEBUTTONS!CLOSEWINDOW
	dc.l WINDOWCLOSE!WINDOWDEPTH!WINDOWDRAG!RMBTRAP
	dc.l 0											; PATCH gadget
	dc.l 0											; default checkmark image
	dc.l 0											; PATCH title
	dc.l 0											; PATCH screen ptr
	dc.l 0											; no bitmap
	dc.w SPR_WIDTH,SPR_HEIGHT						; min width/height
	dc.w SPR_WIDTH,SPR_HEIGHT						; max width/height
	dc.w CUSTOMSCREEN								; type

**** Template
* When a new sprite editor is created, memory for the following is
* allocated and this is copied into it. The base pointer is then
* added onto any relative "pointer"s in the struct

SprEditorTemplate:
	dc.l 0								; next
	dc.l 0								; prev
	dc.l 0								; window
	dc.b "Sprite xxx",0					; title
	dc.b 0								; quit
.numGG:
	dc.l SpriteEditor_NumGG				; next gadget
	dc.w 5,4							; left, top
	dc.w SPRNUM_WIDTH,SPRNUM_HEIGHT
	dc.w GADGHCOMP
    dc.w GACT_STRINGRIGHT!GACT_LONGINT
	dc.w GTYP_STRGADGET
	dc.l SprNumBorder	
	dc.l 0								; no selected render
	dc.l 0								; no text
	dc.l 0								; no mutual exclude
	dc.l SpriteEditor_NumSI
	dc.w 0								; no ID
	dc.l 0								; no special user data
.numSI:
	dc.l SpriteEditor_NumBuf
	dc.l 0								; no undo buffer
	dc.w 0								; buffer pos
	dc.w 4								; max chars + NULL
	dc.w 0								; disp pos
	dc.w 0								; undo pos
	dc.w 1								; numchars
	dc.w 1								; dispcount
	dc.w 0,0							; cleft, ctop
	dc.l 0								; unused
	dc.l 0								; long int
	dc.l 0								; default key map
.numBuf:
	dc.b "0",0,0,0
.nameGG:
	dc.l 0								; next gadget
	dc.w 35,4							; left, top
	dc.w SPRNAME_WIDTH,SPRNAME_HEIGHT
	dc.w GADGHCOMP
    dc.w 0								; activation
	dc.w GTYP_STRGADGET
	dc.l SprNameBorder
	dc.l 0								; no selected render
	dc.l 0								; no text
	dc.l 0								; no mutual exclude
	dc.l SpriteEditor_NameSI
	dc.w 0								; no ID
	dc.l 0								; no special user data
.nameSI:
	dc.l SpriteEditor_NameBuf
	dc.l 0								; no undo buffer
	dc.w 0								; buffer pos
	dc.w 16								; max chars + NULL
	dc.w 0								; disp pos
	dc.w 0								; undo pos
	dc.w 0								; numchars
	dc.w 0								; dispcount
	dc.w 0,0							; cleft, ctop
	dc.l 0								; unused
	dc.l 0								; long int
	dc.l 0								; default key map
.nameBuf:
	dcb.b 16,0
	
	XDEF SprEditorTemplate

** SprName

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

** SprNum

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

	XDEF SprNewWin