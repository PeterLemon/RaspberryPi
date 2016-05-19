; Raspberry Pi 3 'Bare Metal' V3D Clear Color Control List Demo by krom (Peter Lemon):
; 1. Run Tags & Set V3D Frequency To 250MHz, & Enable Quad Processing Unit
; 2. Setup Frame Buffer
; 3. Setup & Run V3D Control List Rendered Tile Buffer

code64
processor cpu64_v8
format binary as 'img'
include 'LIB\R_PI2.INC'
include 'LIB\V3D.INC'
include 'LIB\CONTROL_LIST.INC'

; Setup Frame Buffer
SCREEN_X       = 640
SCREEN_Y       = 480
BITS_PER_PIXEL = 32

org $0000

; Return CPU ID (0..3) Of The CPU Executed On
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
ands x0,x0,3 ; X0 = CPU ID (Bits 0..1)
b.ne CoreLoop ; IF (CPU ID != 0) Branch To Infinite Loop (Core ID 1..3)

; Run Tags To Initialize V3D
mov w0,MAIL_BASE
orr w0,w0,PERIPHERAL_BASE
mov w1,TAGS_STRUCT + MAIL_TAGS
str w1,[x0,MAIL_WRITE] ; Mail Box Write

FB_Init:
  mov w0,FB_STRUCT + MAIL_TAGS
  mov x1,MAIL_BASE
  orr x1,x1,PERIPHERAL_BASE
  str w0,[x1,MAIL_WRITE + MAIL_TAGS] ; Mail Box Write

  ldr w0,[FB_POINTER] ; W0 = Frame Buffer Pointer
  cbz w0,FB_Init ; IF (Frame Buffer Pointer == Zero) Re-Initialize Frame Buffer

  and w0,w0,$3FFFFFFF ; Convert Mail Box Frame Buffer Pointer From BUS Address To Physical Address ($CXXXXXXX -> $3XXXXXXX)
  adr x2,FB_POINTER
  str w0,[x2] ; Store Frame Buffer Pointer Physical Address

adr x1,TILE_MODE_ADDRESS + 1 ; Store Frame Buffer Pointer To Control List Tile Rendering Mode Configuration Memory Address
strb w0,[x1],1
lsr w0,w0,8
strb w0,[x1],1
lsr w0,w0,8
strb w0,[x1],1
lsr w0,w0,8
strb w0,[x1],1

; Run Rendering Control List (Thread 1)
mov w0,PERIPHERAL_BASE + V3D_BASE ; Load V3D Base Address
adr x1,CONTROL_LIST_RENDER_STRUCT ; Store Control List Executor Rendering Thread 1 Current Address
str w1,[x0,V3D_CT1CA]
adr x1,CONTROL_LIST_RENDER_END ; Store Control List Executor Rendering Thread 1 End Address
str w1,[x0,V3D_CT1EA] ; When End Address Is Stored Control List Thread Executes

Loop:
  b Loop

CoreLoop: ; Infinite Loop For Core 1..3
  b CoreLoop

align 16
FB_STRUCT: ; Mailbox Property Interface Buffer Structure
  dw FB_STRUCT_END - FB_STRUCT ; Buffer Size In Bytes (Including The Header Values, The End Tag And Padding)
  dw $00000000 ; Buffer Request/Response Code
	       ; Request Codes: $00000000 Process Request Response Codes: $80000000 Request Successful, $80000001 Partial Response
; Sequence Of Concatenated Tags
  dw Set_Physical_Display ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw SCREEN_X ; Value Buffer
  dw SCREEN_Y ; Value Buffer

  dw Set_Virtual_Buffer ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw SCREEN_X ; Value Buffer
  dw SCREEN_Y ; Value Buffer

  dw Set_Depth ; Tag Identifier
  dw $00000004 ; Value Buffer Size In Bytes
  dw $00000004 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw BITS_PER_PIXEL ; Value Buffer

  dw Set_Virtual_Offset ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
FB_OFFSET_X:
  dw 0 ; Value Buffer
FB_OFFSET_Y:
  dw 0 ; Value Buffer

  dw Allocate_Buffer ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
FB_POINTER:
  dw 0 ; Value Buffer
  dw 0 ; Value Buffer

dw $00000000 ; $0 (End Tag)
FB_STRUCT_END:

align 16
TAGS_STRUCT: ; Mailbox Property Interface Buffer Structure
  dw TAGS_END - TAGS_STRUCT ; Buffer Size In Bytes (Including The Header Values, The End Tag And Padding)
  dw $00000000 ; Buffer Request/Response Code
	       ; Request Codes: $00000000 Process Request Response Codes: $80000000 Request Successful, $80000001 Partial Response
; Sequence Of Concatenated Tags
  dw Set_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_V3D_ID ; Value Buffer (V3D Clock ID)
  dw 250*1000*1000 ; Value Buffer (250MHz)

  dw Enable_QPU ; Tag Identifier
  dw $00000004 ; Value Buffer Size In Bytes
  dw $00000004 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw 1 ; Value Buffer (1 = Enable)

dw $00000000 ; $0 (End Tag)
TAGS_END:

align 4
CONTROL_LIST_RENDER_STRUCT: ; Control List Of Concatenated Control Records & Data Structures (Rendering Mode Thread 1)
  Clear_Colors $FF0000FFFF00FFFF, 0, 0, 0 ; Clear Colors (R) (Clear Color (Red/Yellow), Clear ZS, Clear VGMask, Clear Stencil)

  TILE_MODE_ADDRESS:
    Tile_Rendering_Mode_Configuration $00000000, SCREEN_X, SCREEN_Y, Frame_Buffer_Color_Format_RGBA8888 ; Tile Rendering Mode Configuration (R) (Address, Width, Height, Data)

  Tile_Coordinates 0, 0 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Tile_Buffer_General 0, 0, 0 ; Store Tile Buffer General (R)

  ; Tile Row 0
  Tile_Coordinates 0, 0 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 1, 0 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 2, 0 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 3, 0 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 4, 0 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 5, 0 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 6, 0 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 7, 0 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 8, 0 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 9, 0 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  ; Tile Row 1
  Tile_Coordinates 0, 1 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 1, 1 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 2, 1 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 3, 1 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 4, 1 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 5, 1 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 6, 1 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 7, 1 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 8, 1 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 9, 1 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  ; Tile Row 2
  Tile_Coordinates 0, 2 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 1, 2 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 2, 2 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 3, 2 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 4, 2 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 5, 2 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 6, 2 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 7, 2 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 8, 2 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 9, 2 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  ; Tile Row 3
  Tile_Coordinates 0, 3 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 1, 3 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 2, 3 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 3, 3 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 4, 3 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 5, 3 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 6, 3 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 7, 3 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 8, 3 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 9, 3 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  ; Tile Row 4
  Tile_Coordinates 0, 4 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 1, 4 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 2, 4 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 3, 4 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 4, 4 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 5, 4 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 6, 4 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 7, 4 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 8, 4 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 9, 4 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  ; Tile Row 5
  Tile_Coordinates 0, 5 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 1, 5 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 2, 5 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 3, 5 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 4, 5 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 5, 5 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 6, 5 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 7, 5 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 8, 5 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 9, 5 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  ; Tile Row 6
  Tile_Coordinates 0, 6 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 1, 6 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 2, 6 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 3, 6 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 4, 6 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 5, 6 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 6, 6 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 7, 6 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 8, 6 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 9, 6 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  ; Tile Row 7
  Tile_Coordinates 0, 7 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 1, 7 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 2, 7 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 3, 7 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 4, 7 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 5, 7 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 6, 7 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 7, 7 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 8, 7 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)

  Tile_Coordinates 9, 7 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Multi_Sample_End ; Store Multi-Sample (Resolved Tile Color Buffer & Signal End Of Frame) (R)
CONTROL_LIST_RENDER_END: