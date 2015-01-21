; Raspberry Pi VideoCoreIV
;;;;;;;;;;;;;;;;;;;;;;;;;;;
; V3D Register Address Map
;;;;;;;;;;;;;;;;;;;;;;;;;;;
V3D_BASE  =  $C00000 ; V3D Base Address ($20C00000 PHYSICAL, $7EC00000 BUS)
V3D_IDENT0  = $00000 ; V3D Identification 0 (V3D Block Identity)
V3D_IDENT1  = $00004 ; V3D Identification 1 (V3D Configuration A)
V3D_IDENT2  = $00008 ; V3D Identification 2 (V3D Configuration B)
V3D_IDENT3  = $0000C ; V3D Identification 3 (V3D Configuration C)
V3D_SCRATCH = $00010 ; V3D Scratch Register
V3D_L2CACTL = $00020 ; V3D L2 Cache Control
V3D_SLCACTL = $00024 ; V3D Slices Cache Control
V3D_INTCTL  = $00030 ; V3D Interrupt Control
V3D_INTENA  = $00034 ; V3D Interrupt Enables
V3D_INTDIS  = $00038 ; V3D Interrupt Disables
V3D_CT0CS   = $00100 ; V3D Control List Executor Thread 0 Control & Status
V3D_CT1CS   = $00104 ; V3D Control List Executor Thread 1 Control & Status
V3D_CT0EA   = $00108 ; V3D Control List Executor Thread 0 End Address
V3D_CT1EA   = $0010C ; V3D Control List Executor Thread 1 End Address
V3D_CT0CA   = $00110 ; V3D Control List Executor Thread 0 Current Address
V3D_CT1CA   = $00114 ; V3D Control List Executor Thread 1 Current Address
V3D_CT0RA0  = $00118 ; V3D Control List Executor Thread 0 Return Address
V3D_CT1RA0  = $0011C ; V3D Control List Executor Thread 1 Return Address
V3D_CT0LC   = $00120 ; V3D Control List Executor Thread 0 List Counter
V3D_CT1LC   = $00124 ; V3D Control List Executor Thread 1 List Counter
V3D_CT0PC   = $00128 ; V3D Control List Executor Thread 0 Primitive List Counter
V3D_CT1PC   = $0012C ; V3D Control List Executor Thread 1 Primitive List Counter
V3D_PCS     = $00130 ; V3D Pipeline Control & Status
V3D_BFC     = $00134 ; V3D Binning Mode Flush Count
V3D_RFC     = $00138 ; V3D Rendering Mode Frame Count
V3D_BPCA    = $00300 ; V3D Current Address Of Binning Memory Pool
V3D_BPCS    = $00304 ; V3D Remaining Size Of Binning Memory Pool
V3D_BPOA    = $00308 ; V3D Address Of Overspill Binning Memory Block
V3D_BPOS    = $0030C ; V3D Size Of Overspill Binning Memory Block
V3D_BXCF    = $00310 ; V3D Binner Debug
V3D_SQRSV0  = $00410 ; V3D Reserve QPUs 0-7
V3D_SQRSV1  = $00414 ; V3D Reserve QPUs 8-15
V3D_SQCNTL  = $00418 ; V3D QPU Scheduler Control
V3D_SQCSTAT = $0041C ; V3D QPU Scheduler State
V3D_SRQPC   = $00430 ; V3D QPU User Program Request Program Address
V3D_SRQUA   = $00434 ; V3D QPU User Program Request Uniforms Address
V3D_SRQUL   = $00438 ; V3D QPU User Program Request Uniforms Length
V3D_SRQCS   = $0043C ; V3D QPU User Program Request Control & Status
V3D_VPACNTL = $00500 ; V3D VPM Allocator Control
V3D_VPMBASE = $00504 ; V3D VPM Base (User) Memory Reservation
V3D_PCTRC   = $00670 ; V3D Performance Counter Clear
V3D_PCTRE   = $00674 ; V3D Performance Counter Enables
V3D_PCTR0   = $00680 ; V3D Performance Counter Count 0
V3D_PCTRS0  = $00684 ; V3D Performance Counter Mapping 0
V3D_PCTR1   = $00688 ; V3D Performance Counter Count 1
V3D_PCTRS1  = $0068C ; V3D Performance Counter Mapping 1
V3D_PCTR2   = $00690 ; V3D Performance Counter Count 2
V3D_PCTRS2  = $00694 ; V3D Performance Counter Mapping 2
V3D_PCTR3   = $00698 ; V3D Performance Counter Count 3
V3D_PCTRS3  = $0069C ; V3D Performance Counter Mapping 3
V3D_PCTR4   = $006A0 ; V3D Performance Counter Count 4
V3D_PCTRS4  = $006A4 ; V3D Performance Counter Mapping 4
V3D_PCTR5   = $006A8 ; V3D Performance Counter Count 5
V3D_PCTRS5  = $006AC ; V3D Performance Counter Mapping 5
V3D_PCTR6   = $006B0 ; V3D Performance Counter Count 6
V3D_PCTRS6  = $006B4 ; V3D Performance Counter Mapping 6
V3D_PCTR7   = $006B8 ; V3D Performance Counter Count 7
V3D_PCTRS7  = $006BC ; V3D Performance Counter Mapping 7
V3D_PCTR8   = $006C0 ; V3D Performance Counter Count 8
V3D_PCTRS8  = $006C4 ; V3D Performance Counter Mapping 8
V3D_PCTR9   = $006C8 ; V3D Performance Counter Count 9
V3D_PCTRS9  = $006CC ; V3D Performance Counter Mapping 9
V3D_PCTR10  = $006D0 ; V3D Performance Counter Count 10
V3D_PCTRS10 = $006D4 ; V3D Performance Counter Mapping 10
V3D_PCTR11  = $006D8 ; V3D Performance Counter Count 11
V3D_PCTRS11 = $006DC ; V3D Performance Counter Mapping 11
V3D_PCTR12  = $006E0 ; V3D Performance Counter Count 12
V3D_PCTRS12 = $006E4 ; V3D Performance Counter Mapping 12
V3D_PCTR13  = $006E8 ; V3D Performance Counter Count 13
V3D_PCTRS13 = $006EC ; V3D Performance Counter Mapping 13
V3D_PCTR14  = $006F0 ; V3D Performance Counter Count 14
V3D_PCTRS14 = $006F4 ; V3D Performance Counter Mapping 14
V3D_PCTR15  = $006F8 ; V3D Performance Counter Count 15
V3D_PCTRS15 = $006FC ; V3D Performance Counter Mapping 15
V3D_DBCFG   = $00E00 ; V3D Configure
V3D_DBSCS   = $00E04 ; V3D S Control & Status
V3D_DBSCFG  = $00E08 ; V3D S Configure
V3D_DBSSR   = $00E0C ; V3D S SR
V3D_DBSDR0  = $00E10 ; V3D SD R0
V3D_DBSDR1  = $00E14 ; V3D SD R1
V3D_DBSDR2  = $00E18 ; V3D SD R2
V3D_DBSDR3  = $00E1C ; V3D SD R3
V3D_DBQRUN  = $00E20 ; V3D QPU Run
V3D_DBQHLT  = $00E24 ; V3D QPU Halt
V3D_DBQSTP  = $00E28 ; V3D QPU Step
V3D_DBQITE  = $00E2C ; V3D QPU Interrupt Enables
V3D_DBQITC  = $00E30 ; V3D QPU Interrupt Control
V3D_DBQGHC  = $00E34 ; V3D QPU GHC
V3D_DBQGHG  = $00E38 ; V3D QPU GHG
V3D_DBQGHH  = $00E3C ; V3D QPU GHH
V3D_DBGE    = $00F00 ; V3D PSE Error Signals
V3D_FDBGO   = $00F04 ; V3D FEP Overrun Error Signals
V3D_FDBGB   = $00F08 ; V3D FEP Interface Ready & Stall Signals, FEP Busy Signals
V3D_FDBGR   = $00F0C ; V3D FEP Internal Ready Signals
V3D_FDBGS   = $00F10 ; V3D FEP Internal Stall Input Signals
V3D_ERRSTAT = $00F20 ; V3D Miscellaneous Error Signals (VPM, VDW, VCD, VCM, L2C)

;;;;;;;;;;;;;;;;;;;;;;;;;
; V3D Identity Registers
;;;;;;;;;;;;;;;;;;;;;;;;;
; V3D_IDENT0: V3D Identification 0 (V3D Block Identity) Register Description
IDSTR = $00FFFFFF ; V3D_IDENT0: V3D ID String (Reads As "V3D") READ
TVER  = $FF000000 ; V3D_IDENT0: V3D Technology Version (Reads Technology Version = 2) READ

; V3D_IDENT1: V3D Identification 1 (V3D Configuration A) Register Description
REVR  = $0000000F ; V3D_IDENT1: V3D Revision READ
NSLC  = $000000F0 ; V3D_IDENT1: Number Of Slices READ
QUPS  = $00000F00 ; V3D_IDENT1: Number Of QPUs Per Slice READ
TUPS  = $0000F000 ; V3D_IDENT1: Number Of TMUs Per Slice READ
NSEM  = $00FF0000 ; V3D_IDENT1: Number Of Semaphores READ
HDRT  = $0F000000 ; V3D_IDENT1: HDR Support (0 = Not Supported, 1 = Supported) READ
VPMSZ = $F0000000 ; V3D_IDENT1: VPM Memory Size (Multiples Of 1K, 0 => 16K) READ

; V3D_IDENT2: V3D Identification 2 (V3D Configuration B) Register Description
VRISZ = $0000000F ; V3D_IDENT2: VRI Memory Size (0 = Half Size, 1 = Full Size) READ
TLBSZ = $000000F0 ; V3D_IDENT2: Tile Buffer Size (0 = Quarter Size, 1 = Half Size, 2 = Full Size (32x32msm)) READ
TLBDB = $00000F00 ; V3D_IDENT2: Tile Buffer Double-Buffer Mode Support (0 = Not Supported, 1 = Supported) READ

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; V3D Miscellaneous Registers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; V3D_SCRATCH: V3D Scratch Register Description
SCRATCH = $FFFFFFFF ; V3D_SCRATCH: Scratch Register (Read/Write Registers For General Purposes) READ/WRITE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; V3D Cache Control Registers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; V3D_L2CACTL: V3D L2 Cache Control Register Description
L2CENA = $00000001 ; V3D_L2CACTL: L2 Cache Enable (Reads State Of Cache Enable Bit, Write To Enable The L2 Cache) READ/WRITE
L2CDIS = $00000002 ; V3D_L2CACTL: L2 Cache Disable (Write To Disable The L2 Cache) WRITE
L2CCLR = $00000004 ; V3D_L2CACTL: L2 Cache Clear (Write To Clear The L2 Cache) WRITE

; V3D_SLCACTL: V3D Slices Cache Control Register Description
ICCS0_to_ICCS3   = $0000000F ; V3D_SLCACTL: Instruction Cache Clear Bits (Write To Clear Instruction Cache) WRITE
UCCS0_to_UCCS3   = $00000F00 ; V3D_SLCACTL: Uniforms Cache Clear Bits (Write To Clear Uniforms Cache) WRITE
T0CCS0_to_T0CCS3 = $000F0000 ; V3D_SLCACTL: TMU0 Cache Clear Bits (Write To Clear TMU0 Cache) WRITE
T1CCS0_to_T1CCS3 = $0F000000 ; V3D_SLCACTL: TMU1 Cache Clear Bits (Write To Clear TMU1 Cache) WRITE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; V3D Pipeline Interrupt Control
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; V3D_INTCTL: V3D Interrupt Control Register Description
INT_FRDONE   = $00000001 ; V3D_INTCTL: Render Mode Frame Done Interrupt Status (Set When All Tiles Of The Frame Have Been Written To Memory) READ/WRITE
INT_FLDONE   = $00000002 ; V3D_INTCTL: Binning Mode Flush Done Interrupt Status (Set When Binning Is Complete With All Tile Lists Flushed To Memory) READ/WRITE
INT_OUTOMEM  = $00000004 ; V3D_INTCTL: Binner Out Of Memory Interrupt Status (Set While The Binner Needs More Memory To Complete) READ/WRITE
INT_SPILLUSE = $00000008 ; V3D_INTCTL: Binner Used Overspill Memory Interrupt Status (Set When The Binner Starts Using The (Valid) Overspill Memory Buffer) READ/WRITE

; V3D_INTENA: V3D Interrupt Enables Register Description
EI_FRDONE   = $00000001 ; V3D_INTENA: Render Mode Frame Done Interrupt Enable (Set When The INT_FRDONE Interrupt Is Set) READ/WRITE
EI_FLDONE   = $00000002 ; V3D_INTENA: Binning Mode Flush Done Interrupt Enable (Set When The INT_FLDONE Interrupt Is Set) READ/WRITE
EI_OUTOMEM  = $00000004 ; V3D_INTENA: Binner Out Of Memory Interrupt Enable (Set When The INT_OUTOMEM Interrupt Is Set) READ/WRITE
EI_SPILLUSE = $00000008 ; V3D_INTENA: Binner Used Overspill Memory Interrupt Enable (Set When The INT_SPILLUSE Interrupt Is Set) READ/WRITE

; V3D_INTDIS: V3D Interrupt Disables Register Description
DI_FRDONE   = $00000001 ; V3D_INTDIS: Render Mode Frame Done Interrupt Disable (Set When The INT_FRDONE Interrupt Is Set) READ/WRITE
DI_FLDONE   = $00000002 ; V3D_INTDIS: Binning Mode Flush Done Interrupt Disable (Set When The INT_FLDONE Interrupt Is Set) READ/WRITE
DI_OUTOMEM  = $00000004 ; V3D_INTDIS: Binner Out Of Memory Interrupt Disable (Set When The INT_OUTOMEM Interrupt Is Set) READ/WRITE
DI_SPILLUSE = $00000008 ; V3D_INTDIS: Binner Used Overspill Memory Interrupt Disable (Set When The INT_SPILLUSE Interrupt Is Set) READ/WRITE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; V3D Control List Executor Registers (Per Thread)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; V3D_CTnCS: V3D Control List Executor Thread n Control & Status Register Description
CTMODE = $00000001 ; V3D_CTnCS: Control Thread Mode (Binning Mode Thread Only) READ
CTERR  = $00000008 ; V3D_CTnCS: Control Thread Error (Set When Stopped With An Error, Cleared On Restarting) READ
CTSUBS = $00000010 ; V3D_CTnCS: Control Thread Sub-Mode READ/WRITE
CTRUN  = $00000020 ; V3D_CTnCS: Control Thread Run READ/WRITE
CTRTSD = $00000300 ; V3D_CTnCS: Return Stack Depth (Number Of Levels Of List Nesting) READ
CTSEMA = $00007000 ; V3D_CTnCS: Counting Semaphore (Current State Of The Counting Semaphore For This Thread) READ
CTRSTA = $00008000 ; V3D_CTnCS: Reset Bit (Writing 1 Stops The Control Thread & Resets All Bits In This Register) WRITE

; V3D_CTnEA: V3D Control List Executor Thread n End Address Register Description
CTLEA = $FFFFFFFF ; V3D_CTnEA: Control List End Address (Set To The Byte Address After The Last Record In The Control List) READ/WRITE

; V3D_CTnCA: V3D Control List Executor Thread n Current Address Register Description
CTLCA = $FFFFFFFF ; V3D_CTnCA: Control List Current Address (Points To The Address Of The Current Record In The Control List) READ/WRITE

; V3D_CTnRA0: V3D Control List Executor Thread n Return Address Register Description
CTLRA = $FFFFFFFF ; V3D_CTnRA0: Control List Return Address 0 (Address On Return Address Stack) READ

; V3D_CTnLC: V3D Control List Executor Thread n List Counter Register Description
CTLSLCS = $0000FFFF ; V3D_CTnLC: Sub-list Counter (Count Of Return Commands Encountered) READ/WRITE
CTLLCM  = $FFFF0000 ; V3D_CTnLC: Major List Counter (Count Of Flush Commands Encountered) READ/WRITE

; V3D_CTnPC: V3D Control List Executor Thread n Primitive List Counter Register Description
CTLPC = $FFFFFFFF ; V3D_CTnPC: Primitive List Counter (Count Of Primitives Remaining Whilst Processing A Primitive List) READ

;;;;;;;;;;;;;;;;;;;;;;;;;
; V3D Pipeline Registers
;;;;;;;;;;;;;;;;;;;;;;;;;
; V3D_PCS: V3D Pipeline Control & Status Register Description
BMACTIVE = $00000001 ; V3D_PCS: Binning Mode Active (Set While Binning Pipeline Is In Use) READ
BMBUSY   = $00000002 ; V3D_PCS: Binning Mode Busy (Set While Any Binning Operations Are Actually In Progress) READ
RMACTIVE = $00000004 ; V3D_PCS: Rendering Mode Active (Set While Rendering Pipeline Is In Use) READ
RMBUSY   = $00000008 ; V3D_PCS: Rendering Mode Busy (Set While Any Rendering Operations Are Actually In Progress) READ
BMOOM    = $00000100 ; V3D_PCS: Binning Mode Out Of Memory (Set When PTB Runs Out Of Binning Memory While Binning) READ

; V3D_BFC: V3D Binning Mode Flush Count Register Description
BMFCT = $000000FF ; V3D_BFC: Flush Count (Count Increments In Binning Mode Once PTB Has Flushed All Tile Lists To Mem & PTB Has Finished With Tile State Data Array) READ/WRITE

; V3D_RFC: V3D Rendering Mode Frame Count Register Description
RMFCT = $000000FF ; V3D_RFC: Frame Count (Count Increments In Rendering Mode When Last Tile Store Operation Of Frame Completes, The Tile Has Fully Written Out To Mem) READ/WRITE

; V3D_BPCA: V3D Current Address Of Binning Memory Pool Register Description
BMPCA = $FFFFFFFF ; V3D_BPCA: Current Pool Address (The Address Of The Current Allocation Pointer In The Binning Memory Pool) READ

; V3D_BPCS: V3D Remaining Size Of Binning Memory Pool Register Description
BMPRS = $FFFFFFFF ; V3D_BPCS: Size Of Pool Remaining (The Number Of Bytes Remaining In The Binning Memory Pool) READ

; V3D_BPOA: V3D Address Of Overspill Binning Memory Block Register Description
BMPOA = $FFFFFFFF ; V3D_BPOA: Address Of Overspill Memory Block For Binning (Address Of Additional Mem That PTB Can Use For Binning Once Initial Pool Runs Out) READ/WRITE

; V3D_BPOS: V3D Size Of Overspill Binning Memory Block Register Description
BMPOS = $FFFFFFFF ; V3D_BPOS: Size Of Overspill Memory Block For Binning (Number Of Bytes Of Additional Mem That PTB Can Use For Binning Once Initial Pool Runs Out) READ/WRITE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; V3D QPU Scheduler Registers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; V3D_SQRSV0: V3D Reserve QPUs 0-7 Register Description
QPURSV0 = $0000000F ; V3D_SQRSV0: Reservation Settings For QPU 0 READ/WRITE
QPURSV1 = $000000F0 ; V3D_SQRSV0: Reservation Settings For QPU 1 READ/WRITE
QPURSV2 = $00000F00 ; V3D_SQRSV0: Reservation Settings For QPU 2 READ/WRITE
QPURSV3 = $0000F000 ; V3D_SQRSV0: Reservation Settings For QPU 3 READ/WRITE
QPURSV4 = $000F0000 ; V3D_SQRSV0: Reservation Settings For QPU 4 READ/WRITE
QPURSV5 = $00F00000 ; V3D_SQRSV0: Reservation Settings For QPU 5 READ/WRITE
QPURSV6 = $0F000000 ; V3D_SQRSV0: Reservation Settings For QPU 6 READ/WRITE
QPURSV7 = $F0000000 ; V3D_SQRSV0: Reservation Settings For QPU 7 READ/WRITE

; V3D_SQRSV1: V3D Reserve QPUs 8-15 Register Description
QPURSV8  = $0000000F ; V3D_SQRSV1: Reservation Settings For QPU 8 READ/WRITE
QPURSV9  = $000000F0 ; V3D_SQRSV1: Reservation Settings For QPU 9 READ/WRITE
QPURSV10 = $00000F00 ; V3D_SQRSV1: Reservation Settings For QPU 10 READ/WRITE
QPURSV11 = $0000F000 ; V3D_SQRSV1: Reservation Settings For QPU 11 READ/WRITE
QPURSV12 = $000F0000 ; V3D_SQRSV1: Reservation Settings For QPU 12 READ/WRITE
QPURSV13 = $00F00000 ; V3D_SQRSV1: Reservation Settings For QPU 13 READ/WRITE
QPURSV14 = $0F000000 ; V3D_SQRSV1: Reservation Settings For QPU 14 READ/WRITE
QPURSV15 = $F0000000 ; V3D_SQRSV1: Reservation Settings For QPU 15 READ/WRITE

; V3D_SQCNTL: V3D QPU Scheduler Control Register Description
VSRBL = $00000003 ; V3D_SQCNTL: Vertex Shader Scheduling Bypass Limit READ/WRITE
CSRBL = $0000000C ; V3D_SQCNTL: Coordinate Shader Scheduling Bypass Limit READ/WRITE

; V3D_SRQPC: V3D QPU User Program Request Program Address Register Description
QPURQPC = $FFFFFFFF ; V3D_SRQPC: Program Address (Writing This Register Queues A Request To Run A Program Starting At The Given Address) WRITE

; V3D_SRQUA: V3D QPU User Program Request Uniforms Address Register Description
QPURQUA = $FFFFFFFF ; V3D_SRQUA: Uniforms Address (Contains The Address Of The Uniforms Stream For The Next User Program To Be Queued Via A Write To V3DRQPC) READ/WRITE

; V3D_SRQUL: V3D QPU User Program Request Uniforms Length Register Description
QPURQUL = $00000FFF ; V3D_SRQUL: Uniforms Length (Contains The Max Length Of The Uniforms Stream For The Next User Program To Be Queued Via A Write To V3DRQPC) READ/WRITE

; V3D_SRQCS: V3D QPU User Program Request Control & Status Register Description
QPURQL   = $0000003F ; V3D_SRQCS: Queue Length (Contains The Number Of Program Requests Currently Queued) READ/WRITE
QPURQERR = $00000080 ; V3D_SRQCS: Queue Error (Set When A Request Has Been Made When The Queue Is Full) READ/WRITE
QPURQCM  = $0000FF00 ; V3D_SRQCS: Count Of User Program Requests Made (Contains The Total Number Of User Program Requests Made, Modulo 256) READ/WRITE
QPURQCC  = $00FF0000 ; V3D_SRQCS: Count Of User Programs Completed (Contains The Total Number Of User Programs That Have Run & Completed, Modulo 256) READ/WRITE

;;;;;;;;;;;;;;;;;;;;
; V3D VPM Registers
;;;;;;;;;;;;;;;;;;;;
; V3D_VPACNTL: V3D VPM Allocator Control Register Description
VPARALIM = $00000007 ; V3D_VPACNTL: Rendering VPM Allocation Limit (Limits The Amount Of VPM Memory Allocated To Rendering Mode) READ/WRITE
VPABALIM = $00000038 ; V3D_VPACNTL: Binning VPM Allocation Limit (Limits The Amount Of VPM Memory Allocated To Binning Mode) READ/WRITE
VPARATO  = $000001C0 ; V3D_VPACNTL: Rendering VPM Allocation Timeout (Sets A Timeout For Raising The Priority Of Rendering Mode Allocation Requests) READ/WRITE
VPABATO  = $00000E00 ; V3D_VPACNTL: Binning VPM Allocation Timeout (Sets A Timeout For Raising The Priority Of Binning Mode Allocation Requests) READ/WRITE
VPALIMEN = $00001000 ; V3D_VPACNTL: Enable VPM Allocation Limits (Enables VPM Memory Allocation Limiting Using VPARALIM & VPABALIM) READ/WRITE
VPATOEN  = $00002000 ; V3D_VPACNTL: Enable VPM Allocation Timeout (Enables VPM Memory Allocation Timeout Using VPARATO & VPABATO) READ/WRITE

; V3D_VPMBASE: V3D VPM Base (User) Memory Reservation Register Description
VPMURSV = $0000001F ; V3D_VPMBASE: VPM Memory Reserved For User Programs (Contains Amount Of VPM Mem Reserved For All User Programs, In Multiples Of 256 Bytes) READ/WRITE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; V3D QPU Interrupt Control
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; V3D_DBQITE: V3D QPU Interrupt Enables Register Description
IE_QPU0_to_IE_QPU15 = $0000FFFF ; V3D_DBQITE: QPU Interrupt Enable bits (Set Bit To Allow QPU To Generate An Interrupt) READ/WRITE

; V3D_DBQITC: V3D QPU Interrupt Control Register Description
IC_QPU0_to_IC_QPU15 = $0000FFFF ; V3D_DBQITC: QPU Interrupt Control Bits (Reads When Interrupt Is Latched, Write To Clear Interrupt) READ/WRITE

;;;;;;;;;;;;;;;;;;;;;;;;;;;
; V3D Performance Counters
;;;;;;;;;;;;;;;;;;;;;;;;;;;
; V3D Sources For Performance Counters
COUNT_ID_0  =  0 ; FEP Valid Primitives That Result In No Rendered Pixels, For All Rendered Tiles
COUNT_ID_1  =  1 ; FEP Valid Primitives For All Rendered Tiles (Primitives May Be Counted In More Than One Tile)
COUNT_ID_2  =  2 ; FEP Early-Z/Near/Far Clipped Quads
COUNT_ID_3  =  3 ; FEP Valid Quads
COUNT_ID_4  =  4 ; TLB Quads With No Pixels Passing The Stencil Test
COUNT_ID_5  =  5 ; TLB Quads With No Pixels Passing The Z & Stencil Tests
COUNT_ID_6  =  6 ; TLB Quads With Any Pixels Passing The Z & Stencil Tests
COUNT_ID_7  =  7 ; TLB Quads With All Pixels Having Zero Coverage
COUNT_ID_8  =  8 ; TLB Quads With Any Pixels Having Non-Zero Coverage
COUNT_ID_9  =  9 ; TLB Quads With Valid Pixels Written To Color Buffer
COUNT_ID_10 = 10 ; PTB Primitives Discarded By Being Outside The Viewport
COUNT_ID_11 = 11 ; PTB Primitives That Need Clipping
COUNT_ID_12 = 12 ; PSE Primitives That Are Discarded Because They Are Reversed
COUNT_ID_13 = 13 ; QPU Total Idle Clock Cycles For All QPUs
COUNT_ID_14 = 14 ; QPU Total Clock Cycles For All QPUs Doing Vertex/Coordinate Shading
COUNT_ID_15 = 15 ; QPU Total Clock Cycles For All QPUs Doing Fragment Shading
COUNT_ID_16 = 16 ; QPU Total Clock Cycles For All QPUs Executing Valid Instructions
COUNT_ID_17 = 17 ; QPU Total Clock Cycles For All QPUs Stalled Waiting For TMUs
COUNT_ID_18 = 18 ; QPU Total Clock Cycles For All QPUs Stalled Waiting For Scoreboard
COUNT_ID_19 = 19 ; QPU Total Clock Cycles For All QPUs Stalled Waiting For Varyings
COUNT_ID_20 = 20 ; QPU Total Instruction Cache Hits For All Slices
COUNT_ID_21 = 21 ; QPU Total Instruction Cache Misses For All Slices
COUNT_ID_22 = 22 ; QPU Total Uniforms Cache Hits For All Slices
COUNT_ID_23 = 23 ; QPU Total Uniforms Cache Misses For All Slices
COUNT_ID_24 = 24 ; TMU Total Texture Quads Processed
COUNT_ID_25 = 25 ; TMU Total Texture Cache Misses (Number Of Fetches From Memory/L2 Cache)
COUNT_ID_26 = 26 ; VPM Total Clock Cycles VDW Is Stalled Waiting For VPM Access
COUNT_ID_27 = 27 ; VPM Total Clock Cycles VCD Is Stalled Waiting For VPM Access
COUNT_ID_28 = 28 ; L2C Total Level 2 Cache Hits
COUNT_ID_29 = 29 ; L2C Total Level 2 Cache Misses

; V3D_PCTRC: V3D Performance Counter Clear Register Description
CTCLR0_CTCLR15 = $0000FFFF ; V3D_PCTRC: Performance Counter Clear Bits (Write To Clear The Performance Counter) WRITE

; V3D_PCTRE: V3D Performance Counter Enables Register Description
CTEN0_CTEN15 = $0000FFFF ; V3D_PCTRE: Performance Counter Enable Bits (0 = Counter Disabled, 1 = Performance Counter Enabled To Count) READ/WRITE

; V3D_PCTRn: V3D Performance Counter Count n Register Description
PCTR = $FFFFFFFF ; V3D_PCTRn: Performance Count (Count Value) READ/WRITE

; V3D_PCTRSn: V3D Performance Counter Mapping n Register Description
PCTRS = $0000001F ; V3D_PCTRSn: Performance Counter Device ID READ/WRITE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; V3D Error & Diagnostic Registers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; V3D_BXCF: V3D Binner Debug Register Description
FWDDISA  = $00000001 ; V3D_BXCF: Disable Forwarding In State Cache READ/WRITE
CLIPDISA = $00000002 ; V3D_BXCF: Disable Clipping READ/WRITE

; V3D_DBGE: V3D PSE Error Signals Register Description
VR1_A        = $00000002 ; V3D_DBGE: Error A Reading VPM READ
VR1_B        = $00000004 ; V3D_DBGE: Error B Reading VPM READ
MULIP0       = $00010000 ; V3D_DBGE: Error Mulip 0 READ
MULIP1       = $00020000 ; V3D_DBGE: Error Mulip 1 READ
MULIP2       = $00040000 ; V3D_DBGE: Error Mulip 2 READ
IPD2_VALID   = $00080000 ; V3D_DBGE: Error IPD2 Valid READ
IPD2_FPDUSED = $00100000 ; V3D_DBGE: Error IPD2 FPD Used READ

; V3D_FDBGO: V3D FEP Overrun Error Signals Register Description
WCOEFF_FIFO_FULL = $00000002 ; V3D_FDBGO: Not An Error READ
XYRELZ_FIFO_FULL = $00000004 ; V3D_FDBGO: Not An Error READ
QBFR_FIFO_ORUN   = $00000008 ; V3D_FDBGO: Error READ
QBSZ_FIFO_ORUN   = $00000010 ; V3D_FDBGO: Error READ
XYFO_FIFO_ORUN   = $00000020 ; V3D_FDBGO: Error READ
FIXZ_ORUN        = $00000040 ; V3D_FDBGO: Error READ
XYRELO_FIFO_ORUN = $00000080 ; V3D_FDBGO: Error READ
XYRELW_FIFO_ORUN = $00000400 ; V3D_FDBGO: Error READ
ZCOEFF_FIFO_FULL = $00000800 ; V3D_FDBGO: Not An Error
REFXY_FIFO_ORUN  = $00001000 ; V3D_FDBGO: Error READ
DEPTHO_FIFO_ORUN = $00002000 ; V3D_FDBGO: Error READ
DEPTHO_ORUN      = $00004000 ; V3D_FDBGO: Error READ
EZVAL_FIFO_ORUN  = $00008000 ; V3D_FDBGO: Error READ
EZREQ_FIFO_ORUN  = $00020000 ; V3D_FDBGO: Error READ

; V3D_FDBGB: V3D FEP Interface Ready & Stall Signals, FEP Busy Signals Register Description
EDGES_STALL        = $00000001 ; V3D_FDBGB: Stall READ
EDGES_READY        = $00000002 ; V3D_FDBGB: Ready READ
EDGES_ISCTRL       = $00000004 ; V3D_FDBGB: READ
EDGES_CTRLID       = $00000038 ; V3D_FDBGB: READ
ZRWPE_STALL        = $00000040 ; V3D_FDBGB: Stall READ
ZRWPE_READY        = $00000080 ; V3D_FDBGB: Ready READ
EZ_DATA_READY      = $00800000 ; V3D_FDBGB: Ready READ
EZ_XY_READY        = $02000000 ; V3D_FDBGB: Ready READ
RAST_BUSY          = $04000000 ; V3D_FDBGB: Busy READ
QXYF_FIFO_OP_READY = $08000000 ; V3D_FDBGB: Ready READ
XYFO_FIFO_OP_READY = $10000000 ; V3D_FDBGB: Ready READ

; V3D_FDBGR: V3D FEP Internal Ready Signals Register Description
QXYF_FIFO_READY   = $00000001 ; V3D_FDBGR: Ready READ
EZREQ_FIFO_READY  = $00000002 ; V3D_FDBGR: Ready READ
EZVAL_FIFO_READY  = $00000004 ; V3D_FDBGR: Ready READ
DEPTHO_FIFO_READY = $00000008 ; V3D_FDBGR: Ready READ
REFXY_FIFO_READY  = $00000010 ; V3D_FDBGR: Ready READ
ZCOEFF_FIFO_READY = $00000020 ; V3D_FDBGR: Ready READ
XYRELW_FIFO_READY = $00000040 ; V3D_FDBGR: Ready READ
WCOEFF_FIFO_READY = $00000080 ; V3D_FDBGR: Ready READ
XYRELO_FIFO_READY = $00000800 ; V3D_FDBGR: Ready READ
ZO_FIFO_READY     = $00002000 ; V3D_FDBGR: Ready READ
XYFO_FIFO_READY   = $00004000 ; V3D_FDBGR: Ready READ
RAST_READY        = $00010000 ; V3D_FDBGR: Ready READ
RAST_LAST         = $00020000 ; V3D_FDBGR: Last READ
DEPTHO_READY      = $00040000 ; V3D_FDBGR: Ready READ
EZLIM_READY       = $00080000 ; V3D_FDBGR: Ready READ
XYNRM_READY       = $00100000 ; V3D_FDBGR: Ready READ
XYNRM_LAST        = $00200000 ; V3D_FDBGR: Last READ
XYRELZ_FIFO_READY = $00400000 ; V3D_FDBGR: Ready READ
XYRELZ_FIFO_LAST  = $00800000 ; V3D_FDBGR: Last READ
INTERPZ_READY     = $01000000 ; V3D_FDBGR: Ready READ
INTERPRW_READY    = $08000000 ; V3D_FDBGR: Ready READ
RECIPW_READY      = $10000000 ; V3D_FDBGR: Ready READ
FIXZ_READY        = $40000000 ; V3D_FDBGR: Ready READ

; V3D_FDBGS: V3D FEP Internal Stall Input Signals Register Description
EZTEST_IP_QSTALL     = $00000001 ; V3D_FDBGS: Stall READ
EZTEST_IP_PRSTALL    = $00000002 ; V3D_FDBGS: Stall READ
EZTEST_IP_VLFSTALL   = $00000004 ; V3D_FDBGS: Stall READ
EZTEST_STALL         = $00000008 ; V3D_FDBGS: Stall READ
EZTEST_VLF_OKNOVALID = $00000010 ; V3D_FDBGS: Valid READ
EZTEST_QREADY        = $00000020 ; V3D_FDBGS: Ready READ
EZTEST_ANYQF         = $00000040 ; V3D_FDBGS: READ
EZTEST_ANYQVALID     = $00000080 ; V3D_FDBGS: Valid READ
QXYF_FIFO_OP1_VALID  = $00000100 ; V3D_FDBGS: Valid READ
QXYF_FIFO_OP1_LAST   = $00000200 ; V3D_FDBGR: Last READ
QXYF_FIFO_OP1_DUMMY  = $00000400 ; V3D_FDBGR: Dummy READ
QXYF_FIFO_OP_LAST    = $00000800 ; V3D_FDBGR: Last READ
QXYF_FIFO_OP_VALID   = $00001000 ; V3D_FDBGS: Valid READ
EZREQ_FIFO_OP_VALID  = $00002000 ; V3D_FDBGS: Valid READ
XYNRM_IP_STALL       = $00004000 ; V3D_FDBGS: Stall READ
EZLIM_IP_STALL       = $00008000 ; V3D_FDBGS: Stall READ
DEPTHO_FIFO_IP_STALL = $00010000 ; V3D_FDBGS: Stall READ
INTERPZ_IP_STALL     = $00020000 ; V3D_FDBGS: Stall READ
XYRELZ_FIFO_IP_STALL = $00040000 ; V3D_FDBGS: Stall READ
INTERPW_IP_STALL     = $00400000 ; V3D_FDBGS: Stall READ
RECIPW_IP_STALL      = $02000000 ; V3D_FDBGS: Stall READ
ZO_FIFO_IP_STALL     = $10000000 ; V3D_FDBGS: Stall READ

; V3D_ERRSTAT: V3D Miscellaneous Error Signals (VPM, VDW, VCD, VCM, L2C) Register Description
VPAEABB  = $00000001 ; V3D_ERRSTAT: VPM Allocator Error - Allocating Base While Busy READ
VPAERGS  = $00000002 ; V3D_ERRSTAT: VPM Allocator Error - Request Too Big READ
VPAEBRGL = $00000004 ; V3D_ERRSTAT: VPM Allocator Error - Binner Request Greater Than Limit READ
VPAERRGL = $00000008 ; V3D_ERRSTAT: VPM Allocator Error - Renderer Request Greater Than Limit READ
VPMEWR   = $00000010 ; V3D_ERRSTAT: VPM Error - Write Range READ
VPMERR   = $00000020 ; V3D_ERRSTAT: VPM Error - Read Range READ
VPMERNA  = $00000040 ; V3D_ERRSTAT: VPM Error - Read Non-Allocated READ
VPMEWNA  = $00000080 ; V3D_ERRSTAT: VPM Error - Write Non-Allocated READ
VPMEFNA  = $00000100 ; V3D_ERRSTAT: VPM Error - Free Non-Allocated READ
VPMEAS   = $00000200 ; V3D_ERRSTAT: VPM Error - Allocated Size Error READ
VDWE     = $00000400 ; V3D_ERRSTAT: VDW Error - Address Overflows READ
VCDE     = $00000800 ; V3D_ERRSTAT: VCD Error - FIFO Pointers Out Of Sync READ
VCDI     = $00001000 ; V3D_ERRSTAT: VCD Idle READ
VCMRE    = $00002000 ; V3D_ERRSTAT: VCM Error (Renderer) READ
VCMBE    = $00004000 ; V3D_ERRSTAT: VCM Error (Binner) READ
L2CARE   = $00008000 ; V3D_ERRSTAT: L2C AXI Receive Fifo Overrun Error READ