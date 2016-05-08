	INCLUDE "exec/exec.i"
	INCLUDE "exec/exec_lib.i"
	INCLUDE "graphics/gfx.i"
	INCLUDE "graphics/graphics_lib.i"
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
	move.l #SPRITEEDITOR_SIZEOF,d0		; allocate this many bytes
	move.l #MEMF_CLEAR,d1				; best available local, clear it
	move.l 4.w,a6
	jsr _LVOAllocMem(a6)
	tst.l d0							; success?
	beq.w .done							; fail otherwise
	move.l d0,a3						; a3 = SpriteEditor ptr
.makeEditor:
	lea.l SprEditorTemplate,a0			; src
	move.l a3,a1						; dest=new editor
	move.l #SPRITEEDITOR_SIZEOF,d0		; size
	move.l 4.w,a6
	jsr _LVOCopyMem(a6)
.patchEditor:
	move.l a3,d0						; d0=spriteeditor base
	lea.l SprEditPatchLocs,a0
; NB: it is INTENTIONAL that the first patch point can be 0
	move.l (a0)+,d1						; d1=patch offset
.patchLoop:
	add.l d0,(a3,d1.l)					; patch
	move.l (a0)+,d1
	tst.l d1							; is it 0?
	bne.s .patchLoop
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
.drawPal:
	move.l SpriteEditor_Window(a3),a0
	move.l wd_RPort(a0),a0
	bsr.s DrawPal
.finish:
	move.l a3,d0						; return in d0
	bra.s .done
.freeEditor:
	move.l a3,a1						; a1=editor to free
	move.l #SPRITEEDITOR_SIZEOF,d0
	move.l 4.w,a6
	jsr _LVOFreeMem(a6)
	moveq.l #0,d0						; return NULL
.done:
	movem.l (sp)+,a2-a3
	rts

	XDEF NewSpriteEditor
****************
* a0 - ptr to rastport
DrawPal:
	movem.l d2-d4/a2,-(sp)
	move.l a0,a2						; a2=rastport
	moveq.l #(4-1),d4					; d4=counter
	move.w #PAL_LEFT,d0					; d0=left
	move.w #PAL_TOP,d1					; d1=top
	move.w #(PAL_LEFT+PAL_WIDTH-1),d2	; d2=right
	move.w #(PAL_TOP+PAL_HEIGHT-1),d3	; d3=bottom
.loop:
	movem.l d0-d1,-(sp)
	move.l a2,a1						; a1=rastport
	move.b d4,d0						; d0=color
	move.l GfxBase,a6
	jsr _LVOSetAPen(a6)
	movem.l (sp)+,d0-d1
	movem.l d0-d3,-(sp)
	move.l a2,a1						; a1=rastport
	move.l GfxBase,a6
	jsr _LVORectFill(a6)
	movem.l (sp)+,d0-d3
	add.w #PAL_HEIGHT,d1				; top += PAL_HEIGHT
	add.w #PAL_HEIGHT,d3				; bottom += PAL_HEIGHT
	dbra d4,.loop
	movem.l (sp)+,d2-d4/a2
	rts
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
	move.l #SPRITEEDITOR_SIZEOF,d0
	move.l 4.w,a6
	jmp _LVOFreeMem(a6)

	XDEF CloseSpriteEditor

	SECTION MyData,DATA
******** Sprite window
**** Constants

SPR_WIDTH	=128
SPR_HEIGHT	=144

SPRNAME_WIDTH   =88
SPRNAME_HEIGHT  =10

SPRNUM_WIDTH	=24
SPRNUM_HEIGHT	=10

PAL_WIDTH	=16
PAL_HEIGHT	=16
PAL_LEFT	=112
PAL_TOP		=32

PEN_LEFT	=PAL_LEFT
PEN_TOP		=112
PEN_WIDTH	=PAL_WIDTH
PEN_HEIGHT	=PAL_HEIGHT

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

	EVEN
SprEditorTemplate:
	dc.l 0								; next
	dc.l 0								; prev
	dc.l 0								; window
	dc.b "Sprite xxx",0					; title
	dc.b 0								; quit
.numGG:
	dc.l SpriteEditor_NameGG			; next gadget
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
	dc.l SpriteEditor_PalGGs			; next gadget
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
.palGGs0:
	dc.l SpriteEditor_PalGGs+gg_SIZEOF	; next gadget
	dc.w PAL_LEFT,PAL_TOP					; left, top
	dc.w PAL_WIDTH,PAL_HEIGHT
	dc.w GFLG_GADGHBOX
    dc.w GACT_RELVERIFY					; activation
	dc.w GTYP_BOOLGADGET
	dc.l PalBorder
	dc.l 0								; no selected render
	dc.l 0								; no text
	dc.l 0								; no mutual exclude
	dc.l 0								; no special info
	dc.w 0								; no ID
	dc.l 0								; no special user data
.palGGs1:
	dc.l SpriteEditor_PalGGs+gg_SIZEOF*2; next gadget
	dc.w PAL_LEFT,PAL_TOP+PAL_HEIGHT	; left, top
	dc.w PAL_WIDTH,PAL_HEIGHT
	dc.w GFLG_GADGHBOX
    dc.w GACT_RELVERIFY					; activation
	dc.w GTYP_BOOLGADGET
	dc.l PalBorder
	dc.l 0								; no selected render
	dc.l 0								; no text
	dc.l 0								; no mutual exclude
	dc.l 0								; no special info
	dc.w 0								; no ID
	dc.l 0								; no special user data
.palGGs2:
	dc.l SpriteEditor_PalGGs+(gg_SIZEOF*3); next gadget
	dc.w PAL_LEFT,PAL_TOP+(PAL_HEIGHT*2); left, top
	dc.w PAL_WIDTH,PAL_HEIGHT
	dc.w GFLG_GADGHBOX
    dc.w GACT_RELVERIFY					; activation
	dc.w GTYP_BOOLGADGET
	dc.l PalBorder
	dc.l 0								; no selected render
	dc.l 0								; no text
	dc.l 0								; no mutual exclude
	dc.l 0								; no special info
	dc.w 0								; no ID
	dc.l 0								; no special user data
.palGGs3:
	dc.l 0								; next gadget
	dc.w PAL_LEFT,PAL_TOP+(PAL_HEIGHT*3); left, top
	dc.w PAL_WIDTH,PAL_HEIGHT
	dc.w GFLG_GADGHBOX
    dc.w GACT_RELVERIFY					; activation
	dc.w GTYP_BOOLGADGET
	dc.l PalBorder
	dc.l 0								; no selected render
	dc.l 0								; no text
	dc.l 0								; no mutual exclude
	dc.l 0								; no special info
	dc.w 0								; no ID
	dc.l 0								; no special user data

SprEditPatchLocs:
	dc.l SpriteEditor_NumGG+gg_NextGadget
	dc.l SpriteEditor_NumGG+gg_SpecialInfo
	dc.l SpriteEditor_NumSI+si_Buffer
	dc.l SpriteEditor_NameGG+gg_NextGadget
	dc.l SpriteEditor_NameGG+gg_SpecialInfo
	dc.l SpriteEditor_NameSI+si_Buffer
	dc.l SpriteEditor_PalGGs+gg_NextGadget
	dc.l SpriteEditor_PalGGs+gg_SIZEOF+gg_NextGadget
	dc.l SpriteEditor_PalGGs+(gg_SIZEOF*2)+gg_NextGadget
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

** Pal

	EVEN
PalBorderPts:
	dc.w 0,0
	dc.w PAL_WIDTH+1,0
	dc.w PAL_WIDTH+1,PAL_HEIGHT+1
	dc.w 0,PAL_HEIGHT+1
	dc.w 0,0

PalBorder:
	dc.w -1,-1
	dc.b 1,0
	dc.b 0
	dc.b 5
	dc.l PalBorderPts
	dc.l 0

	XDEF SprNewWin
