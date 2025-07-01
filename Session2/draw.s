xclipmin:       dc.w    clip_left
xclipmax:       dc.w    clip_right
yclipmin:       dc.w    clip_top
yclipmax:       dc.w    clip_bottom

linedraw:
                movem.l d5-a5,-(sp)
            	; Clip against y min and y max

                cmp.w   d1,d3		; Order lines from top to bottom
                bgt.s   .noswap
                exg	    d0,d2 
                exg 	d1,d3
.noswap:
                cmp.w   yclipmin(pc),d3
                ble     .done		; ymax < YCLIPMIN
                cmp.w   yclipmax(pc),d1
                bge     .done		; YCLIPMAX < ymin

                cmp.w   yclipmin(pc),d1
                bge.s   .noyclip0
                move.w  yclipmin(pc),d5
                sub.w   d1,d5
                move.w  d2,d6
                sub.w   d0,d6
                muls.w  d5,d6
                move.w  d3,d5
                sub.w   d1,d5
                divs.w  d5,d6
                add.w   d6,d0
                move.w  yclipmin(pc),d1
.noyclip0:
                cmp.w   yclipmax(pc),d3
                ble.s   .noyclip1
                move.w  yclipmax(pc),d5
                sub.w   d3,d5
                move.w  d0,d6
                sub.w   d2,d6
                muls.w  d5,d6
                move.w  d1,d5
                sub.w   d3,d5
                divs.w  d5,d6
                add.w   d6,d2 
                move.w  yclipmax(pc),d3
.noyclip1:
                ; Clip against xmin and xmax

                cmp.w   d0,d2		; Order lines from left to right
                bgt.s   .noswap2
                exg	    d0,d2 
                exg	    d1,d3
.noswap2:
                cmp.w   xclipmin(pc),d2
                ble	    .done		    ; xmax < XCLIP0 -> done
                cmp.w   xclipmax(pc),d0	
                bge     .done

                cmp.w   xclipmin(pc),d0	; XCLIP0 <= xmin 
                bge.s   .noxclip0
                move.w  xclipmin(pc),d5
                sub.w   d0,d5
                move.w  d3,d6
                sub.w   d1,d6
                muls.w  d5,d6
                move.w  d2,d5
                sub.w   d0,d5
                divs.w  d5,d6
                add.w   d6,d1
                move.w  xclipmin(pc),d0
.noxclip0:
            	cmp.w   xclipmax(pc),d2	; xmax < XCLIP1 -> no clipping with XCLIP1
	            ble.s   .noxclip1
                move.w  xclipmax(pc),d5
                sub.w   d2,d5
                move.w  d1,d6
                sub.w   d3,d6
                muls.w  d5,d6
                move.w  d0,d5
                sub.w   d2,d5
                divs.w  d5,d6
                add.w   d6,d3
                move.w  xclipmax(pc),d2
.noxclip1:

; in:
; d0.w = x1
; d1.w = y1
; d2.w = x2
; d3.w = y2
; d4.b = color
                cmp.w   d1,d3   ; ensure we draw always from up to down
                bgt.s   .y1ok
                exg     d0,d2
                exg     d1,d3
.y1ok:
                move.l  p_drawbuffer(pc),a0

                moveq   #1,d5   ; line goes right
                sub.w   d0,d2   ; calc dx
                bpl.s   .posi
                moveq   #-1,d5  ; line goes left
                neg.w   d2
.posi:
                sub.w   d1,d3   ; calc dy
                mulu.w  #screen_width,d1    ; calc line start position
                add.l   d1,a0

                cmp.w   d3,d2   ; dx < dy
                bcs.s   .steep
.flat:
                move.w  d2,d6   ; dx  
                lsr.w   d6      ; init err
                move.w  d2,d7   ; steps
                addq.w  #1,d7
.flatloop:      subq.w  #1,d7
                bmi.s   .done
                move.b  d4,(a0,d0.w) ; plot pixel
                add.l   d5,a0   ; step to left or right
                sub.w   d3,d6   ; err-dy
                bcc.s   .flatloop
                add.w   d2,d6   ; err+dx
                lea     screen_width(a0),a0     ; step down
                bra.s   .flatloop
.steep:
                move.w  d3,d6   
                lsr.w   d6      ; init err
                move.w  d3,d7   ; steps
                addq.w  #1,d7
.steeploop:     subq.w  #1,d7
                bmi.s   .done
                move.b  d4,(a0,d0.w) ; plot pixel
                lea     screen_width(a0),a0     ; step down
                sub.w   d2,d6   ; err-dx
                bcc.s   .steeploop
                add.w   d3,d6   ; err+dy
                add.l   d5,a0   ; step to left or right
                bra.s   .steeploop
.done:          movem.l (sp)+,d5-a5
                rts

draw_all:
                lea     p1,a1 
                lea     p_polygons(pc),a2
                move.l  p_sortbuffer(pc),(a2)
                move.l  p_rotated_verts(pc),a0
                move.l  p_surfaces(pc),a4
                move.l  p_rotated_norms(pc),a5
                move.w  numfaces(pc),d7
.trianglelp:
                move.l  (a2),a3  ; get polygon pointer
                addq.l  #4,(a2)  ; next polygon
                moveq   #0,d1
                move.w  2(a3),d1        ; get polyindex from sorted offsets
                lsl.l   #4,d1
                lea     4(a4,d1.l),a3   ; get the actual polygon and skip 2 words
                movem.w (a3)+,d1-d3     ; get p1-p3
                movem.w (a0,d1.w*8),d4-d6
                movem.w d4-d5,(a1)      ; p1x/p1y
                movem.w (a0,d2.w*8),d4-d6
                movem.w d4-d5,p2-p1(a1) ; p2x/p2y
                movem.w (a0,d3.w*8),d4-d6
                movem.w d4-d5,p3-p1(a1) ; p3x/p3y
                ; now all edges are populated

                tst.b   mode_draw
                beq.s   .wireframe

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
                movem.w (a3)+,d1-d3    ; get n1-n3
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
                moveq   #2,d4
                add.w   d4,d1
                add.w   d4,d2
                add.w   d4,d3

                tst.b   mode_shade
                bne.s   .gouraud
                add.w   d2,d1
                add.w   d3,d1
                ext.l   d1
                divu.w  #3,d1 
                move.w  d1,d2 
                move.w  d1,d3
.gouraud:
    	        move.w  d1,c1-p1(a1)    ; c1
                move.w  d2,c2-p1(a1)    ; c2
                move.w  d3,c3-p1(a1)    ; c3
                bsr.s   gouraud_triangle
.hidden:        dbf     d7,.trianglelp
    	        rts
.wireframe:
                movem.w (a1),d0-d3  ; p1 & p2. p3 in in d4-d5
                sub.w   d1,d5       ; v3y-v1y
                sub.w   d0,d2       ; v2x-v1x
                sub.w   d0,d4       ; v3x-v1x
                sub.w   d1,d3       ; v2y-v1y
                muls.w  d5,d2       ; (v3y-v1y)*(v2x-v1x)
                muls.w  d4,d3       ; (v3x-v1x)*(v2y-v1y)
                move.w  #255,d4
                sub.l   d3,d2
                bmi.s   .backface
                moveq   #1,d4
.backface:
                movem.w (a1),d0-d1
                movem.w p2-p1(a1),d2-d3 
                bsr     linedraw
                movem.w p2-p1(a1),d0-d1
                movem.w p3-p1(a1),d2-d3 
                bsr     linedraw
                movem.w p3-p1(a1),d0-d1
                movem.w (a1),d2-d3
                bsr     linedraw
                dbf     d7,.trianglelp
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
                sub.w   d1,d7           ;tri height
                subq.w  #1,d7
                bmi     .tridone
                add.w   #screen_height,d1

                move.l	p_drawbuffer(pc),a0
                lea     dummybuffer,a0
                move.l  #screen_width*screen_height,d5
                move.l  a0,a4   ; top clipping address
                add.l   d5,a4
                move.l  a4,a5
                add.l   #clip_top*screen_width,a4
                add.l   #clip_bottom*screen_width,a5

    	        move.l	p_left_buffer(pc),a1			;the left data list.
            	move.l	p_right_buffer(pc),a2			;the right data list.
                move.l  p_ytable(pc),a3
                add.l  (a3,d1.w*4),a0      ;top line start
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
                clr.b   clip_left(a0)
                clr.b   clip_left+1(a0)
                clr.b   clip_right(a0)
                clr.b   clip_right+1(a0)
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
                cmp.w   #clip_right,d0
                bgt.s   .fclipr
                cmp.w   #clip_left,d0
                bgt.s   .fplot
.fclipl:        move.w  #clip_left,(a4)
                bra.s   .fskip
.fclipr:        move.w  #clip_right,(a4)
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
                cmp.w   #clip_right,d0
                bgt.s   .sclipr
                cmp.w   #clip_left,d0
                bgt.s   .splot
                move.w  #clip_left,(a4)+
                bra.s   .sskip
.sclipr:        move.w  #clip_right,(a4)+
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


