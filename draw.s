
draw_all:
                lea     p1,a1 
                lea     p_polygons(pc),a2
                move.l  p_sortbuffer(pc),(a2)
                move.l  p_rotated_verts(pc),a0
                move.l  p_rotated_norms(pc),a5
                move.w  numfaces(pc),d7
.trianglelp:
                move.l  (a2),a3  ; get polygon pointer
                addq.l  #4,(a2)  ; next polygon
                moveq   #0,d1
                move.w  2(a3),d1        ; get polyindex from sorted offsets
                move.l  p_surfaces(pc),a3
                lea     (a3,d1.l),a3    ; get the actual polygon
                move.w  (a3)+,a4
                ; addq.l  #2,a3           ; skip color
                movem.w (a3),d1-d3     ; get p1-p3
                movem.w (a0,d1.w*8),d4-d6
                movem.w d4-d5,(a1)      ; p1x/p1y
                movem.w (a0,d2.w*8),d4-d6
                movem.w d4-d5,p2-p1(a1) ; p2x/p2y
                movem.w (a0,d3.w*8),d4-d6
                movem.w d4-d5,p3-p1(a1) ; p3x/p3y
                ; now all edges are populated
                ; let's check that is the surface visible
                ; if it is not, we save in the drawing time
                movem.w (a1),d0-d3  ; p1 & p2. p3 in in d4-d5
                sub.w   d1,d5       ; v3y-v1y
                sub.w   d0,d2       ; v2x-v1x
                sub.w   d0,d4       ; v3x-v1x
                sub.w   d1,d3       ; v2y-v1y
                muls.w  d5,d2       ; (v3y-v1y)*(v2x-v1x)
                muls.w  d4,d3       ; (v3x-v1x)*(v2y-v1y)
                sub.l   d3,d2
                bpl.s   .hidden
.visible:
                movem.w (a3),d1-d3     ; get n1-n3
                move.w  (a5,d1.w*2),d1
                bpl.s   .ok1
                moveq   #0,d1
.ok1:           move.w  (a5,d2.w*2),d2
                bpl.s   .ok2
                moveq   #0,d2
.ok2:           move.w  (a5,d3.w*2),d3
                bpl.s   .ok3
                moveq   #0,d3
.ok3:
                move.w  a4,d4
                addq.w  #6,d4
                add.w   d4,d1
                add.w   d4,d2
                add.w   d4,d3
    	        move.w  d1,c1-p1(a1)    ; c1
                move.w  d2,c2-p1(a1)    ; c2
                move.w  d3,c3-p1(a1)    ; c3
                bsr.s   gouraud_triangle
.hidden:        dbf     d7,.trianglelp
    	        rts



gouraud_triangle:
                movem.l d5-a6,-(sp)
                movem.w p1,d0-a0
                cmp.w   d1,d3
                bgt.s   .y1ok
                exg     d0,d2
                exg     d1,d3
                exg     d6,d7
.y1ok:          cmp.w   d1,d5
                bgt.s   .y2ok
                exg     d0,d4
                exg     d1,d5
                exg     d6,a0
.y2ok:          cmp.w   d3,d5
                bgt.s   .y3ok
                exg     d2,d4
                exg     d3,d5
                exg     d7,a0
.y3ok:          lsl.w   #8,d6 ; color indices *256
                lsl.w   #8,d7
                exg     d7,a0
                lsl.w   #8,d7
                exg     d7,a0
                lea     tri_vars,a1
                movem.w d0-a0,(a1)

do_line_longest:
                movem.w	d0-d5,-(sp)
		        move.l	p_left_buffer(pc),a4
                move.w	d4,d2               ;p1 to p3
                move.w	d5,d3
                move.w	tri_c1,d4		;start colour.
		        move.w	tri_c3,d5       ;end colour.
        		bsr     triangle_line		;draw the line into the buffer.
                movem.w	(sp)+,d0-d5
do_line_short_1:
                movem.w	d2-d5,-(sp)
		        move.l	p_right_buffer(pc),a4
		        move.w	tri_c1,d4		;start colour.
		        move.w	tri_c2,d5       ;end colour.
        		bsr     triangle_line		;draw the line into the buffer.
                movem.w (sp)+,d0-d3
do_line_short_2:
		        move.w	tri_c2,d4		;start colour.
		        move.w 	tri_c3,d5       ;end colour.
        		bsr     triangle_line		;draw the line into the buffer.

                move.w	tri_p3+2,d7	    ;bottom Y
                move.w	tri_p1+2,d1		;top Y
                sub.w   d1,d7               ;tri height
                subq.w  #1,d7
                move.w  d7,d5               ; height
                bmi     .tridone

                move.l	p_drawbuffer(pc),a0
                move.l  a0,a4
                move.l  a0,a5
                add.l   #screen_width*screen_height,a5

    	        move.l	p_left_buffer(pc),a1			;the left data list.
            	move.l	p_right_buffer(pc),a2			;the right data list.
                move.l  p_ytable(pc),a3
                add.l   (a3,d1.w*4),a0      ;top line start
                move.w  tri_p2+2,d2     ;y2
                sub.w   tri_p1+2,d2     ;-y1
                move.w  (a1,d2.w*4),d4      ;right x
                sub.w   (a2,d2.w*4),d4      ;-left x
                bpl.s   .outer
                exg     a1,a2               ;left <=> right
.outer:
                movem.w (a2)+,d0/d4 ;x right, light right
                movem.w (a1)+,d1/d5 ;x left, light left
                sub.w   d0,d1       ;x delta
                bpl.s   .noflip
                add.w   d0,d1
                exg     d0,d1
                exg     d4,d5
                sub.w   d0,d1
.noflip:
                cmp.l   a4,a0   ; limit top y
                blo.s   .skip
                cmp.l   a0,a5   ; limit bottom y
                blo.s   .tridone
                lea     (a0,d0.w),a3

                addq.w  #1,d1
                sub.w   d4,d5       ;light delta
                tst.w   d1
                beq.s   .nodiv
                ext.l   d5
                divs.w  d1,d5       ;light step
.nodiv:
                move.w  d4,d0
                move.w  d5,d2
                lsr.w   #8,d0       ; color indices /256
                lsr.w   #8,d2

.inner:         ; Gouraud shading inner loop 
                move.b  d0,(a3)+    ;put pixel
                add.b   d5,d4       ;next light
                addx.b  d2,d0
                dbf     d1,.inner
.skip:
                lea     screen_width(a0),a0 ; next scanline
                dbf     d7,.outer
.tridone:
                movem.l (sp)+,d5-a6
                rts


; in:
; d0 = x1
; d1 = y1
; d2 = x2
; d3 = y2
; d4 = color from   
; d5 = color to
; a4 = buffer

triangle_line:
                move.w  #1,a5   ; dir
                sub.w   d0,d2   ; dx
                bpl.s   .posi
                move.w  #-1,a5
                neg.w   d2
.posi:
                sub.w   d1,d3   ; dy
    
                cmp.w   d3,d2   ; dx < dy
                bcs.s   .steep
.flat:
                sub.w   d4,d5   ; ldelta
                tst.w   d2
                beq.s   .fnodiv
                ext.l   d5
                divs.w  d2,d5   ; ldelta/dy
.fnodiv:
                move.w  d2,d6   ; init err
                move.w  d6,d7   ; steps
                lsr.w   d6
.flp:
                subq.w  #1,d7
                bmi.s   .done
                cmp.w   #screen_width,d0
                bge.s   .fclipr
                tst.w   d0
                bpl.s   .fplot
.fclipl:        clr.w   (a4)
                bra.s   .fskip
.fclipr:        move.w  #screen_width-1,(a4)
                bra.s   .fskip
.fplot:         move.w  d0,(a4)
.fskip:         move.w  d4,2(a4)
                add.w   d5,d4   ; light change
                add.w   a5,d0   ; step to dir
                sub.w   d3,d6   ; err-dy
                bcc.s   .flp
                add.w   d2,d6   ; err+dx
                addq.l  #4,a4   ; step down
                bra.s   .flp
.steep:
                sub.w   d4,d5   ; ldelta
                ext.l   d5
                tst.w   d3
                beq.s   .snodiv
                divs.w  d3,d5   ; ldelta/dy
.snodiv:
                move.w  d3,d6   ; init err
                move.w  d6,d7   ; steps
                lsr.w   d6
.slp:
                subq.w  #1,d7
                bmi.s   .done
                cmp.w   #screen_width,d0
                bge.s   .sclipr
                tst.w   d0
                bpl.s   .splot
                clr.w   (a4)+
                bra.s   .sskip
.sclipr:        move.w  #screen_width-1,(a4)+
                bra.s   .sskip
.splot:         move.w  d0,(a4)+
.sskip:         move.w  d4,(a4)+
                add.w   d5,d4   ; light change
                sub.w   d2,d6   ; err-dx
                bcc.s   .slp
                add.w   d3,d6   ; err+dy
                add.w   a5,d0
                bra.s   .slp
.done:          rts


