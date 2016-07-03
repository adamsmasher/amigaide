TILES_PER_SET			=64
TILESETS				=16

 RSRESET
Project_TilesetCnt:		rs.w 1
Project_TilesetNames:	rs.b 16*TILESETS
Project_TilesetImgs:	rs.b 64*TILES_PER_SET*TILESETS
Project_TilesetPassable:rs.b 1*TILES_PER_SET*TILESETS

PROJECT_SIZEOF			=__RS