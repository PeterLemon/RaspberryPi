; Raspberry Pi 2 'Bare Metal' V3D Initialize Demo by krom (Peter Lemon):
; 1. Run Tags & Set V3D Frequency To 250MHz, & Enable Quad Processing Unit
; 2. Setup Frame Buffer
; 3. Copy V3D Readable Register Values To Frame Buffer Using DMA 2D Mode & Stride

macro PrintText Text, TextLength {
  local .DrawChars,.DMAWait
  imm32 r1,Font ; R1 = Characters
  imm32 r2,Text ; R2 = Text Offset
  imm32 r3,CB_STRUCT ; R3 = Control Block Data
  imm32 r4,PERIPHERAL_BASE + DMA0_BASE ; R4 = DMA 0 Base
  mov r5,DMA_ACTIVE ; R5 = DMA Active Bit
  mov r6,TextLength ; R6 = Number Of Text Characters To Print
  .DrawChars:
    ldrb r7,[r2],1 ; R7 = Next Text Character
    add r7,r1,r7,lsl 6 ; Add Shift To Correct Position In Font (* 64)
    str r7,[r3,CB_SOURCE - CB_STRUCT] ; Store DMA Source Address
    str r0,[r3,CB_DEST - CB_STRUCT] ; Store DMA Destination Address
    str r3,[r4,DMA_CONBLK_AD] ; Store DMA Control Block Data Address
    str r5,[r4,DMA_CS] ; Print Next Text Character To Screen
    .DMAWait:
      ldr r7,[r4,DMA_CS] ; Load Control Block Status
      tst r7,r5 ; Test Active Bit
      bne .DMAWait ; Wait Until DMA Has Finished

    subs r6,1 ; Subtract Number Of Text Characters To Print
    add r0,CHAR_X ; Jump Forward 1 Char
    bne .DrawChars ; Continue To Print Characters
}

macro PrintValueLE Value, ValueLength {
  local .DrawHEXChars,.DMAHEXWait,.DMAHEXWaitB
  imm32 r1,Font ; R1 = Characters
  imm32 r2,Value ; R2 = Text Offset
  add r2,ValueLength - 1
  imm32 r3,CB_STRUCT ; R3 = Control Block Data
  imm32 r4,PERIPHERAL_BASE + DMA0_BASE ; R4 = DMA 0 Base
  mov r5,DMA_ACTIVE ; R5 = DMA Active Bit
  mov r6,ValueLength ; R6 = Number Of HEX Characters To Print
  .DrawHEXChars:
    ldrb r7,[r2],-1 ; R7 = Next 2 HEX Characters
    mov r8,r7,lsr 4 ; Get 2nd Nibble
    cmp r8,$9
    addle r8,$30
    addgt r8,$37
    add r8,r1,r8,lsl 6 ; Add Shift To Correct Position In Font (* 64)
    str r8,[r3,CB_SOURCE - CB_STRUCT] ; Store DMA Source Address
    str r0,[r3,CB_DEST - CB_STRUCT] ; Store DMA Destination Address
    str r3,[r4,DMA_CONBLK_AD] ; Store DMA Control Block Data Address
    str r5,[r4,DMA_CS] ; Print Next Text Character To Screen
    .DMAHEXWait:
      ldr r8,[r4,DMA_CS] ; Load Control Block Status
      tst r8,r5 ; Test Active Bit
      bne .DMAHEXWait ; Wait Until DMA Has Finished

    add r0,CHAR_X ; Jump Forward 1 Char
    and r8,r7,$F ; Get 1st Nibble
    cmp r8,$9
    addle r8,$30
    addgt r8,$37
    add r8,r1,r8,lsl 6 ; Add Shift To Correct Position In Font (* 64)
    str r8,[r3,CB_SOURCE - CB_STRUCT] ; Store DMA Source Address
    str r0,[r3,CB_DEST - CB_STRUCT] ; Store DMA Destination Address
    str r3,[r4,DMA_CONBLK_AD] ; Store DMA Control Block Data Address
    str r5,[r4,DMA_CS] ; Print Next Text Character To Screen
    .DMAHEXWaitB:
      ldr r8,[r4,DMA_CS] ; Load Control Block Status
      tst r8,r5 ; Test Active Bit
      bne .DMAHEXWaitB ; Wait Until DMA Has Finished

    subs r6,1 ; Subtract Number Of HEX Characters To Print
    add r0,CHAR_X ; Jump Forward 1 Char
    bne .DrawHEXChars ; Continue To Print Characters
}

format binary as 'img'
include 'LIB\FASMARM.INC'
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
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
ands r0,3 ; R0 = CPU ID (Bits 0..1)
bne CoreLoop ; IF (CPU ID != 0) Branch To Infinite Loop (Core ID 1..3)

imm32 r0,PERIPHERAL_BASE + DMA_ENABLE ; Set DMA Channel 0 Enable Bit
mov r1,DMA_EN0
str r1,[r0]

; Run Tags To Initialize V3D
imm32 r0,PERIPHERAL_BASE + MAIL_BASE
imm32 r1,TAGS_STRUCT
orr r1,MAIL_TAGS
str r1,[r0,MAIL_WRITE] ; Mail Box Write

FB_Init:
  imm32 r0,FB_STRUCT + MAIL_TAGS
  imm32 r1,PERIPHERAL_BASE + MAIL_BASE + MAIL_WRITE + MAIL_TAGS
  str r0,[r1] ; Mail Box Write

  imm32 r1,FB_POINTER
  ldr r10,[r1] ; R10 = Frame Buffer Pointer
  cmp r10,0 ; Compare Frame Buffer Pointer To Zero
  beq FB_Init ; IF Zero Re-Initialize Frame Buffer

  and r10,$3FFFFFFF ; Convert Mail Box Frame Buffer Pointer From BUS Address To Physical Address ($CXXXXXXX -> $3XXXXXXX)
  str r10,[r1] ; Store Frame Buffer Pointer Physical Address

imm32 r1,0 + (SCREEN_X * 8)
add r0,r10,r1 ; Place Text At XY Position 0,8
PrintText VCText, 12

; V3D_IDENT0
imm32 r1,8 + (SCREEN_X * 16)
add r0,r10,r1 ; Place Text At XY Position 8,16
PrintText IDENT0Text, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_IDENT0
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4
PrintText IDSTRText, 8
PrintText TextMEM, 3

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_IDENT0
imm32 r2,TextMEM
ldr r3,[r1]
mov r3,r3,lsr 24
str r3,[r2]
PrintText TVERText, 7
PrintValueLE TextMEM, 1

; V3D_IDENT1
imm32 r1,8 + (SCREEN_X * 24)
add r0,r10,r1 ; Place Text At XY Position 8,24
PrintText IDENT1Text, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_IDENT1
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_IDENT1
imm32 r2,TextMEM
ldr r3,[r1]
and r3,REVR
str r3,[r2]
PrintText REVText, 5
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_IDENT1
imm32 r2,TextMEM
ldr r3,[r1]
and r3,NSLC
mov r3,r3,lsr 4
str r3,[r2]
PrintText NSLCText, 6
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_IDENT1
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QUPS
mov r3,r3,lsr 8
str r3,[r2]
PrintText QUPSText, 6
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_IDENT1
imm32 r2,TextMEM
ldr r3,[r1]
and r3,TUPS
mov r3,r3,lsr 12
str r3,[r2]
PrintText TUPSText, 6
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_IDENT1
imm32 r2,TextMEM
ldr r3,[r1]
and r3,NSEM
mov r3,r3,lsr 16
str r3,[r2]
PrintText NSEMText, 6
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_IDENT1
imm32 r2,TextMEM
ldr r3,[r1]
and r3,HDRT
mov r3,r3,lsr 24
str r3,[r2]
PrintText HDRTText, 6
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_IDENT1
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VPMSZ
mov r3,r3,lsr 28
str r3,[r2]
PrintText VPMSZText, 7
PrintValueLE TextMEM, 1

; V3D_IDENT2
imm32 r1,8 + (SCREEN_X * 32)
add r0,r10,r1 ; Place Text At XY Position 8,32
PrintText IDENT2Text, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_IDENT2
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_IDENT2
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VRISZ
str r3,[r2]
PrintText VRISZText, 7
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_IDENT2
imm32 r2,TextMEM
ldr r3,[r1]
and r3,TLBSZ
mov r3,r3,lsr 4
str r3,[r2]
PrintText TLBSZText, 7
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_IDENT2
imm32 r2,TextMEM
ldr r3,[r1]
and r3,TLBDB
mov r3,r3,lsr 8
str r3,[r2]
PrintText TLBDBText, 7
PrintValueLE TextMEM, 1

; V3D_IDENT3
PrintText IDENT3Text, 14
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_IDENT3
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_SCRATCH
imm32 r1,8 + (SCREEN_X * 40)
add r0,r10,r1 ; Place Text At XY Position 8,40
PrintText SCRATCHText, 14

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SCRATCH
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4
PrintText SCRATCHREGText, 19

; V3D_L2CACTL
PrintText L2CACTLText, 15
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_L2CACTL
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_L2CACTL
imm32 r2,TextMEM
ldr r3,[r1]
and r3,L2CENA
str r3,[r2]
PrintText L2CENAText, 8
PrintValueLE TextMEM, 1

; V3D_INTCTL
imm32 r1,8 + (SCREEN_X * 48)
add r0,r10,r1 ; Place Text At XY Position 8,48
PrintText INTCTLText, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_INTCTL
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_INTCTL
imm32 r2,TextMEM
ldr r3,[r1]
and r3,INT_FRDONE
str r3,[r2]
PrintText FRDONEText, 8
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_INTCTL
imm32 r2,TextMEM
ldr r3,[r1]
and r3,INT_FLDONE
mov r3,r3,lsr 1
str r3,[r2]
PrintText FLDONEText, 8
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_INTCTL
imm32 r2,TextMEM
ldr r3,[r1]
and r3,INT_OUTOMEM
mov r3,r3,lsr 2
str r3,[r2]
PrintText OUTOMEMText, 9
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_INTCTL
imm32 r2,TextMEM
ldr r3,[r1]
and r3,INT_SPILLUSE
mov r3,r3,lsr 3
str r3,[r2]
PrintText SPILLUSEText, 10
PrintValueLE TextMEM, 1

; V3D_INTENA
imm32 r1,8 + (SCREEN_X * 56)
add r0,r10,r1 ; Place Text At XY Position 8,56
PrintText INTENAText, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_INTENA
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_INTENA
imm32 r2,TextMEM
ldr r3,[r1]
and r3,INT_FRDONE
str r3,[r2]
PrintText FRDONEText, 8
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_INTENA
imm32 r2,TextMEM
ldr r3,[r1]
and r3,INT_FLDONE
mov r3,r3,lsr 1
str r3,[r2]
PrintText FLDONEText, 8
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_INTENA
imm32 r2,TextMEM
ldr r3,[r1]
and r3,INT_OUTOMEM
mov r3,r3,lsr 2
str r3,[r2]
PrintText OUTOMEMText, 9
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_INTENA
imm32 r2,TextMEM
ldr r3,[r1]
and r3,INT_SPILLUSE
mov r3,r3,lsr 3
str r3,[r2]
PrintText SPILLUSEText, 10
PrintValueLE TextMEM, 1

; V3D_INTDIS
imm32 r1,8 + (SCREEN_X * 64)
add r0,r10,r1 ; Place Text At XY Position 8,64
PrintText INTDISText, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_INTDIS
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_INTDIS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,INT_FRDONE
str r3,[r2]
PrintText FRDONEText, 8
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_INTDIS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,INT_FLDONE
mov r3,r3,lsr 1
str r3,[r2]
PrintText FLDONEText, 8
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_INTDIS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,INT_OUTOMEM
mov r3,r3,lsr 2
str r3,[r2]
PrintText OUTOMEMText, 9
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_INTDIS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,INT_SPILLUSE
mov r3,r3,lsr 3
str r3,[r2]
PrintText SPILLUSEText, 10
PrintValueLE TextMEM, 1

; V3D_CT0CS
imm32 r1,8 + (SCREEN_X * 72)
add r0,r10,r1 ; Place Text At XY Position 8,72
PrintText CT0CSText, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT0CS
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT0CS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,CTMODE
str r3,[r2]
PrintText MODEText, 6
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT0CS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,CTERR
mov r3,r3,lsr 3
str r3,[r2]
PrintText ERRText, 5
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT0CS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,CTSUBS
mov r3,r3,lsr 4
str r3,[r2]
PrintText SUBSText, 6
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT0CS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,CTRUN
mov r3,r3,lsr 5
str r3,[r2]
PrintText RUNText, 5
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT0CS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,CTRTSD
mov r3,r3,lsr 8
str r3,[r2]
PrintText RTSDText, 6
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT0CS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,CTSEMA
mov r3,r3,lsr 12
str r3,[r2]
PrintText SEMAText, 6
PrintValueLE TextMEM, 1

; V3D_CT1CS
imm32 r1,8 + (SCREEN_X * 80)
add r0,r10,r1 ; Place Text At XY Position 8,80
PrintText CT1CSText, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT1CS
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT1CS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,CTMODE
str r3,[r2]
PrintText MODEText, 6
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT1CS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,CTERR
mov r3,r3,lsr 3
str r3,[r2]
PrintText ERRText, 5
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT1CS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,CTSUBS
mov r3,r3,lsr 4
str r3,[r2]
PrintText SUBSText, 6
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT1CS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,CTRUN
mov r3,r3,lsr 5
str r3,[r2]
PrintText RUNText, 5
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT1CS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,CTRTSD
mov r3,r3,lsr 8
str r3,[r2]
PrintText RTSDText, 6
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT1CS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,CTSEMA
mov r3,r3,lsr 12
str r3,[r2]
PrintText SEMAText, 6
PrintValueLE TextMEM, 1

; V3D_CT0EA
imm32 r1,8 + (SCREEN_X * 88)
add r0,r10,r1 ; Place Text At XY Position 8,88
PrintText CT0EAText, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT0EA
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_CT1EA
PrintText CT1EAText, 14
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT1EA
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4
PrintText ThreadEndAddressText, 25

; V3D_CT0CA
imm32 r1,8 + (SCREEN_X * 96)
add r0,r10,r1 ; Place Text At XY Position 8,96
PrintText CT0CAText, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT0CA
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_CT1CA
PrintText CT1CAText, 14
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT1CA
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4
PrintText ThreadCurrentAddressText, 29

; V3D_CT0RA0
imm32 r1,8 + (SCREEN_X * 104)
add r0,r10,r1 ; Place Text At XY Position 8,104
PrintText CT0RA0Text, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT0RA0
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_CT1RA0
PrintText CT1RA0Text, 14
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT1RA0
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4
PrintText ThreadReturnAddressText, 28

; V3D_CT0LC
imm32 r1,8 + (SCREEN_X * 112)
add r0,r10,r1 ; Place Text At XY Position 8,112
PrintText CT0LCText, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT0LC
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT0LC
imm32 r2,TextMEM
ldr r3,[r1]
imm16 r4,CTLSLCS
and r3,r4
str r3,[r2]
PrintText LSLCSText, 7
PrintValueLE TextMEM, 2

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT0LC
imm32 r2,TextMEM
ldr r3,[r1]
mov r3,r3,lsr 16
str r3,[r2]
PrintText LLCMText, 7
PrintValueLE TextMEM, 2
PrintText Thread0ListCounterText, 24

; V3D_CT1LC
imm32 r1,8 + (SCREEN_X * 120)
add r0,r10,r1 ; Place Text At XY Position 8,120
PrintText CT1LCText, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT1LC
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT1LC
imm32 r2,TextMEM
ldr r3,[r1]
imm16 r4,CTLSLCS
and r3,r4
str r3,[r2]
PrintText LSLCSText, 7
PrintValueLE TextMEM, 2

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT1LC
imm32 r2,TextMEM
ldr r3,[r1]
mov r3,r3,lsr 16
str r3,[r2]
PrintText LLCMText, 7
PrintValueLE TextMEM, 2
PrintText Thread1ListCounterText, 24

; V3D_CT0PC
imm32 r1,8 + (SCREEN_X * 128)
add r0,r10,r1 ; Place Text At XY Position 8,128
PrintText CT0PCText, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT0PC
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_CT1PC
PrintText CT1PCText, 14
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_CT1PC
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4
PrintText ThreadPrimitiveListCounterText, 36

; V3D_PCS
imm32 r1,8 + (SCREEN_X * 136)
add r0,r10,r1 ; Place Text At XY Position 8,136
PrintText PCSText, 11

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCS
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,BMACTIVE
str r3,[r2]
PrintText BMACTIVEText, 10
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,BMBUSY
mov r3,r3,lsr 1
str r3,[r2]
PrintText BMBUSYText, 8
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,RMACTIVE
mov r3,r3,lsr 2
str r3,[r2]
PrintText RMACTIVEText, 10
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,RMBUSY
mov r3,r3,lsr 3
str r3,[r2]
PrintText RMBUSYText, 8
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,BMOOM
mov r3,r3,lsr 8
str r3,[r2]
PrintText BMOOMText, 7
PrintValueLE TextMEM, 1

; V3D_BFC
imm32 r1,8 + (SCREEN_X * 144)
add r0,r10,r1 ; Place Text At XY Position 8,144
PrintText BFCText, 11

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_BFC
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_BFC
imm32 r2,TextMEM
ldr r3,[r1]
and r3,BMFCT
str r3,[r2]
PrintText BMFCTText, 7
PrintValueLE TextMEM, 1

; V3D_RFC
PrintText RFCText, 11
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_RFC
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_RFC
imm32 r2,TextMEM
ldr r3,[r1]
and r3,RMFCT
str r3,[r2]
PrintText RMFCTText, 7
PrintValueLE TextMEM, 1

; V3D_BPCA
imm32 r1,8 + (SCREEN_X * 152)
add r0,r10,r1 ; Place Text At XY Position 8,152
PrintText BPCAText, 11

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_BPCA
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_BPCS
PrintText BPCSText, 12
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_BPCS
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4
PrintText AddressSizeBinningMemPoolText, 32

; V3D_BPOA
imm32 r1,8 + (SCREEN_X * 160)
add r0,r10,r1 ; Place Text At XY Position 8,160
PrintText BPOAText, 11

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_BPOA
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_BPOS
PrintText BPOSText, 12
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_BPOS
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4
PrintText AddressSizeOverspillBinningMemText, 37

; V3D_BXCF
imm32 r1,8 + (SCREEN_X * 168)
add r0,r10,r1 ; Place Text At XY Position 8,168
PrintText BXCFText, 11

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_BXCF
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_BXCF
imm32 r2,TextMEM
ldr r3,[r1]
and r3,FWDDISA
str r3,[r2]
PrintText FWDDISAText, 9
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_BXCF
imm32 r2,TextMEM
ldr r3,[r1]
and r3,CLIPDISA
mov r3,r3,lsr 1
str r3,[r2]
PrintText CLIPDISAText, 10
PrintValueLE TextMEM, 1
PrintText BinnerDebugText, 15

; V3D_SQRSV0
imm32 r1,8 + (SCREEN_X * 176)
add r0,r10,r1 ; Place Text At XY Position 8,176
PrintText SQRSV0Text, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SQRSV0
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SQRSV0
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QPURSV0
str r3,[r2]
PrintText R00Text, 5
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SQRSV0
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QPURSV1
mov r3,r3,lsr 4
str r3,[r2]
PrintText R01Text, 5
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SQRSV0
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QPURSV2
mov r3,r3,lsr 8
str r3,[r2]
PrintText R02Text, 5
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SQRSV0
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QPURSV3
mov r3,r3,lsr 12
str r3,[r2]
PrintText R03Text, 5
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SQRSV0
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QPURSV4
mov r3,r3,lsr 16
str r3,[r2]
PrintText R04Text, 5
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SQRSV0
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QPURSV5
mov r3,r3,lsr 20
str r3,[r2]
PrintText R05Text, 5
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SQRSV0
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QPURSV6
mov r3,r3,lsr 24
str r3,[r2]
PrintText R06Text, 5
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SQRSV0
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QPURSV7
mov r3,r3,lsr 28
str r3,[r2]
PrintText R07Text, 5
PrintValueLE TextMEM, 1

; V3D_SQRSV1
imm32 r1,8 + (SCREEN_X * 184)
add r0,r10,r1 ; Place Text At XY Position 8,184
PrintText SQRSV1Text, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SQRSV1
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SQRSV1
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QPURSV8
str r3,[r2]
PrintText R08Text, 5
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SQRSV1
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QPURSV9
mov r3,r3,lsr 4
str r3,[r2]
PrintText R09Text, 5
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SQRSV1
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QPURSV10
mov r3,r3,lsr 8
str r3,[r2]
PrintText R10Text, 5
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SQRSV1
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QPURSV11
mov r3,r3,lsr 12
str r3,[r2]
PrintText R11Text, 5
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SQRSV1
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QPURSV12
mov r3,r3,lsr 16
str r3,[r2]
PrintText R12Text, 5
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SQRSV1
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QPURSV13
mov r3,r3,lsr 20
str r3,[r2]
PrintText R13Text, 5
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SQRSV1
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QPURSV14
mov r3,r3,lsr 24
str r3,[r2]
PrintText R14Text, 5
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SQRSV1
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QPURSV15
mov r3,r3,lsr 28
str r3,[r2]
PrintText R15Text, 5
PrintValueLE TextMEM, 1

; V3D_SQCNTL
imm32 r1,8 + (SCREEN_X * 192)
add r0,r10,r1 ; Place Text At XY Position 8,192
PrintText SQCNTLText, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SQCNTL
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SQCNTL
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VSRBL
str r3,[r2]
PrintText VSRBLText, 7
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SQCNTL
imm32 r2,TextMEM
ldr r3,[r1]
and r3,CSRBL
mov r3,r3,lsr 2
str r3,[r2]
PrintText CSRBLText, 7
PrintValueLE TextMEM, 1

; V3D_SQCSTAT
PrintText SQCSTATText, 15
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SQCSTAT
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_SRQUA
imm32 r1,8 + (SCREEN_X * 200)
add r0,r10,r1 ; Place Text At XY Position 8,200
PrintText SRQUAText, 12

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SRQUA
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_SRQUL
PrintText SRQULText, 13
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SRQUL
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SRQUL
imm32 r2,TextMEM
ldr r3,[r1]
imm16 r4,QPURQUL
and r3,r4
str r3,[r2]
PrintText RQULText, 6
PrintValueLE TextMEM, 2
PrintText UniformsText, 26

; V3D_SRQCS
imm32 r1,8 + (SCREEN_X * 208)
add r0,r10,r1 ; Place Text At XY Position 8,208
PrintText SRQCSText, 12

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SRQCS
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SRQCS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QPURQL
str r3,[r2]
PrintText QPURQLText, 8
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SRQCS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QPURQERR
mov r3,r3,lsr 7
str r3,[r2]
PrintText QPURQERRText, 10
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SRQCS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QPURQCM
mov r3,r3,lsr 8
str r3,[r2]
PrintText QPURQCMText, 9
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_SRQCS
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QPURQCC
mov r3,r3,lsr 16
str r3,[r2]
PrintText QPURQCCText, 9
PrintValueLE TextMEM, 1

; V3D_VPACNTL
imm32 r1,8 + (SCREEN_X * 216)
add r0,r10,r1 ; Place Text At XY Position 8,216
PrintText VPACNTLText, 14

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_VPACNTL
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_VPACNTL
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VPARALIM
str r3,[r2]
PrintText RALIMText, 7
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_VPACNTL
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VPABALIM
mov r3,r3,lsr 3
str r3,[r2]
PrintText BALIMText, 7
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_VPACNTL
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VPARATO
mov r3,r3,lsr 6
str r3,[r2]
PrintText RATOText, 6
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_VPACNTL
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VPABATO
mov r3,r3,lsr 9
str r3,[r2]
PrintText BATOText, 6
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_VPACNTL
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VPALIMEN
mov r3,r3,lsr 12
str r3,[r2]
PrintText LIMENText, 7
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_VPACNTL
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VPATOEN
mov r3,r3,lsr 13
str r3,[r2]
PrintText TOENText, 6
PrintValueLE TextMEM, 1

; V3D_VPMBASE
imm32 r1,8 + (SCREEN_X * 224)
add r0,r10,r1 ; Place Text At XY Position 8,224
PrintText VPMBASEText, 14

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_VPMBASE
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_VPMBASE
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VPMURSV
str r3,[r2]
PrintText VPMURSVText, 9
PrintValueLE TextMEM, 1
PrintText VPMBaseMemoryReservationText, 30

; V3D_PCTRE
imm32 r1,8 + (SCREEN_X * 232)
add r0,r10,r1 ; Place Text At XY Position 8,232
PrintText PCTREText, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTRE
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTRE
imm32 r2,TextMEM
ldr r3,[r1]
imm16 r4,CTEN0_CTEN15
and r3,r4
str r3,[r2]
PrintText CTEN0_CTEN15Text, 14
PrintValueLE TextMEM, 2
PrintText PerformanceCounterEnablesText, 30

; V3D_PCTR0
imm32 r1,8 + (SCREEN_X * 240)
add r0,r10,r1 ; Place Text At XY Position 8,240
PrintText PCTR0Text, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTR0
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_PCTRS0
PrintText PCTRS0Text, 15
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTRS0
imm32 r2,TextMEM
ldr r3,[r1]
and r3,PCTRS
str r3,[r2]
PrintValueLE TextMEM, 1

; V3D_PCTR1
PrintText PCTR1Text, 14
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTR1
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_PCTRS1
PrintText PCTRS1Text, 15
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTRS1
imm32 r2,TextMEM
ldr r3,[r1]
and r3,PCTRS
str r3,[r2]
PrintValueLE TextMEM, 1

; V3D_PCTR2
imm32 r1,8 + (SCREEN_X * 248)
add r0,r10,r1 ; Place Text At XY Position 8,248
PrintText PCTR2Text, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTR2
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_PCTRS2
PrintText PCTRS2Text, 15
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTRS2
imm32 r2,TextMEM
ldr r3,[r1]
and r3,PCTRS
str r3,[r2]
PrintValueLE TextMEM, 1

; V3D_PCTR3
PrintText PCTR3Text, 14
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTR3
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_PCTRS3
PrintText PCTRS3Text, 15
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTRS3
imm32 r2,TextMEM
ldr r3,[r1]
and r3,PCTRS
str r3,[r2]
PrintValueLE TextMEM, 1

; V3D_PCTR4
imm32 r1,8 + (SCREEN_X * 256)
add r0,r10,r1 ; Place Text At XY Position 8,256
PrintText PCTR4Text, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTR4
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_PCTRS4
PrintText PCTRS4Text, 15
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTRS4
imm32 r2,TextMEM
ldr r3,[r1]
and r3,PCTRS
str r3,[r2]
PrintValueLE TextMEM, 1

; V3D_PCTR5
PrintText PCTR5Text, 14
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTR5
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_PCTRS5
PrintText PCTRS5Text, 15
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTRS5
imm32 r2,TextMEM
ldr r3,[r1]
and r3,PCTRS
str r3,[r2]
PrintValueLE TextMEM, 1

; V3D_PCTR6
imm32 r1,8 + (SCREEN_X * 264)
add r0,r10,r1 ; Place Text At XY Position 8,264
PrintText PCTR6Text, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTR6
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_PCTRS6
PrintText PCTRS6Text, 15
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTRS6
imm32 r2,TextMEM
ldr r3,[r1]
and r3,PCTRS
str r3,[r2]
PrintValueLE TextMEM, 1

; V3D_PCTR7
PrintText PCTR7Text, 14
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTR7
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_PCTRS7
PrintText PCTRS7Text, 15
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTRS7
imm32 r2,TextMEM
ldr r3,[r1]
and r3,PCTRS
str r3,[r2]
PrintValueLE TextMEM, 1

; V3D_PCTR8
imm32 r1,8 + (SCREEN_X * 272)
add r0,r10,r1 ; Place Text At XY Position 8,272
PrintText PCTR8Text, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTR8
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_PCTRS8
PrintText PCTRS8Text, 15
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTRS8
imm32 r2,TextMEM
ldr r3,[r1]
and r3,PCTRS
str r3,[r2]
PrintValueLE TextMEM, 1

; V3D_PCTR9
PrintText PCTR9Text, 14
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTR9
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_PCTRS9
PrintText PCTRS9Text, 15
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTRS9
imm32 r2,TextMEM
ldr r3,[r1]
and r3,PCTRS
str r3,[r2]
PrintValueLE TextMEM, 1

; V3D_PCTR10
imm32 r1,8 + (SCREEN_X * 280)
add r0,r10,r1 ; Place Text At XY Position 8,280
PrintText PCTR10Text, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTR10
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_PCTRS10
PrintText PCTRS10Text, 15
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTRS10
imm32 r2,TextMEM
ldr r3,[r1]
and r3,PCTRS
str r3,[r2]
PrintValueLE TextMEM, 1

; V3D_PCTR11
PrintText PCTR11Text, 14
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTR11
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_PCTRS11
PrintText PCTRS11Text, 15
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTRS11
imm32 r2,TextMEM
ldr r3,[r1]
and r3,PCTRS
str r3,[r2]
PrintValueLE TextMEM, 1

; V3D_PCTR12
imm32 r1,8 + (SCREEN_X * 288)
add r0,r10,r1 ; Place Text At XY Position 8,288
PrintText PCTR12Text, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTR12
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_PCTRS12
PrintText PCTRS12Text, 15
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTRS12
imm32 r2,TextMEM
ldr r3,[r1]
and r3,PCTRS
str r3,[r2]
PrintValueLE TextMEM, 1

; V3D_PCTR13
PrintText PCTR13Text, 14
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTR13
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_PCTRS13
PrintText PCTRS13Text, 15
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTRS13
imm32 r2,TextMEM
ldr r3,[r1]
and r3,PCTRS
str r3,[r2]
PrintValueLE TextMEM, 1

; V3D_PCTR14
imm32 r1,8 + (SCREEN_X * 296)
add r0,r10,r1 ; Place Text At XY Position 8,296
PrintText PCTR14Text, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTR14
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_PCTRS14
PrintText PCTRS14Text, 15
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTRS14
imm32 r2,TextMEM
ldr r3,[r1]
and r3,PCTRS
str r3,[r2]
PrintValueLE TextMEM, 1

; V3D_PCTR15
PrintText PCTR15Text, 14
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTR15
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_PCTRS15
PrintText PCTRS15Text, 15
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_PCTRS15
imm32 r2,TextMEM
ldr r3,[r1]
and r3,PCTRS
str r3,[r2]
PrintValueLE TextMEM, 1

; V3D_DBCFG
imm32 r1,8 + (SCREEN_X * 304)
add r0,r10,r1 ; Place Text At XY Position 8,304
PrintText DBCFGText, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBCFG
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_DBSCS
PrintText DBSCSText, 14
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBSCS
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_DBSCFG
imm32 r1,8 + (SCREEN_X * 312)
add r0,r10,r1 ; Place Text At XY Position 8,312
PrintText DBSCFGText, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBSCFG
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_DBSSR
PrintText DBSSRText, 14
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBSSR
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_DBSDR0
PrintText DBSDR0Text, 14
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBSDR0
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_DBSDR1
imm32 r1,8 + (SCREEN_X * 320)
add r0,r10,r1 ; Place Text At XY Position 8,320
PrintText DBSDR1Text, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBSDR1
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_DBSDR2
PrintText DBSDR2Text, 14
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBSDR2
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_DBSDR3
PrintText DBSDR3Text, 14
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBSDR3
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_DBQRUN
imm32 r1,8 + (SCREEN_X * 328)
add r0,r10,r1 ; Place Text At XY Position 8,328
PrintText DBQRUNText, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBQRUN
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_DBQHLT
PrintText DBQHLTText, 14
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBQHLT
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_DBQSTP
PrintText DBQSTPText, 14
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBQSTP
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_DBQITE
imm32 r1,8 + (SCREEN_X * 336)
add r0,r10,r1 ; Place Text At XY Position 8,336
PrintText DBQITEText, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBQITE
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBQITE
imm32 r2,TextMEM
ldr r3,[r1]
imm16 r4,IE_QPU0_to_IE_QPU15
and r3,r4
str r3,[r2]
PrintText IE_QPU0_to_IE_QPU15Text, 21
PrintValueLE TextMEM, 2
PrintText QPUInterruptEnablesText, 24

; V3D_DBQITC
imm32 r1,8 + (SCREEN_X * 344)
add r0,r10,r1 ; Place Text At XY Position 8,344
PrintText DBQITCText, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBQITC
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBQITC
imm32 r2,TextMEM
ldr r3,[r1]
imm16 r4,IC_QPU0_to_IC_QPU15
and r3,r4
str r3,[r2]
PrintText IC_QPU0_to_IC_QPU15Text, 21
PrintValueLE TextMEM, 2
PrintText QPUInterruptControlText, 24

; V3D_DBQGHC
imm32 r1,8 + (SCREEN_X * 352)
add r0,r10,r1 ; Place Text At XY Position 8,352
PrintText DBQGHCText, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBQGHC
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_DBQGHG
PrintText DBQGHGText, 14
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBQGHG
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_DBQGHH
PrintText DBQGHHText, 14
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBQGHH
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

; V3D_DBGE
imm32 r1,8 + (SCREEN_X * 360)
add r0,r10,r1 ; Place Text At XY Position 8,360
PrintText DBGEText, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBGE
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBGE
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VR1_A
mov r3,r3,lsr 1
str r3,[r2]
PrintText VR1_AText, 7
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBGE
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VR1_A
mov r3,r3,lsr 2
str r3,[r2]
PrintText VR1_BText, 7
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBGE
imm32 r2,TextMEM
ldr r3,[r1]
and r3,MULIP0
mov r3,r3,lsr 16
str r3,[r2]
PrintText MULIP0Text, 8
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBGE
imm32 r2,TextMEM
ldr r3,[r1]
and r3,MULIP1
mov r3,r3,lsr 17
str r3,[r2]
PrintText MULIP1Text, 8
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBGE
imm32 r2,TextMEM
ldr r3,[r1]
and r3,MULIP2
mov r3,r3,lsr 18
str r3,[r2]
PrintText MULIP2Text, 8
PrintValueLE TextMEM, 1

imm32 r1,328 + (SCREEN_X * 368)
add r0,r10,r1 ; Place Text At XY Position 328,368
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBGE
imm32 r2,TextMEM
ldr r3,[r1]
and r3,IPD2_VALID
mov r3,r3,lsr 19
str r3,[r2]
PrintText IPD2_VALIDText, 11
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_DBGE
imm32 r2,TextMEM
ldr r3,[r1]
and r3,IPD2_FPDUSED
mov r3,r3,lsr 20
str r3,[r2]
PrintText IPD2_FPDUSEDText, 14
PrintValueLE TextMEM, 1

; V3D_FDBGO
imm32 r1,8 + (SCREEN_X * 376)
add r0,r10,r1 ; Place Text At XY Position 8,376
PrintText FDBGOText, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGO
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGO
imm32 r2,TextMEM
ldr r3,[r1]
and r3,WCOEFF_FIFO_FULL
mov r3,r3,lsr 1
str r3,[r2]
PrintText WCOEFF_FIFO_FULLText, 18
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGO
imm32 r2,TextMEM
ldr r3,[r1]
and r3,XYRELZ_FIFO_FULL
mov r3,r3,lsr 2
str r3,[r2]
PrintText XYRELZ_FIFO_FULLText, 18
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGO
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QBFR_FIFO_ORUN
mov r3,r3,lsr 3
str r3,[r2]
PrintText QBFR_FIFO_ORUNText, 16
PrintValueLE TextMEM, 1

imm32 r1,96 + (SCREEN_X * 384)
add r0,r10,r1 ; Place Text At XY Position 96,384
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGO
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QBSZ_FIFO_ORUN
mov r3,r3,lsr 4
str r3,[r2]
PrintText QBSZ_FIFO_ORUNText, 15
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGO
imm32 r2,TextMEM
ldr r3,[r1]
and r3,XYFO_FIFO_ORUN
mov r3,r3,lsr 5
str r3,[r2]
PrintText XYFO_FIFO_ORUNText, 16
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGO
imm32 r2,TextMEM
ldr r3,[r1]
and r3,FIXZ_ORUN
mov r3,r3,lsr 6
str r3,[r2]
PrintText FIXZ_ORUNText, 11
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGO
imm32 r2,TextMEM
ldr r3,[r1]
and r3,XYRELO_FIFO_ORUN
mov r3,r3,lsr 7
str r3,[r2]
PrintText XYRELO_FIFO_ORUNText, 18
PrintValueLE TextMEM, 1

imm32 r1,16 + (SCREEN_X * 392)
add r0,r10,r1 ; Place Text At XY Position 16,392
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGO
imm32 r2,TextMEM
ldr r3,[r1]
and r3,XYRELW_FIFO_ORUN
mov r3,r3,lsr 10
str r3,[r2]
PrintText XYRELW_FIFO_ORUNText, 17
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGO
imm32 r2,TextMEM
ldr r3,[r1]
and r3,ZCOEFF_FIFO_FULL
mov r3,r3,lsr 11
str r3,[r2]
PrintText ZCOEFF_FIFO_FULLText, 18
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGO
imm32 r2,TextMEM
ldr r3,[r1]
and r3,REFXY_FIFO_ORUN
mov r3,r3,lsr 12
str r3,[r2]
PrintText REFXY_FIFO_ORUNText, 17
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGO
imm32 r2,TextMEM
ldr r3,[r1]
and r3,DEPTHO_FIFO_ORUN
mov r3,r3,lsr 13
str r3,[r2]
PrintText DEPTHO_FIFO_ORUNText, 18
PrintValueLE TextMEM, 1

imm32 r1,224 + (SCREEN_X * 400)
add r0,r10,r1 ; Place Text At XY Position 224,400
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGO
imm32 r2,TextMEM
ldr r3,[r1]
and r3,DEPTHO_ORUN
mov r3,r3,lsr 14
str r3,[r2]
PrintText DEPTHO_ORUNText, 12
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGO
imm32 r2,TextMEM
ldr r3,[r1]
and r3,EZVAL_FIFO_ORUN
mov r3,r3,lsr 15
str r3,[r2]
PrintText EZVAL_FIFO_ORUNText, 17
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGO
imm32 r2,TextMEM
ldr r3,[r1]
and r3,EZREQ_FIFO_ORUN
mov r3,r3,lsr 17
str r3,[r2]
PrintText EZREQ_FIFO_ORUNText, 17
PrintValueLE TextMEM, 1

; V3D_FDBGB
imm32 r1,8 + (SCREEN_X * 408)
add r0,r10,r1 ; Place Text At XY Position 8,408
PrintText FDBGBText, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGB
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGB
imm32 r2,TextMEM
ldr r3,[r1]
and r3,EDGES_STALL
str r3,[r2]
PrintText EDGES_STALLText, 13
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGB
imm32 r2,TextMEM
ldr r3,[r1]
and r3,EDGES_READY
mov r3,r3,lsr 1
str r3,[r2]
PrintText EDGES_READYText, 13
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGB
imm32 r2,TextMEM
ldr r3,[r1]
and r3,EDGES_ISCTRL
mov r3,r3,lsr 2
str r3,[r2]
PrintText EDGES_ISCTRLText, 14
PrintValueLE TextMEM, 1

imm32 r1,144 + (SCREEN_X * 416)
add r0,r10,r1 ; Place Text At XY Position 144,416
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGB
imm32 r2,TextMEM
ldr r3,[r1]
and r3,EDGES_CTRLID
mov r3,r3,lsr 3
str r3,[r2]
PrintText EDGES_CTRLIDText, 13
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGB
imm32 r2,TextMEM
ldr r3,[r1]
and r3,ZRWPE_STALL
mov r3,r3,lsr 6
str r3,[r2]
PrintText ZRWPE_STALLText, 13
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGB
imm32 r2,TextMEM
ldr r3,[r1]
and r3,ZRWPE_READY
mov r3,r3,lsr 7
str r3,[r2]
PrintText ZRWPE_READYText, 13
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGB
imm32 r2,TextMEM
ldr r3,[r1]
and r3,EZ_DATA_READY
mov r3,r3,lsr 23
str r3,[r2]
PrintText EZ_DATA_READYText, 15
PrintValueLE TextMEM, 1

imm32 r1,72 + (SCREEN_X * 424)
add r0,r10,r1 ; Place Text At XY Position 72,424
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGB
imm32 r2,TextMEM
ldr r3,[r1]
and r3,EZ_XY_READY
mov r3,r3,lsr 25
str r3,[r2]
PrintText EZ_XY_READYText, 12
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGB
imm32 r2,TextMEM
ldr r3,[r1]
and r3,RAST_BUSY
mov r3,r3,lsr 26
str r3,[r2]
PrintText RAST_BUSYText, 11
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGB
imm32 r2,TextMEM
ldr r3,[r1]
and r3,QXYF_FIFO_OP_READY
mov r3,r3,lsr 27
str r3,[r2]
PrintText QXYF_FIFO_OP_READYText, 20
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGB
imm32 r2,TextMEM
ldr r3,[r1]
and r3,XYFO_FIFO_OP_READY
mov r3,r3,lsr 28
str r3,[r2]
PrintText XYFO_FIFO_OP_READYText, 20
PrintValueLE TextMEM, 1

; V3D_FDBGR
imm32 r1,8 + (SCREEN_X * 432)
add r0,r10,r1 ; Place Text At XY Position 8,432
PrintText FDBGRText, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGR
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4
PrintText FEPInternalReadySignalsText, 29

; V3D_FDBGS
imm32 r1,8 + (SCREEN_X * 440)
add r0,r10,r1 ; Place Text At XY Position 8,440
PrintText FDBGSText, 13

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_FDBGS
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4
PrintText FEPInternalStallInputSignalsText, 35

; V3D_ERRSTAT
imm32 r1,8 + (SCREEN_X * 448)
add r0,r10,r1 ; Place Text At XY Position 8,448
PrintText ERRSTATText, 15

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_ERRSTAT
imm32 r2,TextMEM
ldr r3,[r1]
str r3,[r2]
PrintValueLE TextMEM, 4

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_ERRSTAT
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VPAEABB
str r3,[r2]
PrintText VPAEABBText, 9
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_ERRSTAT
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VPAERGS
mov r3,r3,lsr 1
str r3,[r2]
PrintText VPAERGSText, 9
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_ERRSTAT
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VPAEBRGL
mov r3,r3,lsr 2
str r3,[r2]
PrintText VPAEBRGLText, 10
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_ERRSTAT
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VPAERRGL
mov r3,r3,lsr 3
str r3,[r2]
PrintText VPAERRGLText, 10
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_ERRSTAT
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VPMEWR
mov r3,r3,lsr 4
str r3,[r2]
PrintText VPMEWRText, 8
PrintValueLE TextMEM, 1

imm32 r1,32 + (SCREEN_X * 456)
add r0,r10,r1 ; Place Text At XY Position 32,456
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_ERRSTAT
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VPMERR
mov r3,r3,lsr 5
str r3,[r2]
PrintText VPMERRText, 7
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_ERRSTAT
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VPMERNA
mov r3,r3,lsr 6
str r3,[r2]
PrintText VPMERNAText, 9
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_ERRSTAT
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VPMEWNA
mov r3,r3,lsr 7
str r3,[r2]
PrintText VPMEWNAText, 9
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_ERRSTAT
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VPMEFNA
mov r3,r3,lsr 8
str r3,[r2]
PrintText VPMEFNAText, 9
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_ERRSTAT
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VPMEAS
mov r3,r3,lsr 9
str r3,[r2]
PrintText VPMEASText, 8
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_ERRSTAT
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VDWE
mov r3,r3,lsr 10
str r3,[r2]
PrintText VDWEText, 6
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_ERRSTAT
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VCDE
mov r3,r3,lsr 11
str r3,[r2]
PrintText VCDEText, 6
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_ERRSTAT
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VCDI
mov r3,r3,lsr 12
str r3,[r2]
PrintText VCDIText, 6
PrintValueLE TextMEM, 1

imm32 r1,424 + (SCREEN_X * 464)
add r0,r10,r1 ; Place Text At XY Position 424,464
imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_ERRSTAT
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VCMRE
mov r3,r3,lsr 13
str r3,[r2]
PrintText VCMREText, 6
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_ERRSTAT
imm32 r2,TextMEM
ldr r3,[r1]
and r3,VCMBE
mov r3,r3,lsr 14
str r3,[r2]
PrintText VCMBEText, 7
PrintValueLE TextMEM, 1

imm32 r1,PERIPHERAL_BASE + V3D_BASE + V3D_ERRSTAT
imm32 r2,TextMEM
ldr r3,[r1]
and r3,L2CARE
mov r3,r3,lsr 15
str r3,[r2]
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

align 32
CB_STRUCT: ; Control Block Data Structure
  dw DMA_TDMODE + DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
CB_SOURCE:
  dw 0 ; DMA Source Address
CB_DEST:
  dw 0 ; DMA Destination Address
  dw CHAR_X + ((CHAR_Y - 1) * 65536) ; DMA Transfer Length
  dw (SCREEN_X - CHAR_X) * 65536 ; DMA 2D Mode Stride
  dw 0 ; DMA Next Control Block Address

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
Font: include 'Font8x8.asm'