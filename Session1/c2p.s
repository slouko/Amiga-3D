
; d0.w    chunkyx [chunky-pixels]
; d1.w    chunkyy [chunky-pixels]
; d2.w    (scroffsx) [screen-pixels]
; d3.w    scroffsy [screen-pixels]
; d4.w    (rowlen) [bytes] -- offset between one row and the next in a bpl
; d5.l    (bplsize) [bytes] -- offset between one row in one bpl and the next bpl

init_c2p:
                lea       ctp_datanew,a0
                move.w    #screen_width,d0    
                move.w    #screen_height,d1
                moveq     #0,d2
                moveq     #0,d3
                moveq     #0,d4
                subq.w    #1,d4 
                move.l    #bplsize,d5
                and.l     d4,d0
                mulu.w    d0,d3
                lsr.l     #3,d3
                move.l    d3,ctp_scroffs-ctp_data(a0)
                mulu.w    d0,d1
                move.l    d1,ctp_pixels-ctp_data(a0)
                rts

c2p:
                move.l  p_drawbuffer(pc),a0
                move.l  p_drawscreen(pc),a1

                movem.l d2-d7/a2-a6,-(sp)
                lea     ctp_datanew,a2  ; copyinitblock
                lea     ctp_data,a3
                moveq    #16-1,d0
.copy:          move.l  (a2)+,(a3)+
                dbf     d0,.copy

                lea     ctp_data,a2
                move.l  #$33333333,d5
                move.l  #$55555555,d6
                move.l  #$00ff00ff,a6

                add.w    #bplsize,a1
                add.l    ctp_scroffs-ctp_data(a2),a1

                move.l   ctp_pixels-ctp_data(a2),a2
                add.l    a0,a2
                cmp.l    a0,a2
                beq     .none

                movem.l    a0-a1,-(sp)

                move.l    (a0)+,d0
                move.l    (a0)+,d2
                move.l    (a0)+,d1
                move.l    (a0)+,d3

                move.l    #$0f0f0f0f,d4        ; merge 4x1,part 1
                and.l    d4,d0
                and.l    d4,d2
                lsl.l    #4,d0
                or.l    d2,d0

                and.l    d4,d1
                and.l    d4,d3
                lsl.l    #4,d1
                or.l    d3,d1

                move.l    d1,a3

                move.l    (a0)+,d2
                move.l    (a0)+,d1
                move.l    (a0)+,d3
                move.l    (a0)+,d7

                and.l    d4,d2            ; merge 4x1,part 2
                and.l    d4,d1
                lsl.l    #4,d2
                or.l    d1,d2

                and.l    d4,d3
                and.l    d4,d7
                lsl.l    #4,d3
                or.l    d7,d3

                move.l    a3,d1

                move.w    d2,d7            ; swap 16x2
                move.w    d0,d2
                swap    d2
                move.w    d2,d0
                move.w    d7,d2

                move.w    d3,d7
                move.w    d1,d3
                swap    d3
                move.w    d3,d1
                move.w    d7,d3

                bra.s    .start1
.x1
                move.l    (a0)+,d0
                move.l    (a0)+,d2
                move.l    (a0)+,d1
                move.l    (a0)+,d3

                move.l    d7,bplsize(a1)

                move.l    #$0f0f0f0f,d4        ; merge 4x1,part 1
                and.l    d4,d0
                and.l    d4,d2
                lsl.l    #4,d0
                or.l    d2,d0

                and.l    d4,d1
                and.l    d4,d3
                lsl.l    #4,d1
                or.l    d3,d1

                move.l    d1,a3

                move.l    (a0)+,d2
                move.l    (a0)+,d1
                move.l    (a0)+,d3
                move.l    (a0)+,d7

                move.l    a4,(a1)+

                and.l    d4,d2            ; merge 4x1,part 2
                and.l    d4,d1
                lsl.l    #4,d2
                or.l    d1,d2

                and.l    d4,d3
                and.l    d4,d7
                lsl.l    #4,d3
                or.l    d7,d3

                move.l    a3,d1

                move.w    d2,d7            ; swap 16x2
                move.w    d0,d2
                swap    d2
                move.w    d2,d0
                move.w    d7,d2

                move.w    d3,d7
                move.w    d1,d3
                swap    d3
                move.w    d3,d1
                move.w    d7,d3

                move.l    a5,-bplsize-4(a1)
.start1
                move.l    a6,d4

                move.l    d2,d7            ; swap 2x2
                lsr.l    #2,d7
                eor.l    d0,d7
                and.l    d5,d7
                eor.l    d7,d0
                lsl.l    #2,d7
                eor.l    d7,d2

                move.l    d3,d7
                lsr.l    #2,d7
                eor.l    d1,d7
                and.l    d5,d7
                eor.l    d7,d1
                lsl.l    #2,d7
                eor.l    d7,d3

                move.l    d1,d7
                lsr.l    #8,d7
                eor.l    d0,d7
                and.l    d4,d7
                eor.l    d7,d0
                lsl.l    #8,d7
                eor.l    d7,d1

                move.l    d1,d7
                lsr.l    d7
                eor.l    d0,d7
                and.l    d6,d7
                eor.l    d7,d0
                move.l    d0,bplsize*2(a1)
                add.l    d7,d7
                eor.l    d1,d7

                move.l    d3,d1
                lsr.l    #8,d1
                eor.l    d2,d1
                and.l    d4,d1
                eor.l    d1,d2
                lsl.l    #8,d1
                eor.l    d1,d3

                move.l    d3,d1
                lsr.l    d1
                eor.l    d2,d1
                and.l    d6,d1
                eor.l    d1,d2
                add.l    d1,d1
                eor.l    d1,d3

                move.l    d2,a4
                move.l    d3,a5

                cmpa.l    a0,a2
                bne    .x1

                move.l    d7,bplsize(a1)
                move.l    a4,(a1)+
                move.l    a5,-bplsize-4(a1)

                movem.l    (sp)+,a0-a1
                add.l    #bplsize*4,a1

                move.l    (a0)+,d0
                move.l    (a0)+,d2
                move.l    (a0)+,d1
                move.l    (a0)+,d3

                move.l    #$f0f0f0f0,d4        ; merge 4x1,part 1
                and.l    d4,d0
                and.l    d4,d2
                lsr.l    #4,d2
                or.l    d2,d0

                and.l    d4,d1
                and.l    d4,d3
                lsr.l    #4,d3
                or.l    d3,d1

                move.l    d1,a3

                move.l    (a0)+,d2
                move.l    (a0)+,d1
                move.l    (a0)+,d3
                move.l    (a0)+,d7

                and.l    d4,d2            ; merge 4x1,part 2
                and.l    d4,d1
                lsr.l    #4,d1
                or.l    d1,d2

                and.l    d4,d3
                and.l    d4,d7
                lsr.l    #4,d7
                or.l    d7,d3

                move.l    a3,d1

                move.w    d2,d7            ; swap 16x2
                move.w    d0,d2
                swap    d2
                move.w    d2,d0
                move.w    d7,d2

                move.w    d3,d7
                move.w    d1,d3
                swap    d3
                move.w    d3,d1
                move.w    d7,d3

                bra.s    .start2
.x2
                move.l    (a0)+,d0
                move.l    (a0)+,d2
                move.l    (a0)+,d1
                move.l    (a0)+,d3

                move.l    d7,bplsize(a1)

                move.l    #$f0f0f0f0,d4        ; merge 4x1,part 1
                and.l    d4,d0
                and.l    d4,d2
                lsr.l    #4,d2
                or.l    d2,d0

                and.l    d4,d1
                and.l    d4,d3
                lsr.l    #4,d3
                or.l    d3,d1

                move.l    d1,a3

                move.l    (a0)+,d2
                move.l    (a0)+,d1
                move.l    (a0)+,d3
                move.l    (a0)+,d7

                move.l    a4,(a1)+

                and.l    d4,d2            ; merge 4x1,part 2
                and.l    d4,d1
                lsr.l    #4,d1
                or.l    d1,d2

                and.l    d4,d3
                and.l    d4,d7
                lsr.l    #4,d7
                or.l    d7,d3

                move.l    a3,d1

                move.w    d2,d7            ; swap 16x2
                move.w    d0,d2
                swap    d2
                move.w    d2,d0
                move.w    d7,d2

                move.w    d3,d7
                move.w    d1,d3
                swap    d3
                move.w    d3,d1
                move.w    d7,d3

                move.l    a5,-bplsize-4(a1)
.start2
                move.l    a6,d4

                move.l    d2,d7            ; swap 2x2
                lsr.l    #2,d7
                eor.l    d0,d7
                and.l    d5,d7
                eor.l    d7,d0
                lsl.l    #2,d7
                eor.l    d7,d2

                move.l    d3,d7
                lsr.l    #2,d7
                eor.l    d1,d7
                and.l    d5,d7
                eor.l    d7,d1
                lsl.l    #2,d7
                eor.l    d7,d3

                move.l    d1,d7
                lsr.l    #8,d7
                eor.l    d0,d7
                and.l    d4,d7
                eor.l    d7,d0
                lsl.l    #8,d7
                eor.l    d7,d1

                move.l    d1,d7
                lsr.l    d7
                eor.l    d0,d7
                and.l    d6,d7
                eor.l    d7,d0
                move.l    d0,bplsize*2(a1)
                add.l    d7,d7
                eor.l    d1,d7

                move.l    d3,d1
                lsr.l    #8,d1
                eor.l    d2,d1
                and.l    d4,d1
                eor.l    d1,d2
                lsl.l    #8,d1
                eor.l    d1,d3

                move.l    d3,d1
                lsr.l    d1
                eor.l    d2,d1
                and.l    d6,d1
                eor.l    d1,d2
                add.l    d1,d1
                eor.l    d1,d3

                move.l    d2,a4
                move.l    d3,a5

                cmpa.l    a0,a2
                bne    .x2

                move.l    d7,bplsize(a1)
                move.l    a4,(a1)+
                move.l    a5,-bplsize-4(a1)
.none:
                movem.l    (sp)+,d2-d7/a2-a6
                rts
