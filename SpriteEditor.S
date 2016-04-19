SpriteEditor_Next	=0
SpriteEditor_Window	=4
SpriteEditor_Quit	=8

SPRITEEDITOR_SIZE	=9

	SECTION Text,CODE
****************
NewSpriteEditor:
	move.l a2,-(sp)
.allocEditor:
	moveq.l #SPRITEEDITOR_SIZE,d0	; allocate this many bytes
	move.l #MEMF_CLEAR,d1		; best available local, clear it
	move.l 4.w,a6
	jsr _AllocMem(a6)
	tst.l d0			; success?
	beq.s .done			; fail otherwise
	move.l d0,a2			; a2 = SpriteEditor ptr
.openWindow:
	move.l IntuiBase,a6
	lea.l SprNewWin,a0
	jsr _OpenWindow(a6)
	tst.l d0			; success?
	beq.s .freeEditor		; fail if not
	move.l d0,SpriteEditor_Window(a2)
.updateSigMask:
	move.l d0,a0
	bsr.w AddWinToSigMask
.updateSprEditorList:
	move.l FirstSprEditor,SpriteEditor_Next(a2)
	move.l a2,FirstSprEditor
	bsr.s .done
.freeEditor:
	move.l a2,a1
	moveq.l #SPRITEEDITOR_SIZE,d0
	move.l 4.w,a6
	jsr _FreeMem(a6)
.done:	move.l (sp)+,a2
	rts
****************
* a0 - ptr to SpriteEditor
CloseSpriteEditor:
.closeWindow:
	move.l a0,-(sp)
	move.l SpriteEditor_Window(a0),a0
	move.l IntuiBase,a6
	jsr _CloseWindow(a6)
.freeEditor:
	move.l (sp)+,a1
	moveq.l #SPRITEEDITOR_SIZE,d0
	move.l 4.w,a6
	jmp _FreeMem(a6)

	SECTION MyData,DATA
******** Sprite window

SPR_WIDTH	=128
SPR_HEIGHT	=144

SprTitle:
	dc.b "Sprite",0

**** Gadgets

** SprNum

SPRNUM_WIDTH	=24
SPRNUM_HEIGHT	=10

	EVEN
SprNumBorderPts:
	dc.w 0,0
	dc.w SPRNUM_WIDTH,0
	dc.w SPRNUM_WIDTH,SPRNUM_HEIGHT
	dc.w 0,SPRNUM_HEIGHT
	dc.w 0,0

SprNumBorder:
	dc.w 0,0			; left, top
	dc.b 3,3			; pens
	dc.b 0				; JAM1
	dc.b 5				; 5 points
	dc.l SprNumBorderPts
	dc.l 0				; no next

SprNumBuf:
	dc.l 0

SprNumInfo:
	dc.l SprNumBuf
	dc.l 0				; no undo buffer
	dc.w 0				; buffer pos
	dc.w 4				; max chars + NULL
	dc.w 0				; disp pos
	dc.w 0				; undo pos
	dc.w 0				; numchars
	dc.w 0				; dispcount
	dc.w 0,0			; cleft, ctop
	dc.l 0				; unused
	dc.l 0				; long int
	dc.l 0				; default key map

SprNumGadget:
; TODO: add more gadgets
	dc.l 0				; next gadget
	dc.w 0,0			; left, top
	dc.w 24,10			; width, height
	dc.w 0				; no flags?
	dc.w 0				; activation?
	dc.w GTYP_STRGADGET
	dc.l SprNumBorder
	dc.l 0				; no selected render
	dc.l 0				; no text
	dc.l 0				; no mutual exclude
	dc.l 0				; no special info
	dc.w 0				; no ID
	dc.l 0				; no special user data

**** NewWindow
	EVEN
SprNewWin:
	dc.w 20,20			; left,top
	dc.w SPR_WIDTH,SPR_HEIGHT	; width, height
	dc.b -1,-1			; default pens
	dc.l MOUSEBUTTONS!CLOSEWINDOW
	dc.l WINDOWCLOSE!WINDOWDEPTH!WINDOWDRAG!RMBTRAP
	dc.l 0
	dc.l 0				; default checkmark image
	dc.l SprTitle
	dc.l 0				; write screen ptr here
	dc.l 0				; no bitmap
	dc.w SPR_WIDTH,SPR_HEIGHT	; min width/height
	dc.w SPR_WIDTH,SPR_HEIGHT	; max width/height
	dc.w CUSTOMSCREEN		; type
