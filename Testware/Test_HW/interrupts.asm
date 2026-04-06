DEFC	DMA_TRIGGER 	  = $7D85
DEFC	DMA_BASE   		  = $7800
DEFC	REG_VBLANK_ENABLE = $7D84
DEFC	SPRITE_RAM		  = $7000
DEFC	TILE_RAM		  = $7400
DEFC	REG_SPRITE        = $7d83   ; cleared at program start and never used
DEFC	REG_PALETTE_A     = $7d86
DEFC	REG_PALETTE_B     = $7d87
DEFC	REG_FLIPSCREEN    = $7d82

SECTION CODE

PUBLIC _z80_nmi
_z80_nmi:
    ; nmi
    push	AF
    push    HL

    xor     A               ; A := 0
    ld      (REG_VBLANK_ENABLE),A       ; disable interrupts
    ; hl is preloaded with dma_config address
    ; This copies the sprite data from $6900 to $7000
    ; Presumably the reason sprite data isn't stored in $7000 in the first place is to ensure it's updated only during vblank.
    ld      hl,dma_config        ; load hl with start of table data
    ld      (DMA_TRIGGER),A      ; store into P8257 DRQ DMA Request
    ld      A,(hl)          	 ; load table data ($53)
    ld      (DMA_BASE+8),A       ; store into P8257 control register
    inc     hl              	 ; next table entry
    ld      A,(hl)         	 	 ; load table data ($00)
    ld      (DMA_BASE),A         ; store into P8257 control register
    inc     hl              	 ; next table entry
    ld      A,(hl)          	 ; load table data ($69)
    ld      (DMA_BASE),A         ; store into P8257 control register
    inc     hl              	 ; next table entry
    ld      A,(hl)          	 ; load table data ($80)
    ld      (DMA_BASE+1),A       ; store into P8257 control register
    inc     hl              	 ; next table entry
    ld      A,(hl)          	 ; load table data ($41)
    ld      (DMA_BASE+1),A       ; store into P8257 control register
    inc     hl              	 ; next table entry
    ld      A,(hl)          	 ; load table data ($00)
    ld      (DMA_BASE+2),A       ; store into P8257 control register
    inc     hl              	 ; next table entry
    ld      A,(hl)          	 ; load table data ($70)
    ld      (DMA_BASE+2),A       ; store into P8257 control register
    inc     hl              	 ; next table entry
    ld      A,(hl)          	 ; load table data ($80)
    ld      (DMA_BASE+3),A       ; store into P8257 control register
    inc     hl              	 ; next table entry
    ld      A,(hl)          	 ; load table data ($81)
    ld      (DMA_BASE+3),A       ; store into P8257 control register
    ld      A,$01           	 ; A := 1
    ld      (DMA_TRIGGER),A      ; store into P8257 DRQ DMA Request
    xor     A               	 ; A := 0
    ld      (DMA_TRIGGER),A      ; store into P8257 DRQ DMA Request
    ld 		HL, _FrameCounter ; Charger l'adresse du compteur 32 bits

    ; Octet de poids faible
    inc		(HL)             ; incrémenter l'octet
    jr 		NZ, return_from_nmi ; Si pas de dépassement, retour

    ; Octet suivant (2e octet)
    inc 	HL               ; Passer à l'octet suivant
    inc 	(HL)             ; incrémenter
    jr 		NZ, return_from_nmi

    ; Octet suivant (3e octet)
    inc 	HL               ; Passer à l'octet suivant
    inc 	(HL)             ; incrémenter
    jr 		NZ, return_from_nmi

    ; Octet de poids fort (4e octet)
    inc 	HL               ; Passer à l'octet suivant
    inc 	(HL)             ; incrémenter

return_from_nmi:
    ld      A, 1
    ld      (REG_VBLANK_ENABLE),A       ; enable interrupts

    pop     HL
    pop	    AF

    retn

dma_config:
    defb	$53, $00, $69, $80, $41, $00, $70, $80, $81

SECTION BSS

PUBLIC _FrameCounter
_FrameCounter:
    defs 4
