.include "kernel.asm"

.eqv RED_ON         0x00FF0000
.eqv RED_OFF        0x00700000
.eqv RED_X          1
.eqv RED_Y          1
.eqv RED_CHAR       113

.eqv GREEN_ON       0x0000FF00
.eqv GREEN_OFF      0x00007000
.eqv GREEN_X    	2
.eqv GREEN_Y        1
.eqv GREEN_CHAR     119

.eqv BLUE_ON        0x000000FF
.eqv BLUE_OFF       0x00000070
.eqv BLUE_X	        1
.eqv BLUE_Y         2
.eqv BLUE_CHAR      97

.eqv YELLOW_ON      0x00FFFF00
.eqv YELLOW_OFF     0x00707000
.eqv YELLOW_X	    2
.eqv YELLOW_Y       2
.eqv YELLOW_CHAR    115

.eqv BLINK_DELAY    500

.data
genius_steps:    .word 8
genius_sequence: .asciiz "qwssasqq"

str_hello:.asciiz "Genius Game! Have fun!\n"
str_won:  .asciiz "You won! Congrats!\n"
str_lose: .asciiz "You lose. Try again.\n" 

.text
#=============================================================
# old_stack				16($sp)
# ----------------------
# < empty >				12($sp)
# ----------------------
# $ra					8($sp)
# ----------------------
# $s0					4($sp)
# ----------------------
# $a0					0($sp)
# ----------------------
# int main()
main:
	addi 	$sp, $sp, -16
	sw	    $s0, 4($sp)
	sw   	$ra, 8($sp)
	
	jal 	init_genius
		
	la	    $a0, str_hello
	jal 	print_str
	
	lw	    $s0, genius_steps
	li      $s1, 1
	
main_L0:
	bgt	    $s1, $s0, main_L0_end
	
	la	    $a0, genius_sequence
	move	$a1, $s1
	jal	    blink_sequence

	la	    $a0, genius_sequence
	move	$a1, $s1
	jal	    check_sequence
	
	bnez 	$v0, main_L0_skip
	la	    $a0, str_lose
	jal	    print_str
	j	    main_L0_exit
	
main_L0_skip:
	addi    $s1, $s1, 1
	j	    main_L0

main_L0_end:
	la	    $a0, str_won
	jal	    print_str
	
main_L0_exit:
	lw   	$ra, 8($sp)
	lw	    $s0, 4($sp)
	addi 	$sp, $sp, 16
	jr 	    $ra
 
#=============================================================
# init_genius()
init_genius:
	addiu 	$sp, $sp, -8
	sw	    $ra, 0($sp)
	
	li	    $a0, RED_X
	li 	    $a1, RED_Y
	li	    $a2, RED_OFF
	jal 	set_pixel
	
	li	    $a0, GREEN_X
	li 	    $a1, GREEN_Y
	li	    $a2, GREEN_OFF
	jal	    set_pixel
	
	li	    $a0, BLUE_X
	li 	    $a1, BLUE_Y
	li	    $a2, BLUE_OFF
	jal 	set_pixel
	
	li	    $a0, YELLOW_X
	li 	    $a1, YELLOW_Y
	li	    $a2, YELLOW_OFF
	jal 	set_pixel

	lw    	$ra, 0($sp)
	addiu 	$sp, $sp, 8
	jr 	    $ra

loop_generate_sequence:
		li $v0, 30 			# System Time syscall
		syscall                  	# $a0 will contain the 32 LS bits of the system time
		move $t1, $a0
		
		li $v0, 40 			# random seed
		li $a0, 1 			# id
		move $a1, $t1
		syscall	
	
		jr $ra
	
beep_number:
	
		li $v0, 33
		
		li $a0, 60			#pitch
		lw $a1, BLINK_DELAY
		li $a2, 32 			# instrument
		li $a3, 105 			# volume
		syscall
		
		jr $ra

#=============================================================
# void blink_button(btn_id)
blink_button:
		# a0: x0
		# a1: y0
		# a2: x1
		# a3: y1
		sw $a0, 0($sp)
		sw $a1, 4($sp)
		sw $a2, 8($sp)
		
		# 0($sp) a0 setPixel
		# 4($sp) a1 setPixel		
		# 8($sp) a2 setPixel
		
		beqz $a0, light_verde
		beq $a0, 1, light_vermelho
		beq $a0, 2, light_azul
		beq $a0, 3, light_amarelo
	
		b blink_button
	
	light_verde:	
		li	$s0, GREEN_X
		li	$s1, GREEN_Y
		li	$s2, GREEN_ON
		li	$s3, GREEN_OFF
		b 	loop_x
	light_vermelho:
		li	$s0, RED_X
		li	$s1, RED_Y
		li	$s2, RED_ON
		li	$s3, RED_OFF
		b	loop_x
	light_azul:
		li	$s0, BLUE_X
		li	$s1, BLUE_Y
		li	$s2, BLUE_ON
		li	$s3, BLUE_OFF
		b	loop_x
	light_amarelo:
		li	$s0, YELLOW_X
		li	$s1, YELLOW_Y
		li	$s2, YELLOW_ON
		li	$s3, YELLOW_OFF
	
	loop_x:
		move $a0, $s0
		move $a1, $s1
		move $a2, $s2
		jal set_pixel
		
						#li $v0,32
		jal beep_number	#li $a0, BLINK_DELAY
		                            	#syscall
		
		move $a0, $s0
		move $a1, $s1
		move $a2, $s3
		jal set_pixel
	
	loop_y:
		lw $s0, 12($sp)
		lw $s1, 16($sp)
		lw $s2, 20($sp)
		lw $s3, 24($sp)
		lw $s4, 28($sp)
		addiu $sp, $sp, 32
		jr $ra
		
#=============================================================
# void blink_sequence(char * seq, int steps) 
blink_sequence:

	addiu $sp, $sp, -16
	sw     $s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$ra,12($sp)
	
	move	$s0, $a0
	move $s1, $a1

blink_sequence_L0:

	beqz $s1, blink_sequence_L0_end
	
	lb $a0, 0($s0)
	jal blink_button                 # puxando blink_button
	
	li $v0, 32
	li $a0, BLINK_DELAY       # realizando delay de 500ms
	syscall
	
	add $s0, $s0, 1
	addi $s1, $s1, -1
	j blink_sequence_L0

blink_sequence_L0_end:
	
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $ra, 12($sp)
	addiu $sp, $sp, 16

	jr 	    $ra
#=============================================================
# bool check_sequence(char * seq, int steps)
check_sequence:

	jr 	    $ra
#=============================================================
