######################

# Aluno: Fabio Schmitt Avelino

######################
.include "kernel.asm"

.eqv RED_ON         0x00FF0000
.eqv RED_OFF        0x00700000
.eqv RED_X          1
.eqv RED_Y          1
.eqv RED_CHAR       113
.eqv RED_SOM	70

.eqv GREEN_ON       0x0000FF00
.eqv GREEN_OFF      0x00007000
.eqv GREEN_X    	2
.eqv GREEN_Y        1
.eqv GREEN_CHAR     119
.eqv GREEN_SOM 60

.eqv BLUE_ON        0x000000FF
.eqv BLUE_OFF       0x00000070
.eqv BLUE_X	        1
.eqv BLUE_Y         2
.eqv BLUE_CHAR      97
.eqv BLUE_SOM  50

.eqv YELLOW_ON      0x00FFFF00
.eqv YELLOW_OFF     0x00707000
.eqv YELLOW_X	    2
.eqv YELLOW_Y       2
.eqv YELLOW_CHAR    115
.eqv YELLOW_SOM 40

.eqv BLINK_DELAY    500

.data
genius_steps:    .word 1           
genius_sequence: .space 8

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
	
	li	$v0,32	
	li	$a0, BLINK_DELAY	#delay para separar o blink sequence do check sequence
	syscall
	
	la	    $a0, genius_sequence
	move	$a1, $s1
	jal	    blink_sequence

	la	    $a0, genius_sequence
	move	$a1, $s1
	jal	    check_sequence
	
	bnez 	$v0, main_L0_skip
	la	    $a0, str_lose
	jal	    print_str
	
	# beep_lose
	li $v0, 33
	li $a0, 60 		
	li $a1, 500
	li $a2, 30 		# instrument
	li $a3, 90 		# volume
	syscall
	
	j	    main_L0_exit

main_L0_skip:
	
	addi    $s1, $s1, 1
	j	    main_L0

main_L0_end:
	
	la	    $a0, str_won
	jal	    print_str
	#beep_won
	li $v0, 33
	li $a0, 120 		
	li $a1, 5000
	li $a2, 10 		# instrument
	li $a3, 90 		# volume
	syscall
	
main_L0_exit:
	lw   	$ra, 8($sp)
	lw	    $s0, 4($sp)
	addi 	$sp, $sp, 16
	jr 	    $ra
 
#=============================================================
# init_genius()
init_genius:
	addiu 	$sp, $sp, -8
	sw	    	$ra, 0($sp)
	
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
	
	la $a0, genius_sequence  	#carregando genius sequence
	lw $a1, genius_steps		# carregando o genius steps
	jal generate_sequence	# chamando o procedimento de gerar sequencia

	lw    	$ra, 0($sp)
	addiu 	$sp, $sp, 8
	jr 	    $ra

#=============================================================
# void blink_button(btn_id)
blink_button:
		addiu $sp,$sp, -40        #Stack size de 40Bytes
		sw $s0, 12($sp)		 #salva os registradores	
		sw $s1, 16($sp)
		sw $s2, 20($sp)
		sw $s3, 24($sp)
		sw $s4, 28($sp)
		sw $ra, 32($sp)
		
		#IF 
		beq $a0, GREEN_CHAR, light_verde                   
		beq $a0, RED_CHAR, light_vermelho
		beq $a0, BLUE_CHAR, light_azul
		beq $a0, YELLOW_CHAR, light_amarelo
	
		b blink_button_exit
	
	# Configura o setpixel para acender e apagar as cores
	light_verde:	
		li	$s0, GREEN_X
		li	$s1, GREEN_Y
		li	$s2, GREEN_ON
		li	$s3, GREEN_OFF
		li  	$s4, GREEN_SOM
		b 	blink_button_do
	light_vermelho:
		li	$s0, RED_X
		li	$s1, RED_Y
		li	$s2, RED_ON
		li	$s3, RED_OFF
		li	$s4, RED_SOM
		b	blink_button_do
	light_azul:
		li	$s0, BLUE_X
		li	$s1, BLUE_Y
		li	$s2, BLUE_ON
		li	$s3, BLUE_OFF
		li	$s4, BLUE_SOM
		b	blink_button_do
	light_amarelo:
		li	$s0, YELLOW_X
		li	$s1, YELLOW_Y
		li	$s2, YELLOW_ON
		li	$s3, YELLOW_OFF
		li	$s4, YELLOW_SOM

#Executa a função light	
blink_button_do:
		move $a0, $s0    #acender as cores
		move $a1, $s1
		move $a2, $s2
		jal set_pixel
		
		li	$v0, 33 	#Realiza o som de cada cor
		move	$a0, $s4
		li	$a1, BLINK_DELAY
		li	$a2, 30
		li	$a3, 80
		syscall	
					
		move $a0, $s0 	#Apaga as cores
		move $a1, $s1
		move $a2, $s3
		jal set_pixel
	
blink_button_exit:			#restaura os registradores
		lw $s0, 12($sp)
		lw $s1, 16($sp)
		lw $s2, 20($sp)
		lw $s3, 24($sp)
		lw $s4, 28($sp)
		lw $ra, 32($sp)
		addiu $sp, $sp, 40
		
		jr 	$ra
		
#=============================================================
# void blink_sequence(char * seq, int steps) 

blink_sequence:

	addiu $sp, $sp, -16        #Stack size de 16Bytes
	sw     $s0, 4($sp)	 #salva os registradores
	sw	$s1, 8($sp)
	sw	$ra,12($sp)
	
	move	$s0, $a0		# recebe os genius sequence
	move $s1, $a1		# recebe a quantidade que precisa piscar

blink_sequence_L0:  # realiza o loop para piscar as cores um por um
	#if
	beqz $s1, blink_sequence_L0_end
	
	lb $a0, 0($s0)
	jal blink_button                 # puxando blink_button
	
	li $v0, 33
	li $a0, BLINK_DELAY       # realizando delay de 500ms
	syscall
	
	add $s0, $s0, 1    	     #atualizar o endereço para piscar a proxima cor
	addi $s1, $s1, -1
	j blink_sequence_L0

blink_sequence_L0_end:	   #restaura os registradores
	
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $ra, 12($sp)
	addiu $sp, $sp, 16

	jr 	    $ra
#=============================================================
# bool check_sequence(char * seq, int steps)
check_sequence:
	addiu $sp, $sp, -24    #Stack size de 24Bytes
	sw	$s0, 4($sp)	 #salva os registradores
	sw	$s1, 8($sp)
	sw 	$s2, 12($sp)
	sw 	$s3, 16($sp)
	sw 	$ra, 20($sp)
	
	move	$s0, $a0		# recebe genius sequence
	move	$s1, $a1		# recebe o tamanho da sequencia a ser analisada

check_sequence_L0:		
	#if
	beqz	$s1, check_sequence_L0_end #verifica se ja passou a sequencia inteira
	
read_L0:	
	la	$a0, kb_buffer		# Faz a leitura do buffer, se ele não estiver vazio
	jal	rb_read			
	beqz	$v0, read_L0 
	
	move	$s2, $v0			#Pisca a tecla que recebeu
	move	$a0, $s2
	jal	blink_button
	
	lb	$s3, 0($s0)		#Verifica se a tecla apertada é igual ao valor da sequencia
	seq 	$s3, $s2, $s3		# carrega 0 ou 1 no $s3
	beqz	$s3, check_sequence_L0_end   # Se $s3 = 0 a pessoa errou e sai do loop
	
	add	$s0, $s0, 1			#Atualiza os dados para a proxima tecla
	addi	$s1, $s1, -1
	j 	check_sequence_L0   
	
check_sequence_L0_end:	
	move	$v0, $s3  	#se errar = 0 ,  se acertar = 1.
	
	lw	$s0, 4($sp)	#restaura os registradores	
	lw	$s1, 8($sp)
	lw 	$s2, 12($sp)
	lw 	$s3, 16($sp)
	lw 	$ra, 20($sp)
	addiu	$sp, $sp, 24	
	
	jr 	    $ra
#=============================================================
# generate a number between (including) 0 and 3 
generate_sequence:			# Gera a  sequencia 
		addiu	$sp, $sp, -24	#Stack size de 24Bytes		
		sw	$s0, 8($sp)
		sw	$s1, 12($sp)
		sw	$ra, 16($sp)      # termina no multiplo de 8
	
		move	$s0, $a0		# recebe o genius sequence
		move	$s1, $a1		# recebe o genius steps
		
	while:					
		beqz	$s1, while_end	# verifica se ja passou pela sequencia toda
		addiu	$s1, $s1, -1	# atualiza o valor
		li	$a1, 4
		li	$v0, 42		# syscall gerar numeros aleatórios
		syscall
		
	if_generate_sequence:        #if  verifica o numero que recebeu e traduz para uma cor
		beqz	$a0, red_number		
		beq	$a0, 1, green_number
		beq	$a0, 2, blue_number
		beq	$a0, 3, yellow_number
		
		red_number:   					#define a cor
			li	$t0, RED_CHAR
			j	if_generate_sequence_end
		green_number:
			li	$t0, GREEN_CHAR
			j	if_generate_sequence_end
		blue_number:
			li	$t0, BLUE_CHAR
			j	if_generate_sequence_end
		yellow_number:
			li	$t0, YELLOW_CHAR
		
		if_generate_sequence_end:		
		sb	$t0, 0($s0) 			#guarda a tradução no genius sequence
		addiu	$s0, $s0, 1
		j	while
	while_end:
	generate_sequence_end:  			#restaura os registradores
		lw	$s0, 8($sp)
		lw	$s1, 12($sp)
		lw	$ra, 16($sp)
		addiu	$sp, $sp, 24		
		jr	$ra
		


