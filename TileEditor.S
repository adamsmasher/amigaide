	INCLUDE "exec/exec.i"
	INCLUDE "exec/exec_lib.i"
	INCLUDE "graphics/gfx.i"
	INCLUDE "graphics/graphics_lib.i"
	INCLUDE "intuition/intuition.i"
	INCLUDE "intuition/intuition_lib.i"
	
	INCLUDE "bcd_intf.i"

	INCLUDE "globals.i"

	INCLUDE "Project.i"
	INCLUDE "TileEditor.i"

	SECTION TileEditor,CODE
****************
* returns in d0 address of new tile editor, or NULL on failure
AllocEditor:
	move.l #TILEEDITOR_SIZEOF,d0		; allocate this many bytes
	move.l #MEMF_CLEAR,d1				; best available local, clear it
	move.l 4.w,a6
	jmp _LVOAllocMem(a6)
****************
* a1 - ptr to TileEditor memory
MakeEditor:
	lea.l TileEditorTemplate,a0			; src
	move.l #TILEEDITOR_SIZEOF,d0		; size
	move.l 4.w,a6
	jmp _LVOCopyMem(a6)
****************
* a0 - ptr to TileEditor
PatchEditorOffsets:
	move.l a0,d0						; d0=tileeditor base
	lea.l TileEditPatchLocs,a1
; NB: it is INTENTIONAL that the first patch point can be 0
	move.l (a1)+,d1						; d1=patch offset
.loop:
	add.l d0,(a0,d1.l)					; patch
	move.l (a1)+,d1
	tst.l d1							; is it 0?
	bne.s .loop
	rts
****************
* a0 - ptr to TileEditor
PatchNewWin:
	lea.l TileNewWin,a1
	move.l a0,-(sp)
	lea.l TileEditor_NumGG(a0),a0
	move.l a0,nw_FirstGadget(a1)
	move.l (sp)+,a0						; a0 = tile editor ptr
	lea.l TileEditor_Title(a0),a0
	move.l a0,nw_Title(a1)
	rts
****************
* d0 - Tileset number
* returns in d0 address of new tile editor, or NULL on failure
NewTileEditor:
	movem.l a2-a3,-(sp)
	move.w d0,-(sp)						; save tileset number
	bsr.s AllocEditor
	tst.l d0							; success?
	beq.w .done							; fail otherwise
	move.l d0,a3						; a3 = TileEditor ptr
	move.l a3,a1						; a1 = TileEditor ptr
	bsr.s MakeEditor
	move.l a3,a0						; a0 = TileEditor ptr
	bsr.s PatchEditorOffsets
	move.l a3,a0						; a0 = TileEditor ptr
	bsr.s PatchNewWin
.setTileEditorNum:
	move.w (sp)+,d0						; d0 = tileset number
	move.l a3,a0						; a0 = TileEditorPtr
	bsr.w SetTileEditorNum
.loadImageData:
	move.l a3,a0
	bsr.w LoadImageData
.openWindow:
	lea.l TileNewWin,a0
	move.l IntuiBase,a6
	jsr _LVOOpenWindow(a6)
	tst.l d0							; success?
	beq.s .freeEditor					; fail if not
	move.l d0,TileEditor_Window(a3)
.disableTileNum:
	lea.l TileEditor_NumGG(a3),a0
	move.l d0,a1						; a1=Window
	move.l #0,a2						; no requester
	move.l IntuiBase,a6
	jsr _LVOOffGadget(a6)
	move.l a3,a0
	bsr.s DrawTileEditor
.finish:
	move.l a3,d0						; return in d0
	bra.s .done
.freeEditor:
	move.l a3,a1						; a1=editor to free
	move.l #TILEEDITOR_SIZEOF,d0
	move.l 4.w,a6
	jsr _LVOFreeMem(a6)
	moveq.l #0,d0						; return NULL
.done:
	movem.l (sp)+,a2-a3
	rts

	XDEF NewTileEditor
****************
* a0 - ptr to TileEditor
DrawTileEditor:
	move.l a0,-(sp)
	move.l TileEditor_Window(a0),a0
	move.l wd_RPort(a0),a0
	bsr.s DrawPal
	move.l (sp),a0
	move.l TileEditor_Window(a0),a1
	move.l wd_RPort(a1),a1
	bsr.w DrawPenBg
	move.l (sp),a0
	bsr.w DrawPen
	move.l (sp),a0
	bsr.w DrawGrid
	move.l (sp),a0
	bsr.w DrawImage
	move.l (sp)+,a0
	bra.w DrawPreview
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
* a0 - ptr to TileEditor
DrawPen:
	movem.l d2-d3/a2,-(sp)
	move.b TileEditor_Pen(a0),d0
	move.l TileEditor_Window(a0),a0
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
* a0 - TileEditor to update preview for
DrawPreview:
	move.l a0,-(sp)
	bsr.s DrawPreviewBg
	move.l (sp)+,a0
	bra.s DrawPreviewImg
****************
* a0 - TileEditor to update preview for
DrawPreviewBg:
	movem.l d2-d3,-(sp)
	move.l TileEditor_Window(a0),a0
	move.l wd_RPort(a0),a1
	moveq #3,d0							; pen clr
	move.l GfxBase,a6
	movem.l a1/a6,-(sp)
	jsr _LVOSetAPen(a6)
	movem.l (sp)+,a1/a6
	move.w #PREVIEW_LEFT-1,d0
	move.w #PREVIEW_TOP-1,d1
	move.w #PREVIEW_LEFT+PREVIEW_WIDTH,d2
	move.w #PREVIEW_TOP+PREVIEW_HEIGHT,d3
	jsr _LVORectFill(a6)
	movem.l (sp)+,d2-d3
	rts
****************
* a0 - TileEditor to update preview for
DrawPreviewImg:
	lea.l TileEditor_Image(a0),a1
	move.l TileEditor_Window(a0),a0
	move.l wd_RPort(a0),a0
	move.w #PREVIEW_LEFT,d0
	move.w #PREVIEW_TOP,d1
	move.l IntuiBase,a6
	jmp _LVODrawImage(a6)
****************
* a0 - TileEditor to draw Grid for
DrawGrid:
	movem.l d2-d4/a2,-(sp)
.setColor:
	move.l TileEditor_Window(a0),a1
	move.l wd_RPort(a1),a1
	move.l a1,a2							; a2 = rport
	moveq #3,d0								; black
	move.l GfxBase,a6
	jsr _LVOSetAPen(a6)
.placePen:
	move.l a2,a1							; a1 = rport
	move.w GridPoints,d2					; d2 = pen x
	move.w GridPoints+2,d3					; d3 = pen y
	move.w d2,d0							; d0 = pen x
	move.w d3,d1							; d1 = pen y
	move.l GfxBase,a6
	jsr _LVOMove(a6)
.drawBox:
	move.l a2,a1							; a1 = rport
	lea.l GridPoints,a0
	moveq #5,d0								; 5 points
	move.l GfxBase,a6
	jsr _LVOPolyDraw(a6)
.drawVLines:
	moveq #(15-1),d4
.vloop:
.movePenRight:
	add.w #PX_WIDTH+1,d2
	move.w d2,d0							; d0 = pen x
	move.w d3,d1							; d1 = pen y
	move.l a2,a1							; a1 = r port
	move.l GfxBase,a6
	jsr _LVOMove(a6)
.drawVLine:
	move.l a2,a1
	move.w d2,d0							; d0 = pen x
	move.w d3,d1							; d1 = pen y
	add.w #(PX_HEIGHT+1)*16,d1				; d1 = endpoint
	move.l GfxBase,a6
	jsr _LVODraw(a6)
	dbra d4,.vloop
.resetPen:
	move.w GridPoints,d2
	move.w GridPoints+2,d3
	move.w d2,d0
	move.w d3,d1
	move.l a2,a1
	move.l GfxBase,a6
	jsr _LVOMove(a6)
.drawHLines:
	moveq #(15-1),d4
.hloop:
.movePenDown:
	add.w #PX_HEIGHT+1,d3
	move.w d2,d0							; d0 = pen x
	move.w d3,d1							; d1 = pen y
	move.l a2,a1							; a1 = r port
	move.l GfxBase,a6
	jsr _LVOMove(a6)
.drawHLine:
	move.l a2,a1
	move.w d2,d0							; d0 = pen x
	move.w d3,d1							; d1 = pen y
	add.w #(PX_WIDTH+1)*16,d0				; d0 = endpoint
	move.l GfxBase,a6
	jsr _LVODraw(a6)
	dbra d4,.hloop
	movem.l (sp)+,d2-d4/a2
	rts
****************
* a0 - ptr to tile editor
RedrawTitle:
	move.l a2,-(sp)
	lea.l TileEditor_Title(a0),a1
	move.l TileEditor_Window(a0),a0
	move.l #-1,a2							; don't change screen title
	move.l IntuiBase,a6
	jsr _LVOSetWindowTitles(a6)
	move.l (sp)+,a2
	rts
****************
* a0 - ptr to tile editor
SetUnsaved:
	move.b #1,TileEditor_Unsaved(a0)
	move.b #'*',TileEditor_Title+10(a0)
	bra.s RedrawTitle
****************
* a0 - ptr to TileEditor
* a1 - ptr to gadget clicked
TileEditorGadgetDown:
	move.w gg_GadgetID(a1),d0
	cmp.w #PASSABLE_ID,d0
	beq.s TogglePassable
	rts
 XDEF TileEditorGadgetDown
****************
* a0 - ptr to TileEditor
TogglePassable:
	bra.s SetUnsaved
****************
* a0 - ptr to TileEditor
* a1 - ptr to gadget clicked
TileEditorGadgetUp:
	move.w gg_GadgetID(a1),d0
	cmp.w #4,d0								; is this a pal button?
	blt.s SetTileEditorPen
	cmp.w #NAME_ID,d0
	beq.s UpdateName
	cmp.w #NEXT_ID,d0
	beq.s NextTile
	cmp.w #PREV_ID,d0
	beq.s PrevTile
	rts
 XDEF TileEditorGadgetUp
****************
* a0 - ptr to TileEditor
UpdateName:
	bra.s SetUnsaved
****************
* a0 - ptr to TileEditor
* d0 - new pen colour
SetTileEditorPen:
	move.b d0,TileEditor_Pen(a0)
	bsr.w DrawPen
	rts
****************
* a0 - ptr to TilesetEditor
NextTile:
	move.l TileEditor_NumSI+si_LongInt(a0),d0
	addq.b #1,d0
	and.l #(TILES_PER_SET-1),d0
	bra.s UpdateTileNum
****************
* a0 - ptr to TilesetEditor
PrevTile:
	move.l TileEditor_NumSI+si_LongInt(a0),d0
	subq.b #1,d0
	and.l #(TILES_PER_SET-1),d0
	bra.s UpdateTileNum
	rts
****************
* a0 - ptr to TilesetEditor
* d0 - new TileNum
UpdateTileNum:
	move.w d0,-(sp)
	move.l a0,-(sp)
.removeGadget:
	lea.l TileEditor_NumGG(a0),a1
	move.l TileEditor_Window(a0),a0
	move.l IntuiBase,a6
	jsr _LVORemoveGadget(a6)
.updateNum:
	move.l (sp),a0									; a0 = TilesetEditor
	move.w 4(sp),d0									; d0 = new Tilenum
	move.l d0,TileEditor_NumSI+si_LongInt(a0)
	move.l TileEditor_NumSI+si_Buffer(a0),a0
	lea.l TensTable,a1
	move.b (a1,d0),d1								; d1 = tens digit
	lsr.b #4,d1
	beq.s .writeOnesDigit
	add.b #'0',d1									; d1 = tens digit ASCII
	move.b d1,(a0)+									; write tens digit
.writeOnesDigit
	lea.l OnesTable,a1
	move.b (a1,d0),d1								; d1 = ones digit
	add.b #'0',d1									; d1 = ones digit ASCII
	move.b d1,(a0)+									; write ones digit
	clr.b (a0)										; write terminator
.addGadget:
	move.l (sp),a0									; a0 = Tileset Editor
	lea.l TileEditor_NumGG(a0),a1
	move.l TileEditor_Window(a0),a0
	move.w #-1,d0									; position = EOL
	move.l IntuiBase,a6
	jsr _LVOAddGadget(a6)
.refreshGadget:
	move.l (sp),a0									; a0 = TilesetEditor
	move.l TileEditor_Window(a0),a1
	lea.l TileEditor_NumGG(a0),a0
	move.l #0,a2									; no requester
	move.l IntuiBase,a6
	jsr _LVORefreshGadgets(a6)
.updateData:
	move.l (sp),a0									; a0 = TilesetEditor
	move.w 4(sp),d0									; d0 = New Num
	move.w TileEditor_Num(a0),d1
	lsl.w #8,d1										; 4096 bytes per set
	lsl.w #4,d1
	lsl.w #6,d0										; 64 bytes per tile
	lea.l Project+Project_TilesetImgs,a1
	lea.l (a1,d1),a1								; get tileset base
	lea.l (a1,d0),a1								; get tile base
	move.l a1,TileEditor_Data(a0)
	bsr.w LoadImageData
	move.l (sp),a0									; a0 = TilesetEditor
	bsr.w DrawImage
	move.l (sp)+,a0									; a0 = TilesetEditor
	bsr.w DrawPreview
	addq.l #2,sp									; pop off new num
	rts
****************
* a0 - ptr to TileEditor
* d0 - mouse X
* d1 - mouse Y
* d2 - mouse code
TileEditorMouseButtons:
	cmp.w #SELECTUP,d2
	beq.s .selectUp
	cmp.w #SELECTDOWN,d2
	beq.s .selectDown
	rts
.selectUp:
	moveq #0,d0								; d0 = FALSE, stop mouse moving
	move.l TileEditor_Window(a0),a0
	move.l IntuiBase,a6
	jmp _LVOReportMouse(a6)
.selectDown:
	movem.l d0-d1/a0,-(sp)
	bsr.s InPxRange
	tst.w d0
	movem.l (sp)+,d0-d1/a0
	beq.s .done
	movem.l d0-d1/a0,-(sp)
	bsr.w SetUnsaved
	movem.l (sp),d0-d1/a0
	moveq #1,d0								; d0 = TRUE, capture mouse
	move.l TileEditor_Window(a0),a0
	move.l IntuiBase,a6
	jsr _LVOReportMouse(a6)
	movem.l (sp)+,d0-d1/a0					; d0-d1=mouse; a0 = TileEditor
	move.l a0,-(sp)
	bsr.s ToColRow
	move.l (sp)+,a0							; a0 = tile editor
	bsr.s PxClicked
.done:
	rts	

 XDEF TileEditorMouseButtons
****************
* d0 - mouse X
* d1 - mouse Y
* returns 1 in d0 if in range, otherwise 0
InPxRange:
	cmp.w #PX_LEFT,d0
	blt.s .out
	cmp.w #PX_TOP,d1
	blt.s .out
	cmp.w #PX_LEFT+(16*8),d0
	bge.s .out
	cmp.w #PX_TOP+(16*8),d1
	bge.s .out
	moveq #1,d0
	rts
.out:
	moveq #0,d0
	rts
****************
* d0 - mouse X
* d1 - mouse Y
* returns in d0,d1 column and row
ToColRow:
	sub.w #PX_LEFT,d0
	sub.w #PX_TOP,d1
	lsr.w #3,d0								; d0 = column
	lsr.w #3,d1								; d1 = row	
	rts
****************
* a0 - ptr to tile editor
* d0 - mouse X
* d1 - mouse Y
TileEditorMouseMove:
	movem.l d0-d1/a0,-(sp)
	bsr.s InPxRange
	movem.l (sp)+,d0-d1/a0
	beq.s .done
	move.l a0,-(sp)
	bsr.s ToColRow
	move.l (sp)+,a0
	bra.s PxClicked
.done:
	rts
 XDEF TileEditorMouseMove
****************
* a0 - ptr to TileEditor
* d0 - column clicked
* d1 - row clicked
PxClicked:
	movem.l d0-d1/a0,-(sp)
	bsr.s DrawPxGG
	movem.l (sp)+,d0-d1/a0
	move.l a0,-(sp)
	bsr.w DrawPxData
	move.l (sp)+,a0
	bra.w DrawPreviewImg
*****************
* a0 - ptr to TilesetEditor
* d0 - column
* d1 - row
DrawPxGG:
	movem.l d0-d1/a0,-(sp)
	move.b TileEditor_Pen(a0),d0
	bsr.s SetRPortColour
	movem.l (sp)+,d0-d1/a0
	bra.s DrawPx
	rts
****************
* a0 - ptr to TilesetEditor
* d0 - colour
SetRPortColour:
	move.l TileEditor_Window(a0),a0
	move.l wd_RPort(a0),a1
	move.l GfxBase,a6
	jmp _LVOSetAPen(a6)	
****************
* presumes correct pen is set
* a0 - ptr to TileEditor
* d0 - column
* d1 - row
DrawPx:
	movem.l d2-d3,-(sp)
	lsl.w #3,d0								; d0 = column px offset
	lsl.w #3,d1								; d1 = row px
	add.w #PX_LEFT+1,d0
	add.w #PX_TOP+1,d1
	move.w d0,d2							; d2 = column px
	add.w #PX_WIDTH-1,d2
	move.w d1,d3
	add.w #PX_HEIGHT-1,d3
	move.l TileEditor_Window(a0),a0
	move.l wd_RPort(a0),a1
	move.l GfxBase,a6
	jsr _LVORectFill(a6)
	movem.l (sp)+,d2-d3
	rts
****************
* a0 - ptr to TilesetEditor
DrawImage:
	movem.l d2/a2-a3,-(sp)
	move.l a0,a2							; a2 = TilesetEditor
	move.l TileEditor_Data(a0),a3
	clr.w d2								; row = 0
.loop:
	move.l a2,a0							; a0 = TilesetEditor
	move.l a3,a1							; a1 = ptr to chunk
	move.w d2,d0							; d0 = row
	bsr.s DrawRow
	addq.l #2,a3							; Next chunk
	addq.w #1,d2							; row++
	cmp.w #16,d2							; does row = 16?
	bne.s .loop								; if not, loop
	movem.l (sp)+,d2/a2-a3
	rts
******************
* a0 - ptr to TilesetEditor
* a1 - ptr to chunk
* d0 - row
DrawRow:
	movem.l d2-d5/a2,-(sp)
	move.l a0,a2							; a2 = TilesetEditor
	move.w (a1),d2							; get plane 1 word
	move.w 32(a1),d3						; get plane 2 word
	clr.w d4								; column = 0	
	move.w d0,d5							; d5 = row
.loop:
	move.w d3,d0							; d0 = next px (plane 2)
	rol.w #1,d0								; shift high order bit to bit 0
	lsl.w #1,d0								; shift it to bit 1
	and.w #$0002,d0							; get rid of everything else
	move.w d2,d1							; d1 = next px (plane 1)
	rol.w #1,d1								; shift high order bit to bit 0
	and.w #1,d1								; get rid of everything else
	or.w d1,d0								; make color
	move.l a2,a0							; a0 = TilesetEditor
	bsr.w SetRPortColour
	move.l a2,a0							; a0 = TilesetEditor
	move.w d4,d0							; d0 = row
	move.w d5,d1							; d1 = column
	bsr.w DrawPx
	lsl.w d2								; next px (plane 1)
	lsl.w d3								; next px (plane 2)
	add.w #1,d4								; next column
	cmp.w #16,d4
	bne.s .loop	
	movem.l (sp)+,d2-d5/a2
	rts
****************
* a0 - ptr to TileEditor
* d0 - column
* d1 - row
DrawPxData:
	lea.l TileEditor_Image(a0),a1
	move.l ig_ImageData(a1),a1
	movem.l d0-d1/a0,-(sp)
	bsr.s DrawIntoBuffer
	movem.l (sp)+,d0-d1/a0
	move.l TileEditor_Data(a0),a1
	bra.s DrawIntoBuffer
	rts
****************
* a0 - ptr to TileEditor
* a1 - buffer
* d0 - column
* d1 - row
DrawIntoBuffer:	
	movem.l d2-d3,-(sp)
	lsl.w #1,d1								; d1 = row byte offset
	move.w d0,d2							; d2 = column
	lsr.w #3,d2								; d2 = column byte offset
	add.w d2,d1								; d1 = byte offset
	and.w #$0007,d0							; d0 = bit to set
	neg.w d0
	add.w #7,d0
	move.b TileEditor_Pen(a0),d2
	moveq #1,d3								; 2 bitplanes
.loop:
	btst #0,d2
	beq.s .bclr
	bset d0,(a1,d1)
	bra.s .loopEnd
.bclr:
	bclr d0,(a1,d1)
.loopEnd:
	lsr.b #1,d2								; next bit plane
	add.l #32,a1							; next bit plane
	dbra d3,.loop
	movem.l (sp)+,d2-d3
	rts
****************
* a0 - ptr to TileEditor
CloseTileEditor:
.closeWindow:
	move.l a0,-(sp)
	move.l TileEditor_Window(a0),a0
	move.l IntuiBase,a6
	jsr _LVOCloseWindow(a6)
.freeEditor:
	move.l (sp)+,a1							; a1 = tile editor
	move.l #TILEEDITOR_SIZEOF,d0
	move.l 4.w,a6
	jmp _LVOFreeMem(a6)

	XDEF CloseTileEditor
****************
* Called during construction to set the tile editor num
* a0 - ptr to TileEditor
* d0 - tile editor num
SetTileEditorNum:
	move.l a2,-(sp)
	move.l a0,a2							; a2 = TileEditor
	move.w d0,-(sp)
	bsr.s SetTilesetEditorData
	move.l a2,a0							; a0 = TileEditor
	move.w (sp)+,d0							; d0 = tile editor num
	move.w d0,TileEditor_Num(a2)
	lea.l Project+Project_TilesetNames,a0
	move.w d0,d1							; d1 = Tileset number
	lsl.w #4,d1								; d1 = Offset into tileset names
	lea.l (a0,d1),a0						; a0 = ptr to name
	move.l a0,TileEditor_NameSI+si_Buffer(a2)	
	lea.l TensTable,a0
	move.b (a0,d0),d1						; d1 = tens digit
	lsr.b #4,d1
	add.b #'0',d1							; d1 = tens digit ASCII
	move.b d1,TileEditor_Title+8(a2)
	lea.l OnesTable,a0
	move.b (a0,d0),d1
	add.b #'0',d1							; d0 = ones digit ASCII
	move.b d1,TileEditor_Title+9(a2)
	move.l (sp)+,a2
	rts
*******************
* a0 - TilesetEditor
* d0 - Tileset #
SetTilesetEditorData:
	lsl.w #8,d0										; 4096 bytes per tile
	lsl.w #4,d0
	lea.l Project+Project_TilesetImgs,a1
	lea.l (a1,d0),a1
	move.l a1,TileEditor_Data(a0)
	rts
*******************
* a0 - TilesetEditor
LoadImageData:
	move.l TileEditor_Image+ig_ImageData(a0),a1	; a1 = dest
	move.l TileEditor_Data(a0),a0					; a0 = source
	move.l #64,d0									; d0 = length
	move.l 4.w,a6									; exec
	jmp _LVOCopyMem(a6)

	SECTION MyData,DATA
******** Tile window
**** Constants

TILE_WIDTH	=160
TILE_HEIGHT	=192

TILENAME_WIDTH   =88
TILENAME_HEIGHT  =10

TILENUM_WIDTH	=24
TILENUM_HEIGHT	=10

PAL_WIDTH	=16
PAL_HEIGHT	=16
PAL_LEFT	=144
PAL_TOP		=33

PEN_LEFT	=PAL_LEFT
PEN_TOP		=104
PEN_WIDTH	=PAL_WIDTH-1
PEN_HEIGHT	=PAL_HEIGHT

PX_LEFT		=8
PX_TOP		=32
PX_WIDTH	=7
PX_HEIGHT	=7

PREV_ID		=$100
NEXT_ID		=$200
PASSABLE_ID	=$400
NAME_ID		=$800

	EVEN
GridPoints:
	dc.w PX_LEFT,PX_TOP
	dc.w PX_LEFT+(PX_WIDTH+1)*16,PX_TOP
	dc.w PX_LEFT+(PX_WIDTH+1)*16,PX_TOP+(PX_HEIGHT+1)*16
	dc.w PX_LEFT,PX_TOP+(PX_HEIGHT+1)*16
	dc.w PX_LEFT,PX_TOP

PREVIEW_LEFT	=PEN_LEFT
PREVIEW_TOP		=144
PREVIEW_WIDTH	=16
PREVIEW_HEIGHT	=16

PREV_LEFT		=108
PREV_TOP		=172
PREV_WIDTH		=24
PREV_HEIGHT		=16

NEXT_LEFT		=PREV_LEFT+PREV_WIDTH+4
NEXT_TOP		=PREV_TOP
NEXT_WIDTH		=PREV_WIDTH
NEXT_HEIGHT		=PREV_HEIGHT

PASSABLE_TOP	=176
PASSABLE_LEFT	=9
PASSABLE_WIDTH	=8
PASSABLE_HEIGHT	=8

**** NewWindow
* when a new tile editor is created, this struct is updated to refer
* to the correct data
	EVEN
TileNewWin:
	dc.w 20,20										; left,top
	dc.w TILE_WIDTH,TILE_HEIGHT						; width, height
	dc.b -1,-1										; default pens
	dc.l CLOSEWINDOW!GADGETUP!GADGETDOWN!MOUSEBUTTONS!MOUSEMOVE
	dc.l WINDOWCLOSE!WINDOWDEPTH!WINDOWDRAG
	dc.l 0											; PATCH gadget
	dc.l 0											; default checkmark image
	dc.l 0											; PATCH title
	dc.l 0											; PATCH screen ptr
	dc.l 0											; no bitmap
	dc.w TILE_WIDTH,TILE_HEIGHT						; min width/height
	dc.w TILE_WIDTH,TILE_HEIGHT						; max width/height
	dc.w CUSTOMSCREEN								; type

**** Template
* When a new tile editor is created, memory for the following is
* allocated and this is copied into it. The base pointer is then
* added onto any relative "pointer"s in the struct

	EVEN
TileEditorTemplate:
	dc.l 0								; next
	dc.l 0								; prev
	dc.l 0								; window
	dc.b "Tileset xx",0					; title
	dc.b 0								; quit
.numGG:
	dc.l TileEditor_NameGG			; next gadget
	dc.w 5,4							; left, top
	dc.w TILENUM_WIDTH,TILENUM_HEIGHT
	dc.w GADGHCOMP
    dc.w GACT_STRINGRIGHT!GACT_LONGINT
	dc.w GTYP_STRGADGET
	dc.l TileNumBorder
	dc.l 0								; no selected render
	dc.l 0								; no text
	dc.l 0								; no mutual exclude
	dc.l TileEditor_NumSI
	dc.w 0								; no ID
	dc.l 0								; no special user data
.numSI:
	dc.l TileEditor_NumBuf
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
	dc.l TileEditor_PalGGs			; next gadget
	dc.w 35,4							; left, top
	dc.w TILENAME_WIDTH,TILENAME_HEIGHT
	dc.w GADGHCOMP
    dc.w GACT_RELVERIFY					; activation
	dc.w GTYP_STRGADGET
	dc.l TileNameBorder
	dc.l 0								; no selected render
	dc.l 0								; no text
	dc.l 0								; no mutual exclude
	dc.l TileEditor_NameSI
	dc.w NAME_ID
	dc.l 0								; no special user data
.nameSI:
	dc.l 0								; point into global data
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
.palGGs0:
	dc.l TileEditor_PalGGs+gg_SIZEOF	; next gadget
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
	dc.l TileEditor_PalGGs+gg_SIZEOF*2; next gadget
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
	dc.l TileEditor_PalGGs+(gg_SIZEOF*3); next gadget
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
	dc.l TileEditor_PrevGG		; next gadget
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
.prevTileGG:
	dc.l TileEditor_NextGG			; next gadget
	dc.w PREV_LEFT,PREV_TOP
	dc.w PREV_WIDTH,PREV_HEIGHT
	dc.w GFLG_GADGHCOMP
	dc.w GACT_RELVERIFY
	dc.w GTYP_BOOLGADGET
	dc.l PrevBorder
	dc.l 0
	dc.l PrevText
	dc.l 0
	dc.l 0
	dc.w PREV_ID
	dc.l 0
.nextTileGG:
	dc.l TileEditor_PassableGG
	dc.w NEXT_LEFT,NEXT_TOP
	dc.w NEXT_WIDTH,NEXT_HEIGHT
	dc.w GFLG_GADGHCOMP
	dc.w GACT_RELVERIFY
	dc.w GTYP_BOOLGADGET
	dc.l NextBorder
	dc.l 0
	dc.l NextText
	dc.l 0
	dc.l 0
	dc.w NEXT_ID
	dc.l 0
.passableGG:
	dc.l 0
	dc.w PASSABLE_LEFT,PASSABLE_TOP
	dc.w PASSABLE_WIDTH,PASSABLE_HEIGHT
	dc.w GFLG_GADGHCOMP
	dc.w GACT_TOGGLESELECT!GACT_IMMEDIATE
	dc.w GTYP_BOOLGADGET
	dc.l PassableBorder
	dc.l 0
	dc.l PassableText
	dc.l 0
	dc.l 0
	dc.w PASSABLE_ID
	dc.l 0
.pen:
	dc.b 0
.unsaved:
	dc.b 0
.image:
	dc.w 0,0							; left, top
; TODO: this varies
	dc.w 16,16							; width, height
	dc.w 2								; depth
	dc.l OnscreenImage					; image data
	dc.b 3								; 0b0000.0011 - planes 0 and 1
	dc.b 0								; planeonoff
	dc.l 0
.data:
	dc.l 0								; point into project RAM
.tsnum:
	dc.w 0

TileEditPatchLocs:
	dc.l TileEditor_NumGG+gg_NextGadget
	dc.l TileEditor_NumGG+gg_SpecialInfo
	dc.l TileEditor_NumSI+si_Buffer
	dc.l TileEditor_NameGG+gg_NextGadget
	dc.l TileEditor_NameGG+gg_SpecialInfo
	dc.l TileEditor_PalGGs+gg_NextGadget
	dc.l TileEditor_PalGGs+gg_SIZEOF+gg_NextGadget
	dc.l TileEditor_PalGGs+(gg_SIZEOF*2)+gg_NextGadget
	dc.l TileEditor_PalGGs+(gg_SIZEOF*3)+gg_NextGadget
	dc.l TileEditor_PrevGG+gg_NextGadget
	dc.l TileEditor_NextGG+gg_NextGadget
	XDEF TileEditorTemplate

** TileName

	EVEN
TileNameBorderPts:
	dc.w 0,0
	dc.w TILENAME_WIDTH+3,0
	dc.w TILENAME_WIDTH+3,TILENAME_HEIGHT+3
	dc.w 0,TILENAME_HEIGHT+3
	dc.w 0,0

	EVEN
TileNameBorder:
	dc.w -2,-2
	dc.b 1,0
	dc.b 0
	dc.b 5
	dc.l TileNameBorderPts
	dc.l 0

** TileNum

	EVEN
TileNumBorderPts:
	dc.w 0,0
	dc.w TILENUM_WIDTH+3,0
	dc.w TILENUM_WIDTH+3,TILENUM_HEIGHT+3
	dc.w 0,TILENUM_HEIGHT+3
	dc.w 0,0

TileNumBorder:
	dc.w -2,-2			; left, top
	dc.b 1,0			; pens
	dc.b 0				; JAM1
	dc.b 5				; 5 points
	dc.l TileNumBorderPts
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

	XDEF TileNewWin

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

** Next/Prev

	EVEN
PrevBorderPts:
	dc.w -1,-1
	dc.w PREV_WIDTH+1,-1
	dc.w PREV_WIDTH+1,PREV_HEIGHT+1
	dc.w -1,PREV_HEIGHT+1
	dc.w -1,-1

PrevBorder:
	dc.w -1,-1
	dc.b 1,0
	dc.b 0
	dc.b 5
	dc.l PrevBorderPts
	dc.l 0

	EVEN
NextBorderPts:
	dc.w -1,-1
	dc.w NEXT_WIDTH+1,-1
	dc.w NEXT_WIDTH+1,NEXT_HEIGHT+1
	dc.w -1,NEXT_HEIGHT+1
	dc.w -1,-1

NextBorder:
	dc.w -1,-1
	dc.b 1,0
	dc.b 0
	dc.b 5
	dc.l NextBorderPts
	dc.l 0

	EVEN
PrevTxt:
	dc.b '<<',0
	
	EVEN
NextTxt:
	dc.b '>>',0

	EVEN
PrevText:
	dc.b 3,0
	dc.b 0
	dc.w 4,4
	dc.l 0
	dc.l PrevTxt
	dc.l 0

	EVEN
NextText:
	dc.b 3,0
	dc.b 0
	dc.w 4,4
	dc.l 0
	dc.l NextTxt
	dc.l 0

	EVEN
PassableBorderPts:
	dc.w -1,-1
	dc.w PASSABLE_WIDTH+1,-1
	dc.w PASSABLE_WIDTH+1,PASSABLE_HEIGHT+1
	dc.w -1,PASSABLE_HEIGHT+1
	dc.w -1,-1

PassableBorder:
	dc.w -1,-1
	dc.b 1,0
	dc.b 0
	dc.b 5
	dc.l PassableBorderPts
	dc.l 0

PassableTxt:
	dc.b "Passable?",0

	EVEN
PassableText:
	dc.b 3,0
	dc.b 0
	dc.w 16,0
	dc.l 0
	dc.l PassableTxt
	dc.l 0

 SECTION ImageData,DATA_C
OnscreenImage:
.bp1
	dc.b 0,0,0,0,0,0,0,0
	dc.b 0,0,0,0,0,0,0,0
	dc.b 0,0,0,0,0,0,0,0
	dc.b 0,0,0,0,0,0,0,0
.bp2
	dc.b 0,0,0,0,0,0,0,0
	dc.b 0,0,0,0,0,0,0,0
	dc.b 0,0,0,0,0,0,0,0
	dc.b 0,0,0,0,0,0,0,0
