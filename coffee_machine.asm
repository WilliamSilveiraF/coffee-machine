.data
	coffee:		.word	2
	milk:		.word 	2
	chocolate:	.word	1
	sugar: 		.word	2
	actionOptions:	.asciiz	"\n[1]: Get a coffee \n[2]: Refill storage \n[3]: Display amount by type \nSelect an option: "
	
	drinkOptions:	.asciiz	"\n[1]: Pure coffee \n[2]: Coffee with milk \n[3]: Mochaccino \nSelect the drink: "
	drinkSizes:	.asciiz "\n[1]: Small \n[2]: Big \nSelect size: "
	isThereSugar: 	.asciiz "\n[1] Yes \n[2] No \nDo you want sugar? "
	refillOptions: 	.asciiz "\nRefil \n[1] Sugar \n[2] Pure Coffee \n[3] Milk \n[4] Chocolate \nSelect the storage: "
	
	errorMessage:		.asciiz "\nAn invalid type was selected, the system is restarting\n"
	err_ThereIsntSugar: 	.asciiz "\nInsufficient sugar, please refill \n"
	err_ThereIsntCoffee:	.asciiz "\nInsufficient coffee, please refill \n"
	err_ThereIsntMilk:	.asciiz "\nInsufficient milk, please refill \n"
	err_ThereIsntChocolate: .asciiz "\nInsufficient chocolate, please refill \n"
	
	done_message: 	.asciiz "\nDone ;)\n"
	success_filled:	.asciiz "\nSuccessfully filled out! \n"
	preparing_word:	.asciiz "\nPreparing in "
	seconds_word:	.asciiz " seconds\n"
	sugar_word:	.asciiz "\nStorage: \nSugar: "
	coffee_word:	.asciiz "\nCoffee: "
	milk_word:	.asciiz "\nMilk: "
	chocolate_word: .asciiz "\nChocolate: "
	breakline_word: .asciiz "\n"
	
	fout: 				.asciiz "invoice.txt"
	invoice_header: 		.asciiz "======== INVOICE ========\n\n"
	invoice_footer:			.asciiz "\n\n========================="
	invoice_mask_money: 		.asciiz "\n$"
	invoice_pure_coffee_str:	.asciiz ".00 Pure coffee"
	invoice_coffee_with_milk_str: 	.asciiz ".00 Coffee w/ milk"
	invoice_mochaccino_str: 	.asciiz	".00 Mochaccino"
	invoice_sugar_str:		.asciiz ".00 Sugar"
	invoice_total_str:		.asciiz ".00 Total"
	invoice_big:			.asciiz " | Big"
	invoice_small: 			.asciiz	" | Small"
.text
	jal INIT_DYNAMIC_MEM
main:
	jal	GET_ACTION
	ble	$v0, 0, HANDLE_ERROR
	bge	$v0, 4, HANDLE_ERROR
	# $v0 ACTION TYPE ID
	beq 	$v0, 1, GET_COFFEE
	beq	$v0, 2, REFILL
	beq	$v0, 3, DISPLAY_AMOUNT
	
	BACK_GET_COFFEE_OR_REFILL:
	j main

GET_ACTION:
	li	$v0, 4	
	la 	$a0, actionOptions
	syscall
	
	# Select an option input
	li	$v0, 5
	syscall
	jr	$ra

GET_COFFEE:
	# $t0 drink_type
	# $t1 drink_size
	# $t2 sugar

	# Select drink_type input
	li	$v0, 4
	la	$a0, drinkOptions
	syscall

	li	$v0, 5
	syscall	
	ble	$v0, 0, HANDLE_ERROR
	bge	$v0, 4, HANDLE_ERROR
	move	$t0, $v0

	# select drink_size input
	li	$v0, 4
	la 	$a0, drinkSizes
	syscall
	
	li	$v0, 5
	syscall
	ble	$v0, 0, HANDLE_ERROR
	bge	$v0, 3, HANDLE_ERROR
	move	$t1, $v0
	
	# select sugar input
	li	$v0, 4
	la	$a0, isThereSugar
	syscall
	
	li	$v0, 5
	syscall
	ble	$v0, 0, HANDLE_ERROR
	bge	$v0, 3, HANDLE_ERROR
	move 	$t2, $v0
	
	move	$a0, $t0 # $t0 drink_type
	move	$a1, $t1 # $t1 drink_size
	move	$a2, $t2 # $t2 sugar
	
	CHECK_SUGAR_AVAILABILITY:
	beq	$a2, 2, CHECK_DRINK_TYPE_AVAILABILITY # if don't want sugar
	
	la	$s3, sugar
	lw	$s3, ($s3)     	# $t0 storage - sugar amount
	
	mul	$t1, $a2, $a1  	# $t1 - needed sugar amount

	blt	$s3, $t1, HANDLE_THERE_ISNT_SUGAR_ERROR

	CHECK_DRINK_TYPE_AVAILABILITY:
	la	$s0, coffee
	la	$s1, milk
	la	$s2, chocolate
	lw	$s0, ($s0)	# coffee
	lw	$s1, ($s1)	# milk
	lw	$s2, ($s2)	# chocolate
				# sugar $s3
	CHECK_PURE_COFFEE_AVAIBILITY:
	blt	$s0, $a1, HANDLE_THERE_ISNT_COFFEE_ERROR
	beq	$a0, 1, PREPARE

	CHECK_MILK_AVAIBILITY:
	blt	$s1, $a1, HANDLE_THERE_ISNT_MILK_ERROR
	beq	$a0, 2, PREPARE
	
	CHECK_CHOCOLATE_AVAIBILITY:
	blt	$s2, $a1, HANDLE_THERE_ISNT_CHOCOLATE_ERROR
	beq	$a0, 3, PREPARE

	PREPARE:
	# BACKUP PARAMS
	move	$t4, $a0
	move	$t5, $a1
	move	$t6, $a2
	# $t9 === amt ref time
	li	$t9, 0

	beq	$a2, 2, PREPARECOFFEE # if don't want sugar
	la	$t0, sugar
	sub 	$s3, $s3, $a1
	sw	$s3, ($t0)
	add	$t9, $t9, $a1

	PREPARECOFFEE:
	la	$t0, coffee
	sub	$s0, $s0, $a1
	sw	$s0, ($t0)
	add	$t9, $t9, $a1
	beq	$a0, 1, PREPARE_OUT
	PREPAREMILK:
	la	$t0, milk
	sub	$s1, $s1, $a1
	sw	$s1, ($t0)
	add	$t9, $t9, $a1
	beq	$a0, 2, PREPARE_OUT
	PREPARECHOCOLATE:
	la	$t0, chocolate
	sub	$s2, $s2, $a1
	sw	$s2, ($t0)
	add	$t9, $t9, $a1
	beq	$a0, 3, PREPARE_OUT 

	PREPARE_OUT:
	li	$t8, 5
	mul	$t8, $a1, $t8
	add	$t9, $t8, $t9
	
	li	$v0, 4
	la	$a0, preparing_word
	syscall
	
	li	$v0, 1
	move	$a0, $t9
	syscall

	li	$v0, 4
	la	$a0, seconds_word
	syscall
	
	TIMER:
	mul	$t9, $t9, 1000 # $s0 time ref
	
	li	$v0, 30
	syscall
	move	$s1, $a0 # $s1 init time ref

	WAIT:
	li	$v0, 30
	syscall
	# $a0 now time
	sub	$t8, $a0, $s1 # $t8 time difference
	sle	$t8, $t8, $t9 # check if time difference is less or equal to my required time
	bgtz	$t8, WAIT

	WRITE_INVOICE:
	#GET PARAMS
	move	$s0, $t4	# drink_type
	move	$s1, $t5	# drink_size
	move	$s2, $t6	# sugar
	
	# OPEN FILE
	li $v0, 13
	la $a0, fout
	li $a1, 1
	li $a2, 0
	syscall
	move $s6, $v0
	
	jal WRITE_HEADER
	
	
	li	$s5, 0 # TOTAL REF
	# GET SELECTED PRODUCT VALUE
	
	jal WRITE_MASK_MONEY
	mul	$a0, $s0, $s1
	add	$s5, $s5, $a0
	jal WRITE_NUMBER
	beq	$s0, 1, WRITE_PURE_COFFEE
	beq	$s0, 2, WRITE_COFFEE_WITH_MILK
	beq	$s0, 3, WRITE_MOCHACCINO
	WRITE_SIZE:
	beq	$s1, 1, WRITE_SMALL
	beq	$s1, 2, WRITE_BIG
	
	IS_THERE_SUGAR:
	beq	$s2, 2, CLOSEFILE
	
	jal WRITE_MASK_MONEY
	add	$s5, $s5, $s1 # add sugar amount
	move	$a0, $s1
	jal WRITE_NUMBER
	jal WRITE_SUGAR

	CLOSEFILE:
	jal WRITE_BREAKLINE
	jal WRITE_MASK_MONEY
	move 	$a0, $s5
	jal WRITE_NUMBER
	jal WRITE_TOTAL

	jal WRITE_FOOTER

	li $v0, 16
	move $a0, $s6
	syscall

	li	$v0, 4
	la	$a0, done_message
	syscall

	j BACK_GET_COFFEE_OR_REFILL
REFILL:
	li	$v0, 4	
	la 	$a0, refillOptions
	syscall
	
	li	$v0, 5
	syscall
	ble	$v0, 0, HANDLE_ERROR
	bge	$v0, 5, HANDLE_ERROR
	
	beq	$v0, 1, REFILL_SUGAR
	beq	$v0, 2, REFILL_COFFEE
	beq	$v0, 3, REFILL_MILK
	beq	$v0, 4, REFILL_CHOCOLATE


	REFILL_SUGAR:
	la	$t0, sugar
	li	$a0, 20
	sw	$a0, ($t0)
	j REFILL_GETOUT

	REFILL_COFFEE:
	la	$t0, coffee
	li	$a0, 20
	sw	$a0, ($t0)
	j REFILL_GETOUT

	REFILL_MILK:
	la	$t0, milk
	li	$a0, 20
	sw	$a0, ($t0)
	j REFILL_GETOUT

	REFILL_CHOCOLATE:
	la	$t0, chocolate
	li	$a0, 20
	sw	$a0, ($t0)
	
	REFILL_GETOUT:
	li	$v0, 4
	la	$a0, success_filled
	syscall
	
	j BACK_GET_COFFEE_OR_REFILL

HANDLE_ERROR:
	li	$v0, 4
	la	$a0, errorMessage
	syscall
	j 	main

HANDLE_THERE_ISNT_SUGAR_ERROR:
	li	$v0, 4
	la 	$a0, err_ThereIsntSugar
	syscall
	j BACK_GET_COFFEE_OR_REFILL

HANDLE_THERE_ISNT_COFFEE_ERROR:
	li	$v0, 4
	la	$a0, err_ThereIsntCoffee
	syscall
	j BACK_GET_COFFEE_OR_REFILL

HANDLE_THERE_ISNT_MILK_ERROR:
	li	$v0, 4
	la 	$a0, err_ThereIsntMilk
	syscall
	j BACK_GET_COFFEE_OR_REFILL
HANDLE_THERE_ISNT_CHOCOLATE_ERROR:
	li	$v0, 4
	la	$a0, err_ThereIsntChocolate
	syscall
	j BACK_GET_COFFEE_OR_REFILL
DISPLAY_AMOUNT:
	la	$s0, sugar
	la	$s1, coffee
	la	$s2, milk
	la	$s3, chocolate
	lw	$s0, ($s0)	# sugar
	lw	$s1, ($s1)	# coffee
	lw	$s2, ($s2)	# milk
	lw	$s3, ($s3)	# chocolate
	
	li	$v0, 4
	la 	$a0, sugar_word
	syscall
	li	$v0, 1
	move	$a0, $s0
	syscall
	
	li	$v0, 4
	la 	$a0, coffee_word
	syscall
	li	$v0, 1
	move	$a0, $s1
	syscall
	
	li	$v0, 4
	la	$a0, milk_word
	syscall
	li	$v0, 1
	move	$a0, $s2
	syscall
	
	li	$v0, 4
	la	$a0, chocolate_word
	syscall
	li	$v0, 1
	move	$a0, $s3
	syscall
	
	li	$v0, 4
	la	$a0, breakline_word
	syscall
	
	j BACK_GET_COFFEE_OR_REFILL
INIT_DYNAMIC_MEM:
	li 	$v0, 9
	li 	$a0, 4
	syscall
	move 	$s7, $v0
	
	jr 	$ra
WRITE_HEADER:
	li 	$v0, 15
	move 	$a0, $s6
	la 	$a1, invoice_header
	li 	$a2, 26
	syscall
	
	jr 	$ra
WRITE_MASK_MONEY:
	li 	$v0, 15
	move 	$a0, $s6
	la 	$a1, invoice_mask_money
	li 	$a2, 2
	syscall
	
	jr 	$ra
WRITE_NUMBER:
	# $s6 file address
	# $s7 base address
	# $a0 === Number
	addi 	$a0, $a0, 48
	sw 	$a0, ($s7)

	li 	$v0, 15
	move 	$a0, $s6
	move 	$a1, $s7
	li   	$a2, 1
	syscall
	
	jr 	$ra
WRITE_PURE_COFFEE:
	li 	$v0, 15
	move 	$a0, $s6
	la 	$a1, invoice_pure_coffee_str
	li 	$a2, 15
	syscall

	j WRITE_SIZE
WRITE_COFFEE_WITH_MILK:
	li 	$v0, 15
	move 	$a0, $s6
	la 	$a1, invoice_coffee_with_milk_str
	li 	$a2, 18
	syscall

	j WRITE_SIZE
WRITE_MOCHACCINO:
	li 	$v0, 15
	move 	$a0, $s6
	la 	$a1, invoice_mochaccino_str
	li 	$a2, 14
	syscall

	j WRITE_SIZE
WRITE_SUGAR:
	li 	$v0, 15
	move 	$a0, $s6
	la 	$a1, invoice_sugar_str
	li 	$a2, 9
	syscall
	
	jr	$ra
WRITE_SMALL:
	li	$v0, 15
	move	$a0, $s6
	la	$a1, invoice_small
	li	$a2, 8
	syscall

	j IS_THERE_SUGAR
WRITE_BIG:
	li	$v0, 15
	move	$a0, $s6
	la	$a1, invoice_big
	li	$a2, 6
	syscall
	
	j IS_THERE_SUGAR
WRITE_FOOTER:
	li	$v0, 15
	move	$a0, $s6
	la	$a1, invoice_footer
	li	$a2, 27
	syscall
	
	jr 	$ra
WRITE_BREAKLINE:
	li	$v0, 15
	move	$a0, $s6
	la	$a1, breakline_word
	li	$a2, 1
	syscall

	jr	$ra
WRITE_TOTAL:
	li	$v0, 15
	move 	$a0, $s6
	la	$a1, invoice_total_str
	li	$a2, 9
	syscall
	jr	$ra