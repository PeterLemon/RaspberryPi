; Raspberry Pi 'Bare Metal' Nintendo Game Boy Emulator by krom (Peter Lemon):
; (Special thanks to blargg for his Game Boy CPU Tests)
; 1. Turn On L1 Cache
; 2. Setup Game Boy Z80 CPU
; 3. Emulate Game Boy Cartridge Data using BLX Opcode Branch Table
; 4. Display Game Boy Background using DMA 2D Mode & Stride

format binary as 'img'
include 'LIB\FASMARM.INC'
include 'LIB\R_PI.INC'
include 'MEM.INC'

; Setup Frame Buffer
SCREEN_X       = 256
SCREEN_Y       = 256
;SCREEN_X	= 160 ; UNREM These 2 Lines To See BIOS Nintendo Logo Scroll
;SCREEN_Y	= 144
VSCREEN_X      = 256
VSCREEN_Y      = 256
BITS_PER_PIXEL = 8

; Setup Characters
CHAR_X = 8
CHAR_Y = 8

; F Register (CPU Flag Register ZNHC0000 Low 4 Bits Always Zero)
C_FLAG = $10 ; F Register Bit 4 Carry Flag
H_FLAG = $20 ; F Register Bit 5 Half Carry Flag
N_FLAG = $40 ; F Register Bit 6 Negative Flag
Z_FLAG = $80 ; F Register Bit 7 Zero Flag

org $0000

; Start L1 Cache
mov r0,0
mcr p15,0,r0,c7,c7,0 ; Invalidate Caches
mcr p15,0,r0,c8,c7,0 ; Invalidate TLB
mrc p15,0,r0,c1,c0,0 ; Read Control Register Configuration Data
orr r0,$1000 ; Instruction
orr r0,$0004 ; Data
orr r0,$0800 ; Branch Prediction
mcr p15,0,r0,c1,c0,0 ; Write Control Register Configuration Data

; Setup CPU Registers
mov r0,0 ; R0 = 16-Bit Register AF (Bits 0..7 = F, Bits 8..15 = A)
mov r1,0 ; R1 = 16-Bit Register BC (Bits 0..7 = C, Bits 8..15 = B)
mov r2,0 ; R2 = 16-Bit Register DE (Bits 0..7 = E, Bits 8..15 = D)
mov r3,0 ; R3 = 16-Bit Register HL (Bits 0..7 = L, Bits 8..15 = H)
mov r4,0 ; R4 = 16-Bit Register PC (Program Counter)
mov sp,0 ; SP = 16-Bit Register SP (Stack Pointer)

; Copy 32768 Bytes Cartridge ROM To Memory Map
imm32 r5,PERIPHERAL_BASE + DMA_ENABLE ; Set DMA Channel 0 Enable Bit
mov r6,DMA_EN0
str r6,[r5]

imm32 r5,CART_STRUCT ; Set Control Block Data Address To DMA controller
imm32 r6,PERIPHERAL_BASE + DMA0_BASE + DMA_CONBLK_AD
str r5,[r6]
mov r5,DMA_ACTIVE ; Set Start Bit
imm32 r6,PERIPHERAL_BASE + DMA0_BASE + DMA_CS
str r5,[r6]
DMACartWait:
  ldr r5,[r6] ; Load Control Block Status
  tst r5,DMA_ACTIVE ; Test Active bit
  bne DMACartWait ; Wait Until DMA Has Finished

; Copy 256 Bytes BIOS ROM To Memory Map
imm32 r5,BIOS_STRUCT ; Set Control Block Data Address To DMA Controller
imm32 r6,PERIPHERAL_BASE + DMA0_BASE + DMA_CONBLK_AD
str r5,[r6]
mov r5,DMA_ACTIVE ; Set Start Bit
imm32 r6,PERIPHERAL_BASE + DMA0_BASE + DMA_CS
str r5,[r6]
DMABiosWait:
  ldr r5,[r6] ; Load Control Block Status
  tst r5,DMA_ACTIVE ; Test Active bit
  bne DMABiosWait ; Wait Until DMA Has Finished

Refresh: ; Refresh At 60 Hz
  imm32 r9,CPU_INST ; R9 = CPU Instruction Table
  imm32 r10,MEM_MAP ; R10 = MEM_MAP
  imm16 r11,$4444 ; R11 = Quad Cycles Refresh Rate (4194304 Hz / 60 Hz = 69905 CPU Cycles / 4 = 17476 Quad Cycles)
  mov r12,0 ; R12 = Reset QCycles
  CPU_EMU:
    ldrb r5,[r10,r4] ; R5 = CPU Instruction
    ldr r5,[r9,r5,lsl 2] ; R5 = CPU Instruction Table Opcode
    add r4,1 ; PC_REG++
    blx r5 ; Run CPU Instruction

    include 'IOPORT.asm' ; Run IO Port
    cmp r12,r11 ; Compare Quad Cycles Counter
    blt CPU_EMU

  include 'VIDEO.asm' ; Run Video
  b Refresh

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
  dw VSCREEN_X ; Value Buffer
  dw VSCREEN_Y ; Value Buffer

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
  dw $00000018 ; Value Buffer Size In Bytes
  dw $00000018 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw 0 ; Value Buffer (Offset: First Palette Index To Set (0-255))
  dw 4 ; Value Buffer (Length: Number Of Palette Entries To Set (1-256))
FB_PAL:
  dw $FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF ; RGBA Palette Values (Offset To Offset+Length-1)

  dw Allocate_Buffer ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
FB_POINTER:
  dw 0 ; Value Buffer
  dw 0 ; Value Buffer

dw $00000000 ; $0 (End Tag)
FB_STRUCT_END:

align 32
BIOS_STRUCT: ; Control Block Data Structure
  dw DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
  dw GB_BIOS ; DMA Source Address
  dw MEM_MAP ; DMA Destination Address
  dw 256 ; DMA Transfer Length
  dw 0 ; DMA 2D Mode Stride
  dw 0 ; DMA Next Control Block Address

align 32
CART_STRUCT: ; Control Block Data Structure
  dw DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
CART_SRC:
  dw GB_CART ; DMA Source Address
  dw MEM_MAP ; DMA Destination Address
  dw $8000 ; DMA Transfer Length
  dw 0 ; DMA 2D Mode Stride
  dw 0 ; DMA Next Control Block Address

align 32
CHAR_STRUCT: ; Control Block Data Structure
  dw DMA_TDMODE + DMA_DEST_INC + DMA_DEST_WIDTH + DMA_SRC_INC + DMA_SRC_WIDTH ; DMA Transfer Information
CHAR_SOURCE:
  dw 0 ; DMA Source Address
CHAR_DEST:
  dw 0 ; DMA Destination Address
  dw (CHAR_X * (BITS_PER_PIXEL / 8)) + ((CHAR_Y - 1) * 65536) ; DMA Transfer Length
  dw ((VSCREEN_X * (BITS_PER_PIXEL / 8)) - (CHAR_X * (BITS_PER_PIXEL / 8))) * 65536 ; DMA 2D Mode Stride
  dw 0 ; DMA Next Control Block Address

LCDQCycles: dw 0 ; LCD Quad Cycle Count
DIVQCycles: dw 0 ; Divider Register Quad Cycle Count
OldQCycles: dw 0 ; Previous Quad Cycle Count
OldMode: dw 0 ; Previous LCD STAT Mode
OldTAC_REG: dw 4 ; Previous TAC_REG (4096Hz)
TimerQCycles: dw 0 ; Timer Quad Cycles
IME_FLAG: dw 0 ; (IME) Interrupt Master Enable Flag (0 = Disable Interrupts, 1 = Enable Interrupts, Enabled In IE Register)

CPU_INST:
  include 'CPU.asm' ; CPU Instruction Table

align 16
GB_BIOS: file 'DMG_ROM.bin' ; Include Game Boy DMG BIOS ROM

;GB_CART: file 'ROMS\HelloWorld.gb'

GB_CART: file 'ROMS\cpu_instrs\01-special.gb' ; PASSED
;GB_CART: file 'ROMS\cpu_instrs\02-interrupts.gb' ; PASSED
;GB_CART: file 'ROMS\cpu_instrs\03-op sp,hl.gb' ; PASSED
;GB_CART: file 'ROMS\cpu_instrs\04-op r,imm.gb' ; PASSED
;GB_CART: file 'ROMS\cpu_instrs\05-op rp.gb' ; PASSED
;GB_CART: file 'ROMS\cpu_instrs\06-ld r,r.gb' ; PASSED
;GB_CART: file 'ROMS\cpu_instrs\07-jr,jp,call,ret,rst.gb' ; PASSED
;GB_CART: file 'ROMS\cpu_instrs\08-misc instrs.gb' ; PASSED
;GB_CART: file 'ROMS\cpu_instrs\09-op r,r.gb' ; PASSED
;GB_CART: file 'ROMS\cpu_instrs\10-bit ops.gb' ; PASSED
;GB_CART: file 'ROMS\cpu_instrs\11-op a,(hl).gb' ; PASSED
;GB_CART: file 'ROMS\instr_timing.gb' ; PASSED

MEM_MAP: ; Memory Map = $10000 Bytes