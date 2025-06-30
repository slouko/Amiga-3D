
        INCLUDE "constants.s"

        section "main",code_f

start:
.chk_aga:
                move.l  4.w,a6
                moveq   #0,d0
                lea     gfx_name(pc),a1
                jsr     OpenLib(a6)         ; _LVOOpenLibrary
                move.l  d0,gfx_base

                bsr     initialize          ; initialize the main program
 
                move.l  gfx_base(pc),a6
                move.l  38(a6),old_copper       ; store old copper list address
                move.l  34(a6),old_view         ; store old WB view.

                sub.l   a1,a1
                jsr     LoadView(a6)            ; _LVOLoadView(Null)
                jsr     GLWaitTOF(a6)           ; _LVOWaitTOF
                jsr     GLWaitTOF(a6)           ; _LVOWaitTOF

                move.l  4.w,a6
                jsr     Forbid(a6)              ; LVOForbid

                lea     get_vbr(pc),a5
                jsr     Supervisor(a6)         ; _LVOSupervisor

                lea     $dff000,a6
                move.w  INTENAR(a6),old_intena
                move.w  INTREQR(a6),old_intreq
                move.w  DMACONR(a6),old_dmacon
                move.w  ADKCONR(a6),old_adkcon
                
                move.l  gfx_base(pc),a6
                jsr     GLWaitTOF(a6)        ; WaitTOF

            	move.l  vector_base(pc),a0
                move.l  INT3(a0),old_int3   ; save system VBI vector
                move.l  #vbl_int,INT3(a0)

                lea     $dff000,a6
                move.w  #D_SETCLR+D_ALL+D_COPP+D_BTPL+D_BLIT,DMACON(a6)
                move.w  #I_SETCLR+I_INTEN+I_VBL,INTENA(a6)

                bsr     main            ; call the main routine

                move.l  vector_base(pc),a0
                move.l  old_int3,INT3(a0)   ; restore system VBL IRQ

                lea     $dff000,a6
                move.w  #$7fff,d0
                move.w  d0,INTENA(a6)
                move.w  d0,INTREQ(a6)
                move.w  d0,DMACON(a6)       ; disable all irqs + dmas
                addq.w  #1,d0
                move.w  old_intena(pc),d1   ; then restore system irqs + dmas
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
                
                move.l  old_copper(pc),COP1LC(a6)   ; restore system copperlist
                move.l  gfx_base(pc),a6
                move.l  old_view(pc),a1
                jsr     LoadView(a6)                ; _LVOLoadview(OldView)

                move.l  4.w,a6
                move.l  gfx_base(pc),a1
                jsr     CloseLib(a6)                ; close graphics.library

                jsr     Permit(a6)                  ; _LVOPermit
                moveq   #0,d0                       ; clean exit
                rts

                ; Supervisor mode code for getting vector base register (VBR)

get_vbr:        movec   VBR,d0 
                move.l  d0,vector_base
                nop
                rte


vbl_int:
                ; because VBL interrupt is shared irq level with copper and blitter
                ; we test it first that the occurring IRQ is actuallu Vertical Blanking
                btst #IB_VBL,$dff001+INTREQR    ; ensure it's vbl irq
                beq .not_vbi                    ; if it is not, just ignore and exit
         
                movem.l d0-a6,-(sp)             ; if it really is VBL IRQ
                bsr     vbl_subroutine          ; then call subroutine in the main code
                lea     $dff000,a6
                moveq   #I_VBL,d0
                move.w  d0,INTREQ(a6)           ; acknowledge the IRQ
                move.w  d0,INTREQ(a6)           ; twice for compatibility
                movem.l (sp)+,d0-a6 
.not_vbi:
                nop
                rte                             ; exit from IRQ


vector_base:    dc.l    0
old_adkcon:     dc.w    0
old_dmacon:     dc.w    0
old_intena:     dc.w    0
old_intreq:     dc.w    0
old_int3:       dc.l    0
old_copper:     dc.l    0
old_view:       dc.l    0
gfx_base:       dc.l    0
gfx_name:       dc.b    "graphics.library",0

                even

