; Raspberry Pi 'Bare Metal' LZ77 GFX Demo by krom (Peter Lemon):
; 1. Setup Frame Buffer
; 2. Decode LZ77 Chunks To Video Memory

format binary as 'img'
include 'LIB\FASMARM.INC'
include 'LIB\R_PI.INC'

; Setup Frame Buffer
SCREEN_X       = 640
SCREEN_Y       = 480
BITS_PER_PIXEL = 24

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

  imm32 r0,FB_POINTER
  ldr r1,[r0] ; R1 = Frame Buffer Pointer
  cmp r1,0 ; Compare Frame Buffer Pointer To Zero
  beq FB_Init ; IF Zero Re-Initialize Frame Buffer

imm32 r0,LZ ; R0 = Source Address, R1 = Destination Address

ldr r2,[r0],4 ; R2 = Data Length & Header Info
mov r2,r2,lsr 8 ; R2 = Data Length
add r2,r1 ; R2 = Destination End Offset

LZLoop:
  ldrb r3,[r0],1 ; R3 = Flag Data For Next 8 Blocks (0 = Uncompressed Byte, 1 = Compressed Bytes)
  mov r4,10000000b ; R4 = Flag Data Block Type Shifter
  LZBlockLoop:
    cmp r1,r2 ; IF(Destination Address == Destination End Offset) LZEnd
    beq LZEnd
    cmp r4,0 ; IF(Flag Data Block Type Shifter == 0) LZLoop
    beq LZLoop
    tst r3,r4 ; Test Block Type
    mov r4,r4,lsr 1 ; Shift R4 To Next Flag Data Block Type
    bne LZDecode ; IF(BlockType != 0) LZDecode Bytes
    ldrb r5,[r0],1 ; ELSE Copy Uncompressed Byte
    strb r5,[r1],1 ; Store Uncompressed Byte To Destination
    b LZBlockLoop

    LZDecode:
	ldrb r5,[r0],1 ; R5 = Number Of Bytes To Copy & Disp MSB's
	ldrb r6,[r0],1 ; R6 = Disp LSB's
	add r6,r5,lsl 8
	mov r5,r5,lsr 4 ; R5 = Number Of Bytes To Copy (Minus 3)
	add r5,3 ; R5 = Number Of Bytes To Copy
	mov r7,$1000
	sub r7,1 ; R7 = $FFF
	and r6,r7 ; R6 = Disp
	add r6,r6,1 ; R6 = Disp + 1
	sub r6,r1,r6 ; R6 = Destination - Disp - 1
	LZCopy:
	  ldrb r7,[r6],1
	  strb r7,[r1],1
	  subs r5,1
	  bne LZCopy
	  b LZBlockLoop
  LZEnd:

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

align 4 ; LZ77 File Aligned To 4 Bytes
LZ: file 'RaspiLogo24BPP.lz'