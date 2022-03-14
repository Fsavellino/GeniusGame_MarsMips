.eqv STACK_ADDRESS 0x7FFFEFFC

.text 0x00400000
init:
	la 	    $sp, STACK_ADDRESS
	
	la 	    $a0, kb_buffer
	jal	    rb_init
	jal  	enable_keyboard_int
	
	jal 	main
	
	li 	    $v0, 10
	syscall

.include "macros.asm"
.include "ringbuffer.asm"
.include "bitmap.asm"

#=============================================================
# void enable_int
enable_int:
	mfc0 	$t0, $12
	ori  	$t0, $t0, 0x0001
	mtc0 	$t0, $12
	jr 	    $ra

#=============================================================
# void disable_int
disable_int:
	mfc0 	$t0, $12
	andi 	$t0, $t0, 0xFFFE
	mtc0 	$t0, $12
	jr 	    $ra

#=============================================================
# void enable_irq(int irq_num)
enable_irq:
	mfc0 	$t0, $12
	li	    $t1, 1
	addi 	$a0, $a0, 8
	sllv 	$t1, $t1, $a0 #shift l�gico a esquerda, numero de desl. $a0
	or   	$t0, $t0, $t1
	mtc0 	$t0, $12
	jr 	    $ra

#=============================================================
# void disable_irq(int irq_num)
disable_irq:
	mfc0 	$t0, $12
	li	    $t1, 1
	addi 	$a0, $a0, 8
	sllv 	$t1, $t1, $a0 #shift l�gico a esquerda, numero de desl. $a0
	not  	$t1, $t1
	and  	$t0, $t0, $t1
	mtc0 	$t0, $12
	jr 	    $ra

#=============================================================
# void enable_keyboard_int
enable_keyboard_int:
	addi 	$sp, $sp, -8
	sw   	$ra, 0($sp)
	
	jal  	disable_int
	li   	$a0, 0
	jal  	disable_irq
	
	la   	$t0, 0xffff0000
	lw   	$t1, 0($t0)       # Read keyboard control register
	ori  	$t1, $t1, 0x0002  # set bit[1] to 1
	sw   	$t1, 0($t0)	  # Write keyboard control register
	
	li   	$a0, 0
	jal  	enable_irq
	
	jal  	enable_int
	
	lw   	$ra, 0($sp)
	addi 	$sp, $sp, 8
	jr 	    $ra	

#=============================================================
#char kb_get();
kb_get:
	la 	    $t0, 0xffff0000 # keyboard base address

kb_get_pooling:
	lw 	    $t1, 0($t0) 	# Read keyboard control register
	andi 	$t1, $t1, 1 	# Isolando o bit0 do control register
	beq 	$t1, $zero, kb_get_pooling
	
	lb 	    $v0, 4($t0) 	# load keyboard data to $v0
	jr 	    $ra

#=============================================================
# void display_put(char a)
display_put:
 	la 	    $t0, 0xffff0008	# Display register base address 

display_put_pooling:
	lw 	    $t1, 0($t0)	# Read display control register
	andi 	$t1, $t1, 1	# Isolando o bit0 do control register
	beq 	$t1, $zero, display_put_pooling
 	
 	sb 	    $a0, 4($t0)
	jr 	    $ra
	
#=============================================================
#------- 16
# empty  12
# $ra     8
# $s0     4
# $a0     0
# void print_char(char* a)
print_str:
	addiu 	$sp, $sp, -16
	sw    	$s0, 4($sp)
	sw    	$ra, 8($sp)
	
	move 	$s0, $a0
print_str_L0:
	lb   	$a0, 0($s0)
	beqz 	$a0, print_str_end
	jal 	display_put
	addi 	$s0, $s0, 1
	j    	print_str_L0
	
print_str_end:
    lw	    $s0, 4($sp)
	lw	    $ra, 8($sp)
	addiu	$sp, $sp, 16
	jr	    $ra		

#=============================================================
.ktext 0x80000180
interrupt:
	addiu	$sp,$sp,-132
	sw	    $at,0($sp)
	sw	    $v0,4($sp)
	sw	    $v1,8($sp)
	sw	    $a0,16($sp)
	sw	    $a1,20($sp)
	sw  	$a2,24($sp)
	sw  	$a3,28($sp)
	sw  	$t0,32($sp)
	sw  	$t1,36($sp)
	sw  	$t2,40($sp)
	sw  	$t3,44($sp)
	sw  	$t4,48($sp)
	sw  	$t5,52($sp)
	sw  	$t6,56($sp)
	sw  	$t7,60($sp)
	sw	    $s0,64($sp)
	sw  	$s1,68($sp)
	sw  	$s2,72($sp)
	sw  	$s3,76($sp)
	sw  	$s4,80($sp)
	sw  	$s5,84($sp)
	sw	    $s6,88($sp)
	sw	    $s7,92($sp)
	sw  	$t8,96($sp)
	sw  	$t9,100($sp)
	sw	    $k0,104($sp)
	sw  	$k1,108($sp)
	sw  	$gp,112($sp)
	sw  	$fp,116($sp)
	sw  	$ra,120($sp)
	mfhi    $k0
	sw	    $k0,124($sp)
	mflo	$k0
	sw  	$k0,128($sp)
	
	# Identificar a causa da excec�o/interrupc�o
	mfc0 	$k0, $13
	andi	$k0, $k0, 0x007C

	la  	$k1, _kexception_msg
	add 	$k1, $k1, $k0
	lw  	$a0, 0($k1)
	li  	$v0, 4
	syscall
	
	srl 	$k0, $k0, 2
	beqz 	$k0, intHardware

	bge 	$k0, 8, intSoftException
	li 	    $v0, 10
	syscall
	
intSoftException:
	mfc0  	$k0, $14      # $k0 = EPC 
    addiu 	$k0, $k0, 4   # Increment $k0 by 4 
    mtc0  	$k0, $14      # EPC = point to next instruction
   	j	    intDone 

intHardware:
	#Keyboard Interrupt
	la 	    $k0, kb_get
	jalr    $k0
	la	    $a0, kb_buffer
	move	$a1, $v0
	la 	    $k0, rb_write
	jalr	$k0

intDone:
	## Clear Cause register
	mfc0	$t0,$13			# get Cause register, then clear it
	mtc0	$0, $13

	## restore registers
	lw  	$at,0($sp)
	lw  	$v0,4($sp)
	lw  	$v1,8($sp)
	lw  	$a0,16($sp)
	lw  	$a1,20($sp)
	lw  	$a2,24($sp)
	lw  	$a3,28($sp)
	lw  	$t0,32($sp)
	lw  	$t1,36($sp)
	lw  	$t2,40($sp)
	lw  	$t3,44($sp)
	lw  	$t4,48($sp)
	lw  	$t5,52($sp)
	lw  	$t6,56($sp)
	lw  	$t7,60($sp)
	lw  	$s0,64($sp)
	lw  	$s1,68($sp)
	lw  	$s2,72($sp)
	lw  	$s3,76($sp)
	lw  	$s4,80($sp)
	lw  	$s5,84($sp)
	lw  	$s6,88($sp)
	lw  	$s7,92($sp)
	lw  	$t8,96($sp)
	lw  	$t9,100($sp)
	lw  	$k0,104($sp)
	lw  	$k1,108($sp)
	lw  	$gp,112($sp)
	lw  	$fp,116($sp)
	lw  	$ra,120($sp)
	lw  	$k0,124($sp)
	mthi    $k0
	lw  	$k0,128($sp)
	mtlo	$k0
	addiu	$sp,$sp,132
	eret
#===========================================================
.kdata
_kexception_msg: .word _kexc_hardware, _kexc_unknown, _kexc_unknown , _kexc_unknown
		         .word _kexc_addrl, _kexc_addrs, _kexc_ibus , _kexc_dbus
		         .word _kexc_syscall, _kexc_bkpt, _kexc_ri , _kexc_unknown
		         .word _kexc_ovf, _kexc_trap, _kexc_unknown , _kexc_fpe
				 
_kexc_unknown: 	.asciiz   "Exception Unknown\n"
_kexc_hardware: .asciiz   "Hardware Interrupt\n"
_kexc_addrl: 	.asciiz   "Address error exception caused by load or instruction fetch\n"
_kexc_addrs: 	.asciiz   "Address error exception caused by store\n"
_kexc_ibus: 	.asciiz   "Bus Error on instruction fetch\n"
_kexc_dbus: 	.asciiz   "Bus Error on data load or store\n"
_kexc_syscall: 	.asciiz   "Syscall exception\n"
_kexc_bkpt: 	.asciiz   "Breakpoint exception\n"
_kexc_ri: 	    .asciiz   "Reserved instruction exception\n"
_kexc_ovf: 	    .asciiz   "Arithmetic overflow ocurred\n\n"
_kexc_trap: 	.asciiz   "TRAP ocurred\n"
_kexc_fpe: 	    .asciiz   "Floating Point Exception\n"

alloc_ringbuffer(kb_buffer)
