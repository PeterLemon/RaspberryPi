; Raspberry Pi 2 'Bare Metal' Input SNES Mouse Text Demo by krom (Peter Lemon):
; 1. Set Cores 1..3 To Infinite Loop
; 2. Setup Frame Buffer
; 3. Initialize & Update Input Data
; 4. Print RAW Hex Values To Screen

macro PrintText Text, TextLength {
  local .DrawChars,.DrawChar
  imm32 r1,Font ; R1 = Characters
  imm32 r2,Text ; R2 = Text Offset
  mov r3,TextLength ; R3 = Number Of Text Characters To Print
  .DrawChars:
    mov r4,CHAR_Y ; R4 = Character Row Counter
    ldrb r5,[r2],1 ; R5 = Next Text Character
    add r5,r1,r5,lsl 6 ; Add Shift To Correct Position In Font (* 64)

    .DrawChar:
      ldr r6,[r5],4 ; Load Font Text Character 1/2 Row
      str r6,[r0],4 ; Store Font Text Character 1/2 Row To Frame Buffer
      ldr r6,[r5],4 ; Load Font Text Character 1/2 Row
      str r6,[r0],4 ; Store Font Text Character 1/2 Row To Frame Buffer
      add r0,SCREEN_X ; Jump Down 1 Scanline
      sub r0,CHAR_X ; Jump Back 1 Char
      subs r4,1 ; Decrement Character Row Counter
      bne .DrawChar ; IF (Character Row Counter != 0) DrawChar

    subs r3,1 ; Subtract Number Of Text Characters To Print
    sub r0,SCREEN_X * CHAR_Y ; Jump To Top Of Char
    add r0,CHAR_X ; Jump Forward 1 Char
    bne .DrawChars ; IF (Number Of Text Characters != 0) Continue To Print Characters
}

macro PrintValueLE Value, ValueLength {
  local .DrawHEXChars,.DrawHEXChar,.DrawHEXCharB
  imm32 r1,Font ; R1 = Characters
  imm32 r2,Value ; R2 = Text Offset
  add r2,ValueLength - 1
  mov r3,ValueLength ; R3 = Number Of HEX Characters To Print
  .DrawHEXChars:
    ldrb r4,[r2],-1 ; R4 = Next 2 HEX Characters
    lsr r5,r4,4 ; Get 2nd Nibble
    cmp r5,$9
    addle r5,$30
    addgt r5,$37
    add r5,r1,r5,lsl 6 ; Add Shift To Correct Position In Font (* 64)
    mov r6,CHAR_Y ; R6 = Character Row Counter
    .DrawHEXChar:
      ldr r7,[r5],4 ; Load Font Text Character 1/2 Row
      str r7,[r0],4 ; Store Font Text Character 1/2 Row To Frame Buffer
      ldr r7,[r5],4 ; Load Font Text Character 1/2 Row
      str r7,[r0],4 ; Store Font Text Character 1/2 Row To Frame Buffer
      add r0,SCREEN_X ; Jump Down 1 Scanline
      sub r0,CHAR_X ; Jump Back 1 Char
      subs r6,1 ; Decrement Character Row Counter
      bne .DrawHEXChar ; IF (Character Row Counter != 0) DrawChar

    sub r0,SCREEN_X * CHAR_Y ; Jump To Top Of Char

    add r0,CHAR_X ; Jump Forward 1 Char
    and r5,r4,$F ; Get 1st Nibble
    cmp r5,$9
    addle r5,$30
    addgt r5,$37
    add r5,r1,r5,lsl 6 ; Add Shift To Correct Position In Font (* 64)
    mov r6,CHAR_Y ; R6 = Character Row Counter
    .DrawHEXCharB:
      ldr r7,[r5],4 ; Load Font Text Character 1/2 Row
      str r7,[r0],4 ; Store Font Text Character 1/2 Row To Frame Buffer
      ldr r7,[r5],4 ; Load Font Text Character 1/2 Row
      str r7,[r0],4 ; Store Font Text Character 1/2 Row To Frame Buffer
      add r0,SCREEN_X ; Jump Down 1 Scanline
      sub r0,CHAR_X ; Jump Back 1 Char
      subs r6,1 ; Decrement Character Row Counter
      bne .DrawHEXCharB ; IF (Character Row Counter != 0) DrawChar

    subs r3,1 ; Subtract Number Of HEX Characters To Print
    sub r0,SCREEN_X * CHAR_Y ; Jump To Top Of Char
    add r0,CHAR_X ; Jump Forward 1 Char
    bne .DrawHEXChars ; IF (Number Of Hex Characters != 0) Continue To Print Characters
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
include 'LIB\R_PI2.INC'

; Setup Frame Buffer
SCREEN_X       = 640
SCREEN_Y       = 480
BITS_PER_PIXEL = 8

; Setup Characters
CHAR_X = 8
CHAR_Y = 8

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

org $0000

; Return CPU ID (0..3) Of The CPU Executed On
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
ands r0,3 ; R0 = CPU ID (Bits 0..1)
bne CoreLoop ; IF (CPU ID != 0) Branch To Infinite Loop (Core ID 1..3)

FB_Init:
  imm32 r0,FB_STRUCT + MAIL_TAGS
  imm32 r1,PERIPHERAL_BASE + MAIL_BASE + MAIL_WRITE + MAIL_TAGS
  str r0,[r1] ; Mail Box Write

  ldr r0,[FB_POINTER] ; R0 = Frame Buffer Pointer
  cmp r0,0 ; Compare Frame Buffer Pointer To Zero
  beq FB_Init ; IF Zero Re-Initialize Frame Buffer

  and r0,$3FFFFFFF ; Convert Mail Box Frame Buffer Pointer From BUS Address To Physical Address ($CXXXXXXX -> $3XXXXXXX)
  str r0,[FB_POINTER] ; Store Frame Buffer Pointer Physical Address

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

str r1,[DataValue]

ldr r0,[OldDataValue] ; Compare Old & New Mouse XY Data To Old Data, IF == Mouse Has Not Moved
cmp r1,r0
beq SkipXYPos

; Mouse X
and r2,r0,$FF ; R2 = Old Mouse X Data
and r3,r1,$FF ; R3 = New Mouse X Data
cmp r2,r3 ; Compare Old & New Mouse X Data, IF == Mouse X Has Not Moved
beq SkipXPos

ldr r2,[MouseX] ; R2 = Mouse X Position
tst r1,MOUSE_DIRX ; Test Mouse X Direction
addeq r2,1
subne r2,1
str r2,[MouseX] ; Store Mouse X Position
SkipXPos:

; Mouse Y
mov r2,r0,lsr 8 ; R2 = Old Mouse Y Data
and r2,$FF
mov r3,r1,lsr 8 ; R3 = New Mouse Y Data
and r3,$FF
cmp r2,r3 ; Compare Old & New Mouse X Data, IF == Mouse X Has Not Moved
beq SkipYPos

ldr r2,[MouseY] ; R2 = Mouse Y Position
tst r1,MOUSE_DIRY ; Test Mouse Y Direction
addeq r2,1
subne r2,1
str r2,[MouseY] ; Store Mouse Y Position
SkipYPos:

str r1,[OldDataValue]
SkipXYPos:

imm32 r1,FB_POINTER
ldr r0,[r1] ; R0 = Frame Buffer Pointer
imm32 r1,16 + (SCREEN_X * 48)
add r0,r1 ; Place Text At XY Position 16,48
PrintTAGValueLE TextTest, 17, DataValue, 4

adr r1,FB_POINTER
ldr r0,[r1] ; R0 = Frame Buffer Pointer
imm32 r1,16 + (SCREEN_X * 64)
add r0,r1 ; Place Text At XY Position 16,64
PrintTAGValueLE TextMouseX, 9, MouseX, 4

adr r1,FB_POINTER
ldr r0,[r1] ; R0 = Frame Buffer Pointer
imm32 r1,16 + (SCREEN_X * 72)
add r0,r1 ; Place Text At XY Position 16,72
PrintTAGValueLE TextMouseY, 9, MouseY, 4

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

TextTest: db "SNES Mouse Test: "
TextMouseX: db "Mouse X: "
TextMouseY: db "Mouse Y: "

align 4
DataValue: dw 0
OldDataValue dw 0
MouseX: dw 320
MouseY: dw 240
Font: include 'Font8x8.asm'