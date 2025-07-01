
rotate_vertices: 
                move.l  p_vertices(pc),a0
                move.l  p_rotated_verts(pc),a1
                movem.l p_sinus(pc),a5/a6
                movem.w ax(pc),a2-a4            ;ax,ay,az
                move.w  numverts(pc),d0
.vloop:
                movem.w (a0)+,d1-d3             ;x,y,z
                asl.w   #4,d1
                asl.w   #4,d2
                asl.w   #4,d3

                move.w  d1,d4                    ;x1 = x0*cos(az) - y0*sin(az)
                move.w  d2,d5
                muls.w  (a6,a4.w*2),d4
                muls.w  (a5,a4.w*2),d5
                add.l   d4,d4
                add.l   d5,d5
                swap    d4
                swap    d5
                sub.w   d5,d4                     ;d4=x1

                move.w  d1,d5                    ;y1 = x0*sin(az) + y0*cos(az)
                muls.w  (a5,a4.w*2),d5
                muls.w  (a6,a4.w*2),d2
                add.l   d5,d5
                add.l   d2,d2
                swap    d5
                swap    d2
                add.w   d5,d2                     ;d2=y1

                move.w  d2,d5                    ;y2 = y1*cos(ax) - z1*sin(ax)
                move.w  d3,d6
                muls.w  (a6,a2.w*2),d5
                muls.w  (a5,a2.w*2),d6
                add.l   d5,d5
                add.l   d6,d6
                swap    d5
                swap    d6
                sub.w   d6,d5                     ;d5=y2

                move.w  d2,d6                    ;z2 = y1*sin(ax) + z1*cos(ax)
                muls.w  (a5,a2.w*2),d6
                muls.w  (a6,a2.w*2),d3
                add.l   d6,d6
                add.l   d3,d3
                swap    d6
                swap    d3
                add.w   d6,d3                     ;d3=z2

                move.w  d3,d6                    ;z3 = z2*cos(ay) - x2*sin(ay)
                move.w  d4,d7
                muls.w  (a6,a3.w*2),d6
                muls.w  (a5,a3.w*2),d7
                add.l   d6,d6
                add.l   d7,d7
                swap    d6
                swap    d7
                sub.w   d7,d6                     ;d6=z3

                muls.w  (a5,a3.w*2),d3
                muls.w  (a6,a3.w*2),d4
                add.l   d3,d3
                add.l   d4,d4
                swap    d3
                swap    d4
                add.w   d3,d4                     ;d4=x3

                movem.w cx(pc),d1-d3
                moveq   #9,d7
                ext.l   d4
                ext.l   d5
                move.w  d6,4(a1)            ; STORE Z
                ; neg.w   d6
                asr.w   d7,d6
                move.w  #1050,d7
                sub.w   d3,d7
                add.w   d7,d6
                divs.w  d6,d4
                divs.w  d6,d5
                add.w   d1,d4
                add.w   d2,d5
                move.w  d4,(a1)+            ; store projected x/y
                move.w  d5,(a1)+
                addq.l  #4,a1
                dbf     d0,.vloop
                rts

rotate_polynorms:
                move.l  p_normals(pc),a0
                move.l	p_rotated_norms(pc),a1
                movem.l p_sinus(pc),a5/a6
                movem.w ax(pc),a2-a4            ;ax,ay,az
                move.w  numpnorms(pc),d0
.nloop:
                movem.w (a0)+,d1-d3             ;x,y,z
                asl.w   #4,d1
                asl.w   #4,d2
                asl.w   #4,d3

                move.w  d1,d4                    ;x1 = x0*cos(az) - y0*sin(az)
                move.w  d2,d5
                muls.w  (a6,a4.w*2),d4
                muls.w  (a5,a4.w*2),d5
                add.l   d4,d4
                add.l   d5,d5
                swap    d4
                swap    d5
                sub.w   d5,d4                     ;d4=x1

                move.w  d1,d5                    ;y1 = x0*sin(az) + y0*cos(az)
                muls.w  (a5,a4.w*2),d5
                muls.w  (a6,a4.w*2),d2
                add.l   d5,d5
                add.l   d2,d2
                swap    d5
                swap    d2
                add.w   d5,d2                     ;d2=y1

                move.w  d2,d5                    ;y2 = y1*cos(ax) - z1*sin(ax)
                move.w  d3,d6
                muls.w  (a6,a2.w*2),d5
                muls.w  (a5,a2.w*2),d6
                add.l   d5,d5
                add.l   d6,d6
                swap    d5
                swap    d6
                sub.w   d6,d5                     ;d5=y2

                move.w  d2,d6                    ;z2 = y1*sin(ax) + z1*cos(ax)
                muls.w  (a5,a2.w*2),d6
                muls.w  (a6,a2.w*2),d3
                add.l   d6,d6
                add.l   d3,d3
                swap    d6
                swap    d3
                add.w   d6,d3                     ;d3=z2

                move.w  d3,d6                    ;z3 = z2*cos(ay) - x2*sin(ay)
                move.w  d4,d7
                muls.w  (a6,a3.w*2),d6
                muls.w  (a5,a3.w*2),d7
                add.l   d6,d6
                add.l   d7,d7
                swap    d6
                swap    d7
                sub.w   d7,d6                     ;d6=z3

                muls.w  (a5,a3.w*2),d3
                muls.w  (a6,a3.w*2),d4
                add.l   d3,d3
                add.l   d4,d4
                swap    d3
                swap    d4
                add.w   d3,d4                     ;d4=x3

                ext.l   d4
                ext.l   d5
                neg.w   d6
                asr.w   #7,d6
                move.w  d6,(a1)+            ; lightness
                dbf     d0,.nloop
                rts

