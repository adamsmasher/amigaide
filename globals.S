 INCLUDE "Project.i"

	SECTION Globals,BSS
IntuiBase: ds.l 1
GfxBase: ds.l 1
ReqBase: ds.l 1
DosBase: ds.l 1
Project: ds.b PROJECT_SIZEOF

	XDEF IntuiBase
	XDEF GfxBase
	XDEF ReqBase
	XDEF DosBase
	XDEF Project
