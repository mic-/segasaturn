! XorGegga - The Saturn version
! Mic, 2008
!
! Dual processor version
! Mic, 2009
! Watch for _init_slave and _slave

	.text
	.align 1
	.global	_start
	
_start:

! Fill in the rest of the sine table by mirroring the first quadrant

	mov.l	sintb,r6
	mov	r6,r3
	add	#64,r3
	mov	#64,r0
	mov 	#192,r2
	extu.b 	r2,r2
	mov	r2,r14
	mov	#128,r1
	extu.b	r1,r1
_setup_sine:
	add 	#-1,r0
	and 	#127,r0
	mov.b 	@(r0,r6),r5
	cmp/hi 	r1,r2
	bt 	__1
	neg 	r5,r5
__1:
	mov.b 	r5,@r3
	dt 	r2
	bf/s 	_setup_sine
	add 	#1,r3
	
	mov.l	RAMCTL,r11
	mov.l	RAMCTL_mask,r6
	mov.w	@r11,r0
	and	r0,r6
	mov.w	r6,@r11

! Set up a palette going from black->blue->red->yellow->white

	add	r1,r1
	mov 	#144,r3
	extu.b 	r3,r3
	mov 	#0,r5	! r
	mov 	#0,r6	! g
	mov 	#0,r7	! b
	mov.l 	VDP2_CRAM,r8
	mov 	#0,r9	! i
	mov.w 	bit15,r10
_set_pal:
	mov 	#48,r0
	cmp/ge 	r0,r9
	bt 	_check_48_96
_inc_blue:	
	mov 	r2,r7
__2:
	bra 	_clip_color
	shlr2 	r7
_check_48_96:
	mov 	#96,r0
	cmp/ge 	r0,r9
	bt 	_check_96_144
	mov 	r2,r5
	shlr2 	r5
	mov 	#141,r0
	extu.b 	r0,r0
	sub 	r2,r0
	bra	__2
	mov r0,r7
_check_96_144:
	cmp/ge 	r3,r9
	bt 	_check_144_192
	mov 	r2,r6
	bra 	_clip_color
	shlr2 	r6
_check_144_192:
	cmp/ge 	r14,r9
	bf	_inc_blue
_clip_color:	
	mov 	#31,r0
	cmp/gt 	r0,r5
	bf 	_r_ok
	mov 	#31,r5
_r_ok:
	cmp/gt 	r0,r6
	bf 	_g_ok
	mov 	#31,r6
_g_ok:
	cmp/gt 	r0,r7
	bf 	_b_ok
	mov 	#31,r7
_b_ok:
	mov 	r7,r0
	shll2 	r0
	shll2 	r0
	add 	r0,r0
	or 	r6,r0
	shll2 	r0
	shll2 	r0
	add 	r0,r0
	or 	r5,r0
	or 	r10,r0
	mov.w 	r0,@r8
	add 	#3,r2
	cmp/eq 	r3,r2
	bf 	_i3_ok
	mov 	#0,r2
_i3_ok:
	add 	#1,r9
	cmp/eq 	r9,r1
	bf/s 	_set_pal
	add 	#2,r8


! Set up the VDP2 registers

	mov	r1,r8
	add 	#0x2e,r11	!Point to MPOFN
	mov	#0,r2
	mov.w	r2,@r11
	add 	#0x3c,r11	! Point to ZMXIN0
	mov.w 	r2,@-r11	! Clear SCYDN0
	mov.w 	r2,@-r11	! SCYIN0
	mov.w 	r2,@-r11	! SCXDN0
	mov.w 	r2,@-r11	! SCXIN0
	add 	#-72,r11	! Point to CHCTLA
	mov	#0x12,r2
	mov.w	r2,@r11
	add	#-8,r11		! Point to BGON
	add	#1,r8
	mov.w	r8,@r11
	add	#-32,r11	! Point to TVMD
	mov.w	r10,@r11
	add 	#4,r11		! Point to TVSTAT

! Initialize the slave processor

	bsr	_init_slave
	nop

! Wait a little while to give the slave processor a chance to disable the FRT interrupt

	bsr	_wait_vbl
	nop
	
	mov	#0,r13		! Plasma movement delta
_main_loop:
	mov.l	FTCSR,r1
	mov	#0,r0
	mov.b	r0,@r1		
	
	mov.l	FRTICM,r1
	mov	#0xFF,r0	
	mov.w	r0,@r1		! Trigger the high bit in FTCSR on the slave side to be set
	
	mov.l 	VDP2_VRAM,r8
	mov 	#224,r2		! maxy
	extu.b 	r2,r2
	mov	r2,r12
	mov 	#0,r3		! y
	mov.l 	vscreen,r9
	mov.l	sintb,r15
_yloop:
	mov 	#80,r4
	shll2 	r4		! maxx
_xloop:
	mov	r2,r1
	add	r13,r1
	extu.b	r1,r0
	mov.b	@(r0,r15),r6
	mov	r4,r7
	shll2	r7
	add	r7,r7
	add	r7,r6
	mov	r4,r1
	add	r13,r1
	extu.b	r1,r0
	mov.b	@(r0,r15),r7
	add	r3,r7
	xor	r6,r7
	mov	#0x90,r0
	extu.b	r0,r0
	and	r0,r7
	tst	r7,r7
	bt	_no_dec
	add	#-1,r7
_no_dec:
	mov.b 	@(0,r9),r0
	extu.b	r0,r0		! Using r0 directly after a mov.b @(disp,Rm),r0 is supposed to be disallowed, but seems to work
	add	r0,r7
	mov.b 	@(1,r9),r0
	extu.b	r0,r0
	add	r0,r7
	mov.b 	@(2,r9),r0
	extu.b	r0,r0
	add	r7,r0
	shlr2	r0
	mov.b 	r0,@(0,r9)
	dt 	r4
	bf/s 	_xloop
	add 	#1,r9
	add	#4,r3
	dt 	r2
	mov	#112,r0
	cmp/eq	r0,r2
	bf	_yloop

	bsr	_wait_vbl
	nop
	
! Copy the 320x224 offscreen buffer to BG0 (which is 512x256)

	mov.l	vscreen,r3	
_copy_to_vram_y:
	mov	#80,r2
_copy_to_vram_x:
	mov.l	@r3+,r1
	mov.l	r1,@r8
	dt	r2	
	bf/s	_copy_to_vram_x
	add	#4,r8
	dt	r12
	bf/s	_copy_to_vram_y
	add	r14,r8		! r14 contains #192
	
	mov.w	delta_inc,r0
	bra	_main_loop
	add	r0,r13
		

! Wait for vblank
_wait_vbl:
_wait_out:
	mov.w	@r11,r0
	tst	#8,r0	
	bf	_wait_out
_wait_in:
	mov.w	@r11,r0
	tst	#8,r0
	bt	_wait_in
	rts
	nop
	
	

! Called by the main SH2 to enable the slave SH2	
_init_slave:
	mov.l	FRTINT,r1
	mov	#1,r0
	mov.b	r0,@r1	! TIER FRT INT disable
	
	mov.l	SMPC_SF,r1
	mov.l	SMPC_COM,r2
3:
	mov.b	@r1,r0
	tst	#1,r0
	bf	3b

	mov	#1,r0
	mov.b	r0,@r1	! *SMPC_SF = 1
	mov	#3,r0
	mov.b	r0,@r2	! *SMPC_COM = SSHOFF
4:
	mov.b	@r1,r0
	tst	#1,r0
	bf	4b

	mov	#125,r0
	shll2	r0
6:
	dt	r0
	bf	6b
	
	! Set slave entry point address
	mov.l	slave,r4
	mov.l	SLVENTRY,r3
	mov.l	r4,@r3
	
	mov.l	SMPC_SF,r1
	mov.l	SMPC_COM,r2
	mov	#1,r0
	mov.b	r0,@r1	! *SMPC_SF = 1
	mov	#2,r0
	mov.b	r0,@r2	! *SMPC_COM = SSHON
5:
	mov.b	@r1,r0
	tst	#1,r0
	bf	5b
	rts
	nop

bit15:
	.short	0x8000



! This is the slave SH2 entry point
_slave:
	! Set the interrupt mask bits
	stc	sr,r0
	mov.w	int_mask,r1
	and	r1,r0
	mov	#0xf0,r1
	extu.b	r1,r1
	or	r1,r0
	ldc	r0,sr

	mov.l	IPRA,r1
	mov	#0,r0
	mov.w	r0,@r1		! Set interrupt priority levels
	mov.l	IPRB,r1
	mov.w	r0,@r1		! ...
	mov.l	FRTINT,r1
	mov	#1,r0
	mov.b	r0,@r1		! Disable FRT interrupt

	mov	#0,r13		! Plasma movement delta

	! Wait for a command
_slave_loop:
	mov.l	FTCSR,r1
	mov.b	@r1,r0
	tst	#0x80,r0
	bt	_slave_loop	! If bit 7 is clear there's no command, try again
	mov	#0,r0
	mov.b	r0,@r1		! Clear the flag

	! Draw the bottom half of the screen	   
	mov 	#112,r2		! maxy
	extu.b 	r2,r2
	mov 	#112,r3		! y
	shll2	r3
	mov.l 	vscreen_lower,r9
	mov.l	sintb,r12
_yloop_s:
	mov 	#80,r4
	shll2 	r4		! maxx
_xloop_s:
	mov	r2,r1
	add	r13,r1
	extu.b	r1,r0
	mov.b	@(r0,r12),r6
	mov	r4,r7
	shll2	r7
	add	r7,r7
	add	r7,r6
	mov	r4,r1
	add	r13,r1
	extu.b	r1,r0
	mov.b	@(r0,r12),r7
	add	r3,r7
	xor	r6,r7
	mov	#0x90,r0
	extu.b	r0,r0
	and	r0,r7
	tst	r7,r7
	bt	_no_dec_s
	add	#-1,r7
_no_dec_s:
	mov.b 	@(0,r9),r0
	extu.b	r0,r0		
	add	r0,r7
	mov.b 	@(1,r9),r0
	extu.b	r0,r0
	add	r0,r7
	mov.b 	@(2,r9),r0
	extu.b	r0,r0
	add	r7,r0
	shlr2	r0
	mov.b 	r0,@(0,r9)
	dt 	r4
	bf/s 	_xloop_s
	add 	#1,r9
	add	#4,r3
	dt 	r2
	bf	_yloop_s
	
	mov	#129,r0
	extu.b	r0,r0
	shll	r0
	bra	_slave_loop
	add	r0,r13	



delta_inc:
	.short	258
int_mask:
	.short	0xFF0F
	
	.align 2
stack_init:
	.long	0x06002000
SMPC_SF:	
	.long 	0x20100063
SMPC_COM: 	
	.long 	0x2010001F
SLVENTRY:	
	.long 	0x06000250
slave:		
	.long 	_slave
FRTINT:
	.long	0xFFFFFE10
FTCSR:
	.long	0xFFFFFE11
IPRA:
	.long	0xFFFFFEE2
IPRB:
	.long	0xFFFFFE60
CACHECTL:
        .long 	0xFFFFFE92
FRTICM:	
	.long	0x21000000
FRTICS:	
	.long	0x21800000
RAMCTL:
	.long	0x25F8000E
RAMCTL_mask:
	.long	0xCFFF
VDP2_CRAM:
	.long	0x25F00000
sintb:
	.long	_sintb
vscreen:
	.long	_vscreen
vscreen_lower:
	.long	_vscreen+320*112
VDP2_VRAM:
	.long	0x25e00000

! FLOOR(SIN(I*PI/128)*256) for I = 0..63	
_sintb:
	.byte 0,3,6,9,12,15,18,21,24,28,31,34,37,40,43,46,48,51,54,57,60,63,65,68
	.byte 71,73,76,78,81,83,85,88,90,92,94,96,98,100,102,104,106,108,109,111
	.byte 112,114,115,117,118,119,120,121,122,123,124,124,125,126,126,127,127
	.byte 127,127,127
	.comm	sintb_rest,192,4

	.comm	_vscreen,71680,4

