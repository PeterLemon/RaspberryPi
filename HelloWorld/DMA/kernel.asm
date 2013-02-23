; Raspberry Pi 'Bare Metal' Hello World DMA Demo by krom (Peter Lemon):
; 1. Setup Frame Buffer
; 2. Copy Hello World Text Characters To Frame Buffer Using DMA 2D Mode & Stride

format binary as 'img'
include 'LIB\FASMARM.INC'
include 'LIB\R_PI.INC'

; Setup Frame Buffer
SCREEN_X       = 640
SCREEN_Y       = 480
BITS_PER_PIXEL = 8

; Setup Characters
CHAR_X = 8
CHAR_Y = 8

org BUS_ADDRESSES_l2CACHE_ENABLED + $8000

imm32 r0,PERIPHERAL_BASE + DMA_ENABLE ; Set DMA Channel 0 Enable Bit
mov r1,DMA_EN0
str r1,[r0]

FB_Init:
  imm32 r0,PERIPHERAL_BASE + MAIL_BASE
  imm32 r1,FB_STRUCT
  orr r1,MAIL_FB
  str r1,[r0,MAIL_WRITE + MAIL_FB] ; Mail Box Write

  FB_Read:
    ldr r1,[r0,MAIL_READ]
    tst r1,MAIL_FB ; Test Frame Buffer Channel 1
    beq FB_Read ; Wait For Frame Buffer Channel 1 Data

  imm32 r1,FB_POINTER
  ldr r0,[r1] ; R0 = Frame Buffer Pointer
  cmp r0,0 ; Compare Frame Buffer Pointer To Zero
  beq FB_Init ; IF Zero Re-Initialize Frame Buffer

; Draw Characters
imm32 r1,((SCREEN_X * 51) * (BITS_PER_PIXEL / 8)) + (259 * (BITS_PER_PIXEL / 8))
add r0,r1 ; Place Text At XY Position 259,51

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
  str r3,[r4,DMA0_CONBLK_AD] ; Store DMA Control Block Data Address

  str r5,[r4,DMA0_CS] ; Print Next Text Character To Screen
  DMAWait:
    ldr r8,[r4,DMA0_CS] ; Load Control Block Status
    tst r8,r5 ; Test Active bit
    bne DMAWait ; Wait Until DMA Has Finished

  subs r6,1 ; Subtract Number Of Text Characters To Print
  addne r0,CHAR_X ; Jump Forward 1 Char
  bne DrawChars ; Continue To Print Characters

Loop:
  b Loop

align 16
FB_STRUCT: ; Frame Buffer Structure
  dw SCREEN_X ; Frame Buffer Pixel Width
  dw SCREEN_Y ; Frame Buffer Pixel Height
  dw SCREEN_X ; Frame Buffer Virtual Pixel Width
  dw SCREEN_Y ; Frame Buffer Virtual Pixel Height
  dw 0 ; Frame Buffer Pitch (Set By GPU)
  dw BITS_PER_PIXEL ; Frame Buffer Bits Per Pixel
  dw 0 ; Frame Buffer Offset In X Direction
  dw 0 ; Frame Buffer Offset In Y Direction
FB_POINTER:
  dw 0 ; Frame Buffer Pointer (Set By GPU)
  dw 0 ; Frame Buffer Size (Set By GPU)
FB_PAL: ; Frame Buffer Palette
  dh $0000,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF
  dh $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF
  dh $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF
  dh $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF
  dh $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF
  dh $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF
  dh $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF
  dh $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF
  dh $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF
  dh $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF
  dh $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF
  dh $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF
  dh $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF
  dh $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF
  dh $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF
  dh $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF

align 256
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