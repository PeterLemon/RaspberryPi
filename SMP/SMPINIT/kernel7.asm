; Raspberry Pi 2 'Bare Metal' Symmetric Multi-Processing (SMP) Demo by krom (Peter Lemon):
; 1. Setup Frame Buffer
; 2. Get SMP CPU ID
; 3. Return Results From Each Core
; 4. Copy Result Value HEX Characters To Frame Buffer Using CPU

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

macro PrintTAGValueLE Text, TextLength, Value, ValueLength {
  PrintText Text, TextLength
  PrintValueLE Value, ValueLength
}

format binary as 'img'
include 'LIB\FASMARM.INC'
include 'LIB\R_PI2.INC'

; Setup Frame Buffer
SCREEN_X       = 640
SCREEN_Y       = 480
BITS_PER_PIXEL = 8

; Setup Characters
CHAR_X = 8
CHAR_Y = 8

org $0000

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

; Return CPU ID (0..3) Of The CPU Executed On
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
and r0,3 ; R0 = CPU ID (Bits 0..1)

cmp r0,1 ; IF (CPU ID == 1) Branch To Core 1 Code
beq Core1Code
cmp r0,2 ; IF (CPU ID == 2) Branch To Core 2 Code
beq Core2Code
cmp r0,3 ; IF (CPU ID == 3) Branch To Core 3 Code
beq Core3Code


imm32 r1,8 + (SCREEN_X * 8)
add r0,r10,r1 ; Place Text At XY Position 8,8
PrintText SMPText, 33


; Return Implement Multiprocessing Extensions
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
lsr r0,31 ; R0 = Multiprocessing Extensions (Bit 31)
strb r0,[Core0SMPReturnMPEValue] ; Store Multiprocessing Extensions

imm32 r1,16 + (SCREEN_X * 24)
add r0,r10,r1 ; Place Text At XY Position 16,24
PrintTAGValueLE Core0SMPReturnMPEText, 53, Core0SMPReturnMPEValue, 1


; Return Indicates Uses A Uniprocessor System
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
lsr r0,30 ; R0 = Uniprocessor (Bit 30)
and r0,1
strb r0,[Core0SMPReturnUNIValue] ; Store Uniprocessor

imm32 r1,16 + (SCREEN_X * 32)
add r0,r10,r1 ; Place Text At XY Position 16,32
PrintTAGValueLE Core0SMPReturnUNIText, 53, Core0SMPReturnUNIValue, 1


; Return Uses A Multi-Threading Type Approach
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
lsr r0,24 ; R0 = Multi-Threading (Bit 24)
and r0,1
strb r0,[Core0SMPReturnMTValue] ; Store Multi-Threading

imm32 r1,16 + (SCREEN_X * 40)
add r0,r10,r1 ; Place Text At XY Position 16,40
PrintTAGValueLE Core0SMPReturnMTText, 53, Core0SMPReturnMTValue, 1


; Return Value In CLUSTERID Configuration Pin
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
lsr r0,8 ; R0 = Cluster ID (Bits 8..11)
and r0,$F
strb r0,[Core0SMPReturnCLUIDValue] ; Store Cluster ID

imm32 r1,16 + (SCREEN_X * 48)
add r0,r10,r1 ; Place Text At XY Position 16,48
PrintTAGValueLE Core0SMPReturnCLUIDText, 53, Core0SMPReturnCLUIDValue, 1


; Return CPU ID (0..3) Of The CPU Executed On
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
and r0,3 ; R0 = CPU ID (Bits 0..1)
strb r0,[Core0SMPReturnCPUIDValue] ; Store CPU ID

imm32 r1,16 + (SCREEN_X * 56)
add r0,r10,r1 ; Place Text At XY Position 16,56
PrintTAGValueLE Core0SMPReturnCPUIDText, 53, Core0SMPReturnCPUIDValue, 1

Core0Loop:
  b Core0Loop

Core0SMPReturnMPEValue:   db $FF
Core0SMPReturnUNIValue:   db $FF
Core0SMPReturnMTValue:	  db $FF
Core0SMPReturnCLUIDValue: db $FF
Core0SMPReturnCPUIDValue: db $FF


align 4
Core1Code:
imm32 r1,FB_POINTER
ldr r10,[r1] ; R10 = Frame Buffer Pointer

; Return Implement Multiprocessing Extensions
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
lsr r0,31 ; R0 = Multiprocessing Extensions (Bit 31)
strb r0,[Core1SMPReturnMPEValue] ; Store Multiprocessing Extensions

imm32 r1,16 + (SCREEN_X * 72)
add r0,r10,r1 ; Place Text At XY Position 16,72
PrintTAGValueLE Core1SMPReturnMPEText, 53, Core1SMPReturnMPEValue, 1


; Return Indicates Uses A Uniprocessor System
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
lsr r0,30 ; R0 = Uniprocessor (Bit 30)
and r0,1
strb r0,[Core1SMPReturnUNIValue] ; Store Uniprocessor

imm32 r1,16 + (SCREEN_X * 80)
add r0,r10,r1 ; Place Text At XY Position 16,80
PrintTAGValueLE Core1SMPReturnUNIText, 53, Core1SMPReturnUNIValue, 1


; Return Uses A Multi-Threading Type Approach
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
lsr r0,24 ; R0 = Multi-Threading (Bit 24)
and r0,1
strb r0,[Core1SMPReturnMTValue] ; Store Multi-Threading

imm32 r1,16 + (SCREEN_X * 88)
add r0,r10,r1 ; Place Text At XY Position 16,88
PrintTAGValueLE Core1SMPReturnMTText, 53, Core1SMPReturnMTValue, 1


; Return Value In CLUSTERID Configuration Pin
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
lsr r0,8 ; R0 = Cluster ID (Bits 8..11)
and r0,$F
strb r0,[Core1SMPReturnCLUIDValue] ; Store Cluster ID

imm32 r1,16 + (SCREEN_X * 96)
add r0,r10,r1 ; Place Text At XY Position 16,96
PrintTAGValueLE Core1SMPReturnCLUIDText, 53, Core1SMPReturnCLUIDValue, 1


; Return CPU ID (0..3) Of The CPU Executed On
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
and r0,3 ; R0 = CPU ID (Bits 0..1)
strb r0,[Core1SMPReturnCPUIDValue] ; Store CPU ID

imm32 r1,16 + (SCREEN_X * 104)
add r0,r10,r1 ; Place Text At XY Position 16,104
PrintTAGValueLE Core1SMPReturnCPUIDText, 53, Core1SMPReturnCPUIDValue, 1

Core1Loop:
  b Core1Loop

Core1SMPReturnMPEValue:   db $FF
Core1SMPReturnUNIValue:   db $FF
Core1SMPReturnMTValue:	  db $FF
Core1SMPReturnCLUIDValue: db $FF
Core1SMPReturnCPUIDValue: db $FF


align 4
Core2Code:
imm32 r1,FB_POINTER
ldr r10,[r1] ; R10 = Frame Buffer Pointer

; Return Implement Multiprocessing Extensions
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
lsr r0,31 ; R0 = Multiprocessing Extensions (Bit 31)
strb r0,[Core2SMPReturnMPEValue] ; Store Multiprocessing Extensions

imm32 r1,16 + (SCREEN_X * 120)
add r0,r10,r1 ; Place Text At XY Position 16,120
PrintTAGValueLE Core2SMPReturnMPEText, 53, Core2SMPReturnMPEValue, 1


; Return Indicates Uses A Uniprocessor System
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
lsr r0,30 ; R0 = Uniprocessor (Bit 30)
and r0,1
strb r0,[Core2SMPReturnUNIValue] ; Store Uniprocessor

imm32 r1,16 + (SCREEN_X * 128)
add r0,r10,r1 ; Place Text At XY Position 16,128
PrintTAGValueLE Core2SMPReturnUNIText, 53, Core2SMPReturnUNIValue, 1


; Return Uses A Multi-Threading Type Approach
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
lsr r0,24 ; R0 = Multi-Threading (Bit 24)
and r0,1
strb r0,[Core2SMPReturnMTValue] ; Store Multi-Threading

imm32 r1,16 + (SCREEN_X * 136)
add r0,r10,r1 ; Place Text At XY Position 16,136
PrintTAGValueLE Core2SMPReturnMTText, 53, Core2SMPReturnMTValue, 1


; Return Value In CLUSTERID Configuration Pin
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
lsr r0,8 ; R0 = Cluster ID (Bits 8..11)
and r0,$F
strb r0,[Core2SMPReturnCLUIDValue] ; Store Cluster ID

imm32 r1,16 + (SCREEN_X * 144)
add r0,r10,r1 ; Place Text At XY Position 16,144
PrintTAGValueLE Core2SMPReturnCLUIDText, 53, Core2SMPReturnCLUIDValue, 1


; Return CPU ID (0..3) Of The CPU Executed On
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
and r0,3 ; R0 = CPU ID (Bits 0..1)
strb r0,[Core2SMPReturnCPUIDValue] ; Store CPU ID

imm32 r1,16 + (SCREEN_X * 152)
add r0,r10,r1 ; Place Text At XY Position 16,152
PrintTAGValueLE Core2SMPReturnCPUIDText, 53, Core2SMPReturnCPUIDValue, 1

Core2Loop:
  b Core2Loop

Core2SMPReturnMPEValue:   db $FF
Core2SMPReturnUNIValue:   db $FF
Core2SMPReturnMTValue:	  db $FF
Core2SMPReturnCLUIDValue: db $FF
Core2SMPReturnCPUIDValue: db $FF


align 4
Core3Code:
imm32 r1,FB_POINTER
ldr r10,[r1] ; R10 = Frame Buffer Pointer

; Return Implement Multiprocessing Extensions
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
lsr r0,31 ; R0 = Multiprocessing Extensions (Bit 31)
strb r0,[Core3SMPReturnMPEValue] ; Store Multiprocessing Extensions

imm32 r1,16 + (SCREEN_X * 168)
add r0,r10,r1 ; Place Text At XY Position 16,168
PrintTAGValueLE Core3SMPReturnMPEText, 53, Core3SMPReturnMPEValue, 1


; Return Indicates Uses A Uniprocessor System
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
lsr r0,30 ; R0 = Uniprocessor (Bit 30)
and r0,1
strb r0,[Core3SMPReturnUNIValue] ; Store Uniprocessor

imm32 r1,16 + (SCREEN_X * 176)
add r0,r10,r1 ; Place Text At XY Position 16,176
PrintTAGValueLE Core3SMPReturnUNIText, 53, Core3SMPReturnUNIValue, 1


; Return Uses A Multi-Threading Type Approach
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
lsr r0,24 ; R0 = Multi-Threading (Bit 24)
and r0,1
strb r0,[Core3SMPReturnMTValue] ; Store Multi-Threading

imm32 r1,16 + (SCREEN_X * 184)
add r0,r10,r1 ; Place Text At XY Position 16,184
PrintTAGValueLE Core3SMPReturnMTText, 53, Core3SMPReturnMTValue, 1


; Return Value In CLUSTERID Configuration Pin
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
lsr r0,8 ; R0 = Cluster ID (Bits 8..11)
and r0,$F
strb r0,[Core3SMPReturnCLUIDValue] ; Store Cluster ID

imm32 r1,16 + (SCREEN_X * 192)
add r0,r10,r1 ; Place Text At XY Position 16,192
PrintTAGValueLE Core3SMPReturnCLUIDText, 53, Core3SMPReturnCLUIDValue, 1


; Return CPU ID (0..3) Of The CPU Executed On
mrc p15,0,r0,c0,c0,5 ; R0 = Multiprocessor Affinity Register (MPIDR)
and r0,3 ; R0 = CPU ID (Bits 0..1)
strb r0,[Core3SMPReturnCPUIDValue] ; Store CPU ID

imm32 r1,16 + (SCREEN_X * 200)
add r0,r10,r1 ; Place Text At XY Position 16,200
PrintTAGValueLE Core3SMPReturnCPUIDText, 53, Core3SMPReturnCPUIDValue, 1

Core3Loop:
  b Core3Loop

Core3SMPReturnMPEValue:   db $FF
Core3SMPReturnUNIValue:   db $FF
Core3SMPReturnMTValue:	  db $FF
Core3SMPReturnCLUIDValue: db $FF
Core3SMPReturnCPUIDValue: db $FF


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

SMPText: db "Symmetric Multi-Processing (SMP):"

Core0SMPReturnMPEText:	 db "Core0 Return Implement Multiprocessing Extensions = $"
Core0SMPReturnUNIText:	 db "Core0 Return Indicates Uses A Uniprocessor System = $"
Core0SMPReturnMTText:	 db "Core0 Return Uses A Multi-Threading Type Approach = $"
Core0SMPReturnCLUIDText: db "Core0 Return Value In CLUSTERID Configuration Pin = $"
Core0SMPReturnCPUIDText: db "Core0 Return CPU ID (0..3) Of The CPU Executed On = $"

Core1SMPReturnMPEText:	 db "Core1 Return Implement Multiprocessing Extensions = $"
Core1SMPReturnUNIText:	 db "Core1 Return Indicates Uses A Uniprocessor System = $"
Core1SMPReturnMTText:	 db "Core1 Return Uses A Multi-Threading Type Approach = $"
Core1SMPReturnCLUIDText: db "Core1 Return Value In CLUSTERID Configuration Pin = $"
Core1SMPReturnCPUIDText: db "Core1 Return CPU ID (0..3) Of The CPU Executed On = $"

Core2SMPReturnMPEText:	 db "Core2 Return Implement Multiprocessing Extensions = $"
Core2SMPReturnUNIText:	 db "Core2 Return Indicates Uses A Uniprocessor System = $"
Core2SMPReturnMTText:	 db "Core2 Return Uses A Multi-Threading Type Approach = $"
Core2SMPReturnCLUIDText: db "Core2 Return Value In CLUSTERID Configuration Pin = $"
Core2SMPReturnCPUIDText: db "Core2 Return CPU ID (0..3) Of The CPU Executed On = $"

Core3SMPReturnMPEText:	 db "Core3 Return Implement Multiprocessing Extensions = $"
Core3SMPReturnUNIText:	 db "Core3 Return Indicates Uses A Uniprocessor System = $"
Core3SMPReturnMTText:	 db "Core3 Return Uses A Multi-Threading Type Approach = $"
Core3SMPReturnCLUIDText: db "Core3 Return Value In CLUSTERID Configuration Pin = $"
Core3SMPReturnCPUIDText: db "Core3 Return CPU ID (0..3) Of The CPU Executed On = $"

align 4
Font: include 'Font8x8.asm'