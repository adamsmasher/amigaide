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
AllocEditor:
	move.l #SPRITEEDITOR_SIZEOF,d0		; allocate this many bytes
	move.l #MEMF_CLEAR,d1				; best available local, clear it
	move.l 4.w,a6
	jmp _LVOAllocMem(a6)
****************
* a1 - ptr to SpriteEditor memory
MakeEditor:
	lea.l SprEditorTemplate,a0			; src
	move.l #SPRITEEDITOR_SIZEOF,d0		; size
	move.l 4.w,a6
	jmp _LVOCopyMem(a6)
****************
* a0 - ptr to SpriteEditor
PatchEditorOffsets:
	move.l a0,d0						; d0=spriteeditor base
	lea.l SprEditPatchLocs,a1
; NB: it is INTENTIONAL that the first patch point can be 0
	move.l (a1)+,d1						; d1=patch offset
.loop:
	add.l d0,(a0,d1.l)					; patch
	move.l (a1)+,d1
	tst.l d1							; is it 0?
	bne.s .loop
	rts
****************
* a0 - ptr to SpriteEditor
PatchNewWin:
	lea.l SprNewWin,a1
	move.l a0,-(sp)
	lea.l SpriteEditor_NumGG(a0),a0
	move.l a0,nw_FirstGadget(a1)
	move.l (sp)+,a0						; a0 = sprite editor ptr
	lea.l SpriteEditor_Title(a0),a0
	move.l a0,nw_Title(a1)
	rts
****************
* returns in d0 address of new sprite editor, or NULL on failure
NewSpriteEditor:
	movem.l a2-a3,-(sp)
	bsr.s AllocEditor
	tst.l d0							; success?
	beq.w .done							; fail otherwise
	move.l d0,a3						; a3 = SpriteEditor ptr
	move.l a3,a1						; a1 = SpriteEditor ptr
	bsr.s MakeEditor
	move.l a3,a0						; a0 = SpriteEditor ptr
	bsr.s PatchEditorOffsets
	move.l a3,a0						; a0 = SpriteEditor ptr
	bsr.s PatchNewWin
	bsr.w MakePxGGs
	; TODO: handle failure case here
	move.l d0,SpriteEditor_PxGGs(a3)
	move.l d0,a0
	bsr.w ArrangePxGGs
.openWindow:
	lea.l SprNewWin,a0
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
	move.l SpriteEditor_Window(a3),a1
	move.l wd_RPort(a1),a1
	bsr.w DrawPenBg
	move.l a3,a0						; a0=Sprite Editor
	bsr.w DrawPen
.addPxGGs:
	move.l SpriteEditor_Window(a3),a0
	move.l SpriteEditor_PxGGs(a3),a1
	move.l #~0,d0						; add to end of list
	; TODO: this will vary
	move.l #256,d1						; add 256 gadgets
	move.l #0,a2						; no requester
	move.l IntuiBase,a6
	jsr _LVOAddGList(a6)
	move.l SpriteEditor_PxGGs(a3),a0
	move.l SpriteEditor_Window(a3),a1
	move.l #0,a2						; no requester
	move.l #-1,d0						; refresh to end
	move.l IntuiBase,a6
	jsr _LVORefreshGList(a6)
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
DrawPen:
	movem.l d2-d3/a2,-(sp)
	move.b SpriteEditor_Pen(a0),d0
	move.l SpriteEditor_Window(a0),a0
	move.l wd_RPort(a0),a2
	move.l a2,a1						; a1=rport
	move.l GfxBase,a6
	jsr _LVOSetAPen(a6)
	move.w #PEN_LEFT,d0
	move.w #PEN_TOP,d1
	move.w #(PEN_LEFT+PEN_WIDTH),d2
	move.w #(PEN_TOP+PEN_HEIGHT),d3
	move.l a2,a1						; a1=rport
	move.l GfxBase,a6
	jsr _LVORectFill(a6)
	movem.l (sp)+,d2-d3/a2
	rts
****************
* a1 - ptr to RPort
DrawPenBg:
	movem.l d2-d3,-(sp)
	moveq.l #3,d0						; black
	move.l GfxBase,a6
	move.l a1,-(sp)						; save rport
	jsr _LVOSetAPen(a6)
	move.l (sp)+,a1						; a1=rport
	move.w #PEN_LEFT-1,d0
	move.w #PEN_TOP-1,d1
	move.w #(PEN_LEFT+PEN_WIDTH+1),d2
	move.w #(PEN_TOP+PEN_HEIGHT+1),d3
	move.l GfxBase,a6
	jsr _LVORectFill(a6)
	movem.l (sp)+,d2-d3
	rts
****************
* d0 - returns the address of the PxGGs on success, otherwise 0
MakePxGGs:
	; TODO: this will vary based on the sprite
	move.l #(256*gg_SIZEOF),d0
	move.l #MEMF_CLEAR,d1
	move.l 4.w,a6
	jsr _LVOAllocMem(a6)
	tst.l d0
	beq.s .done
	move.l d0,-(sp)
	move.l d0,a1						; a1=gadget base
	lea.l PxGGTmpl,a0
	move.l d0,gg_NextGadget(a0)			; patch in start of list
	; TODO: this will vary based on the sprite
	move.w #(256-1),d2
.loop:
	move.l #gg_SIZEOF,d0
	move.l 4.w,a6
	move.l a1,-(sp)
	jsr _LVOCopyMem(a6)
	move.l (sp),a0					; a0 = old dest
	bsr.s PatchPxGG
	move.l (sp)+,a0					; a0 = old dest = new source
	move.l a0,a1					; a1 = old dest...
	add.l #gg_SIZEOF,a1				; a1 = new dest = old_dest + gg_SIZEOF
	dbra d2,.loop
.done:
	clr.l gg_NextGadget(a0)
	move.l (sp)+,d0
	rts
****************
* a0 - pointer to GG to patch
PatchPxGG:
	add.l #gg_SIZEOF,gg_NextGadget(a0)
	addq.w #1,gg_GadgetID(a0)
	rts
****************
* a0 - pointer to PxGGs
ArrangePxGGs:
	movem.l d2-d3,-(sp)
	; TODO: this will vary
	moveq #15,d3							; d3 = row counter
	move.w #PX_TOP,d1
.rowLoop:
	; TODO: this will vary
	moveq #15,d2							; d2 = column counter
	move.w #PX_LEFT,d0
.loop:
	move.w d0,gg_LeftEdge(a0)
	move.w d1,gg_TopEdge(a0)
	move.l gg_NextGadget(a0),a0
	add.w #PX_WIDTH+2,d0
	dbra d2,.loop
	add.w #PX_HEIGHT+2,d1
	dbra d3,.rowLoop
	movem.l (sp)+,d2-d3
	rts
****************
* a0 - ptr to SpriteEditor
* a1 - ptr to gadget clicked
SpriteEditorGadgetUp:
	move.w gg_GadgetID(a1),d0
	cmp.w #4,d0								; is this a pal button?
	blt.s SetSpriteEditorPen
	rts
 XDEF SpriteEditorGadgetUp
****************
* a0 - ptr to SpriteEditor
* a1 - ptr to gadget clicked
SpriteEditorGadgetDown:
	move.w gg_GadgetID(a1),d0
	cmp.w #4,d0								; is this a px?
	bge.w PxClicked
	rts
 XDEF SpriteEditorGadgetDown
****************
* a0 - ptr to SpriteEditor
* d0 - new pen colour
SetSpriteEditorPen:
	move.b d0,SpriteEditor_Pen(a0)
	bsr.w DrawPen
	rts
****************
* a0 - ptr to SpriteEditor
* d0 - ID number of px clicked
PxClicked:
	movem.l d2-d3,-(sp)
	sub.w #PX_ID_BASE,d0
	move.w d0,d1							; d1 = id clicked
	; TODO: this will change
	and.w #$000F,d0							; d0 = column
	lsr.w #4,d1								; d1 = row
	move.w d0,d2							; d2 = column
	lsl.w #3,d0								; d0 = column px offset
	add.w d2,d0								; ...
	move.w d1,d2							; d2 = row
	lsl.w #3,d1								; d1 = row px
	add.w d2,d1								; ...
	add.w #PX_LEFT,d0
	add.w #PX_TOP,d1
	move.w d0,d2							; d2 = column px
	add.w #PX_WIDTH,d2
	move.w d1,d3
	add.w #PX_HEIGHT,d3
	move.l SpriteEditor_Window(a0),a0
	move.l wd_RPort(a0),a1
	jsr _LVORectFill(a6)
	movem.l (sp)+,d2-d3
	rts
****************
* a0 - ptr to SpriteEditor
CloseSpriteEditor:
.closeWindow:
	move.l a0,-(sp)
	move.l SpriteEditor_Window(a0),a0
	move.l IntuiBase,a6
	jsr _LVOCloseWindow(a6)
.freePxGGs
	move.l (sp),a1						; a1 = sprite editor
	move.l SpriteEditor_PxGGs(a1),a1
	; TODO: this will change
	move.l #256,d0
	move.l 4.w,a6
	jsr _LVOFreeMem(a6)
.freeEditor:							; a1 = sprite editor
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
PEN_TOP		=110
PEN_WIDTH	=PAL_WIDTH
PEN_HEIGHT	=PAL_HEIGHT

PX_LEFT		=9
PX_TOP		=33
PX_WIDTH	=4
PX_HEIGHT	=4

**** NewWindow
* when a new sprite editor is created, this struct is updated to refer
* to the correct data
	EVEN
SprNewWin:
	dc.w 20,20										; left,top
	dc.w SPR_WIDTH,SPR_HEIGHT						; width, height
	dc.b -1,-1										; default pens
	dc.l CLOSEWINDOW!GADGETUP!GADGETDOWN
	dc.l WINDOWCLOSE!WINDOWDEPTH!WINDOWDRAG
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
	dc.w PAL_LEFT,PAL_TOP				; left, top
	dc.w PAL_WIDTH,PAL_HEIGHT
	dc.w GFLG_GADGHBOX
    dc.w GACT_RELVERIFY					; activation
	dc.w GTYP_BOOLGADGET
	dc.l PalBorder
	dc.l 0								; no selected render
	dc.l 0								; no text
	dc.l 0								; no mutual exclude
	dc.l 0								; no special info
	dc.w 3								; pen colour 3
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
	dc.w 2								; pen colour 2
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
	dc.w 1								; pen colour 1
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
	dc.w 0								; pen colour 0
	dc.l 0								; no special user data
.pen:
	dc.b 0
	dc.b 0								; unused
.pxGGs:
	dc.l 0
	
PX_ID_BASE	=4

PxGGTmpl:
	dc.l 0								; next gadget
	dc.w PX_LEFT,PX_TOP					; left, top
	dc.w PX_WIDTH,PX_HEIGHT
	dc.w GFLG_GADGHBOX					; don't highlight on click
	dc.w GACT_RELVERIFY
	dc.w GTYP_BOOLGADGET
	dc.l PxBorder
	dc.l 0								; no selected render
	dc.l 0								; no text
	dc.l 0								; no mutual exclude
	dc.l 0								; no special info
	dc.w PX_ID_BASE-1
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

** Px

	EVEN
PxBorderPts:
	dc.w -1,-1
	dc.w PX_WIDTH+1,-1
	dc.w PX_WIDTH+1,PX_HEIGHT+1
	dc.w -1,PX_HEIGHT+1
	dc.w -1,-1

PxBorder:
	dc.w -1,-1
	dc.b 1,0
	dc.b 0
	dc.b 5
	dc.l PxBorderPts
	dc.l 0
