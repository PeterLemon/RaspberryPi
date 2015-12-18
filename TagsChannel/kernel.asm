; Raspberry Pi 'Bare Metal' Multiple Tags Demo by krom (Peter Lemon):
; 1. Run Tags & Populate Values
; 2. Setup Frame Buffer
; 3. Copy Tags Value HEX Characters To Frame Buffer Using CPU

macro PrintText Text, TextLength {
  local .DrawChars,.DrawChar
  imm32 r1,Font ; R1 = Characters
  imm32 r2,Text ; R2 = Text Offset
  mov r3,TextLength ; R3 = Number Of Text Characters To Print
  .DrawChars:
    mov r4,CHAR_Y ; R4 = Character Row Counter
    ldrb r5,[r2],1 ; R5 = Next Text Character
    add r5,r1,r5,lsl 6 ; Add Shift To Correct Position In Font (* 64)

    .DrawChar:
      ldr r6,[r5],4 ; Load Font Text Character 1/2 Row
      str r6,[r0],4 ; Store Font Text Character 1/2 Row To Frame Buffer
      ldr r6,[r5],4 ; Load Font Text Character 1/2 Row
      str r6,[r0],4 ; Store Font Text Character 1/2 Row To Frame Buffer
      add r0,SCREEN_X ; Jump Down 1 Scanline
      sub r0,CHAR_X ; Jump Back 1 Char
      subs r4,1 ; Decrement Character Row Counter
      bne .DrawChar ; IF (Character Row Counter != 0) DrawChar

    subs r3,1 ; Subtract Number Of Text Characters To Print
    sub r0,SCREEN_X * CHAR_Y ; Jump To Top Of Char
    add r0,CHAR_X ; Jump Forward 1 Char
    bne .DrawChars ; IF (Number Of Text Characters != 0) Continue To Print Characters
}

macro PrintValueLE Value, ValueLength {
  local .DrawHEXChars,.DrawHEXChar,.DrawHEXCharB
  imm32 r1,Font ; R1 = Characters
  imm32 r2,Value ; R2 = Text Offset
  add r2,ValueLength - 1
  mov r3,ValueLength ; R3 = Number Of HEX Characters To Print
  .DrawHEXChars:
    ldrb r4,[r2],-1 ; R4 = Next 2 HEX Characters
    mov r5,r4,lsr 4 ; Get 2nd Nibble
    cmp r5,$9
    addle r5,$30
    addgt r5,$37
    add r5,r1,r5,lsl 6 ; Add Shift To Correct Position In Font (* 64)
    mov r6,CHAR_Y ; R6 = Character Row Counter
    .DrawHEXChar:
      ldr r7,[r5],4 ; Load Font Text Character 1/2 Row
      str r7,[r0],4 ; Store Font Text Character 1/2 Row To Frame Buffer
      ldr r7,[r5],4 ; Load Font Text Character 1/2 Row
      str r7,[r0],4 ; Store Font Text Character 1/2 Row To Frame Buffer
      add r0,SCREEN_X ; Jump Down 1 Scanline
      sub r0,CHAR_X ; Jump Back 1 Char
      subs r6,1 ; Decrement Character Row Counter
      bne .DrawHEXChar ; IF (Character Row Counter != 0) DrawChar

    sub r0,SCREEN_X * CHAR_Y ; Jump To Top Of Char

    add r0,CHAR_X ; Jump Forward 1 Char
    and r5,r4,$F ; Get 1st Nibble
    cmp r5,$9
    addle r5,$30
    addgt r5,$37
    add r5,r1,r5,lsl 6 ; Add Shift To Correct Position In Font (* 64)
    mov r6,CHAR_Y ; R6 = Character Row Counter
    .DrawHEXCharB:
      ldr r7,[r5],4 ; Load Font Text Character 1/2 Row
      str r7,[r0],4 ; Store Font Text Character 1/2 Row To Frame Buffer
      ldr r7,[r5],4 ; Load Font Text Character 1/2 Row
      str r7,[r0],4 ; Store Font Text Character 1/2 Row To Frame Buffer
      add r0,SCREEN_X ; Jump Down 1 Scanline
      sub r0,CHAR_X ; Jump Back 1 Char
      subs r6,1 ; Decrement Character Row Counter
      bne .DrawHEXCharB ; IF (Character Row Counter != 0) DrawChar

    subs r3,1 ; Subtract Number Of HEX Characters To Print
    sub r0,SCREEN_X * CHAR_Y ; Jump To Top Of Char
    add r0,CHAR_X ; Jump Forward 1 Char
    bne .DrawHEXChars ; IF (Number Of Hex Characters != 0) Continue To Print Characters
}

macro PrintValueBE Value, ValueLength {
  local .DrawHEXChars,.DrawHEXChar,.DrawHEXCharB
  imm32 r1,Font ; R1 = Characters
  imm32 r2,Value ; R2 = Text Offset
  mov r3,ValueLength ; R3 = Number Of HEX Characters To Print
  .DrawHEXChars:
    ldrb r4,[r2],1 ; R4 = Next 2 HEX Characters
    mov r5,r4,lsr 4 ; Get 2nd Nibble
    cmp r5,$9
    addle r5,$30
    addgt r5,$37
    add r5,r1,r5,lsl 6 ; Add Shift To Correct Position In Font (* 64)
    mov r6,CHAR_Y ; R6 = Character Row Counter
    .DrawHEXChar:
      ldr r7,[r5],4 ; Load Font Text Character 1/2 Row
      str r7,[r0],4 ; Store Font Text Character 1/2 Row To Frame Buffer
      ldr r7,[r5],4 ; Load Font Text Character 1/2 Row
      str r7,[r0],4 ; Store Font Text Character 1/2 Row To Frame Buffer
      add r0,SCREEN_X ; Jump Down 1 Scanline
      sub r0,CHAR_X ; Jump Back 1 Char
      subs r6,1 ; Decrement Character Row Counter
      bne .DrawHEXChar ; IF (Character Row Counter != 0) DrawChar

    sub r0,SCREEN_X * CHAR_Y ; Jump To Top Of Char

    add r0,CHAR_X ; Jump Forward 1 Char
    and r5,r4,$F ; Get 1st Nibble
    cmp r5,$9
    addle r5,$30
    addgt r5,$37
    add r5,r1,r5,lsl 6 ; Add Shift To Correct Position In Font (* 64)
    mov r6,CHAR_Y ; R6 = Character Row Counter
    .DrawHEXCharB:
      ldr r7,[r5],4 ; Load Font Text Character 1/2 Row
      str r7,[r0],4 ; Store Font Text Character 1/2 Row To Frame Buffer
      ldr r7,[r5],4 ; Load Font Text Character 1/2 Row
      str r7,[r0],4 ; Store Font Text Character 1/2 Row To Frame Buffer
      add r0,SCREEN_X ; Jump Down 1 Scanline
      sub r0,CHAR_X ; Jump Back 1 Char
      subs r6,1 ; Decrement Character Row Counter
      bne .DrawHEXCharB ; IF (Character Row Counter != 0) DrawChar

    subs r3,1 ; Subtract Number Of HEX Characters To Print
    sub r0,SCREEN_X * CHAR_Y ; Jump To Top Of Char
    add r0,CHAR_X ; Jump Forward 1 Char
    bne .DrawHEXChars ; IF (Number Of Hex Characters != 0) Continue To Print Characters
}

macro PrintTAGValueLE Text, TextLength, Value, ValueLength {
  PrintText Text, TextLength
  PrintValueLE Value, ValueLength
}

macro PrintTAGValueBE Text, TextLength, Value, ValueLength {
  PrintText Text, TextLength
  PrintValueBE Value, ValueLength
}

format binary as 'img'
include 'LIB\FASMARM.INC'
include 'LIB\R_PI.INC'

; Setup Frame Buffer
SCREEN_X       = 640
SCREEN_Y       = 480
BITS_PER_PIXEL = 8

; Setup Characters
CHAR_X = 8
CHAR_Y = 8

org $0000

; Run Tags
imm32 r0,PERIPHERAL_BASE + MAIL_BASE
imm32 r1,TAGS_STRUCT
orr r1,MAIL_TAGS
str r1,[r0,MAIL_WRITE] ; Mail Box Write

FB_Init:
  imm32 r0,FB_STRUCT + MAIL_TAGS
  imm32 r1,PERIPHERAL_BASE + MAIL_BASE + MAIL_WRITE + MAIL_TAGS
  str r0,[r1] ; Mail Box Write

  imm32 r1,FB_POINTER
  ldr r10,[r1] ; R10 = Frame Buffer Pointer
  cmp r10,0 ; Compare Frame Buffer Pointer To Zero
  beq FB_Init ; IF Zero Re-Initialize Frame Buffer

  and r10,$3FFFFFFF ; Convert Mail Box Frame Buffer Pointer From BUS Address To Physical Address ($CXXXXXXX -> $3XXXXXXX)
  str r10,[r1] ; Store Frame Buffer Pointer Physical Address

imm32 r1,8 + (SCREEN_X * 8)
add r0,r10,r1 ; Place Text At XY Position 8,8
PrintText VCText, 10

imm32 r1,16 + (SCREEN_X * 16)
add r0,r10,r1 ; Place Text At XY Position 16,16
PrintTAGValueLE VCFirmwareRevisionText, 19, VCFirmwareRevisionValue, 4


imm32 r1,8 + (SCREEN_X * 32)
add r0,r10,r1 ; Place Text At XY Position 8,32
PrintText HWText, 9

imm32 r1,16 + (SCREEN_X * 40)
add r0,r10,r1 ; Place Text At XY Position 16,40
PrintTAGValueLE HWBoardModelText, 19, HWBoardModelValue, 4

imm32 r1,16 + (SCREEN_X * 48)
add r0,r10,r1 ; Place Text At XY Position 16,48
PrintTAGValueLE HWBoardRevisionText, 19, HWBoardRevisionValue, 4

imm32 r1,16 + (SCREEN_X * 56)
add r0,r10,r1 ; Place Text At XY Position 16,56
PrintTAGValueBE HWBoardMACAddressText, 19, HWBoardMACAddressValue, 6

imm32 r1,16 + (SCREEN_X * 64)
add r0,r10,r1 ; Place Text At XY Position 16,64
PrintTAGValueLE HWBoardSerialText, 19, HWBoardSerialValue, 8

imm32 r1,16 + (SCREEN_X * 72)
add r0,r10,r1 ; Place Text At XY Position 16,72
PrintTAGValueLE HWARMMemoryBaseAddressText, 25, HWARMMemoryBaseAddressValue, 4
PrintTAGValueLE SizeText, 7, HWARMMemorySizeValue, 4

imm32 r1,16 + (SCREEN_X * 80)
add r0,r10,r1 ; Place Text At XY Position 16,80
PrintTAGValueLE HWVCMemoryBaseAddressText, 25, HWVCMemoryBaseAddressValue, 4
PrintTAGValueLE SizeText, 7, HWVCMemorySizeValue, 4


imm32 r1,8 + (SCREEN_X * 96)
add r0,r10,r1 ; Place Text At XY Position 8,96
PrintText SRMText, 27

imm32 r1,16 + (SCREEN_X * 104)
add r0,r10,r1 ; Place Text At XY Position 16,104
PrintTAGValueLE SRMDMAChannelsText, 14, SRMDMAChannelsValue, 4


imm32 r1,8 + (SCREEN_X * 120)
add r0,r10,r1 ; Place Text At XY Position 8,120
PrintText PWRText, 6

imm32 r1,16 + (SCREEN_X * 128)
add r0,r10,r1 ; Place Text At XY Position 16,128
PrintTAGValueLE PWRSDCardIDText, 12, PWRSDCardIDValue, 4
PrintTAGValueLE StateText, 8, PWRSDCardStateValue, 4
PrintTAGValueLE TimingText, 9, PWRSDCardTimingValue, 4

imm32 r1,16 + (SCREEN_X * 136)
add r0,r10,r1 ; Place Text At XY Position 16,136
PrintTAGValueLE PWRUART0IDText, 12, PWRUART0IDValue, 4
PrintTAGValueLE StateText, 8, PWRUART0StateValue, 4
PrintTAGValueLE TimingText, 9, PWRUART0TimingValue, 4

imm32 r1,16 + (SCREEN_X * 144)
add r0,r10,r1 ; Place text at XY Position 16,144
PrintTAGValueLE PWRUART1IDText, 12, PWRUART1IDValue, 4
PrintTAGValueLE StateText, 8, PWRUART1StateValue, 4
PrintTAGValueLE TimingText, 9, PWRUART1TimingValue, 4

imm32 r1,16 + (SCREEN_X * 152)
add r0,r10,r1 ; Place Text At XY Position 16,152
PrintTAGValueLE PWRUSBHCDIDText, 12, PWRUSBHCDIDValue, 4
PrintTAGValueLE StateText, 8, PWRUSBHCDStateValue, 4
PrintTAGValueLE TimingText, 9, PWRUSBHCDTimingValue, 4

imm32 r1,16 + (SCREEN_X * 160)
add r0,r10,r1 ; Place Text At XY Position 16,160
PrintTAGValueLE PWRI2C0IDText, 12, PWRI2C0IDValue, 4
PrintTAGValueLE StateText, 8, PWRI2C0StateValue, 4
PrintTAGValueLE TimingText, 9, PWRI2C0TimingValue, 4

imm32 r1,16 + (SCREEN_X * 168)
add r0,r10,r1 ; Place Text At XY Position 16,168
PrintTAGValueLE PWRI2C1IDText, 12, PWRI2C1IDValue, 4
PrintTAGValueLE StateText, 8, PWRI2C1StateValue, 4
PrintTAGValueLE TimingText, 9, PWRI2C1TimingValue, 4

imm32 r1,16 + (SCREEN_X * 176)
add r0,r10,r1 ; Place Text At XY Position 16,176
PrintTAGValueLE PWRI2C2IDText, 12, PWRI2C2IDValue, 4
PrintTAGValueLE StateText, 8, PWRI2C2StateValue, 4
PrintTAGValueLE TimingText, 9, PWRI2C2TimingValue, 4

imm32 r1,16 + (SCREEN_X * 184)
add r0,r10,r1 ; Place Text At XY Position 16,184
PrintTAGValueLE PWRSPIIDText, 12, PWRSPIIDValue, 4
PrintTAGValueLE StateText, 8, PWRSPIStateValue, 4
PrintTAGValueLE TimingText, 9, PWRSPITimingValue, 4

imm32 r1,16 + (SCREEN_X * 192)
add r0,r10,r1 ; Place Text At XY Position 16,192
PrintTAGValueLE PWRCCP2TXIDText, 12, PWRCCP2TXIDValue, 4
PrintTAGValueLE StateText, 8, PWRCCP2TXStateValue, 4
PrintTAGValueLE TimingText, 9, PWRCCP2TXTimingValue, 4


imm32 r1,8 + (SCREEN_X * 208)
add r0,r10,r1 ; Place Text At XY Position 8,208
PrintText CLKText, 7

imm32 r1,16 + (SCREEN_X * 216)
add r0,r10,r1 ; Place Text At XY Position 16,216
PrintTAGValueLE CLKEMMCIDText, 10, CLKEMMCIDValue, 4
PrintTAGValueLE StateText, 8, CLKEMMCStateValue, 4
PrintTAGValueLE RateText, 7, CLKEMMCRateValue, 4
PrintTAGValueLE MaxText, 6, CLKEMMCMaxValue, 4
PrintTAGValueLE MinText, 6, CLKEMMCMinValue, 4

imm32 r1,16 + (SCREEN_X * 224)
add r0,r10,r1 ; Place Text At XY Position 16,224
PrintTAGValueLE CLKUARTIDText, 10, CLKUARTIDValue, 4
PrintTAGValueLE StateText, 8, CLKUARTStateValue, 4
PrintTAGValueLE RateText, 7, CLKUARTRateValue, 4
PrintTAGValueLE MaxText, 6, CLKUARTMaxValue, 4
PrintTAGValueLE MinText, 6, CLKUARTMinValue, 4

imm32 r1,16 + (SCREEN_X * 232)
add r0,r10,r1 ; Place Text At XY Position 16,232
PrintTAGValueLE CLKARMIDText, 10, CLKARMIDValue, 4
PrintTAGValueLE StateText, 8, CLKARMStateValue, 4
PrintTAGValueLE RateText, 7,CLKARMRateValue, 4
PrintTAGValueLE MaxText, 6,CLKARMMaxValue, 4
PrintTAGValueLE MinText, 6,CLKARMMinValue, 4

imm32 r1,16 + (SCREEN_X * 240)
add r0,r10,r1 ; Place Text At XY Position 16,240
PrintTAGValueLE CLKCOREIDText, 10, CLKCOREIDValue, 4
PrintTAGValueLE StateText, 8, CLKCOREStateValue, 4
PrintTAGValueLE RateText, 7, CLKCORERateValue, 4
PrintTAGValueLE MaxText, 6, CLKCOREMaxValue, 4
PrintTAGValueLE MinText, 6, CLKCOREMinValue, 4

imm32 r1,16 + (SCREEN_X * 248)
add r0,r10,r1 ; Place Text At XY Position 16,248
PrintTAGValueLE CLKV3DIDText, 10, CLKV3DIDValue, 4
PrintTAGValueLE StateText, 8, CLKV3DStateValue, 4
PrintTAGValueLE RateText, 7, CLKV3DRateValue, 4
PrintTAGValueLE MaxText, 6, CLKV3DMaxValue, 4
PrintTAGValueLE MinText, 6, CLKV3DMinValue, 4

imm32 r1,16 + (SCREEN_X * 256)
add r0,r10,r1 ; Place Text At XY Position 16,256
PrintTAGValueLE CLKH264IDText, 10, CLKH264IDValue, 4
PrintTAGValueLE StateText, 8, CLKH264StateValue, 4
PrintTAGValueLE RateText, 7, CLKH264RateValue, 4
PrintTAGValueLE MaxText, 6, CLKH264MaxValue, 4
PrintTAGValueLE MinText, 6, CLKH264MinValue, 4

imm32 r1,16 + (SCREEN_X * 264)
add r0,r10,r1 ; Place Text At XY Position 16,264
PrintTAGValueLE CLKISPIDText, 10, CLKISPIDValue, 4
PrintTAGValueLE StateText, 8, CLKISPStateValue, 4
PrintTAGValueLE RateText, 7, CLKISPRateValue, 4
PrintTAGValueLE MaxText, 6, CLKISPMaxValue, 4
PrintTAGValueLE MinText, 6, CLKISPMinValue, 4

imm32 r1,16 + (SCREEN_X * 272)
add r0,r10,r1 ; Place Text At XY Position 16,272
PrintTAGValueLE CLKSDRAMIDText, 10, CLKSDRAMIDValue, 4
PrintTAGValueLE StateText, 8, CLKSDRAMStateValue, 4
PrintTAGValueLE RateText, 7, CLKSDRAMRateValue, 4
PrintTAGValueLE MaxText, 6, CLKSDRAMMaxValue, 4
PrintTAGValueLE MinText, 6, CLKSDRAMMinValue, 4

imm32 r1,16 + (SCREEN_X * 280)
add r0,r10,r1 ; Place Text At XY Position 16,280
PrintTAGValueLE CLKPIXELIDText, 10, CLKPIXELIDValue, 4
PrintTAGValueLE StateText, 8, CLKPIXELStateValue, 4
PrintTAGValueLE RateText, 7, CLKPIXELRateValue, 4
PrintTAGValueLE MaxText, 6, CLKPIXELMaxValue, 4
PrintTAGValueLE MinText, 6, CLKPIXELMinValue, 4

imm32 r1,16 + (SCREEN_X * 288)
add r0,r10,r1 ; Place Text At XY Position 16,288
PrintTAGValueLE CLKPWMIDText, 10, CLKPWMIDValue, 4
PrintTAGValueLE StateText, 8, CLKPWMStateValue, 4
PrintTAGValueLE RateText, 7, CLKPWMRateValue, 4
PrintTAGValueLE MaxText, 6, CLKPWMMaxValue, 4
PrintTAGValueLE MinText, 6, CLKPWMMinValue, 4

imm32 r1,16 + (SCREEN_X * 296)
add r0,r10,r1 ; Place Text At XY Position 16,296
PrintTAGValueLE CLKTurboText, 7, CLKTurboValue, 4


imm32 r1,8 + (SCREEN_X * 312)
add r0,r10,r1 ; Place Text At XY Position 8,312
PrintText VLTText, 8

imm32 r1,16 + (SCREEN_X * 320)
add r0,r10,r1 ; Place Text At XY Position 16,320
PrintTAGValueLE VLTCoreIDText, 12, VLTCoreIDValue, 4
PrintTAGValueLE VoltageText, 10, VLTCoreValue, 4
PrintTAGValueLE MaxText, 6, VLTCoreMaxValue, 4
PrintTAGValueLE MinText, 6, VLTCoreMinValue, 4

imm32 r1,16 + (SCREEN_X * 328)
add r0,r10,r1 ; Place Text At XY Position 16,328
PrintTAGValueLE VLTSDRAM_CIDText, 12, VLTSDRAM_CIDValue, 4
PrintTAGValueLE VoltageText, 10, VLTSDRAM_CValue, 4
PrintTAGValueLE MaxText, 6, VLTSDRAM_CMaxValue, 4
PrintTAGValueLE MinText, 6, VLTSDRAM_CMinValue, 4

imm32 r1,16 + (SCREEN_X * 336)
add r0,r10,r1 ; Place Text At XY Position 16,336
PrintTAGValueLE VLTSDRAM_PIDText, 12, VLTSDRAM_PIDValue, 4
PrintTAGValueLE VoltageText, 10, VLTSDRAM_PValue, 4
PrintTAGValueLE MaxText, 6, VLTSDRAM_PMaxValue, 4
PrintTAGValueLE MinText, 6, VLTSDRAM_PMinValue, 4

imm32 r1,16 + (SCREEN_X * 344)
add r0,r10,r1 ; Place Text At XY Position 16,344
PrintTAGValueLE VLTSDRAM_IIDText, 12, VLTSDRAM_IIDValue, 4
PrintTAGValueLE VoltageText, 10, VLTSDRAM_IValue, 4
PrintTAGValueLE MaxText, 6, VLTSDRAM_IMaxValue, 4
PrintTAGValueLE MinText, 6, VLTSDRAM_IMinValue, 4

imm32 r1,16 + (SCREEN_X * 352)
add r0,r10,r1 ; Place Text At XY Position 16,352
PrintTAGValueLE VLTTemperatureText, 13, VLTTemperatureValue, 4
PrintTAGValueLE MaxText, 6, VLTTemperatureMaxValue, 4


imm32 r1,8 + (SCREEN_X * 368)
add r0,r10,r1 ; Place Text At XY Position 8,368
PrintText FBText, 13

imm32 r1,16 + (SCREEN_X * 376)
add r0,r10,r1 ; Place Text At XY Position 16,376
PrintText FBPhysicalDisplayText, 16
PrintTAGValueLE WidthText, 8, FBPhysicalDisplayWidthValue, 4
PrintTAGValueLE HeightText, 9, FBPhysicalDisplayHeightValue, 4

imm32 r1,16 + (SCREEN_X * 384)
add r0,r10,r1 ; Place Text At XY Position 16,384
PrintText FBVirtualBufferText, 16
PrintTAGValueLE WidthText, 8, FBVirtualBufferWidthValue, 4
PrintTAGValueLE HeightText, 9, FBVirtualBufferHeightValue, 4

imm32 r1,16 + (SCREEN_X * 392)
add r0,r10,r1 ; Place Text At XY Position 16,392
PrintTAGValueLE FBDepthText, 7, FBDepthValue, 4
PrintTAGValueLE FBPixelOrderText, 14, FBPixelOrderValue, 4
PrintTAGValueLE FBAlphaModeText, 13, FBAlphaModeValue, 4
PrintTAGValueLE FBPitchText, 8, FBPitchValue, 4

imm32 r1,16 + (SCREEN_X * 400)
add r0,r10,r1 ; Place Text At XY Position 16,400
PrintText FBVirtualOffsetText, 14
PrintTAGValueLE XText, 4, FBVirtualOffsetXValue, 4
PrintTAGValueLE YText, 4, FBVirtualOffsetYValue, 4

imm32 r1,16 + (SCREEN_X * 408)
add r0,r10,r1 ; Place Text At XY Position 16,408
PrintText FBOverscanText, 8
PrintTAGValueLE TopText, 6, FBOverscanTopValue, 4
PrintTAGValueLE BottomText, 9, FBOverscanBottomValue, 4
PrintTAGValueLE LeftText, 7, FBOverscanLeftValue, 4
PrintTAGValueLE RightText, 8, FBOverscanRightValue, 4

Loop:
  b Loop

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

align 16
TAGS_STRUCT: ; Mailbox Property Interface Buffer Structure
  dw TAGS_END - TAGS_STRUCT ; Buffer Size In Bytes (Including The Header Values, The End Tag And Padding)
  dw $00000000 ; Buffer Request/Response Code
	       ; Request Codes: $00000000 Process Request Response Codes: $80000000 Request Successful, $80000001 Partial Response
; Sequence Of Concatenated Tags
  dw Get_Firmware_Revision ; Tag Identifier
  dw $00000004 ; Value Buffer Size In Bytes
  dw $00000004 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
VCFirmwareRevisionValue:
  dw 0 ; Value Buffer


  dw Get_Board_Model ; Tag Identifier
  dw $00000004 ; Value Buffer Size In Bytes
  dw $00000004 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
HWBoardModelValue:
  dw 0 ; Value Buffer

  dw Get_Board_Revision ; Tag Identifier
  dw $00000004 ; Value Buffer Size In Bytes
  dw $00000004 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
HWBoardRevisionValue:
  dw 0 ; Value Buffer

  dw Get_Board_MAC_Address ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000006 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
HWBoardMACAddressValue:
  dd 0 ; Value Buffer

  dw Get_Board_Serial ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
HWBoardSerialValue:
  dd 0 ; Value Buffer

  dw Get_ARM_Memory ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
HWARMMemoryBaseAddressValue:
  dw 0 ; Value Buffer
HWARMMemorySizeValue:
  dw 0 ; Value Buffer

  dw Get_VC_Memory ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
HWVCMemoryBaseAddressValue:
  dw 0 ; Value Buffer
HWVCMemorySizeValue:
  dw 0 ; Value Buffer


  dw Get_DMA_Channels ; Tag Identifier
  dw $00000004 ; Value Buffer Size In Bytes
  dw $00000004 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
SRMDMAChannelsValue:
  dw 0 ; Value Buffer


  dw Get_Power_State ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
PWRSDCardIDValue:
  dw PWR_SD_Card_ID ; Value Buffer
PWRSDCardStateValue:
  dw 0 ; Value Buffer

  dw Get_Power_State ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
PWRUART0IDValue:
  dw PWR_UART0_ID ; Value Buffer
PWRUART0StateValue:
  dw 0 ; Value Buffer

  dw Get_Power_State ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
PWRUART1IDValue:
  dw PWR_UART1_ID ; Value Buffer
PWRUART1StateValue:
  dw 0 ; Value Buffer

  dw Get_Power_State ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
PWRUSBHCDIDValue:
  dw PWR_USB_HCD_ID ; Value Buffer
PWRUSBHCDStateValue:
  dw 0 ; Value Buffer

  dw Get_Power_State ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
PWRI2C0IDValue:
  dw PWR_I2C0_ID ; Value Buffer
PWRI2C0StateValue:
  dw 0 ; Value Buffer

  dw Get_Power_State ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
PWRI2C1IDValue:
  dw PWR_I2C1_ID ; Value Buffer
PWRI2C1StateValue:
  dw 0 ; Value Buffer

  dw Get_Power_State ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
PWRI2C2IDValue:
  dw PWR_I2C2_ID ; Value Buffer
PWRI2C2StateValue:
  dw 0 ; Value Buffer

  dw Get_Power_State ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
PWRSPIIDValue:
  dw PWR_SPI_ID ; Value Buffer
PWRSPIStateValue:
  dw 0 ; Value Buffer

  dw Get_Power_State ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
PWRCCP2TXIDValue:
  dw PWR_CCP2TX_ID ; Value Buffer
PWRCCP2TXStateValue:
  dw 0 ; Value Buffer


  dw Get_Timing ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw PWR_SD_Card_ID ; Value Buffer
PWRSDCardTimingValue:
  dw 0 ; Value Buffer

  dw Get_Timing ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw PWR_UART0_ID ; Value Buffer
PWRUART0TimingValue:
  dw 0 ; Value Buffer

  dw Get_Timing ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw PWR_UART1_ID ; Value Buffer
PWRUART1TimingValue:
  dw 0 ; Value Buffer

  dw Get_Timing ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw PWR_USB_HCD_ID ; Value Buffer
PWRUSBHCDTimingValue:
  dw 0 ; Value Buffer

  dw Get_Timing ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw PWR_I2C0_ID ; Value Buffer
PWRI2C0TimingValue:
  dw 0 ; Value Buffer

  dw Get_Timing ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw PWR_I2C1_ID ; Value Buffer
PWRI2C1TimingValue:
  dw 0 ; Value Buffer

  dw Get_Timing ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw PWR_I2C2_ID ; Value Buffer
PWRI2C2TimingValue:
  dw 0 ; Value Buffer

  dw Get_Timing ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw PWR_SPI_ID ; Value Buffer
PWRSPITimingValue:
  dw 0 ; Value Buffer

  dw Get_Timing ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw PWR_CCP2TX_ID ; Value Buffer
PWRCCP2TXTimingValue:
  dw 0 ; Value Buffer


  dw Get_Clock_State ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
CLKEMMCIDValue:
  dw CLK_EMMC_ID ; Value Buffer
CLKEMMCStateValue:
  dw 0 ; Value Buffer

  dw Get_Clock_State ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
CLKUARTIDValue:
  dw CLK_UART_ID ; Value Buffer
CLKUARTStateValue:
  dw 0 ; Value Buffer

  dw Get_Clock_State ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
CLKARMIDValue:
  dw CLK_ARM_ID ; Value Buffer
CLKARMStateValue:
  dw 0 ; Value Buffer

  dw Get_Clock_State ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
CLKCOREIDValue:
  dw CLK_CORE_ID ; Value Buffer
CLKCOREStateValue:
  dw 0 ; Value Buffer

  dw Get_Clock_State ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
CLKV3DIDValue:
  dw CLK_V3D_ID ; Value Buffer
CLKV3DStateValue:
  dw 0 ; Value Buffer

  dw Get_Clock_State ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
CLKH264IDValue:
  dw CLK_H264_ID ; Value Buffer
CLKH264StateValue:
  dw 0 ; Value Buffer

  dw Get_Clock_State ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
CLKISPIDValue:
  dw CLK_ISP_ID ; Value Buffer
CLKISPStateValue:
  dw 0 ; Value Buffer

  dw Get_Clock_State ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
CLKSDRAMIDValue:
  dw CLK_SDRAM_ID ; Value Buffer
CLKSDRAMStateValue:
  dw 0 ; Value Buffer

  dw Get_Clock_State ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
CLKPIXELIDValue:
  dw CLK_PIXEL_ID ; Value Buffer
CLKPIXELStateValue:
  dw 0 ; Value Buffer

  dw Get_Clock_State ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
CLKPWMIDValue:
  dw CLK_PWM_ID ; Value Buffer
CLKPWMStateValue:
  dw 0 ; Value Buffer


  dw Get_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_EMMC_ID ; Value Buffer
CLKEMMCRateValue:
  dw 0 ; Value Buffer

  dw Get_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_UART_ID ; Value Buffer
CLKUARTRateValue:
  dw 0 ; Value Buffer

  dw Get_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_ARM_ID ; Value Buffer
CLKARMRateValue:
  dw 0 ; Value Buffer

  dw Get_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_CORE_ID ; Value Buffer
CLKCORERateValue:
  dw 0 ; Value Buffer

  dw Get_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_V3D_ID ; Value Buffer
CLKV3DRateValue:
  dw 0 ; Value Buffer

  dw Get_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_H264_ID ; Value Buffer
CLKH264RateValue:
  dw 0 ; Value Buffer

  dw Get_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_ISP_ID ; Value Buffer
CLKISPRateValue:
  dw 0 ; Value Buffer

  dw Get_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_SDRAM_ID ; Value Buffer
CLKSDRAMRateValue:
  dw 0 ; Value Buffer

  dw Get_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_PIXEL_ID ; Value Buffer
CLKPIXELRateValue:
  dw 0 ; Value Buffer

  dw Get_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_PWM_ID ; Value Buffer
CLKPWMRateValue:
  dw 0 ; Value Buffer


  dw Get_Max_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_EMMC_ID ; Value Buffer
CLKEMMCMaxValue:
  dw 0 ; Value Buffer

  dw Get_Max_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_UART_ID ; Value Buffer
CLKUARTMaxValue:
  dw 0 ; Value Buffer

  dw Get_Max_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_ARM_ID ; Value Buffer
CLKARMMaxValue:
  dw 0 ; Value Buffer

  dw Get_Max_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_CORE_ID ; Value Buffer
CLKCOREMaxValue:
  dw 0 ; Value Buffer

  dw Get_Max_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_V3D_ID ; Value Buffer
CLKV3DMaxValue:
  dw 0 ; Value Buffer

  dw Get_Max_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_H264_ID ; Value Buffer
CLKH264MaxValue:
  dw 0 ; Value Buffer

  dw Get_Max_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_ISP_ID ; Value Buffer
CLKISPMaxValue:
  dw 0 ; Value Buffer

  dw Get_Max_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_SDRAM_ID ; Value Buffer
CLKSDRAMMaxValue:
  dw 0 ; Value Buffer

  dw Get_Max_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_PIXEL_ID ; Value Buffer
CLKPIXELMaxValue:
  dw 0 ; Value Buffer

  dw Get_Max_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_PWM_ID ; Value Buffer
CLKPWMMaxValue:
  dw 0 ; Value Buffer


dw Get_Min_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_EMMC_ID ; Value Buffer
CLKEMMCMinValue:
  dw 0 ; Value Buffer

  dw Get_Min_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_UART_ID ; Value Buffer
CLKUARTMinValue:
  dw 0 ; Value Buffer

  dw Get_Min_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_ARM_ID ; Value Buffer
CLKARMMinValue:
  dw 0 ; Value Buffer

  dw Get_Min_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_CORE_ID ; Value Buffer
CLKCOREMinValue:
  dw 0 ; Value Buffer

  dw Get_Min_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_V3D_ID ; Value Buffer
CLKV3DMinValue:
  dw 0 ; Value Buffer

  dw Get_Min_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_H264_ID ; Value Buffer
CLKH264MinValue:
  dw 0 ; Value Buffer

  dw Get_Min_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_ISP_ID ; Value Buffer
CLKISPMinValue:
  dw 0 ; Value Buffer

  dw Get_Min_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_SDRAM_ID ; Value Buffer
CLKSDRAMMinValue:
  dw 0 ; Value Buffer

  dw Get_Min_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_PIXEL_ID ; Value Buffer
CLKPIXELMinValue:
  dw 0 ; Value Buffer

  dw Get_Min_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_PWM_ID ; Value Buffer
CLKPWMMinValue:
  dw 0 ; Value Buffer

  dw Get_Turbo ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw 0 ; Value Buffer
CLKTurboValue:
  dw 0 ; Value Buffer


  dw Get_Voltage ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
VLTCoreIDValue:
  dw VLT_Core_ID ; Value Buffer
VLTCoreValue:
  dw 0 ; Value Buffer

  dw Get_Voltage ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
VLTSDRAM_CIDValue:
  dw VLT_SDRAM_C_ID ; Value Buffer
VLTSDRAM_CValue:
  dw 0 ; Value Buffer

  dw Get_Voltage ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
VLTSDRAM_PIDValue:
  dw VLT_SDRAM_P_ID ; Value Buffer
VLTSDRAM_PValue:
  dw 0 ; Value Buffer

  dw Get_Voltage ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
VLTSDRAM_IIDValue:
  dw VLT_SDRAM_I_ID ; Value Buffer
VLTSDRAM_IValue:
  dw 0 ; Value Buffer


  dw Get_Max_Voltage ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw VLT_Core_ID ; Value Buffer
VLTCoreMaxValue:
  dw 0 ; Value Buffer

  dw Get_Max_Voltage ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw VLT_SDRAM_C_ID ; Value Buffer
VLTSDRAM_CMaxValue:
  dw 0 ; Value Buffer

  dw Get_Max_Voltage ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw VLT_SDRAM_P_ID ; Value Buffer
VLTSDRAM_PMaxValue:
  dw 0 ; Value Buffer

  dw Get_Max_Voltage ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw VLT_SDRAM_I_ID ; Value Buffer
VLTSDRAM_IMaxValue:
  dw 0 ; Value Buffer


  dw Get_Min_Voltage ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw VLT_Core_ID ; Value Buffer
VLTCoreMinValue:
  dw 0 ; Value Buffer

  dw Get_Min_Voltage ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw VLT_SDRAM_C_ID ; Value Buffer
VLTSDRAM_CMinValue:
  dw 0 ; Value Buffer

  dw Get_Min_Voltage ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw VLT_SDRAM_P_ID ; Value Buffer
VLTSDRAM_PMinValue:
  dw 0 ; Value Buffer

  dw Get_Min_Voltage ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw VLT_SDRAM_I_ID ; Value Buffer
VLTSDRAM_IMinValue:
  dw 0 ; Value Buffer


  dw Get_Temperature ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw 0 ; Value Buffer
VLTTemperatureValue:
  dw 0 ; Value Buffer

  dw Get_Max_Temperature ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw 0 ; Value Buffer
VLTTemperatureMaxValue:
  dw 0 ; Value Buffer


  dw Get_Physical_Display ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
FBPhysicalDisplayWidthValue:
  dw 0 ; Value Buffer
FBPhysicalDisplayHeightValue:
  dw 0 ; Value Buffer

  dw Get_Virtual_Buffer ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
FBVirtualBufferWidthValue:
  dw 0 ; Value Buffer
FBVirtualBufferHeightValue:
  dw 0 ; Value Buffer

  dw Get_Depth ; Tag Identifier
  dw $00000004 ; Value Buffer Size In Bytes
  dw $00000004 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
FBDepthValue:
  dw 0 ; Value Buffer

  dw Get_Pixel_Order ; Tag Identifier
  dw $00000004 ; Value Buffer Size In Bytes
  dw $00000004 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
FBPixelOrderValue:
  dw 0 ; Value Buffer

  dw Get_Alpha_Mode ; Tag Identifier
  dw $00000004 ; Value Buffer Size In Bytes
  dw $00000004 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
FBAlphaModeValue:
  dw 0 ; Value Buffer

  dw Get_Pitch ; Tag Identifier
  dw $00000004 ; Value Buffer Size In Bytes
  dw $00000004 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
FBPitchValue:
  dw 0 ; Value Buffer

  dw Get_Virtual_Offset ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
FBVirtualOffsetXValue:
  dw 0 ; Value Buffer
FBVirtualOffsetYValue:
  dw 0 ; Value Buffer

  dw Get_Overscan ; Tag Identifier
  dw $00000010 ; Value Buffer Size In Bytes
  dw $00000010 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
FBOverscanTopValue:
  dw 0 ; Value Buffer
FBOverscanBottomValue:
  dw 0 ; Value Buffer
FBOverscanLeftValue:
  dw 0 ; Value Buffer
FBOverscanRightValue:
  dw 0 ; Value Buffer

dw $00000000 ; $0 (End Tag)
TAGS_END:

VCText: 		    db "VideoCore:"
VCFirmwareRevisionText:     db "Firmware Revision $"
HWText: 		    db "Hardware:"
HWBoardModelText:	    db "Board Model       $"
HWBoardRevisionText:	    db "Board Revision    $"
HWBoardMACAddressText:	    db "Board MAC Address $"
HWBoardSerialText:	    db "Board Serial      $"
HWARMMemoryBaseAddressText: db "ARM Memory Base Address $"
HWVCMemoryBaseAddressText:  db "VC  Memory Base Address $"
SRMText:		    db "Shared Resource Management:"
SRMDMAChannelsText:	    db "DMA Channels $"
PWRText:		    db "Power:"
PWRSDCardIDText:	    db "SD Card ID $"
PWRUART0IDText: 	    db "UART0   ID $"
PWRUART1IDText: 	    db "UART1   ID $"
PWRUSBHCDIDText:	    db "USB HCD ID $"
PWRI2C0IDText:		    db "I2C0    ID $"
PWRI2C1IDText:		    db "I2C1    ID $"
PWRI2C2IDText:		    db "I2C2    ID $"
PWRSPIIDText:		    db "SPI     ID $"
PWRCCP2TXIDText:	    db "CCP2TX  ID $"
CLKText:		    db "Clocks:"
CLKEMMCIDText:		    db "EMMC  ID $"
CLKUARTIDText:		    db "UART  ID $"
CLKARMIDText:		    db "ARM   ID $"
CLKCOREIDText:		    db "CORE  ID $"
CLKV3DIDText:		    db "V3D   ID $"
CLKH264IDText:		    db "H264  ID $"
CLKISPIDText:		    db "ISP   ID $"
CLKSDRAMIDText: 	    db "SDRAM ID $"
CLKPIXELIDText: 	    db "PIXEL ID $"
CLKPWMIDText:		    db "PWM   ID $"
CLKTurboText:		    db "Turbo $"
VLTText:		    db "Voltage:"
VLTCoreIDText:		    db "Core    ID $"
VLTSDRAM_CIDText:	    db "SDRAM_C ID $"
VLTSDRAM_PIDText:	    db "SDRAM_P ID $"
VLTSDRAM_IIDText:	    db "SDRAM_I ID $"
VLTTemperatureText:	    db "Temperature $"
FBText: 		    db "Frame Buffer:"
FBPhysicalDisplayText:	    db "Physical Display"
FBVirtualBufferText:	    db "Virtual Buffer  "
FBDepthText:		    db "Depth $"
FBPixelOrderText:	    db " Pixel Order $"
FBAlphaModeText:	    db " Alpha Mode $"
FBPitchText:		    db " Pitch $"
FBVirtualOffsetText:	    db "Virtual Offset"
FBOverscanText: 	    db "Overscan"

SizeText: db " Size $"
StateText: db " State $"
TimingText: db " Timing $"
RateText: db " Rate $"
MaxText: db " Max $"
MinText: db " Min $"
VoltageText: db " Voltage $"
WidthText: db " Width $"
HeightText: db " Height $"
XText: db " X $"
YText: db " Y $"
TopText: db " Top $"
BottomText: db " Bottom $"
LeftText: db " Left $"
RightText: db " Right $"

align 4
Font: include 'Font8x8.asm'