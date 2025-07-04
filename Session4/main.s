; Gouraud shaded 3D routine for AGA Amigas (A1200, A4000, Vampire)
;
; v0.1 - initial release
;
; Author: Sami Louko (Proton/Complex^Finnish Gold)

; various constant variables
sc_RastPort = 84	; direct offsets
sc_ViewPort = 44
rp_BitMap = 4
screen_width = 320
screen_height = 180
bplsize = screen_width*screen_height/8
clip_top = 0
clip_left = 0
clip_right = screen_width-1
clip_bottom = screen_height-1
max_vertices = 5000
max_surfaces = 5000
zoomlevel = 950
WIDTH = 320
HEIGHT = 240

; ALL CONFIGURABLE PARAMETERS OR THE DATA IS IN THIS FILE!
; CHANGING ANY OTHER FILE IS NOT NECESSARY.


; all routines other than generic subroutines are splitted into multiple
; files for easier access and better readability

    INCLUDE "init.s"    ; Amiga OS initialization code that executes this program
    INCLUDE "c2p.s"     ; Generic Chunky-to-Planar code by Michael Kalms
    INCLUDE "colors.s"  ; Color ramp generator and AGA-color handler
    INCLUDE "rotate.s"  ; 3D-math routines
    INCLUDE "draw.s"    ; Triangle drawing and gouraud shading
    INCLUDE "fps.s"     ; Simple FPS printing
    even

; object angles
ax:            	dc.w	1024
ay:           	dc.w	0
az:      	    dc.w	0
; object rotation per update
rx:            	dc.w	0
ry:           	dc.w	-3
rz:      	    dc.w	0
; origo and zoom
cx:             dc.w    screen_width/2
cy:             dc.w    screen_height/2
cz:             dc.w    zoomlevel

; color ramp configurations
gradients:      ; #0    red grn blu int
                dc.b    $7f,$00,$2f,$00
                dc.b    $ff,$7f,$3f,$3f
                ; #1    red grn blu int
                dc.b    $ff,$7f,$3f,$40
                dc.b    $ff,$bf,$9f,$ff
                ; #2    red grn blu int
                dc.b    $ff,$bf,$9f,$ff
                dc.b    $ff,$ff,$ff,$ff
                
;variables

sync:           dc.w    0   ; flag: screen synchronization
sec_count:      dc.w    1   ; one second frames counter
tick_count:     dc.w    0   ; draw update counter
fps:            dc.w    0   ; current update rate
dimmer:         dc.w    255 ; Palette dimmer
rtg:            dc.w    0   ; RTG available

; Initialize subroutine is run by init code before main execution
; This call contains all precalculations etc.

initialize:
                ; create lookup table for line offsets in the screen buffer

                move.l  p_ytable(pc),a0
                move.w  #2*screen_height-1,d7
                sub.l   a1,a1
.mklp:          move.l  a1,(a0)+
                lea     screen_width(a1),a1
                dbf     d7,.mklp

                bsr     make_sinus

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

                move.l  #$01888888,palette+1*4
                move.l  #-1,palette+255*4

                tst.w   rtg
                bne.s   .rtgpal
                bsr     make_colors
                bsr     init_c2p
                bra     swap_screen
.rtgpal:
                move.l	p_palette(pc),a1			; setup palette
                lea     rtg_palette(pc),a0
                moveq   #0,d7
.palette:       move.b	1(a1),d1
                move.b	d1,(a0)+
                move.b	d1,(a0)+
                move.b	d1,(a0)+
                move.b	d1,(a0)+
                move.b	2(a1),d1
                move.b	d1,(a0)+
                move.b	d1,(a0)+
                move.b	d1,(a0)+
                move.b	d1,(a0)+
                move.b	3(a1),d1
                move.b	d1,(a0)+
                move.b	d1,(a0)+
                move.b	d1,(a0)+
                move.b	d1,(a0)+
                addq.l  #4,a1
                subq.b  #1,d7
                bne.s   .palette

                ; move.l  _ScreenAddr(pc),d0
                ; lea     p_showscreen(pc),a0
                ; move.l  d0,(a0)+
                ; move.l  d0,(a0)+
                ; move.l  d0,(a0)+
                ; move.l  d0,(a0)+

                move.l	_screen(pc),a0	; load complete 256-color palette
                lea     sc_ViewPort(a0),a0
                lea	    color_table(pc),a1
                move.l 	_GfxBase(pc),a6
                jmp 	LoadRGB32(a6)

; Main programs starts here

main:
                tst.w   rtg
                bne.s   .nocopper
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
.nocopper:
                lea     object(pc),a0
                bsr     load_object

; .w1:            btst    #6,$bfe001
;                 bne.s   .w1
; .w2:            btst    #6,$bfe001
;                 beq.s   .w2

                tst.w   rtg 
                bne.s   mainloop_rtg

; main loop that will run until left mouse button is pressed
mainloop:             
                addq.w  #1,tick_count   ; count drawed frames
                bsr     c2p
                bsr     swap_screen
                bsr     clear_screen
                bsr     rotate_object
                bsr     rotate_vertices
                bsr     rotate_polynorms
                bsr     sort_surfaces
                bsr     draw_all
                bsr     print
                bsr     keycontrol
                bne.s   .exit
                btst    #6,CIAAPRA
                bne     mainloop
.exit:          rts

;  main loop that will run until left mouse button is pressed
mainloop_rtg:             
                addq.w  #1,tick_count   ; count drawed frames
                bsr     clear_screen
                bsr     rotate_object
                bsr     rotate_vertices
                bsr     rotate_polynorms
                bsr     sort_surfaces
                bsr     draw_all
                bsr     print
                lea     chunkybuffer,a0
                move.l	_ScreenAddr,a1
                move.w  #screen_height*screen_width/8,d7
.copylp:        move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                dbf     d7,.copylp
                bsr     keycontrol
                bne.s   .exit
                btst    #6,CIAAPRA
                bne.s   mainloop_rtg
.exit:          rts

key:            dc.w    0
mode_draw:      dc.b    1
mode_shade:     dc.b    1

keycontrol:     bsr	    readkey
                cmp.b   #$c4,d0
                beq.s   .nokey
                cmp.b   key(pc),d0
                beq.s  .nokey
.keychg:
                move.b  d0,key
                cmp.b	#$45,d0			; esc pressed?
                beq.s   .exit
                cmp.b   #$22,d0         ; 'd' pressed
                bne.s   .no_d
                bchg    #0,mode_draw
.no_d:
                cmp.b   #$21,d0         ; 's' pressed
                bne.s   .no_s
                bchg    #0,mode_shade
.no_s:
.nokey:         moveq   #0,d0
                rts
.exit:          moveq   #-1,d0
                rts

readkey:		move.b	CIAASDR,d0
				bset	#6,CIAACRA
				ror.b	#1,d0
				not.b	d0
				moveq	#5,d1
.wait:			tst.b	CIAAPRA
				dbf		d1,.wait
				bclr	#6,CIAACRA
				rts

load_object:    lea     p_vertices(pc),a1
                move.l  (a0)+,(a1)
                lea     p_normals(pc),a1
                move.l  (a0)+,(a1)
                lea     p_surfaces(pc),a1
                move.l  (a0)+,(a1)

                lea     numverts(pc),a1
                move.w  (a0)+,(a1)      ; numverts
                subq.w  #1,(a1)
                lea     numpnorms(pc),a1
                move.w  (a0)+,(a1)      ; numpnorms
                subq.w  #1,(a1)
                lea     numfaces(pc),a1
                move.w  (a0)+,(a1)      ; numfaces
                subq.w  #1,(a1)
                rts

; Generate Sinus & Cosinus tables

make_sinus:     movem.l d0-a6,-(sp)
                move.l  p_sinus(pc),a0
                move.l a0,a2
                lea 1024(a2),a0
                lea 2048(a2),a3
                lea 4096(a2),a5         ; cosine
                move.l a3,a4            ; q2+q3
                move.l a5,a6            ; q4+q5 (cos)
                moveq #-1,d0            ; cos(0) = 1
                lsr.l #1,d0             ; = $7fffffff
            
                moveq #0,d1             ; sin(0) = 0

                move.l #13176774,d6
                move.w #511,d7
.genlp:         move.l d1,d2
                swap d2
                move.w d2,(a2)+
                move.w d2,-(a3)
                move.w d2,(a6)+
                neg.w d2
                move.w d2,(a4)+
                move.w d2,-(a5)
                move.l d0,a0
                move.l d1,a1
                move.l d1,d4
                move.l d0,d5
                move.l d1,d2
                move.l d0,d3
                move.l d6,d0
                mulu.l d0,d0:d1
                move.l d1,a1
                move.l d0,d3
                move.l a0,d1
                move.l #4294947083,d0
                mulu.l d0,d0:d1
                move.l d0,d2
                move.l d1,a0
                move.l d5,d1
                move.l d6,d0
                mulu.l d0,d0:d1
                move.l d0,a1
                move.l d1,d5
                move.l #4294947083,d0
                move.l d4,d1
                mulu.l d0,d0:d1
                move.l d1,d4
                sub.l d3,d2
                move.l a1,d1
                add.l d0,d1
                move.l d2,d0
                dbf d7,.genlp
                movem.l (sp)+,d0-a6
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
                moveq   #16,d6              ; face item size
                move.w  numfaces(pc),d7
.buildlp:       movem.w 4(a0),d0-d2   ; get vertices, skip color+hbr
                move.w  4(a1,d0.w*8),d5    ; v1z
                add.w   4(a1,d0.w*8),d5    ; v1z
                add.w   4(a1,d1.w*8),d5    ; v2z
                add.w   4(a1,d2.w*8),d5    ; v3z
                ext.l   d5
                ; divs.w  #3,d5
                asr.l   #2,d5
                neg.w 	d5
                move.w  d5,(a2)+        ; Z-value
                move.w  a3,(a2)+        ; face offset
                add.w   d6,a0
                addq.w  #1,a3
                dbf     d7,.buildlp    
quicksort:
                move.l  a2,a1 
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
                cmp.w   (a2),d0
                bgt.s   .left
                addq.l  #4,a3
.right:         subq.l  #4,a3
                cmp.w   (a3),d0
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
                lea     ax(pc),a2
                movem.w (a2)+,d0-d2
                add.w   rx(pc),d0
                add.w   ry(pc),d1
                add.w   rz(pc),d2
                move.w  #$7ff,d4        ; limit into 360 degrees
                and.w   d4,d0
                and.w   d4,d1
                and.w   d4,d2
                movem.w d0-d2,-(a2)
                rts

; memory pointers
p_showscreen:   dc.l    screen1
p_drawscreen:   dc.l    screen2
p_clearscreen:  dc.l    screen3
p_drawbuffer:   dc.l    chunkybuffer
p_sinus:        dc.l    sinus
p_cosinus:      dc.l    cosinus
p_sortbuffer:   dc.l    sortspace
p_ytable:       dc.l    ytable
p_left_buffer:  dc.l    left_buffer
p_right_buffer: dc.l    right_buffer
p_palette:      dc.l    palette
p_rotated_verts:dc.l    rotated_xyz
p_rotated_norms:dc.l    rotated_n
p_polygons:     dc.l    0
p_vertices:     dc.l    0
p_normals:      dc.l    0
p_surfaces:     dc.l    0
numverts:       dc.w    0
numpnorms:      dc.w    0
numfaces:       dc.w    0

CYBRBIDTG_NominalWidth = $80050001
CYBRBIDTG_NominalHeight	= $80050002	
CYBRBIDTG_Depth = $80050000
SA_DisplayID = $80000032
SA_Title = $80000028
SA_Depth = $80000025
SA_Pens = $8000003a
TAG_DONE = 0
LBMI_BASEADDRESS = $84001007

CYBRIDTagList:	dc.l	CYBRBIDTG_NominalWidth,WIDTH
				dc.l 	CYBRBIDTG_NominalHeight,HEIGHT
				dc.l 	CYBRBIDTG_Depth,8
				dc.l	TAG_DONE,0
	 
ScreenTagList:	dc.l 	SA_DisplayID,0
				dc.l 	SA_Title,_ScreenTitle
				dc.l 	SA_Depth,8
				dc.l	SA_Pens,Pens
				dc.l 	TAG_DONE,0
	 	 
Pens:		    dc.l 	-1	 

LockTagItems:   dc.l 	LBMI_BASEADDRESS,_ScreenAddr
				dc.l 	TAG_DONE,0
		
_IntuitionBase: dc.l    0
_CGFXBase:      dc.l    0	 
_GfxBase:       dc.l    0
_BestModeID:    dc.l    0
_screen:        dc.l    0
_ScreenAddr:    dc.l    0	 	

IntuitionName:  dc.b 	"intuition.library",0
CGFXName:   	dc.b    "cyber"
GfxName:    	dc.b 	"graphics.library",0
_ScreenTitle:   dc.b    "Amiga-3D",0 

            	even
color_table:    dc.w    256		; number of colors to load
                dc.w    0		; starting from colour 0		
rtg_palette:	dcb.l   256*3	; palette data size is 256x3 longwords		
			    dc.l    0		; end of data


object:         INCLUDE "head.inc"

                SECTION "Copperlist",DATA_C

coplist:
                dc.w	FMODE,3		; Fetch Mode
                dc.w	BPLCON0,$0210	; 8 planes
                dc.w	BPLCON1,$0000	; Scroll
                dc.w	BPLCON2,$224	; Priority
                dc.w	BPLCON3,$C00
                dc.w	BPL1MOD,0	    ; modulos
                dc.w	BPL2MOD,0
                dc.w	DIWHIGH,$2100
                dc.w	DIWSTRT,$5381
                dc.w	DIWSTOP,$07c1	
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

                dc.w    $5311,-2
                dc.w    COL0,$004
                dc.w    $ffdf,-2    ; magic code to wait for lines over 255
                dc.w    $0711,-2
                dc.w    COL0,$000
                dc.l    -2

spriteoff:      dc.l    0,0,-1      ; dummy sprite data (must reside in chip memory)

                SECTION "CHIP BUFFERS",BSS_C

                cnop    0,8
screen1:        ds.b    screen_width*screen_height
screen2:        ds.b    screen_width*screen_height
screen3:        ds.b    screen_width*screen_height

                SECTION "FAST Buffers",BSS_F

; more variables

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

;palette buffers
pal_buffer:     ds.w    16
temp_red:       ds.b    256
temp_green:     ds.b    256
temp_blue:      ds.b    256
temp_inten:     ds.b    256
palette:        ds.l    256

sinus:          ds.w    512
cosinus:        ds.w    2048

; space for Z-buffer sorting
sortspace:      ds.l    max_surfaces

; space for rotated vertices and normals
rotated_xyz:    ds.w    max_vertices*4
rotated_n:      ds.w    max_vertices

; LUT for screen linestart offsets
ytable:         ds.l    screen_height*2

; buffers for triangle rasterization
left_buffer:    ds.l    screen_height
right_buffer:   ds.l    screen_height

                cnop    0,32

; Chunky buffer for faster drawing
dummybuffer:    ds.b    screen_width*screen_height 
chunkybuffer:   ds.b    screen_width*screen_height 

