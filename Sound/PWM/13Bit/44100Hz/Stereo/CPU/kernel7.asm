; Raspberry Pi 2 'Bare Metal' Sound 13Bit Stereo 44100Hz CPU Demo by krom (Peter Lemon):
; 1. Set 3.5" Phone Jack To PWM 
; 2. Setup PWM Sound Buffer
; 3. Play Sound Sample Using CPU & FIFO

format binary as 'img'
include 'LIB\FASMARM.INC'
include 'LIB\R_PI2.INC'

org $0000

; Return CPU ID (0..3) Of The CPU Executed On
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
ands r0,3 ; R0 = CPU ID (Bits 0..1)
bne CoreLoop ; IF (CPU ID != 0) Branch To Infinite Loop (Core ID 1..3)

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
imm32 r1,$1624 ; Range = 13bit 44100Hz Stereo
str r1,[r0,PWM_RNG1]
str r1,[r0,PWM_RNG2]

imm32 r1,PWM_USEF2 + PWM_PWEN2 + PWM_USEF1 + PWM_PWEN1 + PWM_CLRF1
str r1,[r0,PWM_CTL]

Loop:
  imm32 r1,SND_Sample ; R1 = Sound Sample
  imm32 r2,SND_SampleEOF ; R2 = End Of Sound Sample
  FIFO_Write:
    ldrh r3,[r1],2 ; Write 2 Bytes To FIFO (Channel 1)
    mov r3,r3,lsr 3 ; Convert 16bit To 13bit
    str r3,[r0,PWM_FIF1] ; FIFO Address
    ldrh r3,[r1],2 ; Write 2 Bytes To FIFO (Channel 2)
    mov r3,r3,lsr 3 ; Convert 16bit To 13bit
    str r3,[r0,PWM_FIF1] ; FIFO Address
    FIFO_Wait:
      ldr r3,[r0,PWM_STA]
      tst r3,PWM_FULL1 ; Test Bit 1 FIFO Full
      bne FIFO_Wait
    cmp r1,r2 ; Check End Of Sound Sample
    bne FIFO_Write

  b Loop ; Play Sample Again

CoreLoop: ; Infinite Loop For Core 1..3
  b CoreLoop

SND_Sample: ; 16bit 44100Hz Unsigned Little Endian Stereo Sample
  file 'Sample.bin'
  SND_SampleEOF: