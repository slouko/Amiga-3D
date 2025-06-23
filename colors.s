
make_colors:
                moveq   #0,d7
                move.l  p_palette(pc),a5
                lea     $dff000,a6

.loop:          move.w  d7,d0
                move.l  (a5,d0.w*4),d1
                move.w  d1,d2
                swap    d1 
                moveq   #0,d3 
                move.b  d2,d3
                mulu.w  dimmer(pc),d1
                lsr.w   #8,d1
                swap    d1
                lsr.w   #8,d2
                mulu.w  dimmer(pc),d2 
                move.w  d2,d1 
                clr.b   d1
                mulu.w  dimmer(pc),d3 
                lsr.w   #8,d3
                move.b  d3,d1
                bsr     set_aga_color
                addq.b  #1,d7 
                bne.s   .loop
                rts

    
; d0.w = register 0-255
; d1.l = color 00RrGgBb

set_aga_color:

                move.l  d1,d2   ; low  d2
                lsr.l   #4,d1   ; high d1
                move.l  #$0f0f0f,d3
                and.l   d3,d1
                and.l   d3,d2

                lsl.w   #4,d1   ; reorder colors
                lsl.l   #4,d1
                lsl.w   #4,d1
                lsl.l   #4,d1
                lsl.w   #4,d2
                lsl.l   #4,d2
                lsl.w   #4,d2
                lsl.l   #4,d2
                swap    d2
                move.w  d2,d1    ; merge both into d1,l

                move.w  d0,d2
                move.w  d0,d3
                and.w   #%00011111,d0
                or.b    #$c0,d0         ; *2 below,$180 first register
                and.w   #%11100000,d2   ; upper 3 bits of color register
                asl.w   #8,d2           ; shift to bits 13-15
                ; or.w    #$20,d2         ; blank borders + offscreen sprites
                move.w  d2,BPLCON3(a6)
                swap    d1
                move.w  d1,(a6,d0.w*2)  ; write high nybbles    
                or.w    #$200,d2
                move.w  d2,BPLCON3(a6)
                swap    d1
                move.w  d1,(a6,d0.w*2)  ; write low nybbles
                rts

clear_palette:  move.l  p_palette(pc),a0
                move.w  #255,d7 
.clear:         move.l  d0,(a0)+
                dbf     d7,.clear
                rts

; d5.w = gradient setting
; d6.b = first color
; d7.b = last color
                
make_ramp:      
                lea     gradients(pc),a0
                moveq   #0,d0
                moveq   #0,d1
                moveq   #0,d2
                moveq   #0,d3
                move.b  (a0,d5.w*8),d0
                swap    d0
                move.b  4(a0,d5.w*8),d0
                move.b  1(a0,d5.w*8),d1
                swap    d1
                move.b  5(a0,d5.w*8),d1
                move.b  2(a0,d5.w*8),d2
                swap    d2
                move.b  6(a0,d5.w*8),d2
                move.b  3(a0,d5.w*8),d3
                swap    d3
                move.b  7(a0,d5.w*8),d3
                move.l  p_palette(pc),a0
                bra     make_gradient

; d0.l = red start/end level (-1 = skip component)
; d1.l = green start/end level (-1 = skip component)
; d2.l = blue start/end level (-1 = skip component)
; d3.l = intensity start/end level (-1 = skip component)
; d6.b = first color
; d7.b = last color
; a0.l = palette buffer

make_gradient:  move.l  a0,a3
                lea     .colors(pc),a0
                lea     pal_buffer,a1
                movem.l d0-d3,(a0)
                sub.b   d6,d7   ; steps
                beq     .done 
                moveq   #0,d0
                st.b    d0
                and.b   d0,d6
                and.b   d0,d7
                move.w  d7,.steps-.colors(a0)

                moveq   #0,d2       ; calculate step deltas
                bsr     .getchange
                moveq   #1,d2
                bsr     .getchange
                moveq   #2,d2
                bsr     .getchange
                moveq   #3,d2
                bsr     .getchange
                
                subq.b  #1,d7
.makeloop:      moveq   #0,d2       ; process colors
                bsr     .colorstep
                moveq   #1,d2 
                bsr     .colorstep
                moveq   #2,d2 
                bsr     .colorstep
                moveq   #3,d2 
                bsr     .colorstep
                moveq   #0,d3
                lea     temp_inten,a2
                move.b  (a2,d6.w),d3 
                moveq   #0,d0
                moveq   #0,d1
                lea     temp_red,a2
                move.b  (a2,d6.w),d1
                mulu.w  d3,d1           ; apply intensity
                lsr.l   #8,d1 
                move.b  d1,d0
                swap    d0              ; red done
                lea     temp_green,a2
                move.b  (a2,d6.w),d1
                mulu.w  d3,d1           ; apply intensity
                and.w   #$ff00,d1
                move.w  d1,d0           ; green done
                moveq   #0,d1 
                lea     temp_blue,a2
                move.b  (a2,d6.w),d1
                mulu.w  d3,d1           ; apply intensity
                lsr.l   #8,d1 
                move.b  d1,d0           ; blue done
                move.l  d0,(a3,d6.w*4)  ; merge to palette
                addq.b  #1,d6 
                dbf     d7,.makeloop

.done:          rts

; in: d2.w = component # (0-3)

.getchange:     move.w  (a0,d2.w*4),d0  ; get color start value
                move.w  d0,4(a1,d2.w*8) ; store starting level
                clr.w   6(a1,d2.w*8)    ; clear fraction
                move.w  2(a0,d2.w*4),d1 ; and the end value
                sub.w   d0,d1           ; colorchange
                bpl.s   .pos_ok
                neg.w   d1
.pos_ok:        ext.l   d1
                divu.w  .steps(pc),d1    ; calc step size
                move.w  d1,0(a1,d2.w*8)
                swap    d1
                move.w  d1,2(a1,d2.w*8)
                rts

.temptabs       dc.l    temp_red,temp_green,temp_blue,temp_inten

.colorstep:     move.l  .temptabs(pc,d2.w*4),a2
                move.w  4(a1,d2.w*8),d0 ; get color value
                move.b  d0,(a2,d6.w)    ; write to temp
                move.w  (a1,d2.w*8),d1  ; get step value
                move.w  (a0,d2.w*4),d3 
                cmp.w   2(a0,d2.w*4),d3
                bgt.s   .nega
                add.w   d1,d0           ; make a step
                move.w  d0,4(a1,d2.w*8) ; write back
                move.w  6(a1,d2.w*8),d0 ; get fraction
                move.w  2(a1,d2.w*8),d1 ; get fstep
                add.w   d1,d0           ; make a step
                cmp.w   .steps(pc),d0
                blt.s   .notyet
                sub.w   .steps(pc),d0 
                addq.w  #1,4(a1,d2.w*8) ; take extra step
.notyet:        move.w  d0,6(a1,d2.w*8) ; write back
                rts
.nega:          sub.w   d1,d0           ; make a step
                move.w  d0,4(a1,d2.w*8) ; write back
                move.w  6(a1,d2.w*8),d0 ; get fraction
                move.w  2(a1,d2.w*8),d1 ; get fstep
                add.w   d1,d0           ; make a step
                cmp.w   .steps(pc),d0
                blt.s   .notyet
                sub.w   .steps(pc),d0 
                subq.w  #1,4(a1,d2.w*8) ; take extra step
                move.w  d0,6(a1,d2.w*8) ; write back
                rts

.colors         dcb.l   4 ; start/end for rgbi
.steps          dc.w    0
