; Raspberry Pi 3 'Bare Metal' Sound 13Bit Mono 48000Hz DMA Demo by krom (Peter Lemon):
; 1. Convert Sample To DMA
; 2. Set 3.5" Phone Jack To PWM
; 3. Setup PWM Sound Buffer
; 4. Setup DMA & DREQ
; 5. Play Sound Sample Using DMA & FIFO

code64
processor cpu64_v8
format binary as 'img'
include 'LIB\R_PI2.INC'

org $0000

; Return CPU ID (0..3) Of The CPU Executed On
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
ands x0,x0,3 ; X0 = CPU ID (Bits 0..1)
b.ne CoreLoop ; IF (CPU ID != 0) Branch To Infinite Loop (Core ID 1..3)

; Convert Sample
adr x0,SND_Sample
mov w1,DMA_Sample and $0000FFFF
mov w2,DMA_Sample and $FFFF0000
orr w1,w1,w2
mov w2,SND_SampleEOF and $0000FFFF
mov w3,SND_SampleEOF and $FFFF0000
orr w2,w2,w3
ConvertLoop:
  ldrh w3,[x0],2
  lsr w3,w3,3 ; Convert 16bit To 13bit
  str w3,[x1],4
  cmp w0,w2
  b.ne ConvertLoop

; Set GPIO 40 & 45 (Phone Jack) To Alternate PWM Function 0
mov w0,PERIPHERAL_BASE + GPIO_BASE
mov w1,GPIO_FSEL0_ALT0
orr w1,w1,GPIO_FSEL5_ALT0
str w1,[x0,GPIO_GPFSEL4]

; Set Clock
mov w0,(PERIPHERAL_BASE + CM_BASE) and $0000FFFF
mov w1,(PERIPHERAL_BASE + CM_BASE) and $FFFF0000
orr w0,w0,w1
mov w1,CM_PASSWORD
orr w1,w1,$2000 ; Bits 0..11 Fractional Part Of Divisor = 0, Bits 12..23 Integer Part Of Divisor = 2
str w1,[x0,CM_PWMDIV]

mov w1,CM_PASSWORD
orr w1,w1,CM_ENAB
orr w1,w1,CM_SRC_OSCILLATOR + CM_SRC_PLLCPER ; Use 650MHz PLLC Clock
str w1,[x0,CM_PWMCTL]

; Set PWM
mov w0,(PERIPHERAL_BASE + PWM_BASE) and $0000FFFF
mov w1,(PERIPHERAL_BASE + PWM_BASE) and $FFFF0000
orr w0,w0,w1
mov w1,$28A0 ; Range = 13bit 48000Hz Mono
str w1,[x0,PWM_RNG1]
str w1,[x0,PWM_RNG2]

mov w1,PWM_USEF2 + PWM_PWEN2 + PWM_USEF1 + PWM_PWEN1 + PWM_CLRF1
str w1,[x0,PWM_CTL]

mov w1,PWM_ENAB + $0001 ; Bits 0..7 DMA Threshold For DREQ Signal = 1, Bits 8..15 DMA Threshold For PANIC Signal = 0
str w1,[x0,PWM_DMAC] ; PWM DMA Enable

; Set DMA Channel 0 Enable Bit
mov w0,PERIPHERAL_BASE
mov w1,DMA_ENABLE
mov w2,DMA_EN0
str w2,[x0,x1]

; Set Control Block Data Address To DMA Channel 0 Controller
mov w0,PERIPHERAL_BASE
orr w0,w0,DMA0_BASE
adr x1,CB_STRUCT
str w1,[x0,DMA_CONBLK_AD]

mov w1,DMA_ACTIVE
str w1,[x0,DMA_CS] ; Start DMA

Loop:
  b Loop ; Play Sample Again

CoreLoop: ; Infinite Loop For Core 1..3
  b CoreLoop

align 32
CB_STRUCT: ; Control Block Data Structure
  dw DMA_DEST_DREQ + DMA_PERMAP_5 + DMA_SRC_INC ; DMA Transfer Information
  dw DMA_Sample ; DMA Source Address
  dw $7E000000 + PWM_BASE + PWM_FIF1 ; DMA Destination Address
  dw (SND_SampleEOF - SND_Sample) * 2 ; DMA Transfer Length
  dw 0 ; DMA 2D Mode Stride
  dw CB_STRUCT ; DMA Next Control Block Address

align 16
SND_Sample: ; 16bit 48000Hz Unsigned Little Endian Mono Sound Sample
  file 'Sample.bin'
  SND_SampleEOF:

align 16
DMA_Sample: