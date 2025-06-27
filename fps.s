; prints frame counter to the chunky screen

print:          move.l  p_drawbuffer(pc),a1
                lea     screen_width*2-20(a1),a1
                lea     text(pc),a0
                moveq   #4,d7
.y:             moveq   #16,d6      ; print "FPS"
.x:             move.b  (a0)+,d0
                beq.s   .e
                move.b  d0,(a1)
.e:             addq.l  #1,a1
                dbf     d6,.x
                lea     screen_width-17(a1),a1
                dbf     d7,.y 
                
                move.w  fps(pc),d0
                ext.l   d0
                divu.w  #100,d0
                move.w  d0,d2   ; hundreds
                clr.w   d0
                swap    d0
                divu.w  #10,d0
                move.w  d0,d1   ; tens
                swap    d0      ; ones
                tst.b   d2
                bne.s   .not0
                moveq   #10,d2  ; remove leading zero
                tst.b   d1
                bne.s   .not0
                moveq   #10,d1  ; remove leading zero
.not0:
                moveq   #25,d3  ; one digit is 25 bytes
                mulu.w  d3,d0
                mulu.w  d3,d1
                mulu.w  d3,d2
                lea     font(pc),a0
                lea     (a0,d2.w),a2
                tst.b   d2
                bne.s   .h

.h:
                lea     (a0,d1.w),a1 
                lea     (a0,d0.w),a0 
                move.l  p_drawbuffer(pc),a3
                lea     screen_width*2-39(a3),a3    ; start poiters for each digit
                lea     6(a3),a4
                lea     6(a4),a5
                moveq   #5-1,d7   ; 5x5
.y2:            moveq   #5-1,d6
.x2:            move.b  (a2)+,d3    ;100s
                beq.s   .e1         ;transparent back
                move.b  d3,(a3)
.e1:            addq.l  #1,a3
                move.b  (a1)+,d3    ;10s
                beq.s   .e2
                move.b  d3,(a4)
.e2:            addq.l  #1,a4
                move.b  (a0)+,d3    ;1s
                beq.s   .e3
                move.b  d3,(a5)
.e3:            addq.l  #1,a5
                dbf     d6,.x2
                move.W  #screen_width-5,d3
                lea     (a3,d3),a3
                lea     (a4,d3),a4
                lea     (a5,d3),a5
                dbf     d7,.y2 
                rts

 
font:           dc.b    -0,-1,-1,-1,-0
                dc.b    -1,-1,-0,-1,-1
                dc.b    -1,-1,-0,-1,-1
                dc.b    -1,-1,-0,-1,-1
                dc.b    -0,-1,-1,-1,-0

                dc.b    -0,-0,-1,-1,-0
                dc.b    -0,-1,-1,-1,-0
                dc.b    -0,-0,-1,-1,-0
                dc.b    -0,-0,-1,-1,-0
                dc.b    -0,-0,-1,-1,-0

                dc.b    -1,-1,-1,-1,-0
                dc.b    -0,-0,-0,-1,-1
                dc.b    -0,-1,-1,-1,-0
                dc.b    -1,-1,-0,-0,-0
                dc.b    -1,-1,-1,-1,-1

                dc.b    -1,-1,-1,-1,-0
                dc.b    -0,-0,-0,-1,-1
                dc.b    -0,-1,-1,-1,-0
                dc.b    -0,-0,-0,-1,-1
                dc.b    -1,-1,-1,-1,-0

                dc.b    -1,-1,-0,-1,-1
                dc.b    -1,-1,-0,-1,-1
                dc.b    -1,-1,-1,-1,-1
                dc.b    -0,-0,-0,-1,-1
                dc.b    -0,-0,-0,-1,-1

                dc.b    -1,-1,-1,-1,-1
                dc.b    -1,-1,-0,-0,-0
                dc.b    -1,-1,-1,-1,-0
                dc.b    -0,-0,-0,-1,-1
                dc.b    -1,-1,-1,-1,-0

                dc.b    -0,-1,-1,-1,-0
                dc.b    -1,-1,-0,-0,-0
                dc.b    -1,-1,-1,-1,-0
                dc.b    -1,-1,-0,-1,-1
                dc.b    -0,-1,-1,-1,-0

                dc.b    -1,-1,-1,-1,-1
                dc.b    -0,-0,-0,-1,-1
                dc.b    -0,-0,-1,-1,-0
                dc.b    -0,-1,-1,-0,-0
                dc.b    -0,-1,-1,-0,-0

                dc.b    -0,-1,-1,-1,-0
                dc.b    -1,-1,-0,-1,-1
                dc.b    -0,-1,-1,-1,-0
                dc.b    -1,-1,-0,-1,-1
                dc.b    -0,-1,-1,-1,-0

                dc.b    -0,-1,-1,-1,-0
                dc.b    -1,-1,-0,-1,-1
                dc.b    -0,-1,-1,-1,-1
                dc.b    -0,-0,-0,-1,-1
                dc.b    -0,-1,-1,-1,-0

space:          dcb.b   25

text:           dc.b    -1,-1,-1,-1,-1,-0,-1,-1,-1,-1,-0,-0,-0,-1,-1,-1,-1
                dc.b    -1,-1,-0,-0,-0,-0,-1,-1,-0,-1,-1,-0,-1,-1,-1,-0,-0
                dc.b    -1,-1,-1,-1,-0,-0,-1,-1,-1,-1,-0,-0,-0,-1,-1,-1,-0
                dc.b    -1,-1,-0,-0,-0,-0,-1,-1,-0,-0,-0,-0,-0,-0,-1,-1,-1
                dc.b    -1,-1,-0,-0,-0,-0,-1,-1,-0,-0,-0,-0,-1,-1,-1,-1,-0

