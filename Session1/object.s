
make_vertices:
	            move.l	p_vertices(pc),a0
                move.l  p_sinus(pc),a1
                move.l  p_cosinus(pc),a2
                sub.l   a3,a3       ; scale sin angle
                moveq   #0,d5       ; circle sin angle
                moveq   #0,d4       ; round sin angle

                moveq   #obj_rounds-1,d7
.rloop1:
                moveq   #obj_circles-1,d6 
.cloop1:
                and.w   #2047,d4
                and.w   #2047,d5
                move.w  (a1,d5.w*2),d0  ; x=sin(a1)
                move.w  (a2,d5.w*2),d1  ; y=cos(a1)
                move.w  (a1,d4.w*2),d2  ; z=cos(a2)
                move.w  (a2,d4.w*2),d3  ; r=sin(a2)
                muls.w  #obj_width,d3
                swap    d3
                add.w   #16384,d3
                muls.w  d3,d0
                muls.w  d3,d1
                swap    d0
                swap    d1
                move.w  a3,d3
                and.w   #2047,d3
                move.w  (a1,d3.w*2),d3    ; scale
                ext.l   d3
                divs.w  #obj_factor,d3
                add.w   #obj_scale,d3
                muls.w  d3,d0
                muls.w  d3,d1
                muls.w  #obj_thick,d3
                asr.l   #8,d3
                muls    d3,d2
                swap    d0
                swap    d1
                asr.l   #4,d2
                swap    d2
                movem.w d0-d2,(a0)
                addq.l  #6,a0 
                add.w   #2048/obj_circles,d4 
                dbf     d6,.cloop1
                add.w   #obj_step,a3
                add.w   #2048/obj_rounds,d5 
                dbf     d7,.rloop1
                rts

                ; create surfaces (2 triangles per one quad)
make_surfaces:
                move.l  p_surfaces(pc),a0
                sub.w   a2,a2		;points circle
                moveq	#obj_circles,d0
                move.w  #obj_circles*obj_rounds-1,d1
                moveq	#obj_rounds-1,d7
.srloop:    	moveq	#obj_circles-1,d6
.scloop:
                move.w  a2,d2       ;p1
                move.w  d2,d3       ;p2
                addq.w  #1,d3
                move.w  d2,d4
                add.w   d0,d4       ;p3
                move.w  d4,d5       ;p4
                addq.w  #1,d4
                tst.w   d6
                bne.s   .notlast
                sub.w   d0,d3
                sub.w   d0,d4
.notlast:
                and.w   d1,d2
                and.w   d1,d3
                and.w   d1,d4
                and.w   d1,d5
                move.w  .color(pc),(a0)+        ; face color or similar
                move.w  d2,(a0)+
                move.w  d3,(a0)+
                move.w  d5,(a0)+
                move.w  .color(pc),(a0)+  ; face color or similar
                move.w  d5,(a0)+
                move.w  d3,(a0)+
                move.w  d4,(a0)+
                addq.w  #1,a2
                dbf     d6,.scloop
                eor.w   #128,.color
                dbf     d7,.srloop
                rts

.color:          dc.w    0

make_normals:
                move.l  p_normals(pc),a0
                move.w  numverts(pc),d7
.init_vertex_normals:
                clr.w  (a0)+    ; set x component to 0.0
                clr.w  (a0)+    ; set y component to 0.0
                clr.w  (a0)+    ; set z component to 0.0
                dbf     d7,.init_vertex_normals
                
                lea     v,a3    ; variables pointer
                move.l  p_vertices(pc),a4
                move.l  p_surfaces(pc),a5
                move.l  p_vertnormals(pc),a6
                move.w  numfaces(pc),d7
                moveq   #0,d0
                moveq   #0,d1
                moveq   #0,d2
.make_face_normals:
                addq.l  #2,a5       ; skip color+flip
                movem.w (a5)+,d3-d5 ; get vertex indices
                mulu.w  #6,d3
                mulu.w  #6,d4
                mulu.w  #6,d5
                movem.w d3-d5,-(sp)

        ; // Compute two edge vectors

                ; get vertex1 coords
                movem.w (a4,d3.w),d0-d2 
                movem.w d0-d2,vtx1-v(a3)
                ; get vertex2 coords
                movem.w (a4,d4.w),d0-d2 
                movem.w d0-d2,vtx2-v(a3)
                ; get vertex3 coords
                movem.w (a4,d5.w),d0-d2 
                movem.w d0-d2,vtx3-v(a3)
                movem.w vtx1-v(a3),d3-d5
                ; vertex3 - vertex1
                sub.w   d3,d0
                sub.w   d4,d1
                sub.w   d5,d2
                movem.w d0-d2,edge2-v(a3)
                movem.w vtx2-v(a3),d0-d2
                ; vertex2 - vertex1
                sub.w   d3,d0
                sub.w   d4,d1
                sub.w   d5,d2
                movem.w d0-d2,edge1-v(a3)

        ; // Compute the face normal

                move.w  edge1+2-v(a3),d0 ; edge1.y
                muls.w  edge2+4-v(a3),d0 ; edge2.z
                move.w  edge1+4-v(a3),d1 ; edge1.z
                muls.w  edge2+2-v(a3),d1 ; edge2.y
                sub.l   d1,d0   ; cross product x

                move.w  edge1+4-v(a3),d1 ; edge1.z
                muls.w  edge2-v(a3),d1   ; edge2.x
                move.w  edge1-v(a3),d2   ; edge1.x
                muls.w  edge2+4-v(a3),d2 ; edge2.z
                sub.l   d2,d1   ; cross product y
                
                move.w  edge1-v(a3),d2   ; edge1.x
                muls.w  edge2+2-v(a3),d2 ; edge2.y
                move.w  edge1+2-v(a3),d3 ; edge1.y
                muls.w  edge2-v(a3),d3   ; edge2.x
                sub.l   d3,d2   ; cross product z
                
                fmove.w d0,fp0  ; cross product
                fmove.w d1,fp1
                fmove.w d2,fp2
                bsr     normalize
                movem.w (sp)+,d3-d5 ; vertex indices
                lea     (a6,d3.w*2),a1  ; vertex normal 1
                fmove.s (a1),fp3 ; current vertex normal.x
                fadd    fp0,fp3
                fmove.s fp3,(a1)+
                fmove.s (a1),fp3 ; current vertex normal.y
                fadd    fp1,fp3
                fmove.s  fp3,(a1)+
                fmove.s (a1),fp3 ; current vertex normal.z
                fadd    fp2,fp3
                fmove.s fp3,(a1)+
                
                lea     (a6,d4.w*2),a1  ; vertex normal 2
                fmove.s (a1),fp3 ; current vertex normal.x
                fadd    fp0,fp3
                fmove.s fp3,(a1)+
                fmove.s (a1),fp3 ; current vertex normal.y
                fadd    fp1,fp3
                fmove.s fp3,(a1)+
                fmove.s (a1),fp3 ; current vertex normal.z
                fadd    fp2,fp3
                fmove.s fp3,(a1)+
                
                lea     (a6,d5.w*2),a1  ; vertex normal 3
                fmove.s (a1),fp3 ; current vertex normal.x
                fadd    fp0,fp3
                fmove.s fp3,(a1)+
                fmove.s (a1),fp3 ; current vertex normal.y
                fadd    fp1,fp3
                fmove.s fp3,(a1)+
                fmove.s (a1),fp3 ; current vertex normal.z
                fadd    fp2,fp3
                fmove.s fp3,(a1)+
                
                dbf     d7,.make_face_normals

                ; normalize vertex normals

                move.l  p_vertnormals(pc),a0   ; a0 -> vertex normals
                move.l  p_normals(pc),a1    ; a1 -> final normals
                move.w  numverts(pc),d7     ; number of vertices
.normalize_loop:
                ; load x, y, z components
                fmove.s (a0)+,fp0           ; load normal.x
                fmove.s (a0)+,fp1           ; load normal.y
                fmove.s (a0)+,fp2           ; load normal.z
                bsr     normalize
                fmove.w #750,fp3
                fmul    fp3,fp0
                fmul    fp3,fp1
                fmul    fp3,fp2
                fmove.w fp0,(a1)+
                fmove.w fp1,(a1)+
                fmove.w fp2,(a1)+
                dbf     d7,.normalize_loop
                rts
                
; Normalize vector
;
; In:   fp0.s = vector.x
;       fp1.s = vector.y
;       fp2.s = vector.z
; Out:  fp0.s = normalized vector.x
;       fp1.s = normalized vector.y
;       fp2.s = normalized vector.z

normalize:      fmove   fp0,fp6
                fmul    fp6,fp6     ; vector.x²
                fmove   fp6,fp7
                fmove   fp1,fp6
                fmul    fp6,fp6     ; vector.y²
                fadd    fp6,fp7
                fmove   fp2,fp6
                fmul    fp6,fp6     ; vector.z²
                fadd    fp6,fp7
                fsqrt   fp7         ; vector length
                ftst    fp7
                bne.s   .nozero
                fmove.s #0,fp0
                fmove   fp0,fp1
                fmove   fp0,fp2
                rts
.nozero:        fdiv    fp7,fp0
                fdiv    fp7,fp1
                fdiv    fp7,fp2
                rts


