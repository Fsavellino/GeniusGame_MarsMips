.eqv RINGBUFFER_SIZE 16

.macro alloc_ringbuffer (%name)
.data
%name: .space 12
       .space RINGBUFFER_SIZE
.end_macro

.text
#=============================================================
# void rb_init(t_ringbuffer * rbuf)
rb_init:
	sw 		$zero, 0($a0)
	sw 		$zero, 4($a0)
	sw 		$zero, 8($a0)
	jr 		$ra

#=============================================================
# bool rb_empty(t_ringbuffer * rbuf)
rb_empty:
	li 		$v0, 1
	lw  		$t0, 0($a0)
	beqz 		$t0, rb_empty_end
	li 		$v0, 0
rb_empty_end:
	jr 		$ra

#=============================================================
# bool rb_full(t_ringbuffer * rbuf)
rb_full:
	li 		$v0, 1
	lw 		$t0, 0($a0)
	beq 	$t0, RINGBUFFER_SIZE, rb_full_end
	li 		$v0, 0
rb_full_end:
	jr 		$ra

#===========================================
# Stack
# ra    4 (sp)
# a0    0 (sp)
# ------------------------------------------
# char rb_read(t_ringbuffer * rbuf)
rb_read:
	addiu	$sp, $sp, -8
	sw		$ra, 4($sp)
	
	jal 		rb_empty
	bnez 		$v0, rb_read_empty_true
	
	# rbuf->size--;
	lw		$t0, 0($a0)
	addi		$t0, $t0, -1
	sw		$t0, 0($a0)
	
	# tmp = rbuf->buf[rbuf->rd];
	addiu	$t0, $a0, 12
	lw		$t1, 4($a0)
	addu		$t0, $t0, $t1
	lb		$v0, 0($t0)   
	
	# rbuf->rd = (rbuf->rd + 1) % MAX_SIZE;
	addiu	$t1, $t1, 1
	li		$t0, RINGBUFFER_SIZE
	div		$t1, $t0
	mfhi		$t1
	sw		$t1, 4($a0)
	j		rb_read_end
	
rb_read_empty_true:
	li		$v0, 0
	
rb_read_end:
	lw		$ra, 4($sp)
	addiu	$sp, $sp, 8
	jr 		$ra
	
#===========================================
# Stack
# ra   4(sp)
# a0   0(sp)
#-------------------------------------------
#bool rb_write(t_ringbuffer * rbuf, char byte)	
rb_write:
	addiu	$sp, $sp, -8
	sw		$ra, 4($sp)
	
	jal 		rb_full
	bnez 		$v0, rb_write_full_true

	# wbuf->size++;
	lw		$t0, 0($a0)
	addi		$t0, $t0, 1
	sw		$t0, 0($a0)
	
	# tmp = wbuf->buf[wbuf->wr];
	addiu	$t0, $a0, 12
	lw		$t1, 8($a0)
	addu		$t0, $t0, $t1
	sb		$a1, 0($t0)   
	
	# wbuf->wr = (wbuf->wr + 1) % MAX_SIZE;
	addiu	$t1, $t1, 1
	li		$t0, RINGBUFFER_SIZE
	div		$t1, $t0
	mfhi		$t1
	sw		$t1, 8($a0)
	li		$v0, 1
	j		rb_write_end
	
rb_write_full_true:
	li		$v0, 0
	
rb_write_end:
	lw		$ra, 4($sp)
	addiu	$sp, $sp, 8
	jr 		$ra
	
