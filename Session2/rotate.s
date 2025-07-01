
rotate_vertices: 
                lea     ax(pc),a0
                fcos.s	(a0),fp0
                fmove.s	fp0,d0		; xcos
                fsin.s	(a0)+,fp0
                fmove.s	fp0,d1		; xsin
                fcos.s	(a0),fp0
                fmove.s	fp0,d2		; ycos
                fsin.s	(a0)+,fp0
                fmove.s	fp0,d3		; ysin
                fcos.s	(a0),fp0
                fmove.s	fp0,d4		; zcos
                fsin.s	(a0),fp0
                fmove.s	fp0,d5		; zsin

                move.l  p_vertices(pc),a1
                move.l	p_rotated_verts(pc),a2 
                movem.w origo(pc),a3-a4     ; cx/cy
                move.w  numverts(pc),d7

.vloop:         fmove.w (a1)+,fp0    ; get vertex coords
                fmove.w (a1)+,fp1
                fmove.w (a1)+,fp2
                fmove   fp1,fp3		; t=y
                fmul.s	d0,fp1		; y * xcos
                fmove	fp2,fp4		; z
                fmul.s	d1,fp4		; z * xsin
                fsub	fp4,fp1		; y2
                fmul.s	d1,fp3		; t * xsin
                fmul.s	d0,fp2		; z* xcos
                fadd	fp3,fp2		; z2
                fmove	fp0,fp3		; t=x
                fmul.s	d2,fp0		; x* ycos
                fmove	fp2,fp4
                fmul.s	d3,fp4		; z* ysin
                fadd	fp4,fp0		; x2
                fmul.s	d2,fp2		; z * ycos
                fmul.s	d3,fp3		; t * ysin
                fsub	fp3,fp2		; z2
                fmove	fp0,fp3		; t=x
                fmul.s	d4,fp0		; x * zcos
                fmove	fp1,fp4
                fmul.s	d5,fp4		; y * zsin
                fsub	fp4,fp0		; x!
                fmul.s	d5,fp3		; t * zsin
                fmul.s	d4,fp1		; y * zcos
                fadd	fp3,fp1		; y!
                fmove   fp2,fp3
                fadd    fp2,fp3
                fadd.s	#10000,fp2	; distance
                fmove.w zoom(pc),fp6
                fdiv	fp6,fp2	    ; zoom
                fdiv	fp2,fp0		; x/z
                fdiv	fp2,fp1		; y/z
                fmove.l	fp0,d6
                add.w   a3,d6       ; cx
                move.w	d6,(a2)+
                fmove.l	fp1,d6
                add.w   a4,d6       ; cy
                move.w	d6,(a2)+
                fmove.l	fp3,d6
                move.w	d6,(a2)+    ; cz
                addq.l  #2,a2
                dbf 	d7,.vloop
                rts

rotate_polynorms:
                move.l  p_normals(pc),a1
                move.l	p_rotated_norms(pc),a2 
                move.w  numverts(pc),d7

.nloop:         fmove.w (a1)+,fp0    ; get normal vector coords
                fmove.w (a1)+,fp1
                fmove.w (a1)+,fp2
                fmove   fp1,fp3		; t=y
                fmul.s	d0,fp1		; y * xcos
                fmove	fp2,fp4		; z
                fmul.s	d1,fp4		; z * xsin
                fsub	fp4,fp1		; y2
                fmul.s	d1,fp3		; t * xsin
                fmul.s	d0,fp2		; z* xcos
                fadd	fp3,fp2		; z2
                fmove	fp0,fp3		; t=x
                fmul.s	d2,fp0		; x* ycos
                fmove	fp2,fp4
                fmul.s	d3,fp4		; z* ysin
                fadd	fp4,fp0		; x2
                fmul.s	d2,fp2		; z * ycos
                fmul.s	d3,fp3		; t * ysin
                fsub	fp3,fp2		; z2
                fmove	fp0,fp3		; t=x
                fmul.s	d4,fp0		; x * zcos
                fmove	fp1,fp4
                fmul.s	d5,fp4		; y * zsin
                fsub	fp4,fp0		; x!
                fmul.s	d5,fp3		; t * zsin
                fmul.s	d4,fp1		; y * zcos
                fadd	fp3,fp1		; y!
                fmove.s #11,fp6    ; scale brightness to half palette range
                fdiv	fp6,fp2	
                fneg	fp2
                fmove.w	fp2,(a2)+
                dbf 	d7,.nloop
                rts

