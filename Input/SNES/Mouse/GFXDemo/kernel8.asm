; Raspberry Pi 3 'Bare Metal' Input SNES Mouse GFX Demo by krom (Peter Lemon):
; 1. Setup Frame Buffer
; 2. Start DMA 0 To Loop DMA Control Blocks For Fast Screen Buffer
; 3. Initialize & Update Input Data
; 4. Show GFX Representation Of Input Device 

macro Delay amount {
  local .DelayLoop
  mov w12,amount
  .DelayLoop:
    subs w12,w12,1
    b.ne .DelayLoop
}

code64
processor cpu64_v8
format binary as 'img'
include 'LIB\R_PI2.INC'

; Setup Input
JOY_R	   = 0000000000010000b
JOY_L	   = 0000000000100000b
JOY_X	   = 0000000001000000b
JOY_A	   = 0000000010000000b
JOY_RIGHT  = 0000000100000000b
JOY_LEFT   = 0000001000000000b
JOY_DOWN   = 0000010000000000b
JOY_UP	   = 0000100000000000b
JOY_START  = 0001000000000000b
JOY_SELECT = 0010000000000000b
JOY_Y	   = 0100000000000000b
JOY_B	   = 1000000000000000b

; Setup Frame Buffer
SCREEN_X       = 640
SCREEN_Y       = 480
BITS_PER_PIXEL = 32

org $0000

; Return CPU ID (0..3) Of The CPU Executed On
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
ands x0,x0,3 ; X0 = CPU ID (Bits 0..1)
b.ne CoreLoop ; IF (CPU ID != 0) Branch To Infinite Loop (Core ID 1..3)

; Set DMA Channel 0 Enable Bit
mov w0,PERIPHERAL_BASE
mov w1,DMA_ENABLE
mov w2,DMA_EN0
str w2,[x0,x1]

FB_Init:
  mov w0,FB_STRUCT + MAIL_TAGS
  mov x1,MAIL_BASE
  orr x1,x1,PERIPHERAL_BASE
  str w0,[x1,MAIL_WRITE + MAIL_TAGS] ; Mail Box Write

  ldr w0,[FB_POINTER] ; W0 = Frame Buffer Pointer
  cbz w0,FB_Init ; IF (Frame Buffer Pointer == Zero) Re-Initialize Frame Buffer

  and w0,w0,$3FFFFFFF ; Convert Mail Box Frame Buffer Pointer From BUS Address To Physical Address ($CXXXXXXX -> $3XXXXXXX)
  adr x1,FB_POINTER
  str w0,[x1] ; Store Frame Buffer Pointer Physical Address

; Set Control Block Data Destination Address
adr x1,SCRBUF_DEST
str w0,[x1]

; Set Control Block Data Address To DMA Channel 0 Controller
mov w0,PERIPHERAL_BASE
orr w0,w0,DMA0_BASE
adr x1,BG_STRUCT
str w1,[x0,DMA_CONBLK_AD]

; Set Start Bit
mov w1,DMA_ACTIVE
str w1,[x0,DMA_CS] ; Start DMA

;;;;;;;;;;;;;;;;;;;;;;
;; Initialize Input ;;
;;;;;;;;;;;;;;;;;;;;;;
; Set GPIO 10 & 11 (Clock & Latch) Function To Output
mov w0,PERIPHERAL_BASE + GPIO_BASE
mov w1,GPIO_FSEL0_OUT + GPIO_FSEL1_OUT
str w1,[x0,GPIO_GPFSEL1]

;;;;;;;;;;;;;;;;;;
;; Update Input ;;
;;;;;;;;;;;;;;;;;;
UpdateInput:
  mov w0,PERIPHERAL_BASE + GPIO_BASE ; Set GPIO 11 (Latch) Output State To HIGH
  mov w1,GPIO_11
  str w1,[x0,GPIO_GPSET0]
  Delay 32

  mov w1,GPIO_11 ; Set GPIO 11 (Latch) Output State To LOW
  str w1,[x0,GPIO_GPCLR0]
  Delay 32

  mov w1,0  ; W1 = Input Data
  mov w2,15 ; W2 = Input Data Count
  LoopInputData:
    ldr w3,[x0,GPIO_GPLEV0] ; Get GPIO 4 (Data) Level
    tst w3,GPIO_4
    b.ne InputClock
    mov w3,1 ; GPIO 4 (Data) Level LOW
    lsl w3,w3,w2
    orr w1,w1,w3

    InputClock:
    mov w3,GPIO_10 ; Set GPIO 10 (Clock) Output State To HIGH
    str w3,[x0,GPIO_GPSET0]
    Delay 32

    mov w3,GPIO_10 ; Set GPIO 10 (Clock) Output State To LOW
    str w3,[x0,GPIO_GPCLR0]
    Delay 32

    subs w2,w2,1
    b.ge LoopInputData ; Loop 16bit Data

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; W1 Now Contains Input Data ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

tst w1,JOY_L
b.ne ButtonLPressed
adr x0,ButtonL
b ButtonLEnd
ButtonLPressed:
adr x0,ButtonLPress
ButtonLEnd:
adr x2,ButtonL_SOURCE
str w0,[x2]

tst w1,JOY_R
b.ne ButtonRPressed
adr x0,ButtonR
b ButtonREnd
ButtonRPressed:
adr x0,ButtonRPress
ButtonREnd:
adr x2,ButtonR_SOURCE
str w0,[x2]

tst w1,JOY_X
b.ne ButtonXPressed
adr x0,ButtonX
b ButtonXEnd
ButtonXPressed:
adr x0,ButtonXPress
ButtonXEnd:
adr x2,ButtonX_SOURCE
str w0,[x2]

tst w1,JOY_A
b.ne ButtonAPressed
adr x0,ButtonA
b ButtonAEnd
ButtonAPressed:
adr x0,ButtonAPress
ButtonAEnd:
adr x2,ButtonA_SOURCE
str w0,[x2]

tst w1,JOY_B
b.ne ButtonBPressed
adr x0,ButtonB
b ButtonBEnd
ButtonBPressed:
adr x0,ButtonBPress
ButtonBEnd:
adr x2,ButtonB_SOURCE
str w0,[x2]

tst w1,JOY_Y
b.ne ButtonYPressed
adr x0,ButtonY
b ButtonYEnd
ButtonYPressed:
adr x0,ButtonYPress
ButtonYEnd:
adr x2,ButtonY_SOURCE
str w0,[x2]

tst w1,JOY_START
b.ne ButtonStartPressed
adr x0,ButtonStart
b ButtonStartEnd
ButtonStartPressed:
adr x0,ButtonStartPress
ButtonStartEnd:
adr x2,ButtonStart_SOURCE
str w0,[x2]

tst w1,JOY_SELECT
b.ne ButtonSelectPressed
adr x0,ButtonSelect
b ButtonSelectEnd
ButtonSelectPressed:
adr x0,ButtonSelectPress
ButtonSelectEnd:
adr x2,ButtonSelect_SOURCE
str w0,[x2]

tst w1,JOY_UP + JOY_DOWN + JOY_LEFT + JOY_RIGHT
b.ne DirectionUp
adr x0,Direction
b DirectionEnd

DirectionUp:
tst w1,JOY_UP
b.eq DirectionDown
adr x0,DirectionUpPress
b DirectionEnd

DirectionDown:
tst w1,JOY_DOWN
b.eq DirectionLeft
adr x0,DirectionDownPress
b DirectionEnd

DirectionLeft:
tst w1,JOY_LEFT
b.eq DirectionRight
adr x0,DirectionLeftPress
b DirectionEnd

DirectionRight:
tst w1,JOY_RIGHT
b.eq DirectionEnd
adr x0,DirectionRightPress

DirectionEnd:
adr x2,Direction_SOURCE
str w0,[x2]

b UpdateInput ; Refresh Input Data

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

align 32
BG_STRUCT: ; Control Block Data Structure
  dw DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
  dw BG_Image ; DMA Source Address
BG_DEST:
  dw Screen_Buffer ; DMA Destination Address
  dw SCREEN_X * SCREEN_Y * (BITS_PER_PIXEL / 8) ; DMA Transfer Length
  dw 0 ; DMA 2D Mode Stride
  dw ButtonL_STRUCT ; DMA Next Control Block Address

align 32
ButtonL_STRUCT: ; Control Block Data Structure
  dw DMA_TDMODE + DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
ButtonL_SOURCE:
  dw ButtonL ; DMA Source Address
  dw Screen_Buffer + (((SCREEN_X * 192) + 80) * (BITS_PER_PIXEL / 8)) ; DMA Destination Address
  dw (144 * (BITS_PER_PIXEL / 8)) + ((40 - 1) * 65536) ; DMA Transfer Length
  dw ((SCREEN_X * (BITS_PER_PIXEL / 8)) - (144 * (BITS_PER_PIXEL / 8))) * 65536 ; DMA 2D Mode Stride
  dw ButtonR_STRUCT ; DMA Next Control Block Address

align 32
ButtonR_STRUCT: ; Control Block Data Structure
  dw DMA_TDMODE + DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
ButtonR_SOURCE:
  dw ButtonR ; DMA Source Address
  dw Screen_Buffer + (((SCREEN_X * 192) + 416) * (BITS_PER_PIXEL / 8)) ; DMA Destination Address
  dw (144 * (BITS_PER_PIXEL / 8)) + ((40 - 1) * 65536) ; DMA Transfer Length
  dw ((SCREEN_X * (BITS_PER_PIXEL / 8)) - (144 * (BITS_PER_PIXEL / 8))) * 65536 ; DMA 2D Mode Stride
  dw ButtonX_STRUCT ; DMA Next Control Block Address

align 32
ButtonX_STRUCT: ; Control Block Data Structure
  dw DMA_TDMODE + DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
ButtonX_SOURCE:
  dw ButtonX ; DMA Source Address
  dw Screen_Buffer + (((SCREEN_X * 264) + 464) * (BITS_PER_PIXEL / 8)) ; DMA Destination Address
  dw (64 * (BITS_PER_PIXEL / 8)) + ((56 - 1) * 65536) ; DMA Transfer Length
  dw ((SCREEN_X * (BITS_PER_PIXEL / 8)) - (64 * (BITS_PER_PIXEL / 8))) * 65536 ; DMA 2D Mode Stride
  dw ButtonA_STRUCT ; DMA Next Control Block Address

align 32
ButtonA_STRUCT: ; Control Block Data Structure
  dw DMA_TDMODE + DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
ButtonA_SOURCE:
  dw ButtonA ; DMA Source Address
  dw Screen_Buffer + (((SCREEN_X * 308) + 524) * (BITS_PER_PIXEL / 8)) ; DMA Destination Address
  dw (64 * (BITS_PER_PIXEL / 8)) + ((56 - 1) * 65536) ; DMA Transfer Length
  dw ((SCREEN_X * (BITS_PER_PIXEL / 8)) - (64 * (BITS_PER_PIXEL / 8))) * 65536 ; DMA 2D Mode Stride
  dw ButtonB_STRUCT ; DMA Next Control Block Address

align 32
ButtonB_STRUCT: ; Control Block Data Structure
  dw DMA_TDMODE + DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
ButtonB_SOURCE:
  dw ButtonB ; DMA Source Address
  dw Screen_Buffer + (((SCREEN_X * 352) + 464) * (BITS_PER_PIXEL / 8)) ; DMA Destination Address
  dw (64 * (BITS_PER_PIXEL / 8)) + ((56 - 1) * 65536) ; DMA Transfer Length
  dw ((SCREEN_X * (BITS_PER_PIXEL / 8)) - (64 * (BITS_PER_PIXEL / 8))) * 65536 ; DMA 2D Mode Stride
  dw ButtonY_STRUCT ; DMA Next Control Block Address

align 32
ButtonY_STRUCT: ; Control Block Data Structure
  dw DMA_TDMODE + DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
ButtonY_SOURCE:
  dw ButtonY ; DMA Source Address
  dw Screen_Buffer + (((SCREEN_X * 308) + 404) * (BITS_PER_PIXEL / 8)) ; DMA Destination Address
  dw (64 * (BITS_PER_PIXEL / 8)) + ((56 - 1) * 65536) ; DMA Transfer Length
  dw ((SCREEN_X * (BITS_PER_PIXEL / 8)) - (64 * (BITS_PER_PIXEL / 8))) * 65536 ; DMA 2D Mode Stride
  dw ButtonStart_STRUCT ; DMA Next Control Block Address

align 32
ButtonStart_STRUCT: ; Control Block Data Structure
  dw DMA_TDMODE + DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
ButtonStart_SOURCE:
  dw ButtonStart ; DMA Source Address
  dw Screen_Buffer + (((SCREEN_X * 328) + 300) * (BITS_PER_PIXEL / 8)) ; DMA Destination Address
  dw (60 * (BITS_PER_PIXEL / 8)) + ((52 - 1) * 65536) ; DMA Transfer Length
  dw ((SCREEN_X * (BITS_PER_PIXEL / 8)) - (60 * (BITS_PER_PIXEL / 8))) * 65536 ; DMA 2D Mode Stride
  dw ButtonSelect_STRUCT ; DMA Next Control Block Address

align 32
ButtonSelect_STRUCT: ; Control Block Data Structure
  dw DMA_TDMODE + DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
ButtonSelect_SOURCE:
  dw ButtonSelect ; DMA Source Address
  dw Screen_Buffer + (((SCREEN_X * 328) + 236) * (BITS_PER_PIXEL / 8)) ; DMA Destination Address
  dw (60 * (BITS_PER_PIXEL / 8)) + ((52 - 1) * 65536) ; DMA Transfer Length
  dw ((SCREEN_X * (BITS_PER_PIXEL / 8)) - (60 * (BITS_PER_PIXEL / 8))) * 65536 ; DMA 2D Mode Stride
  dw Direction_STRUCT ; DMA Next Control Block Address

align 32
Direction_STRUCT: ; Control Block Data Structure
  dw DMA_TDMODE + DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
Direction_SOURCE:
  dw Direction ; DMA Source Address
  dw Screen_Buffer + (((SCREEN_X * 272) + 76) * (BITS_PER_PIXEL / 8)) ; DMA Destination Address
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

ButtonL:
  file 'ButtonL.bin'
ButtonLPress:
  file 'ButtonLPress.bin'

ButtonR:
  file 'ButtonR.bin'
ButtonRPress:
  file 'ButtonRPress.bin'

ButtonX:
  file 'ButtonX.bin'
ButtonXPress:
  file 'ButtonXPress.bin'

ButtonA:
  file 'ButtonA.bin'
ButtonAPress:
  file 'ButtonAPress.bin'

ButtonB:
  file 'ButtonB.bin'
ButtonBPress:
  file 'ButtonBPress.bin'

ButtonY:
  file 'ButtonY.bin'
ButtonYPress:
  file 'ButtonYPress.bin'

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