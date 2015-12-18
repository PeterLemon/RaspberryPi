; Raspberry Pi 2 'Bare Metal' Hello World DMA Demo by krom (Peter Lemon):
; 1. Setup Frame Buffer
; 2. Copy Hello World Text Characters To Frame Buffer Using DMA 2D Mode & Stride

format binary as 'img'
include 'LIB\FASMARM.INC'
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
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
ands r0,3 ; R0 = CPU ID (Bits 0..1)
bne CoreLoop ; IF (CPU ID != 0) Branch To Infinite Loop (Core ID 1..3)

imm32 r0,PERIPHERAL_BASE + DMA_ENABLE ; Set DMA Channel 0 Enable Bit
mov r1,DMA_EN0
str r1,[r0]

FB_Init:
  imm32 r0,FB_STRUCT + MAIL_TAGS
  imm32 r1,PERIPHERAL_BASE + MAIL_BASE + MAIL_WRITE + MAIL_TAGS
  str r0,[r1] ; Mail Box Write

  ldr r0,[FB_POINTER] ; R0 = Frame Buffer Pointer
  cmp r0,0 ; Compare Frame Buffer Pointer To Zero
  beq FB_Init ; IF Zero Re-Initialize Frame Buffer

  and r0,$3FFFFFFF ; Convert Mail Box Frame Buffer Pointer From BUS Address To Physical Address ($CXXXXXXX -> $3XXXXXXX)
  str r0,[FB_POINTER] ; Store Frame Buffer Pointer Physical Address

; Draw Characters
imm32 r1,256 + (SCREEN_X * 32)
add r0,r1 ; Place Text At XY Position 256,32

adr r1,Font ; R1 = Characters
adr r2,Text ; R2 = Text Offset
adr r3,CB_STRUCT ; R3 = Control Block Data
imm32 r4,PERIPHERAL_BASE + DMA0_BASE ; R4 = DMA 0 Base
mov r5,DMA_ACTIVE ; R5 = DMA Active Bit
mov r6,12 ; R6 = Number Of Text Characters To Print
DrawChars:
  ldrb r7,[r2],1 ; R7 = Next Text Character
  add r7,r1,r7,lsl 6 ; Add Shift To Correct Position In Font (* 64)
  str r7,[CB_SOURCE] ; Store DMA Source Address
  str r0,[CB_DEST] ; Store DMA Destination Address
  str r3,[r4,DMA_CONBLK_AD] ; Store DMA Control Block Data Address

  str r5,[r4,DMA_CS] ; Print Next Text Character To Screen
  DMAWait:
    ldr r7,[r4,DMA_CS] ; Load Control Block Status
    tst r7,r5 ; Test Active Bit
    bne DMAWait ; Wait Until DMA Has Finished

  subs r6,1 ; Subtract Number Of Text Characters To Print
  addne r0,CHAR_X ; Jump Forward 1 Char
  bne DrawChars ; IF (Number Of Text Characters != 0) Continue To Print Characters

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