 RSRESET
SpriteEditor_Next: 		rs.l 1
SpriteEditor_Prev: 		rs.l 1
SpriteEditor_Window:	rs.l 1
SpriteEditor_Title:		rs.b 11
SpriteEditor_Quit:		rs.b 1
SpriteEditor_NumGG:		rs.b gg_SIZEOF
SpriteEditor_NumSI:		rs.b si_SIZEOF
SpriteEditor_NumBuf:	rs.b 4
SpriteEditor_NameGG:	rs.b gg_SIZEOF
SpriteEditor_NameSI:	rs.b si_SIZEOF
SpriteEditor_PalGGs:	rs.b gg_SIZEOF*4
SpriteEditor_PrevGG:	rs.b gg_SIZEOF
SpriteEditor_NextGG:	rs.b gg_SIZEOF
SpriteEditor_PassableGG:rs.b gg_SIZEOF
SpriteEditor_Pen:		rs.b 1
SpriteEditor_Unsaved:	rs.b 1
SpriteEditor_Image:		rs.b ig_SIZEOF
SpriteEditor_Num:		rs.b 1
SpriteEditor_Unused1:	rs.b 1

SPRITEEDITOR_SIZEOF	=__RS
