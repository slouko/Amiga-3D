
        INCLUDE "constants.s"

        section "main",code_f

start:
;     	        move.l  4.w,a6
;                 move.w  $128(a6),d0     ; AttnFlags
;                 lea     txt_cpu+3(pc),a1
;                 move.b  #"0",(a1)

;                 btst    #0,d0       ; 68000
;                 beq.s   .detected
;                 addq.b  #1,(a1)
;                 btst    #1,d0       ; 68010
;                 beq.s   .detected
;                 addq.b  #1,(a1)
;                 btst    #2,d0       ; 68020
;                 beq.s   .detected
;                 addq.b  #1,(a1)
;                 btst    #3,d0       ; 68030
;                 beq.s   .detected
;                 addq.b  #1,(a1)
;                 btst    #7,d0       ; 68040
;                 beq.s   .detected
;                 addq.b  #2,(a1)     ; 68060+
; .detected:
;                 bsr     open_dos
;                 bne.s   .dos_open
;                 rts
; .dos_open: 	
;                 lea     txt_cpu(pc),a0
;                 bsr     print
;                 lea     txt_cpu+3(pc),a1
;                 cmp.b   #"6",(a1)
;                 beq.s   .chk_fpu
; .failed:        lea     txt_req(pc),a0
;                 bsr     print
;                 bsr     close_dos
;                 moveq   #0,d0
;                 rts
; .chk_fpu:
;                 btst    #4,$129(a6)     ; AttnFlags
;                 beq.s   .failed
;                 lea     txt_fpu(pc),a0
;                 bsr     print
; .chk_aga:
                lea     gfx_name(pc),a1
                moveq   #0,d0
                move.l  4.w,a6
                jsr    -552(a6)         ; _LVOOpenLibrary
                move.l  d0,gfx_base
;                 move.l  d0,a0
;                 btst    #2,$ec(a0)
;                 bne.s   .is_aa
;                 move.l  a0,a1
;                 jsr     -414(a6)        ; _LVOCloseLibrary
;                 bra.s   .failed
; .is_aa:
;                 lea     txt_aga(pc),a0
;                 bsr     print

                bsr     initialize

                move.l  gfx_base(pc),a6
                move.l  38(a6),old_copper       ; store old copper list address
                move.l  34(a6),old_view         ; store old WB view.

                sub.l   a1,a1
                jsr     -222(a6)        ; _LVOLoadView(Null)
                jsr     -270(a6)        ; _LVOWaitTOF
                jsr     -270(a6)        ; _LVOWaitTOF

                move.l  4.w,a6
                jsr     -132(a6)        ; _LVOForbid

                lea     get_vbr(pc),a5
                jsr     -$1e(a6)        ; _LVOSupervisor

                lea     $dff000,a6
                move.w  INTENAR(a6),old_intena
                move.w  INTREQR(a6),old_intreq
                move.w  DMACONR(a6),old_dmacon
                move.w  ADKCONR(a6),old_adkcon
                ; move.w  #$7fff,d0
                ; move.w  d0,INTENA(a6)
                ; move.w  d0,DMACON(a6)
                
                move.l  gfx_base(pc),a6
                jsr     -270(a6)        ; WaitTOF

            	move.l  vector_base(pc),a0
                move.l  INT3(a0),old_int3
                move.l  #vbl_int,INT3(a0)

                lea     $dff000,a6
                move.w  #D_SETCLR+D_ALL+D_COPP+D_BTPL+D_BLIT,DMACON(a6)
                ; move.w  #D_SETCLR+D_PRIB+D_ALL+D_BTPL+D_COPP+D_BLIT,DMACON(a6)
                move.w  #I_SETCLR+I_INTEN+I_VBL,INTENA(a6)
                move.w  #0,COL0(a6)

                bsr     main

                move.l  vector_base(pc),a0
                move.l  old_int3,INT3(a0)

                lea     $dff000,a6
                move.w  #$7fff,d0
                move.w  d0,INTENA(a6)
                move.w  d0,INTREQ(a6)
                move.w  d0,DMACON(a6)
                addq.w  #1,d0
                move.w  old_intena(pc),d1
                or.w    d0,d1
                move.w  d1,INTENA(a6)
                move.w  old_intreq(pc),d1
                or.w    d0,d1
                move.w  d1,INTREQ(a6)
                move.w  old_dmacon(pc),d1
                or.w    d0,d1
                move.w  d1,DMACON(a6)
                move.w  old_adkcon(pc),d1
                or.w    d0,d1
                move.w  d1,ADKCON(a6)
                
                move.l  old_copper(pc),COP1LC(a6)

                move.l  gfx_base(pc),a6
                move.l  old_view(pc),a1
                jsr     -222(a6)                ; _LVOLoadview(OldView)

                move.l  4.w,a6
                move.l  gfx_base(pc),a1
                jsr     -414(a6)                ; close graphics.library

                ; jsr     -138(a6)                ; _LVOPermit
                ; bsr     close_dos
                moveq   #0,d0
                rts


; open_dos:
;                 lea     dos_name(pc),a1
;                 moveq   #0,d0           ; any version
;                 move.l	a6,-(sp)
;                 move.l	4.w,a6
;                 jsr	    -552(a6) 		; _LVOOpenLibrary
;                 move.l  d0,dos_base    	; store Dos.library pointer
;                 beq.s   .error
;                 move.l	d0,a6
;                 jsr	    -60(a6) 		; _LVOOutput
;                 move.l	(sp)+,a6
;                 move.l  d0,stdout       ; store descriptor.
;                 beq.s   close_dos
;                 rts      
; .error:         move.l	(sp)+,a6
;                 moveq   #0,d0
;                 rts
        	                         

; close_dos:
;                 move.l  dos_base(pc),a1
;                 move.l	a6,-(sp)
;                 move.l	4.w,a6
;                 jsr	    -414(a6) 		; _LVOCloseLibrary
;                 move.l	(sp)+,a6
;                 rts


; print text out
;
; a0 - pointer to text string (must end with 0)

; print:          
;                 rts     ; disable for asm-one

;                 movem.l d1-d3/a6,-(sp)
;                 move.l  stdout(pc),d1
;                 beq.s   .skip
;                 move.l  a0,d2
;                 moveq   #0,d3
; .cklen:         addq.w  #1,d3
;                 tst.b   (a0)+
;                 bne.s   .cklen
;                 move.l	dos_base(pc),a6
; 	            jsr	    -48(a6) 		; _LVOWrite
; .skip:          movem.l	(sp)+,d1-d3/a6
;                 rts

get_vbr:        movec   VBR,d0 
                move.l  d0,vector_base
                nop
                rte


vbl_int:
                btst #IB_VBL,$dff001+INTREQR    ; ensure it's vbl irq
                beq .not_vbi
         
                movem.l d0-a6,-(sp)
                bsr     vbl_subroutine              
                lea     $dff000,a6
                moveq   #I_VBL,d0
                move.w  d0,INTREQ(a6)
                move.w  d0,INTREQ(a6)
                movem.l (sp)+,d0-a6 
.not_vbi:
                nop
                rte


vector_base:    dc.l    0
old_adkcon:     dc.w    0
old_dmacon:     dc.w    0
old_intena:     dc.w    0
old_intreq:     dc.w    0
old_int3:       dc.l    0
old_copper:     dc.l    0
old_view:       dc.l    0
stdout:         dc.l    0
dos_base:       dc.l    0
gfx_base:       dc.l    0
; dos_name:       dc.b    "dos.library",0
gfx_name:       dc.b    "graphics.library",0
; txt_cpu:        dc.b    "68000 CPU detected.",13,10,0
; txt_fpu:        dc.b    "68882 FPU detected.",13,10,0
; txt_aga:        dc.b    "AGA-chipset detected.",13,10,0
; txt_req:        dc.b    "68060 CPU+FPU and AGA-chipset required.",13,10,0
                even


