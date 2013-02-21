; Raspberry Pi 'Bare Metal' Input SNES Controller Debug Demo by krom (Peter Lemon):
; 1. Setup Frame Buffer
; 2. Initialize & Update Input Data
; 3. Print RAW Hex Values To Screen

macro PrintText Text, TextLength {
  local .DrawChars,.DMAWait
  imm32 r1,Font ; R1 = Characters
  imm32 r2,Text ; R2 = Text Offset
  imm32 r3,CB_STRUCT ; R3 = Control Block Data
  imm32 r4,PERIPHERAL_BASE + DMA0_BASE ; R4 = DMA 0 Base
  mov r5,DMA_ACTIVE ; R5 = DMA Active Bit
  mov r6,TextLength ; R6 = Number of Text Characters to Print
  .DrawChars:
    ldrb r7,[r2],1 ; R7 = Next Text Character
    add r7,r1,r7,lsl 6 ; Add Shift to Correct Position in Font (* 64)
    str r7,[r3,CB_SOURCE - CB_STRUCT] ; Store DMA Source Address
    str r0,[r3,CB_DEST - CB_STRUCT] ; Store DMA Destination Address
    str r3,[r4,DMA0_CONBLK_AD] ; Store DMA Control Block Data Address
    str r5,[r4,DMA0_CS] ; Print Next Text Character to the Screen
    .DMAWait:
      ldr r7,[r4,DMA0_CS] ; Load Control Block Status
      tst r7,r5 ; Test Active bit
      bne .DMAWait ; Wait Until DMA Has Finished

    subs r6,1 ; Subtract Number of Text Characters to Print
    add r0,CHAR_X * (BITS_PER_PIXEL / 8)
    bne .DrawChars ; Continue to Print Characters
}

macro PrintValueLE Value, ValueLength {
  local .DrawHEXChars,.DMAHEXWait,.DMAHEXWaitB
  imm32 r2,Value ; R2 = Text Offset
  add r2,ValueLength - 1
  mov r6,ValueLength ; R6 = Number of HEX Characters to Print
  .DrawHEXChars:
    ldrb r7,[r2],-1 ; R7 = Next 2 HEX Characters
    mov r8,r7,lsr 4 ; Get 2nd Nibble
    cmp r8,$9
    addle r8,$30
    addgt r8,$37
    add r8,r1,r8,lsl 6 ; Add Shift to Correct Position in Font (* 64)
    str r8,[r3,CB_SOURCE - CB_STRUCT] ; Store DMA Source Address
    str r0,[r3,CB_DEST - CB_STRUCT] ; Store DMA Destination Address
    str r3,[r4,DMA0_CONBLK_AD] ; Store DMA Control Block Data Address
    str r5,[r4,DMA0_CS] ; Print Next Text Character to the Screen
    .DMAHEXWait:
      ldr r8,[r4,DMA0_CS] ; Load Control Block Status
      tst r8,r5 ; Test Active bit
      bne .DMAHEXWait ; Wait Until DMA Has Finished

    add r0,CHAR_X * (BITS_PER_PIXEL / 8)
    and r8,r7,$F ; Get 1st Nibble
    cmp r8,$9
    addle r8,$30
    addgt r8,$37
    add r8,r1,r8,lsl 6 ; Add Shift to Correct Position in Font (* 64)
    str r8,[r3,CB_SOURCE - CB_STRUCT] ; Store DMA Source Address
    str r0,[r3,CB_DEST - CB_STRUCT] ; Store DMA Destination Address
    str r3,[r4,DMA0_CONBLK_AD] ; Store DMA Control Block Data Address
    str r5,[r4,DMA0_CS] ; Print Next Text Character to the Screen
    .DMAHEXWaitB:
      ldr r8,[r4,DMA0_CS] ; Load Control Block Status
      tst r8,r5 ; Test Active bit
      bne .DMAHEXWaitB ; Wait Until DMA Has Finished

    subs r6,1 ; Subtract Number of HEX Characters to Print
    add r0,CHAR_X * (BITS_PER_PIXEL / 8)
    bne .DrawHEXChars ; Continue to Print Characters
}

macro PrintTAGValueLE Text, TextLength, Value, ValueLength {
  PrintText Text, TextLength
  PrintValueLE Value, ValueLength
}

macro Delay amount {
  local .DelayLoop
  imm32 r12,amount
  .DelayLoop:
    subs r12,1
    bne .DelayLoop
}

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

imm32 r0,PERIPHERAL_BASE + DMA_ENABLE ; Set DMA Channel 0 Enable Bit
mov r1,DMA_EN0
str r1,[r0]

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

;;;;;;;;;;;;;;;;;;;;;;
;; Initialize Input ;;
;;;;;;;;;;;;;;;;;;;;;;
; Set GPIO 10 & 11 (Clock & Latch) Function To Output
imm32 r0,PERIPHERAL_BASE + GPIO_BASE
mov r1,GPIO_FSEL0_OUT + GPIO_FSEL1_OUT
str r1,[r0,GPIO_GPFSEL1]

;;;;;;;;;;;;;;;;;;
;; Update Input ;;
;;;;;;;;;;;;;;;;;;
UpdateInput:
  imm32 r0,PERIPHERAL_BASE + GPIO_BASE ; Set GPIO 11 (Latch) Output State To HIGH
  mov r1,GPIO_11
  str r1,[r0,GPIO_GPSET0]
  Delay 3

  mov r1,GPIO_11 ; Set GPIO 11 (Latch) Output State To LOW
  str r1,[r0,GPIO_GPCLR0]
  Delay 3

  mov r1,0  ; R1 = Input Data
  mov r2,15 ; R2 = Input Data Count
  LoopInputData:
    ldr r3,[r0,GPIO_GPLEV0] ; Get GPIO 4 (Data) Level
    tst r3,GPIO_4
    moveq r3,1 ; GPIO 4 (Data) Level LOW
    orreq r1,r3,lsl r2

    mov r3,GPIO_10 ; Set GPIO 10 (Clock) Output State To HIGH
    str r3,[r0,GPIO_GPSET0]
    Delay 3

    mov r3,GPIO_10 ; Set GPIO 10 (Clock) Output State To LOW
    str r3,[r0,GPIO_GPCLR0]
    Delay 3

    subs r2,1
    bge LoopInputData ; Loop 16bit Data

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; R1 Now Contains Input Data ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
str r1,[DataValue]

adr r1,FB_POINTER
ldr r0,[r1] ; R0 = Frame Buffer Pointer
imm32 r1,(320 * 50) + 160
add r0,r1
PrintTAGValueLE Text, 22, DataValue, 2

b UpdateInput ; Refresh Input Data

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

align 256
CB_STRUCT: ; Control Block Data Structure
  dw DMA_TDMODE + DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
CB_SOURCE:
  dw 0 ; DMA Source Address
CB_DEST:
  dw 0 ; DMA Destination Address
  dw (CHAR_X * (BITS_PER_PIXEL / 8)) + ((CHAR_Y - 1) * 65536) ; DMA Transfer Length
  dw ((SCREEN_X * (BITS_PER_PIXEL / 8)) - (CHAR_X * (BITS_PER_PIXEL / 8))) * 65536 ; DMA 2D Mode Stride
  dw 0 ; DMA Next Control Block Address

Text: db "SNES Controller Test: "

align 4
DataValue: dw 0
Font: include 'Font8x8.asm'