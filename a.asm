
	.cpu "6502i"
	.enc "ascii"
	.cdef " ~",$20
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; header
	
	.text "NES",$1a
	.byte $02,$04
	.byte $10
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; variables
	
	
rawjoy_1 = $16
joy_1 = $17
rawjoy_2 = $18
joy_2 = $19
	
	.virtual $c9

four_score_sig	.byte ?

rawjoy_3	.byte ?
joy_3	.byte ?
rawjoy_4	.byte ?
joy_4	.byte ?

rawjoy_current	.byte ?
joy_current	.byte ?
	
	
	.cerror * > $100, "zp vars too long"
	.endv
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; old bank
	
	* = $10
	.binary "Anticipation (U) [!].nes",$10
	
	* = $10
	.logical $8000
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;; mapper setup
	
	.comment
	* = $803f
	lda #$1f
	* = $86e3
	lda #$1f
	* = $86eb
	lda #$1e
	* = $894c
	lda #$1f
	* = $89ca
	lda #$1f
	* = $8b74
	lda #$1c
	
	* = $ffe1
	lda #$1f
	* = $fff0
	lda #$02
	.endc
	
	
	* = $fff8
	.byte $9e,$9e
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;; raster timing fixes
	
	* = $8130 ;title
	ldx #$88
	* = $abd4 ;board
	lda 0
	sta $2000
	jmp $a99c
	* = $c397 ;ending
	ldx #$70
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;; randomizer unfucker
	
	* = $df33
	lda $12
	ora $13
	ora $14
	ora $15
	beq +
	lda $12
	lsr
	ror $13
	ror $14
	ror $15
	bcc ++
+	eor #$a3
+	sta $12
	rts
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;; read joy hook
	
	* = $8ee4
	ldx #1
	stx $4016
	stx $05
	stx $07
	stx four_score_sig
	dex
	stx $4016
	
-	lda $4016
	and #3
	cmp #1
	rol $04,x
	lda $4017
	and #3
	cmp #1
	rol $05,x
	bcc -
	inx
	inx
	cpx #4
	bcc -
	
	jmp read_joy_2
	.cerror * > $8f15, "read joy code too long"
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;; simplify memclear
	; for some reason there is a special string written and checked,
	; but there are no reset-persistent variables in RAM
	
	* = $8f15
	lda #0
	tax
-	sta $00,x
	sta $0200,x
	sta $0300,x
	sta $0400,x
	sta $0500,x
	sta $0600,x
	sta $0700,x
	inx
	bne -
	rts
	
	
	
read_joy_2
-	lda $4016
	and #3
	cmp #1
	rol four_score_sig
	bcc -
	
	lax $04
	eor rawjoy_1
	stx rawjoy_1
	sax joy_1
	
	lax $05
	eor rawjoy_2
	stx rawjoy_2
	sax joy_2
	
	jmp read_joy_3
	
	.cerror * > $8f52, "memclear code too long"
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;; player button check hook
	
	* = $8d9a
	jsr are_controllers_unique
	beq +
	
	; not unique controllers, check A/B or D-pad depending on player
	stx $43
	
	asl
	asl
	ora $43
	tay
	
	;txa
	and #2
	tax
	lda joy_1,x
	ldx $43
	
	and player_buttons_tbl - 4,y
	rts
	
	; unique controllers, read all buttons
+	ldy joy_ptr_tbl,x
	lda $01,y
	php
	ldy #4 ;make controller-info-drawing think the buttons index is 0
	plp
	rts
	
	
	
	
	; if the controllers are not shared by players,
	; return Z set
are_controllers_unique
	lda four_score_sig
	cmp #$10
	beq +
	lda $ac
	cmp #2
+	rts
	
	
	.cerror * > $8dcc, "player button check code too long"
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;; get current player controller
	
	* = $8c5d
	ldy $046e
	dey
	jsr are_controllers_unique
	beq +
	tya
	lsr
	tay
+	ldx joy_ptr_tbl,y
	lda $00,x
	sta rawjoy_current
	lda $01,x
	sta joy_current
	rts
	
joy_ptr_tbl	.byte rawjoy_1,rawjoy_2,rawjoy_3,rawjoy_4
	
	
	.cerror * > $8c7b, "$8c5d-unfuck code too long"
	
	* = $a455
	nop
	nop
	nop
	* = $a4ed
	lda joy_current
	* = $a4fe
	lda rawjoy_current
	
	
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;; control indicators
	
	.comment
	* = $90b9
	ldx #0
	jsr are_controllers_unique
	beq $90cd
	jsr get_player_buttons_tbl_index
	tay
	lda player_buttons_tbl - 4,y
	cmp #$ff
	beq $90cd
	ldx #$08
	asl
	bmi $90cd
	ldx #$10
	
	
	
	.cerror * > $90cd, "control indicator code too long"
	.fill $90cd-*, $ea
	.endc
	
	* = $90bc
	lda player_buttons_tbl - 4,y
	
	
	
	;;;;;;;;;;;;;;;;;;;;;;;; free space code
	
	* = $ff5c
	
read_joy_3
	
	lax $06
	eor rawjoy_3
	stx rawjoy_3
	sax joy_3

	lax $07
	eor rawjoy_4
	stx rawjoy_4
	sax joy_4
	
	rts
	
	
	
player_buttons_tbl
	.byte $ff,$00,$00,$00
	.byte $ff,$ff,$00,$00
	.byte $0f,$c0,$ff,$00
	.byte $0f,$c0,$0f,$c0
	
	
	.text "KRM"
	
	
	.cerror * > $ff80, "fixed bank code too long"
	
	.here
	
	