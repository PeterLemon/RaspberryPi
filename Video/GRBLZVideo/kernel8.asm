; Raspberry Pi 3 'Bare Metal' 320x240 GRB LZ Video Decode Demo by krom (Peter Lemon):

code64
processor cpu64_v8
format binary as 'img'
include 'LIB\R_PI2.INC'

; Setup Frame Buffer
SCREEN_X       = 320
SCREEN_Y       = 240
BITS_PER_PIXEL = 24

org $0000

; Return CPU ID (0..3) Of The CPU Executed On
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
ands x0,x0,3 ; X0 = CPU ID (Bits 0..1)
b.ne CoreLoop ; IF (CPU ID != 0) Branch To Infinite Loop (Core ID 1..3)

; Start L1 Cache
mrs x0,SCTLR_EL3 ; X0 = System Control Register
orr x0,x0,$0004 ; Data Cache (Bit 2)
orr x0,x0,$0800 ; Branch Prediction (Bit 11)
orr x0,x0,$1000 ; Instruction Caches (Bit 12)
msr SCTLR_EL3,x0 ; System Control Register = X0

FB_Init:
  mov w0,FB_STRUCT + MAIL_TAGS
  mov x1,MAIL_BASE
  orr x1,x1,PERIPHERAL_BASE
  str w0,[x1,MAIL_WRITE + MAIL_TAGS] ; Mail Box Write

  ldr w13,[FB_POINTER] ; W13 = Frame Buffer Pointer
  cbz w13,FB_Init ; IF (Frame Buffer Pointer == Zero) Re-Initialize Frame Buffer

  and w13,w13,$3FFFFFFF ; Convert Mail Box Frame Buffer Pointer From BUS Address To Physical Address ($CXXXXXXX -> $3XXXXXXX)
  adr x0,FB_POINTER
  str w13,[x0] ; Store Frame Buffer Pointer Physical Address

LoopVideo:
  adr x0,LZVideo ; X0 = Source Address
  mov w12,615 ; W12 = Frame Count
LoopFrames:
  add w0,w0,4 ; LZ Offset += 4
  adr x1,GRB ; X1 = Destination Address
  adr x2,GRB + 100800 ; X2 = Destination End Offset
  LZLoop:
    ldrb w3,[x0],1 ; W3 = Flag Data For Next 8 Blocks (0 = Uncompressed Byte, 1 = Compressed Bytes)
    mov w4,10000000b ; W4 = Flag Data Block Type Shifter
    LZBlockLoop:
      cmp w1,w2 ; IF (Destination Address == Destination End Offset) LZEnd
      b.eq LZEnd
      cbz w4,LZLoop ; IF (Flag Data Block Type Shifter == 0) LZLoop
      tst w3,w4 ; Test Block Type
      lsr w4,w4,1 ; Shift W4 To Next Flag Data Block Type
      b.ne LZDecode ; IF (BlockType != 0) LZDecode Bytes
      ldrb w5,[x0],1 ; ELSE Copy Uncompressed Byte
      strb w5,[x1],1 ; Store Uncompressed Byte To Destination
      b LZBlockLoop

      LZDecode:
	ldrb w5,[x0],1 ; W5 = Number Of Bytes To Copy & Disp MSB's
	ldrb w6,[x0],1 ; W6 = Disp LSB's
	add w6,w6,w5,lsl 8
	lsr w5,w5,4 ; W5 = Number Of Bytes To Copy (Minus 3)
	add w5,w5,3 ; W5 = Number Of Bytes To Copy
	and w6,w6,$FFF ; W6 = Disp
	add w6,w6,1 ; W6 = Disp + 1
	sub w6,w1,w6 ; W6 = Destination - Disp - 1
	LZCopy:
	  ldrb w7,[x6],1 ; W7 = Byte To Copy
	  strb w7,[x1],1 ; Store Byte To RAM
	  subs w5,w5,1 ; Number Of Bytes To Copy -= 1
	  b.ne LZCopy ; IF (Number Of Bytes To Copy != 0) LZCopy Bytes
	  b LZBlockLoop
    LZEnd:

    ; Skip Zero's At End Of LZ77 Compressed File
    ands w1,w0,3 ; Compare LZ77 Offset To A Multiple Of 4
    b.eq LZEOF
    sub w0,w0,w1 ; IF (LZ77 Offset != Multiple Of 4) Add R1 To the LZ77 Offset
    add w0,w0,4 ; LZ77 Offset += 4
    LZEOF:

decodeGRB:
  mov w7,w13
  adr x1,GRB ; G Offset
  adr x2,GRB + (SCREEN_X * SCREEN_Y) ; R Offset
  adr x3,GRB + (SCREEN_X * SCREEN_Y) + (SCREEN_X * SCREEN_Y / 4) ; B Offset

  add w4,w7,1
  LoopG: ; Loop Green Pixels (1:1)
    ldrb w5,[x1],1 ; Load G Byte
    strb w5,[x4],3 ; Store G Byte
    cmp w1,w2 ; IF (G Offset != R Offset) Loop G
    b.ne LoopG

  mov w4,w7
  mov w6,SCREEN_X / 2
  LoopR: ; Loop Red Pixels (1:4)
    ldrb w5,[x2],1 ; Load R Byte
    strb w5,[x4],3 ; Store Pixel 1,1
    strb w5,[x4],-3 ; Store Pixel 1,2
    add w4,w4,SCREEN_X * 3
    strb w5,[x4],3 ; Store Pixel 2,1
    strb w5,[x4],3 ; Store Pixel 2,2
    sub w4,w4,SCREEN_X * 3

    subs w6,w6,1
    b.ne REnd
    mov w6,SCREEN_X / 2
    add w4,w4,SCREEN_X * 3
    REnd:

    cmp w2,w3 ; IF (R Offset != R Offset) Loop R
    b.ne LoopR

  adr x1,GRB + (SCREEN_X * SCREEN_Y) + (SCREEN_X * SCREEN_Y / 4) + (SCREEN_X * SCREEN_Y / 16) ; B End Offset
  add w4,w7,2
  mov w6,SCREEN_X / 4
  LoopB: ; Loop Blue Pixels (1:16)
    ldrb w5,[x3],1 ; Load B Byte
    strb w5,[x4],3 ; Store Pixel 1,1
    strb w5,[x4],3 ; Store Pixel 1,2
    strb w5,[x4],3 ; Store Pixel 1,3
    strb w5,[x4],-9 ; Store Pixel 1,4
    add w4,w4,SCREEN_X * 3
    strb w5,[x4],3 ; Store Pixel 2,1
    strb w5,[x4],3 ; Store Pixel 2,2
    strb w5,[x4],3 ; Store Pixel 2,3
    strb w5,[x4],-9 ; Store Pixel 2,4
    add w4,w4,SCREEN_X * 3
    strb w5,[x4],3 ; Store Pixel 3,1
    strb w5,[x4],3 ; Store Pixel 3,2
    strb w5,[x4],3 ; Store Pixel 3,3
    strb w5,[x4],-9 ; Store Pixel 3,4
    add w4,w4,SCREEN_X * 3
    strb w5,[x4],3 ; Store Pixel 4,1
    strb w5,[x4],3 ; Store Pixel 4,2
    strb w5,[x4],3 ; Store Pixel 4,3
    strb w5,[x4],3 ; Store Pixel 4,4
    sub w4,w4,SCREEN_X * 9

    subs w6,w6,1
    b.ne BEnd
    mov w6,SCREEN_X / 4
    add w4,w4,SCREEN_X * 9
    BEnd:

    cmp w3,w1 ; IF (B Offset != B End Offset) Loop B
    b.ne LoopB

subs w12,w12,1 ; Frame Count --
b.ne LoopFrames
b LoopVideo

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

GRB:
db 100800 dup 0 ; Fill with 100800 Zero Bytes

LZVideo: file 'Video.lz'