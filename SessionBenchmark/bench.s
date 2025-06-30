; Amiga 3D Benchmark Module
; Runs the 3D render loop for 5 seconds, samples FPS, and prints the average FPS to CLI
; *** WARNING NOT OPERATIONAL ***

        SECTION bench_code,CODE

        XDEF    bench_main
        XREF    initialize
        XREF    mainloop          ; your main render loop (should render one frame)
        XREF    chunkybuffer

screen_w    equ 320
screen_h    equ 180

bench_main:
        ; Open timer.device
        lea     timername(pc),a1
        moveq   #0,d0
        moveq   #0,d1
        move.l  4.w,a6
        jsr     -552(a6)           ; OpenLibrary
        move.l  d0,timerbase
        beq     .fail

        ; Initialize engine and scene
        bsr     initialize

        ; Get current time
        lea     starttime(pc),a1
        move.l  timerbase,a6
        moveq   #0,d0
        jsr     -30(a6)            ; GetSysTime

        moveq   #0,d7              ; frame counter

.bench_loop:
        ; Render one frame
        bsr     mainloop           ; should render one frame to chunkybuffer

        addq.l  #1,d7              ; frame++

        ; Get current time
        lea     nowtime(pc),a1
        move.l  timerbase,a6
        moveq   #0,d0
        jsr     -30(a6)            ; GetSysTime

        ; Check if 5 seconds passed
        move.l  nowtime+4(pc),d0   ; seconds
        sub.l   starttime+4(pc),d0
        cmp.l   #5,d0
        blt     .bench_loop

        ; Calculate FPS = frames / 5
        move.l  d7,d0
        divu    #5,d0              ; d0.w = average FPS

        ; Print result
        lea     resultstr(pc),a1
        bsr     printstr           ; "Average FPS: "
        move.w  d0,-(sp)
        bsr     printnum           ; Print FPS number
        addq.l  #2,sp
        lea     nlstr(pc),a1
        bsr     printstr

        bra     .exit

.fail:
        lea     failstr(pc),a1
        bsr     printstr

.exit:
        moveq   #0,d0
        rts

; --- Print string to CLI ---
printstr:
        move.l  4.w,a6
        move.l  #1,d1              ; Output (stdout)
        move.l  a1,d2              ; String pointer
        moveq   #0,d3
.next:
        tst.b   (a1,d3.l)
        beq.s   .done
        addq.l  #1,d3
        bra.s   .next
.done:
        move.l  d3,d4              ; Length
        move.l  4.w,a6
        jsr     -48(a6)            ; Write
        rts

; --- Print decimal number (d0.w) ---
printnum:
        lea     numstr(pc),a1
        move.w  d0,d2
        moveq   #0,d3
        moveq   #100,d4
        divu    d4,d2
        add.b   #'0',d2
        move.b  d2,(a1)+
        move.w  d0,d2
        divu    #10,d2
        and.w   #9,d2
        add.b   #'0',d2
        move.b  d2,(a1)+
        and.w   #9,d0
        add.b   #'0',d0
        move.b  d0,(a1)+
        move.b  #0,(a1)
        lea     numstr(pc),a1
        bsr     printstr
        rts

; --- Data ---
timername:  dc.b 'timer.device',0
failstr:    dc.b 'Could not open timer.device!',10,0
resultstr:  dc.b 'Average FPS: ',0
nlstr:      dc.b 10,0
numstr:     ds.b 4

        SECTION bench_bss,BSS
timerbase:  ds.l 1
starttime:  ds.l 2
nowtime:    ds.l 2

        END