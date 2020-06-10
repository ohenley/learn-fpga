.include "femtorv32.inc"

#################################################################################	
# NanoRv OLED display support
#################################################################################
	
# initialize oled display
.global	oled_init
.type	oled_init, @function
oled_init:
	add sp,sp,-4
        sw ra, 0(sp)	
	# Initialization sequence / RESET
	li a0,5
	sw a0,IO_LEDS(gp)
        li a0,1                      # reset low during 0.5 s
	sw a0,IO_OLED_CNTL(gp)
	call wait
	li a0,10
	sw a0,IO_LEDS(gp)
        li a0,3                      # reset high during 0.5 s
	sw a0,IO_OLED_CNTL(gp)
	call wait
	li a0,15
	sw a0,IO_LEDS(gp)
        li a0,0                      # normal operation
	sw a0,4(gp)
	call oled_wait
	# Initialization sequence / configuration
	# Note: takes a lot of space, could be stored in an array of bytes
	# if ROM space gets crowded
	OLED1 0xfd, 0x12             # unlock driver
	OLED1 0xfd, 0xb1             # unlock commands
	OLED0 0xae                   # display off
	OLED0 0xa4                   # display mode off
	OLED2 0x15,0x00,0x7f         # column address
	OLED2 0x75,0x00,0x7f         # row address
	OLED1 0xb3,0xf1              # front clock divider (see section 8.5 of manual)
	OLED1 0xca, 0x7f             # multiplex
	OLED1 0xa0, 0x74             # remap, data format, increment
	OLED1 0xa1, 0x00             # display start line
	OLED1 0xa2, 0x00             # display offset
	OLED1 0xab, 0x01             # VDD regulator ON
	OLED3 0xb4, 0xa0, 0xb5, 0x55 # segment voltage ref pins
	OLED3 0xc1, 0xc8, 0x80, 0xc0 # contrast current for colors A,B,C
	OLED1 0xc7, 0x0f             # master contrast current
	OLED1 0xb1, 0x32             # length of segments 1 and 2 waveforms
	OLED3 0xb2, 0xa4, 0x00, 0x00 # display enhancement
	OLED1 0xbb, 0x17             # first pre-charge voltage phase 2
	OLED1 0xb6, 0x01             # second pre-charge period (see table 9-1 of manual)
	OLED1 0xbe, 0x05             # Vcomh voltage
	OLED0 0xa6                   # display on
	OLED0 0xaf                   # display mode on
	lw ra, 0(sp)
	add sp,sp,4
	ret

# Clear oled display
.global	oled_clear
.type	oled_clear, @function
oled_clear:  
        mv s2,ra
        OLED2 0x15,0x00,0x7f         # column address
	OLED2 0x75,0x00,0x7f         # row address
	OLED0 0x5c                   # write RAM
	li t0,0
	li s11,128
	li s1,0
cloop_y:li s0,0
cloop_x:sw t0,IO_OLED_DATA(gp)
	call oled_wait 
	sw t0,IO_OLED_DATA(gp)
	call oled_wait 
	add s0,s0,1
	bne s0,s11,cloop_x
	add s1,s1,1
	bne s1,s11,cloop_y
	mv ra,s2
	ret


# Oled display command, 0 argument, command in a0
.global	oled0
.type	oled0, @function
oled0:	add sp,sp,-4
        sw ra, 0(sp)
	sw a0, IO_OLED_CMD(gp)
	call oled_wait
	lw ra, 0(sp)
	add sp,sp,4
	ret

# Oled display command, 1 argument, command in a0, arg in a1	
.global	oled1
.type	oled1, @function
oled1:	add sp,sp,-4
        sw ra, 0(sp)
	sw a0, IO_OLED_CMD(gp)
	call oled_wait
	sw a1, IO_OLED_DATA(gp)
	call oled_wait
	lw ra, 0(sp)
	add sp,sp,4
	ret

# Oled display command, 2 arguments, command in a0, args in a1,a2
.global	oled2
.type	oled2, @function
oled2:	add sp,sp,-4
        sw ra, 0(sp)
	sw a0, IO_OLED_CMD(gp)
	call oled_wait
	sw a1, IO_OLED_DATA(gp)
	call oled_wait
	sw a2, IO_OLED_DATA(gp)
	call oled_wait
	lw ra, 0(sp)	
        add sp,sp,4
	ret

# Oled display command, 3 arguments, command in a0, args in a1,a2,a3
.global	oled3
.type	oled3, @function
oled3:	add sp,sp,-4
        sw ra, 0(sp)
	sw a0, IO_OLED_CMD(gp)
	call oled_wait
	sw a1, IO_OLED_DATA(gp)
	call oled_wait
	sw a2, IO_OLED_DATA(gp)
	call oled_wait
	sw a3, IO_OLED_DATA(gp)
	call oled_wait
	lw ra, 0(sp)
	add sp,sp,4
	ret

# Wait for a while	
.global	wait
.type	wait, @function
wait:	li t0,0x100000
waitl:	add t0,t0,-1
	bnez t0,waitl
	ret

# Wait for Oled driver
.global	oled_wait
.type	oled_wait, @function
oled_wait:
	lw   t0,IO_OLED_CNTL(gp) # (non-zero = busy)
	bnez t0,oled_wait
	ret
	