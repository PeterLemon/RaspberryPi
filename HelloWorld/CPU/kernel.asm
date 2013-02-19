; Raspberry Pi 'Bare Metal' Hello World Demo by krom (Peter Lemon):
; 1. Setup Frame Buffer
; 2. Copy Hello World Text Characters to Frame Buffer

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
  cmp r0,0 ; Compare Frame Buffer Pointer to Zero
  beq FB_Init ; IF Zero Re-Initialize Frame Buffer

; Draw Characters
add r0,((SCREEN_X * 32) * (BITS_PER_PIXEL / 8)) + (256 * (BITS_PER_PIXEL / 8)) ; Place text at XY Position 256,32
adr r1,Font ; R1 = Characters
adr r2,Text ; R2 = Text Offset
mov r3,12 ; R3 = Number of Text Characters to Print
DrawChars:
  mov r4,CHAR_X ; R4 = Character X Pixel Counter
  mov r5,CHAR_Y ; R5 = Character Y Pixel Counter

  ldrb r6,[r2],1 ; R6 = Next Text Character
  add r6,r1,r6,lsl 6 ; Add Shift to Correct Position in Font (* 64)

  DrawCharX:
    ldrb r7,[r6],1 ; Load Font Text Character Pixel
    strb r7,[r0],1 ; Store Font Text Character Pixel into Frame Buffer
    subs r4,1 ; Decrement Character X Pixel Counter
    bne DrawCharX ; IF Character X Pixel Counter != 0 GOTO DrawCharX

    add r0,SCREEN_X * (BITS_PER_PIXEL / 8) ; Jump down 1 Scanline
    sub r0,CHAR_X * (BITS_PER_PIXEL / 8) ; Jump back 1 Char
    mov r4,CHAR_X ; Reset Character X Pixel Counter
    subs r5,1 ; Decrement Character Y Pixel Counter
    bne DrawCharX ; IF Character Y Pixel Counter != 0 GOTO DrawCharX

  subs r3,1 ; Subtract Number of Text Characters to Print
  subne r0,(SCREEN_X * (BITS_PER_PIXEL / 8)) * CHAR_Y
  addne r0,CHAR_X * (BITS_PER_PIXEL / 8)
  bne DrawChars ; Continue to Print Characters

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

Text:
  db "Hello World!"

align 4
Font:
  include 'Font8x8.asm'