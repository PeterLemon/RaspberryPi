; Raspberry Pi 3 'Bare Metal' HUFFMAN GFX Demo by krom (Peter Lemon) & Andy Smith:
; 1. Setup Frame Buffer
; 2. Decode HUFFMAN Chunks To Memory

code64
processor cpu64_v8
format binary as 'img'
include 'LIB\R_PI2.INC'

; Setup Frame Buffer
SCREEN_X       = 640
SCREEN_Y       = 480
BITS_PER_PIXEL = 24

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

  ldr w1,[FB_POINTER] ; W1 = Frame Buffer Pointer
  cbz w1,FB_Init ; IF (Frame Buffer Pointer == Zero) Re-Initialize Frame Buffer

  and w1,w1,$3FFFFFFF ; Convert Mail Box Frame Buffer Pointer From BUS Address To Physical Address ($CXXXXXXX -> $3XXXXXXX)
  adr x0,FB_POINTER
  str w1,[x0] ; Store Frame Buffer Pointer Physical Address

adr x0,Huff ; X0 = Source Address, X1 = Destination Address

ldr w2,[x0],4 ; W2 = Data Length & Header Info
lsr w2,w2,8 ; W2 = Data Length
add w2,w2,w1 ; W2 = Destination End Offset

ldrb w3,[x0],1 ; X0 = Tree Table, W3 = (Tree Table Size / 2) - 1
lsl w3,w3,1
add w3,w3,1 ; W3 = Tree Table Size
add w3,w3,w0 ; W3 = Compressed Bitstream Offset

sub x0,x0,5 ; X0 = Source Address
mov w8,0 ; W8 = Branch/Leaf Flag (0 = Branch 1 = Leaf)
mov w9,5 ; W9 = Tree Table Offset (Reset)
HuffChunkLoop:
  ldr w4,[x3],4 ; W4 = Node Bits (Bit31 = First Bit)
  mov w5,$80000000 ; W5 = Node Bit Shifter

  HuffByteLoop:
    cmp w1,w2 ; IF (Destination Address == Destination End Offset) HuffEnd
    b.eq HuffEnd

    cbz w5,HuffChunkLoop ; IF (Node Bit Shifter == 0) Huff Chunk Loop

    ldrb w6,[x0,x9] ; W6 = Next Node
    tst w8,1 ; Test W8 == Leaf
    b.eq HuffChild
    strb w6,[x1],1 ; Store Data Byte To Destination IF Leaf
    mov w8,0 ; W8 = Branch
    mov w9,5 ; W9 = Tree Table Offset (Reset)
    b HuffByteLoop

    HuffChild:
      and w7,w6,$3F ; W7 = Offset To Next Child Node
      lsl w7,w7,1
      add w7,w7,2 ; W7 = Node0 Child Offset * 2 + 2
      and w9,w9,$FFFFFFFE ; W9 = Tree Offset NOT 1
      add w9,w9,w7 ; W9 = Node0 Child Offset

      tst w4,w5 ; Test Node Bit (0 = Node0, 1 = Node1)
      lsr w5,w5,1 ; Shift W5 To Next Node Bit
      b.eq HuffNode0
      add w9,w9,1 ; W9 = Node1 Child Offset
      mov w10,$40 ; W10 = Test Node1 End Flag
      b HuffNodeEnd
      HuffNode0:
	mov w10,$80 ; W10 = Test Node0 End Flag

      HuffNodeEnd:
	tst w6,w10 ; Test Node End Flag (1 = Next Child Node Is Data)
	b.eq HuffByteLoop
	mov w8,1 ; W8 = Leaf
	b HuffByteLoop
  HuffEnd:

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

  dw Allocate_Buffer ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
FB_POINTER:
  dw 0 ; Value Buffer
  dw 0 ; Value Buffer

dw $00000000 ; $0 (End Tag)
FB_STRUCT_END:

align 4 ; Huffman File Aligned To 4 Bytes
Huff: file 'RaspiLogo24BPP.huff'