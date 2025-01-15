.data

A: .word 13 15 21 23 30 17 18 31 15 21
B: .word 4 5 20 18 40 9 45 9 5 18 2 20 4 2 15
C: .space 24
D: .space 36
E: .word 500 1000 1500
endLine: .asciiz "\n"
spaceChar: .asciiz "   "
const0: .float 0.33
const1: .float 400.0
const2: .float 0.0
F: .space 36

.text
.globl main

main:

# load registers
la 	$s0, A		# load address of A
la 	$s1, B		# load address of B
la	$s2, C		# load address of C, which is the result matrix
la	$s7, D		# load address of D
la	$s6, E		# load address of E
l.s	$f0, const0	# load float .33 into f0
la	$s3, F		# load address of F
l.s	$f10, const1	# load float 400.0 into f10
l.s	$f11, const2	# load float 0.0 into f11

#Initialize counter for columns of B
add $t3, $zero, $zero

#Calc the first row of the result matrix
jal RowLoop

#Change the address of $s0 to the start of the second row of array A
add $s0, $s0, 20

#Calc the second row of the result matrix
jal RowLoop

#Resets s2 to the start of the C array
addi $s2, $s2, -24

#Set loop counter and C array address for printing
add $t0, $zero, $zero
add $t1, $s2, $zero 

#Print the multiplication
jal PrintMatrix1

#Set loop counter
add $a0, $zero, $zero

#Perform the concatenation
jal Concatenation

#Set loop counter and D array address for printing
add $t0, $zero, $zero
add $t1, $s7, $zero

#Print the concatenation
jal PrintMatrix2

#Set counter and address arguments
add $a1, $zero, $zero
add $a2, $s7, $zero
add $a3, $s3, $zero

#Perform Constant Multiplication
jal ConstMult

#Set loop counter and F array address for printing
add $t0, $zero, $zero
add $t1, $s3, $zero

#Print the multiplied array
jal PrintMatrix3

#Set loop counter and address of row 2 in last array
add $a0, $s3, 12
add $a1, $zero, $zero

#Find and Replace num in array
jal Find

#Set loop counter and F array adddress for printing
add $t0, $zero, $zero
add $t1, $s3, $zero

#Print array with replaced num
jal PrintMatrix3

#Set loop counter, F array address and trace sum
add $a0, $zero, $zero
add $a1, $s3, $zero
add.s $f1, $f11, $f11

#Calc the trace of the matrix
jal Trace

#Print the trace
add.s $f12, $f1, $f11
li $v0, 2
syscall

#Calculate the trace of the transposed matrix and print the value of the trace:
#The trace of a transposed matrix is the same as the trace of the original matrix because the diagnol values stay in the same place after the transpose. Therefore I'll print the same value as previously calculated
la $a0, endLine
li $v0, 4
syscall
syscall
add.s $f12, $f1, $f11
li $v0, 2
syscall

#End
li $v0, 10
syscall


Trace:
	#Takes floating point value
	l.s $f2, 0($a1)
	
	#Add the value to the trace sum
	add.s $f1, $f1, $f2
	
	#Update address and counter
	addi $a0, $a0, 1
	addi $a1, $a1, 16

	#Check if end of array
	blt $a0, 3, Trace
	jr $ra


Find:
	#Takes floating point value from row
	l.s $f1, 0($a0)

	#Put return address on stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	#If its less than 400 then function called
	c.lt.s $f1, $f10
	bc1t Replace
	
	#restore return address
	lw $ra, 0($sp)
	addi $sp, $sp, 4

	#Increase pointer and counters
	addi $a0, $a0, 4
	addi $a1, $a1, 1

	#Check if end of array
	blt $a1, 3, Find
	jr $ra

Replace:
	#REplaces the number with 0.0 and returns
	s.s $f11, 0($a0)
	jr $ra

ConstMult:
	#Converts item from integer to floating point
	#l.s $f1, 0($a2)
	lw $t5, 0($a2)
	mtc1 $t5, $f1
	cvt.s.w $f1, $f1

	#Multiplies by .33 constant and sets array position to this value
	mul.s $f4, $f0, $f1
	s.s $f4, 0($a3)

	#increase counter and address
	addi $a3, $a3, 4
	addi $a2, $a2, 4
	addi $a1, $a1, 1

	#Check if at array end
	blt $a1, 9, ConstMult
	jr $ra


Concatenation:
	#Places items from array E into D
	lw $t2, 0($s6)
	sw $t2, 0($s7)

	#Increase the counter and addresses
	addi $s7, $s7, 4
	addi $s6, $s6, 4
	addi $a0, $a0, 1

	#Check if at array end and resets s7 to the start of the D array
	blt $a0, 3, Concatenation
	addi $s7, $s7, -36
	jr $ra


RowLoop:
	#Places address of arrays as arguments
	add $a0, $s0, $zero
	add $a1, $s1, $zero

	#Initialize sum of dot product
	add $s4, $zero, $zero

	#Initialize counter for dot product
	add $s5, $zero, $zero

	#Put return address on stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	#Calc dot product
	jal DotProductLoop

	#Restore return address
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	#Place result in correct position of result matrix
	sw $v0, 0($s2)
	sw $v0, 0($s7)

	#Update address of B and counter
	addi $t3, $t3, 1
	addi $s1, $s1, 4

	#Update position in result matrix, C
	addi $s2, $s2, 4
	addi $s7, $s7, 4

	#Check if calculated whole row
	blt, $t3, 3, RowLoop

	#If so reset counter for columns of B to zero and s1 to the start address of B then return
	add $t3, $zero, $zero
	add $s1, $s1, -12
	jr $ra


DotProductLoop:
	#Get first item in the row and column
	lw $t9, 0($a0)
	lw $t8, 0($a1)

	#Calc the dot product
	mul $t7, $t8, $t9
	add $s4, $s4, $t7

	#Update addresses and counter
	addi $s5, $s5, 1
	addi $a0, $a0, 4
	addi $a1, $a1, 12

	#Check if past bounds of array
	blt $s5, 5, DotProductLoop
	add $v0, $s4, $zero
	jr $ra

PrintMatrix1:
	#Check if new line
	beq $t0, 3, PrintNewLine1

	#Place item in the printing argument and prepare for printing
	lw $a0, 0($t1)
	li $v0, 1
	syscall

	#print a space
	la $a0, spaceChar
	li $v0, 4
	syscall

	#update loop counter and array address
	addi $t0, $t0, 1
	addi $t1, $t1, 4

	#Check for end of array
	blt $t0, 7, PrintMatrix1

	#Print extra lines and return
	la $a0, endLine
	li $v0, 4
	syscall
	syscall
	jr $ra

PrintMatrix2:
	#Check if new line
	beq $t0, 3, PrintNewLine2
	beq $t0, 7, PrintNewLine2

	#Place item in the printing argument and prepare for printing
	lw $a0, 0($t1)
	li $v0, 1
	syscall

	#print a space
	la $a0, spaceChar
	li $v0, 4
	syscall
	
	#Update loop counter and array address
	addi $t0, $t0, 1
	addi $t1, $t1, 4

	#Check for end of array
	blt $t0, 11, PrintMatrix2

	#Print extra lines and return
	la $a0, endLine
	li $v0, 4
	syscall
	syscall
	jr $ra

PrintMatrix3:
	#Check if new line
	beq $t0, 3, PrintNewLine3
	beq $t0, 7, PrintNewLine3

	#Place item in the printing argument and prepare for printing
	l.s $f12, 0($t1)
	li $v0, 2
	syscall

	#print a space
	la $a0, spaceChar
	li $v0, 4
	syscall
	
	#Update loop counter and array address
	addi $t0, $t0, 1
	addi $t1, $t1, 4
	
	#Check for end of array
	blt $t0, 11, PrintMatrix3
	
	#Print extra lines and return
	la $a0, endLine
	li $v0, 4
	syscall
	syscall
	jr $ra

PrintNewLine1:
	la $a0, endLine
	li $v0, 4
	syscall
	addi $t0, $t0, 1
	j PrintMatrix1

PrintNewLine2:
	la $a0, endLine
	li $v0, 4
	syscall
	addi $t0, $t0, 1
	j PrintMatrix2

PrintNewLine3:
	la $a0, endLine
	li $v0, 4
	syscall
	addi $t0, $t0, 1
	j PrintMatrix3
