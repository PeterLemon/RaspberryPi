; Raspberry Pi 'Bare Metal' Input NES Controller GFX Demo by krom (Peter Lemon):
; 1. Setup Frame Buffer
; 2. Start DMA 0 To Loop DMA Control Blocks For Fast Screen Buffer
; 3. Initialize & Update Input Data
; 4. Show GFX Representation Of Input Device 

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

; Setup Input
JOY_RIGHT  = 00000001b
JOY_LEFT   = 00000010b
JOY_DOWN   = 00000100b
JOY_UP     = 00001000b
JOY_START  = 00010000b
JOY_SELECT = 00100000b
JOY_B      = 01000000b
JOY_A      = 10000000b

; Setup Frame Buffer
SCREEN_X       = 640
SCREEN_Y       = 480
BITS_PER_PIXEL = 32

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
  cmp r0,0 ; Compare Frame Buffer Pointer To Zero
  beq FB_Init ; IF Zero Re-Initialize Frame Buffer

; Set Control Block Data Destination Address
str r0,[SCRBUF_DEST]

; Set Control Block Data Address into the DMA controller
adr r0,BG_STRUCT
imm32 r1,PERIPHERAL_BASE + DMA0_BASE + DMA_CONBLK_AD
str r0,[r1]

; Set Start Bit
mov r0,DMA_ACTIVE
imm32 r1,PERIPHERAL_BASE + DMA0_BASE + DMA_CS
str r0,[r1]

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
  Delay 32

  mov r1,GPIO_11 ; Set GPIO 11 (Latch) Output State To LOW
  str r1,[r0,GPIO_GPCLR0]
  Delay 32

  mov r1,0 ; R1 = Input Data
  mov r2,7 ; R2 = Input Data Count
  LoopInputData:
    ldr r3,[r0,GPIO_GPLEV0] ; Get GPIO 4 (Data) Level
    tst r3,GPIO_4
    moveq r3,1 ; GPIO 4 (Data) Level LOW
    orreq r1,r3,lsl r2

    mov r3,GPIO_10 ; Set GPIO 10 (Clock) Output State To HIGH
    str r3,[r0,GPIO_GPSET0]
    Delay 32

    mov r3,GPIO_10 ; Set GPIO 10 (Clock) Output State To LOW
    str r3,[r0,GPIO_GPCLR0]
    Delay 32

    subs r2,1
    bge LoopInputData ; Loop 8bit Data

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; R1 Now Contains Input Data ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

tst r1,JOY_A
imm32ne r0,ButtonAPress
imm32eq r0,ButtonA
str r0,[ButtonA_SOURCE]

tst r1,JOY_B
imm32ne r0,ButtonBPress
imm32eq r0,ButtonB
str r0,[ButtonB_SOURCE]

tst r1,JOY_START
imm32ne r0,ButtonStartPress
imm32eq r0,ButtonStart
str r0,[ButtonStart_SOURCE]

tst r1,JOY_SELECT
imm32ne r0,ButtonSelectPress
imm32eq r0,ButtonSelect
str r0,[ButtonSelect_SOURCE]

tst r1,JOY_UP + JOY_DOWN + JOY_LEFT + JOY_RIGHT
imm32eq r0,Direction
tst r1,JOY_UP
imm32ne r0,DirectionUpPress
tst r1,JOY_DOWN
imm32ne r0,DirectionDownPress
tst r1,JOY_LEFT
imm32ne r0,DirectionLeftPress
tst r1,JOY_RIGHT
imm32ne r0,DirectionRightPress
str r0,[Direction_SOURCE]

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

align 32
BG_STRUCT: ; Control Block Data Structure
  dw DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
  dw BG_Image ; DMA Source Address
BG_DEST:
  dw Screen_Buffer ; DMA Destination Address
  dw SCREEN_X * SCREEN_Y * (BITS_PER_PIXEL / 8) ; DMA Transfer Length
  dw 0 ; DMA 2D Mode Stride
  dw ButtonA_STRUCT ; DMA Next Control Block Address

align 32
ButtonA_STRUCT: ; Control Block Data Structure
  dw DMA_TDMODE + DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
ButtonA_SOURCE:
  dw ButtonA ; DMA Source Address
  dw Screen_Buffer + (((SCREEN_X * 360) + 490) * (BITS_PER_PIXEL / 8)) ; DMA Destination Address
  dw (72 * (BITS_PER_PIXEL / 8)) + ((72 - 1) * 65536) ; DMA Transfer Length
  dw ((SCREEN_X * (BITS_PER_PIXEL / 8)) - (72 * (BITS_PER_PIXEL / 8))) * 65536 ; DMA 2D Mode Stride
  dw ButtonB_STRUCT ; DMA Next Control Block Address

align 32
ButtonB_STRUCT: ; Control Block Data Structure
  dw DMA_TDMODE + DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
ButtonB_SOURCE:
  dw ButtonB ; DMA Source Address
  dw Screen_Buffer + (((SCREEN_X * 360) + 408) * (BITS_PER_PIXEL / 8)) ; DMA Destination Address
  dw (72 * (BITS_PER_PIXEL / 8)) + ((72 - 1) * 65536) ; DMA Transfer Length
  dw ((SCREEN_X * (BITS_PER_PIXEL / 8)) - (72 * (BITS_PER_PIXEL / 8))) * 65536 ; DMA 2D Mode Stride
  dw ButtonStart_STRUCT ; DMA Next Control Block Address

align 32
ButtonStart_STRUCT: ; Control Block Data Structure
  dw DMA_TDMODE + DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
ButtonStart_SOURCE:
  dw ButtonStart ; DMA Source Address
  dw Screen_Buffer + (((SCREEN_X * 380) + 304) * (BITS_PER_PIXEL / 8)) ; DMA Destination Address
  dw (64 * (BITS_PER_PIXEL / 8)) + ((32 - 1) * 65536) ; DMA Transfer Length
  dw ((SCREEN_X * (BITS_PER_PIXEL / 8)) - (64 * (BITS_PER_PIXEL / 8))) * 65536 ; DMA 2D Mode Stride
  dw ButtonSelect_STRUCT ; DMA Next Control Block Address

align 32
ButtonSelect_STRUCT: ; Control Block Data Structure
  dw DMA_TDMODE + DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
ButtonSelect_SOURCE:
  dw ButtonSelect ; DMA Source Address
  dw Screen_Buffer + (((SCREEN_X * 380) + 224) * (BITS_PER_PIXEL / 8)) ; DMA Destination Address
  dw (64 * (BITS_PER_PIXEL / 8)) + ((32 - 1) * 65536) ; DMA Transfer Length
  dw ((SCREEN_X * (BITS_PER_PIXEL / 8)) - (64 * (BITS_PER_PIXEL / 8))) * 65536 ; DMA 2D Mode Stride
  dw Direction_STRUCT ; DMA Next Control Block Address

align 32
Direction_STRUCT: ; Control Block Data Structure
  dw DMA_TDMODE + DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
Direction_SOURCE:
  dw Direction ; DMA Source Address
  dw Screen_Buffer + (((SCREEN_X * 300) + 56) * (BITS_PER_PIXEL / 8)) ; DMA Destination Address
  dw (128 * (BITS_PER_PIXEL / 8)) + ((128 - 1) * 65536) ; DMA Transfer Length
  dw ((SCREEN_X * (BITS_PER_PIXEL / 8)) - (128 * (BITS_PER_PIXEL / 8))) * 65536 ; DMA 2D Mode Stride
  dw SCRBUF_STRUCT ; DMA Next Control Block Address

align 32
SCRBUF_STRUCT: ; Control Block Data Structure
  dw DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
  dw Screen_Buffer ; DMA Source Address
SCRBUF_DEST:
  dw 0 ; DMA Destination Address
  dw SCREEN_X * SCREEN_Y * (BITS_PER_PIXEL / 8) ; DMA Transfer Length
  dw 0 ; DMA 2D Mode Stride
  dw BG_STRUCT ; DMA Next Control Block Address

ButtonA:
  file 'ButtonA.bin'
ButtonAPress:
  file 'ButtonAPress.bin'

ButtonB:
  file 'ButtonB.bin'
ButtonBPress:
  file 'ButtonBPress.bin'

ButtonStart:
  file 'ButtonStart.bin'
ButtonStartPress:
  file 'ButtonStartPress.bin'

ButtonSelect:
  file 'ButtonSelect.bin'
ButtonSelectPress:
  file 'ButtonSelectPress.bin'

Direction:
  file 'Direction.bin'
DirectionUpPress:
  file 'DirectionUpPress.bin'
DirectionDownPress:
  file 'DirectionDownPress.bin'
DirectionLeftPress:
  file 'DirectionLeftPress.bin'
DirectionRightPress:
  file 'DirectionRightPress.bin'

BG_Image:
  file 'BG.bin'

Screen_Buffer: