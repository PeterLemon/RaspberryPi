; Raspberry Pi 3 'Bare Metal' 8BPP Hello World Demo by krom (Peter Lemon):
; 1. Setup Frame Buffer
; 2. Copy Hello World Text Characters To Frame Buffer Using CPU

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
mov w3,12 ; W3 = Number Of Text Characters To Print
DrawChars:
  mov w4,CHAR_Y ; W4 = Character Row Counter
  ldrb x5,[x2],1 ; X5 = Next Text Character
  add x5,x1,x5,lsl 6 ; Add Shift To Correct Position In Font (* 64)

  DrawChar:
    ldr x6,[x5],8 ; Load Font Text Character Row
    str x6,[x0],8 ; Store Font Text Character Row To Frame Buffer
    add x0,x0,SCREEN_X - CHAR_X ; Jump Down 1 Scanline, Jump Back 1 Char
    subs w4,w4,1 ; Decrement Character Row Counter
    b.ne DrawChar ; IF (Character Row Counter != 0) DrawChar

  subs w3,w3,1 ; Subtract Number Of Text Characters To Print
  mov x4,(SCREEN_X * CHAR_Y) - CHAR_X
  sub x0,x0,x4 ; Jump To Top Of Char, Jump Forward 1 Char
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

Text:
  db "Hello World!"

align 8
Font:
  include 'Font8x8.asm'