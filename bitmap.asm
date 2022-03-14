.eqv FB_PTR 0x10040000
.eqv FB_XRES 4
.eqv FB_YRES 4

.text
#=============================================================
# set_pixel(X, Y, color)
set_pixel:
  	la	    $t0, FB_PTR
   	mul 	$a1, $a1, FB_XRES
   	add 	$a0, $a0, $a1
   	sll 	$a0, $a0, 2
   	add 	$a0, $a0, $t0
   	sw  	$a2, 0($a0)
   	jr  	$ra