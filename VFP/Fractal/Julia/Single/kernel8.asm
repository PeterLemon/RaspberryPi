; Raspberry Pi 3 'Bare Metal' Julia Fractal Animation Demo by krom (Peter Lemon):
; 1. Set Cores 1..3 To Infinite Loop
; 2. Turn On L1 Cache
; 3. Setup Frame Buffer
; 4. Plot Fractal Using Single-Precision
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

mov w2,SCREEN_X ; Load Single Screen X
ucvtf s0,w2 ; S0 = X%
fmov s2,s0 ; S2 = SX

mov w2,SCREEN_Y ; Load Single Screen Y
ucvtf s1,w2 ; S1 = Y%
fmov s3,s1 ; S3 = SY

ldr s4,[XMAX] ; S4 = XMax
ldr s5,[YMAX] ; S5 = YMax
ldr s6,[XMIN] ; S6 = XMin
ldr s7,[YMIN] ; S7 = YMin
ldr s8,[RMAX] ; S8 = RMax
ldr s9,[ONE]  ; S9 = 1.0
ldr s16,[ANIM] ; S16 = Anim

fsub s17,s4,s6 ; S17 = XMax - XMin
fsub s18,s5,s7 ; S18 = YMax - YMin
fdiv s19,s9,s2 ; S19 = (1.0 / SX)
fdiv s20,s9,s3 ; S20 = (1.0 / SY)

fmov s12,s9 ; S12 = CX (1.0)
fmov s13,s7 ; S13 = CY (-2.0)

ldr w12,[COL_MUL] ; W12 = Multiply Colour

Refresh:
  mov w2,w0 ; W2 = Frame Buffer Pointer
  mov w3,w1 ; W3 = Frame Buffer Pointer Last Pixel
  fmov s1,s3 ; S1 = Y%
  LoopY:
    fmov s0,s2 ; S0 = X%
    LoopX:
      fmul s10,s0,s17 ; ZX = XMin + ((X% * (XMax - XMin)) * (1.0 / SX))
      fmul s10,s10,s19
      fadd s10,s10,s6 ; S10 = ZX

      fmul s11,s1,s18 ; ZY = YMin + ((Y% * (YMax - YMin)) * (1.0 / SY))
      fmul s11,s11,s20
      fadd s11,s11,s7 ; S11 = ZY

      mov w4,192 ; W4 = IT (Iterations)
      Iterate:
	fmul s14,s10,s10 ; XN = ((ZX * ZX) - (ZY * ZY)) + CX
	fmsub s14,s11,s11,s14
	fadd s14,s14,s12 ; S14 = XN

	fmul s15,s10,s11 ; YN = (2 * ZX * ZY) + CY
	fadd s15,s15,s15
	fadd s15,s15,s13 ; S15 = YN

	fmov s10,s14 ; Copy XN & YN To ZX & ZY For Next Iteration
	fmov s11,s15

	fmul s14,s14,s14 ; R = (XN * XN) + (YN * YN)
	fmadd s14,s15,s15,s14 ; S14 = R

	fcmp s14,s8 ; IF (R > 4) Plot
	b.gt Plot

	subs w4,w4,1 ; IT -= 1
	b.ne Iterate ; IF (IT != 0) Iterate

      Plot:
	mul w4,w4,w12 ; W4 = Pixel Colour
	str w4,[x2],4  ; Store Pixel Colour To Frame Buffer (Top)
	str w4,[x3],-4 ; Store Pixel Colour To Frame Buffer (Bottom)

	fsub s0,s0,s9 ; Decrement X%
	fcmp s0,0.0
	b.ne LoopX ; IF (X% != 0) LoopX

	fsub s1,s1,s9 ; Decrement Y%
	cmp w2,w3 ; Compare Frame Buffer Top & Bottom
	b.lt LoopY ; IF (Y% < Frame Buffer Middle) LoopY

	fsub s12,s12,s16 ; Change Julia Settings
	fadd s13,s13,s16
	b Refresh

CoreLoop: ; Infinite Loop For Core 1..3
  b CoreLoop

XMAX: dw 3.0
YMAX: dw 2.0
XMIN: dw -3.0
YMIN: dw -2.0
RMAX: dw 4.0
ONE:  dw 1.0
ANIM: dw 0.001

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