; Raspberry Pi 3 'Bare Metal' Input SNES Mouse Text Demo by krom (Peter Lemon):
; 1. Set Cores 1..3 To Infinite Loop
; 2. Setup Frame Buffer
; 3. Initialize & Update Input Data
; 4. Print RAW Hex Values To Screen

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

macro PrintTAGValueLE Text, TextLength, Value, ValueLength {
  PrintText Text, TextLength
  PrintValueLE Value, ValueLength
}

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
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
ands x0,x0,3 ; X0 = CPU ID (Bits 0..1)
b.ne CoreLoop ; IF (CPU ID != 0) Branch To Infinite Loop (Core ID 1..3)

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

adr x2,DataValue
str w1,[x2]

ldr w0,[OldDataValue] ; Compare Old & New Mouse XY Data To Old Data, IF == Mouse Has Not Moved
cmp w1,w0
b.eq SkipXYPos

; Mouse X
and w2,w0,$FF ; W2 = Old Mouse X Data
and w3,w1,$FF ; W3 = New Mouse X Data
cmp w2,w3 ; Compare Old & New Mouse X Data, IF == Mouse X Has Not Moved
b.eq SkipXPos

ldr w2,[MouseX] ; W2 = Mouse X Position
tst w1,MOUSE_DIRX ; Test Mouse X Direction
b.ne DIRXNegative
add w2,w2,1
b DIRXEnd
DIRXNegative:
sub w2,w2,1
DIRXEnd:
adr x3,MouseX
str w2,[x3] ; Store Mouse X Position
SkipXPos:

; Mouse Y
lsr w2,w0,8 ; W2 = Old Mouse Y Data
and w2,w2,$FF
lsr w3,w1,8 ; W3 = New Mouse Y Data
and w3,w3,$FF
cmp w2,w3 ; Compare Old & New Mouse X Data, IF == Mouse X Has Not Moved
b.eq SkipYPos

ldr w2,[MouseY] ; W2 = Mouse Y Position
tst w1,MOUSE_DIRY ; Test Mouse Y Direction
b.ne DIRYNegative
add w2,w2,1
b DIRYEnd
DIRYNegative:
sub w2,w2,1
DIRYEnd:
adr x3,MouseY
str w2,[x3] ; Store Mouse Y Position
SkipYPos:

adr x2,OldDataValue
str w1,[x2]
SkipXYPos:

adr x1,FB_POINTER
ldr w0,[x1] ; R0 = Frame Buffer Pointer
mov w1,16 + (SCREEN_X * 48)
add w0,w0,w1 ; Place Text At XY Position 16,48
PrintTAGValueLE TextTest, 17, DataValue, 4

adr x1,FB_POINTER
ldr w0,[x1] ; R0 = Frame Buffer Pointer
mov w1,16 + (SCREEN_X * 64)
add w0,w0,w1 ; Place Text At XY Position 16,64
PrintTAGValueLE TextMouseX, 9, MouseX, 4

adr x1,FB_POINTER
ldr w0,[x1] ; R0 = Frame Buffer Pointer
mov w1,16 + (SCREEN_X * 72)
add w0,w0,w1 ; Place Text At XY Position 16,72
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

align 8
Font: include 'Font8x8.asm'