; Raspberry Pi 3 'Bare Metal' LZ77 Decode Demo by krom (Peter Lemon):
; 1. Set Cores 1..3 To Infinite Loop
; 2. Decode LZ77 Chunks To Memory

code64
processor cpu64_v8
format binary as 'img'
include 'LIB\R_PI2.INC'

org $0000

; Return CPU ID (0..3) Of The CPU Executed On
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
ands x0,x0,3 ; X0 = CPU ID (Bits 0..1)
b.ne CoreLoop ; IF (CPU ID != 0) Branch To Infinite Loop (Core ID 1..3)

adr x0,LZ ; X0 = Source Address
adr x1,Dest ; X1 = Destination Address

ldr w2,[x0],4 ; W2 = Data Length & Header Info
lsr w2,w2,8 ; W2 = Data Length
add w2,w2,w1 ; W2 = Destination End Offset

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

Loop:
  b Loop

CoreLoop: ; Infinite Loop For Core 1..3
  b CoreLoop

align 4 ; LZ77 File Aligned To 4 Bytes
LZ: file 'RaspiLogo24BPP.lz'

Dest: