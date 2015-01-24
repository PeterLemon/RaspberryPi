; Raspberry Pi VideoCoreIV
;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Control ID Codes (Single Byte, B = Binning Only, R = Rendering Only)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

macro Halt { ; Control ID Code: Halt
  db $00 ; Control ID Code Byte: ID Code #0
}

macro No_Op { ; Control ID Code: NOP
  db $01 ; Control ID Code Byte: ID Code #1
}

macro Flush { ; Control ID Code: Flush (Add Return-From-Sub-List To Tile Lists & Then Flush Tile Lists To Memory) (B)
  db $04 ; Control ID Code Byte: ID Code #4
}

macro Flush_All_State { ; Control ID Code: Flush All State (Same As Flush, But Preceded By The Forced Writing Of The Current State To The Tile Lists) (B)
  db $05 ; Control ID Code Byte: ID Code #5
}

macro Start_Tile_Binning { ; Control ID Code: Start Tile Binning (Advances State Counter So That Initial State Items Actually Go Into Tile Lists) (B)
  db $06 ; Control ID Code Byte: ID Code #6
}

macro Increment_Semaphore { ; Control ID Code: Increment Semaphore (After Tile Lists Are Flushed Or Last Tile Written)
  db $07 ; Control ID Code Byte: ID Code #7
}

macro Wait_On_Semaphore { ; Control ID Code: Wait On Semaphore (Wait For Frame To Complete In Other Thread)
  db $08 ; Control ID Code Byte: ID Code #8
}

; Branch: Branch Control ID Code Data Record Description
Branch_Address = $FFFFFFFF ; Branch: 32-Bit Absolute Branch Address
macro Branch address { ; Control ID Code: Branch (32-Bit Absolute Branch Address)
  db $10 ; Control ID Code Byte: ID Code #16
  dw address ; Control ID Data Record Word: 32-Bit Absolute Branch Address (Bit 0..31)
}

; Branch_To_Sub_List: Branch To Sub List Control ID Code Data Record Description
Branch_Address = $FFFFFFFF ; Branch To Sub List: 32-Bit Absolute Branch Address
macro Branch_To_Sub_List address { ; Control ID Code: Branch To Sub List (32-Bit Absolute Branch Address, Maximum Of 2 Levels Of Nesting)
  db $11 ; Control ID Code Byte: ID Code #17
  dw address ; Control ID Data Record Word: 32-Bit Absolute Branch Address (Bit 0..31)
}

macro Return_From_Sub_List { ; Control ID Code: Return From Sub-List (Ignored If Nothing On The Return Stack)
  db $12 ; Control ID Code Byte: ID Code #18
}

macro Store_Multi_Sample { ; Control ID Code: Store Multi-Sample (Resolved Tile Color Buffer) (R)
  db $18 ; Control ID Code Byte: ID Code #24
}

macro Store_Multi_Sample_End { ; Control ID Code: Store Multi-Sample (Resolved Tile Color Buffer & Signal End Of Frame) (R)
  db $19 ; Control ID Code Byte: ID Code #25
}

; Store_Full_Resolution: Store Full Resolution Tile Buffer Control ID Code Data Record Description
Disable_Color_Buffer_Write     = $00000001 ; Store_Full_Resolution: Disable Color Buffer Write
Disable_Z_Stencil_Buffer_Write = $00000002 ; Store_Full_Resolution: Disable Z/Stencil Buffer Write
Disable_Clear_On_Write         = $00000004 ; Store_Full_Resolution: Disable Clear On Write
Last_Tile_Of_Frame             = $00000008 ; Store_Full_Resolution: Last Tile Of Frame
Memory_Base_Address            = $FFFFFFF0 ; Store_Full_Resolution: Memory Base Address Of Tile (In Multiples Of 16 Bytes)
macro Store_Full_Resolution data, address { ; Control ID Code: Store Full Resolution Tile Buffer (32-Bit Data Record) (R)
  db $1A ; Control ID Code Byte: ID Code #26
  dw address + data ; Control ID Data Record Word: Memory Address Of Tile (In Multiples Of 16 Bytes) (Bit 4..31), Data Record (Bit 0..3)
}

; Re_Load_Full_Resolution: Re-Load Full Resolution Tile Buffer Control ID Code Data Record Description
Disable_Color_Buffer_Read     = $00000001 ; Store_Full_Resolution: Disable Color Buffer Read
Disable_Z_Stencil_Buffer_Read = $00000002 ; Store_Full_Resolution: Disable Z/Stencil Buffer Read
Memory_Base_Address           = $FFFFFFF0 ; Store_Full_Resolution: Memory Base Address Of Tile (In Multiples Of 16 Bytes)
macro Re_Load_Full_Resolution data, address { ; Control ID Code: Re-Load Full Resolution Tile Buffer (32-Bit Data Record) (R)
  db $1B ; Control ID Code Byte: ID Code #27
  dw address + data ; Control ID Data Record Word: Memory Address Of Tile (In Multiples Of 16 Bytes) (Bit 4..31), Data Record (Bit 0..3)
}

; Store_Tile_Buffer_General: Store Tile Buffer General Control ID Code Data Record Description
Store_None      = $0000 ; Store_Tile_Buffer_General: Buffer To Store = None
Store_Color     = $0001 ; Store_Tile_Buffer_General: Buffer To Store = Color
Store_Z_Stencil = $0002 ; Store_Tile_Buffer_General: Buffer To Store = Z/Stencil
Store_Z_Only    = $0003 ; Store_Tile_Buffer_General: Buffer To Store = Z-Only
Store_VG_Mask   = $0004 ; Store_Tile_Buffer_General: Buffer To Store = VG-Mask
Store_Full_Dump = $0005 ; Store_Tile_Buffer_General: Buffer To Store = Full Dump
Format_Raster = $0000 ; Store_Tile_Buffer_General: Format = Raster Format
Format_T      = $0010 ; Store_Tile_Buffer_General: Format = T-Format
Format_LT     = $0020 ; Store_Tile_Buffer_General: Format = LT-Format
Mode_Sample       = $0000 ; Store_Tile_Buffer_General: Mode = Sample 
Mode_Decimate_4X  = $0040 ; Store_Tile_Buffer_General: Mode = Decimate 4X
Mode_Decimate_16X = $0080 ; Store_Tile_Buffer_General: Mode = Decimate 16X
Color_Format_RGBA8888         = $0000 ; Store_Tile_Buffer_General: Pixel Color Format = RGBA8888
Color_Format_BGR565_Dithered  = $0100 ; Store_Tile_Buffer_General: Pixel Color Format = BGR565 Dithered
Color_Format_BGR565_No_Dither = $0200 ; Store_Tile_Buffer_General: Pixel Color Format = BGR565 No Dither
Disable_Double_Buffer_Swap     = $1000 ; Store_Tile_Buffer_General: Disable Double-Buffer Swap In Double Buffer Mode
Disable_Color_Buffer_Clear     = $2000 ; Store_Tile_Buffer_General: Disable Color Buffer Clear On Store/Dump
Disable_Z_Stencil_Buffer_Clear = $4000 ; Store_Tile_Buffer_General: Disable Z/Stencil Buffer Clear On Store/Dump
Disable_VG_Mask_Buffer_Clear   = $8000 ; Store_Tile_Buffer_General: Disable VG-Mask Buffer Clear On Store/Dump
Disable_Color_Buffer_Dump     = $00000001 ; Store_Tile_Buffer_General: Disable Color Buffer Dump
Disable_Z_Stencil_Buffer_Dump = $00000002 ; Store_Tile_Buffer_General: Disable Z/Stencil Buffer Dump
Disable_VG_Mask_Buffer_Dump   = $00000004 ; Store_Tile_Buffer_General: Disable VG-Mask Buffer Dump
Last_Tile_Of_Frame            = $00000008 ; Store_Tile_Buffer_General: Last Tile Of Frame
Memory_Base_Address           = $FFFFFFF0 ; Store_Tile_Buffer_General: Memory Base Address Of Frame/Tile Dump Buffer (In multiples of 16 bytes)
macro Store_Tile_Buffer_General data16, data32, address { ; Control ID Code: Store Tile Buffer General (R)
  db $1C ; Control ID Code Byte: ID Code #28
  dh data16 ; Control ID Data Record Short: (Bit 0..15)
  dw address + data32 ; Control ID Data Record Word: Memory Base Address Of Frame/Tile Dump Buffer (In Multiples Of 16 Bytes) (Bit 20..47), Data Record (Bit 16..19)
}

; Load_Tile_Buffer_General: Load Tile Buffer General Control ID Code Data Record Description
Load_None        = $0000 ; Load_Tile_Buffer_General: Buffer To Load = None
Load_Color       = $0001 ; Load_Tile_Buffer_General: Buffer To Load = Color
Load_Z_Stencil   = $0002 ; Load_Tile_Buffer_General: Buffer To Load = Z/Stencil
Load_NA          = $0003 ; Load_Tile_Buffer_General: Buffer To Load = N/A
Load_VG_Mask     = $0004 ; Load_Tile_Buffer_General: Buffer To Load = VG-Mask
Load_Full_Reload = $0005 ; Load_Tile_Buffer_General: Buffer To Load = Full Reload
Format_Raster = $0000 ; Load_Tile_Buffer_General: Format = Raster Format
Format_T      = $0010 ; Load_Tile_Buffer_General: Format = T-Format
Format_LT     = $0020 ; Load_Tile_Buffer_General: Format = LT-Format
Color_Format_RGBA8888         = $0000 ; Load_Tile_Buffer_General: Pixel Color Format = RGBA8888
Color_Format_BGR565_Dithered  = $0100 ; Load_Tile_Buffer_General: Pixel Color Format = BGR565 Dithered
Color_Format_BGR565_No_Dither = $0200 ; Load_Tile_Buffer_General: Pixel Color Format = BGR565 No Dither
Disable_Color_Buffer_Load     = $00000001 ; Load_Tile_Buffer_General: Disable Color Buffer Load
Disable_Z_Stencil_Buffer_Load = $00000002 ; Load_Tile_Buffer_General: Disable Z/Stencil Buffer Load
Disable_VG_Mask_Buffer_Load   = $00000004 ; Load_Tile_Buffer_General: Disable VG-Mask Buffer Load
Memory_Base_Address           = $FFFFFFF0 ; Load_Tile_Buffer_General: Memory Base Address Of Frame/Tile Dump Buffer (In multiples of 16 bytes)
macro Load_Tile_Buffer_General data16, data32, address { ; Control ID Code: Load Tile Buffer General (R)
  db $1D ; Control ID Code Byte: ID Code #29
  dh data16 ; Control ID Data Record Short: (Bit 0..15)
  dw address + data32 ; Control ID Data Record Word: Memory Base Address Of Frame/Tile Dump Buffer (In Multiples Of 16 Bytes) (Bit 20..47), Data Record (Bit 16..19)
}

;;;;;;;;;;;;;;;;;;
; Primitive Lists
;;;;;;;;;;;;;;;;;;
; Indexed_Primitive_List: Indexed Primitive List (OpenGL) Control ID Code Data Record Description
Mode_Points         = $00 ; Indexed_Primitive_List: Primitive Mode = Points
Mode_Lines          = $01 ; Indexed_Primitive_List: Primitive Mode = Lines
Mode_Line_Loop      = $02 ; Indexed_Primitive_List: Primitive Mode = Line Loop
Mode_Line_Strip     = $03 ; Indexed_Primitive_List: Primitive Mode = Line Strip
Mode_Triangles      = $04 ; Indexed_Primitive_List: Primitive Mode = Triangles
Mode_Triangle_Strip = $05 ; Indexed_Primitive_List: Primitive Mode = Triangle Strip
Mode_Triangle_Fan   = $06 ; Indexed_Primitive_List: Primitive Mode = Triangle Fan
Index_Type_8  = $00 ; Indexed_Primitive_List: Index Type = 8-Bit
Index_Type_16 = $10 ; Indexed_Primitive_List: Index Type = 16-Bit
Indices_Length       = $FFFFFFFF ; Indexed_Primitive_List: Length (Number Of Indices)
Indices_List_Address = $FFFFFFFF ; Indexed_Primitive_List: Address Of Indices List
Maximum_Index        = $FFFFFFFF ; Indexed_Primitive_List: Maximum Index (Primitives Using A Greater Index Will Cause Error)
macro Indexed_Primitive_List data, length, address, maxindex { ; Control ID Code: Indexed Primitive List (OpenGL)
  db $20 ; Control ID Code Byte: ID Code #32
  db data     ; Control ID Data Record Byte: (Bit 0..7)
  dw length   ; Control ID Data Record Word: Length (Number Of Indices) (Bit 8..39)
  dw address  ; Control ID Data Record Word: Address Of Indices List (Bit 40..71)
  dw maxindex ; Control ID Data Record Word: Maximum Index (Bit 72..103)
}

; Vertex_Array_Primitives: Vertex Array Primitives (OpenGL) Control ID Code Data Record Description
Mode_Points         = $00 ; Vertex_Array_Primitives: Primitives Mode = Points
Mode_Lines          = $01 ; Vertex_Array_Primitives: Primitives Mode = Lines
Mode_Line_Loop      = $02 ; Vertex_Array_Primitives: Primitives Mode = Line Loop
Mode_Line_Strip     = $03 ; Vertex_Array_Primitives: Primitives Mode = Line Strip
Mode_Triangles      = $04 ; Vertex_Array_Primitives: Primitives Mode = Triangles
Mode_Triangle_Strip = $05 ; Vertex_Array_Primitives: Primitives Mode = Triangle Strip
Mode_Triangle_Fan   = $06 ; Vertex_Array_Primitives: Primitives Mode = Triangle Fan
Vertices_Length    = $FFFFFFFF ; Vertex_Array_Primitives: Length (Number Of Vertices)
First_Vertex_Index = $FFFFFFFF ; Vertex_Array_Primitives: Index Of First Vertex
macro Vertex_Array_Primitives data, length, index { ; Control ID Code: Vertex Array Primitives (OpenGL)
  db $21 ; Control ID Code Byte: ID Code #33
  db data   ; Control ID Data Record Byte: (Bit 0..7)
  dw length ; Control ID Data Record Word: Length (Number Of Vertices) (Bit 8..39)
  dw index  ; Control ID Data Record Word: Index Of First Vertex (Bit 40..71)
}

; VG_Coordinate_Array_Primitives: VG Coordinate Array Primitives (Only For Use In VG Shader Mode) Control ID Code Data Record Description
Primitives_Type_RHT            = $01 ; VG_Coordinate_Array_Primitives: Primitives Type = RHT
Primitives_Type_RHT_Strip      = $03 ; VG_Coordinate_Array_Primitives: Primitives Type = RHT Strip
Primitives_Type_Triangles      = $04 ; VG_Coordinate_Array_Primitives: Primitives Type = Triangles
Primitives_Type_Triangle_Strip = $05 ; VG_Coordinate_Array_Primitives: Primitives Type = Triangle Strip
Primitives_Type_Triangle_Fan   = $06 ; VG_Coordinate_Array_Primitives: Primitives Type = Triangle Fan
Triangle_Fan_Continuation_List = $F0 ; VG_Coordinate_Array_Primitives: Continuation List (For Triangle Fans Only)
Primitives_Length        = $FFFFFFFF ; VG_Coordinate_Array_Primitives: Length (Number Of Primitives)
Coordinate_Array_Address = $FFFFFFFF ; VG_Coordinate_Array_Primitives: Address Of Coordinate Array (32-Bit X,Y Screen Coordinates) 
macro VG_Coordinate_Array_Primitives data, length, address { ; Control ID Code: VG Coordinate Array Primitives (Only For Use In VG Shader Mode)
  db $29 ; Control ID Code Byte: ID Code #41
  db data    ; Control ID Data Record Byte: (Bit 0..7)
  dw length  ; Control ID Data Record Word: Length (Number Of Primitives) (Bit 8..39)
  dw address ; Control ID Data Record Word: Address Of Coordinate Array (Bit 40..71)
}

; VG_Inline_Primitives: VG Inline Primitives (Only For Use In VG Shader Mode) Control ID Code Data Record Description
Primitives_Type_RHT            = $01 ; VG_Inline_Primitives: Primitives Type = RHT
Primitives_Type_RHT_Strip      = $03 ; VG_Inline_Primitives: Primitives Type = RHT Strip
Primitives_Type_Triangles      = $04 ; VG_Inline_Primitives: Primitives Type = Triangles
Primitives_Type_Triangle_Strip = $05 ; VG_Inline_Primitives: Primitives Type = Triangle Strip
Primitives_Type_Triangle_Fan   = $06 ; VG_Inline_Primitives: Primitives Type = Triangle Fan
Triangle_Fan_Continuation_List = $F0 ; VG_Inline_Primitives: Continuation List (For Triangle Fans Only)
Escape_Terminated_Coordinate_List = $FFFFFFFF ; VG_Inline_Primitives: Escape Terminated Uncompressed 32-Bit X,Y Coordinate List
macro VG_Inline_Primitives data { ; Control ID Code: VG Inline Primitives (Only For Use In VG Shader Mode)
  db $2A ; Control ID Code Byte: ID Code #42
  db data ; Control ID Data Record Byte: (Bit 0..7)
  ; Control ID Data Record Words: Escape Terminated Uncompressed 32-Bit X,Y Coordinate List (Bit 8..X)
}

; Compressed_Primitive_List: Compressed Primitive List Control ID Code Data Record Description
Compressed_Primitive_List_Compressed_List = $FF ; Compressed Primitive List: Escape Terminated Compressed List
macro Compressed_Primitive_List { ; Control ID Code: Compressed Primitive List (R)
  db $30 ; Control ID Code Byte: ID Code #48
  ; Control ID Data Record Bytes: Escape Terminated List (Bit 0..X)
}

; Clipped_Primitive_With_Compressed_Primitive_List: Clipped Primitive With Compressed Primitive List Control ID Code Data Record Description
Flag_Per_Vertex_1 = $00000001 ; Clipped Primitive With Compressed Primitive List: 1 Flag Per Vertex Of Next Primitive = 1 (To Indicate If This Vertex Is To Be Clipped)
Flag_Per_Vertex_2 = $00000002 ; Clipped Primitive With Compressed Primitive List: 1 Flag Per Vertex Of Next Primitive = 2 (To Indicate If This Vertex Is To Be Clipped)
Flag_Per_Vertex_3 = $00000004 ; Clipped Primitive With Compressed Primitive List: 1 Flag Per Vertex Of Next Primitive = 3 (To Indicate If This Vertex Is To Be Clipped)
Single_Clipped_Primitive_Data_Address = $FFFFFFF8 ; Clipped Primitive With Compressed Primitive List: Address Of Single Clipped Primitive Data (Multiple Of 8 Bytes)
Escape_Terminated_Compressed_List = $FF ; Clipped Primitive With Compressed Primitive List: Escape Terminated Compressed List
macro Clipped_Primitive_With_Compressed_Primitive_List data, address { ; Control ID Code: Clipped Primitive With Compressed Primitive List (R)
  db $31 ; Control ID Code Byte: ID Code #49
  dw address + data ; Control ID Data Record Word: Address Of Single Clipped Primitive Data (Multiple Of 8 Bytes) (Bit 3..31), 1 Flag Per Vertex Of Next Primitive (Bit 0..2)
  ; Control ID Data Record Bytes: Escape Terminated List (Bit 32..X)
}

; Primitive_List_Format: Primitive List Format Control ID Code Data Record Description
Primitive_Type_Points    = $00 ; Primitive List Format: Primitive Type = Points
Primitive_Type_Lines     = $01 ; Primitive List Format: Primitive Type = Lines
Primitive_Type_Triangles = $02 ; Primitive List Format: Primitive Type = Triangles
Primitive_Type_RHT       = $03 ; Primitive List Format: Primitive Type = RHT
Data_Type_Index_16       = $10 ; Primitive List Format: Data Type = 16-Bit Index
Data_Type_XY_32          = $30 ; Primitive List Format: Data Type = 32-Bit X/Y
macro Primitive_List_Format data { ; Control ID Code: Primitive List Format (R)
  db $38 ; Control ID Code Byte: ID Code #56
  db data ; Control ID Data Record Byte: (Bit 0..7)
}

;;;;;;;;;;;;;
; State Data
;;;;;;;;;;;;;
; GL_Shader_State: GL Shader State Control ID Code Data Record Description
Attribute_Arrays_0 = $00000000 ; GL_Shader_State: Number Of Attribute Arrays = 0 (0 => All 8 Arrays) (Ignored For Extended Shader Record)
Attribute_Arrays_1 = $00000001 ; GL_Shader_State: Number Of Attribute Arrays = 1 (Ignored For Extended Shader Record)
Attribute_Arrays_2 = $00000002 ; GL_Shader_State: Number Of Attribute Arrays = 2 (Ignored For Extended Shader Record)
Attribute_Arrays_3 = $00000003 ; GL_Shader_State: Number Of Attribute Arrays = 3 (Ignored For Extended Shader Record)
Attribute_Arrays_4 = $00000004 ; GL_Shader_State: Number Of Attribute Arrays = 4 (Ignored For Extended Shader Record)
Attribute_Arrays_5 = $00000005 ; GL_Shader_State: Number Of Attribute Arrays = 5 (Ignored For Extended Shader Record)
Attribute_Arrays_6 = $00000006 ; GL_Shader_State: Number Of Attribute Arrays = 6 (Ignored For Extended Shader Record)
Attribute_Arrays_7 = $00000007 ; GL_Shader_State: Number Of Attribute Arrays = 7 (Ignored For Extended Shader Record)
Extended_Shader_Record = $00000008 ; GL_Shader_State: Extended Shader Record (With 26-Bit Attribute Memory Stride)
Memory_Base_Address = $FFFFFFF0 ; GL_Shader_State: Memory Base Address Of Shader Record (In Multiples Of 16 Bytes)
macro GL_Shader_State data, address { ; Control ID Code: GL Shader State
  db $40 ; Control ID Code Byte: ID Code #64
  dw address + data ; Control ID Data Record Word: Memory Address Of Shader Record (In Multiples Of 16 Bytes) (Bit 4..31), Data Record (Bit 0..3)
}

; NV_Shader_State: NV Shader State (No Vertex Shading) Control ID Code Data Record Description
Memory_Base_Address = $FFFFFFF0 ; NV_Shader_State: Memory Base Address Of Shader Record (16-Byte Aligned)
macro NV_Shader_State address { ; Control ID Code: NV Shader State (No Vertex Shading)
  db $41 ; Control ID Code Byte: ID Code #65
  dw address ; Control ID Data Record Word: Memory Address Of Shader Record (16-Byte Aligned) (Bit 0..31)
}

; VG_Shader_State: VG Shader State Control ID Code Data Record Description
Memory_Base_Address = $FFFFFFF0 ; VG_Shader_State: Memory Address Of Shader Record (16-Byte Aligned)
macro VG_Shader_State address { ; Control ID Code: VG Shader State
  db $42 ; Control ID Code Byte: ID Code #66
  dw address ; Control ID Data Record Word: Memory Address Of Shader Record (16-Byte Aligned) (Bit 0..31)
}

; VG_Inline_Shader_Record: VG Inline Shader Record Control ID Code Data Record Description
Dual_Threaded_Fragment_Shader    = $00000000 ; VG_Inline_Shader_Record: Dual Threaded Fragment Shader
Single_Threaded_Fragment_Shader  = $00000001 ; VG_Inline_Shader_Record: Single Threaded Fragment Shader
Fragment_Shader_Code_Address     = $FFFFFFF8 ; VG_Inline_Shader_Record: Fragment Shader Code Address (8-Byte Multiple)
Fragment_Shader_Uniforms_Address = $FFFFFFFF ; VG_Inline_Shader_Record: Fragment Shader Uniforms Address (4-Byte Aligned)
macro VG_Inline_Shader_Record data, addressc, addressu { ; Control ID Code: VG Inline Shader Record
  db $43 ; Control ID Code Byte: ID Code #67
  dw addressc + data ; Control ID Data Record Word: Fragment Shader Code Address (8-Byte Multiple) (Bit 3..31), Data Record (Bit 0..2)
  dw addressu ; Control ID Data Record Word: Fragment Shader Uniforms Address (4-Byte Aligned) (Bit 32..63)
}

;;;;;;;;;;;;;;;;;;;;;
; Configuration Data
;;;;;;;;;;;;;;;;;;;;;
; Configuration_Bits: Configuration Bits Control ID Code Data Record Description
Enable_Forward_Facing_Primitive = $01 ; Configuration_Bits: Enable Forward Facing Primitive
Enable_Reverse_Facing_Primitive = $02 ; Configuration_Bits: Enable Reverse Facing Primitive
Clockwise_Primitives            = $04 ; Configuration_Bits: Clockwise Primitives
Enable_Depth_Offset             = $08 ; Configuration_Bits: Enable Depth Offset
Antialiased_Points_Lines        = $10 ; Configuration_Bits: Antialiased Points & Lines (Not Actually Supported)
Coverage_Read_Type_Level_4_8    = $00 ; Configuration_Bits: Coverage Read Type = 4*8-Bit Level
Coverage_Read_Type_Mask_16      = $20 ; Configuration_Bits: Coverage Read Type = 16-Bit Mask
Rasteriser_Oversample_Mode_None = $00 ; Configuration_Bits: Rasteriser Oversample Mode = None
Rasteriser_Oversample_Mode_4X   = $40 ; Configuration_Bits: Rasteriser Oversample Mode = 4X
Rasteriser_Oversample_Mode_16X  = $80 ; Configuration_Bits: Rasteriser Oversample Mode = 16X
Coverage_Pipe_Select          = $0001 ; Configuration_Bits: Coverage Pipe Select
Coverage_Update_Mode_Non_Zero = $0000 ; Configuration_Bits: Coverage Update Mode = Non Zero
Coverage_Update_Mode_Odd      = $0002 ; Configuration_Bits: Coverage Update Mode = Odd
Coverage_Update_Mode_OR       = $0004 ; Configuration_Bits: Coverage Update Mode = OR
Coverage_Update_Mode_Zero     = $0006 ; Configuration_Bits: Coverage Update Mode = Zero
Coverage_Read_Mode_Clear_On_Read = $0000 ; Configuration_Bits: Coverage Read Mode = Clear On Read
Coverage_Read_Mode_Leave_On_Read = $0008 ; Configuration_Bits: Coverage Read Mode = Leave On Read
Depth_Test_Function_Never  = $0000 ; Configuration_Bits: Depth-Test Function = Never
Depth_Test_Function_LT     = $0010 ; Configuration_Bits: Depth-Test Function = Less Than (LT)
Depth_Test_Function_EQ     = $0020 ; Configuration_Bits: Depth-Test Function = Equal (EQ)
Depth_Test_Function_LE     = $0030 ; Configuration_Bits: Depth-Test Function = Less Equal (LE)
Depth_Test_Function_GT     = $0040 ; Configuration_Bits: Depth-Test Function = Greater Than (GT)
Depth_Test_Function_NE     = $0050 ; Configuration_Bits: Depth-Test Function = Not Equal (NE)
Depth_Test_Function_GE     = $0060 ; Configuration_Bits: Depth-Test Function = Greater Equal (GE)
Depth_Test_Function_Always = $0070 ; Configuration_Bits: Depth-Test Function = Always
Z_Updates_Enable       = $0080 ; Configuration_Bits: Z Updates Enable
Early_Z_Enable         = $0100 ; Configuration_Bits: Early Z Enable
Early_Z_Updates_Enable = $0200 ; Configuration_Bits: Early Z Updates Enable
macro Configuration_Bits data8, data16 { ; Control ID Code: Configuration Bits
  db $60 ; Control ID Code Byte: ID Code #96
  db data8  ; Control ID Data Record Byte: (Bit 0..7)
  dh data16 ; Control ID Data Record Short: (Bit 8..23)
}

; Flat_Shade_Flags: Flat Shade Flags Control ID Code Data Record Description
Flat_Shade_Flags = $FFFFFFFF ; Flat_Shade_Flags: Flat-Shading Flags (32 X 1-Bit)
macro Flat_Shade_Flags flags { ; Control ID Code: Flat Shade Flags
  db $61 ; Control ID Code Byte: ID Code #97
  dw flags ; Control ID Data Record Word: Flat-Shading Flags (32 x 1-Bit) (Bit 0..31)
}

; Point_Size: Points Size Control ID Code Data Record Description
Points_Size = $FFFFFFFF ; Points_Size: Point Size (FLOAT32)
macro Point_Size size { ; Control ID Code: Points Size
  db $62 ; Control ID Code Byte: ID Code #98
  dw size ; Control ID Data Record Word: Point Size (FLOAT32) (Bit 0..31)
}

; Line_Width: Line Width Control ID Code Data Record Description
Line_Width = $FFFFFFFF ; Line_Width: Line Width (FLOAT32)
macro Line_Width width { ; Control ID Code: Line Width
  db $63 ; Control ID Code Byte: ID Code #99
  dw width ; Control ID Data Record Word: Line Width (FLOAT32) (Bit 0..31)
}

; RHT_X_Boundary: RHT X Boundary Control ID Code Data Record Description
RHT_Primitive_X_Boundary = $FFFF ; RHT_X_Boundary: RHT Primitive X Boundary (SINT16)
macro RHT_X_Boundary boundary { ; Control ID Code: RHT X Boundary 
  db $64 ; Control ID Code Byte: ID Code #100
  dh boundary ; Control ID Data Record Short: RHT Primitive X Boundary (SINT16) (Bit 0..15)
}

; Depth_Offset: Depth Offset Control ID Code Data Record Description
Depth_Offset_Factor = $FFFF ; Depth_Offset: Depth Offset Factor (FLOAT1-8-7)
Depth_Offset_Units  = $FFFF ; Depth_Offset: Depth Offset Units (FLOAT1-8-7)
macro Depth_Offset factor, units { ; Control ID Code: Depth Offset
  db $65 ; Control ID Code Byte: ID Code #101
  dh factor ; Control ID Data Record Short: Depth Offset Factor (FLOAT1-8-7) (Bit 0..15)
  dh units  ; Control ID Data Record Short: Depth Offset Units (FLOAT1-8-7) (Bit 16..31)
}

; Clip_Window: Clip Window Control ID Code Data Record Description
Clip_Window_Left   = $FFFF ; Clip_Window: Clip Window Left Pixel Coordinate (UINT16)
Clip_Window_Bottom = $FFFF ; Clip_Window: Clip Window Bottom Pixel Coordinate (UINT16)
Clip_Window_Width  = $FFFF ; Clip_Window: Clip Window Width In Pixels (UINT16)
Clip_Window_Height = $FFFF ; Clip_Window: Clip Window Height In Pixels (UINT16)
macro Clip_Window left, bottom, width, height { ; Control ID Code: Clip Window
  db $66 ; Control ID Code Byte: ID Code #102
  dh left   ; Control ID Data Record Short: Clip Window Left Pixel Coordinate (UINT16) (Bit 0..15)
  dh bottom ; Control ID Data Record Short: Clip Window Bottom Pixel Coordinate (UINT16) (Bit 16..31)
  dh width  ; Control ID Data Record Short: Clip Window Width In Pixels (UINT16) (Bit 32..47)
  dh height ; Control ID Data Record Short: Clip Window Height In Pixels (UINT16) (Bit 48..63)
}

; Viewport_Offset: Viewport Offset Control ID Code Data Record Description
Viewport_Centre_X = $FFFF ; Viewport_Offset: Viewport Centre X-Coordinate (SINT16)
Viewport_Centre_Y = $FFFF ; Viewport_Offset: Viewport Centre Y-Coordinate (SINT16)
macro Viewport_Offset x, y { ; Control ID Code: Viewport Offset
  db $67 ; Control ID Code Byte: ID Code #103
  dh x ; Control ID Data Record Short: Viewport Centre X-Coordinate (SINT16) (Bit 0..15)
  dh y ; Control ID Data Record Short: Viewport Centre Y-Coordinate (SINT16) (Bit 16..31)
}

; Z_Min_Max_Clipping_Planes: Z Min & Max Clipping Planes Control ID Code Data Record Description
Minimum_ZW = $FFFFFFFF ; Z_Min_Max_Clipping_Planes: Minimum ZW (FLOAT32)
Maximum_ZW = $FFFFFFFF ; Z_Min_Max_Clipping_Planes: Maximum ZW (FLOAT32)
macro Z_Min_Max_Clipping_Planes min, max { ; Control ID Code: Z Min & Max Clipping Planes
  db $68 ; Control ID Code Byte: ID Code #104
  dw min ; Control ID Data Record Word: Minimum ZW (FLOAT32) (Bit 0..31)
  dw max ; Control ID Data Record Word: Maximum ZW (FLOAT32) (Bit 32..63)
}

; Clipper_XY_Scaling: Clipper XY Scaling Control ID Code Data Record Description
Viewport_Half_Width  = $FFFFFFFF ; Clipper_XY_Scaling: Viewport Half-Width In 1/16th Of Pixel (FLOAT32)
Viewport_Half_Height = $FFFFFFFF ; Clipper_XY_Scaling: Viewport Half-Height In 1/16th Of pixel (FLOAT32)
macro Clipper_XY_Scaling width, height { ; Control ID Code: Clipper XY Scaling (B)
  db $69 ; Control ID Code Byte: ID Code #105
  dw width  ; Control ID Data Record Word: Viewport Half-Width In 1/16th Of Pixel (FLOAT32) (Bit 0..31)
  dw height ; Control ID Data Record Word: Viewport Half-Height In 1/16th Of pixel (FLOAT32) (Bit 32..63)
}

; Clipper_Z_Scale_Offset: Clipper Z Scale & Offset Control ID Code Data Record Description
Viewport_Z_Scale  = $FFFFFFFF ; Clipper_Z_Scale_Offset: Viewport Z Scale (ZC To ZS) (FLOAT32)
Viewport_Z_Offset = $FFFFFFFF ; Clipper_Z_Scale_Offset: Viewport Z Offset (ZC To ZS) (FLOAT32)
macro Clipper_Z_Scale_Offset scale, offset { ; Control ID Code: Clipper Z Scale & Offset (B)
  db $6A ; Control ID Code Byte: ID Code #106
  dw scale  ; Control ID Data Record Word: Viewport Z Scale (ZC To ZS) (FLOAT32) (Bit 0..31)
  dw offset ; Control ID Data Record Word: Viewport Z Offset (ZC To ZS) (FLOAT32) (Bit 32..63)
}

; Tile_Binning_Mode_Configuration: Tile Binning Mode Configuration Control ID Code Data Record Description
Tile_Allocation_Memory_Address     = $FFFFFFFF ; Tile_Binning_Mode_Configuration: Tile Allocation Memory Address
Tile_Allocation_Memory_Size        = $FFFFFFFF ; Tile_Binning_Mode_Configuration: Tile Allocation Memory Size (Bytes)
Tile_State_Data_Array_Base_Address = $FFFFFFFF ; Tile_Binning_Mode_Configuration: Tile State Data Array Base Address (16-Byte Aligned, Size Of 48 Bytes * Num Tiles)
Width_In_Tiles  = $FF ; Tile_Binning_Mode_Configuration: Width (In Tiles)
Height_In_Tiles = $FF ; Tile_Binning_Mode_Configuration: Height (In Tiles)
Multisample_Mode_4X   = $01 ; Tile_Binning_Mode_Configuration: Multisample Mode (4X)
Buffer_Color_Depth_64 = $02 ; Tile_Binning_Mode_Configuration: Tile Buffer 64-Bit Color Depth
Auto_Initialise_Tile_State_Data_Array  = $04 ; Tile_Binning_Mode_Configuration: Auto-Initialise Tile State Data Array
Tile_Allocation_Initial_Block_Size_32  = $00 ; Tile_Binning_Mode_Configuration: Tile Allocation Initial Block Size = 32 Bytes
Tile_Allocation_Initial_Block_Size_64  = $08 ; Tile_Binning_Mode_Configuration: Tile Allocation Initial Block Size = 64 Bytes
Tile_Allocation_Initial_Block_Size_128 = $10 ; Tile_Binning_Mode_Configuration: Tile Allocation Initial Block Size = 128 Bytes
Tile_Allocation_Initial_Block_Size_256 = $18 ; Tile_Binning_Mode_Configuration: Tile Allocation Initial Block Size = 256 Bytes
Tile_Allocation_Block_Size_32          = $00 ; Tile_Binning_Mode_Configuration: Tile Allocation Block Size = 32 Bytes
Tile_Allocation_Block_Size_64          = $20 ; Tile_Binning_Mode_Configuration: Tile Allocation Block Size = 64 Bytes
Tile_Allocation_Block_Size_128         = $40 ; Tile_Binning_Mode_Configuration: Tile Allocation Block Size = 128 Bytes
Tile_Allocation_Block_Size_256         = $60 ; Tile_Binning_Mode_Configuration: Tile Allocation Block Size = 256 Bytes
Double_Buffer_In_Non_MS_Mode           = $80 ; Tile_Binning_Mode_Configuration: Double-Buffer In Non-MS Mode
macro Tile_Binning_Mode_Configuration address, size, baseaddress, width, height, data { ; Control ID Code: Tile Binning Mode Configuration (B)
  db $70 ; Control ID Code Byte: ID Code #112
  dw address     ; Control ID Data Record Word: Tile Allocation Memory Address (Bit 0..31)
  dw size        ; Control ID Data Record Word: Tile Allocation Memory Size (Bytes) (Bit 32..63)
  dw baseaddress ; Control ID Data Record Word: Tile State Data Array Base Address (16-Byte Aligned, Size Of 48 Bytes * Num Tiles) (Bit 64..95)
  db width       ; Control ID Data Record Byte: Width (In Tiles) (Bit 96..103)
  db height      ; Control ID Data Record Byte: Height (In Tiles) (Bit 104..111)
  db data        ; Control ID Data Record Byte: Data Record (Bit 112..119)
}

; Tile_Rendering_Mode_Configuration: Tile Rendering Mode Configuration Control ID Code Data Record Description
Tile_Rendering_Memory_Address = $FFFFFFFF ; Tile_Rendering_Mode_Configuration: Memory Address
Tile_Rendering_Width  = $FFFF ; Tile_Rendering_Mode_Configuration: Width (Pixels) (UINT16)
Tile_Rendering_Height = $FFFF ; Tile_Rendering_Mode_Configuration: Height (Pixels) (UINT16)
Multisample_Mode_4X   = $0001 ; Tile_Rendering_Mode_Configuration: Multisample Mode (4X)
Buffer_Color_Depth_64 = $0002 ; Tile_Rendering_Mode_Configuration: Tile Buffer 64-Bit Color Depth (HDR Mode)
Frame_Buffer_Color_Format_BGR565_Dithered  = $0000 ; Tile_Rendering_Mode_Configuration: Non-HDR Frame Buffer Color Format = BGR565 Dithered
Frame_Buffer_Color_Format_RGBA8888         = $0004 ; Tile_Rendering_Mode_Configuration: Non-HDR Frame Buffer Color Format = RGBA8888
Frame_Buffer_Color_Format_BGR565_No_Dither = $0008 ; Tile_Rendering_Mode_Configuration: Non-HDR Frame Buffer Color Format = BGR565 No Dither
Decimate_Mode_1X  = $0000 ; Tile_Rendering_Mode_Configuration: Decimate Mode = 1X
Decimate_Mode_4X  = $0010 ; Tile_Rendering_Mode_Configuration: Decimate Mode = 4X
Decimate_Mode_16X = $0020 ; Tile_Rendering_Mode_Configuration: Decimate Mode = 16X
Memory_Format_Linear    = $0000 ; Tile_Rendering_Mode_Configuration: Memory Format = Linear
Memory_Format_T_Format  = $0040 ; Tile_Rendering_Mode_Configuration: Memory Format = T-Format
Memory_Format_LT_Format = $0080 ; Tile_Rendering_Mode_Configuration: Memory Format = LT-Format
Enable_VG_Mask_Buffer = $0100 ; Tile_Rendering_Mode_Configuration: Enable VG Mask Buffer
Select_Coverage_Mode  = $0200 ; Tile_Rendering_Mode_Configuration: Select Coverage Mode
Early_Z_Update_Direction_LT_LE = $0000 ; Tile_Rendering_Mode_Configuration: Early-Z Update Direction = LT/LE
Early_Z_Update_Direction_GT_GE = $0400 ; Tile_Rendering_Mode_Configuration: Early-Z Update Direction = GT/GE
Early_Z_Early_Cov_Disable    = $0800 ; Tile_Rendering_Mode_Configuration: Early-Z/Early-Cov Disable
Double_Buffer_In_Non_MS_Mode = $1000 ; Tile_Rendering_Mode_Configuration: Double-Buffer In Non-MS Mode
macro Tile_Rendering_Mode_Configuration address, width, height, data { ; Control ID Code: Tile Rendering Mode Configuration (R)
  db $71 ; Control ID Code Byte: ID Code #113
  dw address ; Control ID Data Record Word: Memory Address (Bit 0..31)
  dh width   ; Control ID Data Record Short: Width (Pixels) (UINT16) (Bit 32..47)
  dh height  ; Control ID Data Record Short: Height (Pixels) (UINT16) (Bit 48..63)
  dh data    ; Control ID Data Record Short: Data Record (Bit 64..79)
}

; Clear_Colors: Clear Colors Control ID Code Data Record Description
Clear_Color = $FFFFFFFFFFFFFFFF ; Clear_Colors: Clear Color (2X RGBA8888 Or RGBA16161616)
Clear_ZS      = $00FFFFFF ; Clear_Colors: Clear ZS (UINT24)
Clear_VG_Mask = $FF000000 ; Clear_Colors: Clear VG Mask (UINT8)
Clear_Stencil = $FF ; Clear_Colors: Clear Stencil (UINT8)
macro Clear_Colors clearcolor, clearzs, clearvgmask, clearstencil { ; Control ID Code: Clear Colors (R)
  db $72 ; Control ID Code Byte: ID Code #114
  dd clearcolor                         ; Control ID Data Record Double: Clear Color (2X RGBA8888 Or RGBA16161616) (Bit 0..63)
  dw (clearvgmask * $1000000) + clearzs ; Control ID Data Record Word: Clear VG Mask (UINT8) (Bit 80..95), Clear ZS (UINT24) (Bit 64..79)
  db clearstencil                       ; Control ID Data Record Byte: Clear Stencil (UINT8) (Bit 96..103)
}

; Tile_Coordinates: Tile Coordinates Control ID Code Data Record Description
Tile_Column_Number = $FF ; Tile_Coordinates: Tile Column Number (INT8)
Tile_Row_Number    = $FF ; Tile_Coordinates: Tile Row Number (INT8)
macro Tile_Coordinates column, row { ; Control ID Code: Tile Coordinates (R)
  db $73 ; Control ID Code Byte: ID Code #115
  db column ; Control ID Data Record Byte: Tile Column Number (INT8) (Bit 0..7)
  db row    ; Control ID Data Record Byte: Tile Row Number (INT8) (Bit 8..15)
}