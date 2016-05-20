; Raspberry Pi 3 'Bare Metal' Symmetric Multi-Processing (SMP) Demo by krom (Peter Lemon):
; 1. Setup Frame Buffer
; 2. Get SMP CPU ID
; 3. Return Results From Each Core
; 4. Copy Result Value HEX Characters To Frame Buffer Using CPU

macro PrintText Text, TextLength {
  local .DrawChars,.DrawChar
  adr x1,Font ; X1 = Characters
  adr x2,Text ; X2 = Text Offset
  mov w3,TextLength ; W3 = Number Of Text Characters To Print
  .DrawChars:
    mov w4,CHAR_Y ; W4 = Character Row Counter
    ldrb x5,[x2],1 ; X5 = Next Text Character
    add x5,x1,x5,lsl 6 ; Add Shift To Correct Position In Font (* 64)

    .DrawChar:
      ldr x6,[x5],8 ; Load Font Text Character Row
      str x6,[x0],8 ; Store Font Text Character Row To Frame Buffer
      add x0,x0,SCREEN_X - CHAR_X ; Jump Down 1 Scanline, Jump Back 1 Char
      subs w4,w4,1 ; Decrement Character Row Counter
      b.ne .DrawChar ; IF (Character Row Counter != 0) DrawChar

    subs w3,w3,1 ; Subtract Number Of Text Characters To Print
    mov x4,(SCREEN_X * CHAR_Y) - CHAR_X
    sub x0,x0,x4 ; Jump To Top Of Char, Jump Forward 1 Char
    b.ne .DrawChars ; IF (Number Of Text Characters != 0) Continue To Print Characters
}

macro PrintValueLE Value, ValueLength {
  local .DrawHEXChars,.DrawHexNum,.DrawHexNumB,.DrawHEXChar,.DrawHEXCharB
  adr x1,Font ; X1 = Characters
  adr x2,Value ; X2 = Text Offset
  add x2,x2,ValueLength - 1
  mov w3,ValueLength ; W3 = Number Of HEX Characters To Print
  .DrawHEXChars:
    ldrb w4,[x2],-1 ; W4 = Next 2 HEX Characters
    lsr w5,w4,4 ; Get 2nd Nibble
    cmp w5,$9
    add w5,w5,$30
    b.le .DrawHexNum
    add w5,w5,$7
  .DrawHexNum:
    add x5,x1,x5,lsl 6 ; Add Shift To Correct Position In Font (* 64)
    mov w6,CHAR_Y ; W6 = Character Row Counter
    .DrawHEXChar:
      ldr x7,[x5],8 ; Load Font Text Character Row
      str x7,[x0],8 ; Store Font Text Character Row To Frame Buffer
      add x0,x0,SCREEN_X - CHAR_X ; Jump Down 1 Scanline, Jump Back 1 Char
      subs w6,w6,1 ; Decrement Character Row Counter
      b.ne .DrawHEXChar ; IF (Character Row Counter != 0) DrawChar

    mov x5,(SCREEN_X * CHAR_Y) - CHAR_X
    sub x0,x0,x5 ; Jump To Top Of Char, Jump Forward 1 Char

    and w5,w4,$F ; Get 1st Nibble
    cmp w5,$9
    add w5,w5,$30
    b.le .DrawHexNumB
    add w5,w5,$7
  .DrawHexNumB:
    add x5,x1,x5,lsl 6 ; Add Shift To Correct Position In Font (* 64)
    mov w6,CHAR_Y ; W6 = Character Row Counter
    .DrawHEXCharB:
      ldr x7,[x5],8 ; Load Font Text Character Row
      str x7,[x0],8 ; Store Font Text Character Row To Frame Buffer
      add x0,x0,SCREEN_X - CHAR_X ; Jump Down 1 Scanline, Jump Back 1 Char
      subs w6,w6,1 ; Decrement Character Row Counter
      b.ne .DrawHEXCharB ; IF (Character Row Counter != 0) DrawChar

    subs w3,w3,1 ; Subtract Number Of HEX Characters To Print
    mov x4,(SCREEN_X * CHAR_Y) - CHAR_X
    sub x0,x0,x4 ; Jump To Top Of Char, Jump Forward 1 Char
    b.ne .DrawHEXChars ; IF (Number Of Hex Characters != 0) Continue To Print Characters
}

macro PrintTAGValueLE Text, TextLength, Value, ValueLength {
  PrintText Text, TextLength
  PrintValueLE Value, ValueLength
}

code64
processor cpu64_v8
format binary as 'img'
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
  mov w0,FB_STRUCT + MAIL_TAGS
  mov x1,MAIL_BASE
  orr x1,x1,PERIPHERAL_BASE
  str w0,[x1,MAIL_WRITE + MAIL_TAGS] ; Mail Box Write

  ldr w10,[FB_POINTER] ; W10 = Frame Buffer Pointer
  cbz w10,FB_Init ; IF (Frame Buffer Pointer == Zero) Re-Initialize Frame Buffer

  and w10,w10,$3FFFFFFF ; Convert Mail Box Frame Buffer Pointer From BUS Address To Physical Address ($CXXXXXXX -> $3XXXXXXX)
  adr x0,FB_POINTER
  str w10,[x0] ; Store Frame Buffer Pointer Physical Address

; Return CPU ID (0..3) Of The CPU Executed On
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
and x0,x0,3 ; X0 = CPU ID (Bits 0..1)

cmp x0,1 ; IF (CPU ID == 1) Branch To Core 1 Code
b.eq Core1Code
cmp x0,2 ; IF (CPU ID == 2) Branch To Core 2 Code
b.eq Core2Code
cmp x0,3 ; IF (CPU ID == 3) Branch To Core 3 Code
b.eq Core3Code


mov w1,8 + (SCREEN_X * 8)
add w0,w10,w1 ; Place Text At XY Position 8,8
PrintText SMPText, 33


; Return Implement Multiprocessing Extensions
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
lsr x0,x0,31 ; X0 = Multiprocessing Extensions (Bit 31)
adr x1,Core0SMPReturnMPEValue
strb x0,[x1] ; Store Multiprocessing Extensions

mov w1,16 + (SCREEN_X * 24)
add w0,w10,w1 ; Place Text At XY Position 16,24
PrintTAGValueLE Core0SMPReturnMPEText, 53, Core0SMPReturnMPEValue, 1


; Return Indicates Uses A Uniprocessor System
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
lsr x0,x0,30 ; X0 = Uniprocessor (Bit 30)
and x0,x0,1
adr x1,Core0SMPReturnUNIValue
strb x0,[x1] ; Store Uniprocessor

mov w1,16 + (SCREEN_X * 32)
add w0,w10,w1 ; Place Text At XY Position 16,32
PrintTAGValueLE Core0SMPReturnUNIText, 53, Core0SMPReturnUNIValue, 1


; Return Uses A Multi-Threading Type Approach
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
lsr x0,x0,24 ; X0 = Multi-Threading (Bit 24)
and x0,x0,1
adr x1,Core0SMPReturnMTValue
strb x0,[x1] ; Store Multi-Threading

mov w1,16 + (SCREEN_X * 40)
add w0,w10,w1 ; Place Text At XY Position 16,40
PrintTAGValueLE Core0SMPReturnMTText, 53, Core0SMPReturnMTValue, 1


; Return Value In CLUSTERID Configuration Pin
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
lsr x0,x0,8 ; X0 = Cluster ID (Bits 8..11)
and x0,x0,$F
adr x1,Core0SMPReturnCLUIDValue
strb x0,[x1] ; Store Cluster ID

mov w1,16 + (SCREEN_X * 48)
add w0,w10,w1 ; Place Text At XY Position 16,48
PrintTAGValueLE Core0SMPReturnCLUIDText, 53, Core0SMPReturnCLUIDValue, 1


; Return CPU ID (0..3) Of The CPU Executed On
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
and x0,x0,3 ; X0 = CPU ID (Bits 0..1)
adr x1,Core0SMPReturnCPUIDValue
strb x0,[x1] ; Store CPU ID

mov w1,16 + (SCREEN_X * 56)
add w0,w10,w1 ; Place Text At XY Position 16,56
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
adr x1,FB_POINTER
ldr w10,[x1] ; W10 = Frame Buffer Pointer

; Return Implement Multiprocessing Extensions
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
lsr x0,x0,31 ; X0 = Multiprocessing Extensions (Bit 31)
adr x1,Core1SMPReturnMPEValue
strb x0,[x1] ; Store Multiprocessing Extensions

mov w1,16 + (SCREEN_X * 72)
add w0,w10,w1 ; Place Text At XY Position 16,72
PrintTAGValueLE Core1SMPReturnMPEText, 53, Core1SMPReturnMPEValue, 1


; Return Indicates Uses A Uniprocessor System
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
lsr x0,x0,30 ; X0 = Uniprocessor (Bit 30)
and x0,x0,1
adr x1,Core1SMPReturnUNIValue
strb x0,[x1] ; Store Uniprocessor

mov w1,16 + (SCREEN_X * 80)
add w0,w10,w1 ; Place Text At XY Position 16,80
PrintTAGValueLE Core1SMPReturnUNIText, 53, Core1SMPReturnUNIValue, 1


; Return Uses A Multi-Threading Type Approach
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
lsr x0,x0,24 ; X0 = Multi-Threading (Bit 24)
and x0,x0,1
adr x1,Core1SMPReturnMTValue
strb x0,[x1] ; Store Multi-Threading

mov w1,16 + (SCREEN_X * 88)
add w0,w10,w1 ; Place Text At XY Position 16,88
PrintTAGValueLE Core1SMPReturnMTText, 53, Core1SMPReturnMTValue, 1


; Return Value In CLUSTERID Configuration Pin
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
lsr x0,x0,8 ; X0 = Cluster ID (Bits 8..11)
and x0,x0,$F
adr x1,Core1SMPReturnCLUIDValue
strb x0,[x1] ; Store Cluster ID

mov w1,16 + (SCREEN_X * 96)
add w0,w10,w1 ; Place Text At XY Position 16,96
PrintTAGValueLE Core1SMPReturnCLUIDText, 53, Core1SMPReturnCLUIDValue, 1


; Return CPU ID (0..3) Of The CPU Executed On
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
and x0,x0,3 ; X0 = CPU ID (Bits 0..1)
adr x1,Core1SMPReturnCPUIDValue
strb x0,[x1] ; Store CPU ID

mov w1,104 ; (SCREEN_X * 104)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,16
add w0,w10,w1 ; Place Text At XY Position 16,104
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
adr x1,FB_POINTER
ldr w10,[x1] ; W10 = Frame Buffer Pointer

; Return Implement Multiprocessing Extensions
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
lsr x0,x0,31 ; X0 = Multiprocessing Extensions (Bit 31)
adr x1,Core2SMPReturnMPEValue
strb x0,[x1] ; Store Multiprocessing Extensions

mov w1,120 ; (SCREEN_X * 120)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,16
add w0,w10,w1 ; Place Text At XY Position 16,120
PrintTAGValueLE Core2SMPReturnMPEText, 53, Core2SMPReturnMPEValue, 1


; Return Indicates Uses A Uniprocessor System
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
lsr x0,x0,30 ; X0 = Uniprocessor (Bit 30)
and x0,x0,1
adr x1,Core2SMPReturnUNIValue
strb x0,[x1] ; Store Uniprocessor

mov w1,128 ; (SCREEN_X * 128)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,16
add w0,w10,w1 ; Place Text At XY Position 16,128
PrintTAGValueLE Core2SMPReturnUNIText, 53, Core2SMPReturnUNIValue, 1


; Return Uses A Multi-Threading Type Approach
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
lsr x0,x0,24 ; X0 = Multi-Threading (Bit 24)
and x0,x0,1
adr x1,Core2SMPReturnMTValue
strb x0,[x1] ; Store Multi-Threading

mov w1,136 ; (SCREEN_X * 136)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,16
add w0,w10,w1 ; Place Text At XY Position 16,136
PrintTAGValueLE Core2SMPReturnMTText, 53, Core2SMPReturnMTValue, 1


; Return Value In CLUSTERID Configuration Pin
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
lsr x0,x0,8 ; X0 = Cluster ID (Bits 8..11)
and x0,x0,$F
adr x1,Core2SMPReturnCLUIDValue
strb x0,[x1] ; Store Cluster ID

mov w1,144 ; (SCREEN_X * 144)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,16
add w0,w10,w1 ; Place Text At XY Position 16,144
PrintTAGValueLE Core2SMPReturnCLUIDText, 53, Core2SMPReturnCLUIDValue, 1


; Return CPU ID (0..3) Of The CPU Executed On
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
and x0,x0,3 ; X0 = CPU ID (Bits 0..1)
adr x1,Core2SMPReturnCPUIDValue
strb x0,[x1] ; Store CPU ID

mov w1,152 ; (SCREEN_X * 152)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,16
add w0,w10,w1 ; Place Text At XY Position 16,152
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
adr x1,FB_POINTER
ldr w10,[x1] ; W10 = Frame Buffer Pointer

; Return Implement Multiprocessing Extensions
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
lsr x0,x0,31 ; X0 = Multiprocessing Extensions (Bit 31)
adr x1,Core3SMPReturnMPEValue
strb x0,[x1] ; Store Multiprocessing Extensions

mov w1,168 ; (SCREEN_X * 168)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,16
add w0,w10,w1 ; Place Text At XY Position 16,168
PrintTAGValueLE Core3SMPReturnMPEText, 53, Core3SMPReturnMPEValue, 1


; Return Indicates Uses A Uniprocessor System
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
lsr x0,x0,30 ; X0 = Uniprocessor (Bit 30)
and x0,x0,1
adr x1,Core3SMPReturnUNIValue
strb x0,[x1] ; Store Uniprocessor

mov w1,176 ; (SCREEN_X * 176)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,16
add w0,w10,w1 ; Place Text At XY Position 16,176
PrintTAGValueLE Core3SMPReturnUNIText, 53, Core3SMPReturnUNIValue, 1


; Return Uses A Multi-Threading Type Approach
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
lsr x0,x0,24 ; X0 = Multi-Threading (Bit 24)
and x0,x0,1
adr x1,Core3SMPReturnMTValue
strb x0,[x1] ; Store Multi-Threading

mov w1,184 ; (SCREEN_X * 184)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,16
add w0,w10,w1 ; Place Text At XY Position 16,184
PrintTAGValueLE Core3SMPReturnMTText, 53, Core3SMPReturnMTValue, 1


; Return Value In CLUSTERID Configuration Pin
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
lsr x0,x0,8 ; X0 = Cluster ID (Bits 8..11)
and x0,x0,$F
adr x1,Core3SMPReturnCLUIDValue
strb x0,[x1] ; Store Cluster ID

mov w1,192 ; (SCREEN_X * 192)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,16
add w0,w10,w1 ; Place Text At XY Position 16,192
PrintTAGValueLE Core3SMPReturnCLUIDText, 53, Core3SMPReturnCLUIDValue, 1


; Return CPU ID (0..3) Of The CPU Executed On
mrs x0,MPIDR_EL1 ; X0 = Multiprocessor Affinity Register (MPIDR)
and x0,x0,3 ; X0 = CPU ID (Bits 0..1)
adr x1,Core3SMPReturnCPUIDValue
strb x0,[x1] ; Store CPU ID

mov w1,200 ; (SCREEN_X * 200)
mov w2,SCREEN_X
mul w1,w1,w2
add w1,w1,16
add w0,w10,w1 ; Place Text At XY Position 16,200
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

align 8
Font: include 'Font8x8.asm'