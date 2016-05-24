; Raspberry Pi 3 'Bare Metal' V3D Initialize Demo by krom (Peter Lemon):
; 1. Set Cores 1..3 To Infinite Loop
; 2. Run Tags & Set V3D Frequency To 250MHz, & Enable Quad Processing Unit
; 3. Setup Frame Buffer
; 4. Copy V3D Readable Register Values To Frame Buffer Using CPU

macro PrintText Text, TextLength {
  local .DrawChars,.DrawChar
  adr x1,Font ; X1 = Characters
  adr x2,Text ; X2 = Text Offset
  mov w3,TextLength ; W3 = Number Of Text Characters To Print
  .DrawChars:
    mov w4,CHAR_Y ; W4 = Character Row Counter
    ldrb x5,[x2],1 ; X5 = Next Text Character
    add x5,x1,x5,lsl 6 ; Add Shift To Correct Position In Font (* 64)

    .DrawChar:
      ldr x6,[x5],8 ; Load Font Text Character Row
      str x6,[x0],8 ; Store Font Text Character Row To Frame Buffer
      add x0,x0,SCREEN_X - CHAR_X ; Jump Down 1 Scanline, Jump Back 1 Char
      subs w4,w4,1 ; Decrement Character Row Counter
      b.ne .DrawChar ; IF (Character Row Counter != 0) DrawChar

    subs w3,w3,1 ; Subtract Number Of Text Characters To Print
    mov x4,(SCREEN_X * CHAR_Y) - CHAR_X
    sub x0,x0,x4 ; Jump To Top Of Char, Jump Forward 1 Char
    b.ne .DrawChars ; IF (Number Of Text Characters != 0) Continue To Print Characters
}

macro PrintValueLE Value, ValueLength {
  local .DrawHEXChars,.DrawHexNum,.DrawHexNumB,.DrawHEXChar,.DrawHEXCharB
  adr x1,Font ; X1 = Characters
  adr x2,Value ; X2 = Text Offset
  add x2,x2,ValueLength - 1
  mov w3,ValueLength ; W3 = Number Of HEX Characters To Print
  .DrawHEXChars:
    ldrb w4,[x2],-1 ; W4 = Next 2 HEX Characters
    lsr w5,w4,4 ; Get 2nd Nibble
    cmp w5,$9
    add w5,w5,$30
    b.le .DrawHexNum
    add w5,w5,$7
  .DrawHexNum:
    add x5,x1,x5,lsl 6 ; Add Shift To Correct Position In Font (* 64)
    mov w6,CHAR_Y ; W6 = Character Row Counter
    .DrawHEXChar:
      ldr x7,[x5],8 ; Load Font Text Character Row
      str x7,[x0],8 ; Store Font Text Character Row To Frame Buffer
      add x0,x0,SCREEN_X - CHAR_X ; Jump Down 1 Scanline, Jump Back 1 Char
      subs w6,w6,1 ; Decrement Character Row Counter
      b.ne .DrawHEXChar ; IF (Character Row Counter != 0) DrawChar

    mov x5,(SCREEN_X * CHAR_Y) - CHAR_X
    sub x0,x0,x5 ; Jump To Top Of Char, Jump Forward 1 Char

    and w5,w4,$F ; Get 1st Nibble
    cmp w5,$9
    add w5,w5,$30
    b.le .DrawHexNumB
    add w5,w5,$7
  .DrawHexNumB:
    add x5,x1,x5,lsl 6 ; Add Shift To Correct Position In Font (* 64)
    mov w6,CHAR_Y ; W6 = Character Row Counter
    .DrawHEXCharB:
      ldr x7,[x5],8 ; Load Font Text Character Row
      str x7,[x0],8 ; Store Font Text Character Row To Frame Buffer
      add x0,x0,SCREEN_X - CHAR_X ; Jump Down 1 Scanline, Jump Back 1 Char
      subs w6,w6,1 ; Decrement Character Row Counter
      b.ne .DrawHEXCharB ; IF (Character Row Counter != 0) DrawChar

    subs w3,w3,1 ; Subtract Number Of HEX Characters To Print
    mov x4,(SCREEN_X * CHAR_Y) - CHAR_X
    sub x0,x0,x4 ; Jump To Top Of Char, Jump Forward 1 Char
    b.ne .DrawHEXChars ; IF (Number Of Hex Characters != 0) Continue To Print Characters
}

code64
processor cpu64_v8
format binary as 'img'
include 'LIB\R_PI2.INC'
include 'LIB\V3D.INC'

; Setup Frame Buffer
SCREEN_X       = 640
SCREEN_Y       = 480
BITS_PER_PIXEL = 8

; Setup Characters
CHAR_X = 8
CHAR_Y = 8

org $0000

; Return CPU ID (0..3) Of The CPU Executed On
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
ands x0,x0,3 ; X0 = CPU ID (Bits 0..1)
b.ne CoreLoop ; IF (CPU ID != 0) Branch To Infinite Loop (Core ID 1..3)

; Run Tags To Initialize V3D
mov w0,MAIL_BASE
orr w0,w0,PERIPHERAL_BASE
mov w1,TAGS_STRUCT + MAIL_TAGS
str w1,[x0,MAIL_WRITE] ; Mail Box Write

FB_Init:
  mov w0,FB_STRUCT + MAIL_TAGS
  mov x1,MAIL_BASE
  orr x1,x1,PERIPHERAL_BASE
  str w0,[x1,MAIL_WRITE + MAIL_TAGS] ; Mail Box Write

  ldr w10,[FB_POINTER] ; W10 = Frame Buffer Pointer
  cbz w10,FB_Init ; IF (Frame Buffer Pointer == Zero) Re-Initialize Frame Buffer

  and w10,w10,$3FFFFFFF ; Convert Mail Box Frame Buffer Pointer From BUS Address To Physical Address ($CXXXXXXX -> $3XXXXXXX)
  adr x0,FB_POINTER
  str w10,[x0] ; Store Frame Buffer Pointer Physical Address

mov w1,0 + (SCREEN_X * 8)
add w0,w10,w1 ; Place Text At XY Position 0,8
PrintText VCText, 12

; V3D_IDENT0
mov w1,8 + (SCREEN_X * 16)
add w0,w10,w1 ; Place Text At XY Position 8,16
PrintText IDENT0Text, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_IDENT0]
str w3,[x2]
PrintValueLE TextMEM, 4
PrintText IDSTRText, 8
PrintText TextMEM, 3

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_IDENT0]
lsr w3,w3,24
str w3,[x2]
PrintText TVERText, 7
PrintValueLE TextMEM, 1

; V3D_IDENT1
mov w1,8 + (SCREEN_X * 24)
add w0,w10,w1 ; Place Text At XY Position 8,24
PrintText IDENT1Text, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_IDENT1]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_IDENT1]
and w3,w3,REVR
str w3,[x2]
PrintText REVText, 5
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_IDENT1]
and w3,w3,NSLC
lsr w3,w3,4
str w3,[x2]
PrintText NSLCText, 6
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_IDENT1]
and w3,w3,QUPS
lsr w3,w3,8
str w3,[x2]
PrintText QUPSText, 6
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_IDENT1]
and w3,w3,TUPS
lsr w3,w3,12
str w3,[x2]
PrintText TUPSText, 6
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_IDENT1]
and w3,w3,NSEM
lsr w3,w3,16
str w3,[x2]
PrintText NSEMText, 6
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_IDENT1]
and w3,w3,HDRT
lsr w3,w3,24
str w3,[x2]
PrintText HDRTText, 6
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_IDENT1]
and w3,w3,VPMSZ
lsr w3,w3,28
str w3,[x2]
PrintText VPMSZText, 7
PrintValueLE TextMEM, 1

; V3D_IDENT2
mov w1,8 + (SCREEN_X * 32)
add w0,w10,w1 ; Place Text At XY Position 8,32
PrintText IDENT2Text, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_IDENT2]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_IDENT2]
and w3,w3,VRISZ
str w3,[x2]
PrintText VRISZText, 7
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_IDENT2]
and w3,w3,TLBSZ
lsr w3,w3,4
str w3,[x2]
PrintText TLBSZText, 7
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_IDENT2]
and w3,w3,TLBDB
lsr w3,w3,8
str w3,[x2]
PrintText TLBDBText, 7
PrintValueLE TextMEM, 1

; V3D_IDENT3
PrintText IDENT3Text, 14
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_IDENT3]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_SCRATCH
mov w1,8 + (SCREEN_X * 40)
add w0,w10,w1 ; Place Text At XY Position 8,40
PrintText SCRATCHText, 14

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SCRATCH]
str w3,[x2]
PrintValueLE TextMEM, 4
PrintText SCRATCHREGText, 19

; V3D_L2CACTL
PrintText L2CACTLText, 15
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_L2CACTL]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_L2CACTL]
and w3,w3,L2CENA
str w3,[x2]
PrintText L2CENAText, 8
PrintValueLE TextMEM, 1

; V3D_INTCTL
mov w1,8 + (SCREEN_X * 48)
add w0,w10,w1 ; Place Text At XY Position 8,48
PrintText INTCTLText, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_INTCTL]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_INTCTL]
and w3,w3,INT_FRDONE
str w3,[x2]
PrintText FRDONEText, 8
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_INTCTL]
and w3,w3,INT_FLDONE
lsr w3,w3,1
str w3,[x2]
PrintText FLDONEText, 8
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_INTCTL]
and w3,w3,INT_OUTOMEM
lsr w3,w3,2
str w3,[x2]
PrintText OUTOMEMText, 9
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_INTCTL]
and w3,w3,INT_SPILLUSE
lsr w3,w3,3
str w3,[x2]
PrintText SPILLUSEText, 10
PrintValueLE TextMEM, 1

; V3D_INTENA
mov w1,8 + (SCREEN_X * 56)
add w0,w10,w1 ; Place Text At XY Position 8,56
PrintText INTENAText, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_INTENA]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_INTENA]
and w3,w3,INT_FRDONE
str w3,[x2]
PrintText FRDONEText, 8
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_INTENA]
and w3,w3,INT_FLDONE
lsr w3,w3,1
str w3,[x2]
PrintText FLDONEText, 8
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_INTENA]
and w3,w3,INT_OUTOMEM
lsr w3,w3,2
str w3,[x2]
PrintText OUTOMEMText, 9
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_INTENA]
and w3,w3,INT_SPILLUSE
lsr w3,w3,3
str w3,[x2]
PrintText SPILLUSEText, 10
PrintValueLE TextMEM, 1

; V3D_INTDIS
mov w1,8 + (SCREEN_X * 64)
add w0,w10,w1 ; Place Text At XY Position 8,64
PrintText INTDISText, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_INTDIS]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_INTDIS]
and w3,w3,INT_FRDONE
str w3,[x2]
PrintText FRDONEText, 8
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_INTDIS]
and w3,w3,INT_FLDONE
lsr w3,w3,1
str w3,[x2]
PrintText FLDONEText, 8
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_INTDIS]
and w3,w3,INT_OUTOMEM
lsr w3,w3,2
str w3,[x2]
PrintText OUTOMEMText, 9
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_INTDIS]
and w3,w3,INT_SPILLUSE
lsr w3,w3,3
str w3,[x2]
PrintText SPILLUSEText, 10
PrintValueLE TextMEM, 1

; V3D_CT0CS
mov w1,8 + (SCREEN_X * 72)
add w0,w10,w1 ; Place Text At XY Position 8,72
PrintText CT0CSText, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT0CS]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT0CS]
and w3,w3,CTMODE
str w3,[x2]
PrintText MODEText, 6
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT0CS]
and w3,w3,CTERR
lsr w3,w3,3
str w3,[x2]
PrintText ERRText, 5
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT0CS]
and w3,w3,CTSUBS
lsr w3,w3,4
str w3,[x2]
PrintText SUBSText, 6
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT0CS]
and w3,w3,CTRUN
lsr w3,w3,5
str w3,[x2]
PrintText RUNText, 5
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT0CS]
and w3,w3,CTRTSD
lsr w3,w3,8
str w3,[x2]
PrintText RTSDText, 6
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT0CS]
and w3,w3,CTSEMA
lsr w3,w3,12
str w3,[x2]
PrintText SEMAText, 6
PrintValueLE TextMEM, 1

; V3D_CT1CS
mov w1,8 + (SCREEN_X * 80)
add w0,w10,w1 ; Place Text At XY Position 8,80
PrintText CT1CSText, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT1CS]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT1CS]
and w3,w3,CTMODE
str w3,[x2]
PrintText MODEText, 6
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT1CS]
and w3,w3,CTERR
lsr w3,w3,3
str w3,[x2]
PrintText ERRText, 5
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT1CS]
and w3,w3,CTSUBS
lsr w3,w3,4
str w3,[x2]
PrintText SUBSText, 6
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT1CS]
and w3,w3,CTRUN
lsr w3,w3,5
str w3,[x2]
PrintText RUNText, 5
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT1CS]
and w3,w3,CTRTSD
lsr w3,w3,8
str w3,[x2]
PrintText RTSDText, 6
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT1CS]
and w3,w3,CTSEMA
lsr w3,w3,12
str w3,[x2]
PrintText SEMAText, 6
PrintValueLE TextMEM, 1

; V3D_CT0EA
mov w1,8 + (SCREEN_X * 88)
add w0,w10,w1 ; Place Text At XY Position 8,88
PrintText CT0EAText, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT0EA]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_CT1EA
PrintText CT1EAText, 14
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT1EA]
str w3,[x2]
PrintValueLE TextMEM, 4
PrintText ThreadEndAddressText, 25

; V3D_CT0CA
mov w1,8 + (SCREEN_X * 96)
add w0,w10,w1 ; Place Text At XY Position 8,96
PrintText CT0CAText, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT0CA]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_CT1CA
PrintText CT1CAText, 14
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT1CA]
str w3,[x2]
PrintValueLE TextMEM, 4
PrintText ThreadCurrentAddressText, 29

; V3D_CT0RA0
mov w1,104 ; 8 + (SCREEN_X * 104)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,104
PrintText CT0RA0Text, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT0RA0]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_CT1RA0
PrintText CT1RA0Text, 14
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT1RA0]
str w3,[x2]
PrintValueLE TextMEM, 4
PrintText ThreadReturnAddressText, 28

; V3D_CT0LC
mov w1,112 ; 8 + (SCREEN_X * 112)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,112
PrintText CT0LCText, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT0LC]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT0LC]
mov w4,CTLSLCS
and w3,w3,w4
str w3,[x2]
PrintText LSLCSText, 7
PrintValueLE TextMEM, 2

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT0LC]
lsr w3,w3,16
str w3,[x2]
PrintText LLCMText, 7
PrintValueLE TextMEM, 2
PrintText Thread0ListCounterText, 24

; V3D_CT1LC
mov w1,120 ; 8 + (SCREEN_X * 120)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,120
PrintText CT1LCText, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT1LC]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT1LC]
mov w4,CTLSLCS
and w3,w3,w4
str w3,[x2]
PrintText LSLCSText, 7
PrintValueLE TextMEM, 2

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT1LC]
lsr w3,w3,16
str w3,[x2]
PrintText LLCMText, 7
PrintValueLE TextMEM, 2
PrintText Thread1ListCounterText, 24

; V3D_CT0PC
mov w1,128 ; 8 + (SCREEN_X * 128)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,128
PrintText CT0PCText, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT0PC]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_CT1PC
PrintText CT1PCText, 14
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_CT1PC]
str w3,[x2]
PrintValueLE TextMEM, 4
PrintText ThreadPrimitiveListCounterText, 36

; V3D_PCS
mov w1,136 ; 8 + (SCREEN_X * 136)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,136
PrintText PCSText, 11

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCS]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCS]
and w3,w3,BMACTIVE
str w3,[x2]
PrintText BMACTIVEText, 10
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCS]
and w3,w3,BMBUSY
lsr w3,w3,1
str w3,[x2]
PrintText BMBUSYText, 8
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCS]
and w3,w3,RMACTIVE
lsr w3,w3,2
str w3,[x2]
PrintText RMACTIVEText, 10
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCS]
and w3,w3,RMBUSY
lsr w3,w3,3
str w3,[x2]
PrintText RMBUSYText, 8
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCS]
and w3,w3,BMOOM
lsr w3,w3,8
str w3,[x2]
PrintText BMOOMText, 7
PrintValueLE TextMEM, 1

; V3D_BFC
mov w1,144 ; 8 + (SCREEN_X * 144)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,144
PrintText BFCText, 11

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_BFC]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_BFC]
and w3,w3,BMFCT
str w3,[x2]
PrintText BMFCTText, 7
PrintValueLE TextMEM, 1

; V3D_RFC
PrintText RFCText, 11
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_RFC]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_RFC]
and w3,w3,RMFCT
str w3,[x2]
PrintText RMFCTText, 7
PrintValueLE TextMEM, 1

; V3D_BPCA
mov w1,152 ; 8 + (SCREEN_X * 152)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,152
PrintText BPCAText, 11

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_BPCA]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_BPCS
PrintText BPCSText, 12
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_BPCS]
str w3,[x2]
PrintValueLE TextMEM, 4
PrintText AddressSizeBinningMemPoolText, 32

; V3D_BPOA
mov w1,160 ; 8 + (SCREEN_X * 160)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,160
PrintText BPOAText, 11

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_BPOA]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_BPOS
PrintText BPOSText, 12
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_BPOS]
str w3,[x2]
PrintValueLE TextMEM, 4
PrintText AddressSizeOverspillBinningMemText, 37

; V3D_BXCF
mov w1,168 ; 8 + (SCREEN_X * 168)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,168
PrintText BXCFText, 11

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_BXCF]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_BXCF]
and w3,w3,FWDDISA
str w3,[x2]
PrintText FWDDISAText, 9
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_BXCF]
and w3,w3,CLIPDISA
lsr w3,w3,1
str w3,[x2]
PrintText CLIPDISAText, 10
PrintValueLE TextMEM, 1
PrintText BinnerDebugText, 15

; V3D_SQRSV0
mov w1,175 ; 8 + (SCREEN_X * 176)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,176
PrintText SQRSV0Text, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SQRSV0]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SQRSV0]
and w3,w3,QPURSV0
str w3,[x2]
PrintText R00Text, 5
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SQRSV0]
and w3,w3,QPURSV1
lsr w3,w3,4
str w3,[x2]
PrintText R01Text, 5
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SQRSV0]
and w3,w3,QPURSV2
lsr w3,w3,8
str w3,[x2]
PrintText R02Text, 5
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SQRSV0]
and w3,w3,QPURSV3
lsr w3,w3,12
str w3,[x2]
PrintText R03Text, 5
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SQRSV0]
and w3,w3,QPURSV4
lsr w3,w3,16
str w3,[x2]
PrintText R04Text, 5
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SQRSV0]
and w3,w3,QPURSV5
lsr w3,w3,20
str w3,[x2]
PrintText R05Text, 5
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SQRSV0]
and w3,w3,QPURSV6
lsr w3,w3,24
str w3,[x2]
PrintText R06Text, 5
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SQRSV0]
and w3,w3,QPURSV7
lsr w3,w3,28
str w3,[x2]
PrintText R07Text, 5
PrintValueLE TextMEM, 1

; V3D_SQRSV1
mov w1,184 ; 8 + (SCREEN_X * 184)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,184
PrintText SQRSV1Text, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SQRSV1]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SQRSV1]
and w3,w3,QPURSV8
str w3,[x2]
PrintText R08Text, 5
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SQRSV1]
and w3,w3,QPURSV9
lsr w3,w3,4
str w3,[x2]
PrintText R09Text, 5
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SQRSV1]
and w3,w3,QPURSV10
lsr w3,w3,8
str w3,[x2]
PrintText R10Text, 5
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SQRSV1]
and w3,w3,QPURSV11
lsr w3,w3,12
str w3,[x2]
PrintText R11Text, 5
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SQRSV1]
and w3,w3,QPURSV12
lsr w3,w3,16
str w3,[x2]
PrintText R12Text, 5
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SQRSV1]
and w3,w3,QPURSV13
lsr w3,w3,20
str w3,[x2]
PrintText R13Text, 5
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SQRSV1]
and w3,w3,QPURSV14
lsr w3,w3,24
str w3,[x2]
PrintText R14Text, 5
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SQRSV1]
and w3,w3,QPURSV15
lsr w3,w3,28
str w3,[x2]
PrintText R15Text, 5
PrintValueLE TextMEM, 1

; V3D_SQCNTL
mov w1,192 ; 8 + (SCREEN_X * 192)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,192
PrintText SQCNTLText, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SQCNTL]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SQCNTL]
and w3,w3,VSRBL
str w3,[x2]
PrintText VSRBLText, 7
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SQCNTL]
and w3,w3,CSRBL
lsr w3,w3,2
str w3,[x2]
PrintText CSRBLText, 7
PrintValueLE TextMEM, 1

; V3D_SQCSTAT
PrintText SQCSTATText, 15
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SQCSTAT]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_SRQUA
mov w1,200 ; 8 + (SCREEN_X * 200)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,200
PrintText SRQUAText, 12

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SRQUA]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_SRQUL
PrintText SRQULText, 13
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SRQUL]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SRQUL]
mov w4,QPURQUL
and w3,w3,w4
str w3,[x2]
PrintText RQULText, 6
PrintValueLE TextMEM, 2
PrintText UniformsText, 26

; V3D_SRQCS
mov w1,208 ; 8 + (SCREEN_X * 208)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,208
PrintText SRQCSText, 12

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SRQCS]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SRQCS]
and w3,w3,QPURQL
str w3,[x2]
PrintText QPURQLText, 8
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SRQCS]
and w3,w3,QPURQERR
lsr w3,w3,7
str w3,[x2]
PrintText QPURQERRText, 10
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SRQCS]
and w3,w3,QPURQCM
lsr w3,w3,8
str w3,[x2]
PrintText QPURQCMText, 9
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_SRQCS]
and w3,w3,QPURQCC
lsr w3,w3,16
str w3,[x2]
PrintText QPURQCCText, 9
PrintValueLE TextMEM, 1

; V3D_VPACNTL
mov w1,216 ; 8 + (SCREEN_X * 216)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,216
PrintText VPACNTLText, 14

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_VPACNTL]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_VPACNTL]
and w3,w3,VPARALIM
str w3,[x2]
PrintText RALIMText, 7
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_VPACNTL]
and w3,w3,VPABALIM
lsr w3,w3,3
str w3,[x2]
PrintText BALIMText, 7
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_VPACNTL]
and w3,w3,VPARATO
lsr w3,w3,6
str w3,[x2]
PrintText RATOText, 6
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_VPACNTL]
and w3,w3,VPABATO
lsr w3,w3,9
str w3,[x2]
PrintText BATOText, 6
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_VPACNTL]
and w3,w3,VPALIMEN
lsr w3,w3,12
str w3,[x2]
PrintText LIMENText, 7
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_VPACNTL]
and w3,w3,VPATOEN
lsr w3,w3,13
str w3,[x2]
PrintText TOENText, 6
PrintValueLE TextMEM, 1

; V3D_VPMBASE
mov w1,224 ; 8 + (SCREEN_X * 224)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,224
PrintText VPMBASEText, 14

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_VPMBASE]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_VPMBASE]
and w3,w3,VPMURSV
str w3,[x2]
PrintText VPMURSVText, 9
PrintValueLE TextMEM, 1
PrintText VPMBaseMemoryReservationText, 30

; V3D_PCTRE
mov w1,232 ; 8 + (SCREEN_X * 232)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,232
PrintText PCTREText, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTRE]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTRE]
mov w4,CTEN0_CTEN15
and w3,w3,w4
str w3,[x2]
PrintText CTEN0_CTEN15Text, 14
PrintValueLE TextMEM, 2
PrintText PerformanceCounterEnablesText, 30

; V3D_PCTR0
mov w1,240 ; 8 + (SCREEN_X * 240)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,240
PrintText PCTR0Text, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTR0]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_PCTRS0
PrintText PCTRS0Text, 15
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTRS0]
and w3,w3,PCTRS
str w3,[x2]
PrintValueLE TextMEM, 1

; V3D_PCTR1
PrintText PCTR1Text, 14
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTR1]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_PCTRS1
PrintText PCTRS1Text, 15
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTRS1]
and w3,w3,PCTRS
str w3,[x2]
PrintValueLE TextMEM, 1

; V3D_PCTR2
mov w1,248 ; 8 + (SCREEN_X * 248)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,248
PrintText PCTR2Text, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTR2]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_PCTRS2
PrintText PCTRS2Text, 15
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTRS2]
and w3,w3,PCTRS
str w3,[x2]
PrintValueLE TextMEM, 1

; V3D_PCTR3
PrintText PCTR3Text, 14
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTR3]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_PCTRS3
PrintText PCTRS3Text, 15
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTRS3]
and w3,w3,PCTRS
str w3,[x2]
PrintValueLE TextMEM, 1

; V3D_PCTR4
mov w1,256 ; 8 + (SCREEN_X * 256)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,256
PrintText PCTR4Text, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTR4]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_PCTRS4
PrintText PCTRS4Text, 15
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTRS4]
and w3,w3,PCTRS
str w3,[x2]
PrintValueLE TextMEM, 1

; V3D_PCTR5
PrintText PCTR5Text, 14
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTR5]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_PCTRS5
PrintText PCTRS5Text, 15
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTRS5]
and w3,w3,PCTRS
str w3,[x2]
PrintValueLE TextMEM, 1

; V3D_PCTR6
mov w1,264 ; 8 + (SCREEN_X * 264)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,264
PrintText PCTR6Text, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTR6]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_PCTRS6
PrintText PCTRS6Text, 15
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTRS6]
and w3,w3,PCTRS
str w3,[x2]
PrintValueLE TextMEM, 1

; V3D_PCTR7
PrintText PCTR7Text, 14
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTR7]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_PCTRS7
PrintText PCTRS7Text, 15
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTRS7]
and w3,w3,PCTRS
str w3,[x2]
PrintValueLE TextMEM, 1

; V3D_PCTR8
mov w1,272 ; 8 + (SCREEN_X * 272)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,272
PrintText PCTR8Text, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTR8]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_PCTRS8
PrintText PCTRS8Text, 15
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTRS8]
and w3,w3,PCTRS
str w3,[x2]
PrintValueLE TextMEM, 1

; V3D_PCTR9
PrintText PCTR9Text, 14
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTR9]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_PCTRS9
PrintText PCTRS9Text, 15
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTRS9]
and w3,w3,PCTRS
str w3,[x2]
PrintValueLE TextMEM, 1

; V3D_PCTR10
mov w1,280 ; 8 + (SCREEN_X * 280)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,280
PrintText PCTR10Text, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTR10]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_PCTRS10
PrintText PCTRS10Text, 15
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTRS10]
and w3,w3,PCTRS
str w3,[x2]
PrintValueLE TextMEM, 1

; V3D_PCTR11
PrintText PCTR11Text, 14
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTR11]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_PCTRS11
PrintText PCTRS11Text, 15
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTRS11]
and w3,w3,PCTRS
str w3,[x2]
PrintValueLE TextMEM, 1

; V3D_PCTR12
mov w1,288 ; 8 + (SCREEN_X * 288)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,288
PrintText PCTR12Text, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTR12]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_PCTRS12
PrintText PCTRS12Text, 15
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTRS12]
and w3,w3,PCTRS
str w3,[x2]
PrintValueLE TextMEM, 1

; V3D_PCTR13
PrintText PCTR13Text, 14
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTR13]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_PCTRS13
PrintText PCTRS13Text, 15
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTRS13]
and w3,w3,PCTRS
str w3,[x2]
PrintValueLE TextMEM, 1

; V3D_PCTR14
mov w1,296 ; 8 + (SCREEN_X * 296)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,296
PrintText PCTR14Text, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTR14]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_PCTRS14
PrintText PCTRS14Text, 15
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTRS14]
and w3,w3,PCTRS
str w3,[x2]
PrintValueLE TextMEM, 1

; V3D_PCTR15
PrintText PCTR15Text, 14
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTR15]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_PCTRS15
PrintText PCTRS15Text, 15
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_PCTRS15]
and w3,w3,PCTRS
str w3,[x2]
PrintValueLE TextMEM, 1

; V3D_DBCFG
mov w1,304 ; 8 + (SCREEN_X * 304)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,304
PrintText DBCFGText, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBCFG]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_DBSCS
PrintText DBSCSText, 14
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBSCS]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_DBSCFG
mov w1,312 ; 8 + (SCREEN_X * 312)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,312
PrintText DBSCFGText, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBSCFG]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_DBSSR
PrintText DBSSRText, 14
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBSSR]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_DBSDR0
PrintText DBSDR0Text, 14
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBSDR0]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_DBSDR1
mov w1,320 ; 8 + (SCREEN_X * 320)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,320
PrintText DBSDR1Text, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBSDR1]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_DBSDR2
PrintText DBSDR2Text, 14
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBSDR2]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_DBSDR3
PrintText DBSDR3Text, 14
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBSDR3]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_DBQRUN
mov w1,328 ; 8 + (SCREEN_X * 328)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,328
PrintText DBQRUNText, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBQRUN]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_DBQHLT
PrintText DBQHLTText, 14
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBQHLT]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_DBQSTP
PrintText DBQSTPText, 14
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBQSTP]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_DBQITE
mov w1,336 ; 8 + (SCREEN_X * 336)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,336
PrintText DBQITEText, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBQITE]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBQITE]
mov w4,IE_QPU0_to_IE_QPU15
and w3,w3,w4
str w3,[x2]
PrintText IE_QPU0_to_IE_QPU15Text, 21
PrintValueLE TextMEM, 2
PrintText QPUInterruptEnablesText, 24

; V3D_DBQITC
mov w1,344 ; 8 + (SCREEN_X * 344)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,344
PrintText DBQITCText, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBQITC]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBQITC]
mov w4,IC_QPU0_to_IC_QPU15
and w3,w3,w4
str w3,[x2]
PrintText IC_QPU0_to_IC_QPU15Text, 21
PrintValueLE TextMEM, 2
PrintText QPUInterruptControlText, 24

; V3D_DBQGHC
mov w1,352 ; 8 + (SCREEN_X * 352)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,352
PrintText DBQGHCText, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBQGHC]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_DBQGHG
PrintText DBQGHGText, 14
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBQGHG]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_DBQGHH
PrintText DBQGHHText, 14
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBQGHH]
str w3,[x2]
PrintValueLE TextMEM, 4

; V3D_DBGE
mov w1,360 ; 8 + (SCREEN_X * 360)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,360
PrintText DBGEText, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBGE]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBGE]
and w3,w3,VR1_A
lsr w3,w3,1
str w3,[x2]
PrintText VR1_AText, 7
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBGE]
and w3,w3,VR1_A
lsr w3,w3,2
str w3,[x2]
PrintText VR1_BText, 7
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBGE]
and w3,w3,MULIP0
lsr w3,w3,16
str w3,[x2]
PrintText MULIP0Text, 8
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBGE]
and w3,w3,MULIP1
lsr w3,w3,17
str w3,[x2]
PrintText MULIP1Text, 8
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBGE]
and w3,w3,MULIP2
lsr w3,w3,18
str w3,[x2]
PrintText MULIP2Text, 8
PrintValueLE TextMEM, 1

mov w1,368 ; 328 + (SCREEN_X * 368)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,328
add w0,w10,w1 ; Place Text At XY Position 328,368
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBGE]
and w3,w3,IPD2_VALID
lsr w3,w3,19
str w3,[x2]
PrintText IPD2_VALIDText, 11
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_DBGE]
and w3,w3,IPD2_FPDUSED
lsr w3,w3,20
str w3,[x2]
PrintText IPD2_FPDUSEDText, 14
PrintValueLE TextMEM, 1

; V3D_FDBGO
mov w1,376 ; 8 + (SCREEN_X * 376)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,376
PrintText FDBGOText, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGO]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGO]
and w3,w3,WCOEFF_FIFO_FULL
lsr w3,w3,1
str w3,[x2]
PrintText WCOEFF_FIFO_FULLText, 18
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGO]
and w3,w3,XYRELZ_FIFO_FULL
lsr w3,w3,2
str w3,[x2]
PrintText XYRELZ_FIFO_FULLText, 18
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGO]
and w3,w3,QBFR_FIFO_ORUN
lsr w3,w3,3
str w3,[x2]
PrintText QBFR_FIFO_ORUNText, 16
PrintValueLE TextMEM, 1

mov w1,384 ; 96 + (SCREEN_X * 384)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,96
add w0,w10,w1 ; Place Text At XY Position 96,384
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGO]
and w3,w3,QBSZ_FIFO_ORUN
lsr w3,w3,4
str w3,[x2]
PrintText QBSZ_FIFO_ORUNText, 15
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGO]
and w3,w3,XYFO_FIFO_ORUN
lsr w3,w3,5
str w3,[x2]
PrintText XYFO_FIFO_ORUNText, 16
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGO]
and w3,w3,FIXZ_ORUN
lsr w3,w3,6
str w3,[x2]
PrintText FIXZ_ORUNText, 11
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGO]
and w3,w3,XYRELO_FIFO_ORUN
lsr w3,w3,7
str w3,[x2]
PrintText XYRELO_FIFO_ORUNText, 18
PrintValueLE TextMEM, 1

mov w1,392 ; 16 + (SCREEN_X * 392)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,16
add w0,w10,w1 ; Place Text At XY Position 16,392
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGO]
and w3,w3,XYRELW_FIFO_ORUN
lsr w3,w3,10
str w3,[x2]
PrintText XYRELW_FIFO_ORUNText, 17
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGO]
and w3,w3,ZCOEFF_FIFO_FULL
lsr w3,w3,11
str w3,[x2]
PrintText ZCOEFF_FIFO_FULLText, 18
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGO]
and w3,w3,REFXY_FIFO_ORUN
lsr w3,w3,12
str w3,[x2]
PrintText REFXY_FIFO_ORUNText, 17
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGO]
and w3,w3,DEPTHO_FIFO_ORUN
lsr w3,w3,13
str w3,[x2]
PrintText DEPTHO_FIFO_ORUNText, 18
PrintValueLE TextMEM, 1

mov w1,400 ; 224 + (SCREEN_X * 400)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,224
add w0,w10,w1 ; Place Text At XY Position 224,400
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGO]
and w3,w3,DEPTHO_ORUN
lsr w3,w3,14
str w3,[x2]
PrintText DEPTHO_ORUNText, 12
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGO]
and w3,w3,EZVAL_FIFO_ORUN
lsr w3,w3,15
str w3,[x2]
PrintText EZVAL_FIFO_ORUNText, 17
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGO]
and w3,w3,EZREQ_FIFO_ORUN
lsr w3,w3,17
str w3,[x2]
PrintText EZREQ_FIFO_ORUNText, 17
PrintValueLE TextMEM, 1

; V3D_FDBGB
mov w1,408 ; 8 + (SCREEN_X * 408)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,408
PrintText FDBGBText, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGB]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGB]
and w3,w3,EDGES_STALL
str w3,[x2]
PrintText EDGES_STALLText, 13
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGB]
and w3,w3,EDGES_READY
lsr w3,w3,1
str w3,[x2]
PrintText EDGES_READYText, 13
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGB]
and w3,w3,EDGES_ISCTRL
lsr w3,w3,2
str w3,[x2]
PrintText EDGES_ISCTRLText, 14
PrintValueLE TextMEM, 1

mov w1,416 ; 144 + (SCREEN_X * 416)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,144
add w0,w10,w1 ; Place Text At XY Position 144,416
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGB]
and w3,w3,EDGES_CTRLID
lsr w3,w3,3
str w3,[x2]
PrintText EDGES_CTRLIDText, 13
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGB]
and w3,w3,ZRWPE_STALL
lsr w3,w3,6
str w3,[x2]
PrintText ZRWPE_STALLText, 13
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGB]
and w3,w3,ZRWPE_READY
lsr w3,w3,7
str w3,[x2]
PrintText ZRWPE_READYText, 13
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGB]
and w3,w3,EZ_DATA_READY
lsr w3,w3,23
str w3,[x2]
PrintText EZ_DATA_READYText, 15
PrintValueLE TextMEM, 1

mov w1,424 ; 72 + (SCREEN_X * 424)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,72
add w0,w10,w1 ; Place Text At XY Position 72,424
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGB]
and w3,w3,EZ_XY_READY
lsr w3,w3,25
str w3,[x2]
PrintText EZ_XY_READYText, 12
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGB]
and w3,w3,RAST_BUSY
lsr w3,w3,26
str w3,[x2]
PrintText RAST_BUSYText, 11
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGB]
and w3,w3,QXYF_FIFO_OP_READY
lsr w3,w3,27
str w3,[x2]
PrintText QXYF_FIFO_OP_READYText, 20
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGB]
and w3,w3,XYFO_FIFO_OP_READY
lsr w3,w3,28
str w3,[x2]
PrintText XYFO_FIFO_OP_READYText, 20
PrintValueLE TextMEM, 1

; V3D_FDBGR
mov w1,432 ; 8 + (SCREEN_X * 432)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,432
PrintText FDBGRText, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGR]
str w3,[x2]
PrintValueLE TextMEM, 4
PrintText FEPInternalReadySignalsText, 29

; V3D_FDBGS
mov w1,440 ; 8 + (SCREEN_X * 440)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,440
PrintText FDBGSText, 13

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_FDBGS]
str w3,[x2]
PrintValueLE TextMEM, 4
PrintText FEPInternalStallInputSignalsText, 35

; V3D_ERRSTAT
mov w1,448 ; 8 + (SCREEN_X * 448)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,8
add w0,w10,w1 ; Place Text At XY Position 8,448
PrintText ERRSTATText, 15

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_ERRSTAT]
str w3,[x2]
PrintValueLE TextMEM, 4

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_ERRSTAT]
and w3,w3,VPAEABB
str w3,[x2]
PrintText VPAEABBText, 9
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_ERRSTAT]
and w3,w3,VPAERGS
lsr w3,w3,1
str w3,[x2]
PrintText VPAERGSText, 9
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_ERRSTAT]
and w3,w3,VPAEBRGL
lsr w3,w3,2
str w3,[x2]
PrintText VPAEBRGLText, 10
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_ERRSTAT]
and w3,w3,VPAERRGL
lsr w3,w3,3
str w3,[x2]
PrintText VPAERRGLText, 10
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_ERRSTAT]
and w3,w3,VPMEWR
lsr w3,w3,4
str w3,[x2]
PrintText VPMEWRText, 8
PrintValueLE TextMEM, 1

mov w1,456 ; 32 + (SCREEN_X * 456)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,32
add w0,w10,w1 ; Place Text At XY Position 32,456
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_ERRSTAT]
and w3,w3,VPMERR
lsr w3,w3,5
str w3,[x2]
PrintText VPMERRText, 7
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_ERRSTAT]
and w3,w3,VPMERNA
lsr w3,w3,6
str w3,[x2]
PrintText VPMERNAText, 9
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_ERRSTAT]
and w3,w3,VPMEWNA
lsr w3,w3,7
str w3,[x2]
PrintText VPMEWNAText, 9
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_ERRSTAT]
and w3,w3,VPMEFNA
lsr w3,w3,8
str w3,[x2]
PrintText VPMEFNAText, 9
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_ERRSTAT]
and w3,w3,VPMEAS
lsr w3,w3,9
str w3,[x2]
PrintText VPMEASText, 8
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_ERRSTAT]
and w3,w3,VDWE
lsr w3,w3,10
str w3,[x2]
PrintText VDWEText, 6
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_ERRSTAT]
and w3,w3,VCDE
lsr w3,w3,11
str w3,[x2]
PrintText VCDEText, 6
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_ERRSTAT]
and w3,w3,VCDI
lsr w3,w3,12
str w3,[x2]
PrintText VCDIText, 6
PrintValueLE TextMEM, 1

mov w1,464 ; 424 + (SCREEN_X * 464)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,424
add w0,w10,w1 ; Place Text At XY Position 424,464
mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_ERRSTAT]
and w3,w3,VCMRE
lsr w3,w3,13
str w3,[x2]
PrintText VCMREText, 6
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_ERRSTAT]
and w3,w3,VCMBE
lsr w3,w3,14
str w3,[x2]
PrintText VCMBEText, 7
PrintValueLE TextMEM, 1

mov w1,PERIPHERAL_BASE + V3D_BASE
adr x2,TextMEM
ldr w3,[x1,V3D_ERRSTAT]
and w3,w3,L2CARE
lsr w3,w3,15
str w3,[x2]
PrintText L2CAREText, 8
PrintValueLE TextMEM, 1

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

align 16
TAGS_STRUCT: ; Mailbox Property Interface Buffer Structure
  dw TAGS_END - TAGS_STRUCT ; Buffer Size In Bytes (Including The Header Values, The End Tag And Padding)
  dw $00000000 ; Buffer Request/Response Code
	       ; Request Codes: $00000000 Process Request Response Codes: $80000000 Request Successful, $80000001 Partial Response
; Sequence Of Concatenated Tags
  dw Set_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_V3D_ID ; Value Buffer (V3D Clock ID)
  dw 250*1000*1000 ; Value Buffer (250MHz)

  dw Enable_QPU ; Tag Identifier
  dw $00000004 ; Value Buffer Size In Bytes
  dw $00000004 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw 1 ; Value Buffer (1 = Enable)

dw $00000000 ; $0 (End Tag)
TAGS_END:

VCText: db "VideoCoreIV:"

IDENT0Text: db "V3D_IDENT0: $"
IDSTRText:  db " IDSTR='"
TVERText:   db "' TVER="

IDENT1Text: db "V3D_IDENT1: $"
REVText:    db " REV="
NSLCText:   db " NSLC="
QUPSText:   db " QUPS="
TUPSText:   db " TUPS="
NSEMText:   db " NSEM="
HDRTText:   db " HDRT="
VPMSZText:  db " VPMSZ="

IDENT2Text: db "V3D_IDENT2: $"
VRISZText:  db " VRISZ="
TLBSZText:  db " TLBSZ="
TLBDBText:  db " TLBDB="

IDENT3Text: db " V3D_IDENT3: $"

SCRATCHText: db "V3D_SCRATCH: $"
SCRATCHREGText: db " (Scratch Register)"

L2CACTLText: db " V3D_L2CACTL: $"
L2CENAText:  db " L2CENA="

INTCTLText: db "V3D_INTCTL: $"
INTENAText: db "V3D_INTENA: $"
INTDISText: db "V3D_INTDIS: $"
FRDONEText:   db " FRDONE="
FLDONEText:   db " FLDONE="
OUTOMEMText:  db " OUTOMEM="
SPILLUSEText: db " SPILLUSE="

CT0CSText: db "V3D_CT0CS:  $"
CT1CSText: db "V3D_CT1CS:  $"
MODEText: db " MODE="
ERRText:  db " ERR="
SUBSText: db " SUBS="
RUNText:  db " RUN="
RTSDText: db " RTSD="
SEMAText: db " SEMA="

CT0EAText: db "V3D_CT0EA:  $"
CT1EAText: db " V3D_CT1EA:  $"
ThreadEndAddressText: db " (Thread 0/1 End Address)"

CT0CAText: db "V3D_CT0CA:  $"
CT1CAText: db " V3D_CT1CA:  $"
ThreadCurrentAddressText: db " (Thread 0/1 Current Address)"

CT0RA0Text: db "V3D_CT0RA0: $"
CT1RA0Text: db " V3D_CT1RA0: $"
ThreadReturnAddressText: db " (Thread 0/1 Return Address)"

CT0LCText: db "V3D_CT0LC:  $"
CT1LCText: db "V3D_CT1LC:  $"
LSLCSText: db " LSLCS="
LLCMText:  db "  LLCM="
Thread0ListCounterText: db " (Thread 0 List Counter)"
Thread1ListCounterText: db " (Thread 1 List Counter)"

CT0PCText: db "V3D_CT0PC:  $"
CT1PCText: db " V3D_CT1PC:  $"
ThreadPrimitiveListCounterText: db " (Thread 0/1 Primitive List Counter)"

PCSText: db "V3D_PCS:  $"
BMACTIVEText: db " BMACTIVE="
BMBUSYText:   db " BMBUSY="
RMACTIVEText: db " RMACTIVE="
RMBUSYText:   db " RMBUSY="
BMOOMText:    db " BMOOM="

BFCText: db "V3D_BFC:  $"
BMFCTText: db " BMFCT="

RFCText: db " V3D_RFC: $"
RMFCTText: db " RMFCT="

BPCAText: db "V3D_BPCA: $"
BPCSText: db " V3D_BPCS: $"
AddressSizeBinningMemPoolText: db " (Address/Size Binning Mem Pool)"

BPOAText: db "V3D_BPOA: $"
BPOSText: db " V3D_BPOS: $"
AddressSizeOverspillBinningMemText: db " (Address/Size Overspill Binning Mem)"

BXCFText: db "V3D_BXCF: $"
FWDDISAText:  db " FWDDISA="
CLIPDISAText: db " CLIPDISA="
BinnerDebugText: db " (Binner Debug)"

SQRSV0Text: db "V3D_SQRSV0: $"
R00Text: db " R00="
R01Text: db " R01="
R02Text: db " R02="
R03Text: db " R03="
R04Text: db " R04="
R05Text: db " R05="
R06Text: db " R06="
R07Text: db " R07="

SQRSV1Text: db "V3D_SQRSV1: $"
R08Text: db " R08="
R09Text: db " R09="
R10Text: db " R10="
R11Text: db " R11="
R12Text: db " R12="
R13Text: db " R13="
R14Text: db " R14="
R15Text: db " R15="

SQCNTLText: db "V3D_SQCNTL: $"
VSRBLText: db " VSRBL="
CSRBLText: db " CSRBL="

SQCSTATText: db " V3D_SQCSTAT: $"

SRQUAText: db "V3D_SRQUA: $"
SRQULText: db " V3D_SRQUL: $"
RQULText:  db " RQUL="
UniformsText: db " (Uniforms Address/Length)"

SRQCSText: db "V3D_SRQCS: $"
QPURQLText:   db " QPURQL="
QPURQERRText: db " QPURQERR="
QPURQCMText:  db " QPURQCM="
QPURQCCText:  db " QPURQCC="

VPACNTLText: db "V3D_VPACNTL: $"
RALIMText: db " RALIM="
BALIMText: db " BALIM="
RATOText:  db " RATO="
BATOText:  db " BATO="
LIMENText: db " LIMEN="
TOENText:  db " TOEN="

VPMBASEText: db "V3D_VPMBASE: $"
VPMURSVText: db " VPMURSV="
VPMBaseMemoryReservationText: db " (VPM Base Memory Reservation)"

PCTREText: db "V3D_PCTRE:  $"
CTEN0_CTEN15Text: db " CTEN0_CTEN15="
PerformanceCounterEnablesText: db " (Performance Counter Enables)"

PCTR0Text:  db "V3D_PCTR0:  $"
PCTR1Text:  db " V3D_PCTR1:  $"
PCTR2Text:  db "V3D_PCTR2:  $"
PCTR3Text:  db " V3D_PCTR3:  $"
PCTR4Text:  db "V3D_PCTR4:  $"
PCTR5Text:  db " V3D_PCTR5:  $"
PCTR6Text:  db "V3D_PCTR6:  $"
PCTR7Text:  db " V3D_PCTR7:  $"
PCTR8Text:  db "V3D_PCTR8:  $"
PCTR9Text:  db " V3D_PCTR9:  $"
PCTR10Text: db "V3D_PCTR10: $"
PCTR11Text: db " V3D_PCTR11: $"
PCTR12Text: db "V3D_PCTR12: $"
PCTR13Text: db " V3D_PCTR13: $"
PCTR14Text: db "V3D_PCTR14: $"
PCTR15Text: db " V3D_PCTR15: $"

PCTRS0Text:  db " V3D_PCTRS0:  $"
PCTRS1Text:  db " V3D_PCTRS1:  $"
PCTRS2Text:  db " V3D_PCTRS2:  $"
PCTRS3Text:  db " V3D_PCTRS3:  $"
PCTRS4Text:  db " V3D_PCTRS4:  $"
PCTRS5Text:  db " V3D_PCTRS5:  $"
PCTRS6Text:  db " V3D_PCTRS6:  $"
PCTRS7Text:  db " V3D_PCTRS7:  $"
PCTRS8Text:  db " V3D_PCTRS8:  $"
PCTRS9Text:  db " V3D_PCTRS9:  $"
PCTRS10Text: db " V3D_PCTRS10: $"
PCTRS11Text: db " V3D_PCTRS11: $"
PCTRS12Text: db " V3D_PCTRS12: $"
PCTRS13Text: db " V3D_PCTRS13: $"
PCTRS14Text: db " V3D_PCTRS14: $"
PCTRS15Text: db " V3D_PCTRS15: $"

DBCFGText: db "V3D_DBCFG:  $"
DBSCSText: db " V3D_DBSCS:  $"

DBSCFGText: db "V3D_DBSCFG: $"
DBSSRText:  db " V3D_DBSSR:  $"

DBSDR0Text: db " V3D_DBSDR0: $"
DBSDR1Text: db "V3D_DBSDR1: $"
DBSDR2Text: db " V3D_DBSDR2: $"
DBSDR3Text: db " V3D_DBSDR3: $"

DBQRUNText: db "V3D_DBQRUN: $"
DBQHLTText: db " V3D_DBQHLT: $"
DBQSTPText: db " V3D_DBQSTP: $"

DBQITEText: db "V3D_DBQITE: $"
IE_QPU0_to_IE_QPU15Text: db " IE_QPU0_to_IE_QPU15="
QPUInterruptEnablesText: db " (QPU Interrupt Enables)"

DBQITCText: db "V3D_DBQITC: $"
IC_QPU0_to_IC_QPU15Text: db " IC_QPU0_to_IC_QPU15="
QPUInterruptControlText: db " (QPU Interrupt Control)"

DBQGHCText: db "V3D_DBQGHC: $"
DBQGHGText: db " V3D_DBQGHG: $"
DBQGHHText: db " V3D_DBQGHH: $"

DBGEText: db "V3D_DBGE:   $"
VR1_AText: db " VR1_A="
VR1_BText: db " VR1_B="
MULIP0Text: db " MULIP0="
MULIP1Text: db " MULIP1="
MULIP2Text: db " MULIP2="
IPD2_VALIDText:   db "IPD2_VALID="
IPD2_FPDUSEDText: db " IPD2_FPDUSED="

FDBGOText: db "V3D_FDBGO:  $"
WCOEFF_FIFO_FULLText: db " WCOEFF_FIFO_FULL="
XYRELZ_FIFO_FULLText: db " XYRELZ_FIFO_FULL="
QBFR_FIFO_ORUNText: db " QBFR_FIFO_ORUN="
QBSZ_FIFO_ORUNText: db "QBSZ_FIFO_ORUN="
XYFO_FIFO_ORUNText: db " XYFO_FIFO_ORUN="
FIXZ_ORUNText: db " FIXZ_ORUN="
XYRELO_FIFO_ORUNText: db " XYRELO_FIFO_ORUN="
XYRELW_FIFO_ORUNText: db "XYRELW_FIFO_ORUN="
ZCOEFF_FIFO_FULLText: db " ZCOEFF_FIFO_FULL="
REFXY_FIFO_ORUNText: db " REFXY_FIFO_ORUN="
DEPTHO_FIFO_ORUNText: db " DEPTHO_FIFO_ORUN="
DEPTHO_ORUNText: db "DEPTHO_ORUN="
EZVAL_FIFO_ORUNText: db " EZVAL_FIFO_ORUN="
EZREQ_FIFO_ORUNText: db " EZREQ_FIFO_ORUN="

FDBGBText: db "V3D_FDBGB:  $"
EDGES_STALLText: db " EDGES_STALL="
EDGES_READYText: db " EDGES_READY="
EDGES_ISCTRLText: db " EDGES_ISCTRL="
EDGES_CTRLIDText: db "EDGES_CTRLID="
ZRWPE_STALLText: db " ZRWPE_STALL="
ZRWPE_READYText: db " ZRWPE_READY="
EZ_DATA_READYText: db " EZ_DATA_READY="
EZ_XY_READYText: db "EZ_XY_READY="
RAST_BUSYText: db " RAST_BUSY="
QXYF_FIFO_OP_READYText: db " QXYF_FIFO_OP_READY="
XYFO_FIFO_OP_READYText: db " XYFO_FIFO_OP_READY="

FDBGRText: db "V3D_FDBGR:  $"
FEPInternalReadySignalsText: db " (FEP Internal Ready Signals)"

FDBGSText: db "V3D_FDBGS:  $"
FEPInternalStallInputSignalsText: db " (FEP Internal Stall Input Signals)"

ERRSTATText: db "V3D_ERRSTAT:  $"
VPAEABBText: db " VPAEABB="
VPAERGSText: db " VPAERGS="
VPAEBRGLText: db " VPAEBRGL="
VPAERRGLText: db " VPAERRGL="
VPMEWRText: db " VPMEWR="
VPMERRText: db "VPMERR="
VPMERNAText: db " VPMERNA="
VPMEWNAText: db " VPMEWNA="
VPMEFNAText: db " VPMEFNA="
VPMEASText: db " VPMEAS="
VDWEText: db " VDWE="
VCDEText: db " VCDE="
VCDIText: db " VCDI="
VCMREText: db "VCMRE="
VCMBEText: db " VCMBE="
L2CAREText: db " L2CARE="

align 4
TextMEM: dw 0;

align 8
Font: include 'Font8x8.asm'