; Raspberry Pi 2 'Bare Metal' Sound 14Bit Mono 44100Hz DMA Demo by krom (Peter Lemon):
; 1. Convert Sample To DMA
; 2. Set 3.5" Phone Jack To PWM
; 3. Setup PWM Sound Buffer
; 4. Setup DMA & DREQ
; 5. Play Sound Sample Using DMA & FIFO

format binary as 'img'
include 'LIB\FASMARM.INC'
include 'LIB\R_PI2.INC'

org $0000

; Return CPU ID (0..3) Of The CPU Executed On
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
ands r0,3 ; R0 = CPU ID (Bits 0..1)
bne CoreLoop ; IF (CPU ID != 0) Branch To Infinite Loop (Core ID 1..3)

; Convert Sample
imm32 r0,SND_Sample
imm32 r1,DMA_Sample
imm32 r2,SND_SampleEOF
ConvertLoop:
  ldrh r3,[r0],2
  mov r3,r3,lsr 2 ; Convert 16bit To 14bit
  str r3,[r1],4
  cmp r0,r2
  bne ConvertLoop

; Set GPIO 40 & 45 (Phone Jack) To Alternate PWM Function 0
imm32 r0,PERIPHERAL_BASE + GPIO_BASE
imm32 r1,GPIO_FSEL0_ALT0 + GPIO_FSEL5_ALT0
str r1,[r0,GPIO_GPFSEL4]

; Set Clock
imm32 r0,PERIPHERAL_BASE + CM_BASE
imm32 r1,CM_PASSWORD + $2000 ; Bits 0..11 Fractional Part Of Divisor = 0, Bits 12..23 Integer Part Of Divisor = 2
str r1,[r0,CM_PWMDIV]

imm32 r1,CM_PASSWORD + CM_ENAB + CM_SRC_PLLCPER + CM_SRC_OSCILLATOR ; Use 650MHz PLLC Clock
str r1,[r0,CM_PWMCTL]

; Set PWM
imm32 r0,PERIPHERAL_BASE + PWM_BASE
imm32 r1,$2C48 ; Range = 14bit 44100Hz Mono
str r1,[r0,PWM_RNG1]
str r1,[r0,PWM_RNG2]

imm32 r1,PWM_USEF2 + PWM_PWEN2 + PWM_USEF1 + PWM_PWEN1 + PWM_CLRF1
str r1,[r0,PWM_CTL]

imm32 r1,PWM_ENAB + $0001 ; Bits 0..7 DMA Threshold For DREQ Signal = 1, Bits 8..15 DMA Threshold For PANIC Signal = 0
str r1,[r0,PWM_DMAC] ; PWM DMA Enable

; Set DMA Channel 0 Enable Bit
imm32 r0,PERIPHERAL_BASE + DMA_ENABLE
mov r1,DMA_EN0
str r1,[r0]

; Set Control Block Data Address To DMA Channel 0 Controller
imm32 r0,PERIPHERAL_BASE + DMA0_BASE
imm32 r1,CB_STRUCT
str r1,[r0,DMA_CONBLK_AD]

mov r1,DMA_ACTIVE
str r1,[r0,DMA_CS] ; Start DMA

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
SND_Sample: ; 16bit 44100Hz Unsigned Little Endian Mono Sound Sample
  file 'Sample.bin'
  SND_SampleEOF:

align 16
DMA_Sample: