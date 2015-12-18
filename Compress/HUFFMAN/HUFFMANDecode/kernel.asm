; Raspberry Pi 'Bare Metal' HUFFMAN Decode Demo by krom (Peter Lemon) & Andy Smith:
; 1. Decode HUFFMAN Chunks To Memory

format binary as 'img'
include 'LIB\FASMARM.INC'
include 'LIB\R_PI.INC'

org $0000

imm32 r0,Huff ; R0 = Source Address
imm32 r1,Dest ; R1 = Destination Address

ldr r2,[r0],4 ; R2 = Data Length & Header Info
lsr r2,8 ; R2 = Data Length
add r2,r1 ; R2 = Destination End Offset

ldrb r3,[r0],1 ; R0 = Tree Table, R3 = (Tree Table Size / 2) - 1
lsl r3,1
add r3,1 ; R3 = Tree Table Size
add r3,r0 ; R3 = Compressed Bitstream Offset

sub r0,5 ; R0 = Source Address
mov r8,0 ; R8 = Branch/Leaf Flag (0 = Branch 1 = Leaf)
mov r9,5 ; R9 = Tree Table Offset (Reset)
HuffChunkLoop:
  ldr r4,[r3],4 ; R4 = Node Bits (Bit31 = First Bit)
  mov r5,$80000000 ; R5 = Node Bit Shifter

  HuffByteLoop:
    cmp r1,r2 ; IF(Destination Address == Destination End Offset) HuffEnd
    beq HuffEnd

    cmp r5,0 ; IF(Node Bit Shifter == 0) HuffLoop
    beq HuffChunkLoop

    ldrb r6,[r0,r9] ; R6 = Next Node
    tst r8,1 ; Test R8 == Leaf
    strbne r6,[r1],1 ; Store Data Byte To Destination IF Leaf
    movne r8,0 ; R8 = Branch
    movne r9,5 ; R9 = Tree Table Offset (Reset)
    bne HuffByteLoop

    and r7,r6,$3F ; R7 = Offset To Next Child Node
    lsl r7,1
    add r7,2 ; R7 = Node0 Child Offset * 2 + 2
    and r9,$FFFFFFFE ; R9 = Tree Offset NOT 1
    add r9,r7 ; R9 = Node0 Child Offset

    tst r4,r5 ; Test Node Bit (0 = Node0, 1 = Node1)
    lsr r5,1 ; Shift R5 To Next Node Bit
    addne r9,1 ; R9 = Node1 Child Offset
    moveq r10,$80 ; r10 = Test Node0 End Flag
    movne r10,$40 ; r10 = Test Node1 End Flag
    tst r6,r10 ; Test Node End Flag (1 = Next Child Node Is Data)
    movne r8,1 ; R8 = Leaf
    b HuffByteLoop
  HuffEnd:

Loop:
  b Loop

align 4 ; Huffman File Aligned To 4 Bytes
Huff: file 'RaspiLogo24BPP.huff'

Dest: