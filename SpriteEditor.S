SpriteEditor_Next	=0
SpriteEditor_Window	=4
SpriteEditor_Quit	=8

SPRITEEDITOR_SIZE	=9

	SECTION Text,CODE
****************
SpriteMain:
.allocEditor:
	moveq.l #SPRITEEDITOR_SIZE,d0	; allocate this many bytes
	move.l #MEMF_CLEAR,d1		; best available local, clear it
	move.l 4.w,a6
	jsr _AllocMem(a6)
	tst.l d0			; success?
	beq.s .done
	move.l d0,a2			; a2 = SpriteEditor ptr
.openWindow:
	move.l IntuiBase,a6
	lea.l SprNewWin,a0
	jsr _OpenWindow(a6)
	tst.l d0			; success?
	beq.s .freeEditor		; fail if not
	move.l d0,SpriteEditor_Window(a2)
	bsr.s SprMainLoop
	move.l SpriteEditor_Window(a2),a0
	move.l IntuiBase,a6
	jsr _CloseWindow(a6)
.freeEditor:
	move.l a2,a1			; a1=memory to free
	moveq.l #SPRITEEDITOR_SIZE,d0	; d0=bytes to free
	move.l 4.w,a6
	jsr _FreeMem(a6)
.done:	rts
****
* a2 - pointer to this SpriteEditor
SprMainLoop:
	move.l SpriteEditor_Window(a2),a0
	bsr.w WinWait
	rts

****************

	SECTION MyData,DATA
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
