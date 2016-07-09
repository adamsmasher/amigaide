 RSRESET
TileEditor_Next: 		rs.l 1
TileEditor_Prev: 		rs.l 1
TileEditor_Window:	rs.l 1
TileEditor_Title:		rs.b 11
TileEditor_Quit:		rs.b 1
TileEditor_NumGG:		rs.b gg_SIZEOF
TileEditor_NumSI:		rs.b si_SIZEOF
TileEditor_NumBuf:	rs.b 4
TileEditor_NameGG:	rs.b gg_SIZEOF
TileEditor_NameSI:	rs.b si_SIZEOF
TileEditor_PalGGs:	rs.b gg_SIZEOF*4
TileEditor_PrevGG:	rs.b gg_SIZEOF
TileEditor_NextGG:	rs.b gg_SIZEOF
TileEditor_PassableGG:rs.b gg_SIZEOF
TileEditor_Pen:		rs.b 1
TileEditor_Unsaved:	rs.b 1
TileEditor_Image:		rs.b ig_SIZEOF
TileEditor_Data:		rs.l 1
TileEditor_Num:		rs.w 1

TILEEDITOR_SIZEOF	=__RS
