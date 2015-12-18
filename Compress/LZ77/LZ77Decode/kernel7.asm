; Raspberry Pi 2 'Bare Metal' LZ77 Decode Demo by krom (Peter Lemon):
; 1. Decode LZ77 Chunks To Memory

format binary as 'img'
include 'LIB\FASMARM.INC'
include 'LIB\R_PI2.INC'

org $0000

; Return CPU ID (0..3) Of The CPU Executed On
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
ands r0,3 ; R0 = CPU ID (Bits 0..1)
bne CoreLoop ; IF (CPU ID != 0) Branch To Infinite Loop (Core ID 1..3)

imm32 r0,LZ ; R0 = Source Address
imm32 r1,Dest ; R1 = Destination Address

ldr r2,[r0],4 ; R2 = Data Length & Header Info
lsr r2,8 ; R2 = Data Length
add r2,r1 ; R2 = Destination End Offset

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

Loop:
  b Loop

CoreLoop: ; Infinite Loop For Core 1..3
  b CoreLoop

align 4 ; LZ77 File Aligned To 4 Bytes
LZ: file 'RaspiLogo24BPP.lz'

Dest: