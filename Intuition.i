******** IDCMP Classes

MOUSEBUTTONS	=$00000008
MENUPICK	=$00000100
CLOSEWINDOW	=$00000200

******** IDCMP Codes

SELECTDOWN	=$68
MENUDOWN	=$69

******** Function Offsets

_ClearMenuStrip	=-48
_CloseScreen	=-66
_CloseWindow	=-72
_DisplayBeep	=-96
_OpenScreen	=-198
_OpenWindow	=-204
_PrintIText	=-216
_SetMenuStrip	=-264
_ShowTitle	=-282
_ActivateWindow	=-450

******** Structure Offsets

**** IntuiMessage
IntuiMessage_Class	=20
IntuiMessage_Code	=24
IntuiMessage_MouseX	=32
IntuiMessage_MouseY	=34

**** NewWindow

NewWindow_Width		=4
NewWindow_Height	=6
NewWindow_Screen	=30
NewWindow_MinWidth	=38
NewWindow_MinHeight	=40
NewWindow_MaxWidth	=42
NewWindow_MaxHeight	=44

**** Screen
Screen_WBorTop		=35
Screen_WBorL		=36
Screen_WBorR		=37
Screen_WBorBot		=38
Screen_Font		=40
Screen_Viewport		=44

**** Window
Window_RastPort		=50
Window_BorderLeft	=54
Window_BorderTop	=55
Window_UserPort		=86

******** NewScreen defines

**** ViewModes

HIRES		=$8000

**** Types

SHOWTITLE	=$0010
CUSTOMBITMAP	=$0040

******** NewWindow defines

**** Flags

WINDOWDRAG	=$00000002
WINDOWDEPTH	=$00000004
WINDOWCLOSE	=$00000008
BACKDROP	=$00000100
BORDERLESS	=$00000800
RMBTRAP		=$00010000

**** Types

CUSTOMSCREEN	=$000F

******** Gadget defines

**** Flags

GFLG_GADGHCOMP	=$0000

**** Activation

GACT_RELVERIFY	=$0001

**** Types

GTYP_BOOLGADGET	=$0001

******** Menu defines

MENUENABLED	=$0001

******* MenuItem defines

ITEMTEXT	=$0002
COMMSEQ		=$0004
ITEMENABLED	=$0010
