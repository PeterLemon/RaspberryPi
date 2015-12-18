; Raspberry Pi 'Bare Metal' 320x240 GRB LZ Video Decode Demo by krom (Peter Lemon):

format binary as 'img'
include 'LIB\FASMARM.INC'
include 'LIB\R_PI.INC'

; Setup Frame Buffer
SCREEN_X       = 320
SCREEN_Y       = 240
BITS_PER_PIXEL = 24

org $0000

; Start L1 Cache
mrc p15,0,r0,c1,c0,0 ; R0 = System Control Register
orr r0,$0004 ; Data Cache (Bit 2)
orr r0,$0800 ; Branch Prediction (Bit 11)
orr r0,$1000 ; Instruction Caches (Bit 12)
mcr p15,0,r0,c1,c0,0 ; System Control Register = R0

FB_Init:
  imm32 r0,FB_STRUCT + MAIL_TAGS
  imm32 r1,PERIPHERAL_BASE + MAIL_BASE + MAIL_WRITE + MAIL_TAGS
  str r0,[r1] ; Mail Box Write

  ldr r13,[FB_POINTER] ; R13 = Frame Buffer Pointer
  cmp r13,0 ; Compare Frame Buffer Pointer To Zero
  beq FB_Init ; IF Zero Re-Initialize Frame Buffer

  and r13,$3FFFFFFF ; Convert Mail Box Frame Buffer Pointer From BUS Address To Physical Address ($CXXXXXXX -> $3XXXXXXX)
  str r13,[FB_POINTER] ; Store Frame Buffer Pointer Physical Address

LoopVideo:
  imm32 r0,LZVideo ; R0 = Source Address
  imm32 r12,615 ; R12 = Frame Count
LoopFrames:
  add r0,4 ; LZ Offset += 4
  imm32 r1,GRB ; R1 = Destination Address
  imm32 r2,GRB + 100800 ; R2 = Destination End Offset
  LZLoop:
    ldrb r3,[r0],1 ; R3 = Flag Data For Next 8 Blocks (0 = Uncompressed Byte, 1 = Compressed Bytes)
    mov r4,10000000b ; R4 = Flag Data Block Type Shifter
    LZBlockLoop:
      cmp r1,r2 ; IF (Destination Address == Destination End Offset) LZEnd
      beq LZEnd
      cmp r4,0 ; IF (Flag Data Block Type Shifter == 0) LZLoop
      beq LZLoop
      tst r3,r4 ; Test Block Type
      lsr r4,1 ; Shift R4 To Next Flag Data Block Type
      bne LZDecode ; IF (BlockType != 0) LZDecode Bytes
      ldrb r5,[r0],1 ; ELSE Copy Uncompressed Byte
      strb r5,[r1],1 ; Store Uncompressed Byte To Destination
      b LZBlockLoop

      LZDecode:
	ldrb r5,[r0],1 ; R5 = Number Of Bytes To Copy & Disp MSB's
	ldrb r6,[r0],1 ; R6 = Disp LSB's
	add r6,r5,lsl 8
	lsr r5,4 ; R5 = Number Of Bytes To Copy (Minus 3)
	add r5,3 ; R5 = Number Of Bytes To Copy
	mov r7,$1000
	sub r7,1 ; R7 = $FFF
	and r6,r7 ; R6 = Disp
	add r6,1 ; R6 = Disp + 1
	rsb r6,r1 ; R6 = Destination - Disp - 1
	LZCopy:
	  ldrb r7,[r6],1 ; R7 = Byte To Copy
	  strb r7,[r1],1 ; Store Byte To RAM
	  subs r5,1 ; Number Of Bytes To Copy -= 1
	  bne LZCopy ; IF (Number Of Bytes To Copy != 0) LZCopy Bytes
	  b LZBlockLoop
   LZEnd:

   ; Skip Zero's At End Of LZ77 Compressed File
   ands r1,r0,3 ; Compare LZ77 Offset To A Multiple Of 4
   subne r0,r1 ; IF (LZ77 Offset != Multiple Of 4) Add R1 To the LZ77 Offset
   addne r0,4 ; LZ77 Offset += 4

decodeGRB:
  mov r7,r13
  imm32 r1,GRB ; G Offset
  add r2,r1,SCREEN_X * SCREEN_Y ; R Offset
  add r3,r2,SCREEN_X * SCREEN_Y / 4 ; B Offset

  add r4,r7,1
  LoopG: ; Loop Green Pixels (1:1)
    ldrb r5,[r1],1 ; Load G Byte
    strb r5,[r4],3 ; Store G Byte
    cmp r1,r2 ; IF (G Offset != R Offset) Loop G
    bne LoopG

  mov r4,r7
  mov r6,SCREEN_X / 2
  LoopR: ; Loop Red Pixels (1:4)
    ldrb r5,[r2],1 ; Load R Byte
    strb r5,[r4],3 ; Store Pixel 1,1
    strb r5,[r4],-3 ; Store Pixel 1,2
    add r4,SCREEN_X * 3
    strb r5,[r4],3 ; Store Pixel 2,1
    strb r5,[r4],3 ; Store Pixel 2,2
    sub r4,SCREEN_X * 3

    subs r6,1
    moveq r6,SCREEN_X / 2
    addeq r4,SCREEN_X * 3

    cmp r2,r3 ; IF (R Offset != R Offset) Loop R
    bne LoopR

  add r1,r3,SCREEN_X * SCREEN_Y / 16 ; B End Offset
  add r4,r7,2
  mov r6,SCREEN_X / 4
  LoopB: ; Loop Blue Pixels (1:16)
    ldrb r5,[r3],1 ; Load B Byte
    strb r5,[r4],3 ; Store Pixel 1,1
    strb r5,[r4],3 ; Store Pixel 1,2
    strb r5,[r4],3 ; Store Pixel 1,3
    strb r5,[r4],-9 ; Store Pixel 1,4
    add r4,SCREEN_X * 3
    strb r5,[r4],3 ; Store Pixel 2,1
    strb r5,[r4],3 ; Store Pixel 2,2
    strb r5,[r4],3 ; Store Pixel 2,3
    strb r5,[r4],-9 ; Store Pixel 2,4
    add r4,SCREEN_X * 3
    strb r5,[r4],3 ; Store Pixel 3,1
    strb r5,[r4],3 ; Store Pixel 3,2
    strb r5,[r4],3 ; Store Pixel 3,3
    strb r5,[r4],-9 ; Store Pixel 3,4
    add r4,SCREEN_X * 3
    strb r5,[r4],3 ; Store Pixel 4,1
    strb r5,[r4],3 ; Store Pixel 4,2
    strb r5,[r4],3 ; Store Pixel 4,3
    strb r5,[r4],3 ; Store Pixel 4,4
    sub r4,SCREEN_X * 9

    subs r6,1
    moveq r6,SCREEN_X / 4
    addeq r4,SCREEN_X * 9

    cmp r3,r1 ; IF (B Offset != B End Offset) Loop B
    bne LoopB

subs r12,1 ; Frame Count --
bne LoopFrames
b LoopVideo

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

LZVideo: file 'Video.lz'
GRB: