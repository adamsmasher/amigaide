******** Function Offsets

_AllocEntry	=-222
_AddHead	=-240
_AddTask	=-282
_Wait		=-318
_GetMsg		=-372
_ReplyMsg	=-378
_CloseLibrary	=-414
_LoadLibrary	=-552

******** Structure Offsets

**** List
List_Head	=0
List_Tail	=4
List_TailPred	=8


**** MemEntry
MEMENTRY_SIZE	=8

**** MemList
MemList_ME	=16

**** MsgPort
MsgPort_SigBit	=15

**** Node
NODE_SIZE	=14
Node_Type	=8
Node_Pri	=9
Node_Name	=10

**** Task
TASK_SIZE	=92
Task_SPReg	=54
Task_SPLower	=58
Task_SPUpper	=62
Task_MemEntry	=74

******** Flags

**** MemEntry

MEMF_PUBLIC	=$00000001
MEMF_CLEAR	=$00010000

**** Node

NT_TASK		=1
