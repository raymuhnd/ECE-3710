; If it works, mem[0xFF] = 0xCDCE and the PC stops at "done".
; If any branch goes the wrong way, the program jumps to "fail" and mem[0xFF] = 0xDEAD.

; load from mem
        MOVI 0xF0, r1       ; r1 = 0x00F0 (address of A)
        LOAD r2, r1         ; r2 = A = 7
        ADDI 1, r1          ; r1 = 0x00F1
        LOAD r3, r1         ; r3 = B = 5

; arith/logic op
        MOV  r2, r4         ; r4 = 7
        ADD  r3, r4         ; r4 = 12      (sets flags)
        LSHI 2, r4          ; r4 = 48      (0x0030)
        SUB  r3, r4         ; r4 = 43      (0x002B, sets flags)
        ORI  0x80, r4       ; r4 = 0x00AB
        MOVI 0x0F, r5       ; r5 = 0x000F
        AND  r4, r5         ; r5 = 0x000B
        LUI  0xCD, r6       ; r6 = 0xCD00
        XOR  r4, r6         ; r6 = 0xCDAB
        MOV  r6, r10        ; r10 = 0xCDAB
        LSHI -8, r10        ; r10 = 0x00CD (logical right shift)
        MOVI 4, r11         ; r11 = 4
        LSH  r11, r10       ; r10 = 0x0CD0 (shift by register)
        XORI 0xFF, r5       ; r5 = 0x00F4

; store and reload
        ADDI 1, r1          ; r1 = 0x00F2
        STOR r6, r1         ; mem[0xF2] = 0xCDAB
        LOAD r7, r1         ; r7 = 0xCDAB

; check flags and branch
        CMP  r6, r7         ; equal -> Z = 1
        BNE  fail           ; must NOT be taken
        BEQ  eq_ok          ; must be taken
        BUC  fail
eq_ok:
        MOVI 0, r8          ; r8 = acc = 0
        MOV  r3, r9         ; r9 = count = B = 5
loop:   ADD  r2, r8         ; acc += A
        SUBI 1, r9          ; count--  (sets Z when it hits 0)
        BNE  loop           ; backwards branch, runs 5 times
        CMPI 35, r8         ; acc should be A*B = 35
        BNE  fail

        MOVI 0, r14
        SUBI 1, r14         ; r14 = 0xFFFF (-1)
        CMP  r14, r8        ; compare -1 with 35
        BGT  fail           ; signed: -1 > 35 is false   -> not taken
        BLO  fail           ; unsigned: 0xFFFF < 35 false -> not taken
        BLT  lt_ok          ; signed: -1 < 35 true       -> taken
        BUC  fail
lt_ok:  BHI  hi_ok          ; unsigned: 0xFFFF > 35 true -> taken
        BUC  fail

; jumps
hi_ok:  MOVI fail, r15      ; r15 = address of fail
        CMPI 35, r8         ; Z = 1
        JNE  r15            ; must NOT be taken
        MOVI subr, r12      ; r12 = address of subroutine
        JAL  r13, r12       ; call: r13 = return address

; write to mem
        MOVI 0xFF, r1
        STOR r0, r1         ; mem[0xFF] = 0xCDCE
done:   BUC  done           ; halt (branch to itself)

fail:   LUI  0xDE, r0
        ORI  0xAD, r0       ; r0 = 0xDEAD
        MOVI 0xFF, r1
        STOR r0, r1         ; mem[0xFF] = 0xDEAD
halt_f: BUC  halt_f

; subroutine: r0 = r7 + r8, then return
subr:   MOV  r7, r0         ; r0 = 0xCDAB
        ADD  r8, r0         ; r0 = 0xCDAB + 0x23 = 0xCDCE
        JUC  r13            ; return

; data
        .org 0xF0
        .word 0x0007        ; A
        .word 0x0005        ; B
        .word 0x0000        ; scratch (store / reload)
        .org 0xFF
        .word 0x0000        ; result (displayed)
