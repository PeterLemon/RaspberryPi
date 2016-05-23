; Raspberry Pi 3 'Bare Metal' Hello World DMA Demo by krom (Peter Lemon):
; 1. Set Cores 1..3 To Infinite Loop
; 2. Setup Frame Buffer
; 3. Copy Hello World Text Characters To Frame Buffer Using DMA 2D Mode & Stride

code64
processor cpu64_v8
format binary as 'img'
include 'LIB\R_PI2.INC'

; Setup Frame Buffer
SCREEN_X       = 640
SCREEN_Y       = 480
BITS_PER_PIXEL = 8

; Setup Characters
CHAR_X = 8
CHAR_Y = 8

org $0000

; Return CPU ID (0..3) Of The CPU Executed On
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
ands x0,x0,3 ; X0 = CPU ID (Bits 0..1)
b.ne CoreLoop ; IF (CPU ID != 0) Branch To Infinite Loop (Core ID 1..3)

mov x0,PERIPHERAL_BASE
orr x0,x0,DMA_ENABLE
mov w1,DMA_EN0 ; Set DMA Channel 0 Enable Bit
str w1,[x0]

FB_Init:
  mov w0,FB_STRUCT + MAIL_TAGS
  mov x1,MAIL_BASE
  orr x1,x1,PERIPHERAL_BASE
  str w0,[x1,MAIL_WRITE + MAIL_TAGS] ; Mail Box Write

  ldr w0,[FB_POINTER] ; W0 = Frame Buffer Pointer
  cbz w0,FB_Init ; IF (Frame Buffer Pointer == Zero) Re-Initialize Frame Buffer

  and w0,w0,$3FFFFFFF ; Convert Mail Box Frame Buffer Pointer From BUS Address To Physical Address ($CXXXXXXX -> $3XXXXXXX)
  adr x1,FB_POINTER
  str w0,[x1] ; Store Frame Buffer Pointer Physical Address

; Draw Characters
mov w1,256 + (SCREEN_X * 32)
add w0,w0,w1 ; Place Text At XY Position 256,32

adr x1,Font ; X1 = Characters
adr x2,Text ; X2 = Text Offset
adr x3,CB_STRUCT ; X3 = Control Block Data
mov x4,PERIPHERAL_BASE
orr x4,x4,DMA0_BASE ; X4 = DMA 0 Base
mov w5,DMA_ACTIVE ; W5 = DMA Active Bit
mov w6,12 ; W6 = Number Of Text Characters To Print
DrawChars:
  ldrb w7,[x2],1 ; W7 = Next Text Character
  add w7,w1,w7,lsl 6 ; Add Shift To Correct Position In Font (* 64)
  adr x8,CB_SOURCE
  str w7,[x8] ; Store DMA Source Address
  adr x8,CB_DEST
  str w0,[x8] ; Store DMA Destination Address
  str w3,[x4,DMA_CONBLK_AD] ; Store DMA Control Block Data Address

  str w5,[x4,DMA_CS] ; Print Next Text Character To Screen
  DMAWait:
    ldr w7,[x4,DMA_CS] ; Load Control Block Status
    tst w7,w5 ; Test Active Bit
    b.ne DMAWait ; Wait Until DMA Has Finished

  subs w6,w6,1 ; Subtract Number Of Text Characters To Print
  add w0,w0,CHAR_X ; Jump Forward 1 Char
  b.ne DrawChars ; IF (Number Of Text Characters != 0) Continue To Print Characters

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

  dw Set_Palette ; Tag Identifier
  dw $00000010 ; Value Buffer Size In Bytes
  dw $00000010 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw 0 ; Value Buffer (Offset: First Palette Index To Set (0-255))
  dw 2 ; Value Buffer (Length: Number Of Palette Entries To Set (1-256))
FB_PAL:
  dw $00000000,$FFFFFFFF ; RGBA Palette Values (Offset To Offset+Length-1)

  dw Allocate_Buffer ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
FB_POINTER:
  dw 0 ; Value Buffer
  dw 0 ; Value Buffer

dw $00000000 ; $0 (End Tag)
FB_STRUCT_END:

align 32
CB_STRUCT: ; Control Block Data Structure
  dw DMA_TDMODE + DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
CB_SOURCE:
  dw 0 ; DMA Source Address
CB_DEST:
  dw 0 ; DMA Destination Address
  dw CHAR_X + ((CHAR_Y - 1) * 65536) ; DMA Transfer Length
  dw (SCREEN_X - CHAR_X) * 65536 ; DMA 2D Mode Stride
  dw 0 ; DMA Next Control Block Address

Text:
  db "Hello World!"

align 4
Font:
  include 'Font8x8.asm'