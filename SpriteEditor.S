	SECTION SprVars,BSS
; TODO: you'll need to allocate all of these per editor
SprWin:	ds.l 1
SprQuit:
	ds.b 1

	SECTION Text,CODE
****************
SpriteMain:
.openWindow:
	move.l IntuiBase,a6
	lea.l SprNewWin,a0
	jsr _OpenWindow(a6)
	tst.l d0
	beq .done
	move.l d0,SprWin
	bsr.s SprMainLoop
	move.l SprWin,a0
	move.l IntuiBase,a6
	jsr _CloseWindow(a6)
.done:	rts
****
SprMainLoop:
	clr.b SprQuit
.loop:	move.l SprWin,a0
	bsr.s WinWait
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
