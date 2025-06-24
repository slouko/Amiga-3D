; Gouraud shaded 3D routine for AGA Amigas (A1200, A4000, Vampire)
;
; v0.1 - initial release
;
; Author: Sami Louko (Proton/Complex^Finnish Gold)

; various constant variables
screen_width = 320
screen_height = 180
bplsize = screen_width*screen_height/8

; ALL CONFIGURABLE PARAMETERS OR THE DATA IS IN THIS FILE!
; CHANGING ANY OTHER FILE IS NOT NECESSARY.

; object creation parameters and modifiers
; calculated basic shape is a torus. 
obj_circles = 32 ; torus circles (8,16,32 or 64)
obj_rounds = 128 ; torus rounds (8,16,32 or 64)
obj_width = 8000 ; torus width
obj_thick = 450 ; shape thickness
obj_scale = 4000 ; shape scale
obj_step = 96 ; shape modifier
obj_factor = 64 ; shape modifier depth
vertices = obj_circles*obj_rounds
surfaces = vertices*2
zoomlevel = 1200

                ; all routines other than generic subroutines are splitted into multiple
                ; files for easier access and better readability

                INCLUDE "init.s"    ; Amiga OS initialization code that executes this program
                INCLUDE "object.s"  ; 3D object creation code
                INCLUDE "c2p.s"     ; Generic Chunky-to-Planar code by Michael Kalms
                INCLUDE "colors.s"  ; Color ramp generator and AGA-color handler
                INCLUDE "rotate.s"  ; 3D-math routines
                INCLUDE "draw.s"    ; Triangle drawing and gouraud shading
                INCLUDE "fps.s"     ; Simple FPS printing

; object angles
ax:            	dc.s	0
ay:           	dc.s	0
az:      	    dc.s	0
; object rotation per update
rx:            	dc.s	0.0131
ry:           	dc.s	-0.0042
rz:      	    dc.s	0.0079

; color ramp configurations
gradients:      ; #0    red grn blu int
                dc.b    $00,$00,$00,$00
                dc.b    $4f,$1f,$5f,$df
                ; #1    red grn blu int
                dc.b    $4f,$1f,$5f,$df
                dc.b    $bf,$9f,$ff,$df
                ; #2    red grn blu int
                dc.b    $bf,$9f,$ff,$df
                dc.b    $ff,$ff,$ff,$ff
                ; #3    red grn blu int
                dc.b    $00,$00,$00,$00
                dc.b    $5f,$1f,$4f,$df
                ; #4    red grn blu int
                dc.b    $5f,$1f,$4f,$df
                dc.b    $ff,$9f,$bf,$df
                ; #5    red grn blu int
                dc.b    $ff,$9f,$bf,$df
                dc.b    $ff,$ff,$ff,$ff

;variables

origo:          dc.w    screen_width/2,screen_height/2
zoom:           dc.w    zoomlevel
sync:           dc.w    0   ; flag: screen synchronization
sec_count:      dc.w    1   ; one second frames counter
tick_count:     dc.w    0   ; draw update counter
fps:            dc.w    0   ; current update rate
dimmer:         dc.w    255 ; Palette dimmer

; Initialize subroutine is run by init code before main execution
; This call contains all precalculations etc.

initialize:
                ; create lookup table for line offsets in the screen buffer

                move.l  p_ytable(pc),a0
                sub.l   a1,a1
                move.w  #screen_height-1,d7
.mklp:          move.l  a1,(a0)+
                lea     screen_width(a1),a1
                dbf     d7,.mklp
        
                ; calculate object using torus shape with modifiers

                bsr     make_sinus_fpu
                bsr     make_surfaces
                bsr     make_vertices
                bsr     make_normals

                ; create 256-color palette using ramp-generator

                move.l  #$000044,d0
                bsr     clear_palette
                moveq   #0,d5
                move.w  #0,d6
                move.w  #25,d7
                bsr     make_ramp
                moveq   #1,d5
                move.w  #25,d6
                move.w  #111,d7
                bsr     make_ramp
                moveq   #2,d5
                move.w  #111,d6
                move.w  #127,d7
                bsr     make_ramp
                moveq   #3,d5
                move.w  #128+0,d6
                move.w  #128+25,d7
                bsr     make_ramp
                moveq   #4,d5
                move.w  #128+25,d6
                move.w  #128+111,d7
                bsr     make_ramp
                moveq   #5,d5
                move.w  #128+111,d6
                move.w  #128+127,d7
                bsr     make_ramp

                move.l  #-1,palette+255*4
                bsr     make_colors

                bsr     init_c2p
                bra     swap_screen

; Main programs starts here

main:
                lea     $dff000,a6
                lea	    coplist_spr+2,a0
                move.l  #spriteoff,d0
                moveq	#8-1,d7			; 8 sprites to clear
.sproff:	    move.w  d0,4(a0)
                swap    d0
                move.w  d0,(a0)
                swap    d0 
                addq.l  #8,a0
                dbf	    d7,.sproff
                move.l  #coplist,COP1LC(a6) ; enable copperlist

                lea     p_surfaces(pc),a0
                move.l  #obj_surfaces,(a0)+
                move.w  #vertices-1,(a0)+
                move.w  #surfaces-1,(a0)


; main loop that will run until left mouse button is pressed
mainloop:             
                ; bsr     wait_vbl
                addq.w  #1,tick_count   ; count drawed frames
                bsr     swap_screen
                bsr     clear_screen
                bsr     rotate_object
                bsr     rotate_vertices
                bsr     rotate_polynorms
                bsr     sort_surfaces
                bsr     draw_all
                bsr     print
                bsr     c2p

                btst    #6,CIAAPRA
                bne.s    mainloop
.exit:
                rts

; this subroutine is called from Vertical Blanking Interrupt.
; 50 times per second on PAL-machines.

vbl_subroutine:
                addq.b  #1,sync
                subq.w  #1,sec_count
                bpl.s   .done
                move.w  #50,sec_count   ; count 1 second
                move.w  tick_count(pc),fps  ; and cunt how many ticks we got during that second
                clr.w   tick_count
.done:          rts

; wait vertical blank for fixed screen synchronization
wait_vbl:       lea     sync(pc),a0
                clr.b   (a0)
.wait:          tst.b   (a0)
                beq.s   .wait
                rts

; Rotate triplebuffers
swap_screen:
                lea     p_showscreen(pc),a0
                movem.l (a0),d0-d2
                exg     d0,d1
                exg     d1,d2
                movem.l d0-d2,(a0)

                ; update new showscreen pointers to copperlist

                move.l  #screen_width*screen_height/8,d1
                moveq   #8-1,d7
                lea     coplist_bpl,a1
.loop:          move.w  d0,6(a1)        ; lsw
                swap    d0
                move.w  d0,2(a1)        ; msw
                swap    d0
                add.l   d1,d0
                addq.l  #8,a1           ; skip two copper instructions
                dbf    d7,.loop
                rts

; Create Sin and Cos data table 
make_sinus_fpu:
                move.l  p_sinus(pc),a0
				move.w	#2048,d7
				fmove.s	#0,fp0
				fmove.w d7,fp2
				fmove.d #2*3.14159265,fp1
				fdiv	fp2,fp1
				add.w 	d7,d7
				subq.w 	#1,d7
.mksin:			fsin	fp0,fp2
				fmul.d	#32767,fp2  ; maximized 16-bits peak values
				fmove.w	fp2,(a0)+
				fadd	fp1,fp0
				dbf 	d7,.mksin 
                rts


; Clear chunky buffer for drawing
clear_screen:   
                move.l  p_drawbuffer(pc),a0
                move.w  #screen_width*screen_height/4-1,d7
                moveq   #0,d0
.cls:           move.l  d0,(a0)+
                dbf    d7,.cls
                rts

; Build the table of average Z-values for each surface (Z-buffer)
; and then Quicksort the Z-buffer to get the order to draw the surfaces
; from back to front
sort_surfaces:
                move.l  p_surfaces(pc),a0
                move.l  p_rotated_verts(pc),a1
                move.l  p_sortbuffer(pc),a2
                sub.l   a3,a3               ; face index
                move.w  numfaces(pc),d7
.buildlp:       movem.w 2(a0),d0-d2   ; get vertices, skip color
                move.w  4(a1,d0.w*8),d5    ; v1z
                add.w   4(a1,d0.w*8),d5    ; v1z
                add.w   4(a1,d1.w*8),d5    ; v2z
                add.w   4(a1,d2.w*8),d5    ; v3z
                asr.w   #2,d5   ; get average Z of all vertices
                neg.w 	d5      ; reverse order
                move.w  d5,(a2)+ ; store Z-value and face offset
                move.w  a3,(a2)+ ; as one combined 32-bits value
                addq.w  #8,a0
                addq.w  #8,a3
                dbf     d7,.buildlp    

; specially tailored quicksort that sorts 32-bits values
; by first 16-bits only. This limits the Z-buffer maximum
; depth to 32767 surfaces, but it's more than enough for us

quicksort:      move.l  a2,a1 
                move.l  p_sortbuffer(pc),a0
                moveq   #-4,d2
                subq.l  #4,a1
.qsort:         move.l  a0,a2           ; array start
                move.l  a1,a3           ; array end
                move.l  a1,d0
                sub.l   a0,d0           ; array length
                lsr.w   d0              ; divide
                and.w   d2,d0           ; mask into longs
                move.w  (a0,d0.w),d0    ; pivot
.loop:          subq.l  #4,a2 
.left:          addq.l  #4,a2
                cmp.w   (a2),d0         ; only sort by first 16bits
                bgt.s   .left
                addq.l  #4,a3
.right:         subq.l  #4,a3
                cmp.w   (a3),d0         ; only sort by first 16bits
                blt.s   .right
                cmp.l   a2,a3
                blt.s   .check
                move.l  (a2),d1
                move.l  (a3),(a2)
                move.l  d1,(a3)
                addq.l  #4,a2
                subq.l  #4,a3
                cmp.l   a2,a3
                bge.s   .loop
.check:         cmp.l   a0,a3
                ble.s   .check2
                movem.l a1-a2,-(sp) ; nested sorting
                move.l  a3,a1
                bsr.s   .qsort
                movem.l (sp)+,a1-a2
.check2:        cmp.l   a2,a1
                ble.s   .done
                move.l  a2,a0
                bra.s   .qsort
.done:          rts

; make our object to spin

rotate_object:
                lea     ax(pc),a0
                move.l  a0,a1
                fmove.s (a0)+,fp1   ; get angles (x,y,z)
                fmove.s (a0)+,fp2
                fmove.s (a0)+,fp3
                fadd.s  (a0)+,fp1   ; apply rotation (x,y,z)
                fadd.s  (a0)+,fp2
                fadd.s  (a0)+,fp3
                fmove.s fp1,(a1)+   ; save angles (x,y,z)
                fmove.s fp2,(a1)+
                fmove.s fp3,(a1)+
                rts

; memory pointers

p_showscreen:   dc.l    screen1
p_drawscreen:   dc.l    screen2
p_clearscreen:  dc.l    screen3
p_drawbuffer:   dc.l    chunkybuffer

p_sortbuffer:   dc.l    sortspace
p_ytable:       dc.l    ytable
p_left_buffer:  dc.l    left_buffer
p_right_buffer: dc.l    right_buffer
p_palette:      dc.l    palette
p_rotated_verts:dc.l    rotated_xyz
p_rotated_norms:dc.l    rotated_n
p_facenormals:  dc.l    facenormals
p_vertnormals:  dc.l    vertnormals
p_sinus:        dc.l    sinus
p_cosinus:      dc.l    cosinus
p_polygons:     dc.l    0
p_vertices:     dc.l    obj_vertices
p_normals:      dc.l    obj_normals
p_surfaces:     dc.l    obj_surfaces
numverts:       dc.w    vertices-1
numfaces:       dc.w    surfaces-1

                SECTION "Copperlist",DATA_C

coplist:
                dc.w	FMODE,3		; Fetch Mode
                dc.w	BPLCON3,$C20
                dc.w	BPLCON0,$0210	; 8 planes
                dc.w	BPLCON1,$0000	; Scroll
                dc.w	BPLCON2,$224	; Priority
                dc.w	BPL1MOD,0	    ; modulos
                dc.w	BPL2MOD,0
                dc.w	DIWHIGH,$2100
                dc.w	DIWSTRT,$5381
                dc.w	DIWSTOP,$05c1	
                dc.w	DDFSTRT,$0038
                dc.w	DDFSTOP,$00b8
coplist_bpl:
                dc.w    BPL1PTH,0   ; bitplane pointers (updated by swap_screen)
                dc.w    BPL1PTL,0
                dc.w    BPL2PTH,0
                dc.w    BPL2PTL,0
                dc.w    BPL3PTH,0
                dc.w    BPL3PTL,0
                dc.w    BPL4PTH,0
                dc.w    BPL4PTL,0
                dc.w    BPL5PTH,0
                dc.w    BPL5PTL,0
                dc.w    BPL6PTH,0
                dc.w    BPL6PTL,0
                dc.w    BPL7PTH,0
                dc.w    BPL7PTL,0
                dc.w    BPL8PTH,0
                dc.w    BPL8PTL,0
coplist_spr:
                dc.w    SPR0PTH,0   ; sprite pointers
                dc.w    SPR0PTL,0
                dc.w    SPR1PTH,0
                dc.w    SPR1PTL,0
                dc.w    SPR2PTH,0
                dc.w    SPR2PTL,0
                dc.w    SPR3PTH,0
                dc.w    SPR3PTL,0
                dc.w    SPR4PTH,0
                dc.w    SPR4PTL,0
                dc.w    SPR5PTH,0
                dc.w    SPR5PTL,0
                dc.w    SPR6PTH,0
                dc.w    SPR6PTL,0
                dc.w    SPR7PTH,0
                dc.w    SPR7PTL,0
                ; dc.w    $ffdf,-2
                dc.l    -2

spriteoff:      dc.l    0,0,-1      ; dummy sprite data (must reside in chip memory)

                SECTION "CHIP BUFFERS",BSS_C

                cnop    0,8
screen1:        ds.b    screen_width*screen_height
screen2:        ds.b    screen_width*screen_height
screen3:        ds.b    screen_width*screen_height

                SECTION "FAST Buffers",BSS_F

; more variables

v:
vtx1:           ds.l    3
vtx2:           ds.l    3
vtx3:           ds.l    3
edge1:          ds.l    3
edge2:          ds.l    3

p1:             ds.w    2
p2:             ds.w    2
p3:             ds.w    2
c1:             ds.w    1
c2:             ds.w    1
c3:             ds.w    1
tri_vars:
tri_p1:         ds.w    2
tri_p2:         ds.w    2
tri_p3:         ds.w    2
tri_c1:         ds.w    1
tri_c2:         ds.w    1
tri_c3:         ds.w    1

                cnop    0,4
ctp_data:                   ; Chunky to Planar variables
ctp_scroffs:    ds.l    1
ctp_pixels:     ds.l    1
                ds.l    16
ctp_datanew:    ds.l    16

; generated integer Sin and Cos tables
sinus:          ds.w    512
cosinus:        ds.w    2048+1536

;palette buffers
pal_buffer:     ds.w    16
temp_red:       ds.b    256
temp_green:     ds.b    256
temp_blue:      ds.b    256
temp_inten:     ds.b    256
palette:        ds.l    256

; space for Z-buffer sorting
sortspace:      ds.l    surfaces

; space for rotated vertices and normals
rotated_xyz:    ds.w    vertices*4
rotated_n:      ds.w    vertices

; LUT for screen linestart offsets
ytable:         ds.l    screen_height

; buffers for triangle rasterization
left_buffer:    ds.l    screen_height
right_buffer:   ds.l    screen_height

; space for code generated 3D object
obj_surfaces:   ds.w    surfaces*4
obj_vertices:   ds.w    vertices*3
obj_normals:    ds.w    vertices*3
facenormals:    ds.l    vertices*4
vertnormals:    ds.l    vertices*4

                cnop    0,32

; Chunky buffer for faster drawing
chunkybuffer:   ds.b    screen_width*screen_height 

