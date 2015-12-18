; Raspberry Pi 'Bare Metal' Mandelbrot Fractal Demo by krom (Peter Lemon):
; 1. Turn On L1 Cache
; 2. Turn On Vector Floating Point Unit
; 3. Setup Frame Buffer
; 4. Plot Fractal Using Single-Precision

format binary as 'img'
include 'LIB\FASMARM.INC'
include 'LIB\R_PI.INC'

; Setup Frame Buffer
SCREEN_X       = 640
SCREEN_Y       = 480
BITS_PER_PIXEL = 32

org $0000

; Start L1 Cache
mrc p15,0,r0,c1,c0,0 ; R0 = System Control Register
orr r0,$0004 ; Data Cache (Bit 2)
orr r0,$0800 ; Branch Prediction (Bit 11)
orr r0,$1000 ; Instruction Caches (Bit 12)
mcr p15,0,r0,c1,c0,0 ; System Control Register = R0

; Enable Vector Floating Point Calculations
mrc p15,0,r0,c1,c0,2 ; R0 = Access Control Register
orr r0,$300000 + $C00000 ; Enable Single & Double Precision
mcr p15,0,r0,c1,c0,2 ; Access Control Register = R0
mov r0,$40000000 ; R0 = Enable VFP
fmxr fpexc,r0 ; FPEXC = R0

FB_Init:
  imm32 r0,FB_STRUCT + MAIL_TAGS
  imm32 r1,PERIPHERAL_BASE + MAIL_BASE + MAIL_WRITE + MAIL_TAGS
  str r0,[r1] ; Mail Box Write

  ldr r0,[FB_POINTER] ; R0 = Frame Buffer Pointer
  cmp r0,0 ; Compare Frame Buffer Pointer To Zero
  beq FB_Init ; IF Zero Re-Initialize Frame Buffer

  and r0,$3FFFFFFF ; Convert Mail Box Frame Buffer Pointer From BUS Address To Physical Address ($CXXXXXXX -> $3XXXXXXX)
  str r0,[FB_POINTER] ; Store Frame Buffer Pointer Physical Address

ldr r1,[LAST_PIXEL]
add r0,r1 ; R0 = Frame Buffer Pointer Last Pixel

mov r1,SCREEN_X ; Load Single Screen X
fmsr s31,r1
fsitos s0,s31 ; S0 = X%
fcpys s2,s0   ; S2 = SX

mov r1,SCREEN_Y ; Load Single Screen Y
fmsr s31,r1
fsitos s1,s31 ; S1 = Y%
fcpys s3,s1   ; S3 = SY

flds s4,[XMAX] ; S4 = XMax
flds s5,[YMAX] ; S5 = YMax
flds s6,[XMIN] ; S6 = XMin
flds s7,[YMIN] ; S7 = YMin
flds s8,[RMAX] ; S8 = RMax
flds s9,[ONE]  ; S9 = 1.0

fsubs s16,s4,s6 ; S16 = XMax - XMin
fsubs s17,s5,s7 ; S17 = YMax - YMin
fdivs s18,s9,s2 ; S18 = (1.0 / SX)
fdivs s19,s9,s3 ; S19 = (1.0 / SY)

ldr r12,[COL_MUL] ; R12 = Multiply Colour

LoopY:
  fcpys s0,s2 ; S0 = X%
  LoopX:
    fmuls s10,s0,s16 ; CX = XMin + ((X% * (XMax - XMin)) * (1.0 / SX))
    fmuls s10,s18
    fadds s10,s6 ; S10 = CX

    fmuls s11,s1,s17 ; CY = YMin + ((Y% * (YMax - YMin)) * (1.0 / SY))
    fmuls s11,s19
    fadds s11,s7 ; S11 = CY

    mov r1,192 ; R1 = IT (Iterations)
    fsubs s12,s12 ; S12 = ZX
    fsubs s13,s13 ; S13 = ZY

    Iterate:
      fmuls s14,s13,s13 ; XN = ((ZX * ZX) - (ZY * ZY)) + CX
      fmscs s14,s12,s12
      fadds s14,s10 ; S14 = XN

      fmuls s15,s12,s13 ; YN = (2 * ZX * ZY) + CY
      fadds s15,s15
      fadds s15,s11 ; S15 = YN

      fcpyd d6,d7 ; Copy XN & YN To ZX & ZY For Next Iteration

      fmuls s14,s12,s12 ; R = (XN * XN) + (YN * YN)
      fmacs s14,s13,s13 ; S14 = R

      fcmps s14,s8 ; IF (R > 4) Plot
      fmstat
      bgt Plot

      subs r1,1 ; IT -= 1
      bne Iterate ; IF (IT != 0) Iterate

    Plot:
      mul r1,r12 ; R1 = Pixel Colour
      str r1,[r0],-4 ; Store Pixel Colour To Frame Buffer

      fsubs s0,s9 ; Decrement X%
      fcmpzs s0
      fmstat
      bne LoopX ; IF (X% != 0) LoopX

      fsubs s1,s9 ; Decrement Y%
      fcmpzs s1
      fmstat
      bne LoopY ; IF (Y% != 0) LoopY

Loop:
  b Loop

XMAX: dw 1.0
YMAX: dw 1.0
XMIN: dw -2.0
YMIN: dw -1.0
RMAX: dw 4.0
ONE:  dw 1.0

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