; Raspberry Pi 3 'Bare Metal' Input SNES Mouse GFX Demo by krom (Peter Lemon):
; 1. Set Cores 1..3 To Infinite Loop
; 2. Setup Frame Buffer
; 3. Start DMA 0 To Loop DMA Control Blocks For Fast Screen Buffer
; 4. Initialize & Update Input Data
; 5. Show GFX Representation Of Input Device 

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
MOUSE_R      = 00000000100000000000000000000000b
MOUSE_L      = 00000000010000000000000000000000b
MOUSE_SPDSLW = 00000000001000000000000000000000b
MOUSE_SPDNOR = 00000000000100000000000000000000b
MOUSE_SPDFST = 00000000000000000000000000000000b
MOUSE_SIG    = 00000000000011110000000000000000b ; Always %0001
MOUSE_DIRY   = 00000000000000001000000000000000b
MOUSE_Y      = 00000000000000000111111100000000b
MOUSE_DIRX   = 00000000000000000000000010000000b
MOUSE_X      = 00000000000000000000000001111111b

; Setup Frame Buffer
SCREEN_X       = 640
SCREEN_Y       = 480
BITS_PER_PIXEL = 32

; Setup Pointer
POINTER_X = 96
POINTER_Y = 144
POINTER_CENTER_X = (SCREEN_X / 2) - (POINTER_X / 2)
POINTER_CENTER_Y = (SCREEN_Y / 2) - (POINTER_Y / 2)

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
  mov w2,31 ; W2 = Input Data Count
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
    b.ge LoopInputData ; Loop 32bit Data

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; W1 Now Contains Input Data ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

and w0,w1,$300000
cmp w0,MOUSE_SPDFST ; Compare IF On "Fast" Speed Phase, Otherwise Update Input
b.ne UpdateInput

ldr w0,[MOUSE_DATA] ; Compare Old & New Mouse XY Data, IF == Mouse Has Not Moved
cmp w1,w0
b.eq SkipXYPos

; Mouse X
and w2,w0,$FF ; W2 = Old Mouse X Data
and w3,w1,$FF ; W3 = New Mouse X Data
cmp w2,w3 ; Compare Old & New Mouse X Data, IF == Mouse X Has Not Moved
b.eq SkipXPos

ldr w2,[MOUSE_X_POS] ; W2 = Mouse X Position
ldr w3,[POINTER_DEST] ; W3 = Pointer VRAM Destination

tst w1,MOUSE_DIRX ; Test Mouse X Direction
b.ne MouseXDir1
cmp w2,SCREEN_X - POINTER_X ; Maximum X Test (Make Sure Pointer Does Not Go Off Screen Right)
b.eq SkipXPos
b MouseXDir0

MouseXDir1:
cmp w2,0 ; Minimum X Test (Make Sure Pointer Does Not Go Off Screen Left)
b.eq SkipXPos
MouseXDir0:

tst w1,MOUSE_DIRX ; Test Mouse X Direction
b.ne DIRXNegative
add w2,w2,1
add w3,w3,1 * (BITS_PER_PIXEL / 8)
b DIRXEnd
DIRXNegative:
sub w2,w2,1
sub w3,w3,1 * (BITS_PER_PIXEL / 8)
DIRXEnd:
adr x4,MOUSE_X_POS
str w2,[x4] ; Store Mouse X Position
adr x4,POINTER_DEST
str w3,[x4] ; Store Pointer VRAM Destination
SkipXPos:

; Mouse Y
lsr w2,w0,8 ; W2 = Old Mouse Y Data
and w2,w2,$FF
lsr w3,w1,8 ; W3 = New Mouse Y Data
and w3,w3,$FF
cmp w2,w3 ; Compare Old & New Mouse X Data, IF == Mouse X Has Not Moved
b.eq SkipYPos

ldr w2,[MOUSE_Y_POS] ; W2 = Mouse Y Position
ldr w3,[POINTER_DEST] ; W3 = Pointer VRAM Destination

tst w1,MOUSE_DIRY ; Test Mouse Y Direction
b.ne MouseYDir1
cmp w2,SCREEN_Y - POINTER_Y ; Maximum Y Test (Make Sure Pointer Does Not Go Off Screen Bottom)
b.eq SkipYPos
b MouseYDir0

MouseYDir1:
cmp w2,0 ; Minimum Y Test (Make Sure Pointer Does Not Go Off Screen Top)
b.eq SkipYPos
MouseYDir0:

tst w1,MOUSE_DIRY ; Test Mouse Y Direction
b.ne DIRYNegative
add w2,w2,1
add w3,w3,SCREEN_X * (BITS_PER_PIXEL / 8)
b DIRYEnd
DIRYNegative:
sub w2,w2,1
sub w3,w3,SCREEN_X * (BITS_PER_PIXEL / 8)
DIRYEnd:
adr x4,MOUSE_Y_POS
str w2,[x4] ; Store Mouse Y Position
adr x4,POINTER_DEST
str w3,[x4] ; Store Pointer VRAM Destination
SkipYPos:

adr x2,MOUSE_DATA
str w1,[x2]
SkipXYPos:

and w1,w1,MOUSE_R + MOUSE_L ; Get Button State

cmp w1,0 ; Test No Mouse L & R Button
b.ne ButtonL
adr x0,Pointer_Image
b ButtonEnd

ButtonL:
cmp w1,MOUSE_L ; Test Mouse L Button
b.ne ButtonR
adr x0,PointerL_Image
b ButtonEnd

ButtonR:
cmp w1,MOUSE_R ; Test Mouse R Button
b.ne ButtonLR
adr x0,PointerR_Image
b ButtonEnd

ButtonLR:
cmp w1,MOUSE_R + MOUSE_L ; Test Mouse L & R Button
b.ne ButtonEnd
adr x0,PointerLR_Image

ButtonEnd:
adr x1,POINTER_SOURCE
str w0,[x1]

b UpdateInput ; Refresh Input Data

CoreLoop: ; Infinite Loop For Core 1..3
  b CoreLoop

MOUSE_DATA: dw 0
MOUSE_X_POS: dw POINTER_CENTER_X
MOUSE_Y_POS: dw POINTER_CENTER_Y

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
  dw POINTER_STRUCT ; DMA Next Control Block Address

align 32
POINTER_STRUCT: ; Control Block Data Structure
  dw DMA_TDMODE + DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
POINTER_SOURCE:
  dw Pointer_Image ; DMA Source Address
POINTER_DEST:
  dw Screen_Buffer + (((SCREEN_X * POINTER_CENTER_Y) + POINTER_CENTER_X) * (BITS_PER_PIXEL / 8)) ; DMA Destination Address
  dw (POINTER_X * (BITS_PER_PIXEL / 8)) + ((POINTER_Y - 1) * 65536) ; DMA Transfer Length
  dw ((SCREEN_X * (BITS_PER_PIXEL / 8)) - (POINTER_X * (BITS_PER_PIXEL / 8))) * 65536 ; DMA 2D Mode Stride
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

Pointer_Image:
  file 'Pointer.bin'

PointerL_Image:
  file 'PointerL.bin'

PointerR_Image:
  file 'PointerR.bin'

PointerLR_Image:
  file 'PointerLR.bin'

BG_Image:
  file 'BG.bin'

Screen_Buffer: