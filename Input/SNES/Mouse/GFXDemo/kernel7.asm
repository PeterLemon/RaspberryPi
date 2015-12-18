; Raspberry Pi 2 'Bare Metal' Input SNES Mouse GFX Demo by krom (Peter Lemon):
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
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
ands r0,3 ; R0 = CPU ID (Bits 0..1)
bne CoreLoop ; IF (CPU ID != 0) Branch To Infinite Loop (Core ID 1..3)

imm32 r0,PERIPHERAL_BASE + DMA_ENABLE ; Set DMA Channel 0 Enable Bit
mov r1,DMA_EN0
str r1,[r0]

FB_Init:
  imm32 r0,FB_STRUCT + MAIL_TAGS
  imm32 r1,PERIPHERAL_BASE + MAIL_BASE + MAIL_WRITE + MAIL_TAGS
  str r0,[r1] ; Mail Box Write

  ldr r0,[FB_POINTER] ; R0 = Frame Buffer Pointer
  cmp r0,0 ; Compare Frame Buffer Pointer To Zero
  beq FB_Init ; IF Zero Re-Initialize Frame Buffer

  and r0,$3FFFFFFF ; Convert Mail Box Frame Buffer Pointer From BUS Address To Physical Address ($CXXXXXXX -> $3XXXXXXX)
  str r0,[FB_POINTER] ; Store Frame Buffer Pointer Physical Address

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

  mov r1,0  ; R1 = Input Data
  mov r2,31 ; R2 = Input Data Count
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
    bge LoopInputData ; Loop 32bit Data

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; R1 Now Contains Input Data ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

and r0,r1,$300000
cmp r0,MOUSE_SPDFST ; Compare IF On "Fast" Speed Phase, Otherwise Update Input
bne UpdateInput

ldr r0,[MOUSE_DATA] ; Compare Old & New Mouse XY Data, IF == Mouse Has Not Moved
cmp r1,r0
beq SkipXYPos

; Mouse X
and r2,r0,$FF ; R2 = Old Mouse X Data
and r3,r1,$FF ; R3 = New Mouse X Data
cmp r2,r3 ; Compare Old & New Mouse X Data, IF == Mouse X Has Not Moved
beq SkipXPos

ldr r2,[MOUSE_X_POS] ; R2 = Mouse X Position
ldr r3,[POINTER_DEST] ; R3 = Pointer VRAM Destination

tst r1,MOUSE_DIRX ; Test Mouse X Direction
bne MouseXDir1
cmp r2,SCREEN_X - POINTER_X ; Maximum X Test (Make Sure Pointer Does Not Go Off Screen Right)
beq SkipXPos
b MouseXDir0

MouseXDir1:
cmp r2,0 ; Minimum X Test (Make Sure Pointer Does Not Go Off Screen Left)
beq SkipXPos
MouseXDir0:

tst r1,MOUSE_DIRX ; Test Mouse X Direction
addeq r2,1
addeq r3,1 * (BITS_PER_PIXEL / 8)
subne r2,1
subne r3,1 * (BITS_PER_PIXEL / 8)
str r2,[MOUSE_X_POS] ; Store Mouse X Position
str r3,[POINTER_DEST] ; Store Pointer VRAM Destination
SkipXPos:

; Mouse Y
mov r2,r0,lsr 8 ; R2 = Old Mouse Y Data
and r2,$FF
mov r3,r1,lsr 8 ; R3 = New Mouse Y Data
and r3,$FF
cmp r2,r3 ; Compare Old & New Mouse X Data, IF == Mouse X Has Not Moved
beq SkipYPos

ldr r2,[MOUSE_Y_POS] ; R2 = Mouse Y Position
ldr r3,[POINTER_DEST] ; R3 = Pointer VRAM Destination

tst r1,MOUSE_DIRY ; Test Mouse Y Direction
bne MouseYDir1
cmp r2,SCREEN_Y - POINTER_Y ; Maximum Y Test (Make Sure Pointer Does Not Go Off Screen Bottom)
beq SkipYPos
b MouseYDir0

MouseYDir1:
cmp r2,0 ; Minimum Y Test (Make Sure Pointer Does Not Go Off Screen Top)
beq SkipYPos
MouseYDir0:

tst r1,MOUSE_DIRY ; Test Mouse Y Direction
addeq r2,1
addeq r3,SCREEN_X * (BITS_PER_PIXEL / 8)
subne r2,1
subne r3,SCREEN_X * (BITS_PER_PIXEL / 8)
str r2,[MOUSE_Y_POS] ; Store Mouse Y Position
str r3,[POINTER_DEST] ; Store Pointer VRAM Destination
SkipYPos:

str r1,[MOUSE_DATA]
SkipXYPos:

and r1,MOUSE_R + MOUSE_L ; Get Button State

cmp r1,0 ; Test No Mouse L & R Button
imm32eq r0,Pointer_Image
beq ButtonComplete

cmp r1,MOUSE_L ; Test Mouse L Button
imm32eq r0,PointerL_Image
beq ButtonComplete

cmp r1,MOUSE_R ; Test Mouse R Button
imm32eq r0,PointerR_Image
beq ButtonComplete

cmp r1,MOUSE_R + MOUSE_L ; Test Mouse L & R Button
imm32eq r0,PointerLR_Image

ButtonComplete:
str r0,[POINTER_SOURCE]

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