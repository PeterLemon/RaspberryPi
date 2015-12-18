; Raspberry Pi 'Bare Metal' V3D Refresh Multi Sample Vertex Color NV Vertex Array Triangle Control List Demo by krom (Peter Lemon):
; 1. Run Tags & Set V3D Frequency To 250MHz, & Enable Quad Processing Unit
; 2. Setup Frame Buffer
; 3. Setup & Run V3D Control List Rendered Tile Buffer

format binary as 'img'
include 'LIB\FASMARM.INC'
include 'LIB\R_PI.INC'
include 'LIB\V3D.INC'
include 'LIB\CONTROL_LIST.INC'

; Setup Frame Buffer
SCREEN_X       = 640
SCREEN_Y       = 480
BITS_PER_PIXEL = 32

; Setup V3D Binning
BIN_ADDRESS = $00400000
BIN_BASE    = $00500000

org $0000

; Run Tags To Initialize V3D
imm32 r0,PERIPHERAL_BASE + MAIL_BASE
imm32 r1,TAGS_STRUCT
orr r1,MAIL_TAGS
str r1,[r0,MAIL_WRITE] ; Mail Box Write

FB_Init:
  imm32 r0,FB_STRUCT + MAIL_TAGS
  imm32 r1,PERIPHERAL_BASE + MAIL_BASE + MAIL_WRITE + MAIL_TAGS
  str r0,[r1] ; Mail Box Write

  ldr r0,[FB_POINTER] ; R0 = Frame Buffer Pointer
  cmp r0,0 ; Compare Frame Buffer Pointer To Zero
  beq FB_Init ; IF Zero Re-Initialize Frame Buffer

  and r0,$3FFFFFFF ; Convert Mail Box Frame Buffer Pointer From BUS Address To Physical Address ($CXXXXXXX -> $3XXXXXXX)
  str r0,[FB_POINTER] ; Store Frame Buffer Pointer Physical Address

imm32 r1,TILE_MODE_ADDRESS + 1 ; Store Frame Buffer Pointer To Control List Tile Rendering Mode Configuration Memory Address
strb r0,[r1],1
lsr r0,8
strb r0,[r1],1
lsr r0,8
strb r0,[r1],1
lsr r0,8
strb r0,[r1],1

Refresh:
  ; Run Binning Control List (Thread 0)
  imm32 r0,PERIPHERAL_BASE + V3D_BASE ; Load V3D Base Address
  mov r1,1
  str r1,[r0,V3D_BFC] ; Reset Flush Count
  str r1,[r0,V3D_RFC] ; Reset Frame Count

  imm32 r1,CONTROL_LIST_BIN_STRUCT ; Store Control List Executor Binning Thread 0 Current Address
  str r1,[r0,V3D_CT0CA]
  imm32 r1,CONTROL_LIST_BIN_END ; Store Control List Executor Binning Thread 0 End Address
  str r1,[r0,V3D_CT0EA] ; When End Address Is Stored Control List Thread Executes

  WaitBinControlList: ; Wait For Control List To Execute
    ldr r1,[r0,V3D_BFC] ; Load Flush Count
    tst r1,1 ; Test IF PTB Has Flushed All Tile Lists To Memory
    beq WaitBinControlList

  ; Run Rendering Control List (Thread 1)
  imm32 r1,CONTROL_LIST_RENDER_STRUCT ; Store Control List Executor Rendering Thread 1 Current Address
  str r1,[r0,V3D_CT1CA]
  imm32 r1,CONTROL_LIST_RENDER_END ; Store Control List Executor Rendering Thread 1 End Address
  str r1,[r0,V3D_CT1EA] ; When End Address Is Stored Control List Thread Executes

  WaitRenderControlList: ; Wait For Control List To Execute
    ldr r1,[r0,V3D_RFC] ; Load Frame Count
    tst r1,1 ; Test IF Last Tile Store Operation Of The Frame Is Complete
    beq WaitRenderControlList

  ; Translate Primitive X
  imm32 r0,VERTEX_DATA
  ldrh r1,[r0] ; Vertex 0
  cmp r1,160 * 16
  moveq r2,1 ; Translation X Direction Increment
  add r1,r2
  strh r1,[r0],6 * 4

  ldrh r1,[r0] ; Vertex 1
  add r1,r2
  strh r1,[r0],6 * 4

  ldrh r1,[r0] ; Vertex 2
  cmp r1,608 * 16
  mvneq r2,0 ; Translation X Direction Decrement
  add r1,r2
  strh r1,[r0]

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
  dw Set_Clock_Rate ; Tag Identifier
  dw $00000008 ; Value Buffer Size In Bytes
  dw $00000008 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw CLK_V3D_ID ; Value Buffer (V3D Clock ID)
  dw 250*1000*1000 ; Value Buffer (250MHz)

  dw Enable_QPU ; Tag Identifier
  dw $00000004 ; Value Buffer Size In Bytes
  dw $00000004 ; 1 bit (MSB) Request/Response Indicator (0=Request, 1=Response), 31 bits (LSB) Value Length In Bytes
  dw 1 ; Value Buffer (1 = Enable)

dw $00000000 ; $0 (End Tag)
TAGS_END:

align 4
CONTROL_LIST_BIN_STRUCT: ; Control List Of Concatenated Control Records & Data Structure (Binning Mode Thread 0)
  Tile_Binning_Mode_Configuration BIN_ADDRESS, $2000, BIN_BASE, SCREEN_X / 32, SCREEN_Y / 32, Multisample_Mode_4X + Auto_Initialise_Tile_State_Data_Array ; Tile Binning Mode Configuration (B) (Address, Size, Base Address, Tile Width, Tile Height, Data)
  Start_Tile_Binning ; Start Tile Binning (Advances State Counter So That Initial State Items Actually Go Into Tile Lists) (B)

  Clip_Window 0, 0, SCREEN_X, SCREEN_Y ; Clip Window
  Configuration_Bits Rasteriser_Oversample_Mode_4X + Enable_Forward_Facing_Primitive + Enable_Reverse_Facing_Primitive, Early_Z_Updates_Enable ; Configuration Bits
  Viewport_Offset 0, 0 ; Viewport Offset
  NV_Shader_State NV_SHADER_STATE_RECORD ; NV Shader State (No Vertex Shading)
  Vertex_Array_Primitives Mode_Triangles, 3, 0 ; Vertex Array Primitives (OpenGL)
  Flush ; Flush (Add Return-From-Sub-List To Tile Lists & Then Flush Tile Lists To Memory) (B)
CONTROL_LIST_BIN_END:

align 4
CONTROL_LIST_RENDER_STRUCT: ; Control List Of Concatenated Control Records & Data Structures (Rendering Mode Thread 1)
  Clear_Colors $FF00FFFFFF00FFFF, 0, 0, 0 ; Clear Colors (R) (Clear Color (Yellow/Yellow), Clear ZS, Clear VGMask, Clear Stencil)

  TILE_MODE_ADDRESS:
    Tile_Rendering_Mode_Configuration $00000000, SCREEN_X, SCREEN_Y, Multisample_Mode_4X + Frame_Buffer_Color_Format_RGBA8888 ; Tile Rendering Mode Configuration (R) (Address, Width, Height, Data)

  Tile_Coordinates 0, 0 ; Tile Coordinates (R) (Tile Column, Tile Row)
  Store_Tile_Buffer_General 0, 0, 0 ; Store Tile Buffer General (R)

  tx = SCREEN_X / 32
  ty = SCREEN_Y / 32
  y = 0
  while y < ty
    x = 0
    while x < tx
      Tile_Coordinates x, y ; Tile Coordinates (R) (Tile Column, Tile Row)
      Branch_To_Sub_List BIN_ADDRESS + ((y * tx + x) * 32); Branch To Sub List (32-Bit Absolute Branch Address, Maximum Of 2 Levels Of Nesting)
      if y = ty - 1
	if x = tx - 1
	  Store_Multi_Sample_End ; Store Multi-Sample (Resolved Tile Color Buffer & Signal End Of Frame) (R)
	  x = x + 1
	  break
	end if
      end if
      Store_Multi_Sample ; Store Multi-Sample (Resolved Tile Color Buffer) (R)
      x = x + 1
    end while
    y = y + 1
  end while
CONTROL_LIST_RENDER_END:

align 16 ; 128-Bit Align
NV_SHADER_STATE_RECORD:
  db 0 ; Flag Bits: 0 = Fragment Shader Is Single Threaded, 1 = Point Size Included In Shaded Vertex Data, 2 = Enable Clipping, 3 = Clip Coordinates Header Included In Shaded Vertex Data
  db 6 * 4 ; Shaded Vertex Data Stride
  db 0 ; Fragment Shader Number Of Uniforms (Not Used Currently)
  db 3 ; Fragment Shader Number Of Varyings
  dw FRAGMENT_SHADER_CODE ; Fragment Shader Code Address
  dw 0 ; Fragment Shader Uniforms Address
  dw VERTEX_DATA ; Shaded Vertex Data Address (128-Bit Aligned If Including Clip Coordinate Header)

align 16 ; 128-Bit Align
VERTEX_DATA:
  ; Vertex: Top, Red
  dh 160 * 16 ; X In 12.4 Fixed Point
  dh 152 * 16 ; Y In 12.4 Fixed Point
  dw 1.0 ; Z
  dw 1.0 ; 1 / W
  dw 1.0 ; Varying 0 (Red)
  dw 0.0 ; Varying 1 (Green)
  dw 0.0 ; Varying 2 (Blue)

  ; Vertex: Bottom Left, Green
  dh  32 * 16 ; X In 12.4 Fixed Point
  dh 328 * 16 ; Y In 12.4 Fixed Point
  dw 1.0 ; Z
  dw 1.0 ; 1 / W
  dw 0.0 ; Varying 0 (Red)
  dw 1.0 ; Varying 1 (Green)
  dw 0.0 ; Varying 2 (Blue)

  ; Vertex: Bottom Right, Blue
  dh 288 * 16 ; X In 12.4 Fixed Point
  dh 328 * 16 ; Y In 12.4 Fixed Point
  dw 1.0 ; Z
  dw 1.0 ; 1 / W
  dw 0.0 ; Varying 0 (Red)
  dw 0.0 ; Varying 1 (Green)
  dw 1.0 ; Varying 2 (Blue)

align 16 ; 128-Bit Align
FRAGMENT_SHADER_CODE:
  ; Vertex Color Shader
  dw $958E0DBF
  dw $D1724823 ; mov r0, vary; mov r3.8d, 1.0
  dw $818E7176
  dw $40024821 ; fadd r0, r0, r5; mov r1, vary
  dw $818E7376
  dw $10024862 ; fadd r1, r1, r5; mov r2, vary
  dw $819E7540
  dw $114248A3 ; fadd r2, r2, r5; mov r3.8a, r0
  dw $809E7009
  dw $115049E3 ; nop; mov r3.8b, r1
  dw $809E7012
  dw $116049E3 ; nop; mov r3.8c, r2
  dw $159E76C0
  dw $30020BA7 ; mov tlbc, r3; nop; thrend
  dw $009E7000
  dw $100009E7 ; nop; nop; nop
  dw $009E7000
  dw $500009E7 ; nop; nop; sbdone