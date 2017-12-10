#Calculator
#You will recieve marks based 
#on functionality of your calculator.
#REMEMBER: invalid inputs are ignored.


#Have fun!
.data
buffer: 	.space 2048	# buffer to store our calculator input as we receive each character
str1:		.asciiz		"Calculator for MIPS\n"
str2:		.asciiz 	"press 'c' for clear and 'q' to quit:\n"
str3:		.asciiz 	"result: "

res: 		.word		0 	# global var-- result of last calculation

.text
.globl main


#TODO:
#main procedure, that will call your calculator
main:
		la $a0, str1		# print opening prompt
		jal print_str		# split into chars and print
		
init:					# reset buffers and state
		la $a0, str2		# print input instructions prompt
		jal print_str
		
		li $s0, 1		# $s0 is a flag, =1 if we are using last value in current calculation
		li $s2, 0		# $s2 stores first integer input (if there is one)
		li $s3, 0		# $s3 stores second integer input (always exists)
		li $s6, 0		# $s6 is a flag, =1 if first input is negative
		li $s7, 0		# $s7 is a flag, =1 if second input is negative

		li $s5, 0		# s5 tracks our state. 
					# 0 = waiting for first int,neg sign, or other op	['-' -> 1, int -> 2, op -> 4]
					# 1 = got '-', waiting for int or space			[int -> 2, SPACE -> 5]
					# 2 = waiting for int (part of number before op)	[SPACE -> 3]
					# 3 = waiting for op (single char)			[op -> 4]
					# 4 = waiting for space after op			[SPACE -> 5]
					# 5 = waiting for first int or neg after op		['-' -> 6,  int -> 7]
					# 6 = waiting for int (part of num after op)		[int -> 7]
					# 7 = waiting for integers (part of number after op)	[ENTER -> calculate]

mainloop:
		jal stdin		# get character input
		move $a0, $v0		# save character input
		
		li $t0, 'q'		# check for quit command
		beq $a0, $t0, quit	# quit if user enters 'q' at any point
		
		li $t0, 'c'		# check for clear command
		beq $a0, $t0, clear	# clear screen if user enters 'c' at any point
		
		beq $s5, 0, parse_0	# if in state 0
		beq $s5, 1, parse_1	# if in state 1
		beq $s5, 2, parse_2	# if in state 2
		beq $s5, 3, parse_3	# if in state 3
		beq $s5, 4, parse_4	# state 4
		beq $s5, 5, parse_5	# state 5
		beq $s5, 6, parse_6	# 6
		beq $s5, 7, parse_7	# 7
		
		j mainloop
		
parse_0:				# checks if input is an integer, '-', or other operator
		li $t0, '*'		# lowest ascii value for valid char
		blt $a0, $t0, mainloop	# < '*' -> invalid input
		
		li $t0, ','		# an inavlid character between valid ones
		beq $a0, $t0, mainloop 	# ',' -> invalid input
		
		li $t0, '9'		# highest ascii value for valid char
		bgt $a0, $t0, mainloop	# > 9 -> invalid input

		jal stdout		# valid input -> print to screen

		li $t0, '-'		# check if we got a minus sign
		beq $a0, $t0, neg_0	# handle minus sign
		
		li $t0, '0'		# lowest ascii value for integers
		blt $a0, $t0, gotOp	# parse operator if input is not an integer
		
					# else, store integer value in $s2 for later calculation
		li $s0, 0		# disable flag to use most recent value
		sub $t0, $a0, $t0	# subtract ascii value for '0' to get integer value
		move $s2, $t0		# store integer value in $s2
 
		li $s5, 2	 	# increment to collect-integers state
		j mainloop

		
parse_1:				# append if input is an integer, change state if input is space
		li $t0, ' '		# if input is space, change state
		beq $a0, $t0, space_1

		li $t0, '0'		# lowest ascii value for ints
		blt $a0, $t0, mainloop	# < '0' -> invalid input
		
		li $t0, '9'		# highest valid ascii value for ints
		bgt $a0, $t0, mainloop
		
		jal stdout		# valid input -> print
		
		li $s0, 0		# disable flag to use most recent value in calc
		
		li $t0, '0'		# subtract '0' to get integer value
		sub $s2, $a0, $t0	# store int value in $s2

		li $s5, 2		# set state to 2 (waiting for more ints)
		j mainloop
		
parse_2:				# check if input is int or space
		li $t0, ' '		# if space, change state
		beq $a0, $t0, space_2
					# else check if int
		li $t0, '0'		# lowest ascii int
		blt $a0, $t0, mainloop
		
		li $t0, '9'		# highest ascii int
		bgt $a0, $t0, mainloop
		
		jal stdout		# print valid int
		
		li $t0, '0'		# subtract '0' for integer value
		sub $t0, $a0, $t0
		
		li $t1, 10		# multiply s2 by 10 to shift digit
		mult $s2, $t1
		mflo $s2		# get result of mult
		
		add $s2, $s2, $t0	# append new digit
		
		j mainloop		# continue collecting ints

parse_3:				# checks if input is an operator
		li $t0, '*'		# lowest ascii for ops
		blt $a0, $t0, mainloop	# invalid
		
		li $t0, ','		# invalid comma
		beq $a0, $t0 mainloop
		
		li $t0, '/'		# highest ascii for ops
		bgt $a0, $t0, mainloop	# invalid
		
		jal stdout		# valid op -> print to screen
		j gotOp			# parse operator, change state, and continue
		
parse_4:				# waiting for space after op
		li $t0, ' '
		bne $a0, $t0, mainloop	# anything but space, return

		jal stdout		# else print space

		li $s5, 5		# incr state (waiting for int after op)
		j mainloop

parse_5:				# waiting for '-' or int
		li $t0, '-'		# check if second number negative
		beq $a0, $t0, neg_5	# set flag if second number negative
					# else check if valid int
		li $t0, '9'		# highest ascii int
		bgt $a0, $t0, mainloop
		
		li $t0, '0'		# lowest ascii int
		blt $a0, $t0, mainloop
		
		jal stdout		# print valid int
		
		li $t0, '0'
		sub $s3, $a0, $t0	# subtract '0' to get int value, store in $s3
		
		li $s5, 7		# goto final state (waiting for ENTER)
		
		j mainloop
		
parse_6:				# waiting for first digit of second number (after '-')
		li $t0, '9'		# highest ascii int
		bgt $a0, $t0, mainloop
		
		li $t0, '0'		# lowest ascii int
		blt $a0, $t0, mainloop
		
		jal stdout		# print valid int
		
		li $t0, '0'
		sub $s3, $a0, $t0	# subtract '0' to get int value, store in $s3
		
		li $s5, 7		# goto final state (waiting for ENTER)
		
		j mainloop
		
parse_7:				# if integer, append to postOp number, if ENTER -> calculate
		li $t0, '\n'		# check for enter
		beq $a0, $t0, calc	# calculate expression!
		
		li $t0, '0'		# else, make sure input is int
		blt $a0, $t0, mainloop
		
		li $t0, '9'		# highest int
		bgt $a0, $t0, mainloop
		
		jal stdout		# print valid int

		li $t0, 10		# append digit to second integer
		mult $s3, $t0		# multiply by 10 to shift one digit over
		mflo $s3		# get result of multiplication
		li $t0, '0'
		sub $a0, $a0, $t0	# subtract '0' to get int value
		add $s3, $s3, $a0	# append new digit in least significant place

		j mainloop		# hold state and repeat
		
neg_0:					# handle minus sign as first input
		li $s6, 1		# load flag signaling first input is negative
		li $s5, 1		# goto state one (waiting for space or int)
		j mainloop
						
gotOp:
		move $a1, $a0		# load operator as second input to calculator sub-procedure
		li $s5, 4		# goto post operator state (wait for space)
		j mainloop

space_1:				# space after initial '-'		
		jal stdout		# print space
		li $a1, '-'		# set '-' as op arg
		li $s5, 5		# goto state 5 (waiting for second number)
		j mainloop
		
space_2:				# space after first number
		jal stdout		# print space
		li $s5, 3		# goto state 3 (waiting for op)
		j mainloop
		
neg_5:					# '-' signalling second number is negative
		jal stdout		# print negative sign
		li $s7, 1		# set negative flag for second number
		li $s5, 6		# goto state 6 (waiting for second number)
		j mainloop

# ================== CALCULATOR WRAPPER =====================================
calc:					# prepare input and output for calculator procedure
		bne $s0, 1, use_arg1	# if flag not set, we have both new values
		lw $a0, res		# else, use most recent value
		j use_arg2		# skip $a0 initialization
	
use_arg1:	beq $s6, 1, neg_a	# check if first input is negative
arg_1:		move $a0, $s2		# pass first ingeger as first arg
					# $a1 already holds operator
use_arg2:	beq $s7, 1, neg_b	# check if second arg is negative
arg_2:		move $a2, $s3		# pass second int as second arg

		jal calculator		# calculate mathematical expression
		move $s7, $v0		# save results of calculation
		move $s6, $v1

		li $a0, '\n'		# print newline
		jal stdout

		la $a0, str3		# print "result:" string
		jal print_str		
		
		move $a0, $s7		# print result of calculation
		jal print_int
		
		sw $s7, res		# update "most recent value" in memory
		
		beqz $s6, no_dec	# simply print integer if there is no decimal part
					# else print '.' plus decimal
		li $a0, '.'
		jal stdout		# print '.'
		
		move $a0, $s6		# print decimal part
		jal print_int
	
no_dec:			
		li $a0, '\n'		# print newline again
		jal stdout

		j init			# reset everything
neg_a:					# first arg is negative
		li $t0, -1		# multiply by negative 1
		mult $s2, $t0
		mflo $s2		# put result back in $s2
		j arg_1

neg_b:				
		li $t0, -1		# multiply by neg 1
		mult $s3, $t0
		mflo $s3		# put result back in $s3
		j arg_2
	
# ===== SUB PROCEDURE TO CLEAR MMIO PROMPT =====================
clear:					# print newline and reset states
		li $a0, '\n'		# print newline
		jal stdout
		j init			# re-initialize for fresh input
		
# ======================================================================
quit:
		li $v0, 10		# syscall to exit
		syscall			# exit	

# ===== SUB PROCEDURE FOR SPLITTING INT INTO IT'S DIGITS AND PRINTINT TO STDOUT ====
print_int: 				# int is in $a0
		move $s0, $a0		# save input
		subi $sp, $sp, 4	# decr sp
		sw $ra, 0($sp)		# stack $ra

		beq $s0, $0, print_0	# simply print '0' if 0
		blt $s0, $0, print_neg  # print '-' if number is negative
		
buff:		la $s1, buffer + 2046	# else we will have to build up the number digit by digit
int_loop:
		beq $s0, $0, to_str	# exit if input = 0
		subi $s1, $s1, 1	# move pointer back
		li $t0, 10		# else divide by 10 for next digit
		div $s0, $t0		# hi is remainder --> next digit
		mfhi $a0		# get remainder
		addi $a0, $a0, '0'	# convert to ascii value
		sb $a0, 0($s1)		# store into buffer

		mflo $s0		# set remaining digits as input
		j int_loop	
print_neg:				# print minus sign
		li $a0, '-'
		jal stdout		# print '-'

		li $t0, -1		# multiply by -1 to make printing easier
		mult $s0, $t0
		mflo $s0		# return positive value to $s0
		j buff			# return to main print loop
		
to_str:					# print string of numbers
		move $a0, $s1		# pointer to start of int string
		jal print_str
		j int_return		# return

print_0:				# if input is only '0', print 0
		li $a0, '0'
		jal stdout		# print '0'
int_return:				# unstack $ra and return
		lw $ra, 0($sp)
		addi $sp, $sp, 4	# reset sp
		jr $ra
# ===== SUB PROCEDURE FOR SPLITTING STRING INTO CHARS AND PRINTING TO STDOUT =======
print_str:				# prints string to stdout
		la $s0, ($a0)		# address of str
		subi $sp, $sp, 4	# decrement stack pointer
		sw $ra, 0($sp)		# stack $ra
print_loop:
		lb $a0, 0($s0)		# get char at pointer address
		beqz $a0, print_return	# if null terminator, return to main
print_char:				# else print char
		jal stdout		# print char
		addi, $s0, $s0, 1	# increment pointer
		j print_loop		# get next char
print_return:				# unstack $ra and return to main
		lw $ra, 0($sp)		# pop $ra from stack
		addi $sp, $sp, 4
		jr $ra

# ========= calculator procedure, that will deal with the mathematical expression
calculator:				# returns an integer value in $v0
					# with possible decimal value in $v1
	li $v1, 0			# default value is OFF for decimal
					# a1 holds the operator
	beq $a1, '+', plus		# handle addition
	beq $a1, '-', minus		# handle subtraction
	beq $a1, '*', multi		# handle multiplication
	beq $a1, '/', divi		# handle division
	
	move $v0, $0			# stub result otherwise
	jr $ra	
plus:
	move $v0, $a0			# add args together
	add $v0, $v0, $a2		# add second arg
	
	jr $ra				# return
minus:
	move $v0, $a0			# subtract args
	sub $v0, $v0, $a2		# subtract second arg
	
	jr $ra				# return
multi:
	mult $a0, $a2			# multiply args
	mflo $v0			# return result (won't ever be bigger than 32 bits)
	jr $ra
divi:
	div $a0, $a2			# divide, with quotient in lo
	mflo $v0			# return quotient in $v0
	# for decimal, use floating point registers for divison
	mtc1 $a0, $f1			# move to coprocessor
	cvt.s.w $f1, $f1		# convert to float
	mtc1 $a2, $f2			# same with second arg
	cvt.s.w $f2, $f2
	
	div.s $f0, $f1, $f2		# floating point division
					
	cvt.w.s $f1, $f0		# only keep decimal part
	cvt.s.w $f1, $f1
	sub.s $f0, $f0, $f1		# subtract whole number part

	li $t0, 100			# multiply by 100 to get first to dec places
	mtc1 $t0, $f1
	cvt.s.w $f1, $f1
	
	mul.s $f0, $f0, $f1		# multiply decimal result by 100
	cvt.w.s $f0, $f0		# convert back to intever
	mfc1 $v1, $f0			# move result back to $v1

ret:	jr $ra				# return
# ===============================================================================
#driver for getting input from MIPS keyboard
stdin:
					# example taken from slides
		lui $t0, 0xffff		# ffff0000, receiver control register
inloop:		lw $t1, 0($t0)		# control bit
		andi $t1, $t1, 0x0001	# check if control == 1
		beq $t1, $0, inloop	# if not, continue waiting (polling)
		lw $v0, 4($t0)		# else, load data
		jr $ra			# return

#driver for putting output to MIPS display
stdout:
					# character to write is in $a0
		lui $t0, 0xffff		# ffff0000, as before
outloop:	lw $t1, 8($t0)		# get control bit
		andi $t1, $t1, 0x0001	# check if == 1
		beq $t1, $0, outloop	# if not, continue polling
		sw $a0, 12($t0)		# else, send data to screen
		jr $ra			# return
