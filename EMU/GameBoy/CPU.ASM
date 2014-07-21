align 256
CPU_INST:
  ; $00 NOP                     No Operation
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $01 LD    BC, imm           Load 16-Bit Immediate Value To BC
  ldrb r1,[r10,r4]   ; BC_REG = Imm16Bit
  add r4,1           ; PC_REG++
  ldrb r5,[r10,r4]
  orr r1,r5,lsl 8
  add r4,1           ; PC_REG++
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $02 LD    (BC), A           Load Value A To Address In BC
  mov r5,r0,lsr 8    ; MEM_MAP[BC_REG] = A_REG
  strb r5,[r10,r1]
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $03 INC   BC                Increment Register BC
  add r1,1           ; BC_REG++
  tst r1,$10000
  subne r1,$10000
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $04 INC   B                 Increment Register B
  mov r5,r1,lsr 8    ; B_REG++
  add r5,1
  ands r5,$FF
  and r1,$FF
  orr r1,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! B_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  tst r5,$F          ; IF (! (B_REG & $F)) H_SET                           ; H Flag Set IF Carry From Bit 3
  orreq r0,H_FLAG
  bicne r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $05 DEC   B                 Decrement Register B
  mov r5,r1,lsr 8    ; IF (! (B_REG & $F)) H_SET                           ; H Flag Set IF No Borrow From Bit 4
  tst r5,$F
  orreq r0,H_FLAG
  bicne r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  sub r5,1           ; B_REG--
  ands r5,$FF
  and r1,$FF
  orr r1,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! B_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $06 LD    B, imm            Load 8-Bit Immediate Value To B
  ldrb r5,[r10,r4]   ; B_REG = Imm8Bit
  and r1,$FF
  orr r1,r5,lsl 8
  add r4,1           ; PC_REG++
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $07 RLCA                    Rotate Register A Left, Old Bit 7 To Carry Flag
  mov r5,r0,lsr 7    ; A_REG = (A_REG << 1) | (A_REG >> 7)
  and r5,$FE
  orr r5,r0,lsr 15
  and r0,$FF
  orr r0,r5,lsl 8
  tst r5,1           ; IF (A_REG & 1) C_SET                                ; C Flag Set To Old Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  bic r0,H_FLAG + N_FLAG + Z_FLAG ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
                                  ; Z_RESET                                ; Z Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $08 LD    (imm), SP         Load Stack Pointer (SP) To 16-Bit Immediate Address
  ldrb r5,[r10,r4]   ; MEM_MAP[Imm16Bit] = SP_REG
  add r4,1           ; PC_REG++
  ldrb r6,[r10,r4]
  orr r5,r6,lsl 8
  strb sp,[r10,r5]
  add r5,1
  mov r6,sp,lsr 8
  strb r6,[r10,r5]
  add r4,1           ; PC_REG++
  add r12,5          ; QCycles += 5
  bx lr
align 256
  ; $09 ADD   HL, BC            Add BC To HL
  imm16 r5,$FFF      ; IF ((HL_REG & $FFF) + (BC_REG & $FFF) & $1000) H_SET ; H Flag Set IF Carry From Bit 11
  and r6,r3,r5
  and r7,r1,r5
  add r6,r7
  tst r6,$1000
  orrne r0,H_FLAG
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 11
  add r3,r1          ; HL_REG += BC_REG
  tst r3,$10000      ; IF (HL_REG & $10000) C_SET                          ; C Flag Set IF Carry From Bit 15
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 15
  subne r3,$10000
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $0A LD    A, (BC)           Load 8-Bit Value From Address In BC To A
  ldrb r5,[r10,r1]   ; A_REG = MEM_MAP[BC_REG]
  and r0,$FF
  orr r0,r5,lsl 8
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $0B DEC   BC                Decrement Register BC
  sub r1,1           ; BC_REG--
  mov r1,r1,lsl 16
  mov r1,r1,lsr 16
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $0C INC   C                 Increment Register C
  and r5,r1,$FF      ; C_REG++
  add r5,1
  ands r5,$FF
  and r1,$FF00
  orr r1,r5        
  orreq r0,Z_FLAG    ; IF (! C_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  tst r5,$F          ; IF (! (C_REG & $F)) H_SET                           ; H Flag Set IF Carry From Bit 3
  orreq r0,H_FLAG
  bicne r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $0D DEC   C                 Decrement Register C
  and r5,r1,$FF      ; IF (! (C_REG & $F)) H_SET                           ; H Flag Set IF No Borrow From Bit 4
  tst r5,$F
  orreq r0,H_FLAG
  bicne r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  sub r5,1           ; C_REG--
  ands r5,$FF
  and r1,$FF00
  orr r1,r5
  orreq r0,Z_FLAG    ; IF (! C_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $0E LD    C, imm            Load 8-Bit Immediate Value To C
  ldrb r5,[r10,r4]   ; C_REG = Imm8Bit
  and r1,$FF00
  orr r1,r5
  add r4,1           ; PC_REG++
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $0F RRCA                    Rotate Register A Right, Old Bit 0 To Carry Flag
  tst r0,$100        ; IF (A_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  mov r5,r0,lsr 9    ; A_REG = (A_REG >> 1) | (A_REG << 7)
  orrne r5,$80
  and r0,$FF
  orr r0,r5,lsl 8
  bic r0,H_FLAG + N_FLAG + Z_FLAG ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
                                  ; Z_RESET                                ; Z Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $10 STOP                    Halt CPU & LCD Display Until Button Press
  mov r5,1           ; IME_FLAG = 1
  strb r5,[r10,IME_FLAG - MEM_MAP]
  mov r5,r5,lsl 4    ; IF_REG = $10                                        ; Set Joypad Interrupt On
  imm16 r6,IF_REG
  strb r5,[r10,r6]
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $11 LD    DE, imm           Load 16-Bit Immediate Value To DE
  ldrb r2,[r10,r4]   ; DE_REG = Imm16Bit
  add r4,1           ; PC_REG++
  ldrb r5,[r10,r4]
  orr r2,r5,lsl 8
  add r4,1           ; PC_REG++
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $12 LD    (DE), A           Load Value A To Address In DE
  mov r5,r0,lsr 8    ; MEM_MAP[DE_REG] = A_REG
  strb r5,[r10,r2]
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $13 INC   DE                Increment Register DE
  add r2,1           ; DE_REG++
  tst r2,$10000
  subne r2,$10000
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $14 INC   D                 Increment Register D
  mov r5,r2,lsr 8    ; D_REG++
  add r5,1
  ands r5,$FF
  and r2,$FF
  orr r2,r5,lsl 8         
  orreq r0,Z_FLAG    ; IF (! D_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  tst r5,$F          ; IF (! (D_REG & $F)) H_SET                           ; H Flag Set IF Carry From Bit 3
  orreq r0,H_FLAG
  bicne r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $15 DEC   D                 Decrement Register D
  mov r5,r2,lsr 8    ; IF (! (D_REG & $F)) H_SET                           ; H Flag Set IF No Borrow From Bit 4
  tst r5,$F
  orreq r0,H_FLAG
  bicne r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  sub r5,1           ; D_REG--
  ands r5,$FF
  and r2,$FF
  orr r2,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! D_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $16 LD    D, imm            Load 8-Bit Immediate Value To D
  ldrb r5,[r10,r4]   ; B_REG = Imm8Bit
  and r2,$FF
  orr r2,r5,lsl 8
  add r4,1           ; PC_REG++
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $17 RLA                     Rotate Register A Left, Through Carry Flag
  mov r5,r0,lsr 7    ; A_REG = (A_REG << 1) | (C_FLAG)
  tst r0,C_FLAG
  orrne r5,1
  biceq r5,1
  tst r5,$100        ; IF (A_REG & $100) C_SET                             ; C Flag Set To Old Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  andne r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  bic r0,H_FLAG + N_FLAG + Z_FLAG ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
                                  ; Z_RESET                                ; Z Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $18 JR    imm               Add 8-Bit Signed Immediate Value To Current Address & Jump To It
  ldrsb r5,[r10,r4]  ; PC_REG += Imm8Bit
  add r4,r5
  add r4,1           ; PC_REG++
  add r12,3          ; QCycles += 3;
  bx lr
align 256
  ; $19 ADD   HL, DE            Add DE To HL
  imm16 r5,$FFF      ; IF ((HL_REG & $FFF) + (DE_REG & $FFF) & $1000) H_SET ; H Flag Set IF Carry From Bit 11
  and r6,r3,r5
  and r7,r2,r5
  add r6,r7
  tst r6,$1000
  orrne r0,H_FLAG 
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 11
  add r3,r2          ; HL_REG += DE_REG
  tst r3,$10000      ; IF (HL_REG & $10000) C_SET                          ; C Flag Set IF Carry From Bit 15
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 15
  subne r3,$10000
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $1A LD    A, (DE)           Load 8-Bit Value From Address In DE To A
  ldrb r5,[r10,r2]   ; A_REG = MEM_MAP[DE_REG]
  and r0,$FF
  orr r0,r5,lsl 8
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $1B DEC   DE                Decrement Register DE
  sub r2,1           ; DE_REG--
  mov r2,r2,lsl 16
  mov r2,r2,lsr 16
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $1C INC   E                 Increment Register E
  and r5,r2,$FF      ; E_REG++
  add r5,1
  ands r5,$FF
  and r2,$FF00
  orr r2,r5
  orreq r0,Z_FLAG    ; IF (! E_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  tst r5,$F          ; IF (! (E_REG & $F)) H_SET                           ; H Flag Set IF Carry From Bit 3
  orreq r0,H_FLAG
  bicne r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $1D DEC   E                 Decrement Register E
  and r5,r2,$FF      ; IF (! (E_REG & $F)) H_SET                           ; H Flag Set IF No Borrow From Bit 4
  tst r5,$F
  orreq r0,H_FLAG
  bicne r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  sub r5,1           ; E_REG--
  ands r5,$FF
  and r2,$FF00
  orr r2,r5
  orreq r0,Z_FLAG    ; IF (! E_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $1E LD    E, imm            Load 8-Bit Immediate Value To E
  ldrb r5,[r10,r4]   ; E_REG = Imm8Bit
  and r2,$FF00
  orr r2,r5
  add r4,1           ; PC_REG++
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $1F RRA                     Rotate Register A Right, Through Carry Flag
  mov r5,r0,lsr 9    ; A_REG = (A_REG >> 1) | (C_FLAG << 7)
  tst r0,C_FLAG
  orrne r5,$80
  biceq r5,$80
  tst r0,$100        ; IF (A_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  andne r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  bic r0,H_FLAG + N_FLAG + Z_FLAG ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
                                  ; Z_RESET                                ; Z Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $20 JR    NZ, imm           IF Z Flag Reset, Add 8-Bit Signed Immediate Value To Current Address & Jump To It
  tst r0,Z_FLAG      ; IF (! Z_FLAG) {
  ldrsbeq r5,[r10,r4]
  addeq r4,r5        ;   PC_REG += Imm8Bit
  addeq r12,1        ;   QCycles++ }
  add r4,1           ; PC_REG++
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $21 LD    HL, imm           Load 16-Bit Immediate Value To HL
  ldrb r3,[r10,r4]   ; DE_REG = Imm16Bit
  add r4,1           ; PC_REG++
  ldrb r5,[r10,r4]
  orr r3,r5,lsl 8
  add r4,1           ; PC_REG++
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $22 LD    (HLI), A          Load A To Memory Address HL, Increment HL
  mov r5,r0,lsr 8    ; MEM_MAP[HL_REG] = A_REG
  strb r5,[r10,r3]
  add r3,1           ; HL_REG++
  tst r3,$10000
  subne r3,$10000
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $23 INC   HL                Increment Register HL
  add r3,1           ; HL_REG++
  tst r3,$10000
  subne r3,$10000
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $24 INC   H                 Increment Register H
  mov r5,r3,lsr 8    ; H_REG++
  add r5,1
  ands r5,$FF
  and r3,$FF
  orr r3,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! H_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  tst r5,$F          ; IF (! (H_REG & $F)) H_SET                           ; H Flag Set IF Carry From Bit 3
  orreq r0,H_FLAG
  bicne r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $25 DEC   H                 Decrement Register H
  mov r5,r3,lsr 8    ; IF (! (H_REG & $F)) H_SET                           ; H Flag Set IF No Borrow From Bit 4
  tst r5,$F
  orreq r0,H_FLAG
  bicne r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  sub r5,1           ; H_REG--
  ands r5,$FF
  and r3,$FF
  orr r3,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! H_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $26 LD    H, imm            Load 8-Bit Immediate Value To H
  ldrb r5,[r10,r4]   ; H_REG = Imm8Bit
  and r3,$FF
  orr r3,r5,lsl 8
  add r4,1           ; PC_REG++
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $27 DAA                     Decimal Adjust Register A (Convert To Binary Coded Data)
  mov r5,r0,lsr 8    ; A = A_REG
  tst r0,N_FLAG      ; IF (! N_FLAG) {
  bne DAA_N_FLAG
  tst r0,H_FLAG      ;   IF (H_FLAG || (A & $F) > $9) A += $6
  addne r5,6
  bne DAA_H_FLAG
  mov r6,r0,lsr 8
  and r6,$F
  cmp r6,9
  addgt r5,6
DAA_H_FLAG:
  tst r0,C_FLAG      ;   IF (C_FLAG || A > $9F) A += $60 }
  addne r5,$60
  bne DAA_END
  cmp r5,$9F
  addgt r5,$60
  b DAA_END
DAA_N_FLAG:          ; ELSE {
  tst r0,H_FLAG      ;   IF (H_FLAG) {
  beq DAA_C_FLAG
  sub r5,6           ;     A -= $6
  tst r0,C_FLAG      ;     IF (! C_FLAG) A &= $FF }
  andeq r5,$FF
DAA_C_FLAG:
  tst r0,C_FLAG 
  subne r5,$60       ;   IF (C_FLAG) A -= $60 }
DAA_END:
  tst r5,$100        ; IF (A & $100) C_SET                                 ; C Flag Set IF Carry From Bit 7
  orrne r0,C_FLAG
  bic r0,H_FLAG      ; H_RESET                                             ; H Flag Reset
  ands r5,$FF        ; A_REG = A
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $28 JR    Z, imm            IF Z Flag Set, Add 8-Bit Signed Immediate Value To Current Address & Jump To It
  tst r0,Z_FLAG      ; IF (Z_FLAG) {
  ldrsbne r5,[r10,r4]
  addne r4,r5        ;   PC_REG += Imm8Bit
  addne r12,1        ;   QCycles++ }
  add r4,1           ; PC_REG++
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $29 ADD   HL, HL            Add HL To HL
  imm16 r5,$FFF      ; IF ((HL_REG & $FFF) << 1 & $1000) H_SET             ; H Flag Set IF Carry From Bit 11
  and r6,r3,r5
  mov r6,r6,lsl 1
  tst r6,$1000
  orrne r0,H_FLAG
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 11
  mov r3,r3,lsl 1    ; HL_REG += HL_REG
  tst r3,$10000      ; IF (HL_REG & $10000) C_SET                          ; C Flag Set IF Carry From Bit 15
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 15
  subne r3,$10000
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $2A LD    A, (HLI)          Load Value At Address HL To A, Increment HL
  ldrb r5,[r10,r3]   ; A_REG = MEM_MAP[HL_REG]
  and r0,$FF
  orr r0,r5,lsl 8
  add r3,1           ; HL_REG++
  tst r3,$10000
  subne r3,$10000
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $2B DEC   HL                Decrement Register HL
  sub r3,1           ; HL_REG--
  mov r3,r3,lsl 16
  mov r3,r3,lsr 16
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $2C INC   L                 Increment Register L
  and r5,r3,$FF      ; L_REG++
  add r5,1
  ands r5,$FF
  and r3,$FF00
  orr r3,r5
  orreq r0,Z_FLAG    ; IF (! L_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  tst r5,$F          ; IF (! (L_REG & $F)) H_SET                           ; H Flag Set IF Carry From Bit 3
  orreq r0,H_FLAG
  bicne r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $2D DEC   L                 Decrement Register L
  and r5,r3,$FF      ; IF (! (L_REG & $F)) H_SET                           ; H Flag Set IF No Borrow From Bit 4
  tst r5,$F
  orreq r0,H_FLAG
  bicne r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  sub r5,1           ; L_REG--
  ands r5,$FF
  and r3,$FF00
  orr r3,r5
  orreq r0,Z_FLAG    ; IF (! L_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $2E LD    L, imm            Load 8-Bit Immediate Value To L
  ldrb r5,[r10,r4]   ; L_REG = Imm8Bit
  and r3,$FF00
  orr r3,r5
  add r4,1           ; PC_REG++
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $2F CPL                     Complement Register A (Flip All Bits)
  eor r0,$FF00       ; A_REG ^= $FF
  orr r0,H_FLAG + N_FLAG ; H_SET                                           ; H Flag Set
                         ; N_SET                                           ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $30 JR    NC, imm           IF C Flag Reset, Add 8-Bit Signed Immediate Value To Current Address & Jump To It
  tst r0,C_FLAG      ; IF (! C_FLAG) {
  ldrsbeq r5,[r10,r4]
  addeq r4,r5        ;   PC_REG += Imm8Bit
  addeq r12,1        ;   QCycles++ }
  add r4,1           ; PC_REG++
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $31 LD    SP, imm           Load 16-Bit Immediate Value To SP
  ldrb sp,[r10,r4]   ; SP_REG = Imm16Bit
  add r4,1           ; PC_REG++
  ldrb r5,[r10,r4]
  orr sp,r5,lsl 8
  add r4,1           ; PC_REG++
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $32 LD    (HLD), A          Load A To Memory Address HL, Decrement HL
  mov r5,r0,lsr 8    ; MEM_MAP[HL_REG] = A_REG
  strb r5,[r10,r3]
  sub r3,1           ; HL_REG--
  mov r3,r3,lsl 16
  mov r3,r3,lsr 16
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $33 INC   SP                Increment Register SP
  add sp,1           ; SP_REG++
  tst sp,$10000
  subne sp,$10000
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $34 INC   (HL)              Increment Address In Register HL
  ldrb r5,[r10,r3]   ; MEM_MAP[HL_REG]++
  add r5,1
  strb r5,[r10,r3]
  tst r5,$FF
  orreq r0,Z_FLAG    ; IF (! MEM_MAP[HL_REG]) Z_SET                        ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  tst r5,$F          ; IF (! (MEM_MAP[HL_REG] & $F)) H_SET                 ; H Flag Set IF Carry From Bit 3
  orreq r0,H_FLAG
  bicne r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $35 DEC   (HL)              Decrement Address In Register HL
  ldrb r5,[r10,r3]   ; IF (! (MEM_MAP[HL_REG] & $F)) H_SET                 ; H Flag Set IF No Borrow From Bit 4
  tst r5,$F
  orreq r0,H_FLAG
  bicne r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  sub r5,1           ; MEM_MAP[HL_REG]--
  strb r5,[r10,r3]
  tst r5,$FF
  orreq r0,Z_FLAG    ; IF (! MEM_MAP[HL_REG]) Z_SET                        ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $36 LD    (HL), imm         Load 8-Bit Immediate Value To Address In HL
  ldrb r5,[r10,r4]   ; MEM_MAP[HL_REG] = Imm8Bit
  strb r5,[r10,r3]
  add r4,1           ; PC_REG++
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $37 SCF                     Set Carry Flag
  orr r0,C_FLAG      ; C_SET                                               ; C Flag Set
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $38 JR    C, imm            IF C Flag Set, Add 8-Bit Signed Immediate Value To Current Address & Jump To It
  tst r0,C_FLAG      ; IF (C_FLAG) {
  ldrsbne r5,[r10,r4]
  addne r4,r5        ;   PC_REG += Imm8Bit
  addne r12,1        ;   QCycles++ }
  add r4,1           ; PC_REG++
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $39 ADD   HL, SP            Add SP To HL
  imm16 r5,$FFF      ; IF ((HL_REG & $FFF) + (SP_REG & $FFF) & $1000) H_SET ; H Flag Set IF Carry From Bit 11
  and r6,r3,r5
  and r7,sp,r5
  add r6,r7
  tst r6,$1000
  orrne r0,H_FLAG 
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 11
  add r3,sp          ; HL_REG += SP_REG
  tst r3,$10000      ; IF (HL_REG & 10000) C_SET                           ; C Flag Set IF Carry From Bit 15
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 15
  subne r3,$10000
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $3A LD    A, (HLD)          Load Value At Address HL To A, Decrement HL
  ldrb r5,[r10,r3]   ; A_REG = MEM_MAP[HL_REG]
  and r0,$FF
  orr r0,r5,lsl 8
  sub r3,1           ; HL_REG--
  mov r3,r3,lsl 16
  mov r3,r3,lsr 16
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $3B DEC   SP                Decrement Register SP
  sub sp,1           ; SP_REG--
  mov sp,sp,lsl 16
  mov sp,sp,lsr 16
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $3C INC   A                 Increment Register A
  mov r5,r0,lsr 8    ; A_REG++
  add r5,1
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! H_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  tst r5,$F          ; IF (! (H_REG & $F)) H_SET                           ; H Flag Set IF Carry From Bit 3
  orreq r0,H_FLAG
  bicne r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $3D DEC   A                 Decrement Register A
  mov r5,r0,lsr 8    ; IF (! (A_REG & $F)) H_SET                           ; H Flag Set IF No Borrow From Bit 4
  tst r5,$F
  orreq r0,H_FLAG
  bicne r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  sub r5,1           ; A_REG--
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $3E LD    A, imm            Load 8-Bit Immediate Value To A
  ldrb r5,[r10,r4]   ; A_REG = Imm8Bit
  and r0,$FF
  orr r0,r5,lsl 8
  add r4,1           ; PC_REG++
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $3F CCF                     Complement Carry Flag (Flip Carry Bit)
  eor r0,C_FLAG      ; F_REG ^= $10
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $40 LD    B, B              Load Value B To B
                     ; B_REG = B_REG
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $41 LD    B, C              Load Value C To B
  and r5,r1,$FF      ; B_REG = C_REG
  and r1,$FF
  orr r1,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $42 LD    B, D              Load Value D To B
  mov r5,r2,lsr 8    ; B_REG = D_REG
  and r1,$FF
  orr r1,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $43 LD    B, E              Load Value E To B
  and r5,r2,$FF      ; B_REG = E_REG
  and r1,$FF
  orr r1,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $44 LD    B, H              Load Value H To B
  mov r5,r3,lsr 8    ; B_REG = H_REG
  and r1,$FF
  orr r1,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $45 LD    B, L              Load Value L To B
  and r5,r3,$FF      ; B_REG = L_REG
  and r1,$FF
  orr r1,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $46 LD    B, (HL)           Load 8-Bit Value From Address In HL To B
  ldrb r5,[r10,r3]   ; B_REG = MEM_MAP[HL_REG]
  and r1,$FF
  orr r1,r5,lsl 8
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $47 LD    B, A              Load Value A To B
  mov r5,r0,lsr 8    ; B_REG = A_REG
  and r1,$FF
  orr r1,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $48 LD    C, B              Load Value B To C
  mov r5,r1,lsr 8    ; C_REG = B_REG
  and r1,$FF00
  orr r1,r5
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $49 LD    C, C              Load Value C To C
                     ; C_REG = C_REG
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $4A LD    C, D              Load Value D To C
  mov r5,r2,lsr 8    ; C_REG = D_REG
  and r1,$FF00
  orr r1,r5
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $4B LD    C, E              Load Value E To C
  and r5,r2,$FF      ; C_REG = E_REG
  and r1,$FF00
  orr r1,r5
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $4C LD    C, H              Load Value H To C
  mov r5,r3,lsr 8    ; C_REG = H_REG
  and r1,$FF00
  orr r1,r5
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $4D LD    C, L              Load Value L To C
  and r5,r3,$FF      ; C_REG = L_REG
  and r1,$FF00
  orr r1,r5
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $4E LD    C, (HL)           Load 8-Bit Value From Address In HL To C
  ldrb r5,[r10,r3]   ; C_REG = MEM_MAP[HL_REG];
  and r1,$FF00
  orr r1,r5
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $4F LD    C, A              Load Value A To C
  mov r5,r0,lsr 8    ; C_REG = A_REG
  and r1,$FF00
  orr r1,r5
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $50 LD    D, B              Load Value B To D
  mov r5,r1,lsr 8    ; D_REG = B_REG
  and r2,$FF
  orr r2,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $51 LD    D, C              Load Value C To D
  and r5,r1,$FF      ; D_REG = C_REG
  and r2,$FF
  orr r2,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $52 LD    D, D              Load Value D To D
                     ; D_REG = D_REG
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $53 LD    D, E              Load Value E To D
  and r5,r2,$FF      ; D_REG = E_REG
  and r2,$FF
  orr r2,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $54 LD    D, H              Load Value H To D
  mov r5,r3,lsr 8    ; D_REG = H_REG
  and r2,$FF
  orr r2,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $55 LD    D, L              Load Value L To D
  and r5,r3,$FF      ; D_REG = L_REG
  and r2,$FF
  orr r2,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $56 LD    D, (HL)           Load 8-Bit Value From Address In HL To D
  ldrb r5,[r10,r3]   ; D_REG = MEM_MAP[HL_REG]
  and r2,$FF
  orr r2,r5,lsl 8
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $57 LD    D, A              Load Value A To D
  mov r5,r0,lsr 8    ; D_REG = A_REG
  and r2,$FF
  orr r2,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $58 LD    E, B              Load Value B To E
  mov r5,r1,lsr 8    ; E_REG = B_REG
  and r2,$FF00
  orr r2,r5
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $59 LD    E, C              Load Value C To E
  and r5,r1,$FF      ; E_REG = C_REG
  and r2,$FF00
  orr r2,r5
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $5A LD    E, D              Load Value D To E
  mov r5,r2,lsr 8    ; E_REG = D_REG
  and r2,$FF00
  orr r2,r5
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $5B LD    E, E              Load Value E To E
                     ; E_REG = E_REG
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $5C LD    E, H              Load Value H To E
  mov r5,r3,lsr 8    ; E_REG = H_REG
  and r2,$FF00
  orr r2,r5
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $5D LD    E, L              Load Value L To E
  and r5,r3,$FF      ; E_REG = L_REG
  and r2,$FF00
  orr r2,r5
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $5E LD    E, (HL)           Load 8-Bit Value From Address In HL To E
  ldrb r5,[r10,r3]   ; E_REG = MEM_MAP[HL_REG]
  and r2,$FF00
  orr r2,r5
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $5F LD    E, A              Load Value A To E
  mov r5,r0,lsr 8    ; E_REG = A_REG
  and r2,$FF00
  orr r2,r5
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $60 LD    H, B              Load Value B To H
  mov r5,r1,lsr 8    ; H_REG = B_REG
  and r3,$FF
  orr r3,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $61 LD    H, C              Load Value C To H
  and r5,r1,$FF      ; H_REG = C_REG
  and r3,$FF
  orr r3,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $62 LD    H, D              Load Value D To H
  mov r5,r2,lsr 8    ; H_REG = D_REG
  and r3,$FF
  orr r3,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $63 LD    H, E              Load Value E To H
  and r5,r2,$FF      ; H_REG = E_REG
  and r3,$FF
  orr r3,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $64 LD    H, H              Load Value H To H
                     ; H_REG = H_REG
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $65 LD    H, L              Load Value L To H
  and r5,r3,$FF      ; H_REG = L_REG
  and r3,$FF
  orr r3,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $66 LD    H, (HL)           Load 8-Bit Value From Address In HL To H
  ldrb r5,[r10,r3]   ; H_REG = MEM_MAP[HL_REG]
  and r3,$FF
  orr r3,r5,lsl 8
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $67 LD    H, A              Load Value A To H
  mov r5,r0,lsr 8    ; H_REG = A_REG
  and r3,$FF
  orr r3,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $68 LD    L, B              Load Value B To L
  mov r5,r1,lsr 8    ; L_REG = B_REG
  and r3,$FF00
  orr r3,r5
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $69 LD    L, C              Load Value C To L
  and r5,r1,$FF      ; L_REG = C_REG
  and r3,$FF00
  orr r3,r5
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $6A LD    L, D              Load Value D To L
  mov r5,r2,lsr 8    ; L_REG = D_REG
  and r3,$FF00
  orr r3,r5
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $6B LD    L, E              Load Value E To L
  and r5,r2,$FF      ; L_REG = E_REG
  and r3,$FF00
  orr r3,r5
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $6C LD    L, H              Load Value H To L
  mov r5,r3,lsr 8    ; L_REG = H_REG
  and r3,$FF00
  orr r3,r5
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $6D LD    L, L              Load Value L To L
                     ; L_REG = L_REG
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $6E LD    L, (HL)           Load 8-Bit Value From Address In HL To L
  ldrb r5,[r10,r3]   ; L_REG = MEM_MAP[HL_REG]
  and r3,$FF00
  orr r3,r5
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $6F LD    L, A              Load Value A To L
  mov r5,r0,lsr 8    ; L_REG = A_REG
  and r3,$FF00
  orr r3,r5
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $70 LD    (HL), B           Load Value B To Address In HL
  mov r5,r1,lsr 8    ; MEM_MAP[HL_REG] = B_REG
  strb r5,[r10,r3]
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $71 LD    (HL), C           Load Value C To Address In HL
  and r5,r1,$FF      ; MEM_MAP[HL_REG] = C_REG
  strb r5,[r10,r3]
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $72 LD    (HL), D           Load Value D To Address In HL
  mov r5,r2,lsr 8    ; MEM_MAP[HL_REG] = D_REG
  strb r5,[r10,r3]
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $73 LD    (HL), E           Load Value E To Address In HL
  and r5,r2,$FF      ; MEM_MAP[HL_REG] = E_REG
  strb r5,[r10,r3]
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $74 LD    (HL), H           Load Value H To Address In HL
  mov r5,r3,lsr 8    ; MEM_MAP[HL_REG] = H_REG
  strb r5,[r10,r3]
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $75 LD    (HL), L           Load Value L To Address In HL
  and r5,r3,$FF      ; MEM_MAP[HL_REG] = L_REG
  strb r5,[r10,r3]
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $76 HALT                    Power Down CPU Until An Interrupt Occurs
  mov r5,1           ; IME_FLAG = 1
  strb r5,[r10,IME_FLAG - MEM_MAP]
  mov r5,$1F         ; IF_REG = $1F                                        ;  Set All Interrupts On
  imm16 r6,IF_REG
  strb r5,[r10,r6]
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $77 LD    (HL), A           Load Value A To Address In HL
  mov r5,r0,lsr 8    ; MEM_MAP[HL_REG] = A_REG
  strb r5,[r10,r3]
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $78 LD    A, B              Load Value B To A
  mov r5,r1,lsr 8    ; A_REG = B_REG
  and r0,$FF
  orr r0,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $79 LD    A, C              Load Value C To A
  and r5,r1,$FF      ; A_REG = C_REG
  and r0,$FF
  orr r0,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $7A LD    A, D              Load Value D To A
  mov r5,r2,lsr 8    ; A_REG = D_REG
  and r0,$FF
  orr r0,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $7B LD    A, E              Load Value E To A
  and r5,r2,$FF      ; A_REG = E_REG
  and r0,$FF
  orr r0,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $7C LD    A, H              Load Value H To A
  mov r5,r3,lsr 8    ; A_REG = H_REG
  and r0,$FF
  orr r0,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $7D LD    A, L              Load Value L To A
  and r5,r3,$FF      ; A_REG = L_REG
  and r0,$FF
  orr r0,r5,lsl 8
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $7E LD    A, (HL)           Load 8-Bit Value From Address In HL To A
  ldrb r5,[r10,r3]   ; A_REG = MEM_MAP[HL_REG]
  and r0,$FF
  orr r0,r5,lsl 8
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $7F LD    A, A              Load Value A To A
                     ; A_REG = A_REG
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $80 ADD   A, B              Add B To A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) + (B_REG & $F) & $10) H_SET        ; H Flag Set IF Carry From Bit 3
  mov r6,r1,lsr 8
  and r7,r5,$F
  and r8,r6,$F
  add r7,r8
  tst r7,$10
  orrne r0,H_FLAG
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  add r5,r6          ; A_REG += B_REG
  tst r5,$100        ; IF (A_REG & $100) C_SET                             ; C Flag Set IF Carry From Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 7
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8           
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $81 ADD   A, C              Add C To A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) + (C_REG & $F) & $10) H_SET        ; H Flag Set IF Carry From Bit 3
  and r6,r1,$FF
  and r7,r5,$F
  and r8,r6,$F
  add r7,r8
  tst r7,$10
  orrne r0,H_FLAG
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  add r5,r6          ; A_REG += C_REG
  tst r5,$100        ; IF (A_REG & $100) C_SET                             ; C Flag Set IF Carry From Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 7
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $82 ADD   A, D              Add D To A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) + (D_REG & $F) & $10) H_SET        ; H Flag Set IF Carry From Bit 3
  mov r6,r2,lsr 8
  and r7,r5,$F
  and r8,r6,$F
  add r7,r8
  tst r7,$10
  orrne r0,H_FLAG
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  add r5,r6          ; A_REG += D_REG
  tst r5,$100        ; IF (A_REG & $100) C_SET                             ; C Flag Set IF Carry From Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 7
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $83 ADD   A, E              Add E To A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) + (E_REG & $F) & $10) H_SET        ; H Flag Set IF Carry From Bit 3
  and r6,r2,$FF
  and r7,r5,$F
  and r8,r6,$F
  add r7,r8
  tst r7,$10
  orrne r0,H_FLAG
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  add r5,r6          ; A_REG += E_REG
  tst r5,$100        ; IF (A_REG & $100) C_SET                             ; C Flag Set IF Carry From Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 7
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $84 ADD   A, H              Add H To A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) + (H_REG & $F) & $10) H_SET        ; H Flag Set IF Carry From Bit 3
  mov r6,r3,lsr 8
  and r7,r5,$F
  and r8,r6,$F
  add r7,r8
  tst r7,$10
  orrne r0,H_FLAG
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  add r5,r6          ; A_REG += H_REG
  tst r5,$100        ; IF (A_REG & $100) C_SET                             ; C Flag Set IF Carry From Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 7
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $85 ADD   A, L              Add L To A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) + (L_REG & $F) & $10) H_SET        ; H Flag Set IF Carry From Bit 3
  and r6,r3,$FF
  and r7,r5,$F
  and r8,r6,$F
  add r7,r8
  tst r7,$10
  orrne r0,H_FLAG
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  add r5,r6          ; A_REG += L_REG
  tst r5,$100        ; IF (A_REG & $100) C_SET                             ; C Flag Set IF Carry From Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 7
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $86 ADD   A, (HL)           Add 8-Bit Value From Address In HL To A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) + (MEM_MAP[HL_REG] & $F) & $10) H_SET ; H Flag Set IF Carry From Bit 3
  ldrb r6,[r10,r3]
  and r7,r5,$F
  and r8,r6,$F
  add r7,r8
  tst r7,$10
  orrne r0,H_FLAG
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  add r5,r6          ; A_REG += MEM_MAP[HL_REG]
  tst r5,$100        ; IF (A_REG & $100) C_SET                             ; C Flag Set IF Carry From Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 7
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $87 ADD   A, A              Add A To A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) << 1 & $10) H_SET                  ; H Flag Set IF Carry From Bit 3
  and r6,r5,$F
  mov r6,r6,lsl 1
  tst r6,$10
  orrne r0,H_FLAG
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  mov r5,r5,lsl 1    ; A_REG += A_REG
  tst r5,$100        ; IF (A_REG & $100) C_SET                             ; C Flag Set IF Carry From Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 7
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $88 ADC   A, B              Add B + Carry Flag To A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) + (B_REG & $F) + C_FLAG & $10) H_SET ; H Flag Set IF Carry From Bit 3
  mov r6,r1,lsr 8
  and r7,r5,$F
  and r8,r6,$F
  add r7,r8
  and r8,r0,C_FLAG
  add r7,r8,lsr 4
  tst r7,$10
  orrne r0,H_FLAG
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  add r5,r6          ; A_REG += B_REG + C_FLAG
  add r5,r8,lsr 4
  tst r5,$100        ; IF (A_REG & $100) C_SET                             ; C Flag Set IF Carry From Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 7
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $89 ADC   A, C              Add C + Carry Flag To A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) + (C_REG & $F) + C_FLAG & $10) H_SET ; H Flag Set IF Carry From Bit 3
  and r6,r1,$FF
  and r7,r5,$F
  and r8,r6,$F
  add r7,r8
  and r8,r0,C_FLAG
  add r7,r8,lsr 4
  tst r7,$10
  orrne r0,H_FLAG
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  add r5,r6          ; A_REG += C_REG + C_FLAG
  add r5,r8,lsr 4
  tst r5,$100        ; IF (A_REG & $100) C_SET                             ; C Flag Set IF Carry From Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 7
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $8A ADC   A, D              Add D + Carry Flag To A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) + (D_REG & $F) + C_FLAG & $10) H_SET ; H Flag Set IF Carry From Bit 3
  mov r6,r2,lsr 8
  and r7,r5,$F
  and r8,r6,$F
  add r7,r8
  and r8,r0,C_FLAG
  add r7,r8,lsr 4
  tst r7,$10
  orrne r0,H_FLAG
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  add r5,r6          ; A_REG += D_REG + C_FLAG
  add r5,r8,lsr 4
  tst r5,$100        ; IF (A_REG & $100) C_SET                             ; C Flag Set IF Carry From Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 7
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $8B ADC   A, E              Add E + Carry Flag To A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) + (E_REG & $F) + C_FLAG & $10) H_SET ; H Flag Set IF Carry From Bit 3
  and r6,r2,$FF
  and r7,r5,$F
  and r8,r6,$F
  add r7,r8
  and r8,r0,C_FLAG
  add r7,r8,lsr 4
  tst r7,$10
  orrne r0,H_FLAG
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3  
  add r5,r6          ; A_REG += E_REG + C_FLAG
  add r5,r8,lsr 4
  tst r5,$100        ; IF (A_REG & $100) C_SET                             ; C Flag Set IF Carry From Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 7
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $8C ADC   A, H              Add H + Carry Flag To A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) + (H_REG & $F) + C_FLAG & $10) H_SET ; H Flag Set IF Carry From Bit 3
  mov r6,r3,lsr 8
  and r7,r5,$F
  and r8,r6,$F
  add r7,r8
  and r8,r0,C_FLAG
  add r7,r8,lsr 4
  tst r7,$10
  orrne r0,H_FLAG
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  add r5,r6          ; A_REG += H_REG + C_FLAG
  add r5,r8,lsr 4
  tst r5,$100        ; IF (A_REG & $100) C_SET                             ; C Flag Set IF Carry From Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 7
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $8D ADC   A, L              Add L + Carry Flag To A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) + (L_REG & $F) + C_FLAG & $10) H_SET ; H Flag Set IF Carry From Bit 3
  and r6,r3,$FF
  and r7,r5,$F
  and r8,r6,$F
  add r7,r8
  and r8,r0,C_FLAG
  add r7,r8,lsr 4
  tst r7,$10
  orrne r0,H_FLAG
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  add r5,r6          ; A_REG += L_REG + C_FLAG
  add r5,r8,lsr 4
  tst r5,$100        ; IF (A_REG & $100) C_SET                             ; C Flag Set IF Carry From Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 7
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $8E ADC   A, (HL)           Add 8-Bit Value From Address In HL + Carry Flag To A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) + (MEM_MAP[HL_REG] & $F) + C_FLAG & $10) H_SET ; H Flag Set IF Carry From Bit 3
  ldrb r6,[r10,r3]
  and r7,r5,$F
  and r8,r6,$F
  add r7,r8
  and r8,r0,C_FLAG
  add r7,r8,lsr 4
  tst r7,$10
  orrne r0,H_FLAG
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3  
  add r5,r6          ; A_REG += MEM_MAP[HL_REG] + C_FLAG
  add r5,r8,lsr 4
  tst r5,$100        ; IF (A_REG & $100) C_SET                             ; C Flag Set IF Carry From Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 7
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $8F ADC   A, A              Add A + Carry Flag To A
  mov r5,r0,lsr 8    ; IF (((A_REG & $F) << 1) + C_FLAG & $10) H_SET       ; H Flag Set IF Carry From Bit 3
  and r6,r5,$F
  mov r6,r6,lsl 1
  and r7,r0,C_FLAG
  add r6,r7,lsr 4
  tst r6,$10
  orrne r0,H_FLAG
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  mov r5,r5,lsl 1    ; A_REG += A_REG + C_FLAG
  add r5,r7,lsr 4  
  tst r5,$100        ; IF (A_REG & $100) C_SET                             ; C Flag Set IF Carry From Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 7
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $90 SUB   B                 Subtract B From A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (B_REG & $F) < $0) H_SET         ; H Flag Set IF No Borrow From Bit 4
  mov r6,r1,lsr 8
  and r7,r5,$F
  and r8,r6,$F
  subs r7,r8
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  subs r5,r6         ; A_REG -= B_REG
  orrlt r0,C_FLAG    ; IF (A_REG < $0) C_SET                               ; C Flag Set IF No Borrow
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $91 SUB   C                 Subtract C From A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (C_REG & $F) < $0) H_SET         ; H Flag Set IF No Borrow From Bit 4
  and r6,r1,$FF
  and r7,r5,$F
  and r8,r6,$F
  subs r7,r8
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  subs r5,r6         ; A_REG -= C_REG
  orrlt r0,C_FLAG    ; IF (A_REG < $0) C_SET                               ; C Flag Set IF No Borrow
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $92 SUB   D                 Subtract D From A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (D_REG & $F) < $0) H_SET         ; H Flag Set IF No Borrow From Bit 4
  mov r6,r2,lsr 8
  and r7,r5,$F
  and r8,r6,$F
  subs r7,r8
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  subs r5,r6         ; A_REG -= D_REG
  orrlt r0,C_FLAG    ; IF (A_REG < $0) C_SET                               ; C Flag Set IF No Borrow
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $93 SUB   E                 Subtract E From A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (E_REG & $F) < $0) H_SET         ; H Flag Set IF No Borrow From Bit 4
  and r6,r2,$FF
  and r7,r5,$F
  and r8,r6,$F
  subs r7,r8
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  subs r5,r6         ; A_REG -= E_REG
  orrlt r0,C_FLAG    ; IF (A_REG < $0) C_SET                               ; C Flag Set IF No Borrow
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $94 SUB   H                 Subtract H From A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (H_REG & $F) < $0) H_SET         ; H Flag Set IF No Borrow From Bit 4
  mov r6,r3,lsr 8
  and r7,r5,$F
  and r8,r6,$F
  subs r7,r8
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  subs r5,r6         ; A_REG -= H_REG
  orrlt r0,C_FLAG    ; IF (A_REG < $0) C_SET                               ; C Flag Set IF No Borrow
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $95 SUB   L                 Subtract L From A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (L_REG & $F) < $0) H_SET         ; H Flag Set IF No Borrow From Bit 4
  and r6,r3,$FF
  and r7,r5,$F
  and r8,r6,$F
  subs r7,r8
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  subs r5,r6         ; A_REG -= L_REG
  orrlt r0,C_FLAG    ; IF (A_REG < $0) C_SET                               ; C Flag Set IF No Borrow
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $96 SUB   (HL)              Subtract 8-Bit Value From Address In HL From A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (MEM_MAP[HL_REG] & $F) < $0) H_SET ; H Flag Set IF No Borrow From Bit 4
  ldrb r6,[r10,r3]
  and r7,r5,$F
  and r8,r6,$F
  subs r7,r8
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  subs r5,r6         ; A_REG -= MEM_MAP[HL_REG]
  orrlt r0,C_FLAG    ; IF (A_REG < $0) C_SET                               ; C Flag Set IF No Borrow
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $97 SUB   A                 Subtract A From A
  and r0,$FF         ; A_REG = 0
  bic r0,H_FLAG + C_FLAG ; H_RESET                                         ; H Flag Reset
                         ; C_RESET                                         ; C Flag Reset
  orr r0,N_FLAG + Z_FLAG ; N_SET                                           ; N Flag Set
                         ; Z_SET                                           ; Z Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $98 SBC   A, B              Subtract B + Carry Flag From A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (B_REG & $F) - C_FLAG < $0) H_SET ; H Flag Set IF No Borrow From Bit 4
  mov r6,r1,lsr 8
  and r7,r5,$F
  and r8,r6,$F
  sub r7,r8
  and r8,r0,C_FLAG
  subs r7,r8,lsr 4
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  mov r5,r0,lsr 8    
  mov r6,r1,lsr 8
  sub r5,r6          ; A_REG -= B_REG - C_FLAG
  subs r5,r8,lsr 4
  orrlt r0,C_FLAG    ; IF (A_REG < $0) C_SET                               ; C Flag Set IF No Borrow
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $99 SBC   A, C              Subtract C + Carry Flag From A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (C_REG & $F) - C_FLAG < $0) H_SET ; H Flag Set IF No Borrow From Bit 4
  and r6,r1,$FF
  and r7,r5,$F
  and r8,r6,$F
  sub r7,r8
  and r8,r0,C_FLAG
  subs r7,r8,lsr 4
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  sub r5,r6          ; A_REG -= C_REG - C_FLAG
  subs r5,r8,lsr 4
  orrlt r0,C_FLAG    ; IF (A_REG < $0) C_SET                               ; C Flag Set IF No Borrow
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $9A SBC   A, D              Subtract D + Carry Flag From A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (D_REG & $F) - C_FLAG < $0) H_SET ; H Flag Set IF No Borrow From Bit 4
  mov r6,r2,lsr 8
  and r7,r5,$F
  and r8,r6,$F
  sub r7,r8
  and r8,r0,C_FLAG
  subs r7,r8,lsr 4
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  sub r5,r6          ; A_REG -= D_REG - C_FLAG
  subs r5,r8,lsr 4
  orrlt r0,C_FLAG    ; IF (A_REG < $0) C_SET                               ; C Flag Set IF No Borrow
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $9B SBC   A, E              Subtract E + Carry Flag From A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (E_REG & $F) - C_FLAG < $0) H_SET ; H Flag Set IF No Borrow From Bit 4
  and r6,r2,$FF
  and r7,r5,$F
  and r8,r6,$F
  sub r7,r8
  and r8,r0,C_FLAG
  subs r7,r8,lsr 4
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  sub r5,r6          ; A_REG -= E_REG - C_FLAG
  subs r5,r8,lsr 4
  orrlt r0,C_FLAG    ; IF (A_REG < $0) C_SET                               ; C Flag Set IF No Borrow
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $9C SBC   A, H              Subtract H + Carry Flag From A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (H_REG & $F) - C_FLAG < $0) H_SET ; H Flag Set IF No Borrow From Bit 4
  mov r6,r3,lsr 8
  and r7,r5,$F
  and r8,r6,$F
  sub r7,r8
  and r8,r0,C_FLAG
  subs r7,r8,lsr 4
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  sub r5,r6          ; A_REG -= H_REG - C_FLAG
  subs r5,r8,lsr 4
  orrlt r0,C_FLAG    ; IF (A_REG < $0) C_SET                               ; C Flag Set IF No Borrow
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $9D SBC   A, L              Subtract L + Carry Flag From A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (L_REG & $F) - C_FLAG < $0) H_SET ; H Flag Set IF No Borrow From Bit 4
  and r6,r3,$FF
  and r7,r5,$F
  and r8,r6,$F
  sub r7,r8
  and r8,r0,C_FLAG
  subs r7,r8,lsr 4
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  sub r5,r6          ; A_REG -= L_REG - C_FLAG
  subs r5,r8,lsr 4
  orrlt r0,C_FLAG    ; IF (A_REG < $0) C_SET                               ; C Flag Set IF No Borrow
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $9E SBC   A, (HL)           Subtract 8-Bit Value From Address In HL + Carry Flag From A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (MEM_MAP[HL_REG] & $F) - C_FLAG < $0) H_SET ; H Flag Set IF No Borrow From Bit 4
  ldrb r6,[r10,r3]
  and r7,r5,$F
  and r8,r6,$F
  sub r7,r8
  and r8,r0,C_FLAG
  subs r7,r8,lsr 4
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  sub r5,r6          ; A_REG -= MEM_MAP[HL_REG] - C_FLAG
  subs r5,r8,lsr 4
  orrlt r0,C_FLAG    ; IF (A_REG < $0) C_SET                               ; C Flag Set IF No Borrow
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $9F SBC   A, A              Subtract A + Carry Flag From A
  tst r0,C_FLAG      ; A_REG = -C_FLAG
  movne r5,$FF
  moveq r5,0
  and r0,$FF
  orr r0,r5,lsl 8
  orrne r0,H_FLAG    ; IF (-C_FLAG > $F) H_SET                             ; H Flag Set IF No Borrow From Bit 4
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set        
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $A0 AND   B                 Logical AND B With A
  and r5,r1,$FF00    ; A_REG &= B_REG
  orr r5,$FF
  and r0,r5
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + N_FLAG ; C_RESET                                         ; C Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $A1 AND   C                 Logical AND C With A
  mov r5,r1,lsl 24   ; A_REG &= C_REG
  mov r5,r5,lsr 16
  orr r5,$FF
  and r0,r5
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + N_FLAG ; C_RESET                                         ; C Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $A2 AND   D                 Logical AND D With A
  and r5,r2,$FF00    ; A_REG &= D_REG
  orr r5,$FF
  and r0,r5
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + N_FLAG ; C_RESET                                         ; C Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $A3 AND   E                 Logical AND E With A
  mov r5,r2,lsl 24   ; A_REG &= E_REG
  mov r5,r5,lsr 16
  orr r5,$FF
  and r0,r5
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + N_FLAG ; C_RESET                                         ; C Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $A4 AND   H                 Logical AND H With A
  and r5,r3,$FF00    ; A_REG &= H_REG
  orr r5,$FF
  and r0,r5
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + N_FLAG ; C_RESET                                         ; C Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $A5 AND   L                 Logical AND L With A
  mov r5,r3,lsl 24   ; A_REG &= E_REG
  mov r5,r5,lsr 16
  orr r5,$FF
  and r0,r5
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + N_FLAG ; C_RESET                                         ; C Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $A6 AND   (HL)              Logical AND 8-Bit Value Of Address In HL With A
  ldrb r5,[r10,r3]   ; A_REG &= MEM_MAP[HL_REG]
  mov r5,r5,lsl 8
  orr r5,$FF
  and r0,r5
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + N_FLAG ; C_RESET                                         ; C Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $A7 AND   A                 Logical AND A With A
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + N_FLAG ; C_RESET                                         ; C Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $A8 XOR   B                 Logical eXclusive OR B With A
  and r5,r1,$FF00    ; A_REG ^= B_REG
  eor r0,r5
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $A9 XOR   C                 Logical eXclusive OR C With A
  mov r5,r1,lsl 8    ; A_REG ^= C_REG
  and r5,$FF00
  eor r0,r5
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $AA XOR   D                 Logical eXclusive OR D With A
  and r5,r2,$FF00    ; A_REG ^= D_REG
  eor r0,r5
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $AB XOR   E                 Logical eXclusive OR E With A
  mov r5,r2,lsl 8    ; A_REG ^= E_REG
  and r5,$FF00
  eor r0,r5
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $AC XOR   H                 Logical eXclusive OR H With A
  and r5,r3,$FF00    ; A_REG ^= H_REG
  eor r0,r5
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $AD XOR   L                 Logical eXclusive OR L With A
  mov r5,r3,lsl 8    ; A_REG ^= L_REG
  and r5,$FF00
  eor r0,r5
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $AE XOR  (HL)               Logical eXclusive OR 8-Bit Value From Address In HL With A
  ldrb r5,[r10,r3]   ; A_REG ^= MEM_MAP[HL_REG]
  mov r5,r5,lsl 8
  eor r0,r5
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $AF XOR   A                 Logical eXclusive OR A With A
  and r0,$FF         ; A_REG ^= A_REG
  orr r0,Z_FLAG      ; Z_SET                                               ; Z Flag Set
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $B0 OR    B                 Logical OR B With A
  and r5,r1,$FF00    ; A_REG |= B_REG
  orr r0,r5
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $B1 OR    C                 Logical OR C With A
  mov r5,r1,lsl 8    ; A_REG |= C_REG
  and r5,$FF00
  orr r0,r5
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $B2 OR    D                 Logical OR D With A
  and r5,r2,$FF00    ; A_REG |= D_REG
  orr r0,r5
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $B3 OR    E                 Logical OR E With A
  mov r5,r2,lsl 8    ; A_REG |= E_REG
  and r5,$FF00
  orr r0,r5
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $B4 OR    H                 Logical OR H With A
  and r5,r3,$FF00    ; A_REG |= H_REG
  orr r0,r5
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $B5 OR    L                 Logical OR L With A
  mov r5,r3,lsl 8    ; A_REG |= L_REG
  and r5,$FF00
  orr r0,r5
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $B6 OR    (HL)              Logical OR 8-Bit Value From Address In HL With A
  ldrb r5,[r10,r3]   ; A_REG |= MEM_MAP[HL_REG]
  mov r5,r5,lsl 8
  orr r0,r5
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $B7 OR    A                 Logical OR A With A
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $B8 CP    B                 Compare A With B
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (B_REG & $F) < $0) H_SET         ; H Flag Set IF No Borrow From Bit 4
  mov r6,r1,lsr 8
  and r7,r5,$F
  and r8,r6,$F
  subs r7,r8
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  cmp r5,r6          ; IF (A_REG < B_REG) C_SET                            ; C Flag Set IF No Borrow
  orrlt r0,C_FLAG
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $B9 CP    C                 Compare A With C
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (C_REG & $F) < $0) H_SET         ; H Flag Set IF No Borrow From Bit 4
  and r6,r1,$FF
  and r7,r5,$F
  and r8,r6,$F
  subs r7,r8
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  cmp r5,r6          ; IF (A_REG < C_REG) C_SET                            ; C Flag Set IF No Borrow
  orrlt r0,C_FLAG
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $BA CP    D                 Compare A With D
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (D_REG & $F) < $0) H_SET         ; H Flag Set IF No Borrow From Bit 4
  mov r6,r2,lsr 8
  and r7,r5,$F
  and r8,r6,$F
  subs r7,r8
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  cmp r5,r6          ; IF (A_REG < D_REG) C_SET                            ; C Flag Set IF No Borrow
  orrlt r0,C_FLAG
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $BB CP    E                 Compare A With E
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (E_REG & $F) < $0) H_SET         ; H Flag Set IF No Borrow From Bit 4
  and r6,r2,$FF
  and r7,r5,$F
  and r8,r6,$F
  subs r7,r8
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  cmp r5,r6          ; IF (A_REG < E_REG) C_SET                            ; C Flag Set IF No Borrow
  orrlt r0,C_FLAG
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $BC CP    H                 Compare A With H
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (H_REG & $F) < $0) H_SET         ; H Flag Set IF No Borrow From Bit 4
  mov r6,r3,lsr 8
  and r7,r5,$F
  and r8,r6,$F
  subs r7,r8
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  cmp r5,r6          ; IF (A_REG < H_REG) C_SET                            ; C Flag Set IF No Borrow
  orrlt r0,C_FLAG
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $BD CP    L                 Compare A With L
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (L_REG & $F) < $0) H_SET         ; H Flag Set IF No Borrow From Bit 4
  and r6,r3,$FF
  and r7,r5,$F
  and r8,r6,$F
  subs r7,r8
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  cmp r5,r6          ; IF (A_REG < L_REG) C_SET                            ; C Flag Set IF No Borrow
  orrlt r0,C_FLAG
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $BE CP    (HL)              Compare A With 8-Bit Value From Address In HL
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (MEM_MAP[HL_REG] & $F) < $0) H_SET ; H Flag Set IF No Borrow From Bit 4
  ldrb r6,[r10,r3]
  and r7,r5,$F
  and r8,r6,$F
  subs r7,r8
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  cmp r5,r6          ; IF (A_REG < MEM_MAP[HL_REG]) C_SET                  ; C Flag Set IF No Borrow
  orrlt r0,C_FLAG
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $BF CP    A                 Compare A With A
  bic r0,H_FLAG + C_FLAG ; H_RESET                                         ; H Flag Reset
                         ; C_RESET                                         ; C Flag Reset
  orr r0,N_FLAG + Z_FLAG ; N_SET                                           ; N Flag Set
                         ; Z_SET                                           ; Z Flag Set
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $C0 RET   NZ                IF Z Flag Is Reset Pop 2 Bytes From Stack & Jump To That Address
  tst r0,Z_FLAG      ; IF (! Z_FLAG) {
  ldrbeq r4,[r10,sp] ;   PC_REG = STACK
  addeq sp,1         ;   SP_REG++
  ldrbeq r5,[r10,sp]
  orreq r4,r5,lsl 8
  addeq sp,1         ;   SP_REG++ 
  addeq r12,3        ;   QCycles += 3 }
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $C1 POP   BC                Pop 2 Bytes Off Stack To Register Pair BC, Increment Stack Pointer (SP) Twice
  ldrb r1,[r10,sp]   ; BC_REG = STACK
  add sp,1           ; SP_REG++
  ldrb r5,[r10,sp]
  orr r1,r5,lsl 8
  add sp,1           ; SP_REG++
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $C2 JP    NZ, imm           Jump To 16-Bit Immediate Address IF Z Flag Reset
  tst r0,Z_FLAG      ; IF (! Z_FLAG) {
  ldrbeq r5,[r10,r4] ;   PC_REG = Imm16Bit
  add r4,1           ;   PC_REG++
  ldrbeq r6,[r10,r4]
  orreq r5,r6,lsl 8
  moveq r4,r5
  addeq r12,1        ;   QCycles++ }
  addne r4,1         ; ELSE PC_REG++
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $C3 JP    imm               Jump To 16-Bit Immediate Address
  ldrb r5,[r10,r4]   ; PC_REG = Imm16Bit
  add r4,1           ; PC_REG++
  ldrb r6,[r10,r4]
  orr r5,r6,lsl 8
  mov r4,r5
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $C4 CALL  NZ, imm           IF Z Flag Reset, Push Address Of Next Instruction To Stack & Jump To 16-Bit Immediate Address
  tst r0,Z_FLAG      ; IF (! Z_FLAG) {
  subeq sp,2         ;   SP_REG -= 2
  addeq r5,r4,2
  strbeq r5,[r10,sp] ;   STACK = PC_REG + 2
  moveq r5,r5,lsr 8
  addeq r6,sp,1
  strbeq r5,[r10,r6]
  ldrbeq r5,[r10,r4] ;   PC_REG = Imm16Bit
  addeq r12,3        ;   QCycles += 3 }
  add r4,1           ; PC_REG++
  ldrbeq r6,[r10,r4]
  orreq r5,r6,lsl 8
  moveq r4,r5
  addne r4,1         ; ELSE PC_REG++
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $C5 PUSH  BC                Push Register Pair BC To Stack, Decrement Stack Pointer (SP) Twice
  sub sp,2           ; SP_REG -= 2
  strb r1,[r10,sp]   ; STACK = BC_REG
  mov r5,r1,lsr 8
  add r6,sp,1
  strb r5,[r10,r6]
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $C6 ADD   A, imm            Add 8-Bit Immediate Value To A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) + (Imm8Bit & $F) & $10) H_SET      ; H Flag Set IF Carry From Bit 3
  ldrb r6,[r10,r4]
  and r7,r5,$F
  and r8,r6,$F
  add r7,r8
  tst r7,$10
  orrne r0,H_FLAG 
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  add r5,r6          ; A_REG += Imm8Bit
  tst r5,$100        ; IF (A_REG & $100) C_SET                             ; C Flag Set IF Carry From Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 7
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8   
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r4,1           ; PC_REG++
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $C7 RST   00H               Push Present Address To Stack, Jump To Address $0000
  sub sp,2           ; SP_REG -= 2
  strb r4,[r10,sp]   ; STACK = PC_REG
  mov r5,r4,lsr 8
  add r6,sp,1
  strb r5,[r10,r6]
  mov r4,$0000       ; PC_REG = $0000
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $C8 RET   Z                 IF Z Flag Set, Pop 2 Bytes From Stack & Jump To Address
  tst r0,Z_FLAG      ; IF (Z_FLAG) {
  ldrbne r4,[r10,sp] ;   PC_REG = STACK
  addne sp,1         ;   SP_REG++
  ldrbne r5,[r10,sp]
  orrne r4,r5,lsl 8
  addne sp,1         ;   SP_REG++
  addne r12,3        ;   QCycles += 3 }
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $C9 RET                     Pop 2 Bytes From Stack & Jump To Address
  ldrb r4,[r10,sp]   ; PC_REG = STACK
  add sp,1           ; SP_REG++
  ldrb r5,[r10,sp]
  orr r4,r5,lsl 8
  add sp,1           ; SP_REG++
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $CA JP    Z, imm            Jump To 16-Bit Immediate Address IF Z Flag Set
  tst r0,Z_FLAG      ; IF (Z_FLAG) {
  ldrbne r5,[r10,r4] ;   PC_REG = Imm16Bit
  add r4,1           ;   PC_REG++
  ldrbne r6,[r10,r4]
  orrne r5,r6,lsl 8
  movne r4,r5
  addne r12,1        ;   QCycles++ }
  addeq r4,1         ; ELSE PC_REG++
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $CB Run Extra CPU Opcodes Jump Table
  imm32 r5,CPU_CB_INST ; r5 = CPU CB Instruction Table
  ldrb r6,[r10,r4]   ; r6 = CPU CB Instruction
  add r6,r5,r6,lsl 8 ; r6 = CPU CB Instruction Table Opcode
  add r4,1           ; PC_REG++
  bx r6
align 256
  ; $CC CALL  Z, imm            IF Z Flag Set, Push Address Of Next Instruction To Stack & Jump To 16-Bit Immediate Address
  tst r0,Z_FLAG      ; IF (Z_FLAG) {
  subne sp,2         ;   SP_REG -= 2
  addne r5,r4,2
  strbne r5,[r10,sp] ;   STACK = PC_REG + 2
  movne r5,r5,lsr 8
  addne r6,sp,1
  strbne r5,[r10,r6]
  ldrbne r5,[r10,r4] ;   PC_REG = Imm16Bit
  addne r12,3        ;   QCycles += 3 }
  add r4,1           ; PC_REG++
  ldrbne r6,[r10,r4]
  orrne r5,r6,lsl 8
  movne r4,r5
  addeq r4,1         ; ELSE PC_REG++
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $CD CALL  imm               Push Address Of Next Instruction To Stack & Jump To 16-Bit Immediate Address
  sub sp,2           ; SP_REG -= 2
  add r5,r4,2
  strb r5,[r10,sp]   ; STACK = PC_REG + 2
  mov r5,r5,lsr 8
  add r6,sp,1
  strb r5,[r10,r6]
  ldrb r5,[r10,r4]   ; PC_REG = Imm16Bit
  add r4,1           ; PC_REG++
  ldrb r6,[r10,r4]
  orr r5,r6,lsl 8
  mov r4,r5
  add r12,6          ; QCycles += 6
  bx lr
align 256
  ; $CE ADC   A, imm            Add 8-Bit Immediate Value + Carry Flag To A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) + (Imm8Bit & $F) + C_FLAG & $10) H_SET ; H Flag Set IF Carry From Bit 3
  ldrb r6,[r10,r4]
  and r7,r5,$F
  and r8,r6,$F
  add r7,r8
  and r8,r0,C_FLAG
  add r7,r8,lsr 4
  tst r7,$10
  orrne r0,H_FLAG 
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3  
  add r5,r6          ; A_REG += Imm8Bit + C_FLAG
  add r5,r8,lsr 4
  tst r5,$100        ; IF (A_REG < Imm8Bit + C_FLAG) C_SET                 ; C Flag Set IF Carry From Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 7
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  add r4,1           ; PC_REG++
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $CF RST   08H               Push Present Address To Stack, Jump To Address $0008
  sub sp,2           ; SP_REG -= 2
  strb r4,[r10,sp]   ; STACK = PC_REG
  mov r5,r4,lsr 8
  add r6,sp,1
  strb r5,[r10,r6]
  mov r4,$0008       ; PC_REG = $0008
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $D0 RET   NC                If C Flag Reset, Pop 2 Bytes From Stack & Jump To Address
  tst r0,C_FLAG      ; IF (! C_FLAG) {
  ldrbeq r4,[r10,sp] ;   PC_REG = STACK
  addeq sp,1         ;   SP_REG++
  ldrbeq r5,[r10,sp]
  orreq r4,r5,lsl 8
  addeq sp,1         ;   SP_REG++
  addeq r12,3        ;   QCycles += 3 }
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $D1 POP   DE                Pop 2 Bytes Off Stack To Register Pair DE, Increment Stack Pointer (SP) Twice
  ldrb r2,[r10,sp]   ; DE_REG = STACK
  add sp,1           ; SP_REG++
  ldrb r5,[r10,sp] 
  orr r2,r5,lsl 8
  add sp,1           ; SP_REG++
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $D2 JP    NC, imm           Jump To 16-Bit Immediate Address IF C Flag Reset
  tst r0,C_FLAG      ; IF (! C_FLAG) {
  ldrbeq r5,[r10,r4] ;   PC_REG = Imm16Bit
  add r4,1           ;   PC_REG++
  ldrbeq r6,[r10,r4]
  orreq r5,r6,lsl 8
  moveq r4,r5
  addeq r12,1        ;   QCycles++ }
  addne r4,1         ; ELSE PC_REG++
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $D3 UNUSED OPCODE           Execution Will Cause GB To Permanently Halt Operation Until Power Down / Power Up
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $D4 CALL  NC, imm           IF C Flag Reset, Push Address Of Next Instruction To Stack & Jump To 16-Bit Immediate Address
  tst r0,C_FLAG      ; IF (! C_FLAG) {
  subeq sp,2         ;   SP_REG -= 2
  addeq r5,r4,2
  strbeq r5,[r10,sp] ;   STACK = PC_REG + 2
  moveq r5,r5,lsr 8
  addeq r6,sp,1
  strbeq r5,[r10,r6]
  ldrbeq r5,[r10,r4] ;   PC_REG = Imm16Bit
  addeq r12,3        ;   QCycles += 3 }
  add r4,1           ; PC_REG++
  ldrbeq r6,[r10,r4]
  orreq r5,r6,lsl 8
  moveq r4,r5
  addne r4,1         ; ELSE PC_REG++
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $D5 PUSH  DE                Push Register Pair DE To Stack, Decrement Stack Pointer (SP) Twice
  sub sp,2           ; SP_REG -= 2
  strb r2,[r10,sp]   ; STACK = DE_REG
  mov r5,r2,lsr 8
  add r6,sp,1
  strb r5,[r10,r6] 
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $D6 SUB   imm               Subtract 8-Bit Immediate Value From A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (Imm8Bit & $F) < $0) H_SET       ; H Flag Set IF No Borrow From Bit 4
  ldrb r6,[r10,r4]
  and r7,r5,$F
  and r8,r6,$F
  subs r7,r8
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  subs r5,r6         ; A_REG -= Imm8Bit
  orrlt r0,C_FLAG    ; IF (A_REG < $0) C_SET                               ; C Flag Set IF No Borrow
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r4,1           ; PC_REG++
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $D7 RST   10H               Push Present Address To Stack, Jump To Address $0010
  sub sp,2           ; SP_REG -= 2
  strb r4,[r10,sp]   ; STACK = PC_REG
  mov r5,r4,lsr 8
  add r6,sp,1
  strb r5,[r10,r6] 
  mov r4,$0010       ; PC_REG = $0010
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $D8 RET   C                 IF C Flag Set, Pop 2 Bytes From Stack & Jump To Address
  tst r0,C_FLAG      ; IF (C_FLAG) {
  ldrbne r4,[r10,sp] ;   PC_REG = STACK
  addne sp,1         ;   SP_REG++
  ldrbne r5,[r10,sp]
  orrne r4,r5,lsl 8
  addne sp,1         ;   SP_REG++
  addne r12,3        ;   QCycles += 3 }
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $D9 RETI                    Pop 2 Bytes From Stack & Jump To Address, Enable Interrupts
  ldrb r4,[r10,sp]   ; PC_REG = STACK
  add sp,1           ; SP_REG++
  ldrb r5,[r10,sp]
  orr r4,r5,lsl 8
  add sp,1           ; SP_REG++
  mov r5,1           ; IME_FLAG = 1
  strb r5,[r10,IME_FLAG - MEM_MAP]
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $DA JP    C, imm            Jump To 16-Bit Immediate Address IF C Flag Set
  tst r0,C_FLAG      ; IF (C_FLAG) {
  ldrbne r5,[r10,r4] ;   PC_REG = Imm16Bit
  add r4,1           ;   PC_REG++
  ldrbne r6,[r10,r4]
  orrne r5,r6,lsl 8
  movne r4,r5
  addne r12,1        ;   QCycles++ }
  addeq r4,1         ; ELSE PC_REG++
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $DB UNUSED OPCODE           Execution Will Cause GB To Permanently Halt Operation Until Power Down / Power Up
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $DC CALL  C, imm            IF C Flag Set, Push Address Of Next Instruction To Stack & Jump To 16-Bit Immediate Address
  tst r0,C_FLAG      ; IF (C_FLAG) {
  subne sp,2         ;   SP_REG -= 2
  addne r5,r4,2
  strbne r5,[r10,sp] ;   STACK = PC_REG + 2
  movne r5,r5,lsr 8
  addne r6,sp,1
  strbne r5,[r10,r6]  
  ldrbne r5,[r10,r4] ;   PC_REG = Imm16Bit
  addne r12,3        ;   QCycles += 3 }
  add r4,1           ; PC_REG++
  ldrbne r6,[r10,r4]
  orrne r5,r6,lsl 8
  movne r4,r5
  addeq r4,1         ; ELSE PC_REG++
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $DD UNUSED OPCODE           Execution Will Cause GB To Permanently Halt Operation Until Power Down / Power Up
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $DE SBC   A, imm            Subtract 8-Bit Immediate Value + Carry Flag From A
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (Imm8Bit & $F) - C_FLAG < $0) H_SET ; H Flag Set IF No Borrow From Bit 4
  ldrb r6,[r10,r4]
  and r7,r5,$F
  and r8,r6,$F
  sub r7,r8
  and r8,r0,C_FLAG
  subs r7,r8,lsr 4
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  sub r5,r6          ; A_REG -= Imm8Bit - C_FLAG
  subs r5,r8,lsr 4 
  orrlt r0,C_FLAG    ; IF (A_REG < $0) C_SET                               ; C Flag Set IF No Borrow
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r4,1           ; PC_REG++
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $DF RST   18H               Push Present Address To Stack, Jump To Address $0018
  sub sp,2           ; SP_REG -= 2
  strb r4,[r10,sp]   ; STACK = PC_REG
  mov r5,r4,lsr 8
  add r6,sp,1
  strb r5,[r10,r6] 
  mov r4,$0018       ; PC_REG = $0018
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $E0 LD    ($FF00 + imm), A  Load A To Memory Address $FF00 + 8-Bit Immediate Value
  ldrb r5,[r10,r4]   ; MEM_MAP[$FF00 + Imm8Bit] = A_REG
  orr r5,$FF00
  mov r6,r0,lsr 8
  strb r6,[r10,r5]
  add r4,1           ; PC_REG++
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $E1 POP   HL                Pop 2 Bytes Off Stack To Register Pair HL, Increment Stack Pointer (SP) Twice
  ldrb r3,[r10,sp]   ; HL_REG = STACK
  add sp,1           ; SP_REG++
  ldrb r5,[r10,sp] 
  orr r3,r5,lsl 8
  add sp,1           ; SP_REG++
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $E2 LD    (C), A            Load Value A To Address $FF00 + Register C
  and r5,r1,$FF      ; MEM_MAP[$FF00 + C_REG] = A_REG
  orr r5,$FF00
  mov r6,r0,lsr 8
  strb r6,[r10,r5]
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $E3 UNUSED OPCODE           Execution Will Cause GB To Permanently Halt Operation Until Power Down / Power Up
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $E4 UNUSED OPCODE           Execution Will Cause GB To Permanently Halt Operation Until Power Down / Power Up
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $E5 PUSH  HL                Push Register Pair HL To Stack, Decrement Stack Pointer (SP) Twice
  sub sp,2           ; SP_REG -= 2
  strb r3,[r10,sp]   ; STACK = HL_REG
  mov r5,r3,lsr 8
  add r6,sp,1
  strb r5,[r10,r6] 
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $E6 AND   imm               Logical AND 8-Bit Immediate Value With A
  ldrb r5,[r10,r4]   ; A_REG &= Imm8Bit
  mov r5,r5,lsl 8
  orr r5,$FF
  and r0,r5
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + N_FLAG ; C_RESET                                         ; C Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r4,1           ; PC_REG++
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $E7 RST   20H               Push Present Address To Stack, Jump To Address $0020
  sub sp,2           ; SP_REG -= 2
  strb r4,[r10,sp]   ; STACK = PC_REG
  mov r5,r4,lsr 8
  add r6,sp,1
  strb r5,[r10,r6]
  mov r4,$0020       ; PC_REG = $0020
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $E8 ADD   SP, imm           Add 8-Bit Signed Immediate Value To Stack Pointer (SP)
  and r5,sp,$F       ; IF ((SP_REG & $F) + (Imm8bit & $F) & $10) H_SET     ; H Flag Set IF Carry From Bit 3
  ldrb r6,[r10,r4]
  and r7,r6,$F
  add r5,r7
  tst r5,$10
  orrne r0,H_FLAG 
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  ldrsb r5,[r10,r4]  ; SP_REG += Imm8Bit
  add sp,r5        
  tst sp,$10000
  subne sp,$10000
  and r5,sp,$FF      ; IF ((SP_REG & $FF) < Imm8Bit) C_SET                 ; C Flag Set IF Carry From Bit 7
  cmp r5,r6
  orrlt r0,C_FLAG
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 7
  bic r0,N_FLAG + Z_FLAG ; N_RESET                                         ; N Flag Reset
                         ; Z_RESET                                         ; Z Flag Reset
  add r4,1           ; PC_REG++
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $E9 JP    (HL)              Jump To 16-Bit Immediate Address Contained In HL
  mov r4,r3          ; PC_REG = HL_REG
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $EA LD    (imm), A          Load Value A To 16-Bit Immediate Address
  ldrb r5,[r10,r4]   ; MEM_MAP[Imm16Bit] = A_REG
  add r4,1           ; PC_REG++
  ldrb r6,[r10,r4]
  add r5,r6,lsl 8
  mov r6,r0,lsr 8
  strb r6,[r10,r5]
  add r4,1           ; PC_REG++
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $EB UNUSED OPCODE           Execution Will Cause GB To Permanently Halt Operation Until Power Down / Power Up
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $EC UNUSED OPCODE           Execution Will Cause GB To Permanently Halt Operation Until Power Down / Power Up
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $ED UNUSED OPCODE           Execution Will Cause GB To Permanently Halt Operation Until Power Down / Power Up
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $EE XOR   imm               Logical eXclusive OR 8-Bit Immediate Value With A
  ldrb r5,[r10,r4]   ; A_REG ^= Imm8Bit
  mov r5,r5,lsl 8
  eor r0,r5
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r4,1           ; PC_REG++
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $EF RST   28H               Push Present Address To Stack, Jump To Address $0028
  sub sp,2           ; SP_REG -= 2
  strb r4,[r10,sp]   ; STACK = PC_REG
  mov r5,r4,lsr 8
  add r6,sp,1
  strb r5,[r10,r6] 
  mov r4,$0028       ; PC_REG = $0028
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $F0 LD    A, ($FF00 + imm)  Load Memory Address $FF00 + 8-Bit Immediate Value To A
  ldrb r5,[r10,r4]   ; A_REG = MEM_MAP[$FF00 + Imm8Bit]
  orr r5,$FF00
  ldrb r5,[r10,r5]
  and r0,$FF
  orr r0,r5,lsl 8
  add r4,1           ; PC_REG++
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $F1 POP   AF                Pop 2 Bytes Off Stack To Register Pair AF, Increment Stack Pointer (SP) Twice, Mask Flag Register With $F0
  ldrb r0,[r10,sp]   ; AF_REG = STACK
  and r0,$F0         ; F_REG &= $F0
  add sp,1           ; SP_REG++
  ldrb r5,[r10,sp]
  orr r0,r5,lsl 8
  add sp,1           ; SP_REG++
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $F2 LD    A, (C)            Load Value At Address $FF00 + Register C To A
  and r5,r1,$FF      ; A_REG = MEM_MAP[$FF00 + C_REG]
  orr r5,$FF00
  ldrb r5,[r10,r5]
  and r0,$FF
  orr r0,r5,lsl 8
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $F3 DI                      Disable Interrupts 2 Instructions After DI Is Executed
  mov r5,0           ; IME_FLAG = 0
  strb r5,[r10,IME_FLAG - MEM_MAP]
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $F4 UNUSED OPCODE           Execution Will Cause GB To Permanently Halt Operation Until Power Down / Power Up
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $F5 PUSH  AF                Push Register Pair AF To Stack, Decrement Stack Pointer (SP) Twice
  sub sp,2           ; SP_REG -= 2
  strb r0,[r10,sp]   ; STACK = AF_REG
  mov r5,r0,lsr 8
  add r6,sp,1
  strb r5,[r10,r6] 
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $F6 OR    imm               Logical OR 8-Bit Immediate Value With A
  ldrb r5,[r10,r4]   ; A_REG |= Imm8Bit
  mov r5,r5,lsl 8
  orr r0,r5
  tst r0,$FF00       ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r4,1           ; PC_REG++
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $F7 RST   30H               Push Present Address To Stack, Jump To Address $0030
  sub sp,2           ; SP_REG -= 2
  strb r4,[r10,sp]   ; STACK = PC_REG
  mov r5,r4,lsr 8
  add r6,sp,1
  strb r5,[r10,r6] 
  mov r4,$0030       ; PC_REG = $0030
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $F8 LDHL  SP, imm           Load SP + 8-Bit Signed Immediate Value Effective Address To HL
  and r5,sp,$F       ; IF ((SP_REG & $F) + (Imm8bit & $F) & $10) H_SET     ; H Flag Set IF Carry From Bit 3
  ldrb r6,[r10,r4]
  and r7,r6,$F
  add r5,r7
  tst r5,$10
  orrne r0,H_FLAG 
  biceq r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF No Carry From Bit 3
  ldrsb r5,[r10,r4]  ; HL_REG = SP_REG + Imm8Bit
  add r3,sp,r5        
  tst r3,$10000
  subne r3,$10000
  and r5,r3,$FF      ; IF ((HL_REG & $FF) < Imm8Bit) C_SET                 ; C Flag Set IF Carry From Bit 7
  cmp r5,r6
  orrlt r0,C_FLAG
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF No Carry From Bit 7
  bic r0,N_FLAG + Z_FLAG ; N_RESET                                         ; N Flag Reset
                         ; Z_RESET                                         ; Z Flag Reset
  add r4,1           ; PC_REG++
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $F9 LD    SP, HL            Load HL To Stack Pointer (SP)
  mov sp,r3          ; SP_REG = HL_REG
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $FA LD    A, (imm)          Load 16-Bit Immediate Value To A
  ldrb r5,[r10,r4]   ; A_REG = MEM_MAP[Imm16Bit]
  add r4,1           ; PC_REG++
  ldrb r6,[r10,r4]
  orr r5,r6,lsl 8
  ldrb r6,[r10,r5]
  and r0,$FF
  orr r0,r6,lsl 8
  add r4,1           ; PC_REG++
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $FB EI                      Enable Interrupts 2 Instructions After EI Is Executed
  mov r5,1           ; IME_FLAG = 1
  strb r5,[r10,IME_FLAG - MEM_MAP]
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $FC UNUSED OPCODE           Execution Will Cause GB To Permanently Halt Operation Until Power Down / Power Up
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $FD UNUSED OPCODE           Execution Will Cause GB To Permanently Halt Operation Until Power Down / Power Up
  add r12,1          ; QCycles++
  bx lr
align 256
  ; $FE CP    imm               Compare A With 8-Bit Immediate Value
  mov r5,r0,lsr 8    ; IF ((A_REG & $F) - (Imm8Bit & $F) < $0) H_SET       ; H Flag Set IF No Borrow From Bit 4
  ldrb r6,[r10,r4]
  and r7,r5,$F
  and r8,r6,$F
  subs r7,r8
  orrlt r0,H_FLAG
  bicge r0,H_FLAG    ; ELSE H_RESET                                        ; H Flag Reset IF Borrow From Bit 4
  cmp r5,r6          ; IF (A_REG < Imm8Bit) C_SET                          ; C Flag Set IF No Borrow
  orrlt r0,C_FLAG
  bicge r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset IF Borrow
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  orr r0,N_FLAG      ; N_SET                                               ; N Flag Set
  add r4,1           ; PC_REG++
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $FF RST   38H               Push Present Address To Stack, Jump To Address $0038
  sub sp,2           ; SP_REG -= 2
  strb r4,[r10,sp]   ; STACK = PC_REG
  mov r5,r4,lsr 8
  add r6,sp,1
  strb r5,[r10,r6]
  mov r4,$0038       ; PC_REG = $0038
  add r12,4          ; QCycles += 4
  bx lr

align 256
CPU_CB_INST:
  ; $00 RLC   B                 Rotate Register B Left, Old Bit 7 To Carry Flag
  mov r5,r1,lsr 7    ; B_REG = (B_REG << 1) | (B_REG >> 7)
  and r5,$FE
  orrs r5,r1,lsr 15
  and r1,$FF
  orr r1,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! B_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  tst r5,1           ; IF (B_REG & 1) C_SET                                ; C Flag Set To Old Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $01 RLC   C                 Rotate Register C Left, Old Bit 7 To Carry Flag
  and r5,r1,$FF      ; C_REG = (C_REG << 1) | (C_REG >> 7)
  mov r5,r5,lsl 1
  tst r5,$100
  orrne r5,1           
  orrne r0,C_FLAG    ; IF (C_REG & 1) C_SET                                ; C Flag Set To Old Bit 7
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  ands r5,$FF
  and r1,$FF00
  orr r1,r5
  orreq r0,Z_FLAG    ; IF (! C_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $02 RLC   D                 Rotate Register D Left, Old Bit 7 To Carry Flag
  mov r5,r2,lsr 7    ; D_REG = (D_REG << 1) | (D_REG >> 7)
  and r5,$FE
  orrs r5,r2,lsr 15
  and r2,$FF
  orr r2,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! D_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  tst r5,1           ; IF (D_REG & 1) C_SET                                ; C Flag Set To Old Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $03 RLC   E                 Rotate Register E Left, Old Bit 7 To Carry Flag
  and r5,r2,$FF      ; E_REG = (E_REG << 1) | (E_REG >> 7)
  mov r5,r5,lsl 1
  tst r5,$100
  orrne r5,1 
  orrne r0,C_FLAG    ; IF (E_REG & 1) C_SET                                ; C Flag Set To Old Bit 7
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  ands r5,$FF
  and r2,$FF00
  orr r2,r5
  orreq r0,Z_FLAG    ; IF (! E_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $04 RLC   H                 Rotate Register H Left, Old Bit 7 To Carry Flag
  mov r5,r3,lsr 7    ; H_REG = (H_REG << 1) | (H_REG >> 7)
  and r5,$FE
  orrs r5,r3,lsr 15
  and r3,$FF
  orr r3,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! H_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  tst r5,1           ; IF (H_REG & 1) C_SET                                ; C Flag Set To Old Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $05 RLC   L                 Rotate Register L Left, Old Bit 7 To Carry Flag
  and r5,r3,$FF      ; L_REG = (L_REG << 1) | (L_REG >> 7)
  mov r5,r5,lsl 1
  tst r5,$100
  orrne r5,1
  orrne r0,C_FLAG    ; IF (L_REG & 1) C_SET                                ; C Flag Set To Old Bit 7
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  ands r5,$FF
  and r3,$FF00
  orr r3,r5
  orreq r0,Z_FLAG    ; IF (! L_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $06 RLC   (HL)              Rotate 8-Bit Value From Address In HL Left, Old Bit 7 To Carry Flag
  ldrb r5,[r10,r3]   ; MEM_MAP[HL_REG] = (MEM_MAP[HL_REG] << 1) | (MEM_MAP[HL_REG] >> 7)
  mov r5,r5,lsl 1
  tst r5,$100
  orrne r5,1
  strb r5,[r10,r3]
  orrne r0,C_FLAG    ; IF (MEM_MAP[HL_REG] & 1) C_SET                      ; C Flag Set To Old Bit 7
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  tst r5,$FF         ; IF (! MEM_MAP[HL_REG]) Z_SET                        ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $07 RLC   A                 Rotate Register A Left, Old Bit 7 To Carry Flag
  mov r5,r0,lsr 7    ; A_REG = (A_REG << 1) | (A_REG >> 7)
  ands r5,$FE
  orrs r5,r0,lsr 15
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  tst r5,1           ; IF (A_REG & 1) C_SET                                ; C Flag Set To Old Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $08 RRC   B                 Rotate Register B Right, Old Bit 0 To Carry Flag
  tst r1,$100        ; IF (B_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  mov r5,r1,lsr 9    ; B_REG = (B_REG >> 1) | (B_REG << 7)
  orrne r5,$80
  and r1,$FF
  orr r1,r5,lsl 8
  cmp r5,0           ; IF (! B_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $09 RRC   C                 Rotate Register C Right, Old Bit 0 To Carry Flag
  tst r1,1           ; IF (C_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  and r5,r1,$FF      ; C_REG = (C_REG >> 1) | (C_REG << 7)
  orrne r5,$100
  movs r5,r5,lsr 1
  and r1,$FF00
  orr r1,r5
  orreq r0,Z_FLAG    ; IF (! C_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $0A RRC   D                 Rotate Register D Right, Old Bit 0 To Carry Flag
  tst r2,$100        ; IF (D_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  mov r5,r2,lsr 9    ; D_REG = (D_REG >> 1) | (D_REG << 7)
  orrne r5,$80
  and r2,$FF
  orr r2,r5,lsl 8
  cmp r5,0           ; IF (! D_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $0B RRC   E                 Rotate Register E Right, Old Bit 0 To Carry Flag
  tst r2,1           ; IF (E_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  and r5,r2,$FF      ; E_REG = (E_REG >> 1) | (E_REG << 7)
  orrne r5,$100
  movs r5,r5,lsr 1
  and r2,$FF00
  orr r2,r5 
  orreq r0,Z_FLAG    ; IF (! E_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $0C RRC   H                 Rotate Register H Right, Old Bit 0 To Carry Flag
  tst r3,$100        ; IF (H_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  mov r5,r3,lsr 9    ; H_REG = (H_REG >> 1) | (H_REG << 7)
  orrne r5,$80
  and r3,$FF
  orr r3,r5,lsl 8
  cmp r5,0           ; IF (! H_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $0D RRC   L                 Rotate Register L Right, Old Bit 0 To Carry Flag
  tst r3,1           ; IF (L_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  and r5,r3,$FF      ; L_REG = (L_REG >> 1) | (L_REG << 7)
  orrne r5,$100
  movs r5,r5,lsr 1
  and r3,$FF00
  orr r3,r5
  orreq r0,Z_FLAG    ; IF (! L_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $0E RRC   (HL)              Rotate 8-Bit Value From Address In HL Right, Old Bit 0 To Carry Flag
  ldrb r5,[r10,r3] 
  tst r5,1           ; IF (MEM_MAP[HL_REG] & 1) C_SET                      ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  orrne r5,$100
  movs r5,r5,lsr 1   ; MEM_MAP[HL_REG] = (MEM_MAP[HL_REG] >> 1) | (MEM_MAP[HL_REG] << 7)
  strb r5,[r10,r3]
  orreq r0,Z_FLAG    ; IF (! MEM_MAP[HL_REG]) Z_SET                        ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $0F RRC   A                 Rotate Register A Right, Old Bit 0 To Carry Flag
  tst r0,$100        ; IF (A_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  mov r5,r0,lsr 9    ; A_REG = (A_REG >> 1) | (A_REG << 7)
  orrne r5,$80
  and r0,$FF
  orr r0,r5,lsl 8
  cmp r5,0           ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $10 RL    B                 Rotate Register B Left, Through Carry Flag
  mov r5,r1,lsr 7    ; B_REG = (B_REG << 1) | (C_FLAG)
  tst r0,C_FLAG
  orrne r5,1
  biceq r5,1
  tst r5,$100        ; IF (B_REG & $100) C_SET                             ; C Flag Set To Old Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  ands r5,$FF
  and r1,$FF
  orr r1,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! B_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $11 RL    C                 Rotate Register C Left, Through Carry Flag
  and r5,r1,$FF      ; C_REG = (C_REG << 1) | (C_FLAG)
  mov r5,r5,lsl 1
  tst r0,C_FLAG
  orrne r5,1
  biceq r5,1
  tst r5,$100        ; IF (C_REG & $100) C_SET                             ; C Flag Set To Old Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  ands r5,$FF
  and r1,$FF00
  orr r1,r5 
  orreq r0,Z_FLAG    ; IF (! C_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $12 RL    D                 Rotate Register D Left, Through Carry Flag
  mov r5,r2,lsr 7    ; D_REG = (D_REG << 1) | (C_FLAG)
  tst r0,C_FLAG
  orrne r5,1
  biceq r5,1
  tst r5,$100        ; IF (D_REG & $100) C_SET                             ; C Flag Set To Old Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  ands r5,$FF
  and r2,$FF
  orr r2,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! D_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $13 RL    E                 Rotate Register E Left, Through Carry Flag
  and r5,r2,$FF      ; E_REG = (E_REG << 1) | (C_FLAG)
  mov r5,r5,lsl 1
  tst r0,C_FLAG
  orrne r5,1
  biceq r5,1
  tst r5,$100        ; IF (E_REG & $100) C_SET                             ; C Flag Set To Old Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  ands r5,$FF
  and r2,$FF00
  orr r2,r5
  orreq r0,Z_FLAG    ; IF (! E_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $14 RL    H                 Rotate Register H Left, Through Carry Flag
  mov r5,r3,lsr 7    ; H_REG = (H_REG << 1) | (C_FLAG)
  tst r0,C_FLAG
  orrne r5,1
  biceq r5,1
  tst r5,$100        ; IF (H_REG & $100) C_SET                             ; C Flag Set To Old Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  ands r5,$FF
  and r3,$FF
  orr r3,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! H_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $15 RL    L                 Rotate Register L Left, Through Carry Flag
  and r5,r3,$FF      ; L_REG = (L_REG << 1) | (C_FLAG)
  mov r5,r5,lsl 1
  tst r0,C_FLAG
  orrne r5,1
  biceq r5,1
  tst r5,$100        ; IF (L_REG & $100) C_SET                             ; C Flag Set To Old Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  ands r5,$FF
  and r3,$FF00
  orr r3,r5
  orreq r0,Z_FLAG    ; IF (! L_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $16 RL    (HL)              Rotate 8-Bit Value From Address In HL Left, Through Carry Flag
  ldrb r5,[r10,r3]   ; MEM_MAP[HL_REG] = (MEM_MAP[HL_REG] << 1) | (C_FLAG)
  mov r5,r5,lsl 1
  tst r0,C_FLAG
  orrne r5,1
  biceq r5,1
  tst r5,$100        ; IF (MEM_MAP[HL_REG] & $100) C_SET                   ; C Flag Set To Old Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  strb r5,[r10,r3]
  tst r5,$FF         ; IF (! MEM_MAP[HL_REG]) Z_SET                        ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $17 RL    A                 Rotate Register A Left, Through Carry Flag
  mov r5,r0,lsr 7    ; A_REG = (A_REG << 1) | (C_FLAG)
  tst r0,C_FLAG
  orrne r5,1
  biceq r5,1
  tst r5,$100        ; IF (A_REG & $100) C_SET                             ; C Flag Set To Old Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $18 RR    B                 Rotate Register B Right, Through Carry Flag
  mov r5,r1,lsr 9    ; B_REG = (B_REG >> 1) | (C_FLAG << 7)
  tst r0,C_FLAG
  orrne r5,$80
  biceq r5,$80
  tst r1,$100        ; IF (B_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  ands r5,$FF
  and r1,$FF
  orr r1,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! B_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $19 RR    C                 Rotate Register C Right, Through Carry Flag
  and r5,r1,$FF      ; C_REG = (C_REG >> 1) | (C_FLAG << 7)
  mov r5,r5,lsr 1
  tst r0,C_FLAG
  orrne r5,$80
  biceq r5,$80
  tst r1,$1          ; IF (C_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  ands r5,$FF
  and r1,$FF00
  orr r1,r5
  orreq r0,Z_FLAG    ; IF (! C_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $1A RR    D                 Rotate Register D Right, Through Carry Flag
  mov r5,r2,lsr 9    ; D_REG = (D_REG >> 1) | (C_FLAG << 7)
  tst r0,C_FLAG
  orrne r5,$80
  biceq r5,$80
  tst r2,$100        ; IF (D_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  ands r5,$FF
  and r2,$FF
  orr r2,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! D_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $1B RR    E                 Rotate Register E Right, Through Carry Flag
  and r5,r2,$FF      ; E_REG = (E_REG >> 1) | (C_FLAG << 7)
  mov r5,r5,lsr 1
  tst r0,C_FLAG
  orrne r5,$80
  biceq r5,$80
  tst r2,$1          ; IF (E_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  ands r5,$FF
  and r2,$FF00
  orr r2,r5
  orreq r0,Z_FLAG    ; IF (! E_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $1C RR    H                 Rotate Register H Right, Through Carry Flag
  mov r5,r3,lsr 9    ; H_REG = (H_REG >> 1) | (C_FLAG << 7)
  tst r0,C_FLAG
  orrne r5,$80
  biceq r5,$80
  tst r3,$100        ; IF (H_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  ands r5,$FF
  and r3,$FF
  orr r3,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! H_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $1D RR    L                 Rotate Register L Right, Through Carry Flag
  and r5,r3,$FF      ; L_REG = (L_REG >> 1) | (C_FLAG << 7)
  mov r5,r5,lsr 1
  tst r0,C_FLAG
  orrne r5,$80
  biceq r5,$80
  tst r3,$1          ; IF (L_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  ands r5,$FF
  and r3,$FF00
  orr r3,r5
  orreq r0,Z_FLAG    ; IF (! L_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $1E RR    (HL)              Rotate 8-Bit Value From Address In HL Right, Through Carry Flag
  ldrb r5,[r10,r3]   ; MEM_MAP[HL_REG] = (MEM_MAP[HL_REG] >> 1) | (C_FLAG << 7)
  mov r6,r5
  mov r5,r5,lsr 1
  tst r0,C_FLAG
  orrne r5,$80
  biceq r5,$80
  tst r6,$1          ; IF (MEM_MAP[HL_REG] & 1) C_SET                      ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  strb r5,[r10,r3]
  tst r5,$FF         ; IF (! MEM_MAP[HL_REG]) Z_SET                        ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $1F RR    A                 Rotate Register A Right, Through Carry Flag
  mov r5,r0,lsr 9    ; A_REG = (A_REG >> 1) | (C_FLAG << 7)
  tst r0,C_FLAG
  orrne r5,$80
  biceq r5,$80
  tst r0,$100        ; IF (A_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $20 SLA   B                 Shift Register B Left, Into Carry Flag
  mov r5,r1,lsr 7    ; B_REG <<= 1
  bic r5,1
  tst r5,$100        ; IF (B_REG & $100) C_SET                             ; C Flag Set To Old Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  ands r5,$FF
  and r1,$FF
  orr r1,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! B_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $21 SLA   C                 Shift Register C Left, Into Carry Flag
  and r5,r1,$FF      ; C_REG <<= 1
  mov r5,r5,lsl 1
  tst r5,$100        ; IF (C_REG & $100) C_SET                             ; C Flag Set To Old Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  ands r5,$FF
  and r1,$FF00
  orr r1,r5
  orreq r0,Z_FLAG    ; IF (! C_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $22 SLA   D                 Shift Register D Left, Into Carry Flag
  mov r5,r2,lsr 7    ; D_REG <<= 1
  bic r5,1
  tst r5,$100        ; IF (D_REG & $100) C_SET                             ; C Flag Set To Old Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  ands r5,$FF
  and r2,$FF
  orr r2,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! D_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $23 SLA   E                 Shift Register E Left, Into Carry Flag
  and r5,r2,$FF      ; E_REG <<= 1
  mov r5,r5,lsl 1
  tst r5,$100        ; IF (E_REG & $100) C_SET                             ; C Flag Set To Old Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  ands r5,$FF
  and r2,$FF00
  orr r2,r5
  orreq r0,Z_FLAG    ; IF (! E_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $24 SLA   H                 Shift Register H Left, Into Carry Flag
  mov r5,r3,lsr 7    ; H_REG <<= 1
  bic r5,1
  tst r5,$100        ; IF (H_REG & $100) C_SET                             ; C Flag Set To Old Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  ands r5,$FF
  and r3,$FF
  orr r3,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! H_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $25 SLA   L                 Shift Register L Left, Into Carry Flag
  and r5,r3,$FF      ; L_REG <<= 1
  mov r5,r5,lsl 1
  tst r5,$100        ; IF (L_REG & $100) C_SET                             ; C Flag Set To Old Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  ands r5,$FF
  and r3,$FF00
  orr r3,r5
  orreq r0,Z_FLAG    ; IF (! L_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $26 SLA   (HL)              Shift 8-Bit Value From Address In HL Left, Into Carry Flag
  ldrb r5,[r10,r3]   ; MEM_MAP[HL_REG] <<= 1
  mov r5,r5,lsl 1
  tst r5,$100        ; IF (MEM_MAP[HL_REG] & $100) C_SET                   ; C Flag Set To Old Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  strb r5,[r10,r3]
  tst r5,$FF         ; IF (! MEM_MAP[HL_REG]) Z_SET                        ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $27 SLA   A                 Shift Register A Left, Into Carry Flag
  mov r5,r0,lsr 7    ; A_REG <<= 1
  bic r5,1
  tst r5,$100        ; IF (A_REG & $100) C_SET                             ; C Flag Set To Old Bit 7
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 7
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $28 SRA   B                 Shift Register B Right, Into Carry Flag (MSB Does Not Change)
  mov r5,r1,lsr 9
  tst r1,$100        ; IF (B_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  tst r1,$8000       ; IF ((B_REG>>7) & 1) B_REG = (B_REG>>1) + $80
  orrne r5,$80       ; ELSE B_REG >>= 1
  ands r5,$FF
  and r1,$FF
  orr r1,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! B_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $29 SRA   C                 Shift Register C Right, Into Carry Flag (MSB Does Not Change)
  and r5,r1,$FF
  mov r5,r5,lsr 1
  tst r1,$1          ; IF (C_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  tst r1,$80         ; IF ((C_REG>>7) & 1) C_REG = (C_REG>>1) + $80
  orrne r5,$80       ; ELSE C_REG >>= 1
  ands r5,$FF
  and r1,$FF00
  orr r1,r5
  orreq r0,Z_FLAG    ; IF (! C_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $2A SRA   D                 Shift Register D Right, Into Carry Flag (MSB Does Not Change)
  mov r5,r2,lsr 9
  tst r2,$100        ; IF (D_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  tst r2,$8000       ; IF ((D_REG>>7) & 1) D_REG = (D_REG>>1) + $80
  orrne r5,$80       ; ELSE D_REG >>= 1
  ands r5,$FF
  and r2,$FF
  orr r2,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! D_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $2B SRA   E                 Shift Register E Right, Into Carry Flag (MSB Does Not Change)
  and r5,r2,$FF
  mov r5,r5,lsr 1
  tst r2,$1          ; IF (E_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  tst r2,$80         ; IF ((E_REG>>7) & 1) E_REG = (E_REG>>1) + $80
  orrne r5,$80       ; ELSE E_REG >>= 1
  ands r5,$FF
  and r2,$FF00
  orr r2,r5
  orreq r0,Z_FLAG    ; IF (! E_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $2C SRA   H                 Shift Register H Right, Into Carry Flag (MSB Does Not Change)
  mov r5,r3,lsr 9
  tst r3,$100        ; IF (H_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  tst r3,$8000       ; IF ((H_REG>>7) & 1) H_REG = (H_REG>>1) + $80
  orrne r5,$80       ; ELSE H_REG >>= 1
  ands r5,$FF
  and r3,$FF
  orr r3,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! H_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $2D SRA   L                 Shift Register L Right, Into Carry Flag (MSB Does Not Change)
  and r5,r3,$FF
  mov r5,r5,lsr 1
  tst r3,$1          ; IF (L_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  tst r3,$80         ; IF ((L_REG>>7) & 1) L_REG = (L_REG>>1) + $80
  orrne r5,$80       ; ELSE L_REG >>= 1
  ands r5,$FF
  and r3,$FF00
  orr r3,r5
  orreq r0,Z_FLAG    ; IF (! L_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $2E SRA   (HL)              Shift 8-Bit Value From Address In HL Right, Into Carry Flag (MSB Does Not Change)
  ldrb r5,[r10,r3]
  mov r6,r5
  mov r5,r5,lsr 1
  tst r6,$1          ; IF (MEM_MAP[HL_REG] & 1) C_SET                      ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  tst r6,$80         ; IF ((MEM_MAP[HL_REG]>>7) & 1) MEM_MAP[HL_REG] = (MEM_MAP[HL_REG]>>1) + $80
  orrne r5,$80       ; ELSE MEM_MAP[HL_REG] >>= 1
  strb r5,[r10,r3]
  tst r5,$FF         ; IF (! MEM_MAP[HL_REG]) Z_SET                        ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $2F SRA   A                 Shift Register A Right, Into Carry Flag (MSB Does Not Change)
  mov r5,r0,lsr 9
  tst r0,$100        ; IF (A_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  tst r0,$8000       ; IF ((A_REG>>7) & 1) A_REG = (A_REG>>1) + $80
  orrne r5,$80       ; ELSE A_REG >>= 1
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $30 SWAP  B                 Swap Upper & Lower Nibbles Of B
  mov r5,r1,lsr 12   ; B_REG = (B_REG>>4) | (B_REG<<4)
  mov r6,r1,lsr 4
  and r6,$F0
  orrs r5,r6
  and r1,$FF
  orr r1,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! B_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $31 SWAP  C                 Swap Upper & Lower Nibbles Of C
  mov r5,r1,lsl 4    ; C_REG = (C_REG>>4) | (C_REG<<4)
  mov r6,r1,lsr 4
  and r6,$F
  orr r5,r6
  ands r5,$FF
  and r1,$FF00
  orr r1,r5
  orreq r0,Z_FLAG    ; IF (! C_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $32 SWAP  D                 Swap Upper & Lower Nibbles Of D
  mov r5,r2,lsr 12   ; D_REG = (D_REG>>4) | (D_REG<<4)
  mov r6,r2,lsr 4
  and r6,$F0
  orrs r5,r6
  and r2,$FF
  orr r2,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! D_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $33 SWAP  E                 Swap Upper & Lower Nibbles Of E
  mov r5,r2,lsl 4    ; E_REG = (E_REG>>4) | (E_REG<<4)
  mov r6,r2,lsr 4
  and r6,$F
  orr r5,r6
  ands r5,$FF
  and r2,$FF00
  orr r2,r5
  orreq r0,Z_FLAG    ; IF (! E_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $34 SWAP  H                 Swap Upper & Lower Nibbles Of H
  mov r5,r3,lsr 12   ; H_REG = (H_REG>>4) | (H_REG<<4)
  mov r6,r3,lsr 4
  and r6,$F0
  orrs r5,r6
  and r3,$FF
  orr r3,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! H_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $35 SWAP  L                 Swap Upper & Lower Nibbles Of L
  mov r5,r3,lsl 4    ; L_REG = (L_REG>>4) | (L_REG<<4)
  mov r6,r3,lsr 4
  and r6,$F
  orr r5,r6
  ands r5,$FF
  and r3,$FF00
  orr r3,r5
  orreq r0,Z_FLAG    ; IF (! L_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $36 SWAP  (HL)              Swap Upper & Lower Nibbles Of 8-Bit Value From Address In HL
  ldrb r5,[r10,r3]   ; MEM_MAP[HL_REG] = (MEM_MAP[HL_REG]>>4) | (MEM_MAP[HL_REG]<<4)
  mov r6,r5,lsr 4
  mov r5,r5,lsl 4
  and r6,$F
  orrs r5,r6
  strb r5,[r10,r3]
  orreq r0,Z_FLAG    ; IF (! MEM_MAP[HL_REG]) Z_SET                        ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $37 SWAP  A                 Swap Upper & Lower Nibbles Of A
  mov r5,r0,lsr 12   ; A_REG = (A_REG>>4) | (A_REG<<4)
  mov r6,r0,lsr 4
  and r6,$F0
  orrs r5,r6
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! H_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,C_FLAG + H_FLAG + N_FLAG ; C_RESET                                ; C Flag Reset
                                  ; H_RESET                                ; H Flag Reset
                                  ; N_RESET                                ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $38 SRL   B                 Shift Register B Right, Into Carry Flag
  mov r5,r1,lsr 9    ; B_REG >>= 1
  tst r1,$100        ; IF (B_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  ands r5,$FF
  and r1,$FF
  orr r1,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! B_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $39 SRL   C                 Shift Register C Right, Into Carry Flag
  and r5,r1,$FF      ; C_REG >>= 1
  mov r5,r5,lsr 1
  tst r1,$1          ; IF (C_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  ands r5,$FF
  and r1,$FF00
  orr r1,r5
  orreq r0,Z_FLAG    ; IF (! C_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $3A SRL   D                 Shift Register D Right, Into Carry Flag
  mov r5,r2,lsr 9    ; D_REG >>= 1
  tst r2,$100        ; IF (D_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  ands r5,$FF
  and r2,$FF
  orr r2,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! D_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $3B SRL   E                 Shift Register E Right, Into Carry Flag
  and r5,r2,$FF      ; E_REG >>= 1
  mov r5,r5,lsr 1
  tst r2,$1          ; IF (E_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  ands r5,$FF
  and r2,$FF00
  orr r2,r5
  orreq r0,Z_FLAG    ; IF (! E_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $3C SRL   H                 Shift Register H Right, Into Carry Flag
  mov r5,r3,lsr 9    ; H_REG >>= 1
  tst r3,$100        ; IF (H_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  ands r5,$FF
  and r3,$FF
  orr r3,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! H_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $3D SRL   L                 Shift Register L Right, Into Carry Flag
  and r5,r3,$FF      ; L_REG >>= 1
  mov r5,r5,lsr 1
  tst r3,$1          ; IF (L_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  ands r5,$FF
  and r3,$FF00
  orr r3,r5
  orreq r0,Z_FLAG    ; IF (! L_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $3E SRL   (HL)              Shift 8-Bit Value From Address In HL Right, Into Carry Flag
  ldrb r5,[r10,r3]   ; MEM_MAP[HL_REG] >>= 1
  mov r6,r5
  mov r5,r5,lsr 1
  tst r6,$1          ; IF (MEM_MAP[HL_REG] & 1) C_SET                      ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  strb r5,[r10,r3]
  tst r5,$FF         ; IF (! MEM_MAP[HL_REG]) Z_SET                        ; Z Flag Set IF Result Is Zero
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $3F SRL   A                 Shift Register A Right, Into Carry Flag
  mov r5,r0,lsr 9    ; A_REG >>= 1
  tst r0,$100        ; IF (A_REG & 1) C_SET                                ; C Flag Set To Old Bit 0
  orrne r0,C_FLAG
  biceq r0,C_FLAG    ; ELSE C_RESET                                        ; C Flag Reset To Old Bit 0
  ands r5,$FF
  and r0,$FF
  orr r0,r5,lsl 8
  orreq r0,Z_FLAG    ; IF (! A_REG) Z_SET                                  ; Z Flag Set IF Result Is Zero
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Result Is Not Zero
  bic r0,H_FLAG + N_FLAG ; H_RESET                                         ; H Flag Reset
                         ; N_RESET                                         ; N Flag Reset
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $40 BIT   0, B              Test Bit 0 In Register B
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r1,$0100       ; IF (! (B_REG & $01)) Z_SET                          ; Z Flag Set IF Bit 0 Of Register B Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 0 Of Register B Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $41 BIT   0, C              Test Bit 0 In Register C
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r1,$01         ; IF (! (C_REG & $01)) Z_SET                          ; Z Flag Set IF Bit 0 Of Register C Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 0 Of Register C Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $42 BIT   0, D              Test Bit 0 In Register D
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r2,$0100       ; IF (! (D_REG & $01)) Z_SET                          ; Z Flag Set IF Bit 0 Of Register D Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 0 Of Register D Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $43 BIT   0, E              Test Bit 0 In Register E
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r2,$01         ; IF (! (E_REG & $01)) Z_SET                          ; Z Flag Set IF Bit 0 Of Register E Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 0 Of Register E Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $44 BIT   0, H              Test Bit 0 In Register H
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r3,$0100       ; IF (! (H_REG & $01)) Z_SET                          ; Z Flag Set IF Bit 0 Of Register H Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 0 Of Register H Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $45 BIT   0, L              Test Bit 0 In Register L
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r3,$01         ; IF (! (L_REG & $01)) Z_SET                          ; Z Flag Set IF Bit 0 Of Register L Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 0 Of Register L Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $46 BIT   0, (HL)           Test Bit 0 In 8-Bit Value Of Address In Register HL
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  ldrb r5,[r10,r3]
  tst r5,$01         ; IF (! (MEM_MAP[HL_REG] & $01)) Z_SET                ; Z Flag Set IF Bit 0 Of 8-Bit Value Of Address In Register HL Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 0 Of 8-Bit Value Of Address In Register HL Is 1
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $47 BIT   0, A              Test Bit 0 In Register A
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r0,$0100       ; IF (! (A_REG & $01)) Z_SET                          ; Z Flag Set IF Bit 0 Of Register A Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 0 Of Register A Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $48 BIT   1, B              Test Bit 1 In Register B
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r1,$0200       ; IF (! (B_REG & $02)) Z_SET                          ; Z Flag Set IF Bit 1 Of Register B Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 1 Of Register B Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $49 BIT   1, C              Test Bit 1 In Register C
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r1,$02         ; IF (! (C_REG & $02)) Z_SET                          ; Z Flag Set IF Bit 1 Of Register C Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 1 Of Register C Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $4A BIT   1, D              Test Bit 1 In Register D
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r2,$0200       ; IF (! (D_REG & $02)) Z_SET                          ; Z Flag Set IF Bit 1 Of Register D Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 1 Of Register D Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $4B BIT   1, E              Test Bit 1 In Register E
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r2,$02         ; IF (! (E_REG & $02)) Z_SET                          ; Z Flag Set IF Bit 1 Of Register E Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 1 Of Register E Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $4C BIT   1, H              Test Bit 1 In Register H
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r3,$0200       ; IF (! (H_REG & $02)) Z_SET                          ; Z Flag Set IF Bit 1 Of Register H Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 1 Of Register H Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $4D BIT   1, L              Test Bit 1 In Register L
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r3,$02         ; IF (! (L_REG & $02)) Z_SET                          ; Z Flag Set IF Bit 1 Of Register L Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 1 Of Register L Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $4E BIT   1, (HL)           Test Bit 1 In 8-Bit Value Of Address In Register HL
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  ldrb r5,[r10,r3]
  tst r5,$02         ; IF (! (MEM_MAP[HL_REG] & $02)) Z_SET                ; Z Flag Set IF Bit 1 Of 8-Bit Value Of Address In Register HL Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 1 Of 8-Bit Value Of Address In Register HL Is 1
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $4F BIT   1, A              Test Bit 1 In Register A
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r0,$0200       ; IF (! (A_REG & $02)) Z_SET                          ; Z Flag Set IF Bit 1 Of Register A Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 1 Of Register A Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $50 BIT   2, B              Test Bit 2 In Register B
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r1,$0400       ; IF (! (B_REG & $04)) Z_SET                          ; Z Flag Set IF Bit 2 Of Register B Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 2 Of Register B Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $51 BIT   2, C              Test Bit 2 In Register C
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r1,$04         ; IF (! (C_REG & $04)) Z_SET                          ; Z Flag Set IF Bit 2 Of Register C Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 2 Of Register C Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $52 BIT   2, D              Test Bit 2 In Register D
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r2,$0400       ; IF (! (D_REG & $04)) Z_SET                          ; Z Flag Set IF Bit 2 Of Register D Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 2 Of Register D Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $53 BIT   2, E              Test Bit 2 In Register E
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r2,$04         ; IF (! (E_REG & $04)) Z_SET                          ; Z Flag Set IF Bit 2 Of Register E Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 2 Of Register E Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $54 BIT   2, H              Test Bit 2 In Register H
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r3,$0400       ; IF (! (H_REG & $04)) Z_SET                          ; Z Flag Set IF Bit 2 Of Register H Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 2 Of Register H Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $55 BIT   2, L              Test Bit 2 In Register L
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r3,$04         ; IF (! (L_REG & $04)) Z_SET                          ; Z Flag Set IF Bit 2 Of Register L Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 2 Of Register L Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $56 BIT   2, (HL)           Test Bit 2 In 8-Bit Value Of Address In Register HL
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  ldrb r5,[r10,r3]
  tst r5,$04         ; IF (! (MEM_MAP[HL_REG] & $04)) Z_SET                ; Z Flag Set IF Bit 2 Of 8-Bit Value Of Address In Register HL Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 2 Of 8-Bit Value Of Address In Register HL Is 1
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $57 BIT   2, A              Test Bit 2 In Register A
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r0,$0400       ; IF (! (A_REG & $04)) Z_SET                          ; Z Flag Set IF Bit 2 Of Register A Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 2 Of Register A Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $58 BIT   3, B              Test Bit 3 In Register B
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r1,$0800       ; IF (! (B_REG & $08)) Z_SET                          ; Z Flag Set IF Bit 3 Of Register B Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 3 Of Register B Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $59 BIT   3, C              Test Bit 3 In Register C
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r1,$08         ; IF (! (C_REG & $08)) Z_SET                          ; Z Flag Set IF Bit 3 Of Register C Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 3 Of Register C Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $5A BIT   3, D              Test Bit 3 In Register D
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r2,$0800       ; IF (! (D_REG & $08)) Z_SET                          ; Z Flag Set IF Bit 3 Of Register D Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 3 Of Register D Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $5B BIT   3, E              Test Bit 3 In Register E
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r2,$08         ; IF (! (E_REG & $08)) Z_SET                          ; Z Flag Set IF Bit 3 Of Register E Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 3 Of Register E Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $5C BIT   3, H              Test Bit 3 In Register H
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r3,$0800       ; IF (! (H_REG & $08)) Z_SET                          ; Z Flag Set IF Bit 3 Of Register H Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 3 Of Register H Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $5D BIT   3, L              Test Bit 3 In Register L
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r3,$08         ; IF (! (L_REG & $08)) Z_SET                          ; Z Flag Set IF Bit 3 Of Register L Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 3 Of Register L Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $5E BIT   3, (HL)           Test Bit 3 In 8-Bit Value Of Address In Register HL
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  ldrb r5,[r10,r3]
  tst r5,$08         ; IF (! (MEM_MAP[HL_REG] & $08)) Z_SET                ; Z Flag Set IF Bit 3 Of 8-Bit Value Of Address In Register HL Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 3 Of 8-Bit Value Of Address In Register HL Is 1
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $5F BIT   3, A              Test Bit 3 In Register A
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r0,$0800       ; IF (! (A_REG & $08)) Z_SET                          ; Z Flag Set IF Bit 3 Of Register A Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 3 Of Register A Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $60 BIT   4, B              Test Bit 4 In Register B
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r1,$1000       ; IF (! (B_REG & $10)) Z_SET                          ; Z Flag Set IF Bit 4 Of Register B Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 4 Of Register B Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $61 BIT   4, C              Test Bit 4 In Register C
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r1,$10         ; IF (! (C_REG & $10)) Z_SET                          ; Z Flag Set IF Bit 4 Of Register C Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 4 Of Register C Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $62 BIT   4, D              Test Bit 4 In Register D
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r2,$1000       ; IF (! (D_REG & $10)) Z_SET                          ; Z Flag Set IF Bit 4 Of Register D Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 4 Of Register D Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $63 BIT   4, E              Test Bit 4 In Register E
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r2,$10         ; IF (! (E_REG & $10)) Z_SET                          ; Z Flag Set IF Bit 4 Of Register E Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 4 Of Register E Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $64 BIT   4, H              Test Bit 4 In Register H
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r3,$1000       ; IF (! (H_REG & $10)) Z_SET                          ; Z Flag Set IF Bit 4 Of Register H Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 4 Of Register H Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $65 BIT   4, L              Test Bit 4 In Register L
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r3,$10         ; IF (! (L_REG & $10)) Z_SET                          ; Z Flag Set IF Bit 4 Of Register L Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 4 Of Register L Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $66 BIT   4, (HL)           Test Bit 4 In 8-Bit Value Of Address In Register HL
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  ldrb r5,[r10,r3]
  tst r5,$10         ; IF (! (MEM_MAP[HL_REG] & $10)) Z_SET                ; Z Flag Set IF Bit 4 Of 8-Bit Value Of Address In Register HL Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 4 Of 8-Bit Value Of Address In Register HL Is 1
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $67 BIT   4, A              Test Bit 4 In Register A
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r0,$1000       ; IF (! (A_REG & $10)) Z_SET                          ; Z Flag Set IF Bit 4 Of Register A Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 4 Of Register A Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $68 BIT   5, B              Test Bit 5 In Register B
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r1,$2000       ; IF (! (B_REG & $20)) Z_SET                          ; Z Flag Set IF Bit 5 Of Register B Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 5 Of Register B Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $69 BIT   5, C              Test Bit 5 In Register C
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r1,$20         ; IF (! (C_REG & $20)) Z_SET                          ; Z Flag Set IF Bit 5 Of Register C Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 5 Of Register C Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $6A BIT   5, D              Test Bit 5 In Register D
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r2,$2000       ; IF (! (D_REG & $20)) Z_SET                          ; Z Flag Set IF Bit 5 Of Register D Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 5 Of Register D Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $6B BIT   5, E              Test Bit 5 In Register E
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r2,$20         ; IF (! (E_REG & $20)) Z_SET                          ; Z Flag Set IF Bit 5 Of Register E Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 5 Of Register E Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $6C BIT   5, H              Test Bit 5 In Register H
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r3,$2000       ; IF (! (H_REG & $20)) Z_SET                          ; Z Flag Set IF Bit 5 Of Register H Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 5 Of Register H Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $6D BIT   5, L              Test Bit 5 In Register L
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r3,$20         ; IF (! (L_REG & $20)) Z_SET                          ; Z Flag Set IF Bit 5 Of Register L Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 5 Of Register L Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $6E BIT   5, (HL)           Test Bit 5 In 8-Bit Value Of Address In Register HL
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  ldrb r5,[r10,r3]
  tst r5,$20         ; IF (! (MEM_MAP[HL_REG] & $20)) Z_SET                ; Z Flag Set IF Bit 5 Of 8-Bit Value Of Address In Register HL Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 5 Of 8-Bit Value Of Address In Register HL Is 1
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $6F BIT   5, A              Test Bit 5 In Register A
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r0,$2000       ; IF (! (A_REG & $20)) Z_SET                          ; Z Flag Set IF Bit 5 Of Register A Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 5 Of Register A Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $70 BIT   6, B              Test Bit 6 In Register B
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r1,$4000       ; IF (! (B_REG & $40)) Z_SET                          ; Z Flag Set IF Bit 6 Of Register B Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 6 Of Register B Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $71 BIT   6, C              Test Bit 6 In Register C
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r1,$40         ; IF (! (C_REG & $40)) Z_SET                          ; Z Flag Set IF Bit 6 Of Register C Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 6 Of Register C Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $72 BIT   6, D              Test Bit 6 In Register D
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r2,$4000       ; IF (! (D_REG & $40)) Z_SET                          ; Z Flag Set IF Bit 6 Of Register D Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 6 Of Register D Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $73 BIT   6, E              Test Bit 6 In Register E
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r2,$40         ; IF (! (E_REG & $40)) Z_SET                          ; Z Flag Set IF Bit 6 Of Register E Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 6 Of Register E Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $74 BIT   6, H              Test Bit 6 In Register H
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r3,$4000       ; IF (! (H_REG & $40)) Z_SET                          ; Z Flag Set IF Bit 6 Of Register H Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 6 Of Register H Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $75 BIT   6, L              Test Bit 6 In Register L
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r3,$40         ; IF (! (L_REG & $40)) Z_SET                          ; Z Flag Set IF Bit 6 Of Register L Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 6 Of Register L Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $76 BIT   6, (HL)           Test Bit 6 In 8-Bit Value Of Address In Register HL
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  ldrb r5,[r10,r3]
  tst r5,$40         ; IF (! (MEM_MAP[HL_REG] & $40)) Z_SET                ; Z Flag Set IF Bit 6 Of 8-Bit Value Of Address In Register HL Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 6 Of 8-Bit Value Of Address In Register HL Is 1
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $77 BIT   6, A              Test Bit 6 In Register A
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r0,$4000       ; IF (! (A_REG & $40)) Z_SET                          ; Z Flag Set IF Bit 6 Of Register A Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 6 Of Register A Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $78 BIT   7, B              Test Bit 7 In Register B
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r1,$8000       ; IF (! (B_REG & $80)) Z_SET                          ; Z Flag Set IF Bit 7 Of Register B Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 7 Of Register B Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $79 BIT   7, C              Test Bit 7 In Register C
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r1,$80         ; IF (! (C_REG & $80)) Z_SET                          ; Z Flag Set IF Bit 7 Of Register C Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 7 Of Register C Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $7A BIT   7, D              Test Bit 7 In Register D
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r2,$8000       ; IF (! (D_REG & $80)) Z_SET                          ; Z Flag Set IF Bit 7 Of Register D Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 7 Of Register D Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $7B BIT   7, E              Test Bit 7 In Register E
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r2,$80         ; IF (! (E_REG & $80)) Z_SET                          ; Z Flag Set IF Bit 7 Of Register E Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 7 Of Register E Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $7C BIT   7, H              Test Bit 7 In Register H
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r3,$8000       ; IF (! (H_REG & $80)) Z_SET                          ; Z Flag Set IF Bit 7 Of Register H Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 7 Of Register H Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $7D BIT   7, L              Test Bit 7 In Register L
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r3,$80         ; IF (! (L_REG & $80)) Z_SET                          ; Z Flag Set IF Bit 7 Of Register L Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 7 Of Register L Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $7E BIT   7, (HL)           Test Bit 7 In 8-Bit Value Of Address In Register HL
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  ldrb r5,[r10,r3]
  tst r5,$80         ; IF (! (MEM_MAP[HL_REG] & $80)) Z_SET                ; Z Flag Set IF Bit 7 Of 8-Bit Value Of Address In Register HL Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 7 Of 8-Bit Value Of Address In Register HL Is 1
  add r12,3          ; QCycles += 3
  bx lr
align 256
  ; $7F BIT   7, A              Test Bit 7 In Register A
  orr r0,H_FLAG      ; H_SET                                               ; H Flag Set
  bic r0,N_FLAG      ; N_RESET                                             ; N Flag Reset
  tst r0,$8000       ; IF (! (A_REG & $80)) Z_SET                          ; Z Flag Set IF Bit 7 Of Register A Is 0
  orreq r0,Z_FLAG
  bicne r0,Z_FLAG    ; ELSE Z_RESET                                        ; Z Flag Reset IF Bit 7 Of Register A Is 1
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $80 RES   0, B              Reset Bit 0 In Register B
  bic r1,$0100       ; B_REG &= $FE
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $81 RES   0, C              Reset Bit 0 In Register C
  bic r1,$01         ; C_REG &= $FE
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $82 RES   0, D              Reset Bit 0 In Register D
  bic r2,$0100       ; D_REG &= $FE
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $83 RES   0, E              Reset Bit 0 In Register E
  bic r2,$01         ; E_REG &= $FE
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $84 RES   0, H              Reset Bit 0 In Register H
  bic r3,$0100       ; H_REG &= $FE
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $85 RES   0, L              Reset Bit 0 In Register L
  bic r3,$01         ; L_REG &= $FE
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $86 RES   0, (HL)           Reset Bit 0 In 8-Bit Value Of Address In Register HL
  ldrb r5,[r10,r3]
  bic r5,$01         ; MEM_MAP[HL_REG] &= $FE
  strb r5,[r10,r3]
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $87 RES   0, A              Reset Bit 0 In Register A
  bic r0,$0100       ; A_REG &= $FE
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $88 RES   1, B              Reset Bit 1 In Register B
  bic r1,$0200       ; B_REG &= $FD
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $89 RES   1, C              Reset Bit 1 In Register C
  bic r1,$02         ; C_REG &= $FD
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $8A RES   1, D              Reset Bit 1 In Register D
  bic r2,$0200       ; D_REG &= $FD
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $8B RES   1, E              Reset Bit 1 In Register E
  bic r2,$02         ; E_REG &= $FD
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $8C RES   1, H              Reset Bit 1 In Register H
  bic r3,$0200       ; H_REG &= $FD
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $8D RES   1, L              Reset Bit 1 In Register L
  bic r3,$02         ; L_REG &= $FD
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $8E RES   1, (HL)           Reset Bit 1 In 8-Bit Value Of Address In Register HL
  ldrb r5,[r10,r3]
  bic r5,$02         ; MEM_MAP[HL_REG] &= $FD
  strb r5,[r10,r3]
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $8F RES   1, A              Reset Bit 1 In Register A
  bic r0,$0200       ; A_REG &= $FD
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $90 RES   2, B              Reset Bit 2 In Register B
  bic r1,$0400       ; B_REG &= $FB
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $91 RES   2, C              Reset Bit 2 In Register C
  bic r1,$04         ; C_REG &= $FB
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $92 RES   2, D              Reset Bit 2 In Register D
  bic r2,$0400       ; D_REG &= $FB
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $93 RES   2, E              Reset Bit 2 In Register E
  bic r2,$04         ; E_REG &= $FB
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $94 RES   2, H              Reset Bit 2 In Register H
  bic r3,$0400       ; H_REG &= $FB
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $95 RES   2, L              Reset Bit 2 In Register L
  bic r3,$04         ; L_REG &= $FB
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $96 RES   2, (HL)           Reset Bit 2 In 8-Bit Value Of Address In Register HL
  ldrb r5,[r10,r3]
  bic r5,$04         ; MEM_MAP[HL_REG] &= $FB
  strb r5,[r10,r3]
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $97 RES   2, A              Reset Bit 2 In Register A
  bic r0,$0400       ; A_REG &= $FB
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $98 RES   3, B              Reset Bit 3 In Register B
  bic r1,$0800       ; B_REG &= $F7
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $99 RES   3, C              Reset Bit 3 In Register C
  bic r1,$08         ; C_REG &= $F7
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $9A RES   3, D              Reset Bit 3 In Register D
  bic r2,$0800       ; D_REG &= $F7
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $9B RES   3, E              Reset Bit 3 In Register E
  bic r2,$08         ; E_REG &= $F7
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $9C RES   3, H              Reset Bit 3 In Register H
  bic r3,$0800       ; H_REG &= $F7
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $9D RES   3, L              Reset Bit 3 In Register L
  bic r3,$08         ; L_REG &= $F7
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $9E RES   3, (HL)           Reset Bit 3 In 8-Bit Value Of Address In Register HL
  ldrb r5,[r10,r3]
  bic r5,$08         ; MEM_MAP[HL_REG] &= $F7
  strb r5,[r10,r3]
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $9F RES   3, A              Reset Bit 3 In Register A
  bic r0,$0800       ; A_REG &= $F7
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $A0 RES   4, B              Reset Bit 4 In Register B
  bic r1,$1000       ; B_REG &= $EF
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $A1 RES   4, C              Reset Bit 4 In Register C
  bic r1,$10         ; C_REG &= $EF
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $A2 RES   4, D              Reset Bit 4 In Register D
  bic r2,$1000       ; D_REG &= $EF
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $A3 RES   4, E              Reset Bit 4 In Register E
  bic r2,$10         ; E_REG &= $EF
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $A4 RES   4, H              Reset Bit 4 In Register H
  bic r3,$1000       ; H_REG &= $EF
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $A5 RES   4, L              Reset Bit 4 In Register L
  bic r3,$10         ; L_REG &= $EF
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $A6 RES   4, (HL)           Reset Bit 4 In 8-Bit Value Of Address In Register HL
  ldrb r5,[r10,r3]
  bic r5,$10         ; MEM_MAP[HL_REG] &= $EF
  strb r5,[r10,r3]
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $A7 RES   4, A              Reset Bit 4 In Register A
  bic r0,$1000       ; A_REG &= $EF
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $A8 RES   5, B              Reset Bit 5 In Register B
  bic r1,$2000       ; B_REG &= $DF
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $A9 RES   5, C              Reset Bit 5 In Register C
  bic r1,$20         ; C_REG &= $DF
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $AA RES   5, D              Reset Bit 5 In Register D
  bic r2,$2000       ; D_REG &= $DF
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $AB RES   5, E              Reset Bit 5 In Register E
  bic r2,$20         ; E_REG &= $DF
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $AC RES   5, H              Reset Bit 5 In Register H
  bic r3,$2000       ; H_REG &= $DF
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $AD RES   5, L              Reset Bit 5 In Register L
  bic r3,$20         ; L_REG &= $DF
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $AE RES   5, (HL)           Reset Bit 5 In 8-Bit Value Of Address In Register HL
  ldrb r5,[r10,r3]
  bic r5,$20         ; MEM_MAP[HL_REG] &= $DF
  strb r5,[r10,r3]
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $AF RES   5, A              Reset Bit 5 In Register A
  bic r0,$2000       ; A_REG &= $DF
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $B0 RES   6, B              Reset Bit 6 In Register B
  bic r1,$4000       ; B_REG &= $BF
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $B1 RES   6, C              Reset Bit 6 In Register C
  bic r1,$40         ; C_REG &= $BF
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $B2 RES   6, D              Reset Bit 6 In Register D
  bic r2,$4000       ; D_REG &= $BF
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $B3 RES   6, E              Reset Bit 6 In Register E
  bic r2,$40         ; E_REG &= $BF
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $B4 RES   6, H              Reset Bit 6 In Register H
  bic r3,$4000       ; H_REG &= $BF
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $B5 RES   6, L              Reset Bit 6 In Register L
  bic r3,$40         ; L_REG &= $BF
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $B6 RES   6, (HL)           Reset Bit 6 In 8-Bit Value Of Address In Register HL
  ldrb r5,[r10,r3]
  bic r5,$40         ; MEM_MAP[HL_REG] &= $BF
  strb r5,[r10,r3]
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $B7 RES   6, A              Reset Bit 6 In Register A
  bic r0,$4000       ; A_REG &= $BF
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $B8 RES   7, B              Reset Bit 7 In Register B
  bic r1,$8000       ; B_REG &= $7F
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $B9 RES   7, C              Reset Bit 7 In Register C
  bic r1,$80         ; C_REG &= $7F
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $BA RES   7, D              Reset Bit 7 In Register D
  bic r2,$8000       ; D_REG &= $7F
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $BB RES   7, E              Reset Bit 7 In Register E
  bic r2,$80         ; E_REG &= $7F
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $BC RES   7, H              Reset Bit 7 In Register H
  bic r3,$8000       ; H_REG &= $7F
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $BD RES   7, L              Reset Bit 7 In Register L
  bic r3,$80         ; L_REG &= $7F
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $BE RES   7, (HL)           Reset Bit 7 In 8-Bit Value Of Address In Register HL
  ldrb r5,[r10,r3]
  bic r5,$80         ; MEM_MAP[HL_REG] &= $7F
  strb r5,[r10,r3]
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $BF RES   7, A              Reset Bit 7 In Register A
  bic r0,$8000       ; A_REG &= $7F
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $C0 SET   0, B              Set Bit 0 In Register B
  orr r1,$0100       ; B_REG |= $01
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $C1 SET   0, C              Set Bit 0 In Register C
  orr r1,$01         ; C_REG |= $01
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $C2 SET   0, D              Set Bit 0 In Register D
  orr r2,$0100       ; D_REG |= $01
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $C3 SET   0, E              Set Bit 0 In Register E
  orr r2,$01         ; E_REG |= $01
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $C4 SET   0, H              Set Bit 0 In Register H
  orr r3,$0100       ; H_REG |= $01
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $C5 SET   0, L              Set Bit 0 In Register L
  orr r3,$01         ; L_REG |= $01
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $C6 SET   0, (HL)           Set Bit 0 In 8-Bit Value Of Address In Register HL
  ldrb r5,[r10,r3]
  orr r5,$01         ; MEM_MAP[HL_REG] |= $01
  strb r5,[r10,r3]
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $C7 SET   0, A              Set Bit 0 In Register A
  orr r0,$0100       ; A_REG |= $01
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $C8 SET   1, B              Set Bit 1 In Register B
  orr r1,$0200       ; B_REG |= $02
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $C9 SET   1, C              Set Bit 1 In Register C
  orr r1,$02         ; C_REG |= $02
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $CA SET   1, D              Set Bit 1 In Register D
  orr r2,$0200       ; D_REG |= $02
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $CB SET   1, E              Set Bit 1 In Register E
  orr r2,$02         ; E_REG |= $02
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $CC SET   1, H              Set Bit 1 In Register H
  orr r3,$0200       ; H_REG |= $02
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $CD SET   1, L              Set Bit 1 In Register L
  orr r3,$02         ; L_REG |= $02
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $CE SET   1, (HL)           Set Bit 1 In 8-Bit Value Of Address In Register HL
  ldrb r5,[r10,r3]
  orr r5,$02         ; MEM_MAP[HL_REG] |= $02
  strb r5,[r10,r3]
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $CF SET   1, A              Set Bit 1 In Register A
  orr r0,$0200       ; A_REG |= $02
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $D0 SET   2, B              Set Bit 2 In Register B
  orr r1,$0400       ; B_REG |= $04
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $D1 SET   2, C              Set Bit 2 In Register C
  orr r1,$04         ; C_REG |= $04
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $D2 SET   2, D              Set Bit 2 In Register D
  orr r2,$0400       ; D_REG |= $04
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $D3 SET   2, E              Set Bit 2 In Register E
  orr r2,$04         ; E_REG |= $04
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $D4 SET   2, H              Set Bit 2 In Register H
  orr r3,$0400       ; H_REG |= $04
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $D5 SET   2, L              Set Bit 2 In Register L
  orr r3,$04         ; L_REG |= $04
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $D6 SET   2, (HL)           Set Bit 2 In 8-Bit Value Of Address In Register HL
  ldrb r5,[r10,r3]
  orr r5,$04         ; MEM_MAP[HL_REG] |= $04
  strb r5,[r10,r3]
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $D7 SET   2, A              Set Bit 2 In Register A
  orr r0,$0400       ; A_REG |= $04
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $D8 SET   3, B              Set Bit 3 In Register B
  orr r1,$0800       ; B_REG |= $08
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $D9 SET   3, C              Set Bit 3 In Register C
  orr r1,$08         ; C_REG |= $08
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $DA SET   3, D              Set Bit 3 In Register D
  orr r2,$0800       ; D_REG |= $08
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $DB SET   3, E              Set Bit 3 In Register E
  orr r2,$08         ; E_REG |= $08
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $DC SET   3, H              Set Bit 3 In Register H
  orr r3,$0800       ; H_REG |= $08
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $DD SET   3, L              Set Bit 3 In Register L
  orr r3,$08         ; L_REG |= $08
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $DE SET   3, (HL)           Set Bit 3 In 8-Bit Value Of Address In Register HL
  ldrb r5,[r10,r3]
  orr r5,$08         ; MEM_MAP[HL_REG] |= $08
  strb r5,[r10,r3]
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $DF SET   3, A              Set Bit 3 In Register A
  orr r0,$0800       ; A_REG |= $08
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $E0 SET   4, B              Set Bit 4 In Register B
  orr r1,$1000       ; B_REG |= $10
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $E1 SET   4, C              Set Bit 4 In Register C
  orr r1,$10         ; C_REG |= $10
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $E2 SET   4, D              Set Bit 4 In Register D
  orr r2,$1000       ; D_REG |= $10
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $E3 SET   4, E              Set Bit 4 In Register E
  orr r2,$10         ; E_REG |= $10
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $E4 SET   4, H              Set Bit 4 In Register H
  orr r3,$1000       ; H_REG |= $10
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $E5 SET   4, L              Set Bit 4 In Register L
  orr r3,$10         ; L_REG |= $10
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $E6 SET   4, (HL)           Set Bit 4 In 8-Bit Value Of Address In Register HL
  ldrb r5,[r10,r3]
  orr r5,$10         ; MEM_MAP[HL_REG] |= $10
  strb r5,[r10,r3]
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $E7 SET   4, A              Set Bit 4 In Register A
  orr r0,$1000       ; A_REG |= $10
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $E8 SET   5, B              Set Bit 5 In Register B
  orr r1,$2000       ; B_REG |= $20
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $E9 SET   5, C              Set Bit 5 In Register C
  orr r1,$20         ; C_REG |= $20
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $EA SET   5, D              Set Bit 5 In Register D
  orr r2,$2000       ; D_REG |= $20
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $EB SET   5, E              Set Bit 5 In Register E
  orr r2,$20         ; E_REG |= $20
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $EC SET   5, H              Set Bit 5 In Register H
  orr r3,$2000       ; H_REG |= $20
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $ED SET   5, L              Set Bit 5 In Register L
  orr r3,$20         ; L_REG |= $20
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $EE SET   5, (HL)           Set Bit 5 In 8-Bit Value Of Address In Register HL
  ldrb r5,[r10,r3]
  orr r5,$20         ; MEM_MAP[HL_REG] |= $20
  strb r5,[r10,r3]
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $EF SET   5, A              Set Bit 5 In Register A
  orr r0,$2000       ; A_REG |= $20
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $F0 SET   6, B              Set Bit 6 In Register B
  orr r1,$4000       ; B_REG |= $40
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $F1 SET   6, C              Set Bit 6 In Register C
  orr r1,$40         ; C_REG |= $40
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $F2 SET   6, D              Set Bit 6 In Register D
  orr r2,$4000       ; D_REG |= $40
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $F3 SET   6, E              Set Bit 6 In Register E
  orr r2,$40         ; E_REG |= $40
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $F4 SET   6, H              Set Bit 6 In Register H
  orr r3,$4000       ; H_REG |= $40
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $F5 SET   6, L              Set Bit 6 In Register L
  orr r3,$40         ; L_REG |= $40
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $F6 SET   6, (HL)           Set Bit 6 In 8-Bit Value Of Address In Register HL
  ldrb r5,[r10,r3]
  orr r5,$40         ; MEM_MAP[HL_REG] |= $40
  strb r5,[r10,r3]
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $F7 SET   6, A              Set Bit 6 In Register A
  orr r0,$4000       ; A_REG |= $40
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $F8 SET   7, B              Set Bit 7 In Register B
  orr r1,$8000       ; B_REG |= $80
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $F9 SET   7, C              Set Bit 7 In Register C
  orr r1,$80         ; C_REG |= $80
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $FA SET   7, D              Set Bit 7 In Register D
  orr r2,$8000       ; D_REG |= $80
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $FB SET   7, E              Set Bit 7 In Register E
  orr r2,$80         ; E_REG |= $80
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $FC SET   7, H              Set Bit 7 In Register H
  orr r3,$8000       ; H_REG |= $80
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $FD SET   7, L              Set Bit 7 In Register L
  orr r3,$80         ; L_REG |= $80
  add r12,2          ; QCycles += 2
  bx lr
align 256
  ; $FE SET   7, (HL)           Set Bit 7 In 8-Bit Value Of Address In Register HL
  ldrb r5,[r10,r3]
  orr r5,$80         ; MEM_MAP[HL_REG] |= $80
  strb r5,[r10,r3]
  add r12,4          ; QCycles += 4
  bx lr
align 256
  ; $FF SET   7, A              Set Bit 7 In Register A
  orr r0,$8000       ; A_REG |= $80
  add r12,2          ; QCycles += 2
  bx lr  