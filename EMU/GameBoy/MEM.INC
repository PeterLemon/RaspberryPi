;========= (Key: R=Read, W=Write, D=Double Read/Write)
; GameBoy
;=========
; Memory Map
; $0000..$00FF - Interrupt Vectors & RST # Vectors                                                       256B/R
; $0000..$00FF - DMG Boot Code (Only At Initialization)                                                  256B/R

CART_HEAD   = $0100 ; $0100..$014F - Cartridge Header                                                     80B/R
MBC_TYPE    = $0147 ; $0147 - Memory Bank Controller Type                                                  1B/R

CART_ROM0   = $0150 ; $0150..$3FFF - User Program Area - Bank 0 (Fixed)                                16048B/R
CART_ROM1   = $4000 ; $4000..$7FFF - User Program Area - Bank 1..N (Switchable)                          16KB/R
CHAR_RAM    = $8000 ; $8000..$97FF - Bank 0 & 1 Character Data (Bank Switched)                            2KB/RW
BG1_RAM     = $9800 ; $9800..$9BFF - Background Display Data 1, Tile Indices/Attributes (Bank Switched)   1KB/RW
BG2_RAM     = $9C00 ; $9C00..$9FFF - Background Display Data 2, Tile Indices/Attributes (Bank Switched)   1KB/RW
CART_RAM    = $A000 ; $A000..$BFFF - Switchable Cartridge RAM Bank                                        8KB/RW
IRAM0       = $C000 ; $C000..$CFFF - Internal RAM - Bank 0 (Fixed)                                        4KB/RW
IRAM1       = $D000 ; $D000..$DFFF - Internal RAM - Bank 1..7 (CGB Switchable Between 32KB IRAM)          4KB/RW
ECHO_IRAM   = $E000 ; $E000..$FDFF - Echo Of Internal RAM (Reserved)                                    7680B/RW
OAM_RAM     = $FE00 ; $FE00..$FE9F - Sprite Object Attribute Memory (OAM)                                160B/RW
IO_PORT_REG = $FF00 ; $FF00..$FF7F - Hardware I/O Port Register                                          128B/RW
ZP_IRAM     = $FF80 ; $FF80..$FFFE - Zero Page Internal RAM                                              127B/RW

; Hardware I/O Ports

; Serial Ports
P1_REG = $FF00 ; P1: Read Joypad Info                                                                      1B/--WWRRRR
SB_REG = $FF01 ; SB: Serial Transfer Data                                                                  1B/RW
SC_REG = $FF02 ; SC: Serial I/O Control                                                                    1B/RW

; Timer Ports
DIV_REG  = $FF04 ; DIV:  Timer Divider                                                                     1B/RW
TIMA_REG = $FF05 ; TIMA: Timer Counter                                                                     1B/RW
TMA_REG  = $FF06 ; TMA:  Timer Modulo                                                                      1B/RW
TAC_REG  = $FF07 ; TAC:  Timer Control (Timer Speed 0..1, Timer Start/Stop 2)                              1B/RW

; Interrupt Port
IF_REG = $FF0F ; IF: Interrupt Flag                                                                        1B/RW

; APU Audio Processing Unit Ports
NR10_REG = $FF10 ; NR10: Audio Sweep         (Sweep Shift = 0..2, Sweep Inc/Dec 3, Sweep Time 4..6)        1B/RW

NR11_REG = $FF11 ; NR11: Audio Channel #1    (Sound Length Data 0..5, Wave Pattern Duty 6..7)              1B/RW
NR12_REG = $FF12 ; NR12: Envelope Channel #1 (Env Sweep # 0..2, Env Up/Down 3, Env Init Value 4..7)        1B/RW
NR13_REG = $FF13 ; NR13: Sound Frequency #1  (Frequency LSB)                                               1B/W
NR14_REG = $FF14 ; NR14: Sound Frequency #1  (Frequency MS3 Bits 0..2, Count/Consecutive Select 6, Init 7) 1B/W

NR21_REG = $FF16 ; NR21: Audio Channel #2    (Sound Length Data 0..5, Wave Pattern Duty 6..7)              1B/RW
NR22_REG = $FF17 ; NR22: Envelope Channel #2 (Env Sweep # 0..2, Env Up/Down 3, Env Init Value 4..7)        1B/RW
NR23_REG = $FF18 ; NR23: Sound Frequency #2  (Frequency LSB)                                               1B/W
NR24_REG = $FF19 ; NR24: Sound Frequency #2  (Frequency MS3 Bits 0..2, Count/Consecutive Select 6, Init 7) 1B/W

NR30_REG = $FF1A ; NR30: Audio Channel #3    (Sound On/Off 7)                                              1B/RW
NR31_REG = $FF1B ; NR31: Sound Length #3     (Sound Length)                                                1B/RW
NR32_REG = $FF1C ; NR32: Volume #3           (Select Output Level 5..6)                                    1B/RW
NR33_REG = $FF1D ; NR33: Sound Frequency #3  (Frequency LSB)                                               1B/W
NR34_REG = $FF1E ; NR34: Sound Frequency #3  (Frequency MS3 Bits 0..2, Count/Consecutive Select 6, Init 7) 1B/W

NR41_REG = $FF20 ; NR41: Sound Length #4     (Sound Length 0..5)                                           1B/RW
NR42_REG = $FF21 ; NR42: Envelope Channel #4 (Env Sweep # 0..2, Env Up/Down 3, Env Init Value 4..7)        1B/RW
NR43_REG = $FF22 ; NR43: Audio Counter       (Div Ratio 0..2, Polynomial Step 3, Polynomial Freq 4..7)     1B/RW
NR44_REG = $FF23 ; NR44: Audio Counter       (Count/Consecutive Select 6, Init Audio 7)                    1B/RW

NR50_REG = $FF24 ; NR50: Channel Control     (SO1 VOUT 0..2, VIN SO1 3, SO2 VOUT 4..6, VIN SO2 7)          1B/RW
NR51_REG = $FF25 ; NR51: Sound Output        (Sound 1..4 To SO1 0..3, Sound 1..4 To SO2 4..7)              1B/RW
NR52_REG = $FF26 ; NR52: Sound On/Off        (Channel #1..4 On/Off 0..3, All Channels On/Off 7)            1B/RW

AUD3WAVERAM = $FF30 ; $FF30..$FF3F (AUD3WAVERAM) Wave Data (Sound Sample RAM)                             16B/RW

; PPU Picture Processing Unit Ports
LCDC_REG = $FF40 ; LCDC: LCD Control     (BG 0, Obj 1, OBJ Size 2, BG ADDR 3..4, WIN 5, WIN ADDR 6, LCD 7) 1B/RW
STAT_REG = $FF41 ; STAT: LCD Status      (VRAM/OAM Lock 0..1, Coinc 2, Mode0..2 H/VBlank 3..5, LYCEQULY 6) 1B/RW
SCY_REG  = $FF42 ; SCY:  Scroll Screen Y (Vertical Scroll)                                                 1B/RW
SCX_REG  = $FF43 ; SCX:  Scroll Screen X (Horizontal Scroll)                                               1B/RW
LY_REG   = $FF44 ; LY:   LCDC Y-Coord                                                                      1B/RW
LYC_REG  = $FF45 ; LYC:  LY Compare                                                                        1B/RW
DMA_REG  = $FF46 ; DMA:  DMA Transfer                                                                      1B/RW
BGP_REG  = $FF47 ; BGP:  BG Palette Data                                                                   1B/RW
OBP0_REG = $FF48 ; OBP0: Object Palette 0 Data                                                             1B/RW
OBP1_REG = $FF49 ; OBP1: Object Palette 1 Data                                                             1B/RW
WY_REG   = $FF4A ; WY:   Window Y Position                                                                 1B/RW
WX_REG   = $FF4B ; WX:   Window X Position                                                                 1B/RW

; System Ports
KEY1_REG = $FF4D ; KEY1: CPU Speed Select      (GBC Only)                                                  1B/RW
VBK_REG  = $FF4F ; VBK:  VRAM Bank Select      (GBC Only)                                                  1B/RW
DMG_REG  = $FF50 ; DMG:   DMG Bank Select                                                                  1B/RW

HDMA1_REG = $FF51 ; HDMA1: HBL General DMA     (GBC Only)                                                  1B/RW
HDMA2_REG = $FF52 ; HDMA2: HBL General DMA     (GBC Only)                                                  1B/RW
HDMA3_REG = $FF53 ; HDMA3: HBL General DMA     (GBC Only)                                                  1B/RW
HDMA4_REG = $FF54 ; HDMA4: HBL General DMA     (GBC Only)                                                  1B/RW
HDMA5_REG = $FF55 ; HDMA5: HBL General DMA     (GBC Only)                                                  1B/RW
RP_REG    = $FF56 ; RP:    Infrared Comms      (GBC Only)                                                  1B/RW
BCPS_REG  = $FF68 ; BCPS:  BG Colour Index     (GBC Only)                                                  1B/RW
BCPD_REG  = $FF69 ; BCPD:  BG Colour Data      (GBC Only)                                                  1B/RW
OCPS_REG  = $FF6A ; OCPS:  Object Colour Index (GBC Only)                                                  1B/RW
OCPD_REG  = $FF6B ; OCPD:  Object Colour Data  (GBC Only)                                                  1B/RW
SVBK_REG  = $FF70 ; SVBK:  RAM Bank Select     (GBC Only)                                                  1B/RW

IE_REG    = $FFFF ; IE: Interrupt Enable Flag Register                                                     1B/RW
VBL_FLAG  =    $1 ; IE: Bit 0 VBL                                                                          1B/RW
LCDC_FLAG =    $2 ; IE: Bit 1 LCDC                                                                         1B/RW
TOF_FLAG  =    $4 ; IE: Bit 2 Timer Overflow                                                               1B/RW
SIO_FLAG  =    $8 ; IE: Bit 3 Serial I/O Transfer Done                                                     1B/RW
HILO_FLAG =   $10 ; IE: Bit 4 HILO Transition                                                              1B/RW