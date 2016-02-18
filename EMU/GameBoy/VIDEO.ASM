; Convert Palette
adr r5,FB_PAL
imm16 r6,BGP_REG
ldrb r6,[r10,r6]

and r7,r6,3	; BGP Colour 0 (PAL&3)
eor r7,r7,3	; Invert Bits
mov r7,r7,lsl 9
strh r7,[r5,0]

and r7,r6,12	; BGP Colour 1 ((PAL&12)>>2)
eor r7,r7,3 * 4 ; Invert Bits
mov r7,r7,lsl 7
strh r7,[r5,2]

and r7,r6,48	 ; BGP Colour 2 ((PAL&48)>>4)
eor r7,r7,3 * 16 ; Invert Bits
mov r7,r7,lsl 5
strh r7,[r5,4]

and r7,r6,192	 ; BGP Colour 3 ((PAL&192)>>6))
eor r7,r7,3 * 64 ; Invert Bits
mov r7,r7,lsl 3
strh r7,[r5,6]

; Convert Characters
add r5,r10,CHAR_RAM ; r5 = Character RAM Offset
add r6,r10,$10000 ; r6 = Converted Character RAM Offset (192 tiles * 64 Bytes)
LoopTiles:
  ldrh r7,[r5],2 ; Load 2 Bytes From Character RAM

  mov r8,0 ; Reset Conversion Byte
  tst r7,0000000010000000b ; Test GB Pixel Colour Lo Bit In Char Row Position 1
  orrne r8,r8,00000001b ; Put Color 1st Bit In Char Row Position 1
  tst r7,1000000000000000b ; Test GB Pixel Colour Hi Bit In Char Row Position 1
  orrne r8,r8,00000010b ; Put Color 2nd Bit In Char Row Position 1
  strb r8,[r6],1 ; Store Char Row Position 1

  mov r8,0 ; Reset Conversion Byte
  tst r7,0000000001000000b ; Test GB Pixel Colour Lo Bit In Char Row Position 2
  orrne r8,r8,00000001b ; Put Color 1st Bit In Char Row Position 2
  tst r7,0100000000000000b ; Test GB Pixel Colour Hi Bit In Char Row Position 2
  orrne r8,r8,00000010b ; Put Color 2nd Bit In Char Row Position 2
  strb r8,[r6],1 ; Store Char Row Position 2

  mov r8,0 ; Reset Conversion Byte
  tst r7,0000000000100000b ; Test GB Pixel Colour Lo Bit In Char Row Position 3
  orrne r8,r8,00000001b ; Put Color 1st Bit In Char Row Position 3
  tst r7,0010000000000000b ; Test GB Pixel Colour Hi Bit In Char Row Position 3
  orrne r8,r8,00000010b ; Put Color 2nd Bit In Char Row Position 3
  strb r8,[r6],1 ; Store Char Row Position 3

  mov r8,0 ; Reset Conversion Byte
  tst r7,0000000000010000b ; Test GB Pixel Colour Lo Bit In Char Row Position 4
  orrne r8,r8,00000001b ; Put Color 1st Bit In Char Row Position 4
  tst r7,0001000000000000b ; Test GB Pixel Colour Hi Bit In Char Row Position 4
  orrne r8,r8,00000010b ; Put Color 2nd Bit In Char Row Position 4
  strb r8,[r6],1 ; Store Char Row Position 4

  mov r8,0 ; Reset Conversion Byte
  tst r7,0000000000001000b ; Test GB Pixel Colour Lo Bit In Char Row Position 5
  orrne r8,r8,00000001b ; Put Color 1st Bit In Char Row Position 5
  tst r7,0000100000000000b ; Test GB Pixel Colour Hi Bit In Char Row Position 5
  orrne r8,r8,00000010b ; Put Color 2nd Bit In Char Row Position 5
  strb r8,[r6],1 ; Store Char Row Position 5

  mov r8,0 ; Reset Conversion Byte
  tst r7,0000000000000100b ; Test GB Pixel Colour Lo Bit In Char Row Position 6
  orrne r8,r8,00000001b ; Put Color 1st Bit In Char Row Position 6
  tst r7,0000010000000000b ; Test GB Pixel Colour Hi Bit In Char Row Position 6
  orrne r8,r8,00000010b ; Put Color 2nd Bit In Char Row Position 6
  strb r8,[r6],1 ; Store Char Row Position 6

  mov r8,0 ; Reset Conversion Byte
  tst r7,0000000000000010b ; Test GB Pixel Colour Lo Bit In Char Row Position 7
  orrne r8,r8,00000001b ; Put Color 1st Bit In Char Row Position 7
  tst r7,0000001000000000b ; Test GB Pixel Colour Hi Bit In Char Row Position 7
  orrne r8,r8,00000010b ; Put Color 2nd Bit In Char Row Position 7
  strb r8,[r6],1 ; Store Char Row Position 7

  mov r8,0 ; Reset Conversion Byte
  tst r7,0000000000000001b ; Test GB Pixel Colour Lo Bit In Char Row Position 8
  orrne r8,r8,00000001b ; Put Color 1st Bit In Char Row Position 8
  tst r7,0000000100000000b ; Test GB Pixel Colour Hi Bit In Char Row Position 8
  orrne r8,r8,00000010b ; Put Color 2nd Bit In Char Row Position 8
  strb r8,[r6],1 ; Store Char Row Position 7

  add r7,r10,BG1_RAM
  cmp r5,r7
  bne LoopTiles ; Loop All Tiles

; Set Scroll Offsets
imm16 r5,SCX_REG ; Load Scroll X Register
ldrb r6,[r10,r5]
str r6,[FB_OFFSET_X]

imm16 r5,SCY_REG ; Load Scroll Y Register
ldrb r6,[r10,r5]
str r6,[FB_OFFSET_Y]

; Load Palette & Scroll Offset Values & Refresh Screen
FB_Init:
  imm32 r5,FB_STRUCT + MAIL_TAGS
  imm32 r6,PERIPHERAL_BASE + MAIL_BASE + MAIL_WRITE + MAIL_TAGS
  str r5,[r6] ; Mail Box Write

  ldr r12,[FB_POINTER] ; R12 = Frame Buffer Pointer
  cmp r12,0 ; Compare Frame Buffer Pointer to Zero
  beq FB_Init ; IF Zero Re-Initialize Frame Buffer

  and r12,$3FFFFFFF ; Convert Mail Box Frame Buffer Pointer From BUS Address To Physical Address ($CXXXXXXX -> $3XXXXXXX)
  str r12,[FB_POINTER] ; Store Frame Buffer Pointer Physical Address

; Draw Characters
mov r5,32 ; r5 = Number Of Characters To Display On Row
mov r6,32 ; r6 = Number Of Characters To Display On Column
add r7,r10,BG1_RAM ; r7 = Tile Map
add r8,r10,$10000 ; r8 = Converted Character RAM Offset
imm32 r9,PERIPHERAL_BASE + DMA0_BASE + DMA_CS ; R9 = Control Block Status
imm32 r10,PERIPHERAL_BASE + DMA0_BASE + DMA_CONBLK_AD ; R10 = Control Block Data Address

DrawChars:
  ldrb r11,[r7],1 ; R11 = Next Character
  add r11,r8,r11,lsl 6 ; Add Shift To Correct Position In Font (* 64)
  str r11,[CHAR_SOURCE] ; Store DMA Source Address
  str r12,[CHAR_DEST] ; Store DMA Destination Address
  imm32 r11,CHAR_STRUCT ; R11 = Control Block Data
  str r11,[r10] ; Store DMA Control Block Data Address

  mov r11,DMA_ACTIVE ; R11 = DMA Active Bit
  str r11,[r9] ; Print Next Character To The Screen
  CHARWait:
    ldr r11,[r9] ; Load Control Block Status
    tst r11,DMA_ACTIVE ; Test Active Bit
    bne CHARWait ; Wait Until DMA Has Finished

  subs r5,1 ; Subtract Number Of Characters To Print
  add r12,CHAR_X * (BITS_PER_PIXEL / 8)
  bne DrawChars ; Continue to Print Characters

  subs r6,1 ; Subtract Number Of Rows To Print
  movne r5,32
  addne r12,VSCREEN_X * (BITS_PER_PIXEL / 8) * 7
  bne DrawChars ; Continue To Print Characters