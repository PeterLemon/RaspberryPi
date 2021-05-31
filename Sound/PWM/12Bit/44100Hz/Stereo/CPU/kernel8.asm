; Raspberry Pi 3 'Bare Metal' Sound 12Bit Stereo 44100Hz CPU Demo by krom (Peter Lemon):
; 1. Set Cores 1..3 To Infinite Loop
; 2. Set 3.5" Phone Jack To PWM 
; 3. Setup PWM Sound Buffer
; 4. Play Sound Sample Using CPU & FIFO

code64
processor cpu64_v8
format binary as 'img'
include 'LIB\R_PI2.INC'

org $0000

; Return CPU ID (0..3) Of The CPU Executed On
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
ands x0,x0,3 ; X0 = CPU ID (Bits 0..1)
b.ne CoreLoop ; IF (CPU ID != 0) Branch To Infinite Loop (Core ID 1..3)

; Set GPIO 40 & 41 (Phone Jack) To Alternate PWM Function 0
mov w0,PERIPHERAL_BASE + GPIO_BASE
mov w1,GPIO_FSEL0_ALT0
orr w1,w1,GPIO_FSEL1_ALT0
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
mov w1,$1624 ; Range = 12bit 44100Hz Stereo
str w1,[x0,PWM_RNG1]
str w1,[x0,PWM_RNG2]

mov w1,PWM_USEF2 + PWM_PWEN2 + PWM_USEF1 + PWM_PWEN1 + PWM_CLRF1
str w1,[x0,PWM_CTL]

Loop:
  adr x1,SND_Sample ; X1 = Sound Sample
  mov w2,SND_SampleEOF and $0000FFFF ; W2 = End Of Sound Sample
  mov w3,SND_SampleEOF and $FFFF0000
  orr w2,w2,w3
  FIFO_Write:
    ldrh w3,[x1],2 ; Write 2 Bytes To FIFO (Channel 1)
    str w3,[x0,PWM_FIF1] ; FIFO Address
    ldrh w3,[x1],2 ; Write 2 Bytes To FIFO (Channel 2)
    str w3,[x0,PWM_FIF1] ; FIFO Address
    FIFO_Wait:
      ldr w3,[x0,PWM_STA]
      tst w3,PWM_FULL1 ; Test Bit 1 FIFO Full
      b.ne FIFO_Wait
    cmp w1,w2 ; Check End Of Sound Sample
    b.ne FIFO_Write

  b Loop ; Play Sample Again

CoreLoop: ; Infinite Loop For Core 1..3
  b CoreLoop

SND_Sample: ; 12bit 44100Hz Unsigned Little Endian Stereo Sample
  file 'Sample.bin'
  SND_SampleEOF: