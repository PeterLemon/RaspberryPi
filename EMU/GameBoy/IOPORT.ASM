; Copy Cart Over BIOS Area When DMG Is Complete (Overwrite 256 Bytes Bios Area)
cmp r4,$100
bne NO_DMG
imm32 r5,CART_STRUCT ; Set Control Block Data Address To DMA Controller
imm32 r6,PERIPHERAL_BASE + DMA0_BASE + DMA_CONBLK_AD
str r5,[r6]
mov r5,DMA_ACTIVE ; Set Start Bit
imm32 r6,PERIPHERAL_BASE + DMA0_BASE + DMA_CS
str r5,[r6]
DMADMGWait:
  ldr r5,[r6] ; Load Control Block Status
  tst r5,DMA_ACTIVE ; Test Active Bit
  bne DMADMGWait ; Wait Until DMA Has Finished
NO_DMG:

; Instruction Cycles
ldr r5,[r9,OldQCycles - CPU_INST] ; IF (QCycles < OldQCycles) OldQCycles = 0
cmp r12,r5
movlt r5,0
sub r5,r12,r5 ; R5 = InstQCycles = QCycles - OldQCycles (Get Last Instruction Quad Cycle Count)
str r12,[r9,OldQCycles - CPU_INST] ; OldQCycles = QCycles

; LCD
imm16 r6,LCDC_REG ; IF ((LCDC_REG>>7) & 1) {
ldrb r6,[r10,r6]
tst r6,$80
beq NO_LCD

ldrb r6,[r9,LCDQCycles - CPU_INST] ; LCDQCycles += InstQCycles
add r6,r5 ; R6 = LCDQCycles
strb r6,[r9,LCDQCycles - CPU_INST]
imm16 r8,LY_REG
ldrb r7,[r10,r8] ; R7 = LY_REG
cmp r6,114 ; IF (LCDQCycles >= 114){ (Scanline Takes 456 Cycles (114 QCycles))
blt VBLANK
mov r6,0 ; LCDQCycles = 0
strb r6,[r9,LCDQCycles - CPU_INST]
add r7,1 ; LY_REG++ }
strb r7,[r10,r8]

VBLANK:
cmp r7,144 ; IF (LY_REG == 144) IF_REG |= 1 (VBlank Interrupt Flag Set When LY_REG Reaches 144)
bne NO_VBLANK
imm16 r8,IF_REG
ldrb r7,[r10,r8]
orr r7,1
strb r7,[r10,r8]
b END_LY

NO_VBLANK:
cmp r7,153 ; ELSE IF (LY_REG > 153) LY_REG = 0 (Reset LY_REG When Above 153)
ble END_LY
mov r7,0
strb r7,[r10,r8]

END_LY:

imm16 r8,STAT_REG ; OldMode = STAT_REG & 3
ldrb r7,[r10,r8] ; R7 = STAT_REG
and r8,r7,3
strb r8,[r9,OldMode - CPU_INST]

imm16 r8,LY_REG ; IF (LY_REG >= 144) { (Mode 1)
ldrb r8,[r10,r8]
cmp r8,144
blt LCD_MODE_2
orr r7,1 ; STAT_REG |= 1 (Set Status Bit 0)
bic r7,2 ; STAT_REG &= $FD (Reset Status Bit 1)
imm16 r8,STAT_REG
strb r7,[r10,r8]
tst r7,$10 ; IF ((STAT_REG & $10) && (OldMode != 1)) IF_REG |= 2 } (IF Status Bit 4 & OldMode != 1 LCD STAT Interrupt Flag Set)
beq END_STAT
ldrb r8,[r9,OldMode - CPU_INST]
cmp r8,1
beq END_STAT
imm16 r8,IF_REG
ldrb r7,[r10,r8]
orr r7,2
strb r7,[r10,r8]
b END_STAT

LCD_MODE_2:
cmp r6,20 ; IF (LCDQCycles <= 20) { (Mode 2)
bgt LCD_MODE_3
orr r7,2 ; STAT_REG |= 2 (Set Status Bit 1)
bic r7,1 ; STAT_REG &= $FE (Reset Status Bit 0)
imm16 r8,STAT_REG
strb r7,[r10,r8]
tst r7,$20 ; IF ((STAT_REG & $20) && (OldMode != 2)) IF_REG |= 2 } (IF Status Bit 5 & OldMode != 2 LCD STAT Interrupt Flag Set)
beq END_STAT
ldrb r8,[r9,OldMode - CPU_INST]
cmp r8,2
beq END_STAT
imm16 r8,IF_REG
ldrb r7,[r10,r8]
orr r7,2
strb r7,[r10,r8]
b END_STAT

LCD_MODE_3:
cmp r6,63 ; ELSE IF (LCDQCycles <= 63) { (Mode 3)
bgt LCD_MODE_0
orr r7,3 ; STAT_REG |= 3 } (Set Status Bits 0 & 1)
imm16 r8,STAT_REG
strb r7,[r10,r8]
b END_STAT

LCD_MODE_0: ; ELSE { (Mode 0)
bic r7,3 ; STAT_REG &= $FC (Reset Status Bits 0 & 1)
imm16 r8,STAT_REG
strb r7,[r10,r8]
tst r7,8 ; IF ((STAT_REG & 8) && (OldMode != 0)) IF_REG |= 2 } (IF Status Bit 3 & OldMode != 0 LCD STAT Interrupt Flag Set)
beq END_STAT
ldrb r8,[r9,OldMode - CPU_INST]
cmp r8,0
beq END_STAT
imm16 r8,IF_REG
ldrb r7,[r10,r8]
orr r7,2
strb r7,[r10,r8]

END_STAT:
imm16 r7,LY_REG ; IF (LY_REG == LYC_REG) { (Check The Coincidence Flag)
ldrb r7,[r10,r7]
imm16 r8,LYC_REG
ldrb r8,[r10,r8]
cmp r7,r8
bne NO_LYCMP
imm16 r8,STAT_REG ; STAT_REG |= 4 (Set Status Bit 2)
ldrb r7,[r10,r8]
orr r7,4
strb r7,[r10,r8]
tst r7,$40 ; IF (STAT_REG & $40) IF_REG |= 2 } (IF Status Bit 6 LCD STAT Interrupt Flag Set)
beq TIMERS
imm16 r8,IF_REG
ldrb r7,[r10,r8]
orr r7,2
strb r7,[r10,r8]
b TIMERS

NO_LYCMP: ; ELSE {
imm16 r8,STAT_REG ; STAT_REG &= $FB } (Reset Status Bit 2)
ldrb r7,[r10,r8]
bic r7,4
strb r7,[r10,r8]
b TIMERS

NO_LCD: ; ELSE {
mov r6,0 ; LCDQCycles = 0 (Set The Mode To 1 During LCD Disabled & Reset Scanline)
strb r6,[r9,LCDQCycles - CPU_INST]
imm16 r7,LY_REG ; LY_REG = 0
strb r6,[r10,r7]
imm16 r8,STAT_REG ; STAT_REG |= 1 (Set Status Bit 0)
ldrb r7,[r10,r8]
orr r7,1
bic r7,2 ; STAT_REG &= 0xFD } (Reset Status Bit 1)
strb r7,[r10,r8]

; Timers
TIMERS:
ldrh r6,[r9,DIVQCycles - CPU_INST] ; DIVQCycles += InstQCycles
add r6,r5
cmp r6,256 ; IF (DIVQCycles >= 256) {
blt NO_DIV
mov r6,0 ; DIVQCycles = 0
imm16 r7,DIV_REG
ldrb r8,[r10,r7] ; DIV_REG++ }
add r8,1
strb r8,[r10,r7]
NO_DIV:
str r6,[r9,DIVQCycles - CPU_INST]

imm16 r6,TAC_REG ; IF (TAC_REG & 4) {
ldrb r6,[r10,r6]
tst r6,4
beq NO_TMR
ldr r7,[r9,OldTAC_REG - CPU_INST] ; IF (TAC_REG != OldTAC_REG) {
cmp r6,r7
beq NO_TAC
str r6,[r9,OldTAC_REG - CPU_INST] ; OldTAC_REG = TAC_REG
mov r7,4
str r7,[r9,TimerQCycles - CPU_INST] ; TimerQCycles = 0 }
NO_TAC:

TMR_4096:
  cmp r6,4 ; IF (TAC_REG == 4) { (Timer Clock Frequency = 4096 Hz)
  bne TMR_262144
  ldr r6,[r9,TimerQCycles - CPU_INST] ; TimerQCycles += InstQCycles
  add r6,r5
  imm16 r5,TIMA_REG
  ldrb r5,[r10,r5] ; R5 = TIMA_REG 
  LOOP_4096:
    cmp r6,256 ; WHILE (TimerQCycles >= 256) {
    blt TMR_END
    sub r6,256 ; TimerQCycles -= 256
    add r5,1 ; IF (++TIMA_REG == 0) {
    cmp r5,$100
    bne LOOP_4096
    imm16 r7,TMA_REG ; TIMA_REG = TMA_REG
    ldrb r5,[r10,r7]
    imm16 r7,IF_REG ; IF_REG |= 4 }}} (Interrupt Is Requested By Setting Bit 2 In The IF Register)
    ldrb r8,[r10,r7]
    orr r8,4
    strb r8,[r10,r7]
    b LOOP_4096

TMR_262144:
  cmp r6,5 ; IF (TAC_REG == 5) { (Timer Clock Frequency = 262144 Hz)
  bne TMR_65536 
  ldr r6,[r9,TimerQCycles - CPU_INST] ; TimerQCycles += InstQCycles
  add r6,r5
  imm16 r5,TIMA_REG
  ldrb r5,[r10,r5] ; R5 = TIMA_REG 
  LOOP_262144:
    cmp r6,4 ; WHILE (TimerQCycles >= 4) {
    blt TMR_END
    sub r6,4 ; TimerQCycles -= 4
    add r5,1 ; IF (++TIMA_REG == 0) {
    cmp r5,$100
    bne LOOP_262144
    imm16 r7,TMA_REG ; TIMA_REG = TMA_REG
    ldrb r5,[r10,r7]
    imm16 r7,IF_REG ; IF_REG |= 4 }}} (Interrupt Is Requested By Setting Bit 2 In The IF Register)
    ldrb r8,[r10,r7]
    orr r8,4
    strb r8,[r10,r7]
    b LOOP_262144

TMR_65536:
  cmp r6,6 ; IF (TAC_REG == 6) { (Timer Clock Frequency = 65536 Hz)
  bne TMR_16384 
  ldr r6,[r9,TimerQCycles - CPU_INST] ; TimerQCycles += InstQCycles
  add r6,r5
  imm16 r5,TIMA_REG
  ldrb r5,[r10,r5] ; R5 = TIMA_REG 
  LOOP_65536:
    cmp r6,16 ; WHILE (TimerQCycles >= 16) {
    blt TMR_END
    sub r6,16 ; TimerQCycles -= 16
    add r5,1 ; IF (++TIMA_REG == 0) {
    cmp r5,$100
    bne LOOP_65536
    imm16 r7,TMA_REG ; TIMA_REG = TMA_REG
    ldrb r5,[r10,r7]
    imm16 r7,IF_REG ; IF_REG |= 4 }}} (Interrupt Is Requested By Setting Bit 2 In The IF Register)
    ldrb r8,[r10,r7]
    orr r8,4
    strb r8,[r10,r7]
    b LOOP_65536

TMR_16384:
  cmp r6,7 ; IF (TAC_REG == 7) { (Timer Clock Frequency = 16384 Hz)
  bne NO_TMR
  ldr r6,[r9,TimerQCycles - CPU_INST] ; TimerQCycles += InstQCycles
  add r6,r5
  imm16 r5,TIMA_REG
  ldrb r5,[r10,r5] ; R5 = TIMA_REG 
  LOOP_16384:
    cmp r6,64 ; WHILE (TimerQCycles >= 64) {
    blt TMR_END
    sub r6,64 ; TimerQCycles -= 64
    add r5,1 ; IF (++TIMA_REG == 0) {
    cmp r5,$100
    bne LOOP_16384
    imm16 r7,TMA_REG ; TIMA_REG = TMA_REG
    ldrb r5,[r10,r7]
    imm16 r7,IF_REG ; IF_REG |= 4 }}} (Interrupt Is Requested By Setting Bit 2 In The IF Register)
    ldrb r8,[r10,r7]
    orr r8,4
    strb r8,[r10,r7]
    b LOOP_16384

TMR_END:
imm16 r7,TIMA_REG ; Store TIMA_REG
strb r5,[r10,r7]
str r6,[r9,TimerQCycles - CPU_INST] ; Store Timer Cycles
NO_TMR:

; Interrupts
ldrb r5,[r9,IME_FLAG - CPU_INST]
cmp r5,0	; IF (IME_FLAG) {
beq NO_INTR
imm16 r5,IF_REG   ; IF (IF_REG) {
ldrb r5,[r10,r5]
cmp r5,0
beq NO_INTR
mov r5,0	  ; i = 0
INTR_LOOP:
  cmp r5,5	  ; WHILE (i != 5) {
  beq NO_INTR
  imm16 r6,IF_REG ; IF ((IF_REG & (1 << i)) && (IE_REG & (1 << i)) )
  ldrb r6,[r10,r6]
  mov r7,1
  mov r7,r7,lsl r5
  ands r6,r7
  beq INC_INTR
  imm16 r6,IE_REG
  ldrb r6,[r10,r6]
  ands r6,r7
  beq INC_INTR

  mov r6,0	   ; IME_FLAG = 0 Disable Interrupt Master Enable Switch
  strb r6,[r9,IME_FLAG - CPU_INST]

  cmp r5,0	   ; SWITCH(i) {
  bne INTR_1	   ; CASE 0: { // Bit 0: V-Blank Interrupt Request (INT 40h)
  imm16 r6,IE_REG  ; IE_REG &= $FE CALL $0040
  ldrb r7,[r10,r6]
  and r7,$FE
  strb r7,[r10,r6]
  imm16 r6,IF_REG  ; IF_REG &= $FE
  ldrb r7,[r10,r6]
  and r7,$FE
  strb r7,[r10,r6]
  sub sp,2	   ; SP_REG -= 2
  strb r4,[r10,sp] ; STACK = PC_REG
  mov r6,r4,lsr 8
  add r7,sp,1
  strb r6,[r10,r7]
  mov r4,$40	   ; PC_REG = $0040
  add r12,6	   ; QCycles += 6
  b INC_INTR

  INTR_1:
  cmp r5,1
  bne INTR_2	   ; CASE 1: { // Bit 1: LCD STAT Interrupt Request (INT 48h)
  imm16 r6,IE_REG  ; IE_REG &= $FD CALL $0048
  ldrb r7,[r10,r6]
  and r7,$FD
  strb r7,[r10,r6]
  imm16 r6,IF_REG  ; IF_REG &= $FD
  ldrb r7,[r10,r6]
  and r7,$FD
  strb r7,[r10,r6]
  sub sp,2	   ; SP_REG -= 2
  strb r4,[r10,sp] ; STACK = PC_REG
  mov r6,r4,lsr 8
  add r7,sp,1
  strb r6,[r10,r7]
  mov r4,$48	   ; PC_REG = $0048
  add r12,6	   ; QCycles += 6
  b INC_INTR

  INTR_2:
  cmp r5,2
  bne INTR_3	   ; CASE 2: { // Bit 2: Timer Interrupt Request (INT 50h)
  imm16 r6,IE_REG  ; IE_REG &= $FB CALL $0050
  ldrb r7,[r10,r6]
  and r7,$FB
  strb r7,[r10,r6]
  imm16 r6,IF_REG  ; IF_REG &= $FB
  ldrb r7,[r10,r6]
  and r7,$FB
  strb r7,[r10,r6]
  sub sp,2	   ; SP_REG -= 2
  strb r4,[r10,sp] ; STACK = PC_REG
  mov r6,r4,lsr 8
  add r7,sp,1
  strb r6,[r10,r7]
  mov r4,$50	   ; PC_REG = $0050
  add r12,6	   ; QCycles += 6
  b INC_INTR

  INTR_3:
  cmp r5,3
  bne INTR_4	   ; CASE 3: { // Bit 3: Serial Interrupt Request (INT 58h)
  imm16 r6,IE_REG  ; IE_REG &= $F7 CALL $0058
  ldrb r7,[r10,r6]
  and r7,$F7
  strb r7,[r10,r6]
  imm16 r6,IF_REG  ; IF_REG &= $F7
  ldrb r7,[r10,r6]
  and r7,$F7
  strb r7,[r10,r6]
  sub sp,2	   ; SP_REG -= 2
  strb r4,[r10,sp] ; STACK = PC_REG
  mov r6,r4,lsr 8
  add r7,sp,1
  strb r6,[r10,r7]
  mov r4,$58	   ; PC_REG = $0058
  add r12,6	   ; QCycles += 6
  b INC_INTR

  INTR_4:
  cmp r5,4
  bne INC_INTR	   ; CASE 4: { // Bit 4: Joypad Interrupt Request (INT 60h)
  imm16 r6,IE_REG  ; IE_REG &= $EF CALL $0060
  ldrb r7,[r10,r6]
  and r7,$EF
  strb r7,[r10,r6]
  imm16 r6,IF_REG  ; IF_REG &= $EF
  ldrb r7,[r10,r6]
  and r7,$EF
  strb r7,[r10,r6]
  sub sp,2	   ; SP_REG -= 2
  strb r4,[r10,sp] ; STACK = PC_REG
  mov r6,r4,lsr 8
  add r7,sp,1
  strb r6,[r10,r7]
  mov r4,$60	   ; PC_REG = $0060
  add r12,6	   ; QCycles += 6

  INC_INTR:
    add r5,1 ; i++ Check Each Interrupt In Priority Order
    b INTR_LOOP

NO_INTR:

; DMA
imm16 r5,DMA_REG ; IF (DMA_REG) { (DMA Transfer Enabled)
ldrb r6,[r10,r5]
cmp r6,0
beq NO_DMA
mov r7,r6,lsl 8 ; DMASRCADDR = DMA_REG << 8
mov r6,0 ; int i = 0
strb r6,[r10,r5] ; DMA_REG = 0
mov r8,OAM_RAM
DMA_LOOP:
  ldrb r9,[r10,r7] ; WHILE (i < 0xA0) { (Loads 160 Bytes of Cartridge To Memory Map)
  add r7,1
  strb r9,[r10,r8] ; MEM_MAP[0xFE00 + i] = MEM_MAP[DMASRCADDR + i]
  add r8,1
  add r6,1 ; i++ }
  cmp r6,$A0
  bne DMA_LOOP
NO_DMA:

; Joypad
imm16 r5,P1_REG ; Reset Joypad (P1_REG = $F)
mov r6,$F
strb r6,[r10,r5]