; Raspberry Pi 3 'Bare Metal' Julia Fractal Animation Demo by krom (Peter Lemon):
; 1. Turn On L1 Cache
; 2. Turn On Vector Floating Point Unit
; 3. Setup Frame Buffer
; 4. Plot Fractal Using Double-Precision
; 5. Change Julia Settings & Redraw To Animate

code64
processor cpu64_v8 +cpu64_fp +CPU64_SIMD
format binary as 'img'
include 'LIB\R_PI2.INC'

; Setup Frame Buffer
SCREEN_X       = 640
SCREEN_Y       = 480
BITS_PER_PIXEL = 32

org $0000

; Return CPU ID (0..3) Of The CPU Executed On
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
ands x0,x0,3 ; X0 = CPU ID (Bits 0..1)
b.ne CoreLoop ; IF (CPU ID != 0) Branch To Infinite Loop (Core ID 1..3)

; Start L1 Cache
mrs x0,SCTLR_EL3 ; X0 = System Control Register
orr x0,x0,$0004 ; Data Cache (Bit 2)
orr x0,x0,$0800 ; Branch Prediction (Bit 11)
orr x0,x0,$1000 ; Instruction Caches (Bit 12)
msr SCTLR_EL3,x0 ; System Control Register = X0

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

ldr w1,[LAST_PIXEL]
add w1,w1,w0 ; W1 = Frame Buffer Pointer Last Pixel

mov w2,SCREEN_X ; Load Double Screen X
ucvtf d0,w2 ; D0 = X%
fmov d2,d0 ; D2 = SX

mov w2,SCREEN_Y ; Load Double Screen Y
ucvtf d1,w2 ; D1 = Y%
fmov d3,d1 ; D3 = SY

ldr d4,[XMAX] ; D4 = XMax
ldr d5,[YMAX] ; D5 = YMax
ldr d6,[XMIN] ; D6 = XMin
ldr d7,[YMIN] ; D7 = YMin
ldr d8,[RMAX] ; D8 = RMax
ldr d9,[ONE]  ; D9 = 1.0
ldr d16,[ANIM] ; D16 = Anim

fsub d17,d4,d6 ; D17 = XMax - XMin
fsub d18,d5,d7 ; D18 = YMax - YMin
fdiv d19,d9,d2 ; D19 = (1.0 / SX)
fdiv d20,d9,d3 ; D20 = (1.0 / SY)

fmov d12,d9 ; D12 = CX (1.0)
fmov d13,d7 ; D13 = CY (-2.0)

ldr w12,[COL_MUL] ; W12 = Multiply Colour

Refresh:
  mov w2,w0 ; W2 = Frame Buffer Pointer
  mov w3,w1 ; W3 = Frame Buffer Pointer Last Pixel
  fmov d1,d3 ; D1 = Y%
  LoopY:
    fmov d0,d2 ; D0 = X%
    LoopX:
      fmul d10,d0,d17 ; ZX = XMin + ((X% * (XMax - XMin)) * (1.0 / SX))
      fmul d10,d10,d19
      fadd d10,d10,d6 ; D10 = ZX

      fmul d11,d1,d18 ; ZY = YMin + ((Y% * (YMax - YMin)) * (1.0 / SY))
      fmul d11,d11,d20
      fadd d11,d11,d7 ; D11 = ZY

      mov w4,192 ; W4 = IT (Iterations)
      Iterate:
	fmul d14,d10,d10 ; XN = ((ZX * ZX) - (ZY * ZY)) + CX
	fmsub d14,d11,d11,d14
	fadd d14,d14,d12 ; D14 = XN

	fmul d15,d10,d11 ; YN = (2 * ZX * ZY) + CY
	fadd d15,d15,d15
	fadd d15,d15,d13 ; D15 = YN

	fmov d10,d14 ; Copy XN & YN To ZX & ZY For Next Iteration
	fmov d11,d15

	fmul d14,d14,d14 ; R = (XN * XN) + (YN * YN)
	fmadd d14,d15,d15,d14 ; D14 = R

	fcmp d14,d8 ; IF (R > 4) Plot
	b.gt Plot

	subs w4,w4,1 ; IT -= 1
	b.ne Iterate ; IF (IT != 0) Iterate

      Plot:
	mul w4,w4,w12 ; W4 = Pixel Colour
	str w4,[x2],4  ; Store Pixel Colour To Frame Buffer (Top)
	str w4,[x3],-4 ; Store Pixel Colour To Frame Buffer (Bottom)

	fsub d0,d0,d9 ; Decrement X%
	fcmp d0,0.0
	b.ne LoopX ; IF (X% != 0) LoopX

	fsub d1,d1,d9 ; Decrement Y%
	cmp w2,w3 ; Compare Frame Buffer Top & Bottom
	b.lt LoopY ; IF (Y% < Frame Buffer Middle) LoopY

	fsub d12,d12,d16 ; Change Julia Settings
	fadd d13,d13,d16
	b Refresh

CoreLoop: ; Infinite Loop For Core 1..3
  b CoreLoop

align 8
XMAX: dd 3.0
YMAX: dd 2.0
XMIN: dd -3.0
YMIN: dd -2.0
RMAX: dd 4.0
ONE:  dd 1.0
ANIM: dd 0.001

COL_MUL: dw $231AF9 ; Multiply Colour
LAST_PIXEL: dw (SCREEN_X * SCREEN_Y * (BITS_PER_PIXEL / 8)) - (BITS_PER_PIXEL / 8)

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